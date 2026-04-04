import 'package:bloc_structure/user_booking/data/repositories/auth_repositories_impl.dart';
import 'package:bloc_structure/user_booking/domain/repositories/auth_repositories.dart';
import 'package:bloc_structure/user_booking/presentation/blocs/auth/auth_cubit.dart';
import 'package:bloc_structure/user_booking/presentation/blocs/slot_selection/slot_selection_cubit.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bloc_structure/user_booking/data/repositories/ground_repository_impl.dart';
import 'package:bloc_structure/user_booking/data/repositories/slot_repository_impl.dart';
import 'package:bloc_structure/user_booking/domain/repositories/slot_repository.dart';

import '../../domain/repositories/ground_repository.dart';
import '../../presentation/blocs/ground/ground_cubit.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../../domain/usecases/upsert_user_profile.dart';
import '../../presentation/blocs/location/location_cubit.dart';
import '../../presentation/blocs/profile/profile_cubit.dart';
import '../../presentation/blocs/splash/splash_cubit.dart';
import 'package:bloc_structure/user_booking/data/repositories/favorite_repository.dart';
import 'package:bloc_structure/user_booking/presentation/blocs/saved_ground/saved_ground_cubit.dart';
import 'package:bloc_structure/user_booking/presentation/blocs/theme/theme_cubit.dart';

final getIt = GetIt.instance;

Future<void> init() async {
  final supabase = Supabase.instance.client;

  /// Register Supabase
  getIt.registerLazySingleton<SupabaseClient>(() => supabase);

  /// Repository (REGISTER FIRST)
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(getIt<SupabaseClient>()),
  );
  getIt.registerLazySingleton<SlotRepository>(
    () => SlotRepositoryImpl(getIt<SupabaseClient>()),
  );

  /// Cubits (REGISTER AFTER)
  getIt.registerFactory(() => SplashCubit());
  getIt.registerFactory(() => SlotSelectionCubit(getIt<SlotRepository>()));
  getIt.registerFactory(() => AuthCubit(getIt<AuthRepository>()));

  getIt.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(supabase),
  );

  getIt.registerLazySingleton(
    () => UpsertUserProfile(getIt<UserRepository>()),
  );

  getIt.registerFactory(
    () => ProfileCubit(getIt<UpsertUserProfile>()),
  );
  getIt.registerFactory(
    () => LocationCubit(getIt<UserRepository>()),
  );
  getIt.registerLazySingleton<GroundRepository>(
    () => GroundRepositoryImpl(),
  );
  getIt.registerLazySingleton<FavoriteRepository>(
    () => FavoriteRepositoryImpl(getIt<SupabaseClient>()),
  );
  getIt.registerLazySingleton<GroundCubit>(
    () => GroundCubit(getIt<GroundRepository>()),
  );
  getIt.registerLazySingleton<SavedGroundCubit>(
    () => SavedGroundCubit(getIt<FavoriteRepository>()),
  );
  getIt.registerLazySingleton<ThemeCubit>(
    () => ThemeCubit(),
  );
}
