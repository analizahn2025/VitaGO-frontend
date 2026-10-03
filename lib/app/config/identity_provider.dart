enum IdentityProvider {
  local,
  corporateJwt;

  static IdentityProvider parse(String value) {
    return switch (value.trim().toUpperCase()) {
      'LOCAL' => IdentityProvider.local,
      'JWT_CORPORATIVO' => IdentityProvider.corporateJwt,
      _ => throw const FormatException(
        'AUTH_PROVIDER debe ser LOCAL o JWT_CORPORATIVO.',
      ),
    };
  }

  bool get usesLocalCredentials => this == IdentityProvider.local;
}
