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
  final String? errorMessage;

  LocationState({
    this.city,
    this.latitude,
    this.longitude,
    this.isLoading = false,
    this.errorMessage,
  });

  LocationState copyWith({
    String? city,
    double? latitude,
    double? longitude,
    bool? isLoading,
    String? errorMessage,
  }) {
    return LocationState(
      city: city ?? this.city,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage, // Reset if not provided
    );
  }
}

class LocationCubit extends Cubit<LocationState> {
  final UserRepository repo;
  // Timer? _locationTimer;

  LocationCubit(this.repo) : super(LocationState()) {
    // _startPeriodicUpdate();
  }

  // void _startPeriodicUpdate() {
  //   _locationTimer?.cancel();
  //   // Update every 5 minutes as requested
  //   _locationTimer = Timer.periodic(const Duration(minutes: 5), (_) {
  //     print("[LOCATION_CUBIT] Periodic update triggered...");
  //     loadCity();
  //   });
  // }

  @override
  Future<void> close() {
    // _locationTimer?.cancel();
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
 Future<void> loadCity({bool forceRefresh = false}) async {
  if (state.city == null) {
    emit(state.copyWith(isLoading: true));
  }

  print("[LOCATION_CUBIT] Loading city...");

  try {
    /// STEP 1: Check stored city FIRST
    final storedCity = await repo.getUserCity();

    if (storedCity != null && !forceRefresh) {
      print("[LOCATION_CUBIT] Using stored city: $storedCity");

      // Optionally geocode to get lat/lng
      try {
        List<Location> locations = await locationFromAddress(storedCity);
        if (locations.isNotEmpty) {
          emit(state.copyWith(
            city: storedCity,
            latitude: locations.first.latitude,
            longitude: locations.first.longitude,
            isLoading: false,
            errorMessage: null,
          ));
        } else {
          emit(state.copyWith(
            city: storedCity,
            isLoading: false,
          ));
        }
      } catch (_) {
        emit(state.copyWith(
          city: storedCity,
          isLoading: false,
        ));
      }

      return; // 🚀 STOP here (no GPS call)
    }

    /// STEP 2: Fetch from GPS if no stored city
    print("[LOCATION_CUBIT] Fetching GPS location...");
    final userLoc = await getCurrentLocation();

    emit(state.copyWith(
      city: userLoc.city,
      latitude: userLoc.latitude,
      longitude: userLoc.longitude,
      isLoading: false,
      errorMessage: null,
    ));

    await repo.updateUserCity(userLoc.city);

  } catch (e) {
    print("[LOCATION_CUBIT] ERROR: $e");

    String? errorMsg;
    if (e.toString().contains('PERMISSION_DENIED')) {
      errorMsg = 'Location permission is required.';
    } else if (e.toString().contains('PERMISSION_PERMANENTLY_DENIED')) {
      errorMsg = 'Enable location from settings.';
    } else if (e.toString().contains('SERVICE_DISABLED')) {
      errorMsg = 'Turn on GPS.';
    }

    emit(state.copyWith(
      isLoading: false,
      errorMessage: errorMsg,
      city: state.city ?? "Select Location",
    ));
  }
}
}
