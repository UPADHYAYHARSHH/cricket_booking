abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class OTPCodeSent extends AuthState {
  final String verificationId;

  OTPCodeSent(this.verificationId);
}

class AuthSuccess extends AuthState {}

class AuthError extends AuthState {
  final String message;

  AuthError(this.message);
}
