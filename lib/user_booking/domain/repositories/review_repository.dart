import '../../data/models/review_model.dart';
import 'dart:typed_data';

abstract class ReviewRepository {
  Future<void> submitReview({
    required String userId,
    required String locationId,
    required double rating,
    required String reviewText,
    required List<Uint8List> mediaBytes,
    required List<String> mediaTypes, // 'image' or 'video'
  });

  Future<List<ReviewModel>> fetchLocationReviews(String locationId);
  Future<bool> hasUserRatedLocation(String userId, String locationId);
}
