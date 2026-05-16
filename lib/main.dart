import 'package:turfpro/firebase_options.dart';
import 'package:turfpro/user_booking/di/get_it/get_it.dart' as di;
import 'package:turfpro/user_booking/presentation/blocs/auth/auth_cubit.dart';
import 'package:turfpro/user_booking/presentation/blocs/profile/profile_cubit.dart';
import 'package:turfpro/user_booking/presentation/blocs/slot_selection/slot_selection_cubit.dart';
import 'package:turfpro/user_booking/presentation/blocs/splash/splash_cubit.dart';
import 'package:turfpro/user_booking/presentation/blocs/connectivity/connectivity_cubit.dart';
import 'package:turfpro/user_booking/presentation/screens/no_internet/no_internet_screen.dart';
import 'package:turfpro/user_booking/presentation/screens/booking_confirmation/booking_confirmation_screen.dart';
import 'package:turfpro/user_booking/presentation/screens/login/login_screen.dart';
import 'package:turfpro/user_booking/presentation/screens/login/forgot_password_screen.dart';
import 'package:turfpro/user_booking/presentation/screens/main_navbar/main_nav.dart';
import 'package:turfpro/user_booking/presentation/screens/my_booking/my_booking_screen.dart';

import 'package:turfpro/user_booking/presentation/screens/profile_screen/edit_profile.dart';
import 'package:turfpro/user_booking/presentation/screens/payment_status/payment_failed_screen.dart';
import 'package:turfpro/user_booking/presentation/screens/slot_selection/slot_slection.dart';
import 'package:turfpro/user_booking/presentation/screens/signup/signup_screen.dart';
import 'package:turfpro/user_booking/presentation/screens/signup/complete_profile_screen.dart';
import 'package:turfpro/user_booking/presentation/screens/signup/email_verification_waiting_screen.dart';
import 'package:turfpro/user_booking/presentation/screens/signup/set_password_screen.dart';
import 'package:turfpro/user_booking/presentation/screens/search/search_screen.dart';
import 'package:turfpro/user_booking/presentation/screens/split_payment/split_setup_screen.dart';
import 'package:turfpro/user_booking/presentation/screens/split_payment/split_share_screen.dart';
import 'package:turfpro/user_booking/presentation/screens/split_payment/split_overview_screen.dart';
import 'package:turfpro/user_booking/presentation/screens/split_payment/split_history_screen.dart';
import 'package:turfpro/user_booking/presentation/blocs/split_payment/split_cubit.dart';
import 'package:turfpro/user_booking/presentation/blocs/split_history/split_history_cubit.dart';
import 'package:turfpro/user_booking/presentation/screens/category_grounds/category_grounds_screen.dart';
import 'package:turfpro/user_booking/presentation/screens/notification/notification_screen.dart';
import 'package:turfpro/user_booking/presentation/screens/booking_summary/booking_summary_screen.dart';
import 'package:turfpro/user_booking/presentation/blocs/notification/notification_cubit.dart';
import 'package:turfpro/user_booking/constants/route_constants.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:turfpro/common/utils/app_bloc_observer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:turfpro/common/services/remote_config_service.dart';
import 'package:turfpro/common/screens/maintenance_screen.dart';
import 'package:turfpro/user_booking/presentation/screens/splash/app_status_screens.dart';

