import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class FavoriteRepository {
  Future<List<String>> fetchFavoriteIds(String userId);
  Future<void> addFavorite(String userId, String groundId);
  Future<void> removeFavorite(String userId, String groundId);
}

class FavoriteRepositoryImpl implements FavoriteRepository {
  final SupabaseClient _supabase;

  FavoriteRepositoryImpl(this._supabase);

  // Helper to get the correct table reference (handles potential schema)
  PostgrestQueryBuilder get _favoritesTable => _supabase.from('favorites');

  @override
  Future<List<String>> fetchFavoriteIds(String userId) async {
    debugPrint("[WISHLIST_REPO] Fetching favorites for user: $userId");
    List<String> allIds = [];

    // 1. Try Public Schema
    try {
      final response = await _supabase.from('favorites')
          .select('ground_id')
          .eq('user_id', userId);
      
      final ids = (response as List).map((e) => e['ground_id'].toString()).toList();
      if (ids.isNotEmpty) {
        debugPrint("[WISHLIST_REPO] Loaded ${ids.length} ground IDs from public schema");
        return ids;
      }
    } catch (e) {
      debugPrint("[WISHLIST_REPO] Public schema fetch error (might not exist): $e");
    }

    // 2. Try Honors Schema (Fallback or if public was empty)
    try {
      debugPrint("[WISHLIST_REPO] Checking 'honors' schema...");
      final honorsResponse = await _supabase.schema('honors')
          .from('favorites')
          .select('ground_id')
          .eq('user_id', userId);
      
      final ids = (honorsResponse as List).map((e) => e['ground_id'].toString()).toList();
      if (ids.isNotEmpty) {
        debugPrint("[WISHLIST_REPO] Loaded ${ids.length} ground IDs from honors schema");
        return ids;
      }
    } catch (e) {
      debugPrint("[WISHLIST_REPO] Honors schema fetch error: $e");
    }

    return [];
  }

  @override
  Future<void> addFavorite(String userId, String groundId) async {
    debugPrint("[WISHLIST_REPO] Adding favorite: user $userId, ground $groundId");
    try {
      // Use upsert with onConflict to avoid duplicates and handle constraints
      await _favoritesTable.upsert({
        'user_id': userId,
        'ground_id': groundId,
      }, onConflict: 'user_id,ground_id');
      
      debugPrint("[WISHLIST_REPO] Upsert successful in public schema");
    } catch (e) {
      debugPrint("[WISHLIST_REPO] ERROR adding favorite: $e");
      // Try honors schema fallback
      try {
        await _supabase.schema('honors').from('favorites').upsert({
          'user_id': userId,
          'ground_id': groundId,
        }, onConflict: 'user_id,ground_id');
        debugPrint("[WISHLIST_REPO] Upsert successful in honors schema");
      } catch (innerError) {
        debugPrint("[WISHLIST_REPO] honors schema upsert failed: $innerError");
        rethrow;
      }
    }
  }

  @override
  Future<void> removeFavorite(String userId, String groundId) async {
    debugPrint("[WISHLIST_REPO] Removing favorite: user $userId, ground $groundId");
    try {
      await _favoritesTable
          .delete()
          .eq('user_id', userId)
          .eq('ground_id', groundId);
      debugPrint("[WISHLIST_REPO] Delete successful in public schema");
    } catch (e) {
      debugPrint("[WISHLIST_REPO] ERROR removing favorite: $e");
      // Try honors schema fallback
      try {
        await _supabase.schema('honors')
            .from('favorites')
            .delete()
            .eq('user_id', userId)
            .eq('ground_id', groundId);
        debugPrint("[WISHLIST_REPO] Delete successful in honors schema");
      } catch (innerError) {
        debugPrint("[WISHLIST_REPO] honors schema delete failed: $innerError");
        rethrow;
      }
    }
  }
}
