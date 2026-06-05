import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homepets/core/api_client.dart';
import 'package:homepets/core/auth_session_bus.dart';
import 'package:homepets/core/ui/adaptive_design_layout.dart';
import 'package:homepets/models/user.dart';
import 'package:homepets/providers/auth_provider.dart';
import 'package:homepets/screens/auth/login_screen.dart';
import 'package:homepets/services/apple_sign_in_service.dart';
import 'package:homepets/services/auth_service.dart';

void main() {
  testWidgets('login button submits phone and sms code', (tester) async {
    final authService = _FakeAuthService();

    _setPhoneViewport(tester);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authServiceProvider.overrideWithValue(authService)],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), '13800000001');
    await tester.enterText(find.byType(TextFormField).at(1), '123456');
    await tester.tap(find.byKey(LoginScreen.submitButtonKey));
    await tester.pumpAndSettle();

    expect(authService.loginCalls, 1);
    expect(authService.lastPhone, '13800000001');
    expect(authService.lastCode, '123456');
  });

  testWidgets('send code button starts 60 second countdown', (tester) async {
    final authService = _FakeAuthService();

    _setPhoneViewport(tester);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authServiceProvider.overrideWithValue(authService)],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, '13800000001');
    await tester.tap(find.byKey(LoginScreen.sendCodeButtonKey));
    await tester.pump();

    expect(authService.sendCodeCalls, 1);
    expect(find.text('60s'), findsOneWidget);

    await tester.pump(const Duration(seconds: 60));

    expect(find.text('\u91cd\u65b0\u53d1\u9001'), findsOneWidget);
  });

  testWidgets('login panel follows adaptive design coordinates', (
    tester,
  ) async {
    final authService = _FakeAuthService();

    Future<Rect> pumpAt(Size viewportSize) async {
      tester.view.physicalSize = viewportSize;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [authServiceProvider.overrideWithValue(authService)],
          child: const MaterialApp(home: LoginScreen()),
        ),
      );
      await tester.pumpAndSettle();
      return tester.getRect(find.byKey(LoginScreen.panelKey));
    }

    final compactRect = await pumpAt(const Size(390, 844));
    expect(LoginScreen.loginPanelRect.top, 455);

    final compactGeometry = AdaptiveDesignLayoutGeometry.resolve(
      viewportSize: const Size(390, 844),
      designSize: LoginScreen.designSize,
      minimumInsets: LoginScreen.minimumInsets,
    );
    expect(
      compactRect.left,
      closeTo(
        compactGeometry.toScreenRect(LoginScreen.loginPanelRect).left,
        0.01,
      ),
    );
    expect(
      compactRect.top,
      closeTo(compactGeometry.toScreenRect(LoginScreen.loginPanelRect).top, 1),
    );
    expect(
      compactRect.width,
      closeTo(
        compactGeometry.toScreenRect(LoginScreen.loginPanelRect).width,
        0.01,
      ),
    );

    await tester.pumpWidget(const SizedBox.shrink());
    final tallRect = await pumpAt(const Size(430, 932));
    final tallGeometry = AdaptiveDesignLayoutGeometry.resolve(
      viewportSize: const Size(430, 932),
      designSize: LoginScreen.designSize,
      minimumInsets: LoginScreen.minimumInsets,
    );
    expect(
      tallRect.left,
      closeTo(tallGeometry.toScreenRect(LoginScreen.loginPanelRect).left, 0.01),
    );
    expect(
      tallRect.top,
      closeTo(tallGeometry.toScreenRect(LoginScreen.loginPanelRect).top, 1),
    );
    expect(
      tallRect.width,
      closeTo(
        tallGeometry.toScreenRect(LoginScreen.loginPanelRect).width,
        0.01,
      ),
    );

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });

  testWidgets('keyboard lifts login panel without scaling it down', (
    tester,
  ) async {
    final authService = _FakeAuthService();

    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authServiceProvider.overrideWithValue(authService)],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final restingRect = tester.getRect(find.byKey(LoginScreen.panelKey));

    tester.view.viewInsets = const FakeViewPadding(bottom: 320);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authServiceProvider.overrideWithValue(authService)],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final keyboardRect = tester.getRect(find.byKey(LoginScreen.panelKey));
    const keyboardTop = 844 - 320;

    expect(keyboardRect.width, closeTo(restingRect.width, 0.01));
    expect(keyboardRect.height, closeTo(restingRect.height, 0.01));
    expect(keyboardRect.top, lessThan(restingRect.top));
    expect(keyboardRect.bottom, lessThanOrEqualTo(keyboardTop - 16 + 0.01));

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
  });

  testWidgets('send code failure shows visible feedback', (tester) async {
    final authService = _FakeAuthService()
      ..sendCodeError = Exception('network unavailable');

    _setPhoneViewport(tester);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authServiceProvider.overrideWithValue(authService)],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, '13800000001');
    await tester.tap(find.byKey(LoginScreen.sendCodeButtonKey));
    await tester.pumpAndSettle();

    expect(authService.sendCodeCalls, 1);
    expect(
      find.text(
        '\u9a8c\u8bc1\u7801\u53d1\u9001\u5931\u8d25\uff0c\u8bf7\u7a0d\u540e\u91cd\u8bd5',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'invalid credentials show visible feedback when login is tapped',
    (tester) async {
      final authService = _FakeAuthService();

      _setPhoneViewport(tester);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [authServiceProvider.overrideWithValue(authService)],
          child: const MaterialApp(home: LoginScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(LoginScreen.submitButtonKey));
      await tester.pump();

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Text &&
              widget.data ==
                  '\u8bf7\u8f93\u5165\u6709\u6548\u624b\u673a\u53f7' &&
              widget.style?.fontSize == 13,
        ),
        findsOneWidget,
      );
      expect(authService.loginCalls, 0);
    },
  );

  testWidgets('apple login button submits apple credential', (tester) async {
    final authService = _FakeAuthService();
    final appleSignInService = _FakeAppleSignInService();

    _setPhoneViewport(tester);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider.overrideWithValue(authService),
          appleSignInServiceProvider.overrideWithValue(appleSignInService),
        ],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(LoginScreen.appleButtonKey));
    await tester.pumpAndSettle();

    expect(appleSignInService.signInCalls, 1);
    expect(authService.appleLoginCalls, 1);
    expect(authService.lastIdentityToken, 'identity-token');
    expect(authService.lastAuthorizationCode, 'authorization-code');
    expect(authService.lastNonce, 'nonce-value');
    expect(authService.lastFullName, 'Apple Parent');
  });
}

