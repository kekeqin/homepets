import '../core/api_client.dart';
import '../models/subscription_status.dart';

class ClientSubscriptionEntitlement {
  const ClientSubscriptionEntitlement({
    required this.entitlementId,
    required this.productId,
    required this.willRenew,
    required this.isActive,
    this.subscriptionExpiresAt,
  });

  final String entitlementId;
  final String productId;
  final bool willRenew;
  final bool isActive;
  final DateTime? subscriptionExpiresAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'entitlement_id': entitlementId,
      'product_id': productId,
      'subscription_expires_at': subscriptionExpiresAt
          ?.toUtc()
          .toIso8601String(),
      'will_renew': willRenew,
      'is_active': isActive,
    };
  }
}

class SubscriptionService {
  SubscriptionService(this._apiClient);

  final ApiClient _apiClient;

  Future<SubscriptionStatus> fetchStatus() async {
    final response = await _apiClient.dio.get('/api/subscription/status');
    return SubscriptionStatus.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<SubscriptionStatus> syncStatus({
    String? revenueCatAppUserId,
    ClientSubscriptionEntitlement? entitlement,
  }) async {
    final data = <String, dynamic>{};
    if (revenueCatAppUserId != null) {
      data['revenuecat_app_user_id'] = revenueCatAppUserId;
    }
    if (entitlement != null) {
      data.addAll(entitlement.toJson());
    }
    final response = await _apiClient.dio.post(
      '/api/subscription/sync',
      data: data,
    );
    final payload = Map<String, dynamic>.from(response.data as Map);
    return SubscriptionStatus.fromJson(
      Map<String, dynamic>.from(payload['subscription'] as Map),
    );
  }
}
