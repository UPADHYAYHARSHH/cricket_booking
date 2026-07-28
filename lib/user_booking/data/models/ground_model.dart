import 'package:flutter/foundation.dart';

class GroundModel {
  final String id;
  final String name;
  final String displayName;
  final String address;
  final double latitude;
  final double longitude;
  final int pricePerHour;
  final int weekendPrice;
  final String imageUrl;
  final double rating;
  final String openingTime;
  final String closingTime;
  final String slotDuration;
  final String city;
  final int totalReviews;
  final String description;
  final String locationDescription;
  final List<String> amenities;
  final List<String> images;
  final List<String> categories;
  final String ownerId;
  final String locationId;
  final bool isAvailable;
  final List<int> operatingDays;

  GroundModel({
    required this.id,
    required this.name,
    this.displayName = '',
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.pricePerHour,
    required this.imageUrl,
    required this.rating,
    required this.openingTime,
    required this.closingTime,
    required this.slotDuration,
    required this.city,
    required this.totalReviews,
    this.weekendPrice = 0,
    this.description = '',
    this.locationDescription = '',
    this.amenities = const [],
    this.images = const [],
    this.categories = const [],
    this.ownerId = '',
    this.locationId = '',
    this.isAvailable = true,
    this.operatingDays = const [1, 2, 3, 4, 5, 6, 7],
  });

  factory GroundModel.fromJson(Map<String, dynamic> json) {
    return GroundModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      address: (json['locations'] is Map && json['locations']['address'] != null && json['locations']['address'].toString().isNotEmpty) 
          ? json['locations']['address'].toString() 
          : json['address']?.toString() ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      pricePerHour: json['price_per_hour'] ?? 0,
      weekendPrice: json['weekend_price'] ?? 0,
      imageUrl: json['imageUrl'] ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      openingTime: json['opening_time'] ?? '00:00:00',
      closingTime: json['closing_time'] ?? '00:00:00',
      slotDuration: json['slot_duration']?.toString() ?? '1 hour',
      city: (json['locations'] is Map && json['locations']['city'] != null && json['locations']['city'].toString().isNotEmpty) 
          ? json['locations']['city'].toString() 
          : json['city']?.toString() ?? '',
      totalReviews: json['total_reviews'] ?? 0,
      description: json['description'] ?? '',
      locationDescription: json['location_description'] ?? json['locations']?['description'] ?? '',
      amenities: () {
        final list = <String>[];
        if (json['amenities'] is List) {
           list.addAll((json['amenities'] as List).map((a) => a.toString()));
        }
        if (json['has_parking'] == true) list.add('Parking');
        if (json['has_washroom'] == true) list.add('Washroom');
        if (json['has_floodlights'] == true) list.add('Floodlights');
        if (json['has_drinking_water'] == true) list.add('Drinking Water');
        return list.toSet().toList();
      }(),
      images: (json['images'] as List?)?.map((e) => e.toString()).toList() ?? [],
      categories: () {
        final list = <String>[];
        if (json['categories'] is List) {
          list.addAll((json['categories'] as List).map((e) => e.toString()));
        }
        if (json['ground_type'] != null && json['ground_type'].toString().isNotEmpty) {
          list.add(json['ground_type'].toString());
        }
        if (json['category'] != null && json['category'].toString().isNotEmpty) {
          list.add(json['category'].toString());
        }
        return list.toSet().toList();
      }(),
      ownerId: json['owner_id'] ?? '',
      locationId: json['location_id']?.toString() ?? '',
      isAvailable: json['is_available'] ?? true,
      operatingDays: () {
        debugPrint("[GROUND_MODEL] Parsing operating_days for ${json['name']}: ${json['operating_days']}");
        if (json['operating_days'] is List) {
          return (json['operating_days'] as List).map((e) {
            final val = e.toString().toLowerCase();
            if (val.startsWith('mon')) return 1;
            if (val.startsWith('tue')) return 2;
            if (val.startsWith('wed')) return 3;
            if (val.startsWith('thu')) return 4;
            if (val.startsWith('fri')) return 5;
            if (val.startsWith('sat')) return 6;
            if (val.startsWith('sun')) return 7;
            return int.tryParse(val) ?? 1;
          }).toList();
        }
        return [1, 2, 3, 4, 5, 6, 7];
      }(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'displayName': displayName,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'price_per_hour': pricePerHour,
      'weekend_price': weekendPrice,
      'imageUrl': imageUrl,
      'rating': rating,
      'opening_time': openingTime,
      'closing_time': closingTime,
      'slot_duration': slotDuration,
      'city': city,
      'total_reviews': totalReviews,
      'description': description,
      'location_description': locationDescription,
      'amenities': amenities,
      'images': images,
      'categories': categories,
      'owner_id': ownerId,
      'location_id': locationId,
      'is_available': isAvailable,
      'operating_days': operatingDays,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GroundModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}