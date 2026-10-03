class TokenBundle {
  const TokenBundle({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.accessTokenExpiresAt,
    required this.refreshTokenExpiresAt,
    required this.sessionId,
  });

  factory TokenBundle.fromJson(Map<String, dynamic> json) {
    return TokenBundle(
      accessToken: _requiredString(json, 'token_acceso'),
      refreshToken: _requiredString(json, 'token_refresco'),
      tokenType: _requiredString(json, 'tipo_token'),
      accessTokenExpiresAt: DateTime.parse(
        _requiredString(json, 'expira_token_acceso_en'),
      ).toUtc(),
      refreshTokenExpiresAt: DateTime.parse(
        _requiredString(json, 'expira_token_refresco_en'),
      ).toUtc(),
      sessionId: _requiredString(json, 'sesion_id'),
    );
  }

  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final DateTime accessTokenExpiresAt;
  final DateTime refreshTokenExpiresAt;
  final String sessionId;

  bool isAccessTokenValid(DateTime now) {
    return accessTokenExpiresAt.isAfter(
      now.toUtc().add(const Duration(seconds: 30)),
    );
  }

  bool isRefreshTokenValid(DateTime now) {
    return refreshTokenExpiresAt.isAfter(now.toUtc());
  }

  Map<String, dynamic> toJson() => {
    'token_acceso': accessToken,
    'token_refresco': refreshToken,
    'tipo_token': tokenType,
    'expira_token_acceso_en': accessTokenExpiresAt.toIso8601String(),
    'expira_token_refresco_en': refreshTokenExpiresAt.toIso8601String(),
    'sesion_id': sessionId,
  };

  static String _requiredString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('El campo $key no está presente en la respuesta.');
    }
    return value;
  }
}
