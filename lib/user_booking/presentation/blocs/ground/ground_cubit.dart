import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/repositories/ground_repository.dart';
import '../../../data/models/ground_model.dart';
import '../../../data/services/analytics_service.dart';
import 'ground_state.dart';

class GroundCubit extends Cubit<GroundState> {
  final GroundRepository repository;
  final AnalyticsService analytics;

  GroundCubit(this.repository, this.analytics) : super(GroundInitial());

  Future<void> getGrounds({String? city, double? userLat, double? userLng}) async {
    emit(GroundLoading());

    try {
      var grounds = await repository.fetchGrounds();
      
      // Filter by city if selected
      if (city != null && city != "Select Location" && city != "Fetching...") {
        final cityName = city.split(',').first.trim().toLowerCase();
        grounds = grounds.where((g) => g.city.toLowerCase().contains(cityName)).toList();
      }

      // Initial filter: Near Me (sort by distance)
      if (userLat != null && userLng != null) {
        grounds.sort((a, b) {
          final distA = _calculateDistance(userLat, userLng, a.latitude, a.longitude);
          final distB = _calculateDistance(userLat, userLng, b.latitude, b.longitude);
          return distA.compareTo(distB);
        });
      }

      // Log success event (optional: could also log result count)
      analytics.logGroundView(groundId: 'all', groundName: 'Fetch List');

      emit(GroundLoaded(grounds, grounds, activeFilter: GroundFilter.nearMe));
    } catch (e) {
      emit(GroundError(e.toString()));
    }
  }

  /// CHANGE FILTER
  void changeFilter(GroundFilter filter, {double? userLat, double? userLng}) {
    final currentState = state;
    if (currentState is GroundLoaded) {
      List<GroundModel> filteredList = List.from(currentState.allGrounds);

      switch (filter) {
        case GroundFilter.nearMe:
          if (userLat != null && userLng != null) {
            filteredList.sort((a, b) {
              final distA = _calculateDistance(userLat, userLng, a.latitude, a.longitude);
              final distB = _calculateDistance(userLat, userLng, b.latitude, b.longitude);
              return distA.compareTo(distB);
            });
          }
          break;
        case GroundFilter.topRated:
          filteredList.sort((a, b) => b.rating.compareTo(a.rating));
          break;
        case GroundFilter.openNow:
          filteredList = filteredList.where((ground) => _isOpen(ground.openingTime, ground.closingTime)).toList();
          break;
      }

      emit(GroundLoaded(filteredList, currentState.allGrounds, activeFilter: filter));
    }
  }

  /// FILTER GROUNDS BY NAME OR CITY (SEARCH)
  void searchGrounds(String query) {
    final currentState = state;
    if (currentState is GroundLoaded) {
      if (query.isEmpty) {
        emit(GroundLoaded(currentState.allGrounds, currentState.allGrounds, activeFilter: currentState.activeFilter));
        return;
      }

      final filteredList = currentState.allGrounds.where((ground) {
        final name = ground.name.toLowerCase();
        final address = ground.address.toLowerCase();
        final searchLower = query.toLowerCase();

        return name.contains(searchLower) || address.contains(searchLower);
      }).toList();

      emit(GroundLoaded(filteredList, currentState.allGrounds, activeFilter: currentState.activeFilter));
    }
  }

  /// Haversine Formula for distance calculation
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295;
    var a = 0.5 - cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) *
            (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  /// Open Now logic
  bool _isOpen(String openingTime, String closingTime) {
    final now = DateTime.now();
    final currentTime = now.hour * 100 + now.minute;

    try {
      final openParts = openingTime.split(':');
      final closeParts = closingTime.split(':');

      final openTime = int.parse(openParts[0]) * 100 + int.parse(openParts[1]);
      final closeTime = int.parse(closeParts[0]) * 100 + int.parse(closeParts[1]);

      if (closeTime > openTime) {
        return currentTime >= openTime && currentTime < closeTime;
      } else {
        // Overnight
        return currentTime >= openTime || currentTime < closeTime;
      }
    } catch (e) {
      return false;
    }
  }
}
