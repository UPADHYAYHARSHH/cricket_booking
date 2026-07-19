import 'dart:async';
import 'package:turfpro/common/constants/colors.dart';
import 'package:turfpro/user_booking/constants/widgets/app_text.dart';
import 'package:turfpro/user_booking/presentation/screens/ground_list/ground_list_screen.dart';
import 'package:turfpro/user_booking/presentation/screens/profile_screen/profile_screen.dart';
import 'package:turfpro/user_booking/presentation/screens/saved_ground/saved_ground_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:turfpro/user_booking/presentation/screens/ground_list/widgets/city_search_bottomsheet.dart';
import '../my_booking/my_booking_screen.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/saved_ground/saved_ground_cubit.dart';
import '../../blocs/location/location_cubit.dart';
import '../../blocs/notification/notification_cubit.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int currentIndex = 0;
  late final StreamSubscription<User?> _authSubscription;
  bool _isLocationDialogShowing = false;

  static const List<Widget> _pages = [
    GroundListScreen(),
    MyBookingsScreen(),
    SavedGroundsScreen(),
    ProfileScreen(),
  ];

  void _checkLocation(LocationState state) {
    if (!state.isLoading &&
        (state.city == null || state.city == "Select Location")) {
      if (!_isLocationDialogShowing) {
        _isLocationDialogShowing = true;
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          enableDrag: false,
          isDismissible: false,
          backgroundColor: Theme.of(context).cardColor,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (_) => const CitySearchBottomSheet(isMandatory: true),
        ).then((_) {
          _isLocationDialogShowing = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      context.read<SavedGroundCubit>().loadFavorites(user.uid);
    }

    final locationCubit = context.read<LocationCubit>();
    if (locationCubit.state.city == null ||
        locationCubit.state.city == "Select Location") {
      locationCubit.loadCity();
    }

    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      final userId = user?.uid;
      if (userId != null && mounted) {
        context.read<SavedGroundCubit>().loadFavorites(userId);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is int) {
        setState(() {
          currentIndex = args;
        });
      }
      _checkLocation(context.read<LocationCubit>().state);
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  void _handleTabSwitch(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
        listeners: [
          BlocListener<LocationCubit, LocationState>(
            listener: (context, state) {
              _checkLocation(state);
            },
          ),
        ],
        child: BlocBuilder<NotificationCubit, NotificationState>(
          builder: (context, notificationState) {
            return PopScope(
              canPop: currentIndex == 0,
              onPopInvokedWithResult: (didPop, result) {
                if (didPop) return;
                if (currentIndex > 0) {
                  _handleTabSwitch(currentIndex - 1);
                } else {
                  _showExitDialog(context);
                }
              },
              child: Scaffold(
                body: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.02, 0),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                          ),
                        ),
                        child: child,
                      ),
                    );
                  },
                  child: _pages[currentIndex],
                ),
                bottomNavigationBar: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 16,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: SizedBox(
                      height: 68,
                      child: Row(
                        children: [
                          _NavItem(
                            icon: HugeIcons.strokeRoundedDiscoverCircle,
                            label: "Discover",
                            selected: currentIndex == 0,
                            onTap: () => _handleTabSwitch(0),
                            showBadge: notificationState.unreadCount > 0,
                          ),
                          _NavItem(
                            icon: HugeIcons.strokeRoundedCalendar01,
                            label: "Bookings",
                            selected: currentIndex == 1,
                            onTap: () => _handleTabSwitch(1),
                          ),
                          _NavItem(
                            icon: HugeIcons.strokeRoundedFavourite,
                            label: "Saved",
                            selected: currentIndex == 2,
                            onTap: () => _handleTabSwitch(2),
                          ),
                          _NavItem(
                            icon: HugeIcons.strokeRoundedProfile,
                            label: "Profile",
                            selected: currentIndex == 3,
                            onTap: () => _handleTabSwitch(3),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ));
  }

  Future<void> _showExitDialog(BuildContext context) async {
    final theme = Theme.of(context);

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const AppText(
          text: "Exit App",
          size: 18,
          weight: FontWeight.bold,
        ),
        content: const AppText(
          text: "Are you sure you want to close the app?",
          size: 14,
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primaryDarkGreen),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const AppText(
              text: "Cancel",
              size: 14,
              weight: FontWeight.w600,
              color: AppColors.primaryDarkGreen,
            ),
          ),
          ElevatedButton(
            onPressed: () => SystemNavigator.pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDarkGreen,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const AppText(
              text: "Exit",
              size: 14,
              weight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final dynamic icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool showBadge;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.showBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: selected ? 1.0 : 0.0),
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            final color = Color.lerp(
              AppColors.textSecondaryLight,
              AppColors.primaryDarkGreen,
              value,
            )!;
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Transform.scale(
                      scale: 1.0 + (0.15 * value),
                      child: HugeIcon(
                        icon: icon as dynamic,
                        color: color,
                        size: 22,
                      ),
                    ),
                    if (showBadge)
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.surfaceLight,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.error.withValues(alpha: 0.4),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                AppText(
                  text: label,
                  size: 11,
                  weight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                ),
                const SizedBox(height: 2),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  width: selected ? 20 : 0,
                  height: 2,
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primaryDarkGreen
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
