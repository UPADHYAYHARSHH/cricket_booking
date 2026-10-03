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
  final DateTime? createdAt;
  final DateTime? approvedAt;
  final String? notes;

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
    this.createdAt,
    this.approvedAt,
    this.notes,
  });

  /// Resolves the actual slot start time combining the date from slotTime
  /// and the first slot start time from period (e.g. "Evening|09:00 PM").
  DateTime get actualSlotStartTime {
    if (period != null && period!.contains('|')) {
      final parts = period!.split('|');
      if (parts.length > 1) {
        final times = parts[1]
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
        if (times.isNotEmpty) {
          String firstTime = times.first;
          if (firstTime.contains('-')) {
            firstTime = firstTime.split('-').first.trim();
          }
          final timeParts = firstTime.split(':');
          if (timeParts.length >= 2) {
            int h = int.tryParse(timeParts[0]) ?? 0;
            final mPart = timeParts[1].trim().split(' ');
            final m = int.tryParse(mPart[0]) ?? 0;
            final amPm = mPart.length > 1 ? mPart[1].toUpperCase() : '';
            if (amPm == 'PM' && h != 12) h += 12;
            if (amPm == 'AM' && h == 12) h = 0;
            return DateTime(slotTime.year, slotTime.month, slotTime.day, h, m);
          }
        }
      }
    }
    return slotTime;
  }

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
      createdAt: _parseUtcToLocal(json['created_at']),
      approvedAt: _parseUtcToLocal(json['approved_at']),
      notes: json['notes'],
    );
  }

  static DateTime? _parseUtcToLocal(dynamic value) {
    if (value == null) return null;
    String s = value.toString().trim();
    if (s.isEmpty) return null;
    if (s.contains(' ') && !s.contains('T')) {
      s = s.replaceFirst(' ', 'T');
    }
    if (!s.endsWith('Z') && !s.contains('+') && !RegExp(r'-\d{2}:?\d{2}$').hasMatch(s)) {
      s = '${s}Z';
    }
    try {
      return DateTime.parse(s).toLocal();
    } catch (_) {
      return DateTime.tryParse(value.toString())?.toLocal();
    }
  }
}
