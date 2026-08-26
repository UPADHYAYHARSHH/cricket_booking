import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:turfpro/user_booking/constants/widgets/app_text.dart';
import 'package:turfpro/user_booking/constants/widgets/app_sizedBox.dart';
import 'package:turfpro/user_booking/presentation/blocs/ground/ground_cubit.dart';
import 'package:turfpro/user_booking/presentation/blocs/ground/ground_state.dart';
import 'package:turfpro/user_booking/presentation/blocs/location/location_cubit.dart';
import 'package:turfpro/user_booking/presentation/widgets/venue_card.dart';
import 'package:turfpro/user_booking/data/models/venue_model.dart';
import 'package:turfpro/user_booking/presentation/screens/ground_list/widgets/ground_skeleton.dart';

import 'dart:math';
import 'package:turfpro/common/constants/colors.dart';
import 'package:turfpro/user_booking/domain/models/filter_criteria.dart';
import 'package:turfpro/user_booking/presentation/screens/ground_list/widgets/filter_bottom_sheet.dart';
import 'package:turfpro/user_booking/data/models/ground_model.dart';

class CategoryGroundsScreen extends StatefulWidget {
  const CategoryGroundsScreen({super.key});

  @override
  State<CategoryGroundsScreen> createState() => _CategoryGroundsScreenState();
}

