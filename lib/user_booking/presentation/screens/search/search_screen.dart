import 'package:turfpro/user_booking/constants/widgets/app_sizedBox.dart';
import 'package:turfpro/user_booking/presentation/blocs/ground/ground_cubit.dart';
import 'package:turfpro/user_booking/presentation/blocs/ground/ground_state.dart';
import 'package:turfpro/user_booking/presentation/blocs/location/location_cubit.dart';
import 'package:turfpro/user_booking/presentation/widgets/ground_card.dart';
import 'package:turfpro/user_booking/presentation/widgets/venue_card.dart';
import 'package:turfpro/user_booking/presentation/screens/ground_list/widgets/ground_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:turfpro/common/constants/colors.dart';
import 'package:turfpro/common/widgets/discover_app_bar.dart';
import '../../../constants/widgets/app_text.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    final groundCubit = context.read<GroundCubit>();
    if (groundCubit.state is GroundInitial) {
      final loc = context.read<LocationCubit>().state;
      groundCubit.getGrounds(
        city: loc.city,
        userLat: loc.hasGpsLocation ? loc.latitude : null,
        userLng: loc.hasGpsLocation ? loc.longitude : null,
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: const DiscoverAppBarBackground(),
        leading: IconButton(
          icon: const HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            size: 20,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: SizedBox(
            height: 40,
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              autofocus: true,
              onChanged: (value) {
                setState(() {});
              },
              style: const TextStyle(
                color: AppColors.textPrimaryLight,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: "Search turfs...",
                hintStyle: TextStyle(
                  color: AppColors.textSecondaryLight.withValues(alpha: 0.8),
                  fontSize: 14,
                ),
                prefixIcon: const Padding(
                  padding: EdgeInsets.all(10),
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedSearch01,
                    size: 18,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 38,
                ),
                isDense: true,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: _buildGroundSearch(context),
    );
  }

  Widget _buildGroundSearch(BuildContext context) {
    return BlocBuilder<GroundCubit, GroundState>(
      builder: (context, state) {
        if (state is GroundLoading || state is GroundInitial) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 5,
            itemBuilder: (context, index) => const GroundSkeleton(),
          );
        }

        if (state is GroundLoaded) {
          final query = _searchController.text.trim().toLowerCase();
          
          if (query.isEmpty) {
            return _buildEmptyState(context, "Search for your favorite turfs");
          }

          final filteredVenues = state.allVenues.where((venue) {
            final name = venue.name.toLowerCase();
            final address = venue.address.toLowerCase();
            // Since VenueModel doesn't directly expose locationName, we check the first ground's locationName if available
            final locationName = venue.pitches.isNotEmpty 
                ? venue.pitches.first.locationName.toLowerCase() 
                : '';

            return name.contains(query) || 
                   address.contains(query) || 
                   locationName.contains(query);
          }).toList();

          if (filteredVenues.isEmpty) {
            return _buildNoResultsState(context, "No venues found");
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredVenues.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: VenueCard(venue: filteredVenues[index]),
              );
            },
          );
        }

        if (state is GroundError) {
          return Center(child: AppText(text: state.message));
        }

        return const SizedBox();
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedSearch01,
            size: 64,
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
          ),
          const AppSizedBox(height: 16),
          AppText(
            text: message,
            textStyle: TextStyle(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedSearch01,
            size: 64,
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
          ),
          const AppSizedBox(height: 16),
          AppText(text: message),
        ],
      ),
    );
  }
}
