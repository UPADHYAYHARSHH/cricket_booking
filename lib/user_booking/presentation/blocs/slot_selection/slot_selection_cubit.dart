import 'package:turfpro/user_booking/domain/models/slot_models.dart';
import 'package:turfpro/user_booking/domain/repositories/slot_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'dart:async';

import 'package:turfpro/user_booking/domain/repositories/loyalty_repository.dart';
import 'slot_selection_state.dart';

class SlotSelectionCubit extends Cubit<SlotSelectionState> {
  final SlotRepository repository;
  final LoyaltyRepository loyaltyRepository;
  StreamSubscription<List<TimeSlot>>? _slotsSubscription;

  SlotSelectionCubit(this.repository, this.loyaltyRepository)
      : super(
          SlotSelectionState(
            dates: _generateDates(),
            slots: [],
            isLoading: false,
          ),
        ) {
    loadLoyaltyPoints();
  }

  Future<void> loadLoyaltyPoints() async {
    final points = await loyaltyRepository.fetchTotalAvailablePoints();
    emit(state.copyWith(availableLoyaltyPoints: points));
  }

  void toggleLoyaltyPoints() {
    emit(state.copyWith(useLoyaltyPoints: !state.useLoyaltyPoints));
  }

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

  Future<void> loadSlots(String groundId, DateTime date,
      {String? openingTime, String? closingTime, double pricePerSlot = 0}) async {
    emit(state.copyWith(
        isLoading: true,
        errorMessage: null,
        groundId: groundId,
        selectedDate: date));

    // Cancel existing subscription if any
    await _slotsSubscription?.cancel();

    // Start listening to real-time updates
    _slotsSubscription = repository.getSlotsStream(groundId, date).listen(
      (dbSlots) {
        _processAndEmitSlots(dbSlots, openingTime, closingTime, pricePerSlot);
      },
      onError: (error) async {
        print('Realtime stream error: $error. Falling back to static fetch...');
        try {
          final dbSlots = await repository.fetchSlotsForGround(groundId, date);
          _processAndEmitSlots(dbSlots, openingTime, closingTime, pricePerSlot);
        } catch (e) {
          emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
        }
      },
    );
  }

  void _processAndEmitSlots(List<TimeSlot> dbSlots, String? openingTime, String? closingTime, double pricePerSlot) {
    List<TimeSlot> mergedSlots = [];

    if (openingTime != null && closingTime != null) {
      // 1. Generate all possible slots for the day
      mergedSlots = _generateSlots(openingTime, closingTime, pricePerSlot);

      // 2. Overlay booked slots from DB
      for (var dbSlot in dbSlots) {
        final index = mergedSlots
            .indexWhere((s) => s.startTime == dbSlot.startTime);
        if (index != -1) {
          mergedSlots[index] = dbSlot;
        } else {
          mergedSlots.add(dbSlot); // Fallback
        }
      }

      // 3. Sort merged slots by time
      mergedSlots.sort((a, b) => a.startTime.compareTo(b.startTime));
    } else {
      mergedSlots = dbSlots;
    }

    // Set errorMessage to null when successfully emitting slots to clear any previous errors
    emit(state.copyWith(slots: mergedSlots, isLoading: false, errorMessage: null));
  }

  List<TimeSlot> _generateSlots(String open, String close, double price) {
    List<TimeSlot> generated = [];
    final now = DateTime.now();
    final isToday = state.selectedDate != null &&
        state.selectedDate!.year == now.year &&
        state.selectedDate!.month == now.month &&
        state.selectedDate!.day == now.day;

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

        // Determine if slot has already passed
        bool isPast = false;
        if (isToday) {
          // If the slot's hour is before the current hour, it's past
          if (startH < now.hour) {
            isPast = true;
          }
        }

        generated.add(TimeSlot(
          startTime: startStr,
          endTime: endStr,
          price: price,
          status: isPast ? SlotStatus.booked : SlotStatus.available,
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

  void changePeriod(String period) {
    emit(state.copyWith(selectedPeriod: period));
  }

  @override
  Future<void> close() {
    _slotsSubscription?.cancel();
    return super.close();
  }
}
