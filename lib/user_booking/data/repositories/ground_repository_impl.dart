import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/ground_repository.dart';
import 'package:turfpro/user_booking/data/models/ground_model.dart';

class GroundRepositoryImpl implements GroundRepository {
  final supabase = Supabase.instance.client;

  @override
  Future<List<GroundModel>> fetchGrounds() async {
    final response = await supabase.from('grounds').select('''
          id,
          name,
          address,
          latitude,
          longitude,
          price_per_hour,
          rating,
          opening_time,
          closing_time,
          city,
          total_reviews,
          description,
          amenities,
          categories,
          owner_id,
          ground_images(image_url)
        ''');

    return (response as List).map((e) {
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
        imageUrl: e['ground_images'] != null && e['ground_images'].isNotEmpty ? e['ground_images'][0]['image_url'] : '',
      );
    }).toList();
  }
  
  @override
  Future<GroundModel?> fetchGroundById(String id) async {
    final response = await supabase.from('grounds').select('''
          id,
          name,
          address,
          latitude,
          longitude,
          price_per_hour,
          rating,
          opening_time,
          closing_time,
          city,
          total_reviews,
          description,
          amenities,
          categories,
          owner_id,
          ground_images(image_url)
        ''').eq('id', id).maybeSingle();

    if (response == null) return null;

    final e = response;
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
      imageUrl: e['ground_images'] != null && e['ground_images'].isNotEmpty ? e['ground_images'][0]['image_url'] : '',
    );
  }
}
