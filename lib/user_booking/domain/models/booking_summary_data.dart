import 'dart:convert';
import '../../data/models/booking_model.dart';

class BookingSummaryData {
  final double slotPrice;
  final double gstAmount;
  final double platformFee;
  final bool isPlatformFeeFree;
  final double pointsDiscount;
  final double walletDiscount;
  final double grandTotal;

  const BookingSummaryData({
    required this.slotPrice,
    required this.gstAmount,
    required this.platformFee,
    this.isPlatformFeeFree = false,
    this.pointsDiscount = 0.0,
    this.walletDiscount = 0.0,
    required this.grandTotal,
  });

  double get totalSavings =>
      pointsDiscount +
      walletDiscount +
      (isPlatformFeeFree ? platformFee : 0.0);

  Map<String, dynamic> toJson() => {
        'slot_price': slotPrice,
        'gst_amount': gstAmount,
        'platform_fee': platformFee,
        'is_platform_fee_free': isPlatformFeeFree,
        'points_discount': pointsDiscount,
        'wallet_discount': walletDiscount,
        'grand_total': grandTotal,
      };

  factory BookingSummaryData.fromJson(Map<String, dynamic> json) {
    return BookingSummaryData(
      slotPrice: (json['slot_price'] as num?)?.toDouble() ??
          (json['slotPrice'] as num?)?.toDouble() ??
          0.0,
      gstAmount: (json['gst_amount'] as num?)?.toDouble() ??
          (json['gstAmount'] as num?)?.toDouble() ??
          0.0,
      platformFee: (json['platform_fee'] as num?)?.toDouble() ??
          (json['platformFee'] as num?)?.toDouble() ??
          0.0,
      isPlatformFeeFree: json['is_platform_fee_free'] == true ||
          json['isPlatformFeeFree'] == true,
      pointsDiscount: (json['points_discount'] as num?)?.toDouble() ??
          (json['pointsDiscount'] as num?)?.toDouble() ??
          0.0,
      walletDiscount: (json['wallet_discount'] as num?)?.toDouble() ??
          (json['walletDiscount'] as num?)?.toDouble() ??
          0.0,
      grandTotal: (json['grand_total'] as num?)?.toDouble() ??
          (json['grandTotal'] as num?)?.toDouble() ??
          0.0,
    );
  }

  factory BookingSummaryData.fromBookingModel(BookingModel booking) {
    // 1. Check if serialized summary exists in notes
    if (booking.notes != null && booking.notes!.trim().startsWith('{')) {
      try {
        final decoded = jsonDecode(booking.notes!);
        if (decoded is Map<String, dynamic>) {
          if (decoded.containsKey('slot_price') ||
              decoded.containsKey('slotPrice') ||
              decoded.containsKey('grand_total') ||
              decoded.containsKey('grandTotal')) {
            return BookingSummaryData.fromJson(decoded);
          }
        }
      } catch (_) {}
    }

    // 2. Fallback for legacy bookings
    final double slotPrice = booking.baseAmount > 0
        ? booking.baseAmount
        : (booking.amount - booking.platformFee).clamp(0.0, booking.amount);
    final double fee = booking.platformFee;
    final double calculatedGst =
        (booking.amount - (slotPrice + fee)).clamp(0.0, booking.amount);

    return BookingSummaryData(
      slotPrice: slotPrice,
      gstAmount: calculatedGst,
      platformFee: fee,
      isPlatformFeeFree: fee == 0.0,
      pointsDiscount: 0.0,
      walletDiscount: 0.0,
      grandTotal: booking.amount,
    );
  }
}
