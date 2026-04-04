import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

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

  // 1. Check if device location services (GPS) are enabled.
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    return Future.error('Location services are disabled.');
  }

  // 2. Check current permission level.
  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    // 3. Request permission from user if denied.
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return Future.error('Location permissions are denied');
    }
  }

  // 4. Handle permanent permission denial (requires manual app settings change).
  if (permission == LocationPermission.deniedForever) {
    return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.');
  }

  // 5. Fetch device's absolute coordinates.
  final position = await Geolocator.getCurrentPosition();

  // 6. Perform reverse geocoding to get human-readable city name.
  final placemarks = await placemarkFromCoordinates(
    position.latitude,
    position.longitude,
  );

  final place = placemarks.first;

  // 7. Extract the most specific locality name possible.
  final city = place.locality ??
      place.subAdministrativeArea ??
      place.administrativeArea ??
      "Unknown";

  return UserLocation(
    city: city,
    latitude: position.latitude,
    longitude: position.longitude,
  );
}
