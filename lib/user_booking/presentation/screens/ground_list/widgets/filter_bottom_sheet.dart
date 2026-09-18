import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:turfpro/common/constants/colors.dart';
import 'package:turfpro/user_booking/constants/widgets/app_sizedBox.dart';
import 'package:turfpro/user_booking/constants/widgets/app_text.dart';
import 'package:turfpro/user_booking/domain/models/filter_criteria.dart';

class FilterBottomSheet extends StatefulWidget {
  final FilterCriteria initialCriteria;
  final List<String>? suggestedAmenities;
  final Function(FilterCriteria) onApply;

  const FilterBottomSheet({
    super.key,
    required this.initialCriteria,
    this.suggestedAmenities,
    required this.onApply,
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
  late List<String> _selectedAmenities;
  late AnimationController _animCtrl;
  late Animation<double> _fadeIn;

  int get _activeFilterCount {
    int count = 0;
    if (_sortBy != SortBy.none) count++;
    if (_minPrice > 0 || _maxPrice < 5000) count++;
    if (_selectedAmenities.isNotEmpty) count++;
    if (_isAvailableNow) count++;
    if (_isNearMe) count++;
    if (_isTopRated) count++;
    return count;
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
    _selectedAmenities = List.from(widget.initialCriteria.selectedAmenities);
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
    final subtleText = isDark ? Colors.grey[500]! : Colors.grey[500]!;

    return FadeTransition(
      opacity: _fadeIn,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
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
                            text: "$_activeFilterCount filter${_activeFilterCount > 1 ? 's' : ''} active",
                            textStyle: TextStyle(
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
                      icon: Icon(Icons.refresh_rounded, size: 16, color: Colors.redAccent[200]),
                      label: Text(
                        "Reset",
                        style: TextStyle(
                          color: Colors.redAccent[200],
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        backgroundColor: Colors.redAccent.withOpacity(0.08),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                ],
              ),
            ),

            // ─── Scrollable Content ───
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Sort By ──
                    _buildSectionHeader("Sort By", HugeIcons.strokeRoundedSorting01, isDark),
                    const AppSizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? const Color(0xFF333333) : const Color(0xFFEEEEEE),
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
                    _buildSectionHeader("Price Range", HugeIcons.strokeRoundedMoney01, isDark),
                    const AppSizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark ? const Color(0xFF333333) : const Color(0xFFEEEEEE),
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
                              inactiveTrackColor: AppColors.primaryDarkGreen.withOpacity(0.12),
                              thumbColor: AppColors.primaryDarkGreen,
                              overlayColor: AppColors.primaryDarkGreen.withOpacity(0.12),
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 10,
                                elevation: 3,
                                pressedElevation: 6,
                              ),
                              overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
                              rangeThumbShape: const RoundRangeSliderThumbShape(
                                enabledThumbRadius: 10,
                                elevation: 3,
                                pressedElevation: 6,
                              ),
                              rangeTrackShape: const RoundedRectRangeSliderTrackShape(),
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
                    const AppSizedBox(height: 28),

                    // ── Amenities ──
                    if (widget.suggestedAmenities != null &&
                        widget.suggestedAmenities!.isNotEmpty) ...[
                      _buildSectionHeader("Amenities", HugeIcons.strokeRoundedDashboardSquare01, isDark),
                      const AppSizedBox(height: 14),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: widget.suggestedAmenities!.map((amenity) {
                          final isSelected = _selectedAmenities.contains(amenity);
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                isSelected
                                    ? _selectedAmenities.remove(amenity)
                                    : _selectedAmenities.add(amenity);
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOutCubic,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primaryDarkGreen
                                    : cardBg,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primaryDarkGreen
                                      : (isDark
                                          ? const Color(0xFF333333)
                                          : const Color(0xFFE0E0E0)),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isSelected) ...[
                                    const Icon(
                                      Icons.check_rounded,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 6),
                                  ],
                                  Text(
                                    amenity,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isSelected
                                          ? Colors.white
                                          : (isDark
                                              ? Colors.grey[300]
                                              : Colors.grey[800]),
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const AppSizedBox(height: 28),
                    ],

                    // ── Quick Filters ──
                    _buildSectionHeader("Quick Filters", HugeIcons.strokeRoundedFlash, isDark),
                    const AppSizedBox(height: 14),
                    _buildQuickFilterTile(
                      title: "Available Now",
                      subtitle: "Currently open grounds",
                      icon: HugeIcons.strokeRoundedClock01,
                      value: _isAvailableNow,
                      onChanged: (v) => setState(() => _isAvailableNow = v),
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
                    const AppSizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // ─── Bottom CTA ───
            Container(
              padding: EdgeInsets.fromLTRB(
                24, 16, 24,
                MediaQuery.of(context).padding.bottom + 16,
              ),
              decoration: BoxDecoration(
                color: bg,
                border: Border(
                  top: BorderSide(
                    color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0F0F0),
                  ),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    widget.onApply(FilterCriteria(
                      sortBy: _sortBy,
                      minPrice: _minPrice,
                      maxPrice: _maxPrice,
                      selectedAmenities: _selectedAmenities,
                      isAvailableNow: _isAvailableNow,
                      isNearMe: _isNearMe,
                      isTopRated: _isTopRated,
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
                  child: Row(
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

  // ─── HELPERS ───

  void _resetAll() {
    setState(() {
      _sortBy = SortBy.none;
      _minPrice = 0;
      _maxPrice = 5000;
      _isAvailableNow = false;
      _isNearMe = false;
      _isTopRated = false;
      _selectedAmenities.clear();
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

  Widget _buildSortOption(SortBy sort, String label, IconData mIcon, bool isDark) {
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
          color: value
              ? AppColors.primaryDarkGreen.withOpacity(0.08)
              : cardBg,
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
                    : (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0F0F0)),
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
                    : (isDark ? const Color(0xFF333333) : const Color(0xFFDDDDDD)),
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
