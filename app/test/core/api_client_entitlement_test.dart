import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pickstarpet/core/api_client.dart';
import 'package:pickstarpet/core/auth_session_bus.dart';
import 'package:pickstarpet/core/subscription_access_bus.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'ApiClient emits entitlement event on 402 without clearing auth',
    () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      final authBus = AuthSessionBus();
      final accessBus = SubscriptionAccessBus();
      final client = ApiClient(authBus, accessBus);
      client.dio.httpClientAdapter = _EntitlementRequiredAdapter();
      await client.saveToken('token');

      final eventFuture = accessBus.stream.first;
      await expectLater(
        client.dio.get('/api/families/1/tasks'),
        throwsA(isA<DioException>()),
      );
      final event = await eventFuture;

      expect(event.reason, 'trial_expired');
      expect(await client.getToken(), 'token');

      authBus.dispose();
      accessBus.dispose();
    },
  );
}

class _EntitlementRequiredAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      '{"detail":{"code":"ENTITLEMENT_REQUIRED","reason":"trial_expired","trial_ends_at":"2026-05-08T00:00:00Z"}}',
      402,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
