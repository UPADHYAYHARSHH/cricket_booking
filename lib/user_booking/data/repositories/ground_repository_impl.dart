import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/ground_repository.dart';
import 'package:bloc_structure/user_booking/data/models/ground_model.dart';

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
        imageUrl: e['ground_images'] != null && e['ground_images'].isNotEmpty ? e['ground_images'][0]['image_url'] : '',
      );
    }).toList();
  }
}
