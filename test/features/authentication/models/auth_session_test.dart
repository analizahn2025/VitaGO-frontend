import 'package:flutter_test/flutter_test.dart';
import 'package:vitago_app/features/authentication/models/auth_session.dart';
import 'package:vitago_app/features/authentication/models/token_bundle.dart';

void main() {
  final loginResponse = <String, dynamic>{
    'token_acceso': 'access-token',
    'token_refresco': 'refresh-token',
    'tipo_token': 'Bearer',
    'expira_token_acceso_en': '2026-09-22T20:00:00Z',
    'expira_token_refresco_en': '2026-09-29T20:00:00Z',
    'sesion_id': '0b6be16f-4695-46ec-8d75-dbf2566e49e2',
    'usuario': <String, dynamic>{
      'id': '40bc6f06-8634-4103-93d9-aeebda6b19e0',
      'correo': 'usuario@empresa.com',
      'nombres': 'Nombre',
      'apellidos': 'Apellido',
    },
  };

  test('convierte la respuesta documentada en una sesión', () {
    final session = AuthSession.fromLoginResponse(loginResponse);

    expect(session.tokens.accessToken, 'access-token');
    expect(session.tokens.refreshToken, 'refresh-token');
    expect(session.user.email, 'usuario@empresa.com');
    expect(session.user.fullName, 'Nombre Apellido');
  });

  test('serializa y restaura la sesión completa', () {
    final original = AuthSession.fromLoginResponse(loginResponse);
    final restored = AuthSession.fromJson(original.toJson());

    expect(restored.tokens.sessionId, original.tokens.sessionId);
    expect(restored.user.id, original.user.id);
  });

  test('evalúa la vigencia usando las fechas entregadas por el backend', () {
    final tokens = TokenBundle.fromJson(loginResponse);

    expect(tokens.isAccessTokenValid(DateTime.utc(2026, 9, 22, 19)), isTrue);
    expect(tokens.isRefreshTokenValid(DateTime.utc(2026, 9, 30)), isFalse);
  });
}
