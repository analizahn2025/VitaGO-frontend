import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitago_app/core/network/api_failure_diagnostics.dart';

void main() {
  test('registra payload y respuesta completos sin exponer secretos', () {
    final messages = <String>[];
    final previousDebugPrint = debugPrint;
    debugPrint = (message, {wrapWidth}) {
      if (message != null) messages.add(message);
    };
    addTearDown(() => debugPrint = previousDebugPrint);

    final request = RequestOptions(
      path: '/api/v1/seguimiento/registros/',
      method: 'POST',
    );
    final longDetail = '${List.filled(900, 'x').join()}FIN_RESPUESTA';
    final error = DioException(
      requestOptions: request,
      type: DioExceptionType.badResponse,
      response: Response<Object?>(
        requestOptions: request,
        statusCode: 400,
        data: {
          'errores': {
            'registros': [longDetail],
          },
          'token_acceso': 'token-que-no-debe-aparecer',
        },
      ),
    );

    ApiFailureDiagnostics.logDioExchange(
      operation: 'gps tracking upload',
      error: error,
      payload: {
        'jornada_id': 'jornada-1',
        'registros': [
          {
            'registrada_en': '2026-10-19T15:00:00.000Z',
            'sesion_gps': 'sesion-1',
            'secuencia': 7,
            'password': 'clave-que-no-debe-aparecer',
          },
        ],
      },
    );

    final output = messages.join();
    expect(output, contains('status=400'));
    expect(output, contains('"jornada_id":"jornada-1"'));
    expect(output, contains('"registrada_en":"2026-10-19T15:00:00.000Z"'));
    expect(output, contains('"sesion_gps":"sesion-1"'));
    expect(output, contains('"secuencia":7'));
    expect(output, contains('FIN_RESPUESTA'));
    expect(output, contains('"token_acceso":"[REDACTADO]"'));
    expect(output, contains('"password":"[REDACTADO]"'));
    expect(output, isNot(contains('token-que-no-debe-aparecer')));
    expect(output, isNot(contains('clave-que-no-debe-aparecer')));
  });
}
