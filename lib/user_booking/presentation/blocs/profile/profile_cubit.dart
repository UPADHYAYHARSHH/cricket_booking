import 'dart:io';
import 'package:bloc_structure/user_booking/data/repositories/user_repository_impl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/upsert_user_profile.dart';

class ProfileState {
  final bool isLoading;
  final bool isSuccess;
  final String? error;
  final String? name;
  final String? gender;
  final DateTime? dob;
  final String? photoUrl;

  ProfileState({
    this.isLoading = false,
    this.isSuccess = false,
    this.error,
    this.name,
    this.gender,
    this.dob,
    this.photoUrl,
  });

  ProfileState copyWith({
    bool? isLoading,
    bool? isSuccess,
    String? error,
    String? name,
    String? gender,
    DateTime? dob,
    String? photoUrl,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      error: error,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      dob: dob ?? this.dob,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}

class ProfileCubit extends Cubit<ProfileState> {
  final UpsertUserProfile upsertUserProfile;
  final UserRepository userRepository;

  ProfileCubit(this.upsertUserProfile, this.userRepository) : super(ProfileState());

  Future<void> loadProfile() async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final data = await userRepository.fetchUserProfile();
      if (data != null) {
        emit(state.copyWith(
          isLoading: false,
          name: data['name'],
          gender: data['gender'],
          dob: data['dob'] != null ? DateTime.parse(data['dob']) : null,
          photoUrl: data['photo_url'],
        ));
      } else {
        emit(state.copyWith(isLoading: false));
      }
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> saveProfile({
    required String name,
    required String gender,
    required DateTime? dob,
    String? photoUrl,
  }) async {
    emit(state.copyWith(isLoading: true));

    try {
      await upsertUserProfile(
        name: name,
        gender: gender,
        dob: dob,
        photoUrl: photoUrl,
      );

      emit(state.copyWith(
        isLoading: false, 
        isSuccess: true,
        name: name,
        gender: gender,
        dob: dob,
        photoUrl: photoUrl ?? state.photoUrl,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> uploadImage(File file) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final url = await userRepository.uploadProfileImage(file);
      if (url != null) {
        await saveProfile(
          name: state.name ?? '',
          gender: state.gender ?? 'Other',
          dob: state.dob,
          photoUrl: url,
        );
      } else {
        emit(state.copyWith(isLoading: false, error: "Failed to upload image"));
      }
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }
}
