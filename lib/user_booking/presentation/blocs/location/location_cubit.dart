import 'dart:async';
import 'package:bloc/bloc.dart';

import '../../../../utils/location_service.dart';
import '../../../data/repositories/user_repository_impl.dart';

import 'package:geocoding/geocoding.dart';

class LocationState {
  final String? city;
  final double? latitude;
  final double? longitude;
  final bool isLoading;

  LocationState({
    this.city,
    this.latitude,
    this.longitude,
    this.isLoading = false,
  });

  LocationState copyWith({
    String? city,
    double? latitude,
    double? longitude,
    bool? isLoading,
  }) {
    return LocationState(
      city: city ?? this.city,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class LocationCubit extends Cubit<LocationState> {
  final UserRepository repo;
  Timer? _locationTimer;

  LocationCubit(this.repo) : super(LocationState()) {
    _startPeriodicUpdate();
  }

  void _startPeriodicUpdate() {
    _locationTimer?.cancel();
    // Update every 5 minutes as requested
    _locationTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      print("[LOCATION_CUBIT] Periodic update triggered...");
      loadCity();
    });
  }

  @override
  Future<void> close() {
    _locationTimer?.cancel();
    return super.close();
  }

  /// MANUALLY SET CITY AND PERSIST TO DATABASE
  Future<void> setCity(String cityLabel) async {
    emit(state.copyWith(isLoading: true));

    print("[LOCATION_CUBIT] Setting city manually to: $cityLabel");
    final cityName = cityLabel.split(',').first.trim();

    try {
      print("[LOCATION_CUBIT] Geocoding cityName: $cityName");
      List<Location> locations = await locationFromAddress(cityName);
      double? lat, lng;
      if (locations.isNotEmpty) {
        lat = locations.first.latitude;
        lng = locations.first.longitude;
        print("[LOCATION_CUBIT] Successfully geocoded to Lat: $lat, Lng: $lng");
      }

      emit(state.copyWith(
        city: cityLabel,
        latitude: lat,
        longitude: lng,
        isLoading: false,
      ));

      print("[LOCATION_CUBIT] Persisting city to profile...");
      await repo.updateUserCity(cityLabel);
    } catch (e) {
      print("[LOCATION_CUBIT] ERROR in setCity: $e");
      emit(state.copyWith(city: cityLabel, isLoading: false));
    }
  }

  /// INITIALIZE CITY FROM DATABASE OR CURRENT POSITION
  Future<void> loadCity() async {
    // Only show loading if we don't have a city yet (initial load)
    if (state.city == null) {
      emit(state.copyWith(isLoading: true));
    }
    
    print("[LOCATION_CUBIT] Initializing/Refreshing City...");

    try {
      print("[LOCATION_CUBIT] Fetching precise location...");
      final userLoc = await getCurrentLocation();
      print("[LOCATION_CUBIT] Precise Location: ${userLoc.city} (${userLoc.latitude}, ${userLoc.longitude})");

      emit(state.copyWith(
        city: userLoc.city,
        latitude: userLoc.latitude,
        longitude: userLoc.longitude,
        isLoading: false,
      ));
      
      // Update database if changed significantly (optional logic, but let's persist)
      await repo.updateUserCity(userLoc.city);
    } catch (e) {
      print("[LOCATION_CUBIT] GPS Error: $e. Falling back to stored city.");
      
      final storedCity = await repo.getUserCity();
      if (storedCity != null) {
        await setCity(storedCity);
      } else {
        emit(state.copyWith(city: "Select Location", isLoading: false));
      }
    }
  }
}
