class LocationModel {
  final String id;
  final String address;
  final String city;
  final double latitude;
  final double longitude;
  final List<String> amenities;

  LocationModel({
    required this.id,
    required this.address,
    required this.city,
    required this.latitude,
    required this.longitude,
    required this.amenities,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      id: json['id']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      amenities: (json['amenities'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}
