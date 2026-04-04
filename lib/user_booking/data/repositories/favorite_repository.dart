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
    print("[WISHLIST_REPO] Fetching from honors/favorites for user: $userId");
    try {
      final response = await _supabase
          .from('favorites')
          .select('ground_id')
          .eq('user_id', userId);

      final ids = (response as List).map((e) => e['ground_id'] as String).toList();
      print("[WISHLIST_REPO] Query returned ${ids.length} ground IDs");
      return ids;
    } catch (e) {
      print("[WISHLIST_REPO] ERROR fetching favorite IDs: $e");
      rethrow;
    }
  }

  @override
  Future<void> addFavorite(String userId, String groundId) async {
    print("[WISHLIST_REPO] Adding favorite in DB: user $userId, ground $groundId");
    try {
      await _supabase.from('favorites').upsert({
        'user_id': userId,
        'ground_id': groundId,
      });
      print("[WISHLIST_REPO] Upsert successful");
    } catch (e) {
      print("[WISHLIST_REPO] ERROR adding favorite: $e");
      rethrow;
    }
  }

  @override
  Future<void> removeFavorite(String userId, String groundId) async {
    print("[WISHLIST_REPO] Deleting favorite in DB: user $userId, ground $groundId");
    try {
      await _supabase
          .from('favorites')
          .delete()
          .eq('user_id', userId)
          .eq('ground_id', groundId);
      print("[WISHLIST_REPO] Delete successful");
    } catch (e) {
      print("[WISHLIST_REPO] ERROR removing favorite: $e");
      rethrow;
    }
  }
}
