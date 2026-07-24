import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/repositories/ground_repository.dart';
import '../../../data/models/ground_model.dart';
import '../../../data/services/analytics_service.dart';
import 'package:turfpro/user_booking/domain/models/filter_criteria.dart';
import 'ground_state.dart';

class GroundCubit extends Cubit<GroundState> {
  final GroundRepository repository;
  final AnalyticsService analytics;

  GroundCubit(this.repository, this.analytics) : super(GroundInitial());

  Future<void> getGrounds(
      {String? city, double? userLat, double? userLng}) async {
    emit(GroundLoading());

    try {
      var grounds = await repository.fetchGrounds();
      print("🚀 GroundCubit: Fetched ${grounds.length} grounds from DB.");

      // Filter by city if selected
      if (city != null && city != "Select Location" && city != "Fetching...") {
        final cityName = city.split(',').first.trim().toLowerCase();
        print("🌍 GroundCubit: Filtering by city -> '$cityName'");
        grounds = grounds
            .where((g) => g.city.toLowerCase().contains(cityName) || cityName.contains(g.city.toLowerCase()))
            .toList();
      }
      
      print("✅ GroundCubit: Total grounds after city filter: ${grounds.length}");

      // Number multiple same-sport grounds at the same location
      grounds = _applyGroundNumbering(grounds);

      final criteria = FilterCriteria();

      // Initial sort: Rating (Descending), fallback to Near Me
      grounds.sort((a, b) {
        int ratingComparison = b.rating.compareTo(a.rating);
        if (ratingComparison != 0) {
          return ratingComparison;
        }
        if (userLat != null && userLng != null) {
          final distA = _calculateDistance(userLat, userLng, a.latitude, a.longitude);
          final distB = _calculateDistance(userLat, userLng, b.latitude, b.longitude);
          return distA.compareTo(distB);
        }
        return 0;
      });

      analytics.logGroundView(groundId: 'all', groundName: 'Fetch List');

      emit(GroundLoaded(grounds, grounds, criteria: criteria));
    } catch (e) {
      emit(GroundError(e.toString()));
    }
  }

  /// Numbers multiple grounds of the same sport at the same location.
  /// E.g., "Cricket" becomes "Cricket 1", "Cricket 2" when there are 2+ cricket grounds.
  List<GroundModel> _applyGroundNumbering(List<GroundModel> grounds) {
    // Group by locationId + category
    final groups = <String, List<GroundModel>>{};
    for (final ground in grounds) {
      if (ground.categories.isEmpty) continue;
      for (final category in ground.categories) {
        final key = '${ground.locationId}_${category.toLowerCase()}';
        groups.putIfAbsent(key, () => []).add(ground);
      }
    }

    // Build a map from groundId to its numbered name
    final numberedNames = <String, String>{};
    for (final entry in groups.entries) {
      if (entry.value.length <= 1) continue;
      final category = entry.key.split('_').last;
      for (var i = 0; i < entry.value.length; i++) {
        final ground = entry.value[i];
        final number = i + 1;
        numberedNames[ground.id] = '${_capitalize(category)} $number';
      }
    }

    // Create new GroundModel instances with displayName set
    return grounds.map((g) {
      final displayName = numberedNames[g.id];
      if (displayName != null) {
        return GroundModel(
          id: g.id,
          name: g.name,
          displayName: displayName,
          address: g.address,
          latitude: g.latitude,
          longitude: g.longitude,
          pricePerHour: g.pricePerHour,
          weekendPrice: g.weekendPrice,
          imageUrl: g.imageUrl,
          rating: g.rating,
          openingTime: g.openingTime,
          closingTime: g.closingTime,
          city: g.city,
          totalReviews: g.totalReviews,
          description: g.description,
          locationDescription: g.locationDescription,
          amenities: g.amenities,
          images: g.images,
          categories: g.categories,
          ownerId: g.ownerId,
          locationId: g.locationId,
          isAvailable: g.isAvailable,
        );
      }
      return g;
    }).toList();
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return '${s[0].toUpperCase()}${s.substring(1)}';
  }

