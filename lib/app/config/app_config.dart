import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitago_app/app/config/app_mode.dart';
import 'package:vitago_app/app/config/identity_provider.dart';

final appConfigProvider = Provider<AppConfig>((ref) {
  throw StateError('AppConfig debe configurarse durante el arranque.');
});

class AppConfig {
  const AppConfig({
    required this.mode,
    required this.apiBaseUri,
    this.identityProvider = IdentityProvider.local,
  });

  factory AppConfig.fromEnvironment({AppMode? fixedMode}) {
    const environmentMode = String.fromEnvironment('APP_MODE');
    const apiBaseUrl = String.fromEnvironment('API_BASE_URL');
    const authenticationProvider = String.fromEnvironment(
      'AUTH_PROVIDER',
      defaultValue: 'LOCAL',
    );

    final mode = fixedMode ?? AppMode.parse(environmentMode);
    final apiBaseUri = _parseApiBaseUri(apiBaseUrl);
    final identityProvider = IdentityProvider.parse(authenticationProvider);

    if (mode == AppMode.external &&
        identityProvider == IdentityProvider.corporateJwt) {
      throw const FormatException(
        'JWT_CORPORATIVO solo puede utilizarse en VitaGo Corporate.',
      );
    }

    return AppConfig(
      mode: mode,
      apiBaseUri: apiBaseUri,
      identityProvider: identityProvider,
    );
  }

  final AppMode mode;
  final Uri apiBaseUri;
  final IdentityProvider identityProvider;

  String get appName => mode.productName;

  bool get isCorporate => mode == AppMode.corporate;

  bool get isExternal => mode == AppMode.external;

  bool get usesLocalAuthentication => identityProvider.usesLocalCredentials;

  static Uri _parseApiBaseUri(String value) {
    if (value.trim().isEmpty) {
      throw const FormatException('API_BASE_URL es obligatoria.');
    }

    final parsed = Uri.tryParse(value.trim());
    if (parsed == null ||
        !parsed.hasScheme ||
        !parsed.hasAuthority ||
        (parsed.scheme != 'http' && parsed.scheme != 'https')) {
      throw const FormatException('API_BASE_URL no es una URL HTTP válida.');
    }

    final normalizedPath = parsed.path.endsWith('/')
        ? parsed.path
        : '${parsed.path}/';
    if (!normalizedPath.endsWith('/api/v1/')) {
      throw const FormatException('API_BASE_URL debe terminar en /api/v1/.');
    }

    return parsed.replace(path: normalizedPath);
  }
}
