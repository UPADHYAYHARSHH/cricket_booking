import '../../data/models/review_model.dart';
import 'dart:typed_data';

abstract class ReviewRepository {
  Future<void> submitReview({
    required String userId,
    required String groundId,
    required double rating,
    required String reviewText,
    required List<Uint8List> mediaBytes,
    required List<String> mediaTypes, // 'image' or 'video'
  });

  Future<List<ReviewModel>> fetchGroundReviews(String groundId);
  Future<bool> hasUserRatedGround(String userId, String groundId);
}
