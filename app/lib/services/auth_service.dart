import '../core/api_client.dart';
import '../core/token_refresh_policy.dart';
import '../models/user.dart';

class SmsCodeSendResult {
  const SmsCodeSendResult({required this.cooldownSeconds, this.devCode});

  final int cooldownSeconds;
  final String? devCode;
}

class AuthService {
  final ApiClient _apiClient;

  AuthService(this._apiClient);

  Future<SmsCodeSendResult> sendSmsCode({required String phone}) async {
    final response = await _apiClient.dio.post(
      '/api/auth/sms-code',
      data: {'phone': phone},
    );
    final data = response.data;
    if (data is Map) {
      final cooldownSeconds = data['cooldown_seconds'] is num
          ? (data['cooldown_seconds'] as num).toInt()
          : 60;
      final devCode = data['dev_code'];
      return SmsCodeSendResult(
        cooldownSeconds: cooldownSeconds,
        devCode: devCode is String && devCode.isNotEmpty ? devCode : null,
      );
    }
    return const SmsCodeSendResult(cooldownSeconds: 60);
  }

  Future<String> login({required String phone, required String code}) async {
    final response = await _apiClient.dio.post(
      '/api/auth/login',
      data: {'phone': phone, 'code': code},
    );
    return _persistTokenResponse(response.data);
  }

  Future<String> loginWithApple({
    required String identityToken,
    required String authorizationCode,
    String? nonce,
    String? fullName,
  }) async {
    final data = <String, String>{
      'identity_token': identityToken,
      'authorization_code': authorizationCode,
    };
    if (nonce != null) {
      data['nonce'] = nonce;
    }
    if (fullName != null) {
      data['full_name'] = fullName;
    }

    final response = await _apiClient.dio.post('/api/auth/apple', data: data);
    return _persistTokenResponse(response.data);
  }

  /// Refresh the access token using the currently stored bearer token.
  Future<String> refreshAccessToken() async {
    final response = await _apiClient.dio.post('/api/auth/refresh');
    return _persistTokenResponse(response.data);
  }

  /// Refresh when the token has reached the 15/25/29-day checkpoints.
  ///
  /// Failures are ignored so a temporary network error does not force logout;
  /// the next app open can retry at a later checkpoint.
  Future<void> refreshAccessTokenIfNeeded({DateTime? now}) async {
    final token = await _apiClient.getToken();
    if (token == null || token.isEmpty) {
      return;
    }

    final expiresAt = await _apiClient.getTokenExpiresAt();
    if (expiresAt == null) {
      return;
    }

    final currentTime = (now ?? DateTime.now()).toUtc();
    if (!TokenRefreshPolicy.shouldRefresh(
      now: currentTime,
      expiresAt: expiresAt.toUtc(),
    )) {
      return;
    }

    try {
      await refreshAccessToken();
    } catch (_) {
      // Keep the existing token; retry on a later checkpoint or app open.
    }
  }

  Future<String?> getSavedToken() async {
    return _apiClient.getToken();
  }

  Future<DateTime?> getTokenExpiresAt() async {
    return _apiClient.getTokenExpiresAt();
  }

  Future<User> getMe() async {
    final response = await _apiClient.dio.get('/api/auth/me');
    return User.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> logout() async {
    await _apiClient.clearToken();
  }

  Future<String> _persistTokenResponse(dynamic payload) async {
    if (payload is! Map) {
      throw const FormatException('Invalid token response');
    }
    final token = payload['access_token'];
    if (token is! String || token.isEmpty) {
      throw const FormatException('Missing access_token');
    }

    Duration? expiresIn;
    final rawExpiresIn = payload['expires_in'];
    if (rawExpiresIn is num) {
      expiresIn = Duration(seconds: rawExpiresIn.toInt());
    }

    await _apiClient.saveToken(token, expiresIn: expiresIn);
    return token;
  }
}
