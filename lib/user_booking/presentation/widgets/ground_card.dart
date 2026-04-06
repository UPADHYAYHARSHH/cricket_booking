import 'dart:math';
import 'package:bloc_structure/common/constants/colors.dart';
import 'package:bloc_structure/user_booking/constants/widgets/app_sizedBox.dart';
import 'package:bloc_structure/user_booking/presentation/blocs/location/location_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bloc_structure/user_booking/presentation/blocs/saved_ground/saved_ground_cubit.dart';

import 'package:bloc_structure/user_booking/constants/route_constants.dart';
import 'package:bloc_structure/user_booking/constants/text_theme.dart';
import 'package:bloc_structure/user_booking/constants/widgets/app_network_image.dart';
import 'package:bloc_structure/user_booking/constants/widgets/app_text.dart';
import 'package:bloc_structure/user_booking/data/models/ground_model.dart';

class GroundCard extends StatelessWidget {
  final GroundModel ground;

  const GroundCard({
    super.key,
    required this.ground,
  });

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
            color: Colors.black.withOpacity(0.06),
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImageStack(context),
          _buildInfo(context, onSurface),
        ],
      ),
    );
  }

  Widget _buildImageStack(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(18),
          ),
          child: AppNetworkImage(
            imageUrl: ground.imageUrl.isNotEmpty
                ? ground.imageUrl
                : "https://images.unsplash.com/photo-1540747913346-19e32dc3e97e",
            height: 160,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        
        // Favorite Button
        Positioned(
          top: 12,
          right: 12,
          child: BlocBuilder<SavedGroundCubit, SavedGroundState>(
            builder: (context, state) {
              final isSaved = state.favoriteIds.contains(ground.id);
              return GestureDetector(
                onTap: () {
                  final user = Supabase.instance.client.auth.currentUser;
                  if (user != null) {
                    context
                        .read<SavedGroundCubit>()
                        .toggleFavorite(user.id, ground.id);
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
                    color: Theme.of(context).cardColor.withOpacity(0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
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
                          color: Colors.grey.withOpacity(0.5),
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
              if (state.latitude != null && state.longitude != null) {
                final distance = _calculateDistance(
                  state.latitude!,
                  state.longitude!,
                  ground.latitude,
                  ground.longitude,
                );
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.65),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
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
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: AppText(
                  text: ground.name,
                  textStyle: AppTextTheme.black16.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const AppSizedBox(width: 8),
              
              // Rating Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.goldenYellow.withOpacity(0.12),
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
                      text: ground.rating.toString(),
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF856404),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const AppSizedBox(height: 6),

          // Address
          Row(
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedLocation01,
                size: 14,
                color: onSurface.withOpacity(0.5),
              ),
              const AppSizedBox(width: 4),
              Expanded(
                child: AppText(
                  text: ground.address,
                  textStyle: AppTextTheme.black12.copyWith(
                    color: onSurface.withOpacity(0.5),
                  ),
                ),
              ),
            ],
          ),

          const AppSizedBox(height: 14),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Price Label
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   AppText(
                    text: "Price",
                    textStyle: AppTextTheme.black12.copyWith(
                      color: onSurface.withOpacity(0.5),
                    ),
                  ),
                  AppText(
                    text: "₹${ground.pricePerHour}/hr",
                    textStyle: AppTextTheme.black18.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDarkGreen,
                    ),
                  ),
                ],
              ),

              // Book Now Button
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.slotSelection,
                    arguments: ground,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDarkGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text(
                  "Book Now",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
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
