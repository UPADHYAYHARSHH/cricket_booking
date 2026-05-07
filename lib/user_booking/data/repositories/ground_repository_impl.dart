import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/ground_repository.dart';
import 'package:turfpro/user_booking/data/models/ground_model.dart';

class GroundRepositoryImpl implements GroundRepository {
  final supabase = Supabase.instance.client;

  @override
  Future<List<GroundModel>> fetchGrounds() async {
    final response = await supabase.from('grounds').select('*, ground_images(image_url)');

    return (response as List).map((e) {
      final List<String> allImages = [];
      
      // 1. From relation
      if (e['ground_images'] != null && e['ground_images'] is List) {
        for (var img in (e['ground_images'] as List)) {
          if (img is Map && img['image_url'] != null) {
            allImages.add(img['image_url'].toString());
          }
        }
      }
      
      // 2. From 'images' column
      if (e['images'] != null && e['images'] is List) {
        allImages.addAll((e['images'] as List).map((i) => i.toString()));
      }
      
      // 3. From 'image_urls' column
      if (e['image_urls'] != null && e['image_urls'] is List) {
        allImages.addAll((e['image_urls'] as List).map((i) => i.toString()));
      }

      // Final Deduplication
      final uniqueImages = allImages.where((url) => url.isNotEmpty).toSet().toList();
      
      final imageUrl = uniqueImages.isNotEmpty 
          ? uniqueImages[0] 
          : (e['image_url'] ?? e['imageUrl'] ?? '');

      return GroundModel(
        id: e['id'],
        name: e['name'],
        address: e['address'],
        latitude: (e['latitude'] as num).toDouble(),
        longitude: (e['longitude'] as num).toDouble(),
        pricePerHour: e['price_per_hour'] ?? 0,
        rating: (e['rating'] as num?)?.toDouble() ?? 0.0,
        openingTime: e['opening_time'] ?? '00:00:00',
        closingTime: e['closing_time'] ?? '00:00:00',
        city: e['city'] ?? '',
        totalReviews: e['total_reviews'] ?? 0,
        description: e['description'] ?? '',
        amenities: (e['amenities'] as List?)?.map((a) => a.toString()).toList() ?? [],
        categories: (e['categories'] as List?)?.map((c) => c.toString()).toList() ?? [],
        ownerId: e['owner_id'] ?? '',
        isAvailable: e['is_available'] ?? true,
        imageUrl: imageUrl,
        images: uniqueImages,
      );
    }).toList();
  }
  
  @override
  Future<GroundModel?> fetchGroundById(String id) async {
    final response = await supabase.from('grounds').select('*, ground_images(image_url)').eq('id', id).maybeSingle();

    if (response == null) return null;

    final e = response;
    final List<String> allImages = [];
    
    if (e['ground_images'] != null && e['ground_images'] is List) {
      for (var img in (e['ground_images'] as List)) {
        if (img is Map && img['image_url'] != null) {
          allImages.add(img['image_url'].toString());
        }
      }
    }
    
    if (e['images'] != null && e['images'] is List) {
      allImages.addAll((e['images'] as List).map((i) => i.toString()));
    }
    
    if (e['image_urls'] != null && e['image_urls'] is List) {
      allImages.addAll((e['image_urls'] as List).map((i) => i.toString()));
    }

    final uniqueImages = allImages.where((url) => url.isNotEmpty).toSet().toList();
    
    final imageUrl = uniqueImages.isNotEmpty 
        ? uniqueImages[0] 
        : (e['image_url'] ?? e['imageUrl'] ?? '');

    return GroundModel(
      id: e['id'],
      name: e['name'],
      address: e['address'],
      latitude: (e['latitude'] as num).toDouble(),
      longitude: (e['longitude'] as num).toDouble(),
      pricePerHour: e['price_per_hour'] ?? 0,
      rating: (e['rating'] as num?)?.toDouble() ?? 0.0,
      openingTime: e['opening_time'] ?? '00:00:00',
      closingTime: e['closing_time'] ?? '00:00:00',
      city: e['city'] ?? '',
      totalReviews: e['total_reviews'] ?? 0,
      description: e['description'] ?? '',
      amenities: (e['amenities'] as List?)?.map((a) => a.toString()).toList() ?? [],
      categories: (e['categories'] as List?)?.map((c) => c.toString()).toList() ?? [],
      ownerId: e['owner_id'] ?? '',
      isAvailable: e['is_available'] ?? true,
      imageUrl: imageUrl,
      images: uniqueImages,
    );
  }
}
