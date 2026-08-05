import 'package:flutter_test/flutter_test.dart';
import 'package:pickstarpet/core/api_client.dart';
import 'package:pickstarpet/core/auth_session_bus.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('saveToken persists expiry from expiresIn', () async {
    SharedPreferences.setMockInitialValues({});
    final bus = AuthSessionBus();
    final client = ApiClient(bus);

    await client.saveToken(
      'access-token',
      expiresIn: const Duration(days: 30),
    );

    expect(await client.getToken(), 'access-token');
    final expiresAt = await client.getTokenExpiresAt();
    expect(expiresAt, isNotNull);
    expect(
      expiresAt!.difference(DateTime.now().toUtc()).inDays,
      inInclusiveRange(29, 30),
    );

    await client.clearToken();
    expect(await client.getToken(), isNull);
    expect(await client.getTokenExpiresAt(), isNull);
    bus.dispose();
  });
}
