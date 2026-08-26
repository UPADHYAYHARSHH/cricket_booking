class LocationModel {
  final String id;
  final String address;
  final String city;
  final double latitude;
  final double longitude;
  final List<String> amenities;
  final List<String> sports;
  final double rating;
  final int totalReviews;
  final List<String> images;

  LocationModel({
    required this.id,
    required this.address,
    required this.city,
    required this.latitude,
    required this.longitude,
    required this.amenities,
    this.sports = const [],
    this.rating = 0.0,
    this.totalReviews = 0,
    this.images = const [],
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      id: json['id']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      latitude: double.tryParse(json['latitude']?.toString() ?? '') ?? 0.0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '') ?? 0.0,
      amenities: (json['amenities'] as List?)?.map((e) => e.toString()).toList() ?? [],
      sports: (json['sports'] as List?)?.map((e) => e.toString()).toList() ?? [],
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: json['total_reviews'] ?? 0,
      images: (json['images'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}
