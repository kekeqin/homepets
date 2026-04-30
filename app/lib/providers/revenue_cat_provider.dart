import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../services/revenue_cat_service.dart';

final revenueCatServiceProvider = Provider<RevenueCatService>((ref) {
  final service = RevenueCatService();
  ref.onDispose(service.dispose);
  return service;
});

final revenueCatProvider =
    StateNotifierProvider<RevenueCatNotifier, RevenueCatState>((ref) {
      return RevenueCatNotifier(ref.read(revenueCatServiceProvider));
    });

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

  Package? get selectedPackage {
    if (packages.isEmpty) {
      return null;
    }
    final selectedIdentifier = selectedPackageIdentifier;
    if (selectedIdentifier == null) {
      return packages.first;
    }
    for (final package in packages) {
      if (package.identifier == selectedIdentifier) {
        return package;
      }
    }
    return packages.first;
  }

  bool get hasPackages => packages.isNotEmpty;

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
  RevenueCatNotifier(this._service) : super(const RevenueCatState()) {
    initialize();
  }

  final RevenueCatService _service;
  Future<void>? _initializeFuture;

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

  String? _selectedPackageIdentifierFor(
    Offerings offerings,
    String? currentIdentifier,
  ) {
    final packages = offerings.current?.availablePackages ?? const <Package>[];
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
}
