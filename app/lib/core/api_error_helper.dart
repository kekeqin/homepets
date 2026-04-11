import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

bool isUnauthorizedError(Object error) {
  return error is DioException && error.response?.statusCode == 401;
}

bool isNetworkError(Object error) {
  if (error is! DioException) {
    return false;
  }

  return error.type == DioExceptionType.connectionError ||
      error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.receiveTimeout ||
      error.type == DioExceptionType.sendTimeout ||
      (error.response == null && error.type == DioExceptionType.unknown);
}

String? extractApiDetailMessage(Object error) {
  if (error is! DioException) {
    return null;
  }

  final data = error.response?.data;
  if (data is Map) {
    final detail = data['detail'];
    if (detail is String && detail.trim().isNotEmpty) {
      return detail.trim();
    }
  }

  return null;
}

String friendlyApiErrorMessage(
  Object error, {
  required String fallbackMessage,
  String unauthorizedMessage =
      '\u767b\u5f55\u72b6\u6001\u5df2\u5931\u6548\uff0c\u8bf7\u91cd\u65b0\u767b\u5f55',
  String networkMessage =
      '\u65e0\u6cd5\u8fde\u63a5\u670d\u52a1\u5668\uff0c\u8bf7\u7a0d\u540e\u91cd\u8bd5',
  Map<int, String> statusMessages = const {},
}) {
  if (isUnauthorizedError(error)) {
    return unauthorizedMessage;
  }

  final statusCode = error is DioException ? error.response?.statusCode : null;
  if (statusCode != null) {
    final mappedMessage = statusMessages[statusCode];
    if (mappedMessage != null) {
      return mappedMessage;
    }
  }

  final detailMessage = extractApiDetailMessage(error);
  if (detailMessage != null) {
    return detailMessage;
  }

  if (isNetworkError(error)) {
    return networkMessage;
  }

  return fallbackMessage;
}

void showFriendlyApiErrorSnackBar(
  BuildContext context,
  Object error, {
  required String fallbackMessage,
  SnackBarBehavior behavior = SnackBarBehavior.floating,
}) {
  if (isUnauthorizedError(error)) {
    return;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        friendlyApiErrorMessage(error, fallbackMessage: fallbackMessage),
      ),
      behavior: behavior,
    ),
  );
}
