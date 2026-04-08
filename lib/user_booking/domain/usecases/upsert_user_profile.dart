import '../../data/repositories/user_repository_impl.dart';

class UpsertUserProfile {
  final UserRepository repository;

  UpsertUserProfile(this.repository);

  Future<void> call({
    required String name,
    required String gender,
    required DateTime? dob,
    String? photoUrl,
  }) {
    return repository.upsertUser(
      name: name,
      gender: gender,
      dob: dob,
      photoUrl: photoUrl,
    );
  }
}
