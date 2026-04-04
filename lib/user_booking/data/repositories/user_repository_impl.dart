import 'package:supabase_flutter/supabase_flutter.dart';

abstract class UserRepository {
  Future<void> upsertUser({
    required String name,
    required String gender,
    required DateTime? dob,
  });

  /// ✅ ADD THESE TWO METHODS
  Future<String?> getUserCity();
  Future<void> updateUserCity(String city);
}

class UserRepositoryImpl implements UserRepository {
  final SupabaseClient supabase;

  UserRepositoryImpl(this.supabase);

  @override
  Future<void> upsertUser({
    required String name,
    required String gender,
    required DateTime? dob,
  }) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception("User not logged in");
    }

    await supabase.from('users').upsert({
      'id': user.id,
      'name': name,
      'email': user.email, // ✅ always from auth
      'gender': gender,
      'dob': dob?.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  /// FETCH PERSISTED CITY FROM SUPABASE USERS TABLE
  @override
  Future<String?> getUserCity() async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;

    final data = await supabase.from('users').select('city').eq('id', user.id).maybeSingle();

    return data?['city'];
  }

  /// SAVE OR UPDATE CITY IN SUPABASE USERS TABLE
  @override
  Future<void> updateUserCity(String city) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    await supabase.from('users').upsert({
      'id': user.id,
      'city': city,
    });
  }
}
