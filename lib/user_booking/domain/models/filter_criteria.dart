import 'package:flutter/material.dart';

enum SortBy { priceLowToHigh, priceHighToLow, none }

class FilterCriteria {
  final SortBy sortBy;
  final double minPrice;
  final double maxPrice;
  final List<String> selectedAmenities;
  final bool isAvailableNow;
  final bool isNearMe;
  final bool isTopRated;
  final String? sportId;

  // Future Slot Availability
  final bool isSlotFilterActive;
  final DateTime? slotDate;
  final TimeOfDay? slotStartTime;
  final TimeOfDay? slotEndTime;
  final Set<String> unavailableGroundIds;

  FilterCriteria({
    this.sortBy = SortBy.none,
    this.minPrice = 0,
    this.maxPrice = 5000,
    this.selectedAmenities = const [],
    this.isAvailableNow = false,
    this.isNearMe = false,
    this.isTopRated = false,
    this.sportId = 'all',
    this.isSlotFilterActive = false,
    this.slotDate,
    this.slotStartTime,
    this.slotEndTime,
    this.unavailableGroundIds = const {},
  });

  FilterCriteria copyWith({
    SortBy? sortBy,
    double? minPrice,
    double? maxPrice,
    List<String>? selectedAmenities,
    bool? isAvailableNow,
    bool? isNearMe,
    bool? isTopRated,
    String? sportId,
    bool? isSlotFilterActive,
    DateTime? slotDate,
    TimeOfDay? slotStartTime,
    TimeOfDay? slotEndTime,
    Set<String>? unavailableGroundIds,
    bool clearSlotFilter = false,
  }) {
    return FilterCriteria(
      sortBy: sortBy ?? this.sortBy,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      selectedAmenities: selectedAmenities ?? this.selectedAmenities,
      isAvailableNow: isAvailableNow ?? this.isAvailableNow,
      isNearMe: isNearMe ?? this.isNearMe,
      isTopRated: isTopRated ?? this.isTopRated,
      sportId: sportId ?? this.sportId,
      isSlotFilterActive: clearSlotFilter ? false : (isSlotFilterActive ?? this.isSlotFilterActive),
      slotDate: clearSlotFilter ? null : (slotDate ?? this.slotDate),
      slotStartTime: clearSlotFilter ? null : (slotStartTime ?? this.slotStartTime),
      slotEndTime: clearSlotFilter ? null : (slotEndTime ?? this.slotEndTime),
      unavailableGroundIds: clearSlotFilter ? const {} : (unavailableGroundIds ?? this.unavailableGroundIds),
    );
  }

  bool get isDefault =>
      sortBy == SortBy.none &&
      minPrice == 0 &&
      maxPrice == 5000 &&
      selectedAmenities.isEmpty &&
      !isAvailableNow &&
      !isNearMe &&
      !isTopRated &&
      (sportId == null || sportId == 'all') &&
      !isSlotFilterActive;
}
