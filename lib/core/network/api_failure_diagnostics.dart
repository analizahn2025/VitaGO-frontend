import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

abstract final class ApiFailureDiagnostics {
  static void logDio({required String operation, required DioException error}) {
    if (!kDebugMode) return;

    final request = error.requestOptions;
    debugPrint(
      '[VitaGo] $operation: '
      'method=${request.method} '
      'url=${request.uri} '
      'dio=${error.type.name} '
      'status=${error.response?.statusCode ?? 'none'} '
      'body=${_compact(error.response?.data)} '
      'cause=${error.error ?? 'none'}',
    );
  }

  static void logUnexpectedResponse({
    required String operation,
    required int? statusCode,
    required Object? body,
  }) {
    if (!kDebugMode) return;

    debugPrint(
      '[VitaGo] $operation: '
      'unexpectedStatus=${statusCode ?? 'none'} '
      'body=${_compact(body)}',
    );
  }

  static String _compact(Object? value) {
    if (value == null) return 'none';
    final normalized = value.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.length <= 2000) return normalized;
    return '${normalized.substring(0, 2000)}…';
  }
}
