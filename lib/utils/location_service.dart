import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:location/location.dart' as loc;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;

class UserLocation {
  final String city;
  final double latitude;
  final double longitude;

  UserLocation({
    required this.city,
    required this.latitude,
    required this.longitude,
  });
}

/// FETCH CURRENT LOCATION AND CITY NAME BASED ON DEVICE COORDINATES
Future<UserLocation> getCurrentLocation() async {
  bool serviceEnabled;
  LocationPermission permission;

  // 1. Check current permission level.
  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    // 2. Request permission from user if denied.
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return Future.error('PERMISSION_DENIED');
    }
  }

  // 3. Handle permanent permission denial.
  if (permission == LocationPermission.deniedForever) {
    return Future.error('PERMISSION_PERMANENTLY_DENIED');
  }

  // 4. Check if device location services (GPS) are enabled.
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    // Attempt to request service natively
    final location = loc.Location();
    serviceEnabled = await location.requestService().timeout(
      const Duration(seconds: 10),
      onTimeout: () => false,
    );
    if (!serviceEnabled) {
      return Future.error('SERVICE_DISABLED');
    }
  }

  // 5. Fetch device's absolute coordinates with timeout & last-known fallback.
  Position? position;
  try {
    position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 8),
      ),
    );
  } catch (e) {
    debugPrint("getCurrentPosition failed/timed out: $e");
    if (!kIsWeb) {
      try {
        position = await Geolocator.getLastKnownPosition();
      } catch (lastKnownError) {
        debugPrint("getLastKnownPosition failed: $lastKnownError");
      }
    }
  }

  if (position == null) {
    return Future.error('LOCATION_TIMEOUT');
  }

  String city = "Unknown";

  // 6. Perform reverse geocoding (Mobile only, not supported on Web)
  if (!kIsWeb) {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      ).timeout(const Duration(seconds: 5));

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final candidates = [
          place.locality,
          place.subAdministrativeArea,
          place.administrativeArea,
        ];
        final resolved = candidates.firstWhere(
          (c) => c != null && c.trim().isNotEmpty,
          orElse: () => null,
        );
        if (resolved != null) {
          city = resolved.trim();
        }
      }
    } catch (e) {
      debugPrint("Reverse geocoding failed: $e");
    }
  }

  return UserLocation(
    city: city,
    latitude: position.latitude,
    longitude: position.longitude,
  );
}
