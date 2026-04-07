// lib/user_booking/domain/models/slot_models.dart

enum SlotStatus { available, booked, selected, blocked, advance }

class DateItem {
  final String day;
  final int date;
  final String month;
  bool isSelected;

  DateItem({
    required this.day,
    required this.date,
    required this.month,
    this.isSelected = false,
  });
}

class TimeSlot {
  final String startTime;
  final String endTime;
  final double price;
  SlotStatus status;

  TimeSlot({
    required this.startTime,
    required this.endTime,
    required this.price,
    this.status = SlotStatus.available,
  });
}
