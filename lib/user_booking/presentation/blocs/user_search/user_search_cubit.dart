import 'package:flutter/foundation.dart';
import 'package:turfpro/user_booking/data/repositories/user_repository_impl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class UserSearchState {}

class UserSearchInitial extends UserSearchState {}

class UserSearchLoading extends UserSearchState {}

class UserSearchLoaded extends UserSearchState {
  final List<Map<String, dynamic>> users;
  UserSearchLoaded(this.users);
}

class UserSearchError extends UserSearchState {
  final String message;
  UserSearchError(this.message);
}

class UserSearchCubit extends Cubit<UserSearchState> {
  final UserRepository repository;

  UserSearchCubit(this.repository) : super(UserSearchInitial());

  Future<void> searchUsers(String query) async {
    debugPrint("[DEBUG] UserSearchCubit: searchUsers called with query: '$query'");
    if (query.isEmpty) {
      debugPrint("[DEBUG] UserSearchCubit: Query empty, emitting Initial");
      emit(UserSearchInitial());
      return;
    }

    emit(UserSearchLoading());
    try {
      final users = await repository.searchUsersByUsername(query);
      debugPrint("[DEBUG] UserSearchCubit: Received ${users.length} users from repository");
      emit(UserSearchLoaded(users));
    } catch (e) {
      debugPrint("[DEBUG] UserSearchCubit: Error during search: $e");
      emit(UserSearchError(e.toString()));
    }
  }
}
