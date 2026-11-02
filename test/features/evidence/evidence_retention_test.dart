import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitago_app/core/errors/app_failure.dart';
import 'package:vitago_app/core/network/api_client.dart';
import 'package:vitago_app/features/evidence/controllers/evidence_controller.dart';
import 'package:vitago_app/features/evidence/services/evidence_api_service.dart';
import 'package:vitago_app/features/evidence/views/evidence_image_view.dart';

void main() {
  test(
    'descarga vencida responde 410 sin tratarla como error de conexión',
    () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/v1/'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) => handler.reject(
            DioException(
              requestOptions: options,
              response: Response<List<int>>(
                requestOptions: options,
                statusCode: 410,
                data: <int>[123, 34, 100, 101, 116, 97, 105, 108, 34, 58, 34],
              ),
              type: DioExceptionType.badResponse,
            ),
          ),
        ),
      );
      final service = EvidenceApiService(
        ApiClient(
          dio: dio,
          readAuthorization: () async => null,
          refreshAuthorization: () async => null,
          invalidateAuthorization: () async {},
        ),
      );
      await expectLater(
        service.downloadRequestEvidence(
          requestId: 'request',
          evidenceId: 'photo',
        ),
        throwsA(
          isA<AppFailure>()
              .having((error) => error.statusCode, 'statusCode', 410)
              .having(
                (error) => error.message,
                'message',
                contains('retención'),
              ),
        ),
      );
    },
  );

  testWidgets('el visor conserva el registro y no ofrece reintento para 410', (
    tester,
  ) async {
    final query = (ownerId: 'request', evidenceId: 'photo');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          requestEvidenceFileProvider(query).overrideWith((ref) async {
            throw const AppFailure(
              message: 'Imagen eliminada por retención.',
              statusCode: 410,
            );
          }),
        ],
        child: const MaterialApp(
          home: EvidenceImageView(
            ownerId: 'request',
            evidenceId: 'photo',
            isIncident: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Imagen eliminada por retención'), findsOneWidget);
    expect(find.textContaining('registro de evidencia'), findsOneWidget);
    expect(find.text('Reintentar'), findsNothing);
  });
}