void _setPhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(517, 997);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

class _FakeAuthService extends AuthService {
  _FakeAuthService() : super(_FakeApiClient());

  int sendCodeCalls = 0;
  int loginCalls = 0;
  int appleLoginCalls = 0;
  String? lastPhone;
  String? lastCode;
  String? lastIdentityToken;
  String? lastAuthorizationCode;
  String? lastNonce;
  String? lastFullName;
  Object? sendCodeError;

  @override
  Future<String?> getSavedToken() async {
    return null;
  }

  @override
  Future<void> sendSmsCode({required String phone}) async {
    sendCodeCalls++;
    lastPhone = phone;
    final error = sendCodeError;
    if (error != null) {
      throw error;
    }
  }

  @override
  Future<String> login({required String phone, required String code}) async {
    loginCalls++;
    lastPhone = phone;
    lastCode = code;
    return 'token';
  }

  @override
  Future<String> loginWithApple({
    required String identityToken,
    required String authorizationCode,
    String? nonce,
    String? fullName,
  }) async {
    appleLoginCalls++;
    lastIdentityToken = identityToken;
    lastAuthorizationCode = authorizationCode;
    lastNonce = nonce;
    lastFullName = fullName;
    return 'token';
  }

  @override
  Future<User> getMe() async {
    return User(
      id: 1,
      phone: lastPhone,
      nickname: '\u7238\u7238',
      role: 'admin',
      familyId: 1,
    );
  }

  @override
  Future<void> logout() async {}
}

class _FakeAppleSignInService extends AppleSignInService {
  int signInCalls = 0;

  @override
  Future<bool> isAvailable() async {
    return true;
  }

  @override
  Future<AppleSignInCredential> signIn() async {
    signInCalls++;
    return const AppleSignInCredential(
      identityToken: 'identity-token',
      authorizationCode: 'authorization-code',
      nonce: 'nonce-value',
      fullName: 'Apple Parent',
    );
  }
}

class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(AuthSessionBus());

  final Dio _dio = Dio()..httpClientAdapter = _NoopAdapter();

  @override
  Dio get dio => _dio;
}

class _NoopAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString('{}', 200);
  }

  @override
  void close({bool force = false}) {}
}
