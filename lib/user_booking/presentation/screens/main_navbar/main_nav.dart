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
import 'package:geolocator/geolocator.dart';
import '../../blocs/saved_ground/saved_ground_cubit.dart';
import '../../blocs/location/location_cubit.dart';
import '../../blocs/notification/notification_cubit.dart';
import '../../../di/get_it/get_it.dart';

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int currentIndex = 0;
  late final PageController _pageController;
  late final StreamSubscription<AuthState> _authSubscription;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);

    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      context.read<SavedGroundCubit>().loadFavorites(user.id);
    }

    // Trigger location fetch when main navbar opens
    context.read<LocationCubit>().loadCity();

    // Listen for auth state changes (essential for session restoration on restart)
    _authSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;
      final userId = session?.user.id;

      print(
          "[AUTH_SYNC] State change detected: $event. User logged in: ${userId != null}");

      if (userId != null && mounted) {
        print("[AUTH_SYNC] Restoring favorites for: $userId");
        context.read<SavedGroundCubit>().loadFavorites(userId);
      }
    });

    // Check for initial index in arguments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is int) {
        setState(() {
          currentIndex = args;
        });
        _pageController.jumpToPage(args);
      }
    });
  }

  // Removed unused _mapNavbarToPage

  @override
  void dispose() {
    _authSubscription.cancel();
    _pageController.dispose();
    super.dispose();
  }

  final List<Widget> pages = [
    const GroundListScreen(),
    const MyBookingsScreen(),
    const SavedGroundsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return BlocBuilder<NotificationCubit, NotificationState>(
      builder: (context, notificationState) {
        return BlocListener<LocationCubit, LocationState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: AppColors.error,
                action: SnackBarAction(
                  label: 'Settings',
                  textColor: Colors.white,
                  onPressed: () {
                    if (state.errorMessage!.contains('permanently')) {
                      Geolocator.openAppSettings();
                    } else {
                      Geolocator.openLocationSettings();
                    }
                  },
                ),
                duration: const Duration(seconds: 5),
              ),
            );
          }
        },
        child: Scaffold(
          body: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                currentIndex = index;
              });
            },
            children: pages,
          ),
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
                _navItem(HugeIcons.strokeRoundedDiscoverCircle, "Discover", 0,
                    onSurface, showBadge: notificationState.unreadCount > 0),
                _navItem(HugeIcons.strokeRoundedCalendar01, "Bookings", 1,
                    onSurface),
                _navItem(
                    HugeIcons.strokeRoundedFavourite, "Saved", 2, onSurface),
                _navItem(
                    HugeIcons.strokeRoundedProfile, "Profile", 3, onSurface),
              ],
            ),
          ),
        ),
      );
    },
   );
  }

  Widget _navItem(dynamic icon, String label, int index, Color onSurface, {bool showBadge = false}) {
    final bool isActive = currentIndex == index;
    const Color activeColor = AppColors.primaryDarkGreen;
    final Color inactiveColor = onSurface.withValues(alpha: 0.4);

    return GestureDetector(
      onTap: () {
        setState(() {
          currentIndex = index;
        });
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            children: [
              HugeIcon(
                icon: icon,
                color: isActive ? activeColor : inactiveColor,
              ),
              if (showBadge)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
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
