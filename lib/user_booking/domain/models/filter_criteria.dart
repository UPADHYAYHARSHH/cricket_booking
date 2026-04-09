enum SortBy { nearMe, topRated, priceLowToHigh, priceHighToLow }

class FilterCriteria {
  final SortBy sortBy;
  final double minPrice;
  final double maxPrice;
  final List<String> selectedAmenities;

  FilterCriteria({
    this.sortBy = SortBy.nearMe,
    this.minPrice = 0,
    this.maxPrice = 5000,
    this.selectedAmenities = const [],
  });

  FilterCriteria copyWith({
    SortBy? sortBy,
    double? minPrice,
    double? maxPrice,
    List<String>? selectedAmenities,
  }) {
    return FilterCriteria(
      sortBy: sortBy ?? this.sortBy,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      selectedAmenities: selectedAmenities ?? this.selectedAmenities,
    );
  }

  bool get isDefault =>
      sortBy == SortBy.nearMe &&
      minPrice == 0 &&
      maxPrice == 5000 &&
      selectedAmenities.isEmpty;
}
