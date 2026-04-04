import 'dart:math';
import 'package:bloc_structure/common/constants/colors.dart';
import 'package:bloc_structure/user_booking/constants/widgets/app_sizedBox.dart';
import 'package:bloc_structure/user_booking/presentation/blocs/location/location_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bloc_structure/user_booking/presentation/blocs/saved_ground/saved_ground_cubit.dart';

import '../../../../constants/route_constants.dart';
import '../../../../constants/text_theme.dart';
import '../../../../constants/widgets/app_network_image.dart';
import '../../../../constants/widgets/app_text.dart';
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
            blurRadius: 8,
            color: Colors.black.withOpacity(0.05),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(18),
                ),
                child: AppNetworkImage(
                  imageUrl: ground.imageUrl.isNotEmpty
                      ? ground.imageUrl
                      : "https://images.unsplash.com/photo-1540747913346-19e32dc3e97e",
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                bottom: 10,
                left: 10,
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
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
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
              Positioned(
                top: 10,
                right: 10,
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
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: theme.cardColor.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedFavourite,
                          color: isSaved ? AppColors.error : onSurface.withOpacity(0.3),
                          size: 20,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  text: ground.name,
                  textStyle: AppTextTheme.black16,
                ),

                const AppSizedBox(height: 4),

                /// Address
                AppText(
                  text: ground.address,
                  textStyle: AppTextTheme.black14.copyWith(
                    color: onSurface.withOpacity(0.6),
                  ),
                ),

                const AppSizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    /// Price
                    AppText(
                      text: "₹${ground.pricePerHour}/hr",
                      textStyle: AppTextTheme.black12.copyWith(fontWeight: FontWeight.w700),
                    ),

                    /// Book Button
                    InkWell(
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.slotSelection,
                          arguments: ground,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryDarkGreen,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const AppText(
                          text: "Book",
                          textStyle: TextStyle(
                            color: AppColors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  /// Haversine Formula for distance calculation
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295;
    var a = 0.5 - cos((lat2 - lat1) * p) / 2 + cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }
}
