import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../domain/repositories/auth_repositories.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth firebaseAuth;

  AuthRepositoryImpl(this.firebaseAuth);

  /// Creates or signs into a Supabase Auth session using the same email/password
  /// as Firebase Auth. This ensures `auth.email()` works in Supabase RLS policies.
  Future<void> _syncSupabaseSession(String email, String password) async {
    try {
      // Try to sign in first (most common case for returning users)
      await sb.Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      print("DEBUG: [AuthRepository] Supabase session created via signIn");
    } catch (e) {
      // If sign in fails (user doesn't exist in Supabase), sign up
      try {
        await sb.Supabase.instance.client.auth.signUp(
          email: email,
          password: password,
        );
        print("DEBUG: [AuthRepository] Supabase session created via signUp");
      } catch (signUpError) {
        // If both fail, log but don't block the app flow
        // The user can still use the app, just RLS may not work until next login
        print("WARNING: [AuthRepository] Could not create Supabase session: $signUpError");
      }
    }
  }

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
        throw FirebaseAuthException(
            code: 'user-null', message: 'Login failed - user null');
      }

      // Create Supabase Auth session for RLS policies
      await _syncSupabaseSession(email, password);

      print(
          "DEBUG: [AuthRepository] Login success. Verified: ${userCredential.user?.emailVerified}");
    } on FirebaseAuthException catch (e) {
      print(
          "DEBUG: [AuthRepository] Firebase AuthException: ${e.code} - ${e.message}");
      rethrow;
    } catch (e) {
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
        throw FirebaseAuthException(
            code: 'signup-failed', message: 'Signup failed');
      }

      // Create Supabase Auth session for RLS policies
      await _syncSupabaseSession(email, password);

      // Send verification email
      print("DEBUG: [AuthRepository] Sending verification email to: $email");
      await userCredential.user?.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      print(
          "DEBUG: [AuthRepository] Firebase AuthException during signup: ${e.code}");
      rethrow;
    } catch (e) {
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
      print(
          "DEBUG: [AuthRepository] Firebase AuthException during reset: ${e.message}");
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

        // Update Supabase password too
        try {
          await sb.Supabase.instance.client.auth.updateUser(
            sb.UserAttributes(password: newPassword),
          );
        } catch (_) {
          print("WARNING: [AuthRepository] Could not update Supabase password");
        }
      } else {
        throw FirebaseAuthException(
            code: 'no-user', message: 'No user signed in');
      }
    } on FirebaseAuthException catch (e) {
      print(
          "DEBUG: [AuthRepository] Firebase AuthException during update: ${e.message}");
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    await firebaseAuth.signOut();
    // Sign out from Supabase Auth too
    await sb.Supabase.instance.client.auth.signOut();
  }
}
