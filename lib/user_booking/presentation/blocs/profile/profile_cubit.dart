import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/upsert_user_profile.dart';

class ProfileState {
  final bool isLoading;
  final bool isSuccess;
  final String? error;

  ProfileState({
    this.isLoading = false,
    this.isSuccess = false,
    this.error,
  });

  ProfileState copyWith({
    bool? isLoading,
    bool? isSuccess,
    String? error,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      error: error,
    );
  }
}

class ProfileCubit extends Cubit<ProfileState> {
  final UpsertUserProfile upsertUserProfile;

  ProfileCubit(this.upsertUserProfile) : super(ProfileState());

  Future<void> saveProfile({
    required String name,
    required String gender,
    required DateTime? dob,
  }) async {
    emit(state.copyWith(isLoading: true));

    try {
      await upsertUserProfile(
        name: name,
        gender: gender,
        dob: dob,
      );

      emit(state.copyWith(isLoading: false, isSuccess: true));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }
}
