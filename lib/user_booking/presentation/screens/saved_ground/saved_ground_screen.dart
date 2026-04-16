import 'package:bloc_structure/user_booking/data/models/ground_model.dart';
import 'package:bloc_structure/user_booking/presentation/blocs/ground/ground_cubit.dart';
import 'package:bloc_structure/user_booking/presentation/blocs/ground/ground_state.dart';
import 'package:bloc_structure/user_booking/presentation/blocs/saved_ground/saved_ground_cubit.dart';
import 'package:bloc_structure/user_booking/presentation/widgets/ground_card.dart';
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
      body: SafeArea(
        child: BlocBuilder<SavedGroundCubit, SavedGroundState>(
          builder: (context, savedState) {
            return BlocBuilder<GroundCubit, GroundState>(
              builder: (context, groundState) {
                List<GroundModel> savedGrounds = [];

                if (groundState is GroundLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.success),
                  );
                }

                if (groundState is GroundLoaded) {
                  savedGrounds = groundState.allGrounds
                      .where((g) => savedState.favoriteIds.contains(g.id))
                      .toList();
                }

                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _buildHeader()),
                    if (savedGrounds.isEmpty)
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
                              child: GroundCard(
                                ground: savedGrounds[index],
                              ),
                            ),
                            childCount: savedGrounds.length,
                          ),
                        ),
                      ),
                    SliverToBoxAdapter(child: _buildExploreMore(context)),
                    const SliverToBoxAdapter(child: AppSizedBox(height: 24)),
                  ],
                );
              },
            );
          },
        ),
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
            text: "No Saved Grounds Yet",
            textStyle: AppTextTheme.black18,
          ),
          AppSizedBox(height: 8),
          AppText(
            text: "Tap the heart icon on any ground to save it here.",
            textStyle: AppTextTheme.black14,
            align: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            text: "Saved Grounds",
            textStyle: AppTextTheme.black18.copyWith(
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const AppSizedBox(height: 4),
          AppText(
            text: "Your favorite arenas ready for the next match.",
            textStyle: AppTextTheme.black14.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExploreMore(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
          )
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              shape: BoxShape.circle,
            ),
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedDiscoverCircle,
              size: 28,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const AppSizedBox(height: 10),
          const AppText(
            text: "Explore More",
            textStyle: AppTextTheme.black16,
          ),
          const AppSizedBox(height: 4),
          const AppText(
            text:
                "Discover new arenas in your area and\nexpand your favorites.",
            align: TextAlign.center,
            textStyle: AppTextTheme.black12,
          ),
          const AppSizedBox(height: 16),
          OutlinedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content:
                        Text("Search for new grounds in the Discover tab!")),
              );
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(
                  color: AppColors.primaryDarkGreen, width: 1.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
            ),
            child: const AppText(
              text: "Find Grounds",
              textStyle: TextStyle(
                color: AppColors.primaryDarkGreen,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
