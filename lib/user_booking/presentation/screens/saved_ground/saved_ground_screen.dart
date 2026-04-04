import 'dart:math';
import '../../../../common/constants/colors.dart';
import '../../../../user_booking/constants/route_constants.dart';
import '../../../../user_booking/data/models/ground_model.dart';
import '../../../../user_booking/presentation/blocs/ground/ground_cubit.dart';
import '../../../../user_booking/presentation/blocs/ground/ground_state.dart';
import '../../../../user_booking/presentation/blocs/saved_ground/saved_ground_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../user_booking/presentation/blocs/location/location_cubit.dart';
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
                            (context, index) => _GroundCard(
                              ground: savedGrounds[index],
                              onFavToggle: () {
                                final user = Supabase.instance.client.auth.currentUser;
                                if (user != null) {
                                  context.read<SavedGroundCubit>().toggleFavorite(user.id, savedGrounds[index].id);
                                }
                              },
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
            text: "Discover new arenas in your area and\nexpand your favorites.",
            align: TextAlign.center,
            textStyle: AppTextTheme.black12,
          ),
          const AppSizedBox(height: 16),
          OutlinedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text("Search for new grounds in the Discover tab!")),
              );
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primaryDarkGreen, width: 1.5),
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

class _GroundCard extends StatelessWidget {
  final GroundModel ground;
  final VoidCallback onFavToggle;

  const _GroundCard({required this.ground, required this.onFavToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImage(context),
          _buildInfo(context),
        ],
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: Image.network(
            ground.imageUrl.isNotEmpty
                ? ground.imageUrl
                : "https://images.unsplash.com/photo-1540747913346-19e32dc3e97e",
            height: 160,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              height: 160,
              color: AppColors.bgLight,
              child: const HugeIcon(
                  icon: HugeIcons.strokeRoundedCricketBat,
                  size: 48,
                  color: AppColors.borderLight),
            ),
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.white.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const HugeIcon(
                          icon: HugeIcons.strokeRoundedLocation01,
                          size: 12,
                          color: AppColors.white),
                      const AppSizedBox(width: 4),
                      AppText(
                        text: "${distance.toStringAsFixed(1)} km",
                        textStyle: const TextStyle(
                          fontSize: 11,
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
        // Favorite button
        Positioned(
          top: 12,
          right: 12,
          child: GestureDetector(
            onTap: onFavToggle,
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
              child: const HugeIcon(
                icon: HugeIcons.strokeRoundedFavourite,
                size: 16,
                color: AppColors.error,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfo(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: AppText(
                  text: ground.name,
                  textStyle: AppTextTheme.black16,
                ),
              ),
              const AppSizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const HugeIcon(
                        icon: HugeIcons.strokeRoundedStar,
                        size: 13,
                        color: AppColors.goldenYellow),
                    const AppSizedBox(width: 3),
                    AppText(
                      text: ground.rating.toString(),
                      textStyle: AppTextTheme.black12,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const AppSizedBox(height: 6),
          Row(
            children: [
              HugeIcon(
                  icon: HugeIcons.strokeRoundedLocation01,
                  size: 13,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
              const AppSizedBox(width: 4),
              Expanded(
                child: AppText(
                  text: ground.address,
                  textStyle: AppTextTheme.black12.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ),
            ],
          ),
          const AppSizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.slotSelection,
                  arguments: ground,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDarkGreen,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const AppText(
                text: "Book Now",
                textStyle: TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),

        ],
      ),
    );
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295;
    var a = 0.5 - cos((lat2 - lat1) * p) / 2 + cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }
}
