import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../models/user.dart';
import '../services/revenue_cat_service.dart';
import '../services/subscription_service.dart';
import 'auth_provider.dart';
import 'subscription_provider.dart';

final revenueCatServiceProvider = Provider<RevenueCatService>((ref) {
  final service = RevenueCatService();
  ref.onDispose(service.dispose);
  return service;
});

final revenueCatProvider =
    StateNotifierProvider<RevenueCatNotifier, RevenueCatState>((ref) {
      return RevenueCatNotifier(ref.read(revenueCatServiceProvider), ref);
    });

String revenueCatAppUserIdFor(User user) {
  final familyId = user.familyId;
  if (familyId != null) {
    return 'family_$familyId';
  }
  return 'user_${user.id}';
}

class RevenueCatState {
  static const _unset = Object();

  const RevenueCatState({
    this.isInitializing = false,
    this.isInitialized = false,
    this.isAvailable = false,
    this.isLoadingOfferings = false,
    this.isPurchasing = false,
    this.isRestoring = false,
    this.isPremiumActive = false,
    this.customerInfo,
    this.offerings,
    this.selectedPackageIdentifier,
    this.errorMessage,
    this.purchaseError,
    this.restoreError,
  });

  final bool isInitializing;
  final bool isInitialized;
  final bool isAvailable;
  final bool isLoadingOfferings;
  final bool isPurchasing;
  final bool isRestoring;
  final bool isPremiumActive;
  final CustomerInfo? customerInfo;
  final Offerings? offerings;
  final String? selectedPackageIdentifier;
  final String? errorMessage;
  final String? purchaseError;
  final String? restoreError;

  Offering? get currentOffering => offerings?.current;

  List<Package> get packages =>
      currentOffering?.availablePackages ?? const <Package>[];

  /// Packages offered on the paywall (recurring only; lifetime is not sold).
  List<Package> get purchasablePackages => packages
      .where((package) => package.packageType != PackageType.lifetime)
      .toList(growable: false);

  Package? get selectedPackage {
    final candidates = purchasablePackages;
    if (candidates.isEmpty) {
      return null;
    }
    final selectedIdentifier = selectedPackageIdentifier;
    if (selectedIdentifier != null) {
      for (final package in candidates) {
        if (package.identifier == selectedIdentifier) {
          return package;
        }
      }
    }
    return candidates.first;
  }

  bool get hasPackages => purchasablePackages.isNotEmpty;

  bool get canPurchase =>
      isAvailable &&
      !isPurchasing &&
      !isRestoring &&
      !isPremiumActive &&
      selectedPackage != null;

  RevenueCatState copyWith({
    bool? isInitializing,
    bool? isInitialized,
    bool? isAvailable,
    bool? isLoadingOfferings,
    bool? isPurchasing,
    bool? isRestoring,
    bool? isPremiumActive,
    Object? customerInfo = _unset,
    Object? offerings = _unset,
    Object? selectedPackageIdentifier = _unset,
    Object? errorMessage = _unset,
    Object? purchaseError = _unset,
    Object? restoreError = _unset,
  }) {
    return RevenueCatState(
      isInitializing: isInitializing ?? this.isInitializing,
      isInitialized: isInitialized ?? this.isInitialized,
      isAvailable: isAvailable ?? this.isAvailable,
      isLoadingOfferings: isLoadingOfferings ?? this.isLoadingOfferings,
      isPurchasing: isPurchasing ?? this.isPurchasing,
      isRestoring: isRestoring ?? this.isRestoring,
      isPremiumActive: isPremiumActive ?? this.isPremiumActive,
      customerInfo: identical(customerInfo, _unset)
          ? this.customerInfo
          : customerInfo as CustomerInfo?,
      offerings: identical(offerings, _unset)
          ? this.offerings
          : offerings as Offerings?,
      selectedPackageIdentifier: identical(selectedPackageIdentifier, _unset)
          ? this.selectedPackageIdentifier
          : selectedPackageIdentifier as String?,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      purchaseError: identical(purchaseError, _unset)
          ? this.purchaseError
          : purchaseError as String?,
      restoreError: identical(restoreError, _unset)
          ? this.restoreError
          : restoreError as String?,
    );
  }
}

class RevenueCatNotifier extends StateNotifier<RevenueCatState> {
  RevenueCatNotifier(this._service, this._ref)
    : super(const RevenueCatState()) {
    _authSubscription = _ref.listen<AuthState>(authProvider, (previous, next) {
      if (!next.isAuthenticated || next.user == null) {
        return;
      }
      final appUserId = _stableAppUserIdFor(next.user!);
      if (_loggedInAppUserId != appUserId) {
        logIn(appUserId);
      }
    });
    initialize();
  }

