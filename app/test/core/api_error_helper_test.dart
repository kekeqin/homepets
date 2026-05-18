import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homepets/core/api_error_helper.dart';

void main() {
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
