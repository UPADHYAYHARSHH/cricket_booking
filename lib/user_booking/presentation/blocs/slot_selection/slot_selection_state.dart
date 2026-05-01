import 'package:turfpro/user_booking/data/models/ground_model.dart';
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
  final List<GroundModel> facilityGrounds;
  final List<String> availableSports;
  final List<GroundModel> availableTurfs;
  final String? selectedSport;
  final GroundModel? selectedTurf;

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
    this.facilityGrounds = const [],
    this.availableSports = const [],
    this.availableTurfs = const [],
    this.selectedSport,
    this.selectedTurf,
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
    List<GroundModel>? facilityGrounds,
    List<String>? availableSports,
    List<GroundModel>? availableTurfs,
    String? selectedSport,
    bool? clearSelectedSport,
    GroundModel? selectedTurf,
    bool? clearSelectedTurf,
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
      facilityGrounds: facilityGrounds ?? this.facilityGrounds,
      availableSports: availableSports ?? this.availableSports,
      availableTurfs: availableTurfs ?? this.availableTurfs,
      selectedSport: clearSelectedSport == true ? null : (selectedSport ?? this.selectedSport),
      selectedTurf: clearSelectedTurf == true ? null : (selectedTurf ?? this.selectedTurf),
    );
  }
}
