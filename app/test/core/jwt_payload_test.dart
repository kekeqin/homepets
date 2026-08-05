import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pickstarpet/core/jwt_payload.dart';

void main() {
  test('readJwtExpiry parses exp claim without verification', () {
    final header = base64Url.encode(utf8.encode('{"alg":"none"}'));
    final payload = base64Url.encode(
      utf8.encode('{"sub":"1","exp":1893456000}'),
    );
    final token = '$header.$payload.sig';

    final expiry = readJwtExpiry(token);

    expect(expiry, DateTime.utc(2030, 1, 1));
  });

  test('readJwtExpiry returns null for malformed tokens', () {
    expect(readJwtExpiry('not-a-jwt'), isNull);
  });
}
