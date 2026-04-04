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
import 'widgets/ground_card.dart';
import 'widgets/ground_skeleton.dart';

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
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      size: 20,
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedNotification01,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            )
          ],
        ),

        /// BODY
        body: Column(
          children: [
            /// 🔍 SEARCH
            Padding(
              padding: const EdgeInsets.all(16),
              child: Builder(builder: (context) {
                return TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    context.read<GroundCubit>().searchGrounds(value);
                  },
                  decoration: InputDecoration(
                    hintText: "Search nearby grounds...",
                    hintStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                    ),
                    prefixIcon: HugeIcon(
                      icon: HugeIcons.strokeRoundedSearch01,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                );
              }),
            ),

            /// 🎯 FILTERS
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: BlocBuilder<GroundCubit, GroundState>(
                builder: (context, state) {
                  final activeFilter = state is GroundLoaded
                      ? state.activeFilter
                      : GroundFilter.nearMe;
                  final locationState = context.read<LocationCubit>().state;

                  return Row(
                    children: [
                      _filterChip(
                          context,
                          "Near Me",
                          GroundFilter.nearMe,
                          activeFilter == GroundFilter.nearMe,
                          locationState),
                      const AppSizedBox(width: 10),
                      _filterChip(
                          context,
                          "Top Rated",
                          GroundFilter.topRated,
                          activeFilter == GroundFilter.topRated,
                          locationState),
                      const AppSizedBox(width: 10),
                      _filterChip(
                          context,
                          "Open Now",
                          GroundFilter.openNow,
                          activeFilter == GroundFilter.openNow,
                          locationState),
                    ],
                  );
                },
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

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: state.grounds.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: GroundCard(
                            ground: state.grounds[index],
                          ),
                        );
                      },
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

  /// 🎯 FILTER CHIP
  Widget _filterChip(BuildContext context, String text, GroundFilter filter,
      bool active, LocationState locationState) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return GestureDetector(
      onTap: () {
        context.read<GroundCubit>().changeFilter(
              filter,
              userLat: locationState.latitude,
              userLng: locationState.longitude,
            );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.primaryDarkGreen : theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active
                ? Colors.transparent
                : onSurface.withOpacity(0.1),
          ),
        ),
        child: AppText(
          text: text,
          textStyle: TextStyle(
            color: active ? Colors.white : onSurface.withOpacity(0.7),
            fontWeight: active ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
