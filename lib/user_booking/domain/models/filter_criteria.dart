enum SortBy { priceLowToHigh, priceHighToLow, none }

class FilterCriteria {
  final SortBy sortBy;
  final double minPrice;
  final double maxPrice;
  final List<String> selectedAmenities;
  final bool isAvailableNow;
  final bool isNearMe;
  final bool isTopRated;

  FilterCriteria({
    this.sortBy = SortBy.none,
    this.minPrice = 0,
    this.maxPrice = 5000,
    this.selectedAmenities = const [],
    this.isAvailableNow = false,
    this.isNearMe = false,
    this.isTopRated = false,
  });

  FilterCriteria copyWith({
    SortBy? sortBy,
    double? minPrice,
    double? maxPrice,
    List<String>? selectedAmenities,
    bool? isAvailableNow,
    bool? isNearMe,
    bool? isTopRated,
  }) {
    return FilterCriteria(
      sortBy: sortBy ?? this.sortBy,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      selectedAmenities: selectedAmenities ?? this.selectedAmenities,
      isAvailableNow: isAvailableNow ?? this.isAvailableNow,
      isNearMe: isNearMe ?? this.isNearMe,
      isTopRated: isTopRated ?? this.isTopRated,
    );
  }

  bool get isDefault =>
      sortBy == SortBy.none &&
      minPrice == 0 &&
      maxPrice == 5000 &&
      selectedAmenities.isEmpty &&
      !isAvailableNow &&
      !isNearMe &&
      !isTopRated;
}
