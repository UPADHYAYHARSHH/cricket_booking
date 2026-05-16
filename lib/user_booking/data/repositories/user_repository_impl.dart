import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract class UserRepository {
  Future<void> upsertUser({
    required String name,
    required String gender,
    required DateTime? dob,
    String? photoUrl,
    String? username,
  });

  Future<Map<String, dynamic>?> fetchUserProfile();
  Future<String?> uploadProfileImage(Uint8List imageBytes);
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
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception("User not logged in");
    }

    final data = {
      'id': user.uid,
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

    try {
      await supabase.from('users').upsert(data);
    } catch (e) {
      // Fallback in case "photo_url" column does not exist yet.
      if (photoUrl != null && e.toString().contains('photo_url')) {
        print("Warning: photo_url column missing, falling back to without it.");
        data.remove('photo_url');
        await supabase.from('users').upsert(data);
      } else {
        rethrow;
      }
    }
  }

  @override
  Future<Map<String, dynamic>?> fetchUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    debugPrint("[USER_REPO] Fetching profile for ID: ${user?.uid}");
    if (user == null) return null;

    final response = await supabase
        .from('users')
        .select()
        .eq('id', user.uid)
        .maybeSingle();
    
    debugPrint("[USER_REPO] Profile Data Received: $response");
    return response;
  }

  @override
  Future<String?> uploadProfileImage(Uint8List imageBytes) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final fileName = '${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final path = 'profile_images/$fileName';

    try {
      await supabase.storage.from('avatars').uploadBinary(
        path,
        imageBytes,
        fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
      );

      final String publicUrl = supabase.storage.from('avatars').getPublicUrl(path);
      // Ensure url is returning with a cache buster if it's updated rapidly
      return "$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}";
    } catch (e) {
      print("Storage Upload Error: $e");
      throw Exception("Failed to upload image. Make sure 'avatars' bucket exists and RLS allows it.");
    }
  }

  /// FETCH PERSISTED CITY FROM SUPABASE USERS TABLE
  @override
  Future<String?> getUserCity() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final data = await supabase.from('users').select('city').eq('id', user.uid).maybeSingle();

    return data?['city'];
  }

  /// SAVE OR UPDATE CITY IN SUPABASE USERS TABLE
  @override
  Future<void> updateUserCity(String city) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await supabase.from('users').upsert({
      'id': user.uid,
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
    final response = await supabase
        .from('users')
        .select('id, name, username') 
        .ilike('username', '%$query%')
        .limit(20);
    return List<Map<String, dynamic>>.from(response);
  }
}
