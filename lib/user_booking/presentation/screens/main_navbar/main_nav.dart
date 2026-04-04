import 'dart:async';
import 'package:bloc_structure/user_booking/constants/widgets/app_text.dart';
import 'package:bloc_structure/user_booking/presentation/screens/ground_list/ground_list_screen.dart';
import 'package:bloc_structure/user_booking/presentation/screens/profile_screen/profile_screen.dart';
import 'package:bloc_structure/user_booking/presentation/screens/saved_ground/saved_ground_screen.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../common/constants/colors.dart';
import '../my_booking/my_booking_screen.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../blocs/saved_ground/saved_ground_cubit.dart';

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int currentIndex = 0;
  late final StreamSubscription<AuthState> _authSubscription;

  @override
  void initState() {
    super.initState();

    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      context.read<SavedGroundCubit>().loadFavorites(user.id);
    }

    // Listen for auth state changes (essential for session restoration on restart)
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;
      final userId = session?.user.id;

      print("[AUTH_SYNC] State change detected: $event. User logged in: ${userId != null}");

      if (userId != null) {
        print("[AUTH_SYNC] Restoring favorites for: $userId");
        context.read<SavedGroundCubit>().loadFavorites(userId);
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  final List<Widget> screens = [
    const GroundListScreen(),
    const MyBookingsScreen(),
    const SizedBox(), // center add button
    const SavedGroundsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return Scaffold(
      body: screens[currentIndex],
      bottomNavigationBar: Container(
        height: 70,
        decoration: BoxDecoration(
          color: theme.cardColor,
          boxShadow: [
            BoxShadow(
              blurRadius: 10,
              color: Colors.black.withOpacity(0.1),
            )
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(HugeIcons.strokeRoundedDiscoverCircle, "Discover", 0, onSurface),
            _navItem(HugeIcons.strokeRoundedCalendar01, "Bookings", 1, onSurface),

            /// Center Button
            Container(
              height: 50,
              width: 50,
              decoration: const BoxDecoration(
                color: AppColors.primaryDarkGreen,
                shape: BoxShape.circle,
              ),
              child: const HugeIcon(
                icon: HugeIcons.strokeRoundedPlusSign,
                color: AppColors.white,
                size: 24,
              ),
            ),

            _navItem(HugeIcons.strokeRoundedFavourite, "Saved", 3, onSurface),
            _navItem(HugeIcons.strokeRoundedProfile, "Profile", 4, onSurface),
          ],
        ),
      ),
    );
  }

  Widget _navItem(dynamic icon, String label, int index, Color onSurface) {
    final bool isActive = currentIndex == index;
    final Color activeColor = AppColors.primaryDarkGreen;
    final Color inactiveColor = onSurface.withOpacity(0.4);

    return GestureDetector(
      onTap: () {
        setState(() {
          currentIndex = index;
        });
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          HugeIcon(
            icon: icon,
            color: isActive ? activeColor : inactiveColor,
          ),
          const SizedBox(height: 4),
          AppText(
            text: label,
            textStyle: TextStyle(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? activeColor : inactiveColor,
            ),
          )
        ],
      ),
    );
  }
}
