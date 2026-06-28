class ReviewModel {
  final String id;
  final String userId;
  final String userName;
  final String userImage;
  final String groundId;
  final double rating;
  final String reviewText;
  final List<String> mediaUrls;
  final DateTime createdAt;

  ReviewModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userImage,
    required this.groundId,
    required this.rating,
    required this.reviewText,
    required this.mediaUrls,
    required this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    // Assuming 'users' is joined in the Supabase query
    final userData = json['users'] as Map<String, dynamic>?;
    
    return ReviewModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      userName: userData?['name']?.toString() ?? 'User',
      userImage: userData?['photo_url']?.toString() ?? '',
      groundId: json['ground_id']?.toString() ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewText: json['review_text']?.toString() ?? '',
      mediaUrls: (json['media_urls'] as List?)?.map((e) => e.toString()).toList() ?? [],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'ground_id': groundId,
      'rating': rating,
      'review_text': reviewText,
      'media_urls': mediaUrls,
    };
  }
}
