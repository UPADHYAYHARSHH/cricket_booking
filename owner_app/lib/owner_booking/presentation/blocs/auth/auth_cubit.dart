import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(AuthInitial());

  Future<void> signInWithPhone(String phone) async {
    emit(AuthLoading());
    try {
      await Supabase.instance.client.auth.signInWithOtp(
        phone: phone,
      );
      emit(AuthOtpRequired(phone));
    } on AuthException catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> verifyOtp(String phone, String token) async {
    emit(AuthLoading());
    try {
      final response = await Supabase.instance.client.auth.verifyOTP(
        phone: phone,
        token: token,
        type: OtpType.sms,
      );
      
      if (response.user != null) {
        await checkDocumentStatus();
      } else {
        emit(AuthError("Verification failed"));
      }
    } on AuthException catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> checkDocumentStatus() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      emit(AuthInitial());
      return;
    }

    try {
      final data = await Supabase.instance.client
          .from('owner_details')
          .select('pan_url, aadhar_url')
          .eq('id', user.id)
          .maybeSingle();

      if (data == null || data['pan_url'] == null || data['aadhar_url'] == null) {
        emit(AuthDocumentsRequired());
      } else {
        emit(AuthSuccess());
      }
    } catch (e) {
      emit(AuthDocumentsRequired());
    }
  }

  Future<void> uploadDocuments({
    required String businessName,
    required String businessEmail,
    required String ownerName,
    required String phone,
    required String address,
    required String panUrl,
    required String aadharUrl,
    required double latitude,
    required double longitude,
    String? businessRegUrl,
  }) async {
    emit(AuthLoading());
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      await Supabase.instance.client.from('owner_details').upsert({
        'id': user.id,
        'business_name': businessName,
        'business_email': businessEmail,
        'owner_name': ownerName,
        'phone': phone,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'pan_url': panUrl,
        'aadhar_url': aadharUrl,
        'business_reg_url': businessRegUrl,
        'updated_at': DateTime.now().toIso8601String(),
      });
      emit(AuthSuccess());
    } catch (e) {
      emit(AuthError("Failed to upload documents: ${e.toString()}"));
    }
  }

  Future<void> savePartialDetails({
    required String businessName,
    required String businessEmail,
    required String ownerName,
    required String phone,
    String? panUrl,
    String? aadharUrl,
    String? businessRegUrl,
  }) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      await Supabase.instance.client.from('owner_details').upsert({
        'id': user.id,
        'business_name': businessName,
        'business_email': businessEmail,
        'owner_name': ownerName,
        'phone': phone,
        if (panUrl != null) 'pan_url': panUrl,
        if (aadharUrl != null) 'aadhar_url': aadharUrl,
        if (businessRegUrl != null) 'business_reg_url': businessRegUrl,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print("Partial save error: $e");
    }
  }

  void emitLoading() => emit(AuthLoading());
  void emitError(String message) => emit(AuthError(message));

  Future<void> logout() async {
    await Supabase.instance.client.auth.signOut();
    emit(AuthInitial());
  }
}
