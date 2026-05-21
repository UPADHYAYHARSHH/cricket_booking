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
    try {
      final response = await _supabase.from('favorites')
          .select('ground_id')
          .eq('user_id', userId);
      
      final ids = (response as List).map((e) => e['ground_id'].toString()).toList();
      debugPrint("[WISHLIST_REPO] Loaded ${ids.length} ground IDs from public schema");
      return ids;
    } catch (e) {
      debugPrint("[WISHLIST_REPO] Public schema fetch error: $e");
      return [];
    }
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
      rethrow;
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
      rethrow;
    }
  }
}
