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

      // Filter by city if selected
      if (city != null && city != "Select Location" && city != "Fetching...") {
        final cityName = city.split(',').first.trim().toLowerCase();
        grounds = grounds
            .where((g) => g.city.toLowerCase().contains(cityName))
            .toList();
      }

      final criteria = FilterCriteria();

      // Initial sort: Near Me
      if (userLat != null && userLng != null) {
        grounds.sort((a, b) {
          final distA =
              _calculateDistance(userLat, userLng, a.latitude, a.longitude);
          final distB =
              _calculateDistance(userLat, userLng, b.latitude, b.longitude);
          return distA.compareTo(distB);
        });
      }

      analytics.logGroundView(groundId: 'all', groundName: 'Fetch List');

      emit(GroundLoaded(grounds, grounds, criteria: criteria));
    } catch (e) {
      emit(GroundError(e.toString()));
    }
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

      // 3. Sort
      switch (criteria.sortBy) {
        case SortBy.nearMe:
          if (userLat != null && userLng != null) {
            filteredList.sort((a, b) {
              final distA =
                  _calculateDistance(userLat, userLng, a.latitude, a.longitude);
              final distB =
                  _calculateDistance(userLat, userLng, b.latitude, b.longitude);
              return distA.compareTo(distB);
            });
          }
          break;
        case SortBy.topRated:
          filteredList.sort((a, b) => b.rating.compareTo(a.rating));
          break;
        case SortBy.priceLowToHigh:
          filteredList.sort((a, b) => a.pricePerHour.compareTo(b.pricePerHour));
          break;
        case SortBy.priceHighToLow:
          filteredList.sort((a, b) => b.pricePerHour.compareTo(a.pricePerHour));
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
}
