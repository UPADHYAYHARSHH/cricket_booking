import 'package:turfpro/user_booking/data/models/ground_model.dart';
import 'package:turfpro/user_booking/domain/models/slot_models.dart';
import 'package:flutter/foundation.dart';
import 'package:turfpro/user_booking/domain/repositories/slot_repository.dart';
import 'package:turfpro/user_booking/domain/repositories/ground_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'dart:async';

import 'package:turfpro/user_booking/domain/repositories/loyalty_repository.dart';
import 'package:turfpro/user_booking/domain/repositories/wallet_repository.dart';
import 'package:turfpro/common/config/feature_config.dart';
import 'slot_selection_state.dart';

class SlotSelectionCubit extends Cubit<SlotSelectionState> {
  final SlotRepository repository;
  final LoyaltyRepository loyaltyRepository;
  final GroundRepository groundRepository;
  final WalletRepository walletRepository;
  StreamSubscription<List<TimeSlot>>? _slotsSubscription;

  SlotSelectionCubit(this.repository, this.loyaltyRepository, this.groundRepository, this.walletRepository)
      : super(
          SlotSelectionState(
            dates: _generateDates(),
            slots: [],
            isLoading: false,
          ),
        ) {
    if (FeatureConfig.isLoyaltyEnabled) {
      loadLoyaltyPoints();
    }
    if (FeatureConfig.isWalletEnabled) {
      loadWalletBalance();
    }
  }

  Future<void> loadWalletBalance() async {
    try {
      final balance = await walletRepository.getBalance();
      emit(state.copyWith(walletBalance: balance));
    } catch (e) {
      debugPrint("Error loading wallet balance: $e");
    }
  }

  void toggleWallet() {
    emit(state.copyWith(useWallet: !state.useWallet));
  }

  Future<void> loadLoyaltyPoints() async {
    final points = await loyaltyRepository.fetchTotalAvailablePoints();
    emit(state.copyWith(availableLoyaltyPoints: points));
  }

  void toggleLoyaltyPoints() {
    if (FeatureConfig.isLoyaltyEnabled) {
      emit(state.copyWith(useLoyaltyPoints: !state.useLoyaltyPoints));
    }
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

  Future<void> initFacility(GroundModel initialGround) async {
    emit(state.copyWith(isLoading: true, selectedTurf: initialGround));

    try {
      final grounds = await groundRepository.fetchGrounds();
      
      // Group grounds by ownerId and address to find turfs of the same facility
      final facilityGrounds = grounds.where((g) {
        return g.ownerId == initialGround.ownerId && g.address == initialGround.address;
      }).toList();

      if (facilityGrounds.isEmpty) {
        // Fallback if no other grounds found (e.g. current ground only)
        final sports = List<String>.from(initialGround.categories);
        emit(state.copyWith(
          facilityGrounds: [initialGround],
          availableSports: sports,
          isLoading: false,
        ));
        return;
      }

      // Extract unique sports from all grounds in this facility
      final sportsSet = <String>{};
      for (var g in facilityGrounds) {
        for (var cat in g.categories) {
          sportsSet.add(cat);
        }
      }

      final sportsList = sportsSet.toList();
      
      emit(state.copyWith(
        facilityGrounds: facilityGrounds,
        availableSports: sportsList,
        isLoading: false,
      ));

      if (sportsList.isNotEmpty) {
        final firstSport = sportsList.first;
        selectSport(firstSport);
        
        // Find turfs for this first sport and auto-select the first one
        final firstSportTurfs = facilityGrounds.where((g) => g.categories.contains(firstSport)).toList();
        if (firstSportTurfs.isNotEmpty) {
          selectTurf(firstSportTurfs.first);
        }
      }
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: "Error loading facility data: $e"));
    }
  }

  void selectSport(String sport) {
    final turfs = state.facilityGrounds.where((g) {
      return g.categories.contains(sport);
    }).toList();

    emit(state.copyWith(
      selectedSport: sport,
      availableTurfs: turfs,
      clearSelectedTurf: true,
    ));

    // Auto-select if only one turf exists for this sport
    if (turfs.length == 1) {
      selectTurf(turfs.first);
    }
  }

  void clearSelections() {
    final updatedSlots = state.slots.map((slot) {
      if (slot.status == SlotStatus.selected) {
        return slot.copyWith(status: SlotStatus.available);
      }
      return slot;
    }).toList();
    emit(state.copyWith(slots: updatedSlots));
  }

  void selectTurf(GroundModel turf) {
    emit(state.copyWith(selectedTurf: turf));
    loadSlots(
      turf.id,
      state.selectedDate ?? DateTime.now(),
      openingTime: turf.openingTime,
      closingTime: turf.closingTime,
      pricePerSlot: turf.pricePerHour.toDouble(),
    );
  }

  void goBackToSportSelection() {
    emit(state.copyWith(
      clearSelectedSport: true,
      clearSelectedTurf: true,
      slots: [],
    ));
  }

  void goBackToTurfSelection() {
    emit(state.copyWith(
      clearSelectedTurf: true,
      slots: [],
    ));
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

    // Start listening to real-time updates with robust error handling
    _slotsSubscription = repository.getSlotsStream(groundId, date).listen(
      (dbSlots) {
        _processAndEmitSlots(dbSlots, openingTime, closingTime, pricePerSlot);
      },
      onError: (error) async {
        debugPrint('Realtime stream error: $error. Attempting fallback fetch...');
        
        // If it's a network error, give it a moment before fallback
        if (error.toString().contains('ClientException') || 
            error.toString().contains('Failed to fetch')) {
          await Future.delayed(const Duration(milliseconds: 500));
        }

        try {
          final dbSlots = await repository.fetchSlotsForGround(groundId, date);
          _processAndEmitSlots(dbSlots, openingTime, closingTime, pricePerSlot);
        } catch (e) {
          debugPrint('Fallback fetch also failed: $e');
          // Only emit error if we don't have slots yet or it's a critical failure
          if (state.slots.isEmpty || e.toString().contains('ClientException')) {
            emit(state.copyWith(
              isLoading: false, 
              errorMessage: _getUserFriendlyError(e.toString()),
            ));
          }
        }
      },
    );
  }

  String _getUserFriendlyError(String error) {
    if (error.contains('ClientException') || error.contains('Failed to fetch')) {
      return "Unable to connect to the server. Please check your internet connection and try again.";
    }
    return error;
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
      debugPrint("Error generating slots: $e");
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

    slots[index] = slot.copyWith(
      status: slot.status == SlotStatus.selected
          ? SlotStatus.available
          : SlotStatus.selected,
    );

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
