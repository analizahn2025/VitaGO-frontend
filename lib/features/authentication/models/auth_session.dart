import 'package:vitago_app/features/authentication/models/auth_user.dart';
import 'package:vitago_app/features/authentication/models/token_bundle.dart';

class AuthSession {
  const AuthSession({required this.tokens, required this.user});

  factory AuthSession.fromLoginResponse(Map<String, dynamic> json) {
    final userJson = json['usuario'];
    if (userJson is! Map<String, dynamic>) {
      throw const FormatException(
        'El usuario no está presente en la respuesta de autenticación.',
      );
    }

    return AuthSession(
      tokens: TokenBundle.fromJson(json),
      user: AuthUser.fromJson(userJson),
    );
  }

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final tokenJson = json['tokens'];
    final userJson = json['usuario'];
    if (tokenJson is! Map<String, dynamic> ||
        userJson is! Map<String, dynamic>) {
      throw const FormatException('La sesión almacenada no es válida.');
    }

    return AuthSession(
      tokens: TokenBundle.fromJson(tokenJson),
      user: AuthUser.fromJson(userJson),
    );
  }

  final TokenBundle tokens;
  final AuthUser user;

  AuthSession withTokens(TokenBundle newTokens) {
    return AuthSession(tokens: newTokens, user: user);
  }

  Map<String, dynamic> toJson() => {
    'tokens': tokens.toJson(),
    'usuario': user.toJson(),
  };
}
