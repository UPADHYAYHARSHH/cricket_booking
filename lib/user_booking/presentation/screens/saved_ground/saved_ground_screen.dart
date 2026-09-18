import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../common/constants/colors.dart';
import '../../../constants/text_theme.dart';
import '../../../constants/widgets/app_text.dart';
import '../../../constants/route_constants.dart';
import '../../../data/models/location_model.dart';
import '../../../data/models/venue_model.dart';
import '../../blocs/ground/ground_cubit.dart';
import '../../blocs/ground/ground_state.dart';
import '../../blocs/location_list/location_list_cubit.dart';
import '../../blocs/saved_ground/saved_ground_cubit.dart';
import '../../widgets/saved_location_card.dart';

class SavedGroundsScreen extends StatefulWidget {
  const SavedGroundsScreen({super.key});

  @override
  State<SavedGroundsScreen> createState() => _SavedGroundsScreenState();
}

class _SavedGroundsScreenState extends State<SavedGroundsScreen> {
  Future<void> _onRefresh() async {
    HapticFeedback.lightImpact();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      context.read<SavedGroundCubit>().loadFavorites(user.uid);
    }
    context.read<LocationListCubit>().fetchLocations();
    context.read<GroundCubit>().getGrounds();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: BlocBuilder<SavedGroundCubit, SavedGroundState>(
        builder: (context, savedState) {
          return BlocBuilder<GroundCubit, GroundState>(
            builder: (context, groundState) {
              return BlocBuilder<LocationListCubit, LocationListState>(
                builder: (context, locationState) {
                  final favoriteIds = savedState.favoriteIds;

                  // 1. Check venues from GroundCubit
                  final List<VenueModel> allVenues = (groundState is GroundLoaded)
                      ? groundState.allVenues
                      : <VenueModel>[];

                  final List<VenueModel> savedVenues = allVenues.where((v) {
                    return favoriteIds.contains(v.locationId) ||
                        v.pitches.any((p) => favoriteIds.contains(p.id));
                  }).toList();

                  // 2. Check locations from LocationListCubit
                  final List<LocationModel> allLocations =
                      (locationState is LocationListLoaded)
                          ? locationState.locations
                          : <LocationModel>[];

                  final List<LocationModel> savedLocationsOnly =
                      allLocations.where((loc) {
                    final inVenues =
                        savedVenues.any((v) => v.locationId == loc.id);
                    return !inVenues && favoriteIds.contains(loc.id);
                  }).toList();

                  final totalSavedCount =
                      savedVenues.length + savedLocationsOnly.length;
                  final isLoading = (locationState is LocationListLoading ||
                          groundState is GroundLoading) &&
                      totalSavedCount == 0;

                  return RefreshIndicator(
                    onRefresh: _onRefresh,
                    color: AppColors.primaryDarkGreen,
                    backgroundColor: theme.cardColor,
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      slivers: [
                        SliverToBoxAdapter(
                          child: _buildHeader(context, totalSavedCount),
                        ),
                        if (isLoading)
                          const SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primaryDarkGreen,
                              ),
                            ),
                          )
                        else if (totalSavedCount == 0)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: _buildEmptyState(context, isDark),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  if (index < savedVenues.length) {
                                    final venue = savedVenues[index];
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 16),
                                      child: SavedLocationCard(
                                        key: ValueKey('venue_${venue.locationId}'),
                                        venue: venue,
                                      ),
                                    );
                                  } else {
                                    final locIndex =
                                        index - savedVenues.length;
                                    final location =
                                        savedLocationsOnly[locIndex];
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 16),
                                      child: SavedLocationCard(
                                        key: ValueKey('loc_${location.id}'),
                                        location: location,
                                      ),
                                    );
                                  }
                                },
                                childCount: totalSavedCount,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryDarkGreen.withValues(alpha: 0.1),
                border: Border.all(
                  color: AppColors.primaryDarkGreen.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: const Center(
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedFavourite,
                  size: 46,
                  color: AppColors.primaryDarkGreen,
                ),
              ),
            ),
            const SizedBox(height: 24),
            AppText(
              text: "No Saved Venues Yet",
              textStyle: AppTextTheme.black18.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 8),
            AppText(
              text:
                  "Tap the heart icon on any venue or ground to save it here for instant booking.",
              textStyle: TextStyle(
                fontSize: 14,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
                height: 1.4,
              ),
              align: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pushReplacementNamed(context, AppRoutes.nav);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDarkGreen,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 4,
                shadowColor:
                    AppColors.primaryDarkGreen.withValues(alpha: 0.3),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedCompass01,
                    size: 18,
                    color: Colors.white,
                  ),
                  SizedBox(width: 8),
                  Text(
                    "Explore Venues",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int count) {
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
            color: AppColors.primaryDarkGreen.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background ambient circular accents
          Positioned(
            top: -40,
            right: -30,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            top: 50,
            right: 50,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              left: 20,
              right: 20,
              bottom: 22,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const AppText(
                      text: "Saved Venues",
                      size: 22,
                      weight: FontWeight.w800,
                      color: AppColors.white,
                    ),
                    if (count > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.favorite,
                              size: 13,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "$count saved",
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                AppText(
                  text: "Your favorite sports turfs ready for quick booking.",
                  size: 13,
                  color: AppColors.white.withValues(alpha: 0.75),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

