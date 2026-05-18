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
    if (detail is Map) {
      for (final key in const <String>['message', 'detail', 'msg']) {
        final message = detail[key];
        if (message is String && message.trim().isNotEmpty) {
          return message.trim();
        }
      }
    }
    if (detail is List && detail.isNotEmpty) {
      final messages = detail
          .map(_validationDetailMessage)
          .whereType<String>()
          .where((message) => message.trim().isNotEmpty)
          .toList(growable: false);
      if (messages.isNotEmpty) {
        return messages.join('\n');
      }
    }
  }

  return null;
}

String? _validationDetailMessage(Object? item) {
  if (item is String) {
    return item.trim().isEmpty ? null : item.trim();
  }

  if (item is! Map) {
    return null;
  }

  final message = item['msg'];
  if (message is! String || message.trim().isEmpty) {
    return null;
  }

  final location = item['loc'];
  if (location is List && location.isNotEmpty) {
    final field = location.last;
    if (field != null) {
      return '$field: ${message.trim()}';
    }
  }

  return message.trim();
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
