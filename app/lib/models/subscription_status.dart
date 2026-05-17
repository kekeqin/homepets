class SubscriptionStatus {
  const SubscriptionStatus({
    required this.status,
    required this.accessAllowed,
    required this.paywallRequired,
    required this.scope,
    required this.trialDaysRemaining,
    required this.isPremiumActive,
    required this.entitlementId,
    required this.willRenew,
    required this.revenueCatAppUserId,
    this.reason,
    this.familyId,
    this.userId,
    this.trialStartedAt,
    this.trialEndsAt,
    this.productId,
    this.subscriptionExpiresAt,
    this.lastVerifiedAt,
  });

  final String status;
  final bool accessAllowed;
  final bool paywallRequired;
  final String? reason;
  final String scope;
  final int? familyId;
  final int? userId;
  final DateTime? trialStartedAt;
  final DateTime? trialEndsAt;
  final int trialDaysRemaining;
  final bool isPremiumActive;
  final String entitlementId;
  final String? productId;
  final DateTime? subscriptionExpiresAt;
  final bool willRenew;
  final DateTime? lastVerifiedAt;
  final String revenueCatAppUserId;

  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) {
    return SubscriptionStatus(
      status: json['status']?.toString() ?? 'loading',
      accessAllowed: json['access_allowed'] as bool? ?? false,
      paywallRequired: json['paywall_required'] as bool? ?? true,
      reason: _nullableString(json['reason']),
      scope: json['scope']?.toString() ?? 'family',
      familyId: json['family_id'] as int?,
      userId: json['user_id'] as int?,
      trialStartedAt: _dateTimeFromJson(json['trial_started_at']),
      trialEndsAt: _dateTimeFromJson(json['trial_ends_at']),
      trialDaysRemaining: json['trial_days_remaining'] as int? ?? 0,
      isPremiumActive: json['is_premium_active'] as bool? ?? false,
      entitlementId: json['entitlement_id']?.toString() ?? 'premium',
      productId: _nullableString(json['product_id']),
      subscriptionExpiresAt: _dateTimeFromJson(json['subscription_expires_at']),
      willRenew: json['will_renew'] as bool? ?? false,
      lastVerifiedAt: _dateTimeFromJson(json['last_verified_at']),
      revenueCatAppUserId: json['revenuecat_app_user_id']?.toString() ?? '',
    );
  }

  bool get isTrialActive =>
      status == 'trial_active' || status == 'trial_expiring';

  bool get isTrialExpiring => status == 'trial_expiring';

  bool get blocksCoreAccess => paywallRequired || !accessAllowed;
}

DateTime? _dateTimeFromJson(dynamic value) {
  if (value == null) {
    return null;
  }
  return DateTime.tryParse(value.toString());
}

String? _nullableString(dynamic value) {
  if (value == null) {
    return null;
  }
  final text = value.toString();
  return text.isEmpty ? null : text;
}
