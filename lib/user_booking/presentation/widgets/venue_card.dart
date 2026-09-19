import 'dart:math';
import 'package:turfpro/common/constants/colors.dart';
import 'package:turfpro/user_booking/presentation/blocs/location/location_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:turfpro/user_booking/presentation/blocs/saved_ground/saved_ground_cubit.dart';


import 'package:turfpro/user_booking/constants/text_theme.dart';
import 'package:turfpro/user_booking/constants/widgets/app_text.dart';
import 'package:turfpro/user_booking/data/models/venue_model.dart';
import 'package:turfpro/user_booking/constants/route_constants.dart';
import 'package:turfpro/user_booking/presentation/widgets/ground_image_carousel.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:turfpro/user_booking/presentation/widgets/slot_selection_widgets.dart';

class VenueCard extends StatefulWidget {
  final VenueModel venue;
  final String? preferredSport;
  final bool showAmenities;
  final bool isGrid;
  final bool isCompact;

  const VenueCard({
    super.key,
    required this.venue,
    this.preferredSport,
    this.showAmenities = true,
    this.isGrid = false,
    this.isCompact = false,
  });

  @override
  State<VenueCard> createState() => _VenueCardState();
}

class _VenueCardState extends State<VenueCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: (_) => _pressController.forward(),
      onTapUp: (_) {
        _pressController.reverse();
        if (widget.venue.pitches.isEmpty) return;
        Navigator.pushNamed(
          context,
          AppRoutes.slotSelection,
          arguments: {
            'ground': widget.venue.pitches.first,
            'preferredSport': widget.preferredSport,
          },
        );
      },
      onTapCancel: () => _pressController.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
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
                color: Colors.black.withValues(
                    alpha: isDark ? 0.2 : 0.06),
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImageSlider(context),
              _buildInfo(context, onSurface, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSlider(BuildContext context) {
    return Stack(
      children: [
        GroundImageCarousel(
          images: widget.venue.images,
          fallbackImageUrl: widget.venue.imageUrl,
          height: widget.isGrid
              ? 110
              : widget.isCompact
                  ? 120
                  : 160,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),

        // Gradient overlay at bottom of image
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: widget.isCompact ? 42 : 60,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(0)),
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
        if (widget.venue.city.isNotEmpty)
          Positioned(
            bottom: 6,
            left: 8,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedLocation01,
                    size: widget.isCompact ? 10 : 12,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 4),
                AppText(
                  text: widget.venue.city,
                  size: widget.isCompact ? 12 : 14,
                  weight: FontWeight.w700,
                  color: Colors.white,
                ),
              ],
            ),
          ),

        // Favorite Button
        Positioned(
          top: widget.isCompact ? 8 : 10,
          right: widget.isCompact ? 8 : 10,
          child: BlocBuilder<SavedGroundCubit, SavedGroundState>(
            builder: (context, state) {
              final isSaved = state.favoriteIds.contains(widget.venue.locationId);
              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    context
                        .read<SavedGroundCubit>()
                        .toggleFavorite(user.uid, widget.venue.locationId);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("Please login to save grounds")),
                    );
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.all(widget.isCompact ? 5 : 7),
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
                      ? Icon(
                          Icons.favorite,
                          color: Colors.white,
                          size: widget.isCompact ? 13 : 15,
                        )
                      : HugeIcon(
                          icon: HugeIcons.strokeRoundedFavourite,
                          color: Colors.white.withValues(alpha: 0.8),
                          size: widget.isCompact ? 13 : 15,
                        ),
                ),
              );
            },
          ),
        ),

        // Rating Badge
        Positioned(
          top: widget.isCompact ? 8 : 10,
          left: widget.isCompact ? 8 : 10,
          child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: widget.isCompact ? 5 : 7,
                vertical: widget.isCompact ? 3 : 4,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(widget.isCompact ? 6 : 8),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.star_rounded,
                    size: widget.isCompact ? 12 : 14,
                    color: AppColors.goldenYellow,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    "${widget.venue.rating.toStringAsFixed(1)} (${widget.venue.totalReviews})",
                    style: TextStyle(
                      fontSize: widget.isCompact ? 10 : 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInfo(BuildContext context, Color onSurface, bool isDark) {
    final now = DateTime.now();
    final isWeekend = now.weekday == DateTime.saturday || now.weekday == DateTime.sunday;

    final double sportIconSize = widget.isCompact ? 25 : 28;

    return Padding(
      padding: widget.isCompact
          ? const EdgeInsets.fromLTRB(10, 8, 10, 8)
          : const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name
          AppText(
            text: widget.venue.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textStyle: AppTextTheme.black16.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: isWeekend && widget.venue.pitches.first.weekendPrice > 0
                  ? AppColors.primaryDarkGreen
                  : (isDark ? Colors.white : AppColors.black),
            ),
          ),

          SizedBox(height: widget.isCompact ? 4 : 6),

          // Address
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1.5),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedLocation01,
                  size: widget.isCompact ? 13 : 14,
                  color: onSurface.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: AppText(
                  text: widget.venue.address.isNotEmpty
                      ? widget.venue.address
                      : "Location not available",
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textStyle: TextStyle(
                    fontSize: widget.isCompact ? 11.5 : 12,
                    color: onSurface.withValues(alpha: 0.5),
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: widget.isCompact ? 2 : 3),

          // Distance from user
          BlocBuilder<LocationCubit, LocationState>(
            builder: (context, state) {
              final double? originLat = state.gpsLatitude ?? state.latitude;
              final double? originLng = state.gpsLongitude ?? state.longitude;

              if (originLat != null && originLng != null) {
                final distance = _calculateDistance(
                  originLat,
                  originLng,
                  widget.venue.latitude,
                  widget.venue.longitude,
                );
                return Row(
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedNavigation01,
                      size: widget.isCompact ? 10 : 11,
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

          // Sports row
          if (widget.venue.availableSports.isNotEmpty) ...[
            SizedBox(height: widget.isCompact ? 5 : 8),
            SizedBox(
              height: sportIconSize,
              child: Row(
                children: [
                  ...widget.venue.availableSports.take(4).map((sportSlug) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 5),
                      child: Container(
                        width: sportIconSize,
                        height: sportIconSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primaryDarkGreen.withValues(alpha: 0.08),
                          border: Border.all(
                            color: AppColors.primaryDarkGreen.withValues(alpha: 0.35),
                            width: 0.8,
                          ),
                        ),
                        child: ClipOval(
                          child: SlotSelectionWidgets.buildSportIcon(
                            sportSlug,
                            size: sportIconSize,
                          ),
                        ),
                      ),
                    );
                  }),
                  if (widget.venue.availableSports.length > 4)
                    Container(
                      width: sportIconSize,
                      height: sportIconSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryDarkGreen.withValues(alpha: 0.1),
                        border: Border.all(
                          color: AppColors.primaryDarkGreen.withValues(alpha: 0.35),
                          width: 0.8,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        "+${widget.venue.availableSports.length - 4}",
                        style: TextStyle(
                          fontSize: widget.isCompact ? 9.5 : 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDarkGreen,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],

          SizedBox(height: widget.isCompact ? 5 : 8),

          // Price row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: "₹${widget.venue.pitches.first.pricePerHour}",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDarkGreen,
                        ),
                      ),
                      TextSpan(
                        text: "/hr",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
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
