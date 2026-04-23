import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:location/location.dart' as loc;

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
    serviceEnabled = await location.requestService();
    if (!serviceEnabled) {
      return Future.error('SERVICE_DISABLED');
    }
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
