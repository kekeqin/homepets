import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_session_bus.dart';
import 'constants.dart';

class ApiClient {
  ApiClient(this._authSessionBus) {
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
          }
          handler.next(error);
        },
      ),
    );
  }

  final AuthSessionBus _authSessionBus;
  late final Dio _dio;

  Dio get dio => _dio;

  Future<void> _handleUnauthorized() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(ApiConstants.tokenKey);
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(ApiConstants.tokenKey, token);
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(ApiConstants.tokenKey);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(ApiConstants.tokenKey);
  }
}
