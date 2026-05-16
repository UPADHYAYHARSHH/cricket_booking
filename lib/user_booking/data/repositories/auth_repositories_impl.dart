import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/repositories/auth_repositories.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth firebaseAuth;

  AuthRepositoryImpl(this.firebaseAuth);

  @override
  Future<void> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      print("DEBUG: [AuthRepository] Firebase login for: $email");

      final userCredential = await firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw FirebaseAuthException(code: 'user-null', message: 'Login failed - user null');
      }
      
      // We check verification status in the Cubit, but we can log it here
      print("DEBUG: [AuthRepository] Login success. Verified: ${userCredential.user?.emailVerified}");
      
    } on FirebaseAuthException catch (e) {
      print("DEBUG: [AuthRepository] Firebase AuthException: ${e.code} - ${e.message}");
      rethrow;
    } catch (e, st) {
      print("DEBUG: [AuthRepository] Unexpected error: $e");
      rethrow;
    }
  }

  @override
  Future<void> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      print("DEBUG: [AuthRepository] Firebase signup for: $email");
      
      final userCredential = await firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw FirebaseAuthException(code: 'signup-failed', message: 'Signup failed');
      }

      // Send verification email
      print("DEBUG: [AuthRepository] Sending verification email to: $email");
      await userCredential.user?.sendEmailVerification();

    } on FirebaseAuthException catch (e) {
      print("DEBUG: [AuthRepository] Firebase AuthException during signup: ${e.code}");
      rethrow;
    } catch (e, st) {
      print("DEBUG: [AuthRepository] Unexpected error during signup: $e");
      rethrow;
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      print("DEBUG: [AuthRepository] Firebase password reset for: $email");
      await firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      print("DEBUG: [AuthRepository] Firebase AuthException during reset: ${e.message}");
      rethrow;
    } catch (e) {
      print("DEBUG: [AuthRepository] Unexpected error during reset: $e");
      rethrow;
    }
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    try {
      print("DEBUG: [AuthRepository] Firebase updatePassword");
      final user = firebaseAuth.currentUser;
      if (user != null) {
        await user.updatePassword(newPassword);
      } else {
        throw FirebaseAuthException(code: 'no-user', message: 'No user signed in');
      }
    } on FirebaseAuthException catch (e) {
      print("DEBUG: [AuthRepository] Firebase AuthException during update: ${e.message}");
      rethrow;
    } catch (e) {
      print("DEBUG: [AuthRepository] Unexpected error during update: $e");
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    await firebaseAuth.signOut();
  }
}
