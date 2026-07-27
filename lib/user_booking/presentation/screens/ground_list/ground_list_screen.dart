import 'package:cached_network_image/cached_network_image.dart';
import 'package:turfpro/common/constants/colors.dart';
import 'package:turfpro/common/constants/size_constants.dart';
import 'package:turfpro/user_booking/presentation/screens/ground_list/widgets/city_search_bottomsheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:turfpro/user_booking/data/models/sport_model.dart';
import 'package:turfpro/user_booking/presentation/blocs/sport/sport_cubit.dart';
import 'package:turfpro/user_booking/presentation/blocs/sport/sport_state.dart';

import '../../../constants/widgets/app_text.dart';

import '../../blocs/location/location_cubit.dart';
import '../../blocs/ground/ground_cubit.dart';
import '../../blocs/ground/ground_state.dart';
import 'package:turfpro/user_booking/presentation/widgets/ground_card.dart';
import 'widgets/ground_skeleton.dart';
import '../../blocs/notification/notification_cubit.dart';
import 'package:turfpro/user_booking/constants/route_constants.dart';
import 'package:turfpro/user_booking/data/models/ground_model.dart';

class GroundListScreen extends StatefulWidget {
  const GroundListScreen({super.key});

  @override
  State<GroundListScreen> createState() => _GroundListScreenState();
}

