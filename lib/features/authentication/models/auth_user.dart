class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.firstNames,
    required this.lastNames,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: _requiredString(json, 'id'),
      email: _requiredString(json, 'correo'),
      firstNames: _requiredString(json, 'nombres'),
      lastNames: _requiredString(json, 'apellidos'),
    );
  }

  final String id;
  final String email;
  final String firstNames;
  final String lastNames;

  String get fullName => '$firstNames $lastNames'.trim();

  Map<String, dynamic> toJson() => {
    'id': id,
    'correo': email,
    'nombres': firstNames,
    'apellidos': lastNames,
  };

  static String _requiredString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('El campo $key no está presente en la respuesta.');
    }
    return value;
  }
}