  /// APPLY FILTERS
  void applyFilters(FilterCriteria criteria,
      {double? userLat, double? userLng}) {
    final currentState = state;
    if (currentState is GroundLoaded) {
      List<GroundModel> filteredList = List.from(currentState.allGrounds);

      // 1. Filter by Price
      filteredList = filteredList
          .where((g) =>
              g.pricePerHour >= criteria.minPrice &&
              g.pricePerHour <= criteria.maxPrice)
          .toList();

      // 2. Filter by Amenities
      if (criteria.selectedAmenities.isNotEmpty) {
        filteredList = filteredList.where((g) {
          return criteria.selectedAmenities.every((amenity) => g.amenities
              .any((ga) => ga.toLowerCase() == amenity.toLowerCase()));
        }).toList();
      }

      // 3. Filter by Available Now
      if (criteria.isAvailableNow) {
        filteredList = filteredList
            .where((g) => _isAvailableNow(g.openingTime, g.closingTime))
            .toList();
      }

      // 4. Filter by Near Me (radius < 10km)
      if (criteria.isNearMe && userLat != null && userLng != null) {
        filteredList = filteredList.where((g) {
          final distance =
              _calculateDistance(userLat, userLng, g.latitude, g.longitude);
          return distance <= 10.0; // 10km radius
        }).toList();
      }

      // 5. Filter by Top Rated (rating >= 4.0)
      if (criteria.isTopRated) {
        filteredList = filteredList.where((g) => g.rating >= 4.0).toList();
      }

      // 6. Filter by Sport Category
      if (criteria.sportId != null && criteria.sportId != 'all') {
        filteredList = filteredList.where((g) {
          return g.categories.any((c) =>
              c.toLowerCase() == criteria.sportId!.toLowerCase());
        }).toList();
      }

      // 7. Sort
      switch (criteria.sortBy) {
        case SortBy.priceLowToHigh:
          filteredList.sort((a, b) => a.pricePerHour.compareTo(b.pricePerHour));
          break;
        case SortBy.priceHighToLow:
          filteredList.sort((a, b) => b.pricePerHour.compareTo(a.pricePerHour));
          break;
        case SortBy.none:
        default:
          // Maintain rating sort if no other sort is selected
          filteredList.sort((a, b) {
            int ratingComparison = b.rating.compareTo(a.rating);
            if (ratingComparison != 0) {
              return ratingComparison;
            }
            if (userLat != null && userLng != null) {
              final distA = _calculateDistance(userLat, userLng, a.latitude, a.longitude);
              final distB = _calculateDistance(userLat, userLng, b.latitude, b.longitude);
              return distA.compareTo(distB);
            }
            return 0;
          });
          break;
      }

      emit(GroundLoaded(filteredList, currentState.allGrounds,
          criteria: criteria));
    }
  }

  /// FILTER GROUNDS BY NAME OR CITY (SEARCH)
  void searchGrounds(String query) {
    final currentState = state;
    if (currentState is GroundLoaded) {
      if (query.isEmpty) {
        emit(GroundLoaded(currentState.allGrounds, currentState.allGrounds,
            criteria: currentState.criteria));
        return;
      }

      final filteredList = currentState.allGrounds.where((ground) {
        final name = ground.name.toLowerCase();
        final address = ground.address.toLowerCase();
        final searchLower = query.toLowerCase();

        return name.contains(searchLower) || address.contains(searchLower);
      }).toList();

      emit(GroundLoaded(filteredList, currentState.allGrounds,
          criteria: currentState.criteria));
    }
  }

  /// Haversine Formula for distance calculation
  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295;
    var a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  bool _isAvailableNow(String openingTimeStr, String closingTimeStr) {
    try {
      final now = DateTime.now();
      final currentTimeMinutes = now.hour * 60 + now.minute;
      
      final openParts = openingTimeStr.split(':');
      final openMinutes = int.parse(openParts[0]) * 60 + int.parse(openParts[1]);
      
      final closeParts = closingTimeStr.split(':');
      final closeMinutes = int.parse(closeParts[0]) * 60 + int.parse(closeParts[1]);
      
      // Handle overnight grounds (e.g., open 18:00, close 02:00)
      if (openMinutes <= closeMinutes) {
        return currentTimeMinutes >= openMinutes && currentTimeMinutes <= closeMinutes;
      } else {
        // Overnight
        return currentTimeMinutes >= openMinutes || currentTimeMinutes <= closeMinutes;
      }
    } catch (e) {
      // If parsing fails or times are missing/invalid, default to false
      return false; 
    }
  }
}
