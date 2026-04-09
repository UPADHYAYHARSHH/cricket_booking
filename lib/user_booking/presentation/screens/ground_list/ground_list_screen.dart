import 'package:bloc_structure/common/constants/colors.dart';
import 'package:bloc_structure/user_booking/constants/widgets/app_sizedBox.dart';
import 'package:bloc_structure/user_booking/presentation/screens/ground_list/widgets/city_search_bottomsheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../constants/widgets/app_text.dart';

import '../../blocs/location/location_cubit.dart';
import '../../blocs/ground/ground_cubit.dart';
import '../../blocs/ground/ground_state.dart';
import 'package:bloc_structure/user_booking/presentation/widgets/ground_card.dart';
import 'widgets/ground_skeleton.dart';
import '../../blocs/notification/notification_cubit.dart';
import 'package:bloc_structure/user_booking/constants/route_constants.dart';
import 'package:bloc_structure/user_booking/domain/models/filter_criteria.dart';
import 'widgets/filter_bottom_sheet.dart';

class GroundListScreen extends StatefulWidget {
  const GroundListScreen({super.key});

  @override
  State<GroundListScreen> createState() => _GroundListScreenState();
}

class _GroundListScreenState extends State<GroundListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locationCubit = context.read<LocationCubit>();

    // Trigger initial load if not already loaded (since it's a shared singleton now)
    final groundCubit = context.read<GroundCubit>();
    if (groundCubit.state is GroundInitial) {
      groundCubit.getGrounds(
        city: locationCubit.state.city,
        userLat: locationCubit.state.latitude,
        userLng: locationCubit.state.longitude,
      );
    }

    return BlocListener<LocationCubit, LocationState>(
      listener: (context, state) {
        if (state.city != null && !state.isLoading) {
          context.read<GroundCubit>().getGrounds(
                city: state.city,
                userLat: state.latitude,
                userLng: state.longitude,
              );
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,

        /// APP BAR
        appBar: AppBar(
          backgroundColor: Theme.of(context).cardColor,
          elevation: 0,
          title: BlocBuilder<LocationCubit, LocationState>(
            builder: (context, state) {
              final city = state.city ?? "Fetching...";

              return GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Theme.of(context).cardColor,
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (_) => const CitySearchBottomSheet(),
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const HugeIcon(
                      icon: HugeIcons.strokeRoundedLocation01,
                      color: AppColors.primaryDarkGreen,
                      size: 18,
                    ),
                    const AppSizedBox(width: 4),
                    Flexible(
                      child: AppText(
                        text: city,
                        textStyle: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const AppSizedBox(width: 4),
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedArrowDown01,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.5),
                      size: 20,
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            BlocBuilder<NotificationCubit, NotificationState>(
              builder: (context, state) {
                final bool hasUnread = state.unreadCount > 0;
                
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: GestureDetector(
                    onTap: () => Navigator.pushNamed(context, AppRoutes.notification),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedNotification01,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        if (hasUnread)
                          Positioned(
                            right: 0,
                            top: 15,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 1.5),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            )
          ],
        ),

        /// BODY
        body: Column(
          children: [
            /// 🔍 SEARCH & FILTER
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.search);
                      },
                      child: Hero(
                        tag: 'search_bar',
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            children: [
                              HugeIcon(
                                icon: HugeIcons.strokeRoundedSearch01,
                                size: 18,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.4),
                              ),
                              const AppSizedBox(width: 10),
                              AppText(
                                text: "Search nearby grounds...",
                                textStyle: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.4),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                   const AppSizedBox(width: 12),
                   BlocBuilder<GroundCubit, GroundState>(
                    builder: (context, state) {
                      final bool hasFilters = state is GroundLoaded && !state.criteria.isDefault;
                      
                      return GestureDetector(
                        onTap: () {
                          if (state is GroundLoaded) {
                            _showFilterSheet(context, state);
                          }
                        },
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primaryDarkGreen,
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryDarkGreen.withOpacity(0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const HugeIcon(
                                icon: HugeIcons.strokeRoundedFilterHorizontal,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            if (hasFilters)
                              Positioned(
                                top: -2,
                                right: -2,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),



            const AppSizedBox(height: 10),

            /// 📋 LIST (DYNAMIC)
            Expanded(
              child: BlocBuilder<GroundCubit, GroundState>(
                builder: (context, state) {
                  /// 🔄 Loading
                  if (state is GroundLoading) {
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: 5,
                      itemBuilder: (context, index) => const GroundSkeleton(),
                    );
                  }

                  /// ✅ Data Loaded
                  if (state is GroundLoaded) {
                    if (state.grounds.isEmpty) {
                      return const Center(
                        child: AppText(text: "No grounds found"),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        final locationState =
                            context.read<LocationCubit>().state;
                        await context.read<GroundCubit>().getGrounds(
                              city: locationState.city,
                              userLat: locationState.latitude,
                              userLng: locationState.longitude,
                            );
                      },
                      color: AppColors.primaryDarkGreen,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: state.grounds.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: GroundCard(
                              ground: state.grounds[index],
                            ),
                          );
                        },
                      ),
                    );
                  }

                  /// ❌ Error
                  if (state is GroundError) {
                    return Center(
                      child: AppText(text: state.message),
                    );
                  }

                  return const SizedBox();
                },
              ),
            )
          ],
        ),
      ),
    );
  }


  void _showFilterSheet(BuildContext context, GroundLoaded state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FilterBottomSheet(
        initialCriteria: state.criteria,
        onApply: (criteria) {
          final locationState = context.read<LocationCubit>().state;
          context.read<GroundCubit>().applyFilters(
                criteria,
                userLat: locationState.latitude,
                userLng: locationState.longitude,
              );
        },
      ),
    );
  }
}
