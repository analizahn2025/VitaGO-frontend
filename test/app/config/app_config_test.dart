import 'package:flutter_test/flutter_test.dart';
import 'package:vitago_app/app/config/app_config.dart';
import 'package:vitago_app/app/config/app_mode.dart';
import 'package:vitago_app/app/config/identity_provider.dart';

void main() {
  group('AppMode', () {
    test('interpreta los dos valores documentados', () {
      expect(AppMode.parse('CORPORATE'), AppMode.corporate);
      expect(AppMode.parse('EXTERNAL'), AppMode.external);
    });

    test('rechaza un modo desconocido', () {
      expect(() => AppMode.parse('otro'), throwsFormatException);
    });
  });

  group('IdentityProvider', () {
    test('interpreta los proveedores soportados', () {
      expect(IdentityProvider.parse('LOCAL'), IdentityProvider.local);
      expect(
        IdentityProvider.parse('JWT_CORPORATIVO'),
        IdentityProvider.corporateJwt,
      );
    });

    test('rechaza un proveedor desconocido', () {
      expect(() => IdentityProvider.parse('otro'), throwsFormatException);
    });
  });

  group('AppConfig', () {
    test('conserva el modo y la URL configurados', () {
      final config = AppConfig(
        mode: AppMode.external,
        apiBaseUri: Uri.parse('https://api.example.com/api/v1/'),
      );

      expect(config.isExternal, isTrue);
      expect(config.isCorporate, isFalse);
      expect(config.appName, 'VitaGo Network');
      expect(config.usesLocalAuthentication, isTrue);
    });

    test('permite seleccionar el proveedor corporativo futuro', () {
      final config = AppConfig(
        mode: AppMode.corporate,
        apiBaseUri: Uri.parse('https://corporate.example.com/api/v1/'),
        identityProvider: IdentityProvider.corporateJwt,
      );

      expect(config.isCorporate, isTrue);
      expect(config.usesLocalAuthentication, isFalse);
    });
  });
}
