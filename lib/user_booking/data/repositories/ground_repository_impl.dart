import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/ground_repository.dart';
import 'package:turfpro/user_booking/data/models/ground_model.dart';

class GroundRepositoryImpl implements GroundRepository {
  final supabase = Supabase.instance.client;

  static const _select =
      '*, ground_images(image_url), locations(address, city, latitude, longitude, amenities)';

  static const _selectActiveOnly =
      '*, ground_images(image_url), locations!inner(address, city, latitude, longitude, amenities, is_active, documents_verified)';

  @override
  Future<List<GroundModel>> fetchGrounds() async {
    final response = await supabase
        .from('grounds')
        .select(_selectActiveOnly)
        .eq('is_available', true)
        .eq('locations.is_active', true)
        .eq('locations.documents_verified', true);

    return (response as List).map((e) => _toModel(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<GroundModel?> fetchGroundById(String id) async {
    final response =
        await supabase.from('grounds').select(_select).eq('id', id).maybeSingle();

    if (response == null) return null;
    return _toModel(response);
  }

  GroundModel _toModel(Map<String, dynamic> e) {
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

    final imageUrl =
        uniqueImages.isNotEmpty ? uniqueImages[0] : (e['image_url'] ?? e['imageUrl'] ?? '');

    return GroundModel.fromJson({
      ...e,
      'imageUrl': imageUrl,
      'images': uniqueImages,
    });
  }
}
