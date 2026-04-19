class LoyaltyPointModel {
  final String id;
  final String userId;
  final int points;
  final DateTime expiryDate;
  final DateTime createdAt;
  final bool isUsed;

  LoyaltyPointModel({
    required this.id,
    required this.userId,
    required this.points,
    required this.expiryDate,
    required this.createdAt,
    this.isUsed = false,
  });

  factory LoyaltyPointModel.fromJson(Map<String, dynamic> json) {
    return LoyaltyPointModel(
      id: json['id'],
      userId: json['user_id'],
      points: json['points'],
      expiryDate: DateTime.parse(json['expiry_date']),
      createdAt: DateTime.parse(json['created_at']),
      isUsed: json['is_used'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'points': points,
      'expiry_date': expiryDate.toIso8601String(),
      'is_used': isUsed,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
