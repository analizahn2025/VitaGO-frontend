import 'dart:convert';

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

  static void logDioExchange({
    required String operation,
    required DioException error,
    required Object? payload,
  }) {
    if (!kDebugMode) return;

    final request = error.requestOptions;
    debugPrint(
      '[VitaGo] $operation: '
      'method=${request.method} '
      'url=${request.uri} '
      'dio=${error.type.name} '
      'status=${error.response?.statusCode ?? 'none'} '
      'cause=${error.error ?? 'none'}',
    );
    _printCompleteJson('$operation payload', payload);
    _printCompleteJson('$operation response', error.response?.data);
  }

  static void _printCompleteJson(String label, Object? value) {
    const chunkSize = 800;
    final json = jsonEncode(_redactSensitiveValues(value));
    final chunkCount = (json.length / chunkSize).ceil().clamp(1, 1 << 20);

    for (var index = 0; index < chunkCount; index++) {
      final start = index * chunkSize;
      final end = (start + chunkSize).clamp(0, json.length);
      debugPrint(
        '[VitaGo] $label [${index + 1}/$chunkCount]: '
        '${json.substring(start, end)}',
      );
    }
  }

  static Object? _redactSensitiveValues(Object? value) {
    if (value is Map) {
      return value.map((key, nestedValue) {
        final name = key.toString();
        return MapEntry(
          name,
          _isSensitiveKey(name)
              ? '[REDACTADO]'
              : _redactSensitiveValues(nestedValue),
        );
      });
    }
    if (value is Iterable) {
      return value.map(_redactSensitiveValues).toList(growable: false);
    }
    if (value is String) {
      final trimmed = value.trimLeft();
      if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
        try {
          return _redactSensitiveValues(jsonDecode(value));
        } on FormatException {
          // Conserva respuestas de texto que no contienen JSON válido.
        }
      }
      return value.replaceAll(
        RegExp(r'Bearer\s+[^\s"}]+', caseSensitive: false),
        'Bearer [REDACTADO]',
      );
    }
    if (value == null || value is num || value is bool) return value;
    return value.toString();
  }

  static bool _isSensitiveKey(String key) {
    final normalized = key.toLowerCase();
    return normalized.contains('token') ||
        normalized == 'authorization' ||
        normalized.contains('password') ||
        normalized.contains('contrasena') ||
        normalized.contains('contraseña') ||
        normalized.contains('secret') ||
        normalized == 'clave' ||
        normalized == 'api_key' ||
        normalized == 'apikey';
  }

  static String _compact(Object? value) {
    if (value == null) return 'none';
    final normalized = value.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.length <= 2000) return normalized;
    return '${normalized.substring(0, 2000)}…';
  }
}
