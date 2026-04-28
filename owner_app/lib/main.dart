import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/auth/auth_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/ground/ground_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/slot/slot_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/login_screen.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/otp_screen.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/document_upload_screen.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/main_navbar.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/add_sport_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://qcybnzopffyzmpiaxwbc.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFjeWJuem9wZmZ5em1waWF4d2JjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQxMDYyNzMsImV4cCI6MjA4OTY4MjI3M30.cRnvZzQhbwI26PhRkdjnptVa5yiWo6oBIGZlZU7JEgg',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(create: (context) => AuthCubit()),
        BlocProvider<GroundCubit>(create: (context) => GroundCubit()),
        BlocProvider<SlotCubit>(create: (context) => SlotCubit()),
      ],
      child: ToastificationWrapper(
        child: MaterialApp(
          title: 'TurfPro Owner',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF6B00)),
            useMaterial3: true,
          ),
          initialRoute: '/',
          routes: {
            '/': (context) => const LoginScreen(),
            '/otp': (context) => const OtpScreen(),
            '/upload-documents': (context) => const DocumentUploadScreen(),
            '/dashboard': (context) => const MainNavbar(),
            '/add-sport': (context) => const AddSportScreen(),
          },
        ),
      ),
    );
  }
}
