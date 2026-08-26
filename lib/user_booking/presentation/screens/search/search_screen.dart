import 'package:turfpro/user_booking/constants/widgets/app_sizedBox.dart';
import 'package:turfpro/user_booking/presentation/blocs/ground/ground_cubit.dart';
import 'package:turfpro/user_booking/presentation/blocs/ground/ground_state.dart';
import 'package:turfpro/user_booking/presentation/widgets/ground_card.dart';
import 'package:turfpro/user_booking/presentation/widgets/venue_card.dart';
import 'package:turfpro/user_booking/presentation/screens/ground_list/widgets/ground_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
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
        leading: IconButton(
          icon: HugeIcon(icon: HugeIcons.strokeRoundedArrowLeft01, size: 20, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Hero(
            tag: 'search_bar',
            child: Material(
              color: Colors.transparent,
              child: TextField(
                controller: _searchController,
                focusNode: _focusNode,
                onChanged: (value) {
                  setState(() {});
                },
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: "Search turfs...",
                  hintStyle: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.4),
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(12),
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedSearch01,
                      size: 18,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.4),
                    ),
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 40,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).scaffoldBackgroundColor,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
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
        if (state is GroundLoading) {
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
