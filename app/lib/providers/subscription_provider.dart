import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/subscription_access_bus.dart';
import '../models/subscription_status.dart';
import '../services/subscription_service.dart';
import 'auth_provider.dart';

final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  return SubscriptionService(ref.read(apiClientProvider));
});

final subscriptionProvider =
    StateNotifierProvider<SubscriptionNotifier, SubscriptionState>((ref) {
      return SubscriptionNotifier(ref.read(subscriptionServiceProvider), ref);
    });

final coreMutationBlockedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authProvider);
  if (authState.viewOnly) {
    return true;
  }
  final subscriptionState = ref.watch(subscriptionProvider);
  if (!subscriptionState.isInitialized) {
    return true;
  }
  return !subscriptionState.accessAllowed ||
      subscriptionState.shouldBlockCoreAccess;
});

bool homeGuideBlockedByEntitlement(AuthState authState) {
  return authState.viewOnly;
}

class SubscriptionState {
  static const _unset = Object();

  const SubscriptionState({
    this.isLoading = false,
    this.isInitialized = false,
    this.status,
    this.error,
    this.lastEntitlementReason,
  });

  final bool isLoading;
  final bool isInitialized;
  final SubscriptionStatus? status;
  final String? error;
  final String? lastEntitlementReason;

  bool get accessAllowed => status?.accessAllowed == true;
  bool get paywallRequired => status?.paywallRequired == true;
  bool get shouldBlockCoreAccess => isInitialized && paywallRequired;
  bool get isTrialActive => status?.isTrialActive == true;
  int get trialDaysRemaining => status?.trialDaysRemaining ?? 0;

  SubscriptionState copyWith({
    bool? isLoading,
    bool? isInitialized,
    Object? status = _unset,
    Object? error = _unset,
    Object? lastEntitlementReason = _unset,
  }) {
    return SubscriptionState(
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
      status: identical(status, _unset)
          ? this.status
          : status as SubscriptionStatus?,
      error: identical(error, _unset) ? this.error : error as String?,
      lastEntitlementReason: identical(lastEntitlementReason, _unset)
          ? this.lastEntitlementReason
          : lastEntitlementReason as String?,
    );
  }
}

class SubscriptionNotifier extends StateNotifier<SubscriptionState> {
  SubscriptionNotifier(this._service, this._ref)
    : super(const SubscriptionState()) {
    _authSubscription = _ref.listen<AuthState>(authProvider, (previous, next) {
      if (!next.isInitialized) {
        return;
      }
      if (!next.isAuthenticated) {
        _requestVersion++;
        state = const SubscriptionState(isInitialized: true);
        return;
      }
      if (previous?.user?.id != next.user?.id ||
          previous?.isAuthenticated != next.isAuthenticated) {
        refresh();
      }
    });
    _accessSubscription = _ref
        .read(subscriptionAccessBusProvider)
        .stream
        .listen((event) {
          state = state.copyWith(lastEntitlementReason: event.reason);
          refresh(forceBlockingFallback: true);
        });

    final authState = _ref.read(authProvider);
    if (authState.isInitialized && authState.isAuthenticated) {
      refresh();
    } else if (authState.isInitialized) {
      state = const SubscriptionState(isInitialized: true);
    }
  }

  final SubscriptionService _service;
  final Ref _ref;
  late final ProviderSubscription<AuthState> _authSubscription;
  late final StreamSubscription<SubscriptionAccessEvent> _accessSubscription;
  int _requestVersion = 0;

  Future<void> refresh({bool forceBlockingFallback = false}) async {
    if (!_ref.read(authProvider).isAuthenticated) {
      state = const SubscriptionState(isInitialized: true);
      return;
    }

    final requestVersion = ++_requestVersion;
    state = state.copyWith(isLoading: true, error: null);

    try {
      final status = await _service.fetchStatus();
      if (!mounted || requestVersion != _requestVersion) {
        return;
      }
      state = state.copyWith(
        isLoading: false,
        isInitialized: true,
        status: status,
        error: null,
      );
      if (status.accessAllowed) {
        _ref.read(authProvider.notifier).setViewOnly(false);
      }
    } catch (_) {
      if (!mounted || requestVersion != _requestVersion) {
        return;
      }
      state = state.copyWith(
        isLoading: false,
        isInitialized: true,
        error: '订阅状态刷新失败，请检查网络后重试。',
      );
    }
  }

  Future<bool> syncAfterStorePurchase({
    String? revenueCatAppUserId,
    ClientSubscriptionEntitlement? entitlement,
  }) async {
    final requestVersion = ++_requestVersion;
    state = state.copyWith(isLoading: true, error: null);

    try {
      final status = await _service.syncStatus(
        revenueCatAppUserId: revenueCatAppUserId,
        entitlement: entitlement,
      );
      if (!mounted || requestVersion != _requestVersion) {
        return false;
      }
      state = state.copyWith(
        isLoading: false,
        isInitialized: true,
        status: status,
        error: null,
      );
      if (status.accessAllowed) {
        _ref.read(authProvider.notifier).setViewOnly(false);
      }
      return status.accessAllowed;
    } catch (_) {
      if (!mounted || requestVersion != _requestVersion) {
        return false;
      }
      state = state.copyWith(
        isLoading: false,
        isInitialized: true,
        error: '已完成商店操作，但同步会员状态失败，请稍后重试。',
      );
      return false;
    }
  }

  @override
  void dispose() {
    _authSubscription.close();
    _accessSubscription.cancel();
    super.dispose();
  }
}