  final RevenueCatService _service;
  final Ref _ref;
  late final ProviderSubscription<AuthState> _authSubscription;
  Future<void>? _initializeFuture;
  String? _loggedInAppUserId;

  Future<void> initialize() {
    final existingFuture = _initializeFuture;
    if (existingFuture != null) {
      return existingFuture;
    }
    final future = _initialize();
    _initializeFuture = future;
    return future;
  }

  Future<void> _initialize() async {
    state = state.copyWith(
      isInitializing: true,
      isLoadingOfferings: true,
      errorMessage: null,
      purchaseError: null,
      restoreError: null,
    );

    try {
      await _service.initialize(
        onCustomerInfoUpdated: _handleCustomerInfoUpdated,
      );
      final user = _ref.read(authProvider).user;
      if (user != null) {
        final appUserId = _stableAppUserIdFor(user);
        await _service.logIn(appUserId);
        _loggedInAppUserId = appUserId;
      }
      final offerings = await _service.fetchOfferings();
      final customerInfo = await _service.fetchCustomerInfo();
      if (!mounted) {
        return;
      }
      state = state.copyWith(
        isInitializing: false,
        isInitialized: true,
        isAvailable: true,
        isLoadingOfferings: false,
        offerings: offerings,
        customerInfo: customerInfo,
        selectedPackageIdentifier: _selectedPackageIdentifierFor(
          offerings,
          state.selectedPackageIdentifier,
        ),
        isPremiumActive: _service.hasActiveEntitlement(customerInfo),
        errorMessage: null,
      );
      unawaited(_syncActiveEntitlementToBackend(customerInfo));
    } on RevenueCatUnavailableException catch (error) {
      _markUnavailable(error.message);
    } on RevenueCatConfigurationException catch (error) {
      _markUnavailable(error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }
      state = state.copyWith(
        isInitializing: false,
        isInitialized: true,
        isAvailable: false,
        isLoadingOfferings: false,
        errorMessage: '订阅服务初始化失败，请稍后重试。',
      );
    }
  }