import 'package:path_provider/path_provider.dart' as path_provider;
import 'user_booking/presentation/screens/splash/splash_screen.dart';
import 'package:turfpro/user_booking/presentation/screens/splash/app_status_screens.dart';
import 'package:turfpro/user_booking/presentation/blocs/ground/ground_cubit.dart';
import 'user_booking/presentation/blocs/location/location_cubit.dart';
import 'user_booking/presentation/blocs/saved_ground/saved_ground_cubit.dart';
import 'package:turfpro/user_booking/presentation/blocs/theme/theme_cubit.dart';
import 'package:turfpro/user_booking/presentation/blocs/config/config_cubit.dart';
import 'package:turfpro/user_booking/presentation/screens/scanning/scanning_screen.dart';
import 'package:turfpro/user_booking/presentation/blocs/booking/booking_cubit.dart';
import 'package:turfpro/common/constants/colors.dart';
import 'package:turfpro/user_booking/data/services/deep_link_service.dart';
import 'package:turfpro/user_booking/data/services/shorebird_service.dart';
import 'package:turfpro/utils/app_scroll_behavior.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint("DEBUG: [Main] App starting. Full URL: ${Uri.base}");
  
  // Silent OTA updates
  ShorebirdService.checkForUpdates();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Remote Config
  await RemoteConfigService().initialize();

  // Pass all uncaught "fatal" errors from the framework to Crashlytics
  if (!kIsWeb) {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

    // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  Bloc.observer = AppBlocObserver();

  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL'),
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
  );
  debugPrint("DEBUG: [Main] Supabase Initialized.");
  SystemChrome.setPreferredOrientations(
    [
      DeviceOrientation.portraitUp,
    ],
  );

  if (kIsWeb) {
    debugPrint("DEBUG: [Main] Initializing Hive for Web.");
    await Hive.initFlutter();
  } else {
    debugPrint("DEBUG: [Main] Initializing Hive for Mobile.");
    final appDocumentDir = await path_provider.getApplicationDocumentsDirectory();
    Hive.init(appDocumentDir.path);
  }

  // Open settings box for Theme persistence
  await Hive.openBox('settings');

  debugPrint("DEBUG: [Main] Initializing DI.");
  await di.init();
  debugPrint("DEBUG: [Main] Initializing DeepLinkService.");
  DeepLinkService().init();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(
          create: (_) => di.getIt<AuthCubit>(),
        ),
        BlocProvider<SplashCubit>(
          create: (_) => di.getIt<SplashCubit>(),
        ),
        BlocProvider<SlotSelectionCubit>(
          create: (_) => di.getIt<SlotSelectionCubit>(),
        ),
        BlocProvider<GroundCubit>(
          create: (_) => di.getIt<GroundCubit>(),
        ),
        BlocProvider<LocationCubit>(
          create: (_) => di.getIt<LocationCubit>(),
        ),
        BlocProvider<SavedGroundCubit>(
          create: (_) => di.getIt<SavedGroundCubit>(),
        ),
        BlocProvider<ThemeCubit>(
          create: (_) => di.getIt<ThemeCubit>(),
        ),
        BlocProvider<BookingCubit>(
          create: (_) => di.getIt<BookingCubit>(),
        ),
        BlocProvider<SplitPaymentCubit>(
          create: (_) => di.getIt<SplitPaymentCubit>(),
        ),
        BlocProvider<SplitHistoryCubit>(
          create: (_) => di.getIt<SplitHistoryCubit>(),
        ),
        BlocProvider<ConnectivityCubit>(
          create: (_) => di.getIt<ConnectivityCubit>(),
        ),
        BlocProvider<NotificationCubit>(
          create: (_) => di.getIt<NotificationCubit>()..fetchNotifications(),
        ),
        BlocProvider<ConfigCubit>(
          create: (_) => di.getIt<ConfigCubit>(),
        ),
      ],
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, state) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            scrollBehavior: const AppScrollBehavior(),
            themeMode: state.themeMode,
            theme: AppColors.getLightTheme(),
            darkTheme: AppColors.getDarkTheme(),
            navigatorKey: navigatorKey,
            builder: (context, child) {
              return BlocBuilder<ConfigCubit, ConfigState>(
                builder: (context, configState) {
                  if (configState is ConfigLoaded) {
                    if (configState.isMaintenanceMode) {
                      return const MaintenanceScreen();
                    }
                    if (configState.isUpdateRequired) {
                      return Stack(
                        children: [
                          if (child != null) child,
                          // Dimmed background
                          Container(color: Colors.black.withValues(alpha: 0.5)),
                          // Unclosable Dialog
                          Center(
                            child: ForceUpdateDialog(updateUrl: configState.updateUrl),
                          ),
                        ],
                      );
                    }
                  }
                  return BlocBuilder<ConnectivityCubit, ConnectivityState>(
                    builder: (context, connectivityState) {
                      return Stack(
                        children: [
                          if (child != null) child,
                          if (connectivityState is ConnectivityDisconnected)
                            const NoInternetScreen(),
                        ],
                      );
                    },
                  );
                },
              );
            },
            routes: {
              AppRoutes.splash: (context) => const SplashScreen(),
              AppRoutes.login: (context) => const LoginScreen(),
              AppRoutes.signUp: (context) => const SignUpScreen(),
              AppRoutes.completeProfile: (context) => const CompleteProfileScreen(),
              AppRoutes.waitingVerification: (context) => const EmailVerificationWaitingScreen(),
              AppRoutes.setPassword: (context) => const SetPasswordScreen(),
              AppRoutes.nav: (context) => const MainNavScreen(),
              "/search": (context) => const SearchScreen(),
              "/slotSelection": (context) => const SlotSelectionScreen(),
              "/bookingConfirmationScreen": (context) => const BookingConfirmationScreen(),
              "/myBookingScreen": (context) => const MyBookingsScreen(),
              "/paymentFailedScreen": (context) => const PaymentFailedScreen(),
              AppRoutes.editProfileScreen: (context) => BlocProvider(
                    create: (_) => di.getIt<ProfileCubit>(),
                    child: const EditProfileScreen(),
                  ),
              AppRoutes.splitSetup: (context) => const SplitSetupScreen(),
              AppRoutes.splitShare: (context) => const SplitShareScreen(),
              AppRoutes.splitOverview: (context) => const SplitOverviewScreen(),
              AppRoutes.splitHistory: (context) => const SplitHistoryScreen(),
              AppRoutes.forgotPassword: (context) => const ForgotPasswordScreen(),
              AppRoutes.scan: (context) => const ScanningScreen(),
              AppRoutes.categoryGrounds: (context) => const CategoryGroundsScreen(),
              AppRoutes.notification: (context) => const NotificationScreen(),
              AppRoutes.bookingSummary: (context) => const BookingSummaryScreen(),
            },
          );
        },
      ),
    ),
  );
}
