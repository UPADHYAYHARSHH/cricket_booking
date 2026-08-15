import 'package:turfpro/user_booking/data/models/ground_model.dart';

class VenueModel {
  final String locationId;
  final String name;
  final String address;
  final String city;
  final double rating;
  final int totalReviews;
  final String imageUrl;
  final List<String> images;
  final List<String> availableSports;
  final List<GroundModel> pitches;
  final double latitude;
  final double longitude;
  final String privacyPolicy;
  final List<String> amenities;

  VenueModel({
    required this.locationId,
    required this.name,
    required this.address,
    required this.city,
    required this.rating,
    required this.totalReviews,
    required this.imageUrl,
    required this.images,
    required this.availableSports,
    required this.pitches,
    required this.latitude,
    required this.longitude,
    required this.privacyPolicy,
    required this.amenities,
  });

  /// Creates a VenueModel by grouping a list of GroundModels that belong to the same location.
  factory VenueModel.fromGrounds(String locationId, List<GroundModel> grounds) {
    if (grounds.isEmpty) {
      throw Exception('Cannot create a VenueModel without grounds');
    }

    final firstGround = grounds.first;
    
    // Extract unique sports from all categories/ground_types across all pitches
    final Set<String> sportsSet = {};
    for (var ground in grounds) {
      for (var category in ground.categories) {
        // Format category: replace underscores with spaces and capitalize words
        final formatted = category.split('_').map((word) {
          if (word.isEmpty) return word;
          return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
        }).join(' ');
        sportsSet.add(formatted);
      }
    }
    
    // Sort pitches by name or ID
    grounds.sort((a, b) => a.name.compareTo(b.name));

    return VenueModel(
      locationId: locationId,
      name: firstGround.locationDescription.isNotEmpty 
          ? firstGround.locationDescription 
          : firstGround.address.split(',').first, // Use location description or address
      address: firstGround.address,
      city: firstGround.city,
      rating: firstGround.rating, // Could also average the ratings
      totalReviews: firstGround.totalReviews,
      imageUrl: firstGround.imageUrl,
      images: firstGround.images,
      latitude: firstGround.latitude,
      longitude: firstGround.longitude,
      privacyPolicy: firstGround.privacyPolicy,
      amenities: firstGround.amenities,
      availableSports: sportsSet.toList()..sort(),
      pitches: grounds,
    );
  }
}