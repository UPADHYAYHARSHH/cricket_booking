import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:turfpro/common/constants/colors.dart';
import 'package:turfpro/user_booking/constants/text_theme.dart';
import 'package:turfpro/user_booking/constants/widgets/app_text.dart';
import 'package:turfpro/user_booking/data/models/location_model.dart';
import 'package:turfpro/user_booking/data/models/sport_model.dart';
import 'package:turfpro/user_booking/constants/route_constants.dart';
import 'package:turfpro/user_booking/constants/widgets/app_network_image.dart';
import 'package:turfpro/user_booking/presentation/blocs/location/location_cubit.dart';
import 'package:turfpro/user_booking/presentation/blocs/saved_ground/saved_ground_cubit.dart';
import 'package:turfpro/user_booking/presentation/blocs/sport/sport_cubit.dart';
import 'package:turfpro/user_booking/presentation/blocs/sport/sport_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:turfpro/user_booking/presentation/widgets/ground_image_carousel.dart';

class LocationCard extends StatelessWidget {
  final LocationModel location;
  final bool showAmenities;
  final bool isGrid;

  const LocationCard({
    super.key,
    required this.location,
    this.showAmenities = true,
    this.isGrid = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.pushNamed(
          context,
          AppRoutes.slotSelection,
          arguments: location,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : AppColors.borderLight,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              blurRadius: 16,
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
              offset: const Offset(0, 4),
            )
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildImageSection(context, isDark),
            ClipRect(
              child: _buildInfoSection(context, onSurface, isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection(BuildContext context, bool isDark) {
    return Stack(
      children: [
        // Image Carousel
        GroundImageCarousel(
          images: location.images,
          fallbackImageUrl: location.images.isNotEmpty ? location.images.first : '',
          height: isGrid ? 85 : 110,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),

        // Gradient overlay
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 60,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(0)),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.6),
                ],
              ),
            ),
          ),
        ),

        // City name on image
        Positioned(
          bottom: 6,
          left: 8,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const HugeIcon(
                  icon: HugeIcons.strokeRoundedLocation01,
                  size: 12,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 6),
              AppText(
                text: location.city,
                size: 14,
                weight: FontWeight.w700,
                color: Colors.white,
              ),
            ],
          ),
        ),

        // Rating badge (top-right)
        if (location.totalReviews > 0)
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.star_rounded,
                    size: 13,
                    color: AppColors.goldenYellow,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    location.rating.toString(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Favorite button (top-left)
        Positioned(
          top: 6,
          left: 6,
          child: BlocBuilder<SavedGroundCubit, SavedGroundState>(
            builder: (context, state) {
              final isSaved = state.favoriteIds.contains(location.id);
              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    context
                        .read<SavedGroundCubit>()
                        .toggleFavorite(user.uid, location.id);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("Please login to save venues")),
                    );
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isSaved
                        ? AppColors.error
                        : Colors.black.withValues(alpha: 0.35),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: isSaved
                      ? const Icon(
                          Icons.favorite,
                          color: Colors.white,
                          size: 14,
                        )
                      : HugeIcon(
                          icon: HugeIcons.strokeRoundedFavourite,
                          color: Colors.white.withValues(alpha: 0.8),
                          size: 14,
                        ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection(BuildContext context, Color onSurface, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        // clipBehavior: Clip.hardEdge,
        children: [
          // Address
          AppText(
            text: location.address.isNotEmpty
                ? location.address
                : "${location.city} Area",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textStyle: AppTextTheme.black14.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 3),

          // Distance from user
          BlocBuilder<LocationCubit, LocationState>(
            builder: (context, state) {
              final double? originLat = state.gpsLatitude ?? state.latitude;
              final double? originLng = state.gpsLongitude ?? state.longitude;

              if (originLat != null && originLng != null) {
                final distance = _calculateDistance(
                  originLat,
                  originLng,
                  location.latitude,
                  location.longitude,
                );
                return Row(
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedNavigation01,
                      size: 11,
                      color: AppColors.primaryDarkGreen,
                    ),
                    const SizedBox(width: 3),
                    AppText(
                      text: "${distance.toStringAsFixed(1)} km away",
                      size: 10,
                      color: onSurface.withValues(alpha: 0.5),
                    ),
                  ],
                );
              }
              return const SizedBox();
            },
          ),

          // Sports icons row
          if (location.sports.isNotEmpty) ...[
            const SizedBox(height: 3),
            BlocBuilder<SportCubit, SportState>(
              builder: (context, sportState) {
                final sports = sportState is SportLoaded ? sportState.sports : <SportModel>[];
                return SizedBox(
                  height: 20,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: location.sports.length > 5
                        ? 5
                        : location.sports.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 4),
                    itemBuilder: (context, index) {
                      final sportSlug = location.sports[index];
                      SportModel? sportData;
                      try {
                        sportData = sports.firstWhere((s) => s.slug == sportSlug);
                      } catch (_) {}
                      return Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: AppColors.accentOrange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: sportData != null && sportData.iconUrl.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: CachedNetworkImage(
                                  imageUrl: sportData.iconUrl,
                                  width: 16,
                                  height: 16,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => const SizedBox(
                                    width: 16,
                                    height: 16,
                                  ),
                                  errorWidget: (_, __, ___) => Icon(
                                    Icons.sports,
                                    size: 14,
                                    color: AppColors.accentOrange,
                                  ),
                                ),
                              )
                            : sportData != null && sportData.localAsset.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(2),
                                    child: Image.asset(
                                      sportData.localAsset,
                                      width: 16,
                                      height: 16,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Icon(
                                        Icons.sports,
                                        size: 14,
                                        color: AppColors.accentOrange,
                                      ),
                                    ),
                                  )
                                : Icon(
                                    Icons.sports,
                                    size: 14,
                                    color: AppColors.accentOrange,
                              ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295;
    var a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }
}
