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
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'],
      userId: json['user_id'],
      groundId: json['ground_id'],
      slotTime: DateTime.parse(json['slot_time']),
      amount: (json['amount'] as num).toDouble(),
      status: json['status'],
      razorpayOrderId: json['razorpay_order_id'] ?? '',
      razorpayPaymentId: json['razorpay_payment_id'] ?? '',
      razorpaySignature: json['razorpay_signature'] ?? '',
      displayId: json['display_id'] ?? 0,
      sportName: json['sport_name'],
      period: json['period'],
      ground: json['grounds'] != null ? GroundModel.fromJson(json['grounds']) : null,
    );
  }
}
