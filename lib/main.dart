import 'package:bloc_structure/firebase_options.dart';
import 'package:bloc_structure/user_booking/di/get_it/get_it.dart' as di;
import 'package:bloc_structure/user_booking/presentation/blocs/auth/auth_cubit.dart';
import 'package:bloc_structure/user_booking/presentation/blocs/profile/profile_cubit.dart';
import 'package:bloc_structure/user_booking/presentation/blocs/slot_selection/slot_selection_cubit.dart';
import 'package:bloc_structure/user_booking/presentation/blocs/splash/splash_cubit.dart';
import 'package:bloc_structure/user_booking/presentation/blocs/connectivity/connectivity_cubit.dart';
import 'package:bloc_structure/user_booking/presentation/screens/no_internet/no_internet_screen.dart';
import 'package:bloc_structure/user_booking/presentation/screens/booking_confirmation/booking_confirmation_screen.dart';
import 'package:bloc_structure/user_booking/presentation/screens/login/login_screen.dart';
import 'package:bloc_structure/user_booking/presentation/screens/login/forgot_password_screen.dart';
import 'package:bloc_structure/user_booking/presentation/screens/main_navbar/main_nav.dart';
import 'package:bloc_structure/user_booking/presentation/screens/my_booking/my_booking_screen.dart';
import 'package:bloc_structure/user_booking/presentation/screens/otp/otp_screen.dart';
import 'package:bloc_structure/user_booking/presentation/screens/profile_screen/edit_profile.dart';
import 'package:bloc_structure/user_booking/presentation/screens/payment_status/payment_failed_screen.dart';
import 'package:bloc_structure/user_booking/presentation/screens/slot_selection/slot_slection.dart';
import 'package:bloc_structure/user_booking/presentation/screens/signup/signup_screen.dart';
import 'package:bloc_structure/user_booking/presentation/screens/search/search_screen.dart';
import 'package:bloc_structure/user_booking/presentation/screens/split_payment/split_setup_screen.dart';
import 'package:bloc_structure/user_booking/presentation/screens/split_payment/split_share_screen.dart';
import 'package:bloc_structure/user_booking/presentation/screens/split_payment/split_overview_screen.dart';
import 'package:bloc_structure/user_booking/presentation/blocs/split_payment/split_cubit.dart';
import 'package:bloc_structure/user_booking/presentation/screens/category_grounds/category_grounds_screen.dart';
import 'package:bloc_structure/user_booking/presentation/screens/notification/notification_screen.dart';
import 'package:bloc_structure/user_booking/presentation/blocs/notification/notification_cubit.dart';
import 'package:bloc_structure/user_booking/constants/route_constants.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:bloc_structure/common/utils/app_bloc_observer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:path_provider/path_provider.dart' as path_provider;
import 'user_booking/presentation/screens/splash/splash_screen.dart';
import 'package:bloc_structure/user_booking/presentation/blocs/ground/ground_cubit.dart';
import 'user_booking/presentation/blocs/location/location_cubit.dart';
import 'user_booking/presentation/blocs/saved_ground/saved_ground_cubit.dart';
import 'package:bloc_structure/user_booking/presentation/blocs/theme/theme_cubit.dart';
import 'package:bloc_structure/user_booking/presentation/blocs/booking/booking_cubit.dart';
import 'package:bloc_structure/common/constants/colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Pass all uncaught "fatal" errors from the framework to Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  Bloc.observer = AppBlocObserver();

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  SystemChrome.setPreferredOrientations(
    [
      DeviceOrientation.portraitUp,
    ],
  );

  if (kIsWeb) {
    await Hive.initFlutter();
  } else {
    final appDocumentDir = await path_provider.getApplicationDocumentsDirectory();

    Hive.init(appDocumentDir.path);
  }

  // Open settings box for Theme persistence
  await Hive.openBox('settings');

  await di.init();

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
        BlocProvider<ConnectivityCubit>(
          create: (_) => di.getIt<ConnectivityCubit>(),
        ),
        BlocProvider<NotificationCubit>(
          create: (_) => di.getIt<NotificationCubit>()..fetchNotifications(),
        ),
      ],
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, state) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            themeMode: state.themeMode,
            theme: AppColors.getLightTheme(),
            darkTheme: AppColors.getDarkTheme(),
            initialRoute: "/",
            builder: (context, child) {
              return BlocBuilder<ConnectivityCubit, ConnectivityState>(
                builder: (context, connectivityState) {
                  if (connectivityState is ConnectivityDisconnected) {
                    return const NoInternetScreen();
                  }
                  return child!;
                },
              );
            },
            routes: {
              "/": (context) => const SplashScreen(),
              "/login": (context) => const LoginScreen(),
              "/signup": (context) => const SignUpScreen(),
              "/otp": (context) => const OtpScreen(),
              "/nav": (context) => const MainNavScreen(),
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
              AppRoutes.forgotPassword: (context) => const ForgotPasswordScreen(),
              AppRoutes.categoryGrounds: (context) => const CategoryGroundsScreen(),
              AppRoutes.notification: (context) => const NotificationScreen(),
            },
          );
        },
      ),
    ),
  );
}
