import 'package:dio/dio.dart';

class AppFailure implements Exception {
  const AppFailure({
    required this.message,
    this.statusCode,
    this.fieldErrors = const {},
  });

  factory AppFailure.fromDio(DioException error) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;
    final fieldErrors = _readFieldErrors(data);

    if (statusCode != null && statusCode >= 500) {
      return AppFailure(
        message: 'Ocurrió un error en el servicio. Inténtalo nuevamente.',
        statusCode: statusCode,
      );
    }

    if (statusCode == 401) {
      return const AppFailure(
        message: 'Las credenciales o la sesión no son válidas.',
        statusCode: 401,
      );
    }

    if (statusCode == 403) {
      return const AppFailure(
        message: 'No tienes permiso para realizar esta operación.',
        statusCode: 403,
      );
    }

    if (statusCode == 404) {
      return const AppFailure(
        message:
            'No encontramos este recurso o no está disponible para tu cuenta.',
        statusCode: 404,
      );
    }

    if (statusCode == 409) {
      return AppFailure(
        message:
            _readDetail(data) ??
            'La operación entra en conflicto con el estado actual.',
        statusCode: 409,
      );
    }

    if (fieldErrors.isNotEmpty) {
      return AppFailure(
        message: 'Revisa los datos ingresados.',
        statusCode: statusCode,
        fieldErrors: fieldErrors,
      );
    }

    final detail = _readDetail(data);
    if (detail != null) {
      return AppFailure(message: detail, statusCode: statusCode);
    }

    if (error.type == DioExceptionType.receiveTimeout) {
      return const AppFailure(
        message:
            'El servidor tardó demasiado en responder. Inténtalo de nuevo.',
      );
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.connectionError) {
      return const AppFailure(
        message: 'No fue posible conectar con VitaGo. Revisa tu conexión.',
      );
    }

    return AppFailure(
      message: 'No fue posible completar la operación.',
      statusCode: statusCode,
    );
  }

  final String message;
  final int? statusCode;
  final Map<String, List<String>> fieldErrors;

  bool get isUnauthorized => statusCode == 401;

  bool get isForbidden => statusCode == 403;

  bool get isNotFound => statusCode == 404;

  bool get isConflict => statusCode == 409;

  String? fieldMessage(String key, [String? alternativeKey]) {
    final messages =
        fieldErrors[key] ??
        (alternativeKey == null ? null : fieldErrors[alternativeKey]);
    return messages == null || messages.isEmpty ? null : messages.first;
  }

  static String? _readDetail(Object? data) {
    if (data case {'detail': final Object detail}) {
      final text = detail.toString().trim();
      return text.isEmpty ? null : text;
    }
    return null;
  }

  static Map<String, List<String>> _readFieldErrors(Object? data) {
    if (data is! Map) {
      return const {};
    }

    final result = <String, List<String>>{};
    for (final entry in data.entries) {
      if (entry.key == 'detail') {
        continue;
      }

      final messages = _readMessages(entry.value).toList(growable: false);
      if (messages.isNotEmpty) {
        result[entry.key.toString()] = messages;
      }
    }
    return result;
  }

  static Iterable<String> _readMessages(Object? value) sync* {
    if (value is String) {
      final message = value.trim();
      if (message.isNotEmpty) yield message;
      return;
    }
    if (value is Iterable) {
      for (final item in value) {
        yield* _readMessages(item);
      }
      return;
    }
    if (value is Map) {
      if (value['mensaje'] case final Object rawMessage) {
        final message = rawMessage.toString().trim();
        if (message.isEmpty) return;
        final index = int.tryParse(value['indice']?.toString() ?? '');
        final field = value['campo']?.toString().trim();
        final article = index == null ? 'Artículo' : 'Artículo ${index + 1}';
        if (field != null && field.isNotEmpty) {
          yield '$article · $field: $message';
        } else {
          yield '$article: $message';
        }
        return;
      }
      for (final item in value.values) {
        yield* _readMessages(item);
      }
    }
  }

  @override
  String toString() => message;
}
