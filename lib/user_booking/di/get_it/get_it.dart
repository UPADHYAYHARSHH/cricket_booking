import 'package:turfpro/user_booking/data/repositories/auth_repositories_impl.dart';
import 'package:turfpro/user_booking/presentation/blocs/connectivity/connectivity_cubit.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:turfpro/user_booking/data/services/analytics_service.dart';
import 'package:turfpro/user_booking/data/repositories/payment_repository.dart';
import 'package:turfpro/user_booking/data/repositories/booking_repository.dart';
import 'package:turfpro/user_booking/presentation/blocs/booking/booking_cubit.dart';
import 'package:turfpro/user_booking/domain/repositories/auth_repositories.dart';
import 'package:turfpro/user_booking/presentation/blocs/auth/auth_cubit.dart';
import 'package:turfpro/user_booking/presentation/blocs/slot_selection/slot_selection_cubit.dart';
import 'package:turfpro/user_booking/presentation/blocs/split_history/split_history_cubit.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:turfpro/user_booking/data/repositories/ground_repository_impl.dart';
import 'package:turfpro/user_booking/data/repositories/slot_repository_impl.dart';
import 'package:turfpro/user_booking/domain/repositories/slot_repository.dart';
import 'package:turfpro/user_booking/data/repositories/review_repository_impl.dart';
import 'package:turfpro/user_booking/domain/repositories/review_repository.dart';
import 'package:turfpro/user_booking/domain/repositories/loyalty_repository.dart';
import 'package:turfpro/user_booking/data/repositories/loyalty_repository_impl.dart';

import 'package:turfpro/user_booking/domain/repositories/ground_repository.dart';
import 'package:turfpro/user_booking/presentation/blocs/ground/ground_cubit.dart';
import 'package:turfpro/user_booking/data/repositories/user_repository_impl.dart';
import 'package:turfpro/user_booking/domain/usecases/upsert_user_profile.dart';
import 'package:turfpro/user_booking/presentation/blocs/location/location_cubit.dart';
import 'package:turfpro/user_booking/presentation/blocs/profile/profile_cubit.dart';
import 'package:turfpro/user_booking/presentation/blocs/splash/splash_cubit.dart';
import 'package:turfpro/user_booking/data/repositories/favorite_repository.dart';
import 'package:turfpro/user_booking/presentation/blocs/saved_ground/saved_ground_cubit.dart';
import 'package:turfpro/user_booking/presentation/blocs/theme/theme_cubit.dart';
import 'package:turfpro/user_booking/data/repositories/split_payment_repository.dart';
import 'package:turfpro/user_booking/presentation/blocs/split_payment/split_cubit.dart';
import 'package:turfpro/user_booking/presentation/blocs/user_search/user_search_cubit.dart';
import 'package:turfpro/user_booking/data/repositories/notification_repository.dart';
import 'package:turfpro/user_booking/presentation/blocs/notification/notification_cubit.dart';

import 'package:turfpro/user_booking/presentation/blocs/config/config_cubit.dart';
import 'package:turfpro/common/services/remote_config_service.dart';

final getIt = GetIt.instance;

Future<void> init() async {
  final supabase = Supabase.instance.client;

  /// Register Supabase
  getIt.registerLazySingleton<SupabaseClient>(() => supabase);

  /// Register Connectivity
  getIt.registerLazySingleton<Connectivity>(() => Connectivity());

  /// Repository (REGISTER FIRST)
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(getIt<SupabaseClient>()),
  );
  getIt.registerLazySingleton<SlotRepository>(
    () => SlotRepositoryImpl(getIt<SupabaseClient>()),
  );
  getIt.registerLazySingleton<LoyaltyRepository>(
    () => LoyaltyRepositoryImpl(),
  );

  /// Cubits (REGISTER AFTER)
  getIt.registerFactory(() => SplashCubit());
  getIt.registerFactory(() => SlotSelectionCubit(
        getIt<SlotRepository>(),
        getIt<LoyaltyRepository>(),
      ));
  getIt.registerFactory(() => AuthCubit(getIt<AuthRepository>()));

  getIt.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(supabase),
  );

  getIt.registerLazySingleton(
    () => UpsertUserProfile(getIt<UserRepository>()),
  );

  getIt.registerFactory(
    () => ProfileCubit(getIt<UpsertUserProfile>(), getIt<UserRepository>()),
  );
  getIt.registerFactory(
    () => LocationCubit(getIt<UserRepository>()),
  );
  getIt.registerLazySingleton<GroundRepository>(
    () => GroundRepositoryImpl(),
  );
  getIt.registerLazySingleton<PaymentRepository>(
    () => PaymentRepository(),
  );
  getIt.registerLazySingleton<BookingRepository>(
    () => BookingRepository(),
  );
  getIt.registerFactory(
    () => BookingCubit(getIt<BookingRepository>(), getIt<AnalyticsService>()),
  );
  getIt.registerLazySingleton<FavoriteRepository>(
    () => FavoriteRepositoryImpl(getIt<SupabaseClient>()),
  );
  getIt.registerLazySingleton<SplitPaymentRepository>(
    () => SplitPaymentRepository(),
  );
  getIt.registerLazySingleton<NotificationRepository>(
    () => NotificationRepository(),
  );
  getIt.registerLazySingleton<ReviewRepository>(
    () => ReviewRepositoryImpl(),
  );
  getIt.registerLazySingleton<GroundCubit>(
    () => GroundCubit(getIt<GroundRepository>(), getIt<AnalyticsService>()),
  );
  getIt.registerLazySingleton<SavedGroundCubit>(
    () => SavedGroundCubit(getIt<FavoriteRepository>()),
  );
  getIt.registerLazySingleton<ThemeCubit>(
    () => ThemeCubit(),
  );
  getIt.registerFactory(
    () => SplitPaymentCubit(getIt<SplitPaymentRepository>()),
  );
  getIt.registerLazySingleton(
    () => UserSearchCubit(getIt<UserRepository>()),
  );
  getIt.registerFactory(
    () => NotificationCubit(getIt<NotificationRepository>()),
  );

  getIt.registerFactory(
    () => SplitHistoryCubit(getIt<SplitPaymentRepository>()),
  );

  getIt.registerLazySingleton<ConnectivityCubit>(
    () => ConnectivityCubit(getIt<Connectivity>()),
  );

  getIt.registerLazySingleton<ConfigCubit>(
    () => ConfigCubit(RemoteConfigService()),
  );

  /// Services
  getIt.registerLazySingleton<AnalyticsService>(() => AnalyticsService());
}
