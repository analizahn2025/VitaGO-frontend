import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitago_app/core/errors/app_failure.dart';

void main() {
  test('distingue una respuesta lenta de un fallo de conexión', () {
    final error = DioException(
      requestOptions: RequestOptions(path: 'autenticacion/iniciar-sesion/'),
      type: DioExceptionType.receiveTimeout,
    );

    final failure = AppFailure.fromDio(error);

    expect(failure.message, contains('tardó demasiado'));
    expect(failure.message, isNot(contains('Revisa tu conexión')));
  });

  test('distingue falta de permisos de recurso fuera de alcance', () {
    final forbidden = AppFailure.fromDio(
      DioException(
        requestOptions: RequestOptions(path: 'usuarios/'),
        response: Response(
          requestOptions: RequestOptions(path: 'usuarios/'),
          statusCode: 403,
        ),
      ),
    );
    final notFound = AppFailure.fromDio(
      DioException(
        requestOptions: RequestOptions(path: 'usuarios/id/'),
        response: Response(
          requestOptions: RequestOptions(path: 'usuarios/id/'),
          statusCode: 404,
        ),
      ),
    );

    expect(forbidden.isForbidden, isTrue);
    expect(notFound.isNotFound, isTrue);
    expect(notFound.message, contains('no está disponible para tu cuenta'));
  });

  test('conserva el detalle funcional de un conflicto', () {
    final failure = AppFailure.fromDio(
      DioException(
        requestOptions: RequestOptions(path: 'solicitudes/'),
        response: Response(
          requestOptions: RequestOptions(path: 'solicitudes/'),
          statusCode: 409,
          data: {'detail': 'Network requiere una cotización antes de crear.'},
        ),
      ),
    );

    expect(failure.isConflict, isTrue);
    expect(failure.message, contains('cotización'));
  });

  test('expone errores simples y anidados junto a su campo', () {
    final failure = AppFailure.fromDio(
      DioException(
        requestOptions: RequestOptions(path: 'solicitudes/'),
        response: Response(
          requestOptions: RequestOptions(path: 'solicitudes/'),
          statusCode: 400,
          data: {
            'correo': ['Este correo ya existe.'],
            'articulos': [
              {
                'cantidad': ['Debe ser mayor que cero.'],
              },
            ],
          },
        ),
      ),
    );

    expect(failure.fieldMessage('correo'), 'Este correo ya existe.');
    expect(failure.fieldMessage('articulos'), 'Debe ser mayor que cero.');
  });

  test('expone el índice y campo de un artículo inválido', () {
    final failure = AppFailure.fromDio(
      DioException(
        requestOptions: RequestOptions(path: 'solicitudes/'),
        response: Response(
          requestOptions: RequestOptions(path: 'solicitudes/'),
          statusCode: 400,
          data: {
            'articulos': [
              {
                'indice': 1,
                'campo': 'cantidad',
                'mensaje': 'Debe ser positiva.',
              },
            ],
          },
        ),
      ),
    );

    expect(
      failure.fieldMessage('articulos'),
      'Artículo 2 · cantidad: Debe ser positiva.',
    );
  });
}
