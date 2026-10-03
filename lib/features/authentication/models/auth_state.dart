import 'package:vitago_app/features/authentication/models/auth_session.dart';

enum AuthenticationStatus {
  unauthenticated,
  authenticated,
  corporateAuthenticationRequired,
}

class AuthState {
  const AuthState._({
    required this.status,
    this.session,
    this.message,
    this.fieldErrors = const {},
    this.isProcessing = false,
  });

  const AuthState.unauthenticated({
    String? message,
    Map<String, List<String>> fieldErrors = const {},
    bool isProcessing = false,
  }) : this._(
         status: AuthenticationStatus.unauthenticated,
         message: message,
         fieldErrors: fieldErrors,
         isProcessing: isProcessing,
       );

  const AuthState.authenticated(
    AuthSession session, {
    String? message,
    bool isProcessing = false,
  }) : this._(
         status: AuthenticationStatus.authenticated,
         session: session,
         message: message,
         isProcessing: isProcessing,
       );

  const AuthState.corporateAuthenticationRequired()
    : this._(status: AuthenticationStatus.corporateAuthenticationRequired);

  final AuthenticationStatus status;
  final AuthSession? session;
  final String? message;
  final Map<String, List<String>> fieldErrors;
  final bool isProcessing;
}
