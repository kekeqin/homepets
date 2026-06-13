import '../core/api_client.dart';
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
    final token = response.data['access_token'] as String;
    await _apiClient.saveToken(token);
    return token;
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
    final token = response.data['access_token'] as String;
    await _apiClient.saveToken(token);
    return token;
  }

  Future<String?> getSavedToken() async {
    return _apiClient.getToken();
  }

  Future<User> getMe() async {
    final response = await _apiClient.dio.get('/api/auth/me');
    return User.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> logout() async {
    await _apiClient.clearToken();
  }
}
