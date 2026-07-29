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

class VenueCard extends StatefulWidget {
  final VenueModel venue;

  final bool showAmenities;
  final bool isGrid;

  const VenueCard({
    super.key,
    required this.venue,
    this.showAmenities = true,
    this.isGrid = false,
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
        Navigator.pushNamed(
          context,
          AppRoutes.slotSelection,
          arguments: widget.venue.pitches.first,
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
          height: widget.isGrid ? 110 : 160,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),

        // Gradient overlay at bottom of image
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 40,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(0)),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.3),
                ],
              ),
            ),
          ),
        ),

        // Favorite Button
        Positioned(
          top: 10,
          right: 10,
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
                  padding: const EdgeInsets.all(7),
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
                          size: 15,
                        )
                      : HugeIcon(
                          icon: HugeIcons.strokeRoundedFavourite,
                          color: Colors.white.withValues(alpha: 0.8),
                          size: 15,
                        ),
                ),
              );
            },
          ),
        ),

        // Distance Badge
        Positioned(
          bottom: 10,
          left: 10,
          child: BlocBuilder<LocationCubit, LocationState>(
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
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
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
                      const HugeIcon(
                        icon: HugeIcons.strokeRoundedLocation01,
                        size: 12,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "${distance.toStringAsFixed(1)} km",
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox();
            },
          ),
        ),

        // Rating Badge
        if (widget.venue.totalReviews > 0)
          Positioned(
            top: 10,
            left: 10,
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
                    size: 14,
                    color: AppColors.goldenYellow,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    widget.venue.rating.toString(),
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
      ],
    );
  }

  Widget _buildInfo(BuildContext context, Color onSurface, bool isDark) {
    final now = DateTime.now();
    final isWeekend = now.weekday == DateTime.saturday || now.weekday == DateTime.sunday;
    final displayDescription = "".isNotEmpty
        ? ""
        : widget.venue.address;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name
          AppText(
            text: widget.venue.name,
            textStyle: AppTextTheme.black16.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: isWeekend && widget.venue.pitches.first.weekendPrice > 0
                  ? AppColors.primaryDarkGreen
                  : (isDark ? Colors.white : AppColors.black),
            ),
          ),

          const SizedBox(height: 6),

          // Categories
          if (widget.venue.availableSports.isNotEmpty)
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: widget.venue.availableSports.map((category) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primaryDarkGreen.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: AppText(
                    text: category,
                    textStyle: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryDarkGreen,
                    ),
                  ),
                );
              }).toList(),
            ),

          const SizedBox(height: 6),

          // Description (if available)
          if (displayDescription.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: AppText(
                text: displayDescription,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textStyle: AppTextTheme.black12.copyWith(
                  color: onSurface.withValues(alpha: 0.6),
                  fontSize: 11,
                ),
              ),
            ),

          // Address
          Row(
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedLocation01,
                size: 12,
                color: onSurface.withValues(alpha: 0.4),
              ),
              const SizedBox(width: 3),
              Expanded(
                child: AppText(
                  text: widget.venue.address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textStyle: AppTextTheme.black12.copyWith(
                    color: onSurface.withValues(alpha: 0.5),
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

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
                        style: TextStyle(
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
                      if (widget.venue.pitches.first.weekendPrice > 0 &&
                          widget.venue.pitches.first.weekendPrice != widget.venue.pitches.first.pricePerHour) ...[
                        TextSpan(
                          text: "  •  Weekend: ₹${widget.venue.pitches.first.weekendPrice}/hr",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: AppColors.accentOrange,
                          ),
                        ),
                      ],
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
