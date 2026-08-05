import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_session_bus.dart';
import 'constants.dart';
import 'jwt_payload.dart';
import 'subscription_access_bus.dart';

class ApiClient {
  ApiClient(
    this._authSessionBus, [
    SubscriptionAccessBus? subscriptionAccessBus,
  ]) : _subscriptionAccessBus = subscriptionAccessBus {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString(ApiConstants.tokenKey);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final hadAuthHeader =
              error.requestOptions.headers['Authorization'] != null;
          if (error.response?.statusCode == 401 && hadAuthHeader) {
            await _handleUnauthorized();
            _authSessionBus.notifyUnauthorized();
          } else if (_isEntitlementRequired(error)) {
            final detail = _detailMap(error.response?.data);
            _subscriptionAccessBus?.notifyEntitlementRequired(
              reason: detail?['reason']?.toString(),
              trialEndsAt: DateTime.tryParse(
                detail?['trial_ends_at']?.toString() ?? '',
              ),
            );
          }
          handler.next(error);
        },
      ),
    );
  }

  final AuthSessionBus _authSessionBus;
  final SubscriptionAccessBus? _subscriptionAccessBus;
  late final Dio _dio;

  Dio get dio => _dio;

  Future<void> _handleUnauthorized() async {
    await clearToken();
  }

  Future<void> saveToken(String token, {Duration? expiresIn}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(ApiConstants.tokenKey, token);

    final expiresAt = expiresIn != null
        ? DateTime.now().toUtc().add(expiresIn)
        : readJwtExpiry(token);
    if (expiresAt != null) {
      await prefs.setString(
        ApiConstants.tokenExpiresAtKey,
        expiresAt.toUtc().toIso8601String(),
      );
    } else {
      await prefs.remove(ApiConstants.tokenExpiresAtKey);
    }
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(ApiConstants.tokenKey);
    await prefs.remove(ApiConstants.tokenExpiresAtKey);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(ApiConstants.tokenKey);
  }

  Future<DateTime?> getTokenExpiresAt() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(ApiConstants.tokenExpiresAtKey);
    if (stored != null && stored.isNotEmpty) {
      final parsed = DateTime.tryParse(stored);
      if (parsed != null) {
        return parsed.toUtc();
      }
    }

    final token = prefs.getString(ApiConstants.tokenKey);
    if (token == null || token.isEmpty) {
      return null;
    }
    return readJwtExpiry(token);
  }

  bool _isEntitlementRequired(DioException error) {
    if (error.response?.statusCode != 402) {
      return false;
    }
    return _detailMap(error.response?.data)?['code'] == 'ENTITLEMENT_REQUIRED';
  }

  Map<String, dynamic>? _detailMap(dynamic payload) {
    if (payload is Map && payload['detail'] is Map) {
      return Map<String, dynamic>.from(payload['detail'] as Map);
    }
    return null;
  }
}
