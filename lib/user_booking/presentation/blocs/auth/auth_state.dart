abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthOtpRequired extends AuthState {
  final String phone;
  AuthOtpRequired(this.phone);
}

class AuthEmailOtpRequired extends AuthState {
  final String email;
  AuthEmailOtpRequired(this.email);
}

class AuthMagicLinkSent extends AuthState {
  final String email;
  AuthMagicLinkSent(this.email);
}

class AuthVerified extends AuthState {}

class AuthProfileIncomplete extends AuthState {}

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