class _CategoryGroundsScreenState extends State<CategoryGroundsScreen> {
  FilterCriteria _criteria = FilterCriteria();
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _isInitialized = true;
      // Ensure grounds are loaded
      final state = context.read<GroundCubit>().state;
      if (state is! GroundLoaded) {
        final locationState = context.read<LocationCubit>().state;
        context.read<GroundCubit>().getGrounds(
          city: locationState.city,
          userLat: locationState.hasGpsLocation ? locationState.latitude : null,
          userLng: locationState.hasGpsLocation ? locationState.longitude : null,
        );
      }
    }
  }

  List<String> _getSuggestedAmenities(String category) {
    switch (category.toLowerCase()) {
      case 'cricket':
        return ['Turf Wicket', 'Matting', 'Bowling Machine', 'Floodlights', 'Pavilion'];
      case 'football':
        return ['Turf', '5v5', '7v7', '11v11', 'Floodlights'];
      case 'badminton':
      case 'pickleball':
        return ['Wooden Court', 'Synthetic Court', 'Indoor', 'AC'];
      default:
        return ['Floodlights', 'Washroom', 'Parking', 'Drinking Water'];
    }
  }

  void _showFilterSheet(BuildContext context, String category) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FilterBottomSheet(
        initialCriteria: _criteria,
        suggestedAmenities: _getSuggestedAmenities(category),
        onApply: (newCriteria) {
          setState(() {
            _criteria = newCriteria;
          });
        },
      ),
    );
  }

  bool _isAvailableNow(String openingTimeStr, String closingTimeStr) {
    try {
      final now = DateTime.now();
      final currentTimeMinutes = now.hour * 60 + now.minute;
      
      final openParts = openingTimeStr.split(':');
      final openMinutes = int.parse(openParts[0]) * 60 + int.parse(openParts[1]);
      
      final closeParts = closingTimeStr.split(':');
      final closeMinutes = int.parse(closeParts[0]) * 60 + int.parse(closeParts[1]);
      
      if (openMinutes <= closeMinutes) {
        return currentTimeMinutes >= openMinutes && currentTimeMinutes <= closeMinutes;
      } else {
        return currentTimeMinutes >= openMinutes || currentTimeMinutes <= closeMinutes;
      }
    } catch (e) {
      return false; 
    }
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295;
    var a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  List<VenueModel> _applyLocalFilters(List<VenueModel> baseVenues, double? userLat, double? userLng) {
    List<VenueModel> filtered = List.from(baseVenues);

    filtered = filtered.where((v) { final p = v.pitches.first; return p.pricePerHour >= _criteria.minPrice && p.pricePerHour <= _criteria.maxPrice; }).toList();

    if (_criteria.selectedAmenities.isNotEmpty) {
      filtered = filtered.where((v) {
        return _criteria.selectedAmenities.every((amenity) => 
          v.pitches.first.amenities.any((pa) => pa.toLowerCase() == amenity.toLowerCase())
        );
      }).toList();
    }

    if (_criteria.isAvailableNow) {
      filtered = filtered.where((v) => _isAvailableNow(v.pitches.first.openingTime, v.pitches.first.closingTime)).toList();
    }

    if (_criteria.isNearMe && userLat != null && userLng != null) {
      filtered = filtered.where((v) => _calculateDistance(userLat, userLng, v.latitude, v.longitude) <= 10.0).toList();
    }

    if (_criteria.isTopRated) {
      filtered = filtered.where((v) => v.rating >= 4.0).toList();
    }

    switch (_criteria.sortBy) {
      case SortBy.priceLowToHigh:
        filtered.sort((a, b) => a.pitches.first.pricePerHour.compareTo(b.pitches.first.pricePerHour));
        break;
      case SortBy.priceHighToLow:
        filtered.sort((a, b) => b.pitches.first.pricePerHour.compareTo(a.pitches.first.pricePerHour));
        break;
      case SortBy.none:
      default:
        filtered.sort((a, b) {
          int ratingComparison = b.rating.compareTo(a.rating);
          if (ratingComparison != 0) return ratingComparison;
          if (userLat != null && userLng != null) {
            return _calculateDistance(userLat, userLng, a.latitude, a.longitude)
                .compareTo(_calculateDistance(userLat, userLng, b.latitude, b.longitude));
          }
          return 0;
        });
        break;
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final String category = ModalRoute.of(context)!.settings.arguments as String;
    final theme = Theme.of(context);
    final hasFilters = !_criteria.isDefault;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: HugeIcon(icon: HugeIcons.strokeRoundedArrowLeft01, size: 20, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: AppText(
          text: category,
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          GestureDetector(
            onTap: () => _showFilterSheet(context, category),
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryDarkGreen,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const HugeIcon(
                      icon: HugeIcons.strokeRoundedFilterHorizontal,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  if (hasFilters)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
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
            final locationState = context.read<LocationCubit>().state;
            
            // Find locationIds that have grounds matching the category
            final matchingLocationIds = state.allGrounds.where((g) {
              return g.categories.any((c) {
                final catLower = c.replaceAll('_', ' ').toLowerCase();
                final searchLower = category.toLowerCase();
                return catLower == searchLower || 
                       catLower.contains(searchLower) || 
                       searchLower.contains(catLower);
              });
            }).map((g) => g.locationId).toSet();

            // Group ALL grounds belonging to those matching locations
            final Map<String, List<GroundModel>> grouped = {};
            for (final ground in state.allGrounds) {
              if (matchingLocationIds.contains(ground.locationId)) {
                grouped.putIfAbsent(ground.locationId, () => []).add(ground);
              }
            }
            
            final baseCategoryVenues = grouped.entries
                .map((e) => VenueModel.fromGrounds(e.key, e.value))
                .toList();

            final filteredVenues = _applyLocalFilters(
              baseCategoryVenues,
              locationState.latitude,
              locationState.longitude,
            );

            if (filteredVenues.isEmpty) {
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
                      text: hasFilters ? "No grounds match your filters" : "No $category grounds found",
                      textStyle: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                    ),
                    if (hasFilters) ...[
                      const AppSizedBox(height: 12),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _criteria = FilterCriteria();
                          });
                        },
                        child: const AppText(
                          text: "Clear Filters",
                          textStyle: TextStyle(color: AppColors.primaryDarkGreen, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                await context.read<GroundCubit>().getGrounds(
                  city: locationState.city,
                  userLat: locationState.latitude,
                  userLng: locationState.longitude,
                );
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredVenues.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: VenueCard(
                      venue: filteredVenues[index], 
                      showAmenities: true, 
                      isGrid: false,
                      preferredSport: category,
                    ),
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
