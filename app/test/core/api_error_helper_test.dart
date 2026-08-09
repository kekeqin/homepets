import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pickstarpet/core/api_error_helper.dart';

void main() {
  group('shouldForceReLoginOnSessionError', () {
    final requestOptions = RequestOptions(path: '/api/auth/me');

    test('forces re-login only on HTTP 401', () {
      final unauthorized = DioException(
        requestOptions: requestOptions,
        response: Response<Map<String, dynamic>>(
          requestOptions: requestOptions,
          statusCode: 401,
          data: const <String, dynamic>{'detail': '无效的认证凭据'},
        ),
        type: DioExceptionType.badResponse,
      );

      expect(shouldForceReLoginOnSessionError(unauthorized), isTrue);
    });

    test('keeps session on network timeout', () {
      final timeout = DioException(
        requestOptions: requestOptions,
        type: DioExceptionType.connectionTimeout,
      );

      expect(shouldForceReLoginOnSessionError(timeout), isFalse);
    });

    test('keeps session on connection error', () {
      final connectionError = DioException(
        requestOptions: requestOptions,
        type: DioExceptionType.connectionError,
      );

      expect(shouldForceReLoginOnSessionError(connectionError), isFalse);
    });

    test('keeps session on server 5xx', () {
      final serverError = DioException(
        requestOptions: requestOptions,
        response: Response<Map<String, dynamic>>(
          requestOptions: requestOptions,
          statusCode: 503,
          data: const <String, dynamic>{'detail': 'unavailable'},
        ),
        type: DioExceptionType.badResponse,
      );

      expect(shouldForceReLoginOnSessionError(serverError), isFalse);
    });
  });

  test('extracts message from structured API detail', () {
    final requestOptions = RequestOptions(path: '/api/tasks');
    final error = DioException(
      requestOptions: requestOptions,
      response: Response<Map<String, dynamic>>(
        requestOptions: requestOptions,
        statusCode: 402,
        data: const <String, dynamic>{
          'detail': <String, dynamic>{
            'code': 'ENTITLEMENT_REQUIRED',
            'message': '试用期已结束，请订阅后继续使用。',
          },
        },
      ),
    );

    expect(
      friendlyApiErrorMessage(error, fallbackMessage: '创建任务失败，请稍后重试'),
      '试用期已结束，请订阅后继续使用。',
    );
  });

  test('extracts message from FastAPI validation detail list', () {
    final requestOptions = RequestOptions(path: '/api/tasks');
    final error = DioException(
      requestOptions: requestOptions,
      response: Response<Map<String, dynamic>>(
        requestOptions: requestOptions,
        statusCode: 422,
        data: const <String, dynamic>{
          'detail': <Object>[
            <String, Object>{
              'loc': <Object>['body', 'title'],
              'msg': 'String should have at least 1 character',
            },
          ],
        },
      ),
    );

    expect(
      friendlyApiErrorMessage(error, fallbackMessage: 'Create task failed'),
      'title: String should have at least 1 character',
    );
  });
}
