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

  @override
  Future<List<String>> fetchFavoriteIds(String userId) async {
    debugPrint("[WISHLIST_REPO] Fetching favorites for user: $userId");
    try {
      final response = await _supabase.rpc('get_favorite_ids', params: {
        'p_user_id': userId,
      });
      
      final List data = response as List;
      final ids = data.map((e) => e.toString()).toList();
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
      await _supabase.rpc('add_favorite', params: {
        'p_user_id': userId,
        'p_ground_id': groundId,
      });
      debugPrint("[WISHLIST_REPO] Add favorite successful via RPC");
    } catch (e) {
      debugPrint("[WISHLIST_REPO] ERROR adding favorite: $e");
      rethrow;
    }
  }

  @override
  Future<void> removeFavorite(String userId, String groundId) async {
    debugPrint("[WISHLIST_REPO] Removing favorite: user $userId, ground $groundId");
    try {
      await _supabase.rpc('remove_favorite', params: {
        'p_user_id': userId,
        'p_ground_id': groundId,
      });
      debugPrint("[WISHLIST_REPO] Remove favorite successful via RPC");
    } catch (e) {
      debugPrint("[WISHLIST_REPO] ERROR removing favorite: $e");
      rethrow;
    }
  }
}
