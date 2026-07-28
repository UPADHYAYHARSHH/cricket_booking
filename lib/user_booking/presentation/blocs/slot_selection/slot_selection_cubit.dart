import 'package:turfpro/user_booking/data/models/ground_model.dart';
import 'package:turfpro/user_booking/data/models/location_model.dart';
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
            selectedDate: DateTime.now(),
            selectedPeriod: _getCurrentPeriod(),
          ),
        ) {
    if (FeatureConfig.isLoyaltyEnabled) {
      loadLoyaltyPoints();
    }
    if (FeatureConfig.isWalletEnabled) {
      loadWalletBalance();
    }
  }

  static String _getCurrentPeriod() {
    final hour = DateTime.now().hour;
    if (hour < 6) return 'Midnight';
    if (hour < 12) return 'Day';
    if (hour < 18) return 'Evening';
    return 'Night';
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

  static List<DateItem> _generateDates([GroundModel? turf]) {
    final now = DateTime.now();
    final ops = (turf?.operatingDays != null && turf!.operatingDays.isNotEmpty) 
        ? turf.operatingDays 
        : [1, 2, 3, 4, 5, 6, 7];
        
    debugPrint("[SLOT_CUBIT] Generating dates for turf: ${turf?.name}");
    debugPrint("[SLOT_CUBIT] Turf operating days: $ops");
        
    final dates = <DateItem>[];
    int added = 0;
    int offset = 0;
    
    while (added < 7 && offset < 30) {
      final date = now.add(Duration(days: offset));
      if (ops.contains(date.weekday)) {
        dates.add(DateItem(
          day: DateFormat('EEE').format(date).toUpperCase(),
          date: date.day,
          month: DateFormat('MMM').format(date).toUpperCase(),
          fullDate: date,
          isSelected: added == 0,
        ));
        added++;
      }
      offset++;
    }
    
    if (dates.isEmpty) {
      dates.add(DateItem(
        day: DateFormat('EEE').format(now).toUpperCase(),
        date: now.day,
        month: DateFormat('MMM').format(now).toUpperCase(),
        fullDate: now,
        isSelected: true,
      ));
    }
    
    return dates;
  }

  Future<void> initFacility(GroundModel initialGround) async {
    final todayDates = _generateDates(initialGround);
    emit(state.copyWith(
      isLoading: true,
      selectedTurf: initialGround,
      selectedDate: todayDates.first.fullDate,
      dates: todayDates,
      errorMessage: null,
    ));

    try {
      final grounds = await groundRepository.fetchGrounds();
      
      // Group grounds by ownerId and address to find turfs of the same facility
      final facilityGrounds = grounds.where((g) {
        return g.ownerId == initialGround.ownerId && g.address == initialGround.address;
      }).toList();

      // Ensure the initial ground is present in facility grounds
      if (facilityGrounds.isEmpty || !facilityGrounds.any((g) => g.id == initialGround.id)) {
        facilityGrounds.add(initialGround);
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

      // Choose preferred sport based on the initial ground's category
      String? preferredSport;
      if (initialGround.categories.isNotEmpty && sportsList.contains(initialGround.categories.first)) {
        preferredSport = initialGround.categories.first;
      } else if (sportsList.isNotEmpty) {
        preferredSport = sportsList.first;
      }

      if (preferredSport != null) {
        selectSport(preferredSport);
      }

      // Explicitly select the initial ground and load slots
      selectTurf(initialGround);
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: "Error loading facility data: $e",
      ));
    }
  }

  Future<void> initForLocation(LocationModel location) async {
    final todayDates = _generateDates();
    emit(state.copyWith(
      isLoading: true,
      selectedTurf: null,
      selectedDate: DateTime.now(),
      dates: todayDates,
      errorMessage: null,
      availableSports: const [],
      availableTurfs: const [],
    ));

    try {
      debugPrint("[SLOT_CUBIT] Fetching grounds for location: ${location.city}");
      // Revert to fetchGrounds since grounds table uses city instead of location_id
      final grounds = await groundRepository.fetchGrounds();
      
      final cityName = location.city.split(',').first.trim().toLowerCase();
      
      final locationGrounds = grounds.where((g) {
        return g.city.toLowerCase().contains(cityName) || cityName.contains(g.city.toLowerCase());
      }).toList();
      
      debugPrint("[SLOT_CUBIT] Found ${locationGrounds.length} grounds for this location.");

      // Extract unique sports from all grounds in this location
      final sportsSet = <String>{};
      for (var g in locationGrounds) {
        debugPrint("[SLOT_CUBIT] Ground ${g.name} has categories: ${g.categories}");
        for (var cat in g.categories) {
          sportsSet.add(cat);
        }
      }

      final sportsList = sportsSet.toList();
      debugPrint("[SLOT_CUBIT] Unique sports found: $sportsList");
      
      emit(state.copyWith(
        facilityGrounds: locationGrounds, // Using facilityGrounds to store location grounds for now
        availableSports: sportsList,
        isLoading: false,
      ));

      if (sportsList.isNotEmpty) {
        selectSport(sportsList.first);
      }
    } catch (e, st) {
      debugPrint("[SLOT_CUBIT] ERROR in initForLocation: $e\n$st");
      emit(state.copyWith(
        isLoading: false,
        errorMessage: "Error loading location data: $e",
      ));
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
    final dates = _generateDates(turf);
    final selectedDate = dates.first.fullDate;
    
    emit(state.copyWith(
      selectedTurf: turf,
      dates: dates,
      selectedDate: selectedDate,
    ));
    loadSlots(
      turf.id,
      selectedDate,
      openingTime: turf.openingTime,
      closingTime: turf.closingTime,
      pricePerSlot: _getPriceForDate(turf, selectedDate),
      slotDuration: turf.slotDuration,
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
      {String? openingTime, String? closingTime, double pricePerSlot = 0, String? slotDuration}) async {
    emit(state.copyWith(
        isLoading: true,
        errorMessage: null,
        groundId: groundId,
        selectedDate: date));

    // Cancel existing subscription if any
    await _slotsSubscription?.cancel();

    // 1. Eagerly fetch and emit slots via direct HTTP first to guarantee instant snapshot display
    try {
      final initialDbSlots = await repository.fetchSlotsForGround(groundId, date);
      _processAndEmitSlots(initialDbSlots, openingTime, closingTime, pricePerSlot, slotDuration);
    } catch (e) {
      debugPrint('[SLOT_CUBIT] Eager slot fetch failed: $e');
    }

    // 2. Start listening to real-time updates with robust error handling
    _slotsSubscription = repository.getSlotsStream(groundId, date).listen(
      (dbSlots) {
        _processAndEmitSlots(dbSlots, openingTime, closingTime, pricePerSlot, slotDuration);
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
          _processAndEmitSlots(dbSlots, openingTime, closingTime, pricePerSlot, slotDuration);
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

  void _processAndEmitSlots(List<TimeSlot> dbSlots, String? openingTime, String? closingTime, double pricePerSlot, String? slotDuration) {
    List<TimeSlot> mergedSlots = [];

    if (openingTime != null && closingTime != null) {
      // 1. Generate all possible slots for the day
      mergedSlots = _generateSlots(openingTime, closingTime, pricePerSlot, slotDuration);

      // 2. Overlay booked slots from DB
      for (var dbSlot in dbSlots) {
        final index = mergedSlots
            .indexWhere((s) => s.startTime == dbSlot.startTime);
        if (index != -1) {
          mergedSlots[index] = mergedSlots[index].copyWith(
            status: dbSlot.status,
            price: dbSlot.price > 0 ? dbSlot.price : null,
          );
        } else {
          mergedSlots.add(dbSlot); // Fallback
        }
      }

      // 3. Sort merged slots by time
      mergedSlots.sort((a, b) => _timeToMinutes(a.startTime).compareTo(_timeToMinutes(b.startTime)));
    } else {
      mergedSlots = dbSlots;
    }

    // Set errorMessage to null when successfully emitting slots to clear any previous errors
    emit(state.copyWith(slots: mergedSlots, isLoading: false, errorMessage: null));
  }

  int _timeToMinutes(String time) {
    try {
      final parts = time.split(' ');
      if (parts.length != 2) return 0;
      final timeParts = parts[0].split(':');
      int hours = int.parse(timeParts[0]);
      int minutes = timeParts.length > 1 ? int.parse(timeParts[1]) : 0;
      final amPm = parts[1].toUpperCase();

      if (amPm == 'PM' && hours != 12) {
        hours += 12;
      } else if (amPm == 'AM' && hours == 12) {
        hours = 0;
      }
      return hours * 60 + minutes;
    } catch (e) {
      return 0;
    }
  }

  int _parseSlotDuration(dynamic raw) {
    try {
      if (raw == null) return 60;
      if (raw is int) return raw;
      if (raw is num) return raw.toInt();
      if (raw is String) {
        final s = raw.trim().toLowerCase();
        final numStr = RegExp(r'[0-9]+(?:\.[0-9]+)?').firstMatch(s)?.group(0);
        if (numStr == null) return 60;
        final value = double.tryParse(numStr) ?? 0.0;
        if (s.contains('hour')) {
          return (value * 60).round();
        } else if (s.contains('min')) {
          return value.round();
        } else {
          return value.round();
        }
      }
      return 60;
    } catch (e) {
      return 60;
    }
  }

  List<TimeSlot> _generateSlots(String open, String close, double price, String? slotDurationStr) {
    List<TimeSlot> generated = [];
    final now = DateTime.now();
    final isToday = state.selectedDate != null &&
        state.selectedDate!.year == now.year &&
        state.selectedDate!.month == now.month &&
        state.selectedDate!.day == now.day;

    try {
      final openParts = open.split(':');
      final closeParts = close.split(':');
      
      final slotDurationMins = _parseSlotDuration(slotDurationStr);

      final selectedDate = state.selectedDate ?? now;
      
      final slotStart = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        int.parse(openParts[0]),
        int.parse(openParts[1]),
      );
      
      var slotEnd = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        int.parse(closeParts[0]),
        int.parse(closeParts[1]),
      );
      
      if (slotEnd.isBefore(slotStart) || slotEnd.isAtSameMomentAs(slotStart)) {
        slotEnd = slotEnd.add(const Duration(days: 1));
      }

      var currentSlotTime = slotStart;
      
      while (currentSlotTime.isBefore(slotEnd)) {
        final nextSlotTime = currentSlotTime.add(Duration(minutes: slotDurationMins));
        if (nextSlotTime.isAfter(slotEnd)) break;
        
        final startStr = _formatTime(currentSlotTime);
        final endStr = _formatTime(nextSlotTime);

        // Determine if slot has already passed
        bool isPast = false;
        if (isToday) {
          if (currentSlotTime.isBefore(now)) {
            isPast = true;
          }
        }

        generated.add(TimeSlot(
          startTime: startStr,
          endTime: endStr,
          price: price,
          status: isPast ? SlotStatus.booked : SlotStatus.available,
        ));
        
        currentSlotTime = nextSlotTime;
      }
    } catch (e) {
      debugPrint("Error generating slots: $e");
    }
    return generated;
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final amPm = time.hour >= 12 ? 'PM' : 'AM';
    final minStr = time.minute > 0 ? ':${time.minute.toString().padLeft(2, '0')}' : ':00';
    return '$hour$minStr $amPm';
  }

  void selectDate(int index, String groundId, {String? openingTime, String? closingTime, double pricePerSlot = 0, String? slotDuration}) {
    final dates = List<DateItem>.from(state.dates);
    for (var d in dates) {
      d.isSelected = false;
    }
    dates[index].isSelected = true;

    final selectedDate = dates[index].fullDate;
    emit(state.copyWith(dates: dates));

    // Calculate price based on weekday/weekend
    final turf = state.selectedTurf;
    final effectivePrice = turf != null ? _getPriceForDate(turf, selectedDate) : pricePerSlot;
    
    loadSlots(groundId, selectedDate, openingTime: openingTime, closingTime: closingTime, pricePerSlot: effectivePrice, slotDuration: slotDuration);
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

  /// Get the correct price for a ground on a specific date (weekday vs weekend).
  static double _getPriceForDate(GroundModel ground, DateTime date) {
    final isWeekend = date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
    if (isWeekend && ground.weekendPrice > 0) {
      return ground.weekendPrice.toDouble();
    }
    return ground.pricePerHour.toDouble();
  }

  @override
  Future<void> close() {
    _slotsSubscription?.cancel();
    return super.close();
  }
}
