import 'package:turfpro/user_booking/data/repositories/user_repository_impl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../domain/usecases/upsert_user_profile.dart';

class ProfileState {
  final bool isLoading;
  final bool isSuccess;
  final String? error;
  final String? name;
  final String? gender;
  final DateTime? dob;
  final String? photoUrl;
  final String? username;
  final bool? isUsernameAvailable;
  final String? lastCheckedUsername;

  ProfileState({
    this.isLoading = false,
    this.isSuccess = false,
    this.error,
    this.name,
    this.gender,
    this.dob,
    this.photoUrl,
    this.username,
    this.isUsernameAvailable,
    this.lastCheckedUsername,
  });

  ProfileState copyWith({
    bool? isLoading,
    bool? isSuccess,
    String? error,
    String? name,
    String? gender,
    DateTime? dob,
    String? photoUrl,
    String? username,
    bool? isUsernameAvailable,
    String? lastCheckedUsername,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      error: error,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      dob: dob ?? this.dob,
      photoUrl: photoUrl ?? this.photoUrl,
      username: username ?? this.username,
      isUsernameAvailable: isUsernameAvailable ?? this.isUsernameAvailable,
      lastCheckedUsername: lastCheckedUsername ?? this.lastCheckedUsername,
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
        String? username = data['username'];
        
        // Auto-generate username if null
        if (username == null || username.isEmpty) {
          username = await _generateUniqueUsername(data['name'] ?? 'user');
          // Save it automatically
          await userRepository.upsertUser(
            name: data['name'] ?? '',
            gender: data['gender'] ?? 'Other',
            dob: data['dob'] != null ? DateTime.parse(data['dob']) : null,
            photoUrl: data['photo_url'],
            username: username,
          );
        }

        emit(state.copyWith(
          isLoading: false,
          name: data['name'],
          gender: data['gender'],
          dob: data['dob'] != null ? DateTime.parse(data['dob']) : null,
          photoUrl: data['photo_url'],
          username: username,
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
    String? username,
  }) async {
    emit(state.copyWith(isLoading: true));

    try {
      await upsertUserProfile(
        name: name,
        gender: gender,
        dob: dob,
        photoUrl: photoUrl,
        username: username,
      );

      emit(state.copyWith(
        isLoading: false, 
        isSuccess: true,
        name: name,
        gender: gender,
        dob: dob,
        photoUrl: photoUrl ?? state.photoUrl,
        username: username ?? state.username,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> uploadImage(XFile file) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final bytes = await file.readAsBytes();
      final url = await userRepository.uploadProfileImage(bytes);
      if (url != null) {
        await saveProfile(
          name: state.name ?? '',
          gender: state.gender ?? 'Other',
          dob: state.dob,
          photoUrl: url,
          username: state.username,
        );
      } else {
        emit(state.copyWith(isLoading: false, error: "Failed to upload image"));
      }
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> checkUsernameAvailability(String username) async {
    if (username == state.username) {
      emit(state.copyWith(isUsernameAvailable: true, lastCheckedUsername: username));
      return;
    }
    
    if (username.length < 3) {
      emit(state.copyWith(isUsernameAvailable: false, lastCheckedUsername: username));
      return;
    }

    try {
      final available = await userRepository.isUsernameAvailable(username);
      emit(state.copyWith(isUsernameAvailable: available, lastCheckedUsername: username));
    } catch (e) {
      // Silently fail or log
    }
  }

  Future<String> _generateUniqueUsername(String name) async {
    final cleanName = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final base = cleanName.isEmpty ? 'user' : cleanName;
    
    // Try base name first if it's long enough
    if (base.length >= 3) {
      if (await userRepository.isUsernameAvailable(base)) return base;
    }

    // Add random suffix
    while (true) {
      final random = (1000 + (9999 - 1000) * (DateTime.now().microsecond / 1000000)).toInt();
      final candidate = '${base}_$random';
      if (await userRepository.isUsernameAvailable(candidate)) return candidate;
    }
  }
}
