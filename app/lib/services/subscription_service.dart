import '../core/api_client.dart';
import '../models/subscription_status.dart';

class SubscriptionService {
  SubscriptionService(this._apiClient);

  final ApiClient _apiClient;

  Future<SubscriptionStatus> fetchStatus() async {
    final response = await _apiClient.dio.get('/api/subscription/status');
    return SubscriptionStatus.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<SubscriptionStatus> syncStatus({String? revenueCatAppUserId}) async {
    final data = revenueCatAppUserId == null
        ? const <String, dynamic>{}
        : {'revenuecat_app_user_id': revenueCatAppUserId};
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
