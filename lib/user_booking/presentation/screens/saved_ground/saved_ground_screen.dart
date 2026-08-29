import 'package:turfpro/user_booking/data/models/location_model.dart';
import 'package:turfpro/user_booking/presentation/blocs/location_list/location_list_cubit.dart';
import 'package:turfpro/user_booking/presentation/blocs/saved_ground/saved_ground_cubit.dart';
import 'package:turfpro/user_booking/presentation/widgets/location_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../common/constants/colors.dart';
import '../../../constants/text_theme.dart';
import '../../../constants/widgets/app_sizedBox.dart';
import '../../../constants/widgets/app_text.dart';

class SavedGroundsScreen extends StatefulWidget {
  const SavedGroundsScreen({super.key});

  @override
  State<SavedGroundsScreen> createState() => _SavedGroundsScreenState();
}

class _SavedGroundsScreenState extends State<SavedGroundsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: BlocBuilder<SavedGroundCubit, SavedGroundState>(
          builder: (context, savedState) {
            return BlocBuilder<LocationListCubit, LocationListState>(
              builder: (context, locationState) {
                List<LocationModel> savedLocations = [];

                if (locationState is LocationListLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.success),
                  );
                }

                if (locationState is LocationListLoaded) {
                  savedLocations = locationState.locations
                      .where((loc) => savedState.favoriteIds.contains(loc.id))
                      .toList();
                }

                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _buildHeader()),
                    if (savedLocations.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _buildEmptyState(context),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: LocationCard(
                                location: savedLocations[index],
                              ),
                            ),
                            childCount: savedLocations.length,
                          ),
                        ),
                      ),
                    const SliverToBoxAdapter(child: AppSizedBox(height: 24)),
                  ],
                );
              },
            );
          },
        ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedFavourite,
            size: 64,
            color: AppColors.borderLight,
          ),
          AppSizedBox(height: 16),
          AppText(
            text: "No Saved Locations Yet",
            textStyle: AppTextTheme.black18,
          ),
          AppSizedBox(height: 8),
          AppText(
            text: "Tap the heart icon on any location to save it here.",
            textStyle: AppTextTheme.black14,
            align: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 24,
        left: 20,
        right: 20,
        bottom: 24,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0B8457), Color(0xFF065B3C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppText(
            text: "Saved Locations",
            size: 22,
            weight: FontWeight.w700,
            color: AppColors.white,
          ),
          const SizedBox(height: 4),
          AppText(
            text: "Your favorite venues ready for the next match.",
            size: 13,
            color: AppColors.white.withValues(alpha: 0.7),
          ),
        ],
      ),
    );
  }

}
