import 'package:flutter_test/flutter_test.dart';
import 'package:pickstarpet/core/token_refresh_policy.dart';

void main() {
  final issuedAt = DateTime.utc(2026, 1, 1);
  final expiresAt = issuedAt.add(TokenRefreshPolicy.defaultLifetime);

  test('does not refresh before the 15-day checkpoint', () {
    final now = issuedAt.add(const Duration(days: 14, hours: 23));

    expect(
      TokenRefreshPolicy.shouldRefresh(now: now, expiresAt: expiresAt),
      isFalse,
    );
  });

  test('refreshes at the 15-day checkpoint', () {
    final now = issuedAt.add(const Duration(days: 15));

    expect(
      TokenRefreshPolicy.shouldRefresh(now: now, expiresAt: expiresAt),
      isTrue,
    );
  });

  test('refreshes at the 25-day checkpoint', () {
    final now = issuedAt.add(const Duration(days: 25));

    expect(
      TokenRefreshPolicy.shouldRefresh(now: now, expiresAt: expiresAt),
      isTrue,
    );
  });

  test('refreshes at the 29-day checkpoint', () {
    final now = issuedAt.add(const Duration(days: 29));

    expect(
      TokenRefreshPolicy.shouldRefresh(now: now, expiresAt: expiresAt),
      isTrue,
    );
  });

  test('does not refresh when token is already expired', () {
    final now = expiresAt.add(const Duration(seconds: 1));

    expect(
      TokenRefreshPolicy.shouldRefresh(now: now, expiresAt: expiresAt),
      isFalse,
    );
  });
}
