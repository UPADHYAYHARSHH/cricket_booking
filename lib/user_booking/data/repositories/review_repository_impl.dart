import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/review_repository.dart';
import '../models/review_model.dart';

class ReviewRepositoryImpl implements ReviewRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  Future<void> submitReview({
    required String userId,
    required String groundId,
    required double rating,
    required String reviewText,
    required List<Uint8List> mediaBytes,
    required List<String> mediaTypes,
  }) async {
    List<String> mediaUrls = [];

    // 1. Upload media to Supabase Storage
    for (int i = 0; i < mediaBytes.length; i++) {
      final fileName = '${userId}_${groundId}_${DateTime.now().millisecondsSinceEpoch}_$i';
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
        // We could either fail the whole thing or just skip this media. 
        // Failing seems safer for data consistency.
        throw Exception("Failed to upload review media. Make sure 'reviews' bucket exists.");
      }
    }

    // 2. Insert review record
    await _supabase.from('reviews').insert({
      'user_id': userId,
      'ground_id': groundId,
      'rating': rating,
      'review_text': reviewText,
      'media_urls': mediaUrls,
    });
  }

  @override
  Future<List<ReviewModel>> fetchGroundReviews(String groundId) async {
    try {
      final response = await _supabase
          .from('reviews')
          .select('*, users(name, photo_url)')
          .eq('ground_id', groundId)
          .order('created_at', ascending: false);

      return (response as List).map((e) => ReviewModel.fromJson(e)).toList();
    } catch (e) {
      print("Error fetching reviews: $e");
      return [];
    }
  }

  @override
  Future<bool> hasUserRatedGround(String userId, String groundId) async {
    try {
      final response = await _supabase
          .from('reviews')
          .select('id')
          .eq('user_id', userId)
          .eq('ground_id', groundId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print("Error checking user rating: $e");
      return false;
    }
  }
}