class _GroundListScreenState extends State<GroundListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  void initState() {
    super.initState();
    _checkInitialLoad();
  }

  void _checkInitialLoad() {
    final locationCubit = context.read<LocationCubit>();
    final groundCubit = context.read<GroundCubit>();

    if (groundCubit.state is GroundInitial &&
        locationCubit.state.city != null &&
        !locationCubit.state.isLoading &&
        locationCubit.state.city != "Fetching...") {
      groundCubit.getGrounds(
        city: locationCubit.state.city,
        userLat: locationCubit.state.hasGpsLocation
            ? locationCubit.state.latitude
            : null,
        userLng: locationCubit.state.hasGpsLocation
            ? locationCubit.state.longitude
            : null,
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocListener<LocationCubit, LocationState>(
      listenWhen: (previous, current) =>
          previous.city != current.city ||
          previous.isLoading != current.isLoading ||
          previous.hasGpsLocation != current.hasGpsLocation,
      listener: (context, state) {
        if (state.city != null &&
            !state.isLoading &&
            state.city != "Fetching...") {
          final groundCubit = context.read<GroundCubit>();

          final currentState = groundCubit.state;
          bool shouldFetch = true;
          if (currentState is GroundLoaded) {
            final cityName = state.city!.split(',').first.trim().toLowerCase();
            if (currentState.allGrounds.isNotEmpty) {
              final firstGroundCity =
                  currentState.allGrounds.first.city.toLowerCase();
              if (firstGroundCity.contains(cityName) ||
                  cityName.contains(firstGroundCity)) {
                shouldFetch = false;
              }
            }
          }

          if (shouldFetch) {
            groundCubit.getGrounds(
              city: state.city,
              userLat: state.hasGpsLocation ? state.latitude : null,
              userLng: state.hasGpsLocation ? state.longitude : null,
            );
          }
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Column(
          children: [
            _buildPremiumHeader(context, isDark),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primaryDarkGreen,
                onRefresh: () async {
                  HapticFeedback.lightImpact();
                  final sportCubit = context.read<SportCubit>();
                  final locationCubit = context.read<LocationCubit>();
                  final groundCubit = context.read<GroundCubit>();
                  
                  // Refresh sports
                  await sportCubit.fetchSports();
                  
                  // Refresh grounds
                  final locationState = locationCubit.state;
                  if (locationState.city != null && locationState.city != "Fetching...") {
                    await groundCubit.getGrounds(
                      city: locationState.city,
                      userLat: locationState.hasGpsLocation ? locationState.latitude : null,
                      userLng: locationState.hasGpsLocation ? locationState.longitude : null,
                    );
                  } else {
                    await groundCubit.getGrounds();
                  }
                },
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  slivers: [
                    // Search Bar
                    SliverToBoxAdapter(child: _buildSearchBar(context, isDark)),
  
                    // Sport Selection
                    SliverToBoxAdapter(
                        child: _buildSportSelection(context, isDark)),
  
                    // Top Venues (Horizontal)
                    SliverToBoxAdapter(
                        child: _buildTopVenuesSection(context, isDark)),
  
                    // Nearby Venues Header
                    SliverToBoxAdapter(
                        child: _buildNearbyVenuesHeader(context, isDark)),
  
                    // Nearby Venues (Vertical List)
                    _buildNearbyVenuesList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── PREMIUM HEADER ───────────────────────────────────────────
  Widget _buildPremiumHeader(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0B8457), Color(0xFF065B3C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDarkGreen.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -40,
            right: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            top: 60,
            right: 40,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),

          // Content
          Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20,
              left: 20,
              right: 20,
              bottom: 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: City + Notification
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    BlocBuilder<LocationCubit, LocationState>(
                      builder: (context, state) {
                        final city = state.city ?? "Fetching...";
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Theme.of(context).cardColor,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(20)),
                              ),
                              builder: (_) => const CitySearchBottomSheet(),
                            );
                          },
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const HugeIcon(
                                  icon: HugeIcons.strokeRoundedLocation01,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              AppText(
                                text: city,
                                size: 14,
                                weight: FontWeight.w600,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              HugeIcon(
                                icon: HugeIcons.strokeRoundedArrowDown01,
                                color: Colors.white.withValues(alpha: 0.6),
                                size: 16,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    BlocBuilder<NotificationCubit, NotificationState>(
                      builder: (context, state) {
                        final bool hasUnread = state.unreadCount > 0;
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.pushNamed(
                                context, AppRoutes.notification);
                          },
                          child: _buildNotificationBell(hasUnread),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Greeting
                AppText(
                  text: _greeting(),
                  size: 14,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
                const SizedBox(height: 4),
                AppText(
                  text: "Find your perfect turf",
                  size: 26,
                  weight: FontWeight.w800,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(
          begin: -0.1,
          end: 0,
          duration: 400.ms,
          curve: Curves.easeOutCubic,
        );
  }

  Widget _buildNotificationBell(bool hasUnread) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          const HugeIcon(
            icon: HugeIcons.strokeRoundedNotification03,
            color: Colors.white,
            size: 20,
          ),
          if (hasUnread)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── SEARCH BAR ──────────────────────────────────────────────
  Widget _buildSearchBar(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.pushNamed(context, AppRoutes.search);
        },
        child: Hero(
          tag: 'search_bar',
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : AppColors.borderLight,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color:
                      Colors.black.withValues(alpha: isDark ? 0.1 : 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color:
                        AppColors.primaryDarkGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const HugeIcon(
                    icon: HugeIcons.strokeRoundedSearch01,
                    size: 16,
                    color: AppColors.primaryDarkGreen,
                  ),
                ),
                const SizedBox(width: 12),
                AppText(
                  text: "Search grounds, sports...",
                  textStyle: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.4),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms);
  }

  // ─── TOP VENUES (Horizontal) ──────────────────────────────────
  Widget _buildTopVenuesSection(BuildContext context, bool isDark) {
    return BlocBuilder<GroundCubit, GroundState>(
      builder: (context, state) {
        if (state is! GroundLoaded || state.allGrounds.isEmpty) {
          return const SizedBox.shrink();
        }

        // Get top rated venues (rating >= 4.0 or top 5 by rating)
        final topVenues = List<GroundModel>.from(state.allGrounds)
          ..sort((a, b) => b.rating.compareTo(a.rating));
        final displayTopVenues = topVenues.where((g) => g.rating >= 4.0).take(10).toList();
        if (displayTopVenues.isEmpty && topVenues.isNotEmpty) {
          displayTopVenues.addAll(topVenues.take(5));
        }

        if (displayTopVenues.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSizes.sm),
                    decoration: BoxDecoration(
                      color: AppColors.accentOrange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    ),
                    child: const HugeIcon(
                      icon: HugeIcons.strokeRoundedStar,
                      color: AppColors.accentOrange,
                      size: AppSizes.iconMd,
                    ),
                  ),
                  const SizedBox(width: AppSizes.md),
                  const AppText(
                    text: "Top Venues",
                    size: 18,
                    weight: FontWeight.w700,
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 310,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: displayTopVenues.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  return _AnimatedGroundCard(
                    index: index,
                    child: SizedBox(
                      width: 260,
                      child: GroundCard(
                        ground: displayTopVenues[index],
                        showAmenities: false,
                        isGrid: false,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ).animate().fadeIn(delay: 400.ms, duration: 400.ms);
      },
    );
  }

  // ─── NEARBY VENUES HEADER ─────────────────────────────────────
  Widget _buildNearbyVenuesHeader(BuildContext context, bool isDark) {
    return BlocBuilder<GroundCubit, GroundState>(
      builder: (context, state) {
        final count = (state is GroundLoaded) ? state.grounds.length : 0;

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSizes.sm),
                    decoration: BoxDecoration(
                      color: AppColors.primaryDarkGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    ),
                    child: const HugeIcon(
                      icon: HugeIcons.strokeRoundedCompass,
                      color: AppColors.primaryDarkGreen,
                      size: AppSizes.iconMd,
                    ),
                  ),
                  const SizedBox(width: AppSizes.md),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppText(
                        text: "Nearby Venues",
                        size: 18,
                        weight: FontWeight.w700,
                      ),
                      if (count > 0) ...[
                        const SizedBox(height: 2),
                        AppText(
                          text: "$count venue${count == 1 ? '' : 's'} found",
                          size: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.5),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),
        ).animate().fadeIn(delay: 500.ms, duration: 400.ms);
      },
    );
  }

  // ─── NEARBY VENUES LIST (Vertical) ────────────────────────────
  Widget _buildNearbyVenuesList() {
    return BlocBuilder<GroundCubit, GroundState>(
      builder: (context, state) {
        if (state is GroundLoading || state is GroundInitial) {
          return SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: _buildSkeletonCard(),
              ),
              childCount: 4,
            ),
          );
        }

        if (state is GroundLoaded) {
          if (state.grounds.isEmpty) {
            return _buildEmptyState();
          }

          return SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _AnimatedGroundCard(
                      index: index,
                      child: GroundCard(
                        ground: state.grounds[index],
                        showAmenities: true,
                        isGrid: false,
                      ),
                    ),
                  );
                },
                childCount: state.grounds.length,
              ),
            ),
          );
        }

        if (state is GroundError) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: _buildErrorState(state.message),
          );
        }

        return const SliverToBoxAdapter(child: SizedBox());
      },
    );
  }

  // ─── SPORT SELECTION ─────────────────────────────────────────
  Widget _buildSportSelection(BuildContext context, bool isDark) {
    return BlocBuilder<GroundCubit, GroundState>(
      builder: (context, state) {
        final currentSportId =
            (state is GroundLoaded) ? (state.criteria.sportId ?? 'all') : 'all';

        return BlocBuilder<SportCubit, SportState>(
          builder: (context, sportState) {
            final sports = sportState is SportLoaded ? sportState.sports : <SportModel>[];
            final sportCategories = <Map<String, dynamic>>[
              {
                'id': 'all',
                'name': 'All',
                'icon': HugeIcons.strokeRoundedDashboardSquare01,
                'color': AppColors.primaryDarkGreen,
              },
              ...sports.map((s) => <String, dynamic>{
                'id': s.slug,
                'name': s.name,
                'icon_url': s.iconUrl,
                'local_asset': s.localAsset,
                'color': Color(int.parse(s.color.replaceFirst('#', '0xFF'))),
              }),
            ];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSizes.sm),
                        decoration: BoxDecoration(
                          color: AppColors.primaryDarkGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                        ),
                        child: const HugeIcon(
                          icon: HugeIcons.strokeRoundedCricketBat,
                          color: AppColors.primaryDarkGreen,
                          size: AppSizes.iconMd,
                        ),
                      ),
                      const SizedBox(width: AppSizes.md),
                      const AppText(
                        text: "Popular Sports",
                        size: 18,
                        weight: FontWeight.w700,
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: sportCategories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final sport = sportCategories[index];
                      final isSelected = currentSportId == sport['id'];

                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: Duration(milliseconds: 400 + (index * 80)),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(30 * (1 - value), 0),
                              child: child,
                            ),
                          );
                        },
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            if (sport['id'] != 'all') {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.categoryGrounds,
                                arguments: sport['name'],
                              );
                            }
                          },
                          child: Column(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOutCubic,
                                width: 64,
                                height: 64,
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  gradient: isSelected
                                      ? LinearGradient(
                                          colors: [
                                            AppColors.primaryDarkGreen,
                                            AppColors.primaryLightGreen,
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        )
                                      : null,
                                  color: isSelected
                                      ? null
                                      : isDark
                                          ? Colors.white.withValues(alpha: 0.06)
                                          : Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primaryDarkGreen
                                        : isDark
                                            ? Colors.white.withValues(alpha: 0.08)
                                            : AppColors.borderLight,
                                    width: 1.5,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: AppColors.primaryDarkGreen
                                                .withValues(alpha: 0.3),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          )
                                        ]
                                      : null,
                                ),
                                child: sport['icon_url'] != null && sport['icon_url'] != ''
                                    ? ClipOval(
                                        child: CachedNetworkImage(
                                          imageUrl: sport['icon_url'],
                                          width: 40,
                                          height: 40,
                                          fit: BoxFit.cover,
                                          placeholder: (_, __) => const SizedBox(
                                            width: 40,
                                            height: 40,
                                          ),
                                          errorWidget: (_, __, ___) => Icon(
                                            Icons.sports,
                                            size: 28,
                                            color: isSelected
                                                ? Colors.white
                                                : AppColors.primaryDarkGreen,
                                          ),
                                        ),
                                      )
                                    : sport['local_asset'] != null && sport['local_asset'] != ''
                                        ? ClipOval(
                                            child: Image.asset(
                                              sport['local_asset'],
                                              width: 40,
                                              height: 40,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => Icon(
                                                Icons.sports,
                                                size: 28,
                                                color: isSelected
                                                    ? Colors.white
                                                    : AppColors.primaryDarkGreen,
                                              ),
                                            ),
                                          )
                                        : Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: HugeIcon(
                                              icon: sport['icon'] ?? HugeIcons.strokeRoundedDashboardSquare01,
                                          color: isSelected
                                              ? Colors.white
                                              : AppColors.primaryDarkGreen,
                                          size: 28,
                                        ),
                                      ),
                              ),
                              const SizedBox(height: 8),
                              AppText(
                                text: sport['name'],
                                size: 12,
                                weight:
                                    isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected
                                    ? AppColors.primaryDarkGreen
                                    : Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.6),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ─── SKELETON CARD ───────────────────────────────────────────
  Widget _buildSkeletonCard() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.hardEdge,
      child: const GroundSkeleton(),
    );
  }

  // ─── EMPTY STATE ─────────────────────────────────────────────
  Widget _buildEmptyState() {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primaryDarkGreen.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const HugeIcon(
                  icon: HugeIcons.strokeRoundedSearch01,
                  size: 48,
                  color: AppColors.primaryDarkGreen,
                ),
              ).animate().scale(
                    delay: 200.ms,
                    duration: 500.ms,
                    curve: Curves.easeOutBack,
                  ),
              const SizedBox(height: 20),
              AppText(
                text: "No venues found",
                size: 18,
                weight: FontWeight.w700,
              ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
              const SizedBox(height: 8),
              AppText(
                text: "Try changing your sport or location",
                size: 13,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
              ).animate().fadeIn(delay: 500.ms, duration: 400.ms),
            ],
          ),
        ),
      ),
    );
  }

  // ─── ERROR STATE ─────────────────────────────────────────────
  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const HugeIcon(
                icon: HugeIcons.strokeRoundedAlertCircle,
                size: 48,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 20),
            AppText(
              text: "Something went wrong",
              size: 18,
              weight: FontWeight.w700,
            ),
            const SizedBox(height: 8),
            AppText(
              text: message,
              size: 13,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

}

// ─── ANIMATED GROUND CARD WRAPPER ──────────────────────────────
class _AnimatedGroundCard extends StatelessWidget {
  final int index;
  final Widget child;

  const _AnimatedGroundCard({
    required this.index,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 500 + (index * 100)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
