import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homepets/core/api_client.dart';
import 'package:homepets/core/auth_session_bus.dart';
import 'package:homepets/models/user.dart';
import 'package:homepets/providers/auth_provider.dart';
import 'package:homepets/screens/auth/login_screen.dart';
import 'package:homepets/services/auth_service.dart';

void main() {
  testWidgets('login button hit area submits valid credentials', (
    tester,
  ) async {
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
    await tester.enterText(find.byType(TextFormField).at(1), 'testpass123');
    await tester.tap(find.byKey(LoginScreen.submitButtonKey));
    await tester.pumpAndSettle();

    expect(authService.loginCalls, 1);
    expect(authService.lastPhone, '13800000001');
    expect(authService.lastPassword, 'testpass123');
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
}

void _setPhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(517, 997);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

class _FakeAuthService extends AuthService {
  _FakeAuthService() : super(_FakeApiClient());

  int loginCalls = 0;
  String? lastPhone;
  String? lastPassword;

  @override
  Future<String?> getSavedToken() async {
    return null;
  }

  @override
  Future<String> login({
    required String phone,
    required String password,
  }) async {
    loginCalls++;
    lastPhone = phone;
    lastPassword = password;
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