  Future<void> refreshOfferings() async {
    if (!state.isAvailable) {
      return;
    }

    state = state.copyWith(
      isLoadingOfferings: true,
      errorMessage: null,
      purchaseError: null,
      restoreError: null,
    );

    try {
      final offerings = await _service.fetchOfferings();
      if (!mounted) {
        return;
      }
      state = state.copyWith(
        isLoadingOfferings: false,
        offerings: offerings,
        selectedPackageIdentifier: _selectedPackageIdentifierFor(
          offerings,
          state.selectedPackageIdentifier,
        ),
        errorMessage: null,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      state = state.copyWith(
        isLoadingOfferings: false,
        errorMessage: '套餐信息加载失败，请稍后再试。',
      );
    }
  }

  void selectPackage(Package package) {
    state = state.copyWith(
      selectedPackageIdentifier: package.identifier,
      purchaseError: null,
      restoreError: null,
    );
  }

  Future<bool> purchaseSelectedPackage() async {
    final selectedPackage = state.selectedPackage;
    if (selectedPackage == null) {
      state = state.copyWith(purchaseError: '请先选择一个会员套餐。');
      return false;
    }

    state = state.copyWith(
      isPurchasing: true,
      purchaseError: null,
      restoreError: null,
      errorMessage: null,
    );

    try {
      await _service.purchasePackage(selectedPackage);
      final customerInfo = await _service.fetchCustomerInfo();
      final isPremiumActive = _service.hasActiveEntitlement(customerInfo);
      if (!mounted) {
        return false;
      }
      state = state.copyWith(
        isPurchasing: false,
        customerInfo: customerInfo,
        isPremiumActive: isPremiumActive,
        purchaseError: isPremiumActive ? null : '购买已完成，但会员状态还未生效，请稍后刷新。',
      );
      if (isPremiumActive) {
        unawaited(_syncActiveEntitlementToBackend(customerInfo));
      }
      return isPremiumActive;
    } on PlatformException catch (error) {
      if (!mounted) {
        return false;
      }
      state = state.copyWith(
        isPurchasing: false,
        purchaseError: _purchaseErrorMessage(error),
      );
      return false;
    } catch (_) {
      if (!mounted) {
        return false;
      }
      state = state.copyWith(isPurchasing: false, purchaseError: '购买失败，请稍后重试。');
      return false;
    }
  }

  Future<bool> restorePurchases() async {
    state = state.copyWith(
      isRestoring: true,
      purchaseError: null,
      restoreError: null,
      errorMessage: null,
    );

    try {
      await _service.restorePurchases();
      final customerInfo = await _service.fetchCustomerInfo();
      final isPremiumActive = _service.hasActiveEntitlement(customerInfo);
      if (!mounted) {
        return false;
      }
      state = state.copyWith(
        isRestoring: false,
        customerInfo: customerInfo,
        isPremiumActive: isPremiumActive,
        restoreError: isPremiumActive ? null : '没有找到已开通的高级版订阅。',
      );
      if (isPremiumActive) {
        unawaited(_syncActiveEntitlementToBackend(customerInfo));
      }
      return isPremiumActive;
    } on PlatformException catch (error) {
      if (!mounted) {
        return false;
      }
      state = state.copyWith(
        isRestoring: false,
        restoreError: _restoreErrorMessage(error),
      );
      return false;
    } catch (_) {
      if (!mounted) {
        return false;
      }
      state = state.copyWith(isRestoring: false, restoreError: '恢复购买失败，请稍后重试。');
      return false;
    }
  }

  Future<void> logIn(String appUserId) async {
    if (!_service.isSupportedPlatform || !_service.hasPublicSdkKey) {
      return;
    }
    try {
      await initialize();
      if (state.isAvailable == false) {
        return;
      }
      await _service.logIn(appUserId);
      _loggedInAppUserId = appUserId;
      final customerInfo = await _service.fetchCustomerInfo();
      if (!mounted) {
        return;
      }
      state = state.copyWith(
        customerInfo: customerInfo,
        isPremiumActive: _service.hasActiveEntitlement(customerInfo),
      );
      unawaited(_syncActiveEntitlementToBackend(customerInfo));
    } catch (_) {}
  }

  ClientSubscriptionEntitlement? currentClientEntitlement() {
    return _clientEntitlementFromCustomerInfo(state.customerInfo);
  }

  void clearErrors() {
    state = state.copyWith(
      errorMessage: null,
      purchaseError: null,
      restoreError: null,
    );
  }

  void _handleCustomerInfoUpdated(CustomerInfo customerInfo) {
    if (!mounted) {
      return;
    }
    state = state.copyWith(
      customerInfo: customerInfo,
      isPremiumActive: _service.hasActiveEntitlement(customerInfo),
    );
    unawaited(_syncActiveEntitlementToBackend(customerInfo));
  }

  Future<void> _syncActiveEntitlementToBackend(
    CustomerInfo customerInfo,
  ) async {
    final user = _ref.read(authProvider).user;
    final entitlement = _clientEntitlementFromCustomerInfo(customerInfo);
    if (user == null || entitlement == null || !entitlement.isActive) {
      return;
    }
    try {
      await _ref
          .read(subscriptionProvider.notifier)
          .syncAfterStorePurchase(
            revenueCatAppUserId: revenueCatAppUserIdFor(user),
            entitlement: entitlement,
          );
    } catch (_) {}
  }

  ClientSubscriptionEntitlement? _clientEntitlementFromCustomerInfo(
    CustomerInfo? customerInfo,
  ) {
    final entitlement =
        customerInfo?.entitlements.active[_service.entitlementId];
    if (entitlement == null || !entitlement.isActive) {
      return null;
    }
    return ClientSubscriptionEntitlement(
      entitlementId: entitlement.identifier,
      productId: entitlement.productIdentifier,
      willRenew: entitlement.willRenew,
      isActive: entitlement.isActive,
      subscriptionExpiresAt: _businessExpirationFor(entitlement),
    );
  }

  DateTime? _businessExpirationFor(EntitlementInfo entitlement) {
    final revenueCatExpiration = _dateFromRevenueCat(
      entitlement.expirationDate,
    );
    if (entitlement.periodType == PeriodType.trial ||
        entitlement.periodType == PeriodType.intro) {
      return revenueCatExpiration;
    }

    final packageExpiration = _packageExpirationFor(entitlement);
    if (packageExpiration == null) {
      return revenueCatExpiration;
    }
    if (revenueCatExpiration == null) {
      return packageExpiration;
    }
    return packageExpiration.isAfter(revenueCatExpiration)
        ? packageExpiration
        : revenueCatExpiration;
  }

  DateTime? _packageExpirationFor(EntitlementInfo entitlement) {
    final period = _subscriptionPeriodFor(entitlement.productIdentifier);
    if (period == null) {
      return null;
    }
    final purchasedAt =
        _dateFromRevenueCat(entitlement.latestPurchaseDate) ??
        _dateFromRevenueCat(entitlement.originalPurchaseDate) ??
        DateTime.now().toUtc();
    return _addIso8601Period(purchasedAt, period);
  }

  String? _subscriptionPeriodFor(String productIdentifier) {
    final offerings = state.offerings;
    if (offerings != null) {
      final currentPackages = offerings.current?.availablePackages;
      if (currentPackages != null) {
        for (final package in currentPackages) {
          if (package.storeProduct.identifier == productIdentifier &&
              package.storeProduct.subscriptionPeriod != null) {
            return package.storeProduct.subscriptionPeriod;
          }
        }
      }
      for (final offering in offerings.all.values) {
        for (final package in offering.availablePackages) {
          if (package.storeProduct.identifier == productIdentifier) {
            return package.storeProduct.subscriptionPeriod;
          }
        }
      }
    }
    return _subscriptionPeriodFromProductIdentifier(productIdentifier);
  }

  String? _subscriptionPeriodFromProductIdentifier(String productIdentifier) {
    final normalized = productIdentifier.toLowerCase();
    if (normalized.contains('year') || normalized.contains('annual')) {
      return 'P1Y';
    }
    if (normalized.contains('month') || normalized.contains('monthly')) {
      return 'P1M';
    }
    if (normalized.contains('week') || normalized.contains('weekly')) {
      return 'P1W';
    }
    return null;
  }

  DateTime? _dateFromRevenueCat(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty) {
      return null;
    }
    return DateTime.tryParse(text)?.toUtc();
  }

