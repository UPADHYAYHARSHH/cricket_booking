import 'dart:math';
import 'package:turfpro/common/constants/colors.dart';
import 'package:turfpro/user_booking/constants/widgets/app_sizedBox.dart';
import 'package:turfpro/user_booking/presentation/blocs/location/location_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:turfpro/user_booking/presentation/blocs/saved_ground/saved_ground_cubit.dart';

import 'package:turfpro/user_booking/constants/route_constants.dart';
import 'package:turfpro/user_booking/constants/text_theme.dart';
import 'package:turfpro/user_booking/constants/widgets/app_text.dart';
import 'package:turfpro/user_booking/data/models/ground_model.dart';
import 'package:turfpro/user_booking/presentation/widgets/ground_image_carousel.dart';
import 'package:turfpro/user_booking/presentation/widgets/slot_selection_widgets.dart';

class GroundCard extends StatefulWidget {
  final GroundModel ground;

  const GroundCard({
    super.key,
    required this.ground,
  });

  @override
  State<GroundCard> createState() => _GroundCardState();
}

class _GroundCardState extends State<GroundCard> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            color: Colors.black.withValues(
                alpha: theme.brightness == Brightness.dark ? 0.2 : 0.06),
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            Navigator.pushNamed(
              context,
              AppRoutes.slotSelection,
              arguments: widget.ground,
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImageSlider(context),
              _buildInfo(context, onSurface),
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
          images: widget.ground.images,
          fallbackImageUrl: widget.ground.imageUrl,
          height: 160,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        ),

        // Favorite Button
        Positioned(
          top: 12,
          right: 12,
          child: BlocBuilder<SavedGroundCubit, SavedGroundState>(
            builder: (context, state) {
              final isSaved = state.favoriteIds.contains(widget.ground.id);
              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  final user = Supabase.instance.client.auth.currentUser;
                  if (user != null) {
                    context
                        .read<SavedGroundCubit>()
                        .toggleFavorite(user.id, widget.ground.id);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("Please login to save grounds")),
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: isSaved
                      ? const Icon(
                          Icons.favorite,
                          color: AppColors.error,
                          size: 18,
                        )
                      : HugeIcon(
                          icon: HugeIcons.strokeRoundedFavourite,
                          color: Colors.grey.withValues(alpha: 0.5),
                          size: 18,
                        ),
                ),
              );
            },
          ),
        ),

        // Distance Badge
        Positioned(
          bottom: 12,
          left: 12,
          child: BlocBuilder<LocationCubit, LocationState>(
            builder: (context, state) {
              final double? originLat = state.gpsLatitude ?? state.latitude;
              final double? originLng = state.gpsLongitude ?? state.longitude;

              if (originLat != null && originLng != null) {
                final distance = _calculateDistance(
                  originLat,
                  originLng,
                  widget.ground.latitude,
                  widget.ground.longitude,
                );
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const HugeIcon(
                        icon: HugeIcons.strokeRoundedLocation01,
                        size: 14,
                        color: AppColors.white,
                      ),
                      const AppSizedBox(width: 4),
                      AppText(
                        text: "${distance.toStringAsFixed(1)} km",
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.white,
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
      ],
    );
  }

  Widget _buildInfo(BuildContext context, Color onSurface) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: AppText(
                  text: widget.ground.name,
                  textStyle: AppTextTheme.black16.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const AppSizedBox(width: 8),

              // Rating Badge
              if (widget.ground.totalReviews > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.goldenYellow.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 16,
                        color: AppColors.goldenYellow,
                      ),
                      const AppSizedBox(width: 4),
                      AppText(
                        text: widget.ground.rating.toString(),
                        textStyle: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: theme.brightness == Brightness.dark
                              ? AppColors.goldenYellow
                              : const Color(0xFF856404),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          if (widget.ground.categories.isNotEmpty) ...[
            const AppSizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: widget.ground.categories.map((category) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryDarkGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: AppColors.primaryDarkGreen.withValues(alpha: 0.2)),
                  ),
                  child: AppText(
                    text: category,
                    textStyle: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryDarkGreen,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],

          const AppSizedBox(height: 8),

          // Address
          Row(
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedLocation01,
                size: 14,
                color: onSurface.withValues(alpha: 0.5),
              ),
              const AppSizedBox(width: 4),
              Expanded(
                child: AppText(
                  text: widget.ground.address,
                  textStyle: AppTextTheme.black12.copyWith(
                    color: onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          ),

          if (widget.ground.amenities.isNotEmpty) ...[
            const AppSizedBox(height: 10),
            Row(
              children: widget.ground.amenities.take(3).map((amenity) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Row(
                    children: [
                      HugeIcon(
                        icon: SlotSelectionWidgets.getAmenityHugeIcon(amenity),
                        size: 14,
                        color: AppColors.primaryDarkGreen,
                      ),
                      const AppSizedBox(width: 4),
                      AppText(
                        text: amenity,
                        textStyle: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],

          const AppSizedBox(height: 14),

          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Price Label
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    text: "Price",
                    textStyle: AppTextTheme.black12.copyWith(
                      color: onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  AppText(
                    text: "₹${widget.ground.pricePerHour}/hr",
                    textStyle: AppTextTheme.black18.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDarkGreen,
                    ),
                  ),
                ],
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
