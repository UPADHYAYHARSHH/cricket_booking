class GroundModel {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final int pricePerHour;
  final String imageUrl;
  final double rating;
  final String openingTime;
  final String closingTime;
  final String city;
  final int totalReviews;
  final String description;
  final List<String> amenities;

  GroundModel({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.pricePerHour,
    required this.imageUrl,
    required this.rating,
    required this.openingTime,
    required this.closingTime,
    required this.city,
    required this.totalReviews,
    this.description = '',
    this.amenities = const [],
  });

  factory GroundModel.fromJson(Map<String, dynamic> json) {
    return GroundModel(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      pricePerHour: json['price_per_hour'] ?? 0,
      imageUrl: json['imageUrl'] ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      openingTime: json['opening_time'] ?? '00:00:00',
      closingTime: json['closing_time'] ?? '00:00:00',
      city: json['city'] ?? '',
      totalReviews: json['total_reviews'] ?? 0,
      description: json['description'] ?? '',
      amenities: (json['amenities'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}