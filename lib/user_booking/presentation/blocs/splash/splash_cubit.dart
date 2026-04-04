import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class SplashState {}

class SplashInitial extends SplashState {}


class SplashNavigateToLogin extends SplashState {}

class SplashNavigateToHome extends SplashState {}

class SplashCubit extends Cubit<SplashState> {
  SplashCubit() : super(SplashInitial());

  void checkAuth() async {
    await Future.delayed(const Duration(seconds: 1)); // optional splash delay

    final user = Supabase.instance.client.auth.currentUser;

    if (user != null) {
      emit(SplashNavigateToHome());
    } else {
      emit(SplashNavigateToLogin());
    }
  }
}
