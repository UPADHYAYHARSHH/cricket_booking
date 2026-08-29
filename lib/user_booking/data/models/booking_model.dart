import '../../data/models/ground_model.dart';

class BookingModel {
  final String id;
  final String userId;
  final String groundId;
  final DateTime slotTime;
  final double amount;
  final String status;
  final String razorpayOrderId;
  final String razorpayPaymentId;
  final String razorpaySignature;
  final int displayId;
  final String? sportName;
  final String? period;
  final GroundModel? ground;
  final bool checkedIn;
  final DateTime? checkedInAt;
  final double platformFee;
  final double commissionRate;
  final bool commissionIsPercentage;
  final double baseAmount;
  final double ownerEarnings;

  BookingModel({
    required this.id,
    required this.userId,
    required this.groundId,
    required this.slotTime,
    required this.amount,
    required this.status,
    required this.razorpayOrderId,
    required this.razorpayPaymentId,
    required this.razorpaySignature,
    required this.displayId,
    this.sportName,
    this.period,
    this.ground,
    this.checkedIn = false,
    this.checkedInAt,
    this.platformFee = 0.0,
    this.commissionRate = 0.0,
    this.commissionIsPercentage = true,
    this.baseAmount = 0.0,
    this.ownerEarnings = 0.0,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      groundId: json['ground_id']?.toString() ?? '',
      slotTime: DateTime.parse(json['slot_time'] ?? DateTime.now().toIso8601String()).toLocal(),
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      status: json['status']?.toString() ?? '',
      razorpayOrderId: json['razorpay_order_id'] ?? '',
      razorpayPaymentId: json['razorpay_payment_id'] ?? '',
      razorpaySignature: json['razorpay_signature'] ?? '',
      displayId: json['display_id'] ?? 0,
      sportName: json['sport_name'],
      period: json['period'],
      ground: json['grounds'] != null ? GroundModel.fromJson(json['grounds']) : null,
      checkedIn: json['checked_in'] == true,
      checkedInAt: json['checked_in_at'] != null ? DateTime.tryParse(json['checked_in_at'])?.toLocal() : null,
      platformFee: (json['platform_fee'] as num?)?.toDouble() ?? 0.0,
      commissionRate: (json['commission_rate'] as num?)?.toDouble() ?? 0.0,
      commissionIsPercentage: json['commission_is_percentage'] ?? true,
      baseAmount: (json['base_amount'] as num?)?.toDouble() ?? 0.0,
      ownerEarnings: (json['owner_earnings'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