  DateTime? _addIso8601Period(DateTime start, String period) {
    final match = RegExp(
      r'^P(?:(\d+)Y)?(?:(\d+)M)?(?:(\d+)W)?(?:(\d+)D)?$',
    ).firstMatch(period);
    if (match == null) {
      return null;
    }
    final years = int.tryParse(match.group(1) ?? '') ?? 0;
    final months = int.tryParse(match.group(2) ?? '') ?? 0;
    final weeks = int.tryParse(match.group(3) ?? '') ?? 0;
    final days = int.tryParse(match.group(4) ?? '') ?? 0;
    var result = _addMonths(start, years * 12 + months);
    if (weeks != 0 || days != 0) {
      result = result.add(Duration(days: weeks * 7 + days));
    }
    return result;
  }

  DateTime _addMonths(DateTime date, int months) {
    if (months == 0) {
      return date;
    }
    final monthIndex = date.month - 1 + months;
    final year = date.year + monthIndex ~/ 12;
    final month = monthIndex % 12 + 1;
    final day = math.min(date.day, _lastDayOfMonth(year, month));
    return DateTime.utc(
      year,
      month,
      day,
      date.hour,
      date.minute,
      date.second,
      date.millisecond,
      date.microsecond,
    );
  }

  int _lastDayOfMonth(int year, int month) {
    return DateTime.utc(year, month + 1, 0).day;
  }

  void _markUnavailable(String message) {
    if (!mounted) {
      return;
    }
    state = state.copyWith(
      isInitializing: false,
      isInitialized: true,
      isAvailable: false,
      isLoadingOfferings: false,
      errorMessage: message,
    );
  }

  String _stableAppUserIdFor(User user) {
    return revenueCatAppUserIdFor(user);
  }

  String? _selectedPackageIdentifierFor(
    Offerings offerings,
    String? currentIdentifier,
  ) {
    final packages = (offerings.current?.availablePackages ?? const <Package>[])
        .where((package) => package.packageType != PackageType.lifetime)
        .toList(growable: false);
    if (packages.isEmpty) {
      return null;
    }
    if (currentIdentifier != null &&
        packages.any((package) => package.identifier == currentIdentifier)) {
      return currentIdentifier;
    }
    return packages.first.identifier;
  }

  String _purchaseErrorMessage(PlatformException error) {
    final errorCode = PurchasesErrorHelper.getErrorCode(error);
    return switch (errorCode) {
      PurchasesErrorCode.purchaseCancelledError => '已取消购买。',
      PurchasesErrorCode.productAlreadyPurchasedError => '这个会员套餐已经开通。',
      PurchasesErrorCode.paymentPendingError => '付款正在处理中，请稍后查看会员状态。',
      PurchasesErrorCode.productNotAvailableForPurchaseError =>
        '当前套餐暂时无法购买，请稍后再试。',
      PurchasesErrorCode.networkError ||
      PurchasesErrorCode.offlineConnectionError => '网络连接异常，请稍后重试。',
      PurchasesErrorCode.purchaseNotAllowedError => '当前设备不允许购买。',
      _ => '购买失败，请稍后重试。',
    };
  }

  String _restoreErrorMessage(PlatformException error) {
    final errorCode = PurchasesErrorHelper.getErrorCode(error);
    return switch (errorCode) {
      PurchasesErrorCode.networkError ||
      PurchasesErrorCode.offlineConnectionError => '网络连接异常，请稍后重试。',
      PurchasesErrorCode.storeProblemError => '商店服务暂时不可用，请稍后重试。',
      _ => '恢复购买失败，请稍后重试。',
    };
  }

  @override
  void dispose() {
    _authSubscription.close();
    super.dispose();
  }
}
