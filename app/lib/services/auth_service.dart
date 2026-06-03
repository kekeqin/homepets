import '../core/api_client.dart';
import '../models/user.dart';

class AuthService {
  final ApiClient _apiClient;

  AuthService(this._apiClient);

  Future<void> sendSmsCode({required String phone}) async {
    await _apiClient.dio.post('/api/auth/sms-code', data: {'phone': phone});
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
