import 'package:turfpro/user_booking/domain/models/slot_models.dart';

class SlotSelectionState {
  final List<DateItem> dates;
  final List<TimeSlot> slots;
  final bool isLoading;
  final String? errorMessage;
  final DateTime? selectedDate;
  final String selectedPeriod;
  final String? groundId;
  final int availableLoyaltyPoints;
  final bool useLoyaltyPoints;

  SlotSelectionState({
    required this.dates,
    required this.slots,
    this.isLoading = false,
    this.errorMessage,
    this.selectedDate,
    this.selectedPeriod = 'Morning',
    this.groundId,
    this.availableLoyaltyPoints = 0,
    this.useLoyaltyPoints = false,
  });

  SlotSelectionState copyWith({
    List<DateItem>? dates,
    List<TimeSlot>? slots,
    bool? isLoading,
    String? errorMessage,
    DateTime? selectedDate,
    String? selectedPeriod,
    String? groundId,
    int? availableLoyaltyPoints,
    bool? useLoyaltyPoints,
  }) {
    return SlotSelectionState(
      dates: dates ?? this.dates,
      slots: slots ?? this.slots,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      groundId: groundId ?? this.groundId,
      availableLoyaltyPoints: availableLoyaltyPoints ?? this.availableLoyaltyPoints,
      useLoyaltyPoints: useLoyaltyPoints ?? this.useLoyaltyPoints,
    );
  }
}
