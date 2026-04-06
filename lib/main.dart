import 'package:bloc_structure/user_booking/di/get_it/get_it.dart' as di;
import 'package:bloc_structure/user_booking/presentation/blocs/auth/auth_cubit.dart';
import 'package:bloc_structure/user_booking/presentation/blocs/profile/profile_cubit.dart';
import 'package:bloc_structure/user_booking/presentation/blocs/slot_selection/slot_selection_cubit.dart';
import 'package:bloc_structure/user_booking/presentation/blocs/splash/splash_cubit.dart';
import 'package:bloc_structure/user_booking/presentation/screens/booking_confirmation/booking_confirmation_screen.dart';
import 'package:bloc_structure/user_booking/presentation/screens/login/login_screen.dart';
import 'package:bloc_structure/user_booking/presentation/screens/main_navbar/main_nav.dart';
import 'package:bloc_structure/user_booking/presentation/screens/my_booking/my_booking_screen.dart';
import 'package:bloc_structure/user_booking/presentation/screens/otp/otp_screen.dart';
import 'package:bloc_structure/user_booking/presentation/screens/profile_screen/edit_profile.dart';
import 'package:bloc_structure/user_booking/presentation/screens/payment_status/payment_failed_screen.dart';
import 'package:bloc_structure/user_booking/presentation/screens/slot_selection/slot_slection.dart';
import 'package:bloc_structure/user_booking/presentation/screens/signup/signup_screen.dart';
import 'package:bloc_structure/user_booking/presentation/screens/search/search_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:path_provider/path_provider.dart' as path_provider;
import 'user_booking/presentation/screens/splash/splash_screen.dart';
import 'package:bloc_structure/user_booking/presentation/blocs/ground/ground_cubit.dart';
import 'user_booking/presentation/blocs/location/location_cubit.dart';
import 'user_booking/presentation/blocs/saved_ground/saved_ground_cubit.dart';
import 'package:bloc_structure/user_booking/presentation/blocs/theme/theme_cubit.dart';
import 'package:bloc_structure/common/constants/colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://qcybnzopffyzmpiaxwbc.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFjeWJuem9wZmZ5em1waWF4d2JjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQxMDYyNzMsImV4cCI6MjA4OTY4MjI3M30.cRnvZzQhbwI26PhRkdjnptVa5yiWo6oBIGZlZU7JEgg',
  );
  SystemChrome.setPreferredOrientations(
    [
      DeviceOrientation.portraitUp,
    ],
  );

  if (kIsWeb) {
    await Hive.initFlutter();
  } else {
    final appDocumentDir =
        await path_provider.getApplicationDocumentsDirectory();

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
      ],
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, state) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            themeMode: state.themeMode,
            theme: AppColors.getLightTheme(),
            darkTheme: AppColors.getDarkTheme(),
            initialRoute: "/",
            routes: {
              "/": (context) => const SplashScreen(),
              "/login": (context) => const LoginScreen(),
              "/signup": (context) => const SignUpScreen(),
              "/otp": (context) => const OtpScreen(),
              "/nav": (context) => const MainNavScreen(),
              "/search": (context) => const SearchScreen(),
              "/slotSelection": (context) => const SlotSelectionScreen(),
              "/bookingConfirmationScreen": (context) =>
                  const BookingConfirmationScreen(),
              "/myBookingScreen": (context) => const MyBookingsScreen(),
              "/paymentFailedScreen": (context) => const PaymentFailedScreen(),
              "/editProfileScreen": (context) => BlocProvider(
                    create: (_) => di.getIt<ProfileCubit>(),
                    child: const EditProfileScreen(),
                  ),
            },
          );
        },
      ),
    ),
  );
}
// api key- rzp_test_SZQGlX68eXuGzw
// secret key GumrVkR1ylb4jG2dnLdmz2e8
