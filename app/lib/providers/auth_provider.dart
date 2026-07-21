import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../core/api_error_helper.dart';
import '../core/auth_session_bus.dart';
import '../core/subscription_access_bus.dart';
import '../models/user.dart';
import '../services/apple_sign_in_service.dart';
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

final appleSignInServiceProvider = Provider<AppleSignInService>((ref) {
  return AppleSignInService();
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
  AuthNotifier(
    this._authService,
    this._appleSignInService,
    this._authSessionBus,
  ) : super(const AuthState()) {
    _authSessionSubscription = _authSessionBus.stream.listen((_) {
      handleUnauthorized();
    });
    _checkAuth();
  }

  final AuthService _authService;
  final AppleSignInService _appleSignInService;
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

  Future<SmsCodeSendResult?> sendSmsCode(String phone) async {
    state = state.copyWith(error: null);

    try {
      return await _authService.sendSmsCode(phone: phone);
    } catch (error) {
      if (kDebugMode &&
          error is DioException &&
          error.response?.statusCode == 429) {
        return const SmsCodeSendResult(cooldownSeconds: 0);
      }

      state = state.copyWith(
        isInitialized: true,
        error: friendlyApiErrorMessage(
          error,
          fallbackMessage:
              '\u9a8c\u8bc1\u7801\u53d1\u9001\u5931\u8d25\uff0c\u8bf7\u7a0d\u540e\u91cd\u8bd5',
          networkMessage:
              '\u65e0\u6cd5\u8fde\u63a5\u670d\u52a1\u5668\uff0c\u8bf7\u5148\u542f\u52a8\u540e\u7aef',
          statusMessages: const {
            429:
                '\u83b7\u53d6\u592a\u9891\u7e41\uff0c\u8bf7\u7a0d\u540e\u518d\u8bd5',
            422: '\u8bf7\u8f93\u5165\u6709\u6548\u624b\u673a\u53f7',
            503: '\u77ed\u4fe1\u670d\u52a1\u5c1a\u672a\u914d\u7f6e',
          },
        ),
      );
      return null;
    }
  }

  Future<bool> login(String phone, String code) async {
    final requestVersion = ++_authRequestVersion;
    state = state.copyWith(isLoading: true, isInitialized: true, error: null);

    try {
      await _authService.login(phone: phone, code: code);
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
              '\u9a8c\u8bc1\u7801\u9519\u8bef\u6216\u5df2\u8fc7\u671f',
          networkMessage:
              '\u65e0\u6cd5\u8fde\u63a5\u670d\u52a1\u5668\uff0c\u8bf7\u5148\u542f\u52a8\u540e\u7aef',
          statusMessages: const {
            429:
                '\u5c1d\u8bd5\u6b21\u6570\u8fc7\u591a\uff0c\u8bf7\u7a0d\u540e\u518d\u8bd5',
            422: '\u8bf7\u68c0\u67e5\u624b\u673a\u53f7\u548c\u9a8c\u8bc1\u7801',
            503: '\u77ed\u4fe1\u670d\u52a1\u5c1a\u672a\u914d\u7f6e',
          },
        ),
      );
      return false;
    }
  }

  Future<bool> loginWithApple() async {
    final requestVersion = ++_authRequestVersion;
    state = state.copyWith(isLoading: true, isInitialized: true, error: null);

    try {
      final credential = await _appleSignInService.signIn();
      await _authService.loginWithApple(
        identityToken: credential.identityToken,
        authorizationCode: credential.authorizationCode,
        nonce: credential.nonce,
        fullName: credential.fullName,
      );
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
    } on AppleSignInCanceledException {
      if (requestVersion != _authRequestVersion) {
        return false;
      }
      state = state.copyWith(
        isLoading: false,
        isInitialized: true,
        error: null,
      );
      return false;
    } on AppleSignInFailure catch (error) {
      if (requestVersion != _authRequestVersion) {
        return false;
      }
      state = state.copyWith(
        isAuthenticated: false,
        isLoading: false,
        isInitialized: true,
        user: null,
        error: _appleSignInFailureMessage(error),
      );
      return false;
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
              '\u82f9\u679c\u767b\u5f55\u5931\u8d25\uff0c\u8bf7\u7a0d\u540e\u91cd\u8bd5',
          unauthorizedMessage:
              '\u82f9\u679c\u767b\u5f55\u51ed\u8bc1\u65e0\u6548\uff0c\u8bf7\u91cd\u65b0\u6388\u6743',
          networkMessage:
              '\u65e0\u6cd5\u8fde\u63a5\u670d\u52a1\u5668\uff0c\u8bf7\u5148\u542f\u52a8\u540e\u7aef',
          statusMessages: const {
            422:
                '\u82f9\u679c\u767b\u5f55\u8fd4\u56de\u7684\u4fe1\u606f\u4e0d\u5b8c\u6574',
            503: '\u82f9\u679c\u767b\u5f55\u670d\u52a1\u5c1a\u672a\u914d\u7f6e',
          },
        ),
      );
      return false;
    }
  }

  String _appleSignInFailureMessage(AppleSignInFailure error) {
    final message = error.message.trim();
    if (message.isEmpty) {
      return '\u82f9\u679c\u767b\u5f55\u5931\u8d25\uff0c\u8bf7\u7a0d\u540e\u91cd\u8bd5';
    }
    final lower = message.toLowerCase();
    if (lower.contains('not available') || lower.contains('not supported')) {
      return '\u5f53\u524d\u8bbe\u5907\u4e0d\u652f\u6301\u82f9\u679c\u767b\u5f55';
    }
    if (lower.contains('network') || lower.contains('internet')) {
      return '\u7f51\u7edc\u5f02\u5e38\uff0c\u8bf7\u68c0\u67e5\u7f51\u7edc\u540e\u91cd\u8bd5';
    }
    if (lower.contains('missing apple identity token')) {
      return '\u82f9\u679c\u767b\u5f55\u8fd4\u56de\u7684\u4fe1\u606f\u4e0d\u5b8c\u6574';
    }
    return '\u82f9\u679c\u767b\u5f55\u5931\u8d25\uff0c\u8bf7\u7a0d\u540e\u91cd\u8bd5';
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
    ref.read(appleSignInServiceProvider),
    ref.read(authSessionBusProvider),
  );
});
