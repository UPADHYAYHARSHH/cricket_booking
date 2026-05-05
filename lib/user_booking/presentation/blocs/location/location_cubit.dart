import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:bloc/bloc.dart';

import '../../../../utils/location_service.dart';
import '../../../data/repositories/user_repository_impl.dart';

import 'package:geocoding/geocoding.dart';

class LocationState {
  final String? city;
  final double? latitude; // For filtering
  final double? longitude; // For filtering
  final double? gpsLatitude; // Origin for distance
  final double? gpsLongitude; // Origin for distance
  final bool isLoading;
  final String? errorMessage;
  final bool hasGpsLocation;

  LocationState({
    this.city,
    this.latitude,
    this.longitude,
    this.gpsLatitude,
    this.gpsLongitude,
    this.isLoading = false,
    this.errorMessage,
    this.hasGpsLocation = false,
  });

  LocationState copyWith({
    String? city,
    double? latitude,
    double? longitude,
    double? gpsLatitude,
    double? gpsLongitude,
    bool? isLoading,
    String? errorMessage,
    bool? hasGpsLocation,
  }) {
    return LocationState(
      city: city ?? this.city,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      gpsLatitude: gpsLatitude ?? this.gpsLatitude,
      gpsLongitude: gpsLongitude ?? this.gpsLongitude,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage, // Reset if not provided
      hasGpsLocation: hasGpsLocation ?? this.hasGpsLocation,
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
  //     debugPrint("[LOCATION_CUBIT] Periodic update triggered...");
  //     loadCity();
  //   });
  // }

  @override
  Future<void> close() {
    // _locationTimer?.cancel();
    return super.close();
  }

  /// MANUALLY SET CITY AND PERSIST TO DATABASE
  Future<void> setCity(String cityLabel, {double? lat, double? lng}) async {
    emit(state.copyWith(isLoading: true));

    debugPrint("[LOCATION_CUBIT] Setting city manually to: $cityLabel (lat: $lat, lng: $lng)");
    final cityName = cityLabel.split(',').first.trim();

    try {
      double? finalLat = lat;
      double? finalLng = lng;

      // If coordinates not provided and not on web, try geocoding
      if (finalLat == null || finalLng == null) {
        if (!kIsWeb) {
          try {
            debugPrint("[LOCATION_CUBIT] Geocoding cityName: $cityName");
            List<Location> locations = await locationFromAddress(cityName);
            if (locations.isNotEmpty) {
              finalLat = locations.first.latitude;
              finalLng = locations.first.longitude;
              debugPrint("[LOCATION_CUBIT] Successfully geocoded to Lat: $finalLat, Lng: $finalLng");
            }
          } catch (e) {
            debugPrint("[LOCATION_CUBIT] Geocoding failed: $e");
          }
        } else {
          debugPrint("[LOCATION_CUBIT] Geocoding skipped on web");
        }
      }

      emit(state.copyWith(
        city: cityLabel,
        latitude: finalLat,
        longitude: finalLng,
        isLoading: false,
        hasGpsLocation: finalLat != null && finalLng != null,
      ));

      debugPrint("[LOCATION_CUBIT] Persisting city to profile...");
      await repo.updateUserCity(cityLabel);
    } catch (e) {
      debugPrint("[LOCATION_CUBIT] ERROR in setCity: $e");
      emit(state.copyWith(city: cityLabel, isLoading: false, hasGpsLocation: false));
    }
  }

  /// INITIALIZE CITY FROM DATABASE OR CURRENT POSITION
  Future<void> loadCity({bool forceRefresh = false}) async {
    if (state.city == null) {
      emit(state.copyWith(isLoading: true));
    }

    debugPrint("[LOCATION_CUBIT] Loading city...");

    try {
      /// STEP 1: Check stored city FIRST
      final storedCity = await repo.getUserCity();

      if (storedCity != null && !forceRefresh) {
        debugPrint("[LOCATION_CUBIT] Found stored city: $storedCity");

        // Set initial state from stored city
        if (!kIsWeb) {
          try {
            List<Location> locations = await locationFromAddress(storedCity);
            if (locations.isNotEmpty) {
              emit(state.copyWith(
                city: storedCity,
                latitude: locations.first.latitude,
                longitude: locations.first.longitude,
                isLoading: false,
                errorMessage: null,
                hasGpsLocation: true, // Allow distance display from stored coordinates
              ));
            } else {
              emit(state.copyWith(
                city: storedCity,
                isLoading: false,
                hasGpsLocation: false,
              ));
            }
          } catch (_) {
            emit(state.copyWith(
              city: storedCity,
              isLoading: false,
              hasGpsLocation: false,
            ));
          }
        } else {
          emit(state.copyWith(
            city: storedCity,
            isLoading: false,
            hasGpsLocation: false,
          ));
        }

        // 🚀 CONTINUE to fetch GPS location in background to get accurate distance
        debugPrint("[LOCATION_CUBIT] Continuing to fetch GPS for distance...");
      }

      /// STEP 2: Fetch from GPS
      debugPrint("[LOCATION_CUBIT] Fetching GPS location...");
      final userLoc = await getCurrentLocation();

      // Only update city name if it's not "Unknown" or if we don't have one yet
      final bool shouldUpdateCity = userLoc.city != "Unknown" || state.city == null;

      emit(state.copyWith(
        city: shouldUpdateCity ? userLoc.city : state.city,
        latitude: userLoc.latitude,
        longitude: userLoc.longitude,
        gpsLatitude: userLoc.latitude,
        gpsLongitude: userLoc.longitude,
        isLoading: false,
        errorMessage: null,
        hasGpsLocation: true, // Successfully fetched GPS
      ));

      if (shouldUpdateCity && userLoc.city != "Unknown") {
        await repo.updateUserCity(userLoc.city);
      }
    } catch (e) {
      debugPrint("[LOCATION_CUBIT] GPS ERROR: $e");

      String? errorMsg;
      if (e.toString().contains('PERMISSION_DENIED')) {
        errorMsg = 'Location permission is required.';
      } else if (e.toString().contains('PERMISSION_PERMANENTLY_DENIED')) {
        errorMsg = 'Enable location from settings.';
      } else if (e.toString().contains('SERVICE_DISABLED')) {
        errorMsg = 'Turn on GPS.';
      }

      // If we already have a city (from stored or previous), keep it but set GPS to false
      emit(state.copyWith(
        isLoading: false,
        errorMessage: errorMsg,
        city: state.city ?? "Select Location",
        hasGpsLocation: false,
      ));
    }
  }
}
