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
  final List<String> images;
  final String category;
  final String locationId;
  final String ownerId;
  final bool isAvailable;

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
    this.images = const [],
    this.category = '',
    this.locationId = '',
    this.ownerId = '',
    this.isAvailable = true,
  });

  factory GroundModel.fromJson(Map<String, dynamic> json) {
    final location = json['locations'] as Map<String, dynamic>?;
    return GroundModel(
      id: json['id'],
      name: json['name'],
      address: location?['address'] ?? json['address'] ?? '',
      latitude: ((location?['latitude'] ?? json['latitude']) as num?)?.toDouble() ?? 0.0,
      longitude: ((location?['longitude'] ?? json['longitude']) as num?)?.toDouble() ?? 0.0,
      pricePerHour: json['price_per_hour'] ?? 0,
      imageUrl: json['imageUrl'] ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      openingTime: json['opening_time'] ?? '00:00:00',
      closingTime: json['closing_time'] ?? '00:00:00',
      city: location?['city'] ?? json['city'] ?? '',
      totalReviews: json['total_reviews'] ?? 0,
      description: json['description'] ?? '',
      amenities: ((location?['amenities'] ?? json['amenities']) as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      images: (json['images'] as List?)?.map((e) => e.toString()).toList() ?? [],
      category: json['category'] ?? '',
      locationId: json['location_id'] ?? '',
      ownerId: json['owner_id'] ?? '',
      isAvailable: json['is_available'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'price_per_hour': pricePerHour,
      'imageUrl': imageUrl,
      'rating': rating,
      'opening_time': openingTime,
      'closing_time': closingTime,
      'city': city,
      'total_reviews': totalReviews,
      'description': description,
      'amenities': amenities,
      'images': images,
      'category': category,
      'location_id': locationId,
      'owner_id': ownerId,
      'is_available': isAvailable,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GroundModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}