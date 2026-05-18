import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homepets/core/api_client.dart';
import 'package:homepets/core/auth_session_bus.dart';
import 'package:homepets/models/user.dart';
import 'package:homepets/providers/auth_provider.dart';
import 'package:homepets/screens/auth/register_screen.dart';
import 'package:homepets/services/auth_service.dart';

void main() {
  testWidgets('register button submits valid form', (tester) async {
    final authService = _FakeAuthService();

    _setPhoneViewport(tester);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authServiceProvider.overrideWithValue(authService)],
        child: const MaterialApp(home: RegisterScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), '\u5c0f\u5b9d');
    await tester.enterText(find.byType(TextFormField).at(1), '13800000002');
    await tester.enterText(find.byType(TextFormField).at(2), 'password123');
    await tester.tap(find.byKey(RegisterScreen.submitButtonKey));
    await tester.pumpAndSettle();

    expect(authService.registerCalls, 1);
    expect(authService.lastNickname, '\u5c0f\u5b9d');
    expect(authService.lastPhone, '13800000002');
    expect(authService.lastPassword, 'password123');
  });

  testWidgets('invalid register form shows visible feedback', (tester) async {
    final authService = _FakeAuthService();

    _setPhoneViewport(tester);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authServiceProvider.overrideWithValue(authService)],
        child: const MaterialApp(home: RegisterScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(RegisterScreen.submitButtonKey));
    await tester.pump();

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            widget.data == '\u8bf7\u8f93\u5165\u6635\u79f0' &&
            widget.style?.fontSize == 13,
      ),
      findsOneWidget,
    );
    expect(authService.registerCalls, 0);
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

  int registerCalls = 0;
  String? lastPhone;
  String? lastPassword;
  String? lastNickname;

  @override
  Future<String?> getSavedToken() async {
    return null;
  }

  @override
  Future<Map<String, dynamic>> register({
    required String phone,
    required String password,
    required String nickname,
  }) async {
    registerCalls++;
    lastPhone = phone;
    lastPassword = password;
    lastNickname = nickname;
    return {'id': 1, 'phone': phone, 'nickname': nickname, 'role': 'admin'};
  }

  @override
  Future<String> login({
    required String phone,
    required String password,
  }) async {
    return 'token';
  }

  @override
  Future<User> getMe() async {
    return User(
      id: 1,
      phone: lastPhone,
      nickname: lastNickname ?? '\u5c0f\u5b9d',
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
