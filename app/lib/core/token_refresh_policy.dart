/// Policy for proactively refreshing access tokens before they expire.
///
/// Server issues tokens with a [defaultLifetime] of 30 days. The client
/// refreshes when the token age reaches any of [refreshAfterAges]
/// (15 / 25 / 29 days), i.e. once age is at least 15 days while still valid.
class TokenRefreshPolicy {
  static const Duration defaultLifetime = Duration(days: 30);

  static const List<Duration> refreshAfterAges = [
    Duration(days: 15),
    Duration(days: 25),
    Duration(days: 29),
  ];

  /// Whether the stored access token should be refreshed now.
  ///
  /// Returns false when already expired (caller must re-login) or when the
  /// token is still younger than the first refresh checkpoint.
  static bool shouldRefresh({
    required DateTime now,
    required DateTime expiresAt,
    Duration lifetime = defaultLifetime,
    List<Duration> checkpoints = refreshAfterAges,
  }) {
    if (!expiresAt.isAfter(now)) {
      return false;
    }

    final issuedAt = expiresAt.subtract(lifetime);
    final age = now.difference(issuedAt);
    if (age.isNegative) {
      return false;
    }

    Duration? earliest;
    for (final checkpoint in checkpoints) {
      if (earliest == null || checkpoint < earliest) {
        earliest = checkpoint;
      }
    }
    if (earliest == null) {
      return false;
    }
    return age >= earliest;
  }
}
