import 'package:turfpro/user_booking/data/models/ground_model.dart';
import 'package:turfpro/user_booking/domain/models/slot_models.dart';

class BookingSuccessArguments {
  final GroundModel ground;
  final DateTime date;
  final List<TimeSlot> selectedSlots;
  final String orderId;
  final int displayId;
  final double totalPrice;

  final String sportName;

  BookingSuccessArguments({
    required this.ground,
    required this.date,
    required this.selectedSlots,
    required this.orderId,
    required this.displayId,
    required this.totalPrice,
    required this.sportName,
  });
}

class BookingFailureArguments {
  final String errorMessage;
  final VoidCallback? onRetry;
  final String? groundId;

  BookingFailureArguments({
    required this.errorMessage,
    this.onRetry,
    this.groundId,
  });
}

typedef VoidCallback = void Function();
