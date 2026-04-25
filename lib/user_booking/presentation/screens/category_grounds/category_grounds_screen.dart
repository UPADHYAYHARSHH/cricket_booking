import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:turfpro/user_booking/constants/widgets/app_text.dart';
import 'package:turfpro/user_booking/constants/widgets/app_sizedBox.dart';
import 'package:turfpro/user_booking/presentation/blocs/ground/ground_cubit.dart';
import 'package:turfpro/user_booking/presentation/blocs/ground/ground_state.dart';
import 'package:turfpro/user_booking/presentation/blocs/location/location_cubit.dart';
import 'package:turfpro/user_booking/presentation/widgets/ground_card.dart';
import 'package:turfpro/user_booking/presentation/screens/ground_list/widgets/ground_skeleton.dart';

class CategoryGroundsScreen extends StatelessWidget {
  const CategoryGroundsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String category = ModalRoute.of(context)!.settings.arguments as String;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 20, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: AppText(
          text: category,
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<GroundCubit, GroundState>(
        builder: (context, state) {
          if (state is GroundLoading) {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 5,
              itemBuilder: (context, index) => const GroundSkeleton(),
            );
          }

          if (state is GroundLoaded) {
            final city = context.read<LocationCubit>().state.city?.split(',').first.trim().toLowerCase();
            
            final filteredGrounds = state.allGrounds.where((g) {
              final matchesCategory = g.categories.any((c) => c.toLowerCase() == category.toLowerCase());
              final matchesCity = city == null || g.city.toLowerCase().contains(city);
              return matchesCategory && matchesCity;
            }).toList();

            if (filteredGrounds.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedSearch01,
                      size: 64,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                    ),
                    const AppSizedBox(height: 16),
                    AppText(
                      text: "No $category grounds found in this city",
                      textStyle: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                final locationState = context.read<LocationCubit>().state;
                await context.read<GroundCubit>().getGrounds(
                  city: locationState.city,
                  userLat: locationState.latitude,
                  userLng: locationState.longitude,
                );
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredGrounds.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: GroundCard(ground: filteredGrounds[index]),
                  );
                },
              ),
            );
          }

          if (state is GroundError) {
            return Center(child: AppText(text: state.message));
          }

          return const SizedBox();
        },
      ),
    );
  }
}
