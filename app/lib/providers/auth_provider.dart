import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../core/api_error_helper.dart';
import '../core/auth_session_bus.dart';
import '../core/subscription_access_bus.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

final authSessionBusProvider = Provider<AuthSessionBus>((ref) {
  final bus = AuthSessionBus();
  ref.onDispose(bus.dispose);
  return bus;
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    ref.read(authSessionBusProvider),
    ref.read(subscriptionAccessBusProvider),
  );
});

final subscriptionAccessBusProvider = Provider<SubscriptionAccessBus>((ref) {
  final bus = SubscriptionAccessBus();
  ref.onDispose(bus.dispose);
  return bus;
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.read(apiClientProvider));
});

class AuthState {
  static const _unset = Object();

  final bool isAuthenticated;
  final bool isLoading;
  final bool isInitialized;
  final User? user;
  final String? error;
  final bool viewOnly;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.isInitialized = false,
    this.user,
    this.error,
    this.viewOnly = false,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    bool? isInitialized,
    Object? user = _unset,
    Object? error = _unset,
    bool? viewOnly,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
      user: identical(user, _unset) ? this.user : user as User?,
      error: identical(error, _unset) ? this.error : error as String?,
      viewOnly: viewOnly ?? this.viewOnly,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._authService, this._authSessionBus)
    : super(const AuthState()) {
    _authSessionSubscription = _authSessionBus.stream.listen((_) {
      handleUnauthorized();
    });
    _checkAuth();
  }

  final AuthService _authService;
  final AuthSessionBus _authSessionBus;
  late final StreamSubscription<void> _authSessionSubscription;
  int _authRequestVersion = 0;
  bool _handlingUnauthorized = false;

  Future<void> _checkAuth() async {
    final requestVersion = ++_authRequestVersion;
    final token = await _authService.getSavedToken();

    if (requestVersion != _authRequestVersion) {
      return;
    }

    if (token == null || token.isEmpty) {
      state = state.copyWith(
        isAuthenticated: false,
        isLoading: false,
        isInitialized: true,
        user: null,
        error: null,
      );
      return;
    }

    try {
      final user = await _authService.getMe();
      if (requestVersion != _authRequestVersion) {
        return;
      }

      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        isInitialized: true,
        user: user,
        error: null,
        viewOnly: false,
      );
    } catch (_) {
      if (requestVersion != _authRequestVersion) {
        return;
      }

      await _authService.logout();
      state = state.copyWith(
        isAuthenticated: false,
        isLoading: false,
        isInitialized: true,
        user: null,
        error: null,
      );
    }
  }

  Future<bool> login(String phone, String password) async {
    final requestVersion = ++_authRequestVersion;
    state = state.copyWith(isLoading: true, isInitialized: true, error: null);

    try {
      await _authService.login(phone: phone, password: password);
      final user = await _authService.getMe();

      if (requestVersion != _authRequestVersion) {
        return false;
      }

      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        isInitialized: true,
        user: user,
        error: null,
        viewOnly: false,
      );
      return true;
    } catch (error) {
      if (requestVersion != _authRequestVersion) {
        return false;
      }

      await _authService.logout();
      state = state.copyWith(
        isAuthenticated: false,
        isLoading: false,
        isInitialized: true,
        user: null,
        error: friendlyApiErrorMessage(
          error,
          fallbackMessage:
              '\u767b\u5f55\u5931\u8d25\uff0c\u8bf7\u7a0d\u540e\u91cd\u8bd5',
          unauthorizedMessage:
              '\u624b\u673a\u53f7\u6216\u5bc6\u7801\u9519\u8bef',
          networkMessage:
              '\u65e0\u6cd5\u8fde\u63a5\u670d\u52a1\u5668\uff0c\u8bf7\u5148\u542f\u52a8\u540e\u7aef',
        ),
      );
      return false;
    }
  }

  Future<bool> register(String phone, String password, String nickname) async {
    state = state.copyWith(isLoading: true, isInitialized: true, error: null);

    try {
      await _authService.register(
        phone: phone,
        password: password,
        nickname: nickname,
      );
      return await login(phone, password);
    } catch (error) {
      await _authService.logout();
      state = state.copyWith(
        isAuthenticated: false,
        isLoading: false,
        isInitialized: true,
        user: null,
        error: friendlyApiErrorMessage(
          error,
          fallbackMessage:
              '\u6ce8\u518c\u5931\u8d25\uff0c\u8bf7\u7a0d\u540e\u91cd\u8bd5',
          networkMessage:
              '\u65e0\u6cd5\u8fde\u63a5\u670d\u52a1\u5668\uff0c\u8bf7\u5148\u542f\u52a8\u540e\u7aef',
          statusMessages: const {
            409: '\u8be5\u624b\u673a\u53f7\u5df2\u6ce8\u518c',
            422:
                '\u8bf7\u68c0\u67e5\u624b\u673a\u53f7\u3001\u5bc6\u7801\u548c\u6635\u79f0\u662f\u5426\u5408\u6cd5',
          },
        ),
      );
      return false;
    }
  }

  Future<void> logout() async {
    _authRequestVersion++;
    await _authService.logout();
    state = const AuthState(isInitialized: true);
  }

  Future<void> handleUnauthorized() async {
    if (_handlingUnauthorized) {
      return;
    }

    _handlingUnauthorized = true;
    try {
      _authRequestVersion++;
      await _authService.logout();
      state = const AuthState(isInitialized: true);
    } finally {
      _handlingUnauthorized = false;
    }
  }

  Future<void> refreshUser() async {
    if (!state.isAuthenticated) {
      return;
    }

    try {
      final user = await _authService.getMe();
      state = state.copyWith(user: user);
    } catch (_) {}
  }

  void toggleViewOnly() {
    state = state.copyWith(viewOnly: !state.viewOnly);
  }

  void setViewOnly(bool viewOnly) {
    if (state.viewOnly == viewOnly) {
      return;
    }
    state = state.copyWith(viewOnly: viewOnly);
  }

  @override
  void dispose() {
    _authSessionSubscription.cancel();
    super.dispose();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.read(authServiceProvider),
    ref.read(authSessionBusProvider),
  );
});
