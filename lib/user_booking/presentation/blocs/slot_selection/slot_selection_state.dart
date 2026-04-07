import 'package:bloc_structure/user_booking/domain/models/slot_models.dart';

import 'package:bloc_structure/user_booking/domain/models/slot_models.dart';

class SlotSelectionState {
  final List<DateItem> dates;
  final List<TimeSlot> slots;
  final bool isLoading;
  final String? errorMessage;
  final DateTime? selectedDate;
  final String selectedPeriod;
  final String? groundId;

  SlotSelectionState({
    required this.dates,
    required this.slots,
    this.isLoading = false,
    this.errorMessage,
    this.selectedDate,
    this.selectedPeriod = 'Morning',
    this.groundId,
  });

  SlotSelectionState copyWith({
    List<DateItem>? dates,
    List<TimeSlot>? slots,
    bool? isLoading,
    String? errorMessage,
    DateTime? selectedDate,
    String? selectedPeriod,
    String? groundId,
  }) {
    return SlotSelectionState(
      dates: dates ?? this.dates,
      slots: slots ?? this.slots,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      groundId: groundId ?? this.groundId,
    );
  }
}
