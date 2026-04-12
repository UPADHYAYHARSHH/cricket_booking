abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthOtpRequired extends AuthState {
  final String email;
  AuthOtpRequired(this.email);
}

class AuthSuccess extends AuthState {}

class AuthPasswordResetEmailSent extends AuthState {
  final String email;
  AuthPasswordResetEmailSent(this.email);
}

class AuthPasswordResetOtpVerified extends AuthState {}

class AuthPasswordUpdated extends AuthState {}

class AuthError extends AuthState {
  final String message;

  AuthError(this.message);
}
