import 'package:turfpro/common/constants/colors.dart';
import 'package:turfpro/user_booking/constants/widgets/app_sizedBox.dart';
import 'package:turfpro/common/services/notification_service.dart';
import 'package:flutter/services.dart';
import 'package:turfpro/user_booking/presentation/screens/ground_list/widgets/city_search_bottomsheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';

import '../../../constants/widgets/app_text.dart';

import '../../blocs/location/location_cubit.dart';
import '../../blocs/ground/ground_cubit.dart';
import '../../blocs/ground/ground_state.dart';
import 'package:turfpro/user_booking/presentation/widgets/ground_card.dart';
import 'widgets/ground_skeleton.dart';
import '../../blocs/notification/notification_cubit.dart';
import 'package:turfpro/user_booking/constants/route_constants.dart';
import 'widgets/filter_bottom_sheet.dart';

class GroundListScreen extends StatefulWidget {
  const GroundListScreen({super.key});

  @override
  State<GroundListScreen> createState() => _GroundListScreenState();
}

class _GroundListScreenState extends State<GroundListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, dynamic>> _sportCategories = [
    {
      'id': 'cricket',
      'name': 'Cricket',
      'icon': HugeIcons.strokeRoundedCricketBat,
    },
    {
      'id': 'pickleball',
      'name': 'Pickleball',
      'icon': HugeIcons.strokeRoundedTennisBall,
    },
    {
      'id': 'badminton',
      'name': 'Badminton',
      'icon': HugeIcons.strokeRoundedBadminton,
    },
    {
      'id': 'volleyball',
      'name': 'Volleyball',
      'icon': HugeIcons.strokeRoundedVolleyball,
    },
  ];

  @override
  void initState() {
    super.initState();
    _checkInitialLoad();
  }

  void _checkInitialLoad() {
    final locationCubit = context.read<LocationCubit>();
    final groundCubit = context.read<GroundCubit>();

    // If city is already available and not loading, trigger grounds fetch
    if (groundCubit.state is GroundInitial &&
        locationCubit.state.city != null &&
        !locationCubit.state.isLoading &&
        locationCubit.state.city != "Fetching...") {
      groundCubit.getGrounds(
        city: locationCubit.state.city,
        userLat: locationCubit.state.latitude,
        userLng: locationCubit.state.longitude,
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locationCubit = context.read<LocationCubit>();

    return BlocListener<LocationCubit, LocationState>(
      listenWhen: (previous, current) =>
          previous.city != current.city ||
          previous.isLoading != current.isLoading ||
          previous.latitude != current.latitude ||
          previous.longitude != current.longitude,
      listener: (context, state) {
        if (state.city != null &&
            !state.isLoading &&
            state.city != "Fetching...") {
          final groundCubit = context.read<GroundCubit>();
          // Avoid redundant fetch if already loading or loaded with same parameters
          // Simple check: if it's initial or if city/location changed significantly
          groundCubit.getGrounds(
            city: state.city,
            userLat: state.latitude,
            userLng: state.longitude,
          );
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,

        /// APP BAR
        appBar: AppBar(
          backgroundColor: Theme.of(context).cardColor,
          elevation: 0,
          title: BlocBuilder<LocationCubit, LocationState>(
            builder: (context, state) {
              final city = state.city ?? "Fetching...";

              return GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Theme.of(context).cardColor,
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (_) => const CitySearchBottomSheet(),
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const HugeIcon(
                      icon: HugeIcons.strokeRoundedLocation01,
                      color: AppColors.primaryDarkGreen,
                      size: 18,
                    ),
                    const AppSizedBox(width: 4),
                    Flexible(
                      child: AppText(
                        text: city,
                        textStyle: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const AppSizedBox(width: 4),
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedArrowDown01,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.5),
                      size: 20,
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            BlocBuilder<NotificationCubit, NotificationState>(
              builder: (context, state) {
                final bool hasUnread = state.unreadCount > 0;
                
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: GestureDetector(
                    onTap: () => Navigator.pushNamed(context, AppRoutes.notification),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedNotification01,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        if (hasUnread)
                          Positioned(
                            right: 0,
                            top: 15,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 1.5),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            )
          ],
        ),

        /// BODY
        body: CustomScrollView(
          controller: _scrollController,
          slivers: [
            /// 🔑 FCM TOKEN DISPLAY
            SliverToBoxAdapter(
              child: FutureBuilder<String?>(
                future: NotificationService.getLocalToken(),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data != null) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: snapshot.data!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("FCM Token copied to clipboard!"),
                              backgroundColor: AppColors.primaryDarkGreen,
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.key_rounded, color: Colors.blue, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Your FCM Token (Tap to copy)",
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                    ),
                                    Text(
                                      snapshot.data!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.copy_rounded, color: Colors.blue, size: 16),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),

            /// 🔍 SEARCH & FILTER
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, AppRoutes.search);
                        },
                        child: Hero(
                          tag: 'search_bar',
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              children: [
                                HugeIcon(
                                  icon: HugeIcons.strokeRoundedSearch01,
                                  size: 18,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.4),
                                ),
                                const AppSizedBox(width: 10),
                                AppText(
                                  text: "Search nearby grounds...",
                                  textStyle: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.4),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const AppSizedBox(width: 12),
                    BlocBuilder<GroundCubit, GroundState>(
                      builder: (context, state) {
                        final bool hasFilters = state is GroundLoaded && !state.criteria.isDefault;
                        
                        return GestureDetector(
                          onTap: () {
                            if (state is GroundLoaded) {
                              _showFilterSheet(context, state);
                            }
                          },
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryDarkGreen,
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primaryDarkGreen.withOpacity(0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const HugeIcon(
                                  icon: HugeIcons.strokeRoundedFilterHorizontal,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              if (hasFilters)
                                Positioned(
                                  top: -2,
                                  right: -2,
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            /// 🎾 SPORT SELECTION
            SliverToBoxAdapter(
              child: Column(
                children: [
                  const AppSizedBox(height: 4),
                  _buildSportSelection(),
                  const AppSizedBox(height: 24),
                ],
              ),
            ),

            /// 📋 LIST (DYNAMIC)
            BlocBuilder<GroundCubit, GroundState>(
              builder: (context, state) {
                /// 🔄 Loading or Initial
                if (state is GroundLoading || state is GroundInitial) {
                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => const Padding(
                          padding: EdgeInsets.only(bottom: 16),
                          child: GroundSkeleton(),
                        ),
                        childCount: 5,
                      ),
                    ),
                  );
                }

                /// ✅ Data Loaded
                if (state is GroundLoaded) {
                  if (state.grounds.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              child: Lottie.network(
                                'https://Assets1.lottiefiles.com/packages/lf20_cwA7Cn.json',
                                height: 180,
                                width: 180,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const HugeIcon(
                                      icon: HugeIcons.strokeRoundedSearch01,
                                      size: 48,
                                      color: AppColors.primaryDarkGreen,
                                    ),
                                  );
                                },
                              ),
                            ).animate().scale(delay: 200.ms, duration: 400.ms, curve: Curves.easeOutBack),
                            const AppSizedBox(height: 16),
                            AppText(
                              text: "No Grounds Found",
                              textStyle: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ).animate().fadeIn(delay: 400.ms),
                            const AppSizedBox(height: 8),
                            AppText(
                              text: "Try adjusting your filters or location",
                              textStyle: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                              ),
                            ).animate().fadeIn(delay: 500.ms),
                          ],
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: GroundCard(
                              ground: state.grounds[index],
                            ).animate()
                             .fadeIn(duration: 300.ms, delay: (index < 10 ? index * 50 : 0).ms)
                             .slideY(begin: 0.03, end: 0, duration: 300.ms, curve: Curves.easeOutQuad),
                          );
                        },
                        childCount: state.grounds.length,
                      ),
                    ),
                  );
                }

                /// ❌ Error
                if (state is GroundError) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: AppText(text: state.message),
                    ),
                  );
                }

                return const SliverToBoxAdapter(child: SizedBox());
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSportSelection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppText(
            text: "Popular Sports",
            textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const AppSizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _sportCategories.map((sport) {
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.categoryGrounds,
                      arguments: sport['name'],
                    );
                  },
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryDarkGreen.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: HugeIcon(
                          icon: sport['icon'],
                          color: AppColors.primaryDarkGreen,
                          size: 28,
                        ),
                      ),
                      const AppSizedBox(height: 8),
                      AppText(
                        text: sport['name'],
                        textStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }


  void _showFilterSheet(BuildContext context, GroundLoaded state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FilterBottomSheet(
        initialCriteria: state.criteria,
        onApply: (criteria) {
          final locationState = context.read<LocationCubit>().state;
          context.read<GroundCubit>().applyFilters(
                criteria,
                userLat: locationState.latitude,
                userLng: locationState.longitude,
              );
          // Scroll to top when filters are applied
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        },
      ),
    );
  }
}
