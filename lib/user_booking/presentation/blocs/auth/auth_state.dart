abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthOtpRequired extends AuthState {
  final String email;
  AuthOtpRequired(this.email);
}

class AuthSuccess extends AuthState {}

class AuthError extends AuthState {
  final String message;

  AuthError(this.message);
}
