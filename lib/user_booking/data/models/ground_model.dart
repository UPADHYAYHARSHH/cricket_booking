import 'package:flutter/foundation.dart';

class GroundModel {
  final String id;
  final String name;
  final String locationName;
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
  final String privacyPolicy;
  final List<String> amenities;
  final List<String> images;
  final List<String> categories;
  final String ownerId;
  final String locationId;
  final bool isAvailable;
  final int? morningPrice;
  final int? afternoonPrice;
  final int? eveningPrice;
  final int? nightPrice;
  final int? weekendMorningPrice;
  final int? weekendAfternoonPrice;
  final int? weekendEveningPrice;
  final int? weekendNightPrice;
  final List<int> operatingDays;

  GroundModel({
    required this.id,
    required this.name,
    this.locationName = '',
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
    this.morningPrice,
    this.afternoonPrice,
    this.eveningPrice,
    this.nightPrice,
    this.weekendMorningPrice,
    this.weekendAfternoonPrice,
    this.weekendEveningPrice,
    this.weekendNightPrice,
    this.description = '',
    this.locationDescription = '',
    this.privacyPolicy = '',
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
      locationName: (json['locations'] is Map && json['locations']['name'] != null) ? json['locations']['name'].toString() : (json['location_name']?.toString() ?? ''),
      address: (json['locations'] is Map && json['locations']['address'] != null && json['locations']['address'].toString().isNotEmpty) 
          ? json['locations']['address'].toString() 
          : json['address']?.toString() ?? '',
      latitude: (json['locations'] is Map && json['locations']['latitude'] != null)
          ? (double.tryParse(json['locations']['latitude'].toString()) ?? 0.0)
          : (double.tryParse(json['latitude']?.toString() ?? '') ?? 0.0),
      longitude: (json['locations'] is Map && json['locations']['longitude'] != null)
          ? (double.tryParse(json['locations']['longitude'].toString()) ?? 0.0)
          : (double.tryParse(json['longitude']?.toString() ?? '') ?? 0.0),
      pricePerHour: json['price_per_hour'] ?? 0,
      weekendPrice: json['weekend_price'] ?? 0,
      morningPrice: (json['morning_price'] as num?)?.toInt(),
      afternoonPrice: (json['afternoon_price'] as num?)?.toInt(),
      eveningPrice: (json['evening_price'] as num?)?.toInt(),
      nightPrice: (json['night_price'] as num?)?.toInt(),
      weekendMorningPrice: (json['weekend_morning_price'] as num?)?.toInt(),
      weekendAfternoonPrice: (json['weekend_afternoon_price'] as num?)?.toInt(),
      weekendEveningPrice: (json['weekend_evening_price'] as num?)?.toInt(),
      weekendNightPrice: (json['weekend_night_price'] as num?)?.toInt(),
      imageUrl: json['imageUrl'] ?? '',
      rating: (json['locations'] is Map && json['locations']['rating'] != null)
          ? (json['locations']['rating'] as num).toDouble()
          : ((json['rating'] as num?)?.toDouble() ?? 0.0),
      openingTime: json['opening_time'] ?? '00:00:00',
      closingTime: json['closing_time'] ?? '00:00:00',
      slotDuration: json['slot_duration']?.toString() ?? '1 hour',
      city: (json['locations'] is Map && json['locations']['city'] != null && json['locations']['city'].toString().isNotEmpty) 
          ? json['locations']['city'].toString() 
          : json['city']?.toString() ?? '',
      totalReviews: (json['locations'] is Map && json['locations']['total_reviews'] != null)
          ? json['locations']['total_reviews']
          : (json['total_reviews'] ?? 0),
      description: json['description'] ?? '',
      locationDescription: json['location_description'] ?? json['locations']?['description'] ?? '',
      privacyPolicy: json['privacy_policy'] ?? json['locations']?['privacy_policy'] ?? '',
      amenities: () {
        final list = <String>[];
        if (json['amenities'] is List) {
          list.addAll((json['amenities'] as List).map((a) => a.toString()));
        }
        final loc = json['locations'];
        if (loc is Map && loc['amenities'] is List) {
          list.addAll((loc['amenities'] as List).map((a) => a.toString()));
        } else if (loc is List && loc.isNotEmpty && loc.first is Map && loc.first['amenities'] is List) {
          list.addAll((loc.first['amenities'] as List).map((a) => a.toString()));
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
      'locationName': locationName,
      'displayName': displayName,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'price_per_hour': pricePerHour,
      'weekend_price': weekendPrice,
      'morning_price': morningPrice,
      'afternoon_price': afternoonPrice,
      'evening_price': eveningPrice,
      'night_price': nightPrice,
      'imageUrl': imageUrl,
      'rating': rating,
      'opening_time': openingTime,
      'closing_time': closingTime,
      'slot_duration': slotDuration,
      'city': city,
      'total_reviews': totalReviews,
      'description': description,
      'location_description': locationDescription,
      'privacy_policy': privacyPolicy,
      'amenities': amenities,
      'images': images,
      'categories': categories,
      'owner_id': ownerId,
      'weekend_morning_price': weekendMorningPrice,
      'weekend_afternoon_price': weekendAfternoonPrice,
      'weekend_evening_price': weekendEveningPrice,
      'weekend_night_price': weekendNightPrice,
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

  /// Returns the price for a specific slot date and time, taking into account
  /// time-of-day rates (morning, afternoon, evening, night) and weekday/weekend base rates.
  double getPriceForSlot(DateTime slotTime) {
    final hour = slotTime.hour;
    final isWeekend = slotTime.weekday == DateTime.saturday || slotTime.weekday == DateTime.sunday;

    int? customPrice;
    if (isWeekend) {
      if (hour >= 6 && hour < 12) {
        customPrice = weekendMorningPrice;
      } else if (hour >= 12 && hour < 16) {
        customPrice = weekendAfternoonPrice;
      } else if (hour >= 16 && hour < 20) {
        customPrice = weekendEveningPrice;
      } else {
        customPrice = weekendNightPrice;
      }
    } else {
      if (hour >= 6 && hour < 12) {
        customPrice = morningPrice;
      } else if (hour >= 12 && hour < 16) {
        customPrice = afternoonPrice;
      } else if (hour >= 16 && hour < 20) {
        customPrice = eveningPrice;
      } else {
        customPrice = nightPrice;
      }
    }

    if (customPrice != null && customPrice > 0) {
      return customPrice.toDouble();
    }

    if (isWeekend && weekendPrice > 0) {
      return weekendPrice.toDouble();
    }
    return pricePerHour.toDouble();
  }

  GroundModel copyWith({
    String? id,
    String? name,
    String? locationName,
    String? displayName,
    String? address,
    double? latitude,
    double? longitude,
    int? pricePerHour,
    int? weekendPrice,
    int? morningPrice,
    int? afternoonPrice,
    int? eveningPrice,
    int? nightPrice,
    int? weekendMorningPrice,
    int? weekendAfternoonPrice,
    int? weekendEveningPrice,
    int? weekendNightPrice,
    String? imageUrl,
    double? rating,
    String? openingTime,
    String? closingTime,
    String? slotDuration,
    String? city,
    int? totalReviews,
    String? description,
    String? locationDescription,
    String? privacyPolicy,
    List<String>? amenities,
    List<String>? images,
    List<String>? categories,
    String? ownerId,
    String? locationId,
    bool? isAvailable,
    List<int>? operatingDays,
  }) {
    return GroundModel(
      id: id ?? this.id,
      name: name ?? this.name,
      locationName: locationName ?? this.locationName,
      displayName: displayName ?? this.displayName,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      pricePerHour: pricePerHour ?? this.pricePerHour,
      weekendPrice: weekendPrice ?? this.weekendPrice,
      morningPrice: morningPrice ?? this.morningPrice,
      afternoonPrice: afternoonPrice ?? this.afternoonPrice,
      eveningPrice: eveningPrice ?? this.eveningPrice,
      nightPrice: nightPrice ?? this.nightPrice,
      weekendMorningPrice: weekendMorningPrice ?? this.weekendMorningPrice,
      weekendAfternoonPrice: weekendAfternoonPrice ?? this.weekendAfternoonPrice,
      weekendEveningPrice: weekendEveningPrice ?? this.weekendEveningPrice,
      weekendNightPrice: weekendNightPrice ?? this.weekendNightPrice,
      imageUrl: imageUrl ?? this.imageUrl,
      rating: rating ?? this.rating,
      openingTime: openingTime ?? this.openingTime,
      closingTime: closingTime ?? this.closingTime,
      slotDuration: slotDuration ?? this.slotDuration,
      city: city ?? this.city,
      totalReviews: totalReviews ?? this.totalReviews,
      description: description ?? this.description,
      locationDescription: locationDescription ?? this.locationDescription,
      privacyPolicy: privacyPolicy ?? this.privacyPolicy,
      amenities: amenities ?? this.amenities,
      images: images ?? this.images,
      categories: categories ?? this.categories,
      ownerId: ownerId ?? this.ownerId,
      locationId: locationId ?? this.locationId,
      isAvailable: isAvailable ?? this.isAvailable,
      operatingDays: operatingDays ?? this.operatingDays,
    );
  }
}