import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/favorite_repository.dart';

abstract class SavedGroundState {
  final List<String> favoriteIds;
  SavedGroundState(this.favoriteIds);
}

class SavedGroundInitial extends SavedGroundState {
  SavedGroundInitial() : super([]);
}

class SavedGroundLoading extends SavedGroundState {
  SavedGroundLoading(super.favoriteIds);
}

class SavedGroundLoaded extends SavedGroundState {
  SavedGroundLoaded(super.favoriteIds);
}

class SavedGroundError extends SavedGroundState {
  final String message;
  SavedGroundError(this.message, super.favoriteIds);
}

class SavedGroundCubit extends Cubit<SavedGroundState> {
  final FavoriteRepository _repository;

  SavedGroundCubit(this._repository) : super(SavedGroundInitial());

  Future<void> loadFavorites(String userId) async {
    print("[WISHLIST_CUBIT] Requesting favorites for User: $userId");
    emit(SavedGroundLoading(state.favoriteIds));
    try {
      final ids = await _repository.fetchFavoriteIds(userId);
      print("[WISHLIST_CUBIT] Loaded ${ids.length} favorites from Supabase: $ids");
      emit(SavedGroundLoaded(ids));
    } catch (e) {
      print("[WISHLIST_CUBIT] ERROR loading favorites: $e");
      emit(SavedGroundError(e.toString(), state.favoriteIds));
    }
  }

  Future<void> toggleFavorite(String userId, String groundId) async {
    final isFavorite = state.favoriteIds.contains(groundId);
    final action = isFavorite ? "REMOVING" : "ADDING";
    print("[WISHLIST_CUBIT] $action favorite - User: $userId, Ground: $groundId");
    
    final updatedIds = List<String>.from(state.favoriteIds);

    if (isFavorite) {
      updatedIds.remove(groundId);
    } else {
      updatedIds.add(groundId);
    }

    // Optimistic update
    emit(SavedGroundLoaded(updatedIds));

    try {
      if (isFavorite) {
        await _repository.removeFavorite(userId, groundId);
        print("[WISHLIST_CUBIT] Successfully removed from Supabase");
      } else {
        await _repository.addFavorite(userId, groundId);
        print("[WISHLIST_CUBIT] Successfully added to Supabase");
      }
    } catch (e) {
      print("[WISHLIST_CUBIT] ERROR in toggleFavorite: $e");
      // Revert on error
      emit(SavedGroundError(e.toString(), state.favoriteIds));
    }
  }

  bool isFavorite(String groundId) => state.favoriteIds.contains(groundId);
}
