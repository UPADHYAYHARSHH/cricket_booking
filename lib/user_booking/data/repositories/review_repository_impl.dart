import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/review_repository.dart';
import '../models/review_model.dart';

class ReviewRepositoryImpl implements ReviewRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  Future<void> submitReview({
    required String userId,
    required String locationId,
    required double rating,
    required String reviewText,
    required List<Uint8List> mediaBytes,
    required List<String> mediaTypes,
  }) async {
    List<String> mediaUrls = [];

    // 1. Upload media to Supabase Storage
    for (int i = 0; i < mediaBytes.length; i++) {
      final fileName = '${userId}_${locationId}_${DateTime.now().millisecondsSinceEpoch}_$i';
      final fileExtension = mediaTypes[i] == 'image' ? 'jpg' : 'mp4';
      final path = 'review_media/$fileName.$fileExtension';

      try {
        await _supabase.storage.from('reviews').uploadBinary(
              path,
              mediaBytes[i],
              fileOptions: FileOptions(
                  contentType: mediaTypes[i] == 'image' ? 'image/jpeg' : 'video/mp4',
                  upsert: true),
            );

        final String publicUrl = _supabase.storage.from('reviews').getPublicUrl(path);
        mediaUrls.add(publicUrl);
      } catch (e) {
        print("Storage Upload Error for review media: $e");
        throw Exception("Failed to upload review media. Make sure 'reviews' bucket exists.");
      }
    }

    // 2. Insert review record
    await _supabase.from('location_reviews').insert({
      'user_id': userId,
      'location_id': locationId,
      'rating': rating,
      'review_text': reviewText,
      'media_urls': mediaUrls,
    });

    // 3. Send notification to the owner
    try {
      final locationData = await _supabase
          .from('locations')
          .select('owner_id, name')
          .eq('id', locationId)
          .single();
          
      final String ownerId = locationData['owner_id']?.toString() ?? '';
      final String locationName = locationData['name']?.toString() ?? 'their venue';

      if (ownerId.isNotEmpty) {
        await _supabase.from('notifications').insert({
          'user_id': ownerId,
          'title': 'New Review for $locationName',
          'message': 'A user just gave a ${rating.toStringAsFixed(1)}-star review!',
          'type': 'review',
          'is_read': false,
          'created_at': DateTime.now().toUtc().toIso8601String(),
        });
      }
    } catch (e) {
      print("Failed to send review notification to owner: $e");
    }
  }

  @override
  Future<List<ReviewModel>> fetchLocationReviews(String locationId) async {
    try {
      final response = await _supabase
          .from('location_reviews')
          .select('*, users(name, photo_url)')
          .eq('location_id', locationId)
          .order('created_at', ascending: false);

      return (response as List).map((e) => ReviewModel.fromJson(e)).toList();
    } catch (e) {
      print("Error fetching reviews: $e");
      return [];
    }
  }

  @override
  Future<bool> hasUserRatedLocation(String userId, String locationId) async {
    try {
      final response = await _supabase
          .from('location_reviews')
          .select('id')
          .eq('user_id', userId)
          .eq('location_id', locationId)
          .limit(1);

      return (response as List).isNotEmpty;
    } catch (e) {
      print("Error checking user rating: $e");
      return false;
    }
  }
}
