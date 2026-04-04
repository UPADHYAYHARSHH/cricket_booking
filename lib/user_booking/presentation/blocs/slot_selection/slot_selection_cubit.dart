import 'package:bloc_structure/user_booking/domain/models/slot_models.dart';
import 'package:bloc_structure/user_booking/domain/repositories/slot_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'slot_selection_state.dart';

class SlotSelectionCubit extends Cubit<SlotSelectionState> {
  final SlotRepository repository;

  SlotSelectionCubit(this.repository)
      : super(
          SlotSelectionState(
            dates: _generateDates(),
            slots: [],
            isLoading: false,
          ),
        );

  static List<DateItem> _generateDates() {
    final now = DateTime.now();
    return List.generate(7, (i) {
      final date = now.add(Duration(days: i));
      return DateItem(
        day: DateFormat('EEE').format(date).toUpperCase(),
        date: date.day,
        month: DateFormat('MMM').format(date).toUpperCase(),
        isSelected: i == 0,
      );
    });
  }

  Future<void> loadSlots(String groundId, DateTime date, {String? openingTime, String? closingTime, double pricePerSlot = 0}) async {
    emit(state.copyWith(isLoading: true, errorMessage: null, groundId: groundId, selectedDate: date));

    try {
      var slots = await repository.fetchSlotsForGround(groundId, date);

      if (slots.isEmpty && openingTime != null && closingTime != null) {
        // Generate slots if none found
        slots = _generateSlots(openingTime, closingTime, pricePerSlot);
      }

      emit(state.copyWith(slots: slots, isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  List<TimeSlot> _generateSlots(String open, String close, double price) {
    List<TimeSlot> generated = [];
    try {
      final openHour = int.parse(open.split(':')[0]);
      var closeHour = int.parse(close.split(':')[0]);

      if (closeHour <= openHour) {
        closeHour += 24; // Handle overnight
      }

      for (int h = openHour; h < closeHour; h++) {
        final startH = h % 24;
        final endH = (h + 1) % 24;

        final startStr = _formatHour(startH);
        final endStr = _formatHour(endH);

        generated.add(TimeSlot(
          startTime: startStr,
          endTime: endStr,
          price: price,
          status: SlotStatus.available,
        ));
      }
    } catch (e) {
      print("Error generating slots: $e");
    }
    return generated;
  }

  String _formatHour(int h) {
    final hour = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    final amPm = h >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:00 $amPm';
  }

  void selectDate(int index, String groundId, {String? openingTime, String? closingTime, double pricePerSlot = 0}) {
    final dates = List<DateItem>.from(state.dates);
    for (var d in dates) {
      d.isSelected = false;
    }
    dates[index].isSelected = true;

    final selectedDate = DateTime.now().add(Duration(days: index));
    emit(state.copyWith(dates: dates));
    
    loadSlots(groundId, selectedDate, openingTime: openingTime, closingTime: closingTime, pricePerSlot: pricePerSlot);
  }

  void toggleSlot(int index) {
    final slots = List<TimeSlot>.from(state.slots);
    final slot = slots[index];

    if (slot.status == SlotStatus.booked || slot.status == SlotStatus.blocked) {
      return;
    }

    slot.status = slot.status == SlotStatus.selected
        ? SlotStatus.available
        : SlotStatus.selected;

    emit(state.copyWith(slots: slots));
  }
}
