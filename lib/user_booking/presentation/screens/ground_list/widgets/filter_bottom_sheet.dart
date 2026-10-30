import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:turfpro/common/constants/colors.dart';
import 'package:turfpro/user_booking/constants/widgets/app_sizedBox.dart';
import 'package:turfpro/user_booking/constants/widgets/app_text.dart';
import 'package:turfpro/user_booking/domain/models/filter_criteria.dart';
import 'package:turfpro/user_booking/data/services/slot_availability_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:turfpro/user_booking/presentation/blocs/sport/sport_cubit.dart';
import 'package:turfpro/user_booking/presentation/blocs/sport/sport_state.dart';

class FilterBottomSheet extends StatefulWidget {
  final FilterCriteria initialCriteria;
  final Function(FilterCriteria) onApply;
  final bool showFutureSlotFilter;

  const FilterBottomSheet({
    super.key,
    required this.initialCriteria,
    required this.onApply,
    this.showFutureSlotFilter = true,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet>
    with SingleTickerProviderStateMixin {
  late SortBy _sortBy;
  late double _minPrice;
  late double _maxPrice;
  late bool _isAvailableNow;
  late bool _isNearMe;
  late bool _isTopRated;

  // Slot Availability Filter State
  late bool _isSlotFilterActive;
  late DateTime _slotDate;
  late TimeOfDay _slotStartTime;
  late TimeOfDay _slotEndTime;
  late String _selectedSport;
  bool _isLoadingAvailability = false;

  late AnimationController _animCtrl;
  late Animation<double> _fadeIn;

  int get _activeFilterCount {
    int count = 0;
    if (_sortBy != SortBy.none) count++;
    if (_minPrice > 0 || _maxPrice < 5000) count++;
    if (_isAvailableNow) count++;
    if (_isNearMe) count++;
    if (_isTopRated) count++;
    if (widget.showFutureSlotFilter) {
      if (_isSlotFilterActive) count++;
      if (_selectedSport != 'all' && !_isSlotFilterActive) count++;
    }
    return count;
  }

  String get _selectedSportName {
    if (_selectedSport == 'all' || _selectedSport.isEmpty) return 'All Sports';
    return _selectedSport[0].toUpperCase() + _selectedSport.substring(1);
  }

  @override
  void initState() {
    super.initState();
    _sortBy = widget.initialCriteria.sortBy;
    _minPrice = widget.initialCriteria.minPrice;
    _maxPrice = widget.initialCriteria.maxPrice;
    _isAvailableNow = widget.initialCriteria.isAvailableNow;
    _isNearMe = widget.initialCriteria.isNearMe;
    _isTopRated = widget.initialCriteria.isTopRated;

    // Initialize Slot Filter
    _isSlotFilterActive = widget.showFutureSlotFilter && widget.initialCriteria.isSlotFilterActive;
    _slotDate = widget.initialCriteria.slotDate ??
        DateTime.now().add(const Duration(days: 2));
    _slotStartTime = widget.initialCriteria.slotStartTime ??
        const TimeOfDay(hour: 18, minute: 0); // 6:00 PM
    _slotEndTime = widget.initialCriteria.slotEndTime ??
        const TimeOfDay(hour: 20, minute: 0); // 8:00 PM
    _selectedSport = widget.showFutureSlotFilter ? (widget.initialCriteria.sportId ?? 'all') : 'all';

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeIn = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final cardBg = isDark ? const Color(0xFF252525) : const Color(0xFFF8FAF9);
    final subtleText = isDark ? Colors.grey[500]! : Colors.grey[600]!;

    return FadeTransition(
      opacity: _fadeIn,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.90,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ─── Drag Handle ───
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: (isDark ? Colors.grey[700] : Colors.grey[300]),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // ─── Header ───
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 16, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryDarkGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const HugeIcon(
                      icon: HugeIcons.strokeRoundedFilterVertical,
                      color: AppColors.primaryDarkGreen,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AppText(
                          text: "Filters",
                          textStyle: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (_activeFilterCount > 0)
                          AppText(
                            text:
                                "$_activeFilterCount filter${_activeFilterCount > 1 ? 's' : ''} active",
                            textStyle: const TextStyle(
                              fontSize: 12,
                              color: AppColors.primaryDarkGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (_activeFilterCount > 0)
                    TextButton.icon(
                      onPressed: _resetAll,
                      icon: Icon(Icons.refresh_rounded,
                          size: 16, color: Colors.redAccent[200]),
                      label: Text(
                        "Reset",
                        style: TextStyle(
                          color: Colors.redAccent[200],
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        backgroundColor: Colors.redAccent.withOpacity(0.08),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                ],
              ),
            ),

            // ─── Scrollable Content ───
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Slot Availability (Future Check) ──
                    if (widget.showFutureSlotFilter) ...[
                      _buildSectionHeader(
                          "Slot Availability",
                          HugeIcons.strokeRoundedCalendar03,
                          isDark),
                      const AppSizedBox(height: 14),
                      _buildSlotAvailabilitySection(isDark, cardBg, subtleText),
                      const AppSizedBox(height: 28),
                    ],

                    // ── Quick Filters ──
                    _buildSectionHeader("Quick Filters",
                        HugeIcons.strokeRoundedFlash, isDark),
                    const AppSizedBox(height: 14),
                    _buildQuickFilterTile(
                      title: "Available Now",
                      subtitle: "Currently open grounds",
                      icon: HugeIcons.strokeRoundedClock01,
                      value: _isAvailableNow,
                      onChanged: (v) {
                        setState(() {
                          _isAvailableNow = v;
                          if (v) {
                            _isSlotFilterActive = false;
                          }
                        });
                      },
                      isDark: isDark,
                      cardBg: cardBg,
                    ),
                    const AppSizedBox(height: 10),
                    _buildQuickFilterTile(
                      title: "Near Me",
                      subtitle: "Within 10km radius",
                      icon: HugeIcons.strokeRoundedLocation01,
                      value: _isNearMe,
                      onChanged: (v) => setState(() => _isNearMe = v),
                      isDark: isDark,
                      cardBg: cardBg,
                    ),
                    const AppSizedBox(height: 10),
                    _buildQuickFilterTile(
                      title: "Top Rated",
                      subtitle: "4.0+ rating",
                      icon: HugeIcons.strokeRoundedStar,
                      value: _isTopRated,
                      onChanged: (v) => setState(() => _isTopRated = v),
                      isDark: isDark,
                      cardBg: cardBg,
                    ),
                    const AppSizedBox(height: 28),

                    // ── Sort By ──
                    _buildSectionHeader("Sort By",
                        HugeIcons.strokeRoundedSorting01, isDark),
                    const AppSizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF333333)
                              : const Color(0xFFEEEEEE),
                        ),
                      ),
                      child: Row(
                        children: [
                          _buildSortOption(
                            SortBy.priceLowToHigh,
                            "Price: Low → High",
                            Icons.trending_down_rounded,
                            isDark,
                          ),
                          _buildSortOption(
                            SortBy.priceHighToLow,
                            "Price: High → Low",
                            Icons.trending_up_rounded,
                            isDark,
                          ),
                        ],
                      ),
                    ),
                    const AppSizedBox(height: 28),

                    // ── Price Range ──
                    _buildSectionHeader("Price Range",
                        HugeIcons.strokeRoundedMoney01, isDark),
                    const AppSizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF333333)
                              : const Color(0xFFEEEEEE),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildPriceChip("₹${_minPrice.toInt()}", isDark),
                              Container(
                                height: 1,
                                width: 24,
                                color: subtleText.withOpacity(0.3),
                              ),
                              _buildPriceChip("₹${_maxPrice.toInt()}", isDark),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SliderTheme(
                            data: SliderThemeData(
                              trackHeight: 6,
                              activeTrackColor: AppColors.primaryDarkGreen,
                              inactiveTrackColor: AppColors.primaryDarkGreen
                                  .withOpacity(0.12),
                              thumbColor: AppColors.primaryDarkGreen,
                              overlayColor: AppColors.primaryDarkGreen
                                  .withOpacity(0.12),
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 10,
                                elevation: 3,
                                pressedElevation: 6,
                              ),
                              overlayShape: const RoundSliderOverlayShape(
                                  overlayRadius: 20),
                              rangeThumbShape: const RoundRangeSliderThumbShape(
                                enabledThumbRadius: 10,
                                elevation: 3,
                                pressedElevation: 6,
                              ),
                              rangeTrackShape:
                                  const RoundedRectRangeSliderTrackShape(),
                            ),
                            child: RangeSlider(
                              values: RangeValues(_minPrice, _maxPrice),
                              min: 0,
                              max: 5000,
                              divisions: 50,
                              onChanged: (values) {
                                setState(() {
                                  _minPrice = values.start;
                                  _maxPrice = values.end;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const AppSizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // ─── Bottom CTA ───
            Container(
              padding: EdgeInsets.fromLTRB(
                24,
                16,
                24,
                MediaQuery.of(context).padding.bottom + 16,
              ),
              decoration: BoxDecoration(
                color: bg,
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? const Color(0xFF2A2A2A)
                        : const Color(0xFFF0F0F0),
                  ),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoadingAvailability
                      ? null
                      : () async {
                          Set<String> unavailableGroundIds = {};
                          if (widget.showFutureSlotFilter && _isSlotFilterActive) {
                            setState(() => _isLoadingAvailability = true);
                            try {
                              unavailableGroundIds =
                                  await SlotAvailabilityService
                                      .getBookedGroundIds(
                                date: _slotDate,
                                startTime: _slotStartTime,
                                endTime: _slotEndTime,
                              );
                            } catch (e) {
                              debugPrint(
                                  'Error fetching slot availability: $e');
                            }
                            if (mounted) {
                              setState(() => _isLoadingAvailability = false);
                            }
                          }

                          if (!mounted) return;

                          widget.onApply(FilterCriteria(
                            sortBy: _sortBy,
                            minPrice: _minPrice,
                            maxPrice: _maxPrice,
                            isAvailableNow: _isAvailableNow,
                            isNearMe: _isNearMe,
                            isTopRated: _isTopRated,
                            sportId: widget.showFutureSlotFilter ? _selectedSport : (widget.initialCriteria.sportId ?? 'all'),
                            isSlotFilterActive: widget.showFutureSlotFilter ? _isSlotFilterActive : false,
                            slotDate: widget.showFutureSlotFilter && _isSlotFilterActive ? _slotDate : null,
                            slotStartTime:
                                widget.showFutureSlotFilter && _isSlotFilterActive ? _slotStartTime : null,
                            slotEndTime:
                                widget.showFutureSlotFilter && _isSlotFilterActive ? _slotEndTime : null,
                            unavailableGroundIds: unavailableGroundIds,
                          ));
                          Navigator.pop(context);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDarkGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoadingAvailability
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_rounded, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              _activeFilterCount > 0
                                  ? "Apply $_activeFilterCount Filter${_activeFilterCount > 1 ? 's' : ''}"
                                  : "Show All Grounds",
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── SLOT AVAILABILITY SECTION WIDGET ───
  Widget _buildSlotAvailabilitySection(
      bool isDark, Color cardBg, Color subtleText) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDayOnly =
        DateTime(_slotDate.year, _slotDate.month, _slotDate.day);
    final daysDiff = selectedDayOnly.difference(today).inDays;

    return Container(
      decoration: BoxDecoration(
        color: _isSlotFilterActive
            ? AppColors.primaryDarkGreen.withOpacity(0.04)
            : cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isSlotFilterActive
              ? AppColors.primaryDarkGreen.withOpacity(0.35)
              : (isDark ? const Color(0xFF333333) : const Color(0xFFEEEEEE)),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Toggle Header
          InkWell(
            onTap: () {
              setState(() {
                _isSlotFilterActive = !_isSlotFilterActive;
                if (_isSlotFilterActive) {
                  _isAvailableNow = false; // mutually exclusive
                }
              });
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _isSlotFilterActive
                          ? AppColors.primaryDarkGreen.withOpacity(0.15)
                          : (isDark
                              ? const Color(0xFF2A2A2A)
                              : const Color(0xFFF0F0F0)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedCalendar03,
                      color: _isSlotFilterActive
                          ? AppColors.primaryDarkGreen
                          : (isDark ? Colors.grey[500]! : Colors.grey[600]!),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Check Future Slot",
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        Text(
                          _isSlotFilterActive
                              ? "${DateFormat('d MMM').format(_slotDate)} • ${_formatTimeOfDay(_slotStartTime)} - ${_formatTimeOfDay(_slotEndTime)}"
                              : "Find grounds available on a selected slot",
                          style: TextStyle(
                            fontSize: 12,
                            color: _isSlotFilterActive
                                ? AppColors.primaryDarkGreen
                                : subtleText,
                            fontWeight: _isSlotFilterActive
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Animated Switch
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    width: 48,
                    height: 28,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: _isSlotFilterActive
                          ? AppColors.primaryDarkGreen
                          : (isDark
                              ? const Color(0xFF333333)
                              : const Color(0xFFDDDDDD)),
                    ),
                    child: AnimatedAlign(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      alignment: _isSlotFilterActive
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expanded Controls when active
          if (_isSlotFilterActive) ...[
            Divider(
              height: 1,
              color: isDark ? const Color(0xFF333333) : const Color(0xFFEEEEEE),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. SPORT SELECTOR
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.sports_soccer_outlined,
                            size: 16,
                            color: AppColors.primaryDarkGreen,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "Select Sport",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.grey[300] : Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                      if (_selectedSport != 'all')
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryDarkGreen.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _selectedSportName,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDarkGreen,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildSportSelector(isDark),

                  const SizedBox(height: 20),

                  // 2. DATE SELECTOR
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Booking Date",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.grey[300] : Colors.grey[800],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryDarkGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          DateFormat('EEE, d MMM yyyy').format(_slotDate),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDarkGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Quick Date Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _buildQuickDateChip("Today", 0, daysDiff == 0, isDark),
                        const SizedBox(width: 8),
                        _buildQuickDateChip(
                            "Tomorrow", 1, daysDiff == 1, isDark),
                        const SizedBox(width: 8),
                        _buildQuickDateChip(
                            "In 2 Days", 2, daysDiff == 2, isDark),
                        const SizedBox(width: 8),
                        _buildQuickDateChip(
                            "In 3 Days", 3, daysDiff == 3, isDark),
                        const SizedBox(width: 8),
                        _buildPickDateButton(isDark),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 3. TIME RANGE SELECTOR
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Slot Time Range",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.grey[300] : Colors.grey[800],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryDarkGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _formatDuration(_slotStartTime, _slotEndTime),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDarkGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Quick Time Presets
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _buildQuickTimeChip(
                          label: "6 PM - 8 PM",
                          start: const TimeOfDay(hour: 18, minute: 0),
                          end: const TimeOfDay(hour: 20, minute: 0),
                          isDark: isDark,
                        ),
                        const SizedBox(width: 8),
                        _buildQuickTimeChip(
                          label: "7 PM - 9 PM",
                          start: const TimeOfDay(hour: 19, minute: 0),
                          end: const TimeOfDay(hour: 21, minute: 0),
                          isDark: isDark,
                        ),
                        const SizedBox(width: 8),
                        _buildQuickTimeChip(
                          label: "8 PM - 10 PM",
                          start: const TimeOfDay(hour: 20, minute: 0),
                          end: const TimeOfDay(hour: 22, minute: 0),
                          isDark: isDark,
                        ),
                        const SizedBox(width: 8),
                        _buildQuickTimeChip(
                          label: "6 AM - 8 AM",
                          start: const TimeOfDay(hour: 6, minute: 0),
                          end: const TimeOfDay(hour: 8, minute: 0),
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Interactive Start & End Time Pickers
                  Row(
                    children: [
                      Expanded(
                        child: _buildTimePickerBox(
                          label: "Start Time",
                          time: _slotStartTime,
                          onTap: _pickStartTime,
                          isDark: isDark,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                          color: AppColors.primaryDarkGreen.withOpacity(0.7),
                        ),
                      ),
                      Expanded(
                        child: _buildTimePickerBox(
                          label: "End Time",
                          time: _slotEndTime,
                          onTap: _pickEndTime,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickDateChip(
      String label, int daysOffset, bool isSelected, bool isDark) {
    return GestureDetector(
      onTap: () {
        final now = DateTime.now();
        setState(() {
          _slotDate = DateTime(now.year, now.month, now.day + daysOffset);
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryDarkGreen
              : (isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF0F2F1)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryDarkGreen
                : (isDark ? Colors.grey[800]! : Colors.grey[300]!),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.grey[300] : Colors.grey[800]),
          ),
        ),
      ),
    );
  }

  Widget _buildPickDateButton(bool isDark) {
    return GestureDetector(
      onTap: _pickCustomDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF0F2F1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_month_rounded,
              size: 14,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
            const SizedBox(width: 4),
            Text(
              "Calendar",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSportSelector(bool isDark) {
    return BlocBuilder<SportCubit, SportState>(
      builder: (context, sportState) {
        final List<({String id, String name, String? iconUrl, String? localAsset, IconData? icon})> sportsList = [
          (
            id: 'all',
            name: 'All Sports',
            iconUrl: null,
            localAsset: null,
            icon: Icons.grid_view_rounded,
          ),
        ];

        if (sportState is SportLoaded && sportState.sports.isNotEmpty) {
          for (final s in sportState.sports) {
            sportsList.add((
              id: s.name.toLowerCase(),
              name: s.name,
              iconUrl: s.iconUrl.isNotEmpty ? s.iconUrl : null,
              localAsset: s.localAsset.isNotEmpty ? s.localAsset : null,
              icon: _getSportFallbackIcon(s.name),
            ));
          }
        } else {
          const fallbackNames = [
            'Cricket',
            'Box Cricket',
            'Football',
            'Badminton',
            'Pickleball',
            'Tennis',
            'Volleyball',
          ];
          for (final name in fallbackNames) {
            sportsList.add((
              id: name.toLowerCase(),
              name: name,
              iconUrl: null,
              localAsset: null,
              icon: _getSportFallbackIcon(name),
            ));
          }
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: sportsList.map((sport) {
              final isSelected = _selectedSport.toLowerCase() == sport.id.toLowerCase() ||
                  (_selectedSport == 'all' && sport.id == 'all');
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _selectedSport = sport.id;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryDarkGreen
                          : (isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF0F2F1)),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryDarkGreen
                            : (isDark ? Colors.grey[800]! : Colors.grey[300]!),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (sport.iconUrl != null && sport.iconUrl!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: sport.iconUrl!,
                                width: 16,
                                height: 16,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => Icon(
                                  sport.icon ?? Icons.sports,
                                  size: 14,
                                  color: isSelected ? Colors.white : AppColors.primaryDarkGreen,
                                ),
                              ),
                            ),
                          )
                        else if (sport.localAsset != null && sport.localAsset!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ClipOval(
                              child: Image.asset(
                                sport.localAsset!,
                                width: 16,
                                height: 16,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(
                                  sport.icon ?? Icons.sports,
                                  size: 14,
                                  color: isSelected ? Colors.white : AppColors.primaryDarkGreen,
                                ),
                              ),
                            ),
                          )
                        else if (sport.icon != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Icon(
                              sport.icon,
                              size: 14,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? Colors.grey[400] : Colors.grey[700]),
                            ),
                          ),
                        Text(
                          sport.name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? Colors.grey[300] : Colors.grey[800]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  IconData _getSportFallbackIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('cricket')) return Icons.sports_cricket;
    if (lower.contains('football') || lower.contains('soccer')) return Icons.sports_soccer;
    if (lower.contains('tennis')) return Icons.sports_tennis;
    if (lower.contains('badminton')) return Icons.sports_tennis;
    if (lower.contains('basket')) return Icons.sports_basketball;
    if (lower.contains('volley')) return Icons.sports_volleyball;
    if (lower.contains('golf')) return Icons.sports_golf;
    return Icons.sports;
  }

  Widget _buildQuickTimeChip({
    required String label,
    required TimeOfDay start,
    required TimeOfDay end,
    required bool isDark,
  }) {
    final isSelected = _slotStartTime.hour == start.hour &&
        _slotStartTime.minute == start.minute &&
        _slotEndTime.hour == end.hour &&
        _slotEndTime.minute == end.minute;

    return GestureDetector(
      onTap: () {
        setState(() {
          _slotStartTime = start;
          _slotEndTime = end;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryDarkGreen
              : (isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF0F2F1)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryDarkGreen
                : (isDark ? Colors.grey[800]! : Colors.grey[300]!),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.grey[300] : Colors.grey[800]),
          ),
        ),
      ),
    );
  }

  Widget _buildTimePickerBox({
    required String label,
    required TimeOfDay time,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? const Color(0xFF3D3D3D) : const Color(0xFFDCDCDC),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatTimeOfDay(time),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const Icon(
                  Icons.access_time_rounded,
                  size: 16,
                  color: AppColors.primaryDarkGreen,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickCustomDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _slotDate.isBefore(now) ? now : _slotDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primaryDarkGreen,
              primary: AppColors.primaryDarkGreen,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _slotDate = picked;
      });
    }
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _slotStartTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primaryDarkGreen,
              primary: AppColors.primaryDarkGreen,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _slotStartTime = picked;
        // If end time is before or equal to start time, advance end time by 2 hours
        int startMins = picked.hour * 60 + picked.minute;
        int endMins = _slotEndTime.hour * 60 + _slotEndTime.minute;
        if (endMins <= startMins) {
          int newEndMins = (startMins + 120) % 1440;
          _slotEndTime =
              TimeOfDay(hour: newEndMins ~/ 60, minute: newEndMins % 60);
        }
      });
    }
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _slotEndTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primaryDarkGreen,
              primary: AppColors.primaryDarkGreen,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _slotEndTime = picked;
      });
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('h:mm a').format(dt);
  }

  String _formatDuration(TimeOfDay start, TimeOfDay end) {
    int startMins = start.hour * 60 + start.minute;
    int endMins = end.hour * 60 + end.minute;
    if (endMins <= startMins) endMins += 1440;
    final diff = endMins - startMins;
    final hours = diff ~/ 60;
    final mins = diff % 60;
    if (hours > 0 && mins > 0) return "$hours hr $mins min";
    if (hours > 0) return "$hours hr${hours > 1 ? 's' : ''}";
    return "$mins mins";
  }

  // ─── HELPERS ───

  void _resetAll() {
    setState(() {
      _sortBy = SortBy.none;
      _minPrice = 0;
      _maxPrice = 5000;
      _isAvailableNow = false;
      _isNearMe = false;
      _isTopRated = false;
      _isSlotFilterActive = false;
      _selectedSport = 'all';
      _slotDate = DateTime.now().add(const Duration(days: 2));
      _slotStartTime = const TimeOfDay(hour: 18, minute: 0);
      _slotEndTime = const TimeOfDay(hour: 20, minute: 0);
    });
  }

  Widget _buildSectionHeader(String title, dynamic icon, bool isDark) {
    return Row(
      children: [
        HugeIcon(
          icon: icon,
          color: AppColors.primaryDarkGreen,
          size: 18,
        ),
        const SizedBox(width: 8),
        AppText(
          text: title,
          textStyle: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 15,
            color: isDark ? Colors.white : Colors.black87,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildSortOption(
      SortBy sort, String label, IconData mIcon, bool isDark) {
    final isSelected = _sortBy == sort;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _sortBy = isSelected ? SortBy.none : sort),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryDarkGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                mIcon,
                size: 16,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.grey[500] : Colors.grey[600]),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.grey[400] : Colors.grey[700]),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceChip(String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryDarkGreen.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.primaryDarkGreen.withOpacity(0.2),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.primaryDarkGreen,
          fontWeight: FontWeight.w800,
          fontSize: 15,
        ),
      ),
    );
  }

  Widget _buildQuickFilterTile({
    required String title,
    required String subtitle,
    required dynamic icon,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDark,
    required Color cardBg,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: value ? AppColors.primaryDarkGreen.withOpacity(0.08) : cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: value
                ? AppColors.primaryDarkGreen.withOpacity(0.4)
                : (isDark ? const Color(0xFF333333) : const Color(0xFFEEEEEE)),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: value
                    ? AppColors.primaryDarkGreen.withOpacity(0.15)
                    : (isDark
                        ? const Color(0xFF2A2A2A)
                        : const Color(0xFFF0F0F0)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: HugeIcon(
                icon: icon,
                color: value
                    ? AppColors.primaryDarkGreen
                    : (isDark ? Colors.grey[500]! : Colors.grey[600]!),
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[600] : Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // Custom Toggle
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              width: 48,
              height: 28,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: value
                    ? AppColors.primaryDarkGreen
                    : (isDark
                        ? const Color(0xFF333333)
                        : const Color(0xFFDDDDDD)),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
