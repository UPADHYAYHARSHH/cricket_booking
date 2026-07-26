import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  Future<void> deleteUserAccount();
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

    debugPrint("[USER_REPO] Supabase URL: ${supabase.rest.url}");

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

    // Primary: Use SECURITY DEFINER RPC function to bypass RLS.
    // The RLS policy on `users` requires auth.email() which returns null
    // for Firebase Auth users, so direct upserts are blocked by RLS.
    try {
      await supabase.rpc('upsert_user_profile', params: {
        'p_id': user.uid,
        'p_name': name,
        'p_email': user.email ?? '',
        'p_gender': gender,
        'p_dob': dob?.toIso8601String() ?? '',
        'p_username': username ?? '',
      });
      return;
    } catch (rpcError) {
      debugPrint("[USER_REPO] RPC upsert_user_profile failed: $rpcError");
      // If the RPC function doesn't exist, throw a clear actionable error
      throw Exception(
        "The upsert_user_profile database function is missing or not deployed. "
        "Please run the SQL in supabase/upsert_user_function.sql in your Supabase SQL Editor.",
      );
    }
  }

  @override
  Future<Map<String, dynamic>?> fetchUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    debugPrint("[USER_REPO] Fetching profile for ID: ${user?.uid}");
    if (user == null) return null;

    try {
      final response = await supabase
          .rpc('get_user_profile', params: {'p_id': user.uid})
          .timeout(const Duration(seconds: 10));

      debugPrint("[USER_REPO] Profile Data Received: $response");
      return response as Map<String, dynamic>?;
    } catch (e) {
      debugPrint("[USER_REPO] Error in fetchUserProfile: $e");
      rethrow;
    }
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
            fileOptions:
                const FileOptions(contentType: 'image/jpeg', upsert: true),
          );

      final String publicUrl =
          supabase.storage.from('avatars').getPublicUrl(path);
      // Ensure url is returning with a cache buster if it's updated rapidly
      return "$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}";
    } catch (e) {
      print("Storage Upload Error: $e");
      throw Exception(
          "Failed to upload image. Make sure 'avatars' bucket exists and RLS allows it.");
    }
  }

  /// FETCH PERSISTED CITY FROM SUPABASE USERS TABLE (AND LOCAL CACHE)
  @override
  Future<String?> getUserCity() async {
    // 1. Try local cache first for instant load and offline support
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedCity = prefs.getString('user_city');
      if (cachedCity != null && cachedCity.isNotEmpty) {
        return cachedCity;
      }
    } catch (e) {
      debugPrint("[USER_REPO] Local cache read error: $e");
    }

    // 2. Fallback to Supabase if not in local cache
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    try {
      final data = await supabase
          .from('users')
          .select('city')
          .eq('id', user.uid)
          .maybeSingle();
      
      final dbCity = data?['city'];
      
      // Cache it locally for next time
      if (dbCity != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_city', dbCity);
      }
      
      return dbCity;
    } catch (e) {
      debugPrint("[USER_REPO] Supabase city fetch error: $e");
      return null; // Return null safely instead of throwing
    }
  }

  /// SAVE OR UPDATE CITY IN SUPABASE USERS TABLE (AND LOCAL CACHE)
  @override
  Future<void> updateUserCity(String city) async {
    // 1. Save to local cache immediately
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_city', city);
    } catch (e) {
      debugPrint("[USER_REPO] Local cache write error: $e");
    }

    // 2. Save to Supabase using RPC to bypass RLS issues
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await supabase.rpc('update_user_city', params: {
        'p_id': user.uid,
        'p_city': city,
      });
      debugPrint("[USER_REPO] Successfully saved city to Supabase DB via RPC");
    } catch (e) {
      debugPrint("[USER_REPO] Error updating city in Supabase: $e");
    }
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
    print(
        "[DEBUG] UserRepository: Executing Supabase search for username: '%$query%'");
    final response = await supabase
        .from('users')
        .select('id, name, username')
        .ilike('username', '%$query%')
        .limit(20);
    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Future<void> deleteUserAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("User not logged in");
    }

    final uid = user.uid;

    try {
      // 1. Delete associated data from Supabase atomically via RPC
      // This bypasses RLS constraints using SECURITY DEFINER and handles all FKs
      try {
        await supabase
            .rpc('delete_user_and_data', params: {'user_id_text': uid});
      } catch (e) {
        print('Supabase RPC delete error: $e');
        throw Exception('Database deletion failed: $e');
      }

      // 2. Delete from Firebase Auth
      await user.delete();

      // 4. Ensure sign out
      await FirebaseAuth.instance.signOut();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw Exception(
            'For security reasons, please log out and log back in before deleting your account.');
      }
      throw Exception('Failed to delete account: ${e.message}');
    } catch (e) {
      throw Exception('Failed to delete account data: $e');
    }
  }
}
