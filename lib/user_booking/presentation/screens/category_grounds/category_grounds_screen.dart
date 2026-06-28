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

  List<GroundModel> _applyLocalFilters(List<GroundModel> baseGrounds, double? userLat, double? userLng) {
    List<GroundModel> filtered = List.from(baseGrounds);

    filtered = filtered.where((g) => g.pricePerHour >= _criteria.minPrice && g.pricePerHour <= _criteria.maxPrice).toList();

    if (_criteria.selectedAmenities.isNotEmpty) {
      filtered = filtered.where((g) {
        return _criteria.selectedAmenities.every((amenity) => 
          g.amenities.any((ga) => ga.toLowerCase() == amenity.toLowerCase())
        );
      }).toList();
    }

    if (_criteria.isAvailableNow) {
      filtered = filtered.where((g) => _isAvailableNow(g.openingTime, g.closingTime)).toList();
    }

    if (_criteria.isNearMe && userLat != null && userLng != null) {
      filtered = filtered.where((g) => _calculateDistance(userLat, userLng, g.latitude, g.longitude) <= 10.0).toList();
    }

    if (_criteria.isTopRated) {
      filtered = filtered.where((g) => g.rating >= 4.0).toList();
    }

    switch (_criteria.sortBy) {
      case SortBy.priceLowToHigh:
        filtered.sort((a, b) => a.pricePerHour.compareTo(b.pricePerHour));
        break;
      case SortBy.priceHighToLow:
        filtered.sort((a, b) => b.pricePerHour.compareTo(a.pricePerHour));
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
          icon: Icon(Icons.arrow_back_ios_new, size: 20, color: theme.colorScheme.onSurface),
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
            final city = locationState.city?.split(',').first.trim().toLowerCase();
            
            final baseCategoryGrounds = state.allGrounds.where((g) {
              final matchesCategory = g.categories.any((c) {
                final catLower = c.toLowerCase();
                final searchLower = category.toLowerCase();
                return catLower == searchLower || 
                       catLower.contains(searchLower) || 
                       searchLower.contains(catLower);
              });
              final matchesCity = city == null || 
                                  g.city.toLowerCase().contains(city) || 
                                  city.contains(g.city.toLowerCase());
              
              return matchesCategory && matchesCity;
            }).toList();

            final filteredGrounds = _applyLocalFilters(
              baseCategoryGrounds,
              locationState.latitude,
              locationState.longitude,
            );

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
                      text: hasFilters ? "No grounds match your filters" : "No $category grounds found in this city",
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
