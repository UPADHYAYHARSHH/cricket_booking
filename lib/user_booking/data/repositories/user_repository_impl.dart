import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class UserRepository {
  Future<void> upsertUser({
    required String name,
    required String gender,
    required DateTime? dob,
    String? photoUrl,
    String? username,
  });

  Future<Map<String, dynamic>?> fetchUserProfile();
  Future<String?> uploadProfileImage(File imageFile);
  Future<String?> getUserCity();
  Future<void> updateUserCity(String city);
  Future<bool> isUsernameAvailable(String username);
  Future<List<Map<String, dynamic>>> searchUsersByUsername(String query);
}

class UserRepositoryImpl implements UserRepository {
  final SupabaseClient supabase;

  UserRepositoryImpl(this.supabase);

  @override
  Future<void> upsertUser({
    required String name,
    required String gender,
    required DateTime? dob,
    String? photoUrl,
    String? username,
  }) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception("User not logged in");
    }

    final data = {
      'id': user.id,
      'name': name,
      'email': user.email,
      'gender': gender,
      'dob': dob?.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (photoUrl != null) {
      data['photo_url'] = photoUrl;
    }

    if (username != null) {
      data['username'] = username;
    }

    await supabase.from('users').upsert(data);
  }

  @override
  Future<Map<String, dynamic>?> fetchUserProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;

    final response = await supabase
        .from('users')
        .select()
        .eq('id', user.id)
        .maybeSingle();
    
    return response;
  }

  @override
  Future<String?> uploadProfileImage(File imageFile) async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;

    final fileName = '${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final path = 'profile_images/$fileName';

    await supabase.storage.from('avatars').upload(path, imageFile);

    final String publicUrl = supabase.storage.from('avatars').getPublicUrl(path);
    return publicUrl;
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

  @override
  Future<bool> isUsernameAvailable(String username) async {
    final response = await supabase
        .from('users')
        .select('id')
        .eq('username', username)
        .maybeSingle();
    return response == null;
  }

  @override
  Future<List<Map<String, dynamic>>> searchUsersByUsername(String query) async {
    print("[DEBUG] UserRepository: Executing Supabase search for username: '%$query%'");
    // Removed photo_url to prevent crash if column is missing. 
    // You should add the column via SQL to see photos.
    final response = await supabase
        .from('users')
        .select('id, name, username') 
        .ilike('username', '%$query%')
        .limit(20);
    print("[DEBUG] UserRepository: Supabase Response Type: ${response.runtimeType}");
    print("[DEBUG] UserRepository: Supabase Raw Result: $response");
    return List<Map<String, dynamic>>.from(response);
  }
}
