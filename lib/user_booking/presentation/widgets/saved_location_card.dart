import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:turfpro/common/constants/colors.dart';
import 'package:turfpro/user_booking/constants/text_theme.dart';
import 'package:turfpro/user_booking/constants/widgets/app_text.dart';
import 'package:turfpro/user_booking/constants/route_constants.dart';
import 'package:turfpro/user_booking/data/models/location_model.dart';
import 'package:turfpro/user_booking/data/models/venue_model.dart';
import 'package:turfpro/user_booking/presentation/blocs/location/location_cubit.dart';
import 'package:turfpro/user_booking/presentation/blocs/saved_ground/saved_ground_cubit.dart';
import 'package:turfpro/user_booking/presentation/widgets/ground_image_carousel.dart';
import 'package:turfpro/user_booking/presentation/widgets/slot_selection_widgets.dart';

class SavedLocationCard extends StatefulWidget {
  final LocationModel? location;
  final VenueModel? venue;
  final VoidCallback? onUnfavorite;

  const SavedLocationCard({
    super.key,
    this.location,
    this.venue,
    this.onUnfavorite,
  }) : assert(location != null || venue != null,
            'Either location or venue must be provided');

  @override
  State<SavedLocationCard> createState() => _SavedLocationCardState();
}

class _SavedLocationCardState extends State<SavedLocationCard>
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

  String get _id => widget.venue?.locationId ?? widget.location!.id;
  String get _name {
    if (widget.venue != null && widget.venue!.name.isNotEmpty && widget.venue!.name != '---') {
      return widget.venue!.name;
    }
    if (widget.location != null) {
      if (widget.location!.address.isNotEmpty) {
        return widget.location!.address.split(',').first.trim();
      }
      return "${widget.location!.city} Venue";
    }
    return "Venue";
  }

  String get _address => widget.venue?.address ?? widget.location?.address ?? '';
  String get _city => widget.venue?.city ?? widget.location?.city ?? '';
  double get _rating => widget.venue?.rating ?? widget.location?.rating ?? 0.0;
  int get _totalReviews => widget.venue?.totalReviews ?? widget.location?.totalReviews ?? 0;
  List<String> get _images => widget.venue?.images ?? widget.location?.images ?? [];
  String get _fallbackImage => widget.venue?.imageUrl ?? (_images.isNotEmpty ? _images.first : '');
  List<String> get _sports => widget.venue?.availableSports ?? widget.location?.sports ?? [];
  double get _latitude => widget.venue?.latitude ?? widget.location?.latitude ?? 0.0;
  double get _longitude => widget.venue?.longitude ?? widget.location?.longitude ?? 0.0;
  int? get _pricePerHour => widget.venue?.pitches.firstOrNull?.pricePerHour;

  void _onTapCard() {
    HapticFeedback.lightImpact();
    if (widget.venue != null && widget.venue!.pitches.isNotEmpty) {
      Navigator.pushNamed(
        context,
        AppRoutes.slotSelection,
        arguments: {
          'ground': widget.venue!.pitches.first,
        },
      );
    } else if (widget.location != null) {
      Navigator.pushNamed(
        context,
        AppRoutes.slotSelection,
        arguments: widget.location,
      );
    }
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
        _onTapCard();
      },
      onTapCancel: () => _pressController.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : AppColors.borderLight,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                blurRadius: 18,
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
                offset: const Offset(0, 6),
              )
            ],
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildImageHeader(context, isDark),
              _buildCardBody(context, onSurface, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageHeader(BuildContext context, bool isDark) {
    return Stack(
      children: [
        // Image Carousel
        GroundImageCarousel(
          images: _images,
          fallbackImageUrl: _fallbackImage.isNotEmpty
              ? _fallbackImage
              : "https://images.unsplash.com/photo-1540747913346-19e32dc3e97e",
          height: 155,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
          allowFullScreen: false,
        ),

        // Gradient overlay for readability
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 65,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.65),
                ],
              ),
            ),
          ),
        ),

        // City & Location Badge (Bottom-Left)
        if (_city.isNotEmpty)
          Positioned(
            bottom: 8,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const HugeIcon(
                    icon: HugeIcons.strokeRoundedLocation01,
                    size: 13,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  AppText(
                    text: _city,
                    size: 12,
                    weight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),

        // Rating Badge (Top-Right)
        if (_rating > 0)
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 0.8,
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
                    "${_rating.toStringAsFixed(1)} ($_totalReviews)",
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

        // Favorite Toggle Button (Top-Left)
        Positioned(
          top: 10,
          left: 10,
          child: BlocBuilder<SavedGroundCubit, SavedGroundState>(
            builder: (context, state) {
              final isSaved = state.favoriteIds.contains(_id);
              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    context.read<SavedGroundCubit>().toggleFavorite(user.uid, _id);
                    if (isSaved && widget.onUnfavorite != null) {
                      widget.onUnfavorite!();
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Please login to manage saved locations"),
                      ),
                    );
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: isSaved
                        ? AppColors.error
                        : Colors.black.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: isSaved
                      ? const Icon(
                          Icons.favorite,
                          color: Colors.white,
                          size: 15,
                        )
                      : HugeIcon(
                          icon: HugeIcons.strokeRoundedFavourite,
                          color: Colors.white.withValues(alpha: 0.9),
                          size: 15,
                        ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCardBody(BuildContext context, Color onSurface, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          AppText(
            text: _name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textStyle: AppTextTheme.black16.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: isDark ? Colors.white : AppColors.black,
            ),
          ),

          const SizedBox(height: 6),

          // Address Row
          Row(
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedLocation01,
                size: 14,
                color: onSurface.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: AppText(
                  text: _address.isNotEmpty ? _address : "Location not available",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textStyle: TextStyle(
                    fontSize: 12,
                    color: onSurface.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          // Distance from user
          BlocBuilder<LocationCubit, LocationState>(
            builder: (context, state) {
              final double? originLat = state.gpsLatitude ?? state.latitude;
              final double? originLng = state.gpsLongitude ?? state.longitude;

              if (originLat != null && originLng != null && _latitude != 0.0 && _longitude != 0.0) {
                final distance = _calculateDistance(
                  originLat,
                  originLng,
                  _latitude,
                  _longitude,
                );
                return Row(
                  children: [
                    const HugeIcon(
                      icon: HugeIcons.strokeRoundedNavigation01,
                      size: 12,
                      color: AppColors.primaryDarkGreen,
                    ),
                    const SizedBox(width: 4),
                    AppText(
                      text: "${distance.toStringAsFixed(1)} km away",
                      size: 11,
                      weight: FontWeight.w600,
                      color: AppColors.primaryDarkGreen,
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // Sports row
          if (_sports.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 28,
              child: Row(
                children: [
                  ..._sports.take(4).map((sportSlug) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primaryDarkGreen.withValues(alpha: 0.08),
                          border: Border.all(
                            color: AppColors.primaryDarkGreen.withValues(alpha: 0.35),
                            width: 1.0,
                          ),
                        ),
                        child: ClipOval(
                          child: SlotSelectionWidgets.buildSportIcon(
                            sportSlug,
                            size: 28,
                          ),
                        ),
                      ),
                    );
                  }),
                  if (_sports.length > 4)
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryDarkGreen.withValues(alpha: 0.1),
                        border: Border.all(
                          color: AppColors.primaryDarkGreen.withValues(alpha: 0.35),
                          width: 1.0,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        "+${_sports.length - 4}",
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDarkGreen,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),
          Divider(
            height: 1,
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : AppColors.borderLight,
          ),
          const SizedBox(height: 10),

          // Bottom Pricing & Book Button Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_pricePerHour != null && _pricePerHour! > 0)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      "₹$_pricePerHour",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDarkGreen,
                      ),
                    ),
                    Text(
                      "/hr",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryDarkGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Instant Slots",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),

              // Action Button
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF0B8457),
                      Color(0xFF065B3C),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryDarkGreen.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Book Now",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                  ],
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
