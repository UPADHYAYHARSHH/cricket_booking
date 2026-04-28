import 'package:turfpro/common/constants/colors.dart';
import 'package:turfpro/user_booking/constants/widgets/app_sizedBox.dart';
import 'package:turfpro/user_booking/constants/widgets/app_text.dart';
import 'package:turfpro/user_booking/domain/models/filter_criteria.dart';

import 'package:flutter/material.dart';

class FilterBottomSheet extends StatefulWidget {
  final FilterCriteria initialCriteria;
  final Function(FilterCriteria) onApply;

  const FilterBottomSheet({
    super.key,
    required this.initialCriteria,
    required this.onApply,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late SortBy _sortBy;
  late double _minPrice;
  late double _maxPrice;
  late bool _isAvailableNow;

  @override
  void initState() {
    super.initState();
    _sortBy = widget.initialCriteria.sortBy;
    _minPrice = widget.initialCriteria.minPrice;
    _maxPrice = widget.initialCriteria.maxPrice;
    _isAvailableNow = widget.initialCriteria.isAvailableNow;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const AppText(
                text: "Filters",
                textStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _sortBy = SortBy.nearMe;
                    _minPrice = 0;
                    _maxPrice = 5000;
                    _isAvailableNow = false;
                  });
                },
                child: const AppText(
                  text: "Reset All",
                  textStyle:
                      TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const Divider(),
          const AppSizedBox(height: 16),

          /// SORT BY
          const AppText(
            text: "Sort By",
            textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const AppSizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: SortBy.values.map((sort) {
                final isSelected = _sortBy == sort;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(_getSortLabel(sort)),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) setState(() => _sortBy = sort);
                    },
                    selectedColor: AppColors.primaryDarkGreen,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurface,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                );
              }).toList(),
            ),
          ),
          const AppSizedBox(height: 24),

          /// PRICE RANGE
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const AppText(
                text: "Price Range",
                textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              AppText(
                text: "₹${_minPrice.toInt()} - ₹${_maxPrice.toInt()}",
                textStyle: const TextStyle(
                    color: AppColors.primaryDarkGreen,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          RangeSlider(
            values: RangeValues(_minPrice, _maxPrice),
            min: 0,
            max: 5000,
            divisions: 50,
            activeColor: AppColors.primaryDarkGreen,
            inactiveColor: AppColors.primaryDarkGreen.withValues(alpha: 0.1),
            labels:
                RangeLabels("₹${_minPrice.toInt()}", "₹${_maxPrice.toInt()}"),
            onChanged: (values) {
              setState(() {
                _minPrice = values.start;
                _maxPrice = values.end;
              });
            },
          ),
          const AppSizedBox(height: 24),

          const AppSizedBox(height: 24),

          /// AVAILABLE NOW
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppText(
                    text: "Available Now",
                    textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  AppText(
                    text: "Show grounds that are currently open",
                    textStyle: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                  ),
                ],
              ),
              Switch(
                value: _isAvailableNow,
                activeColor: AppColors.primaryDarkGreen,
                onChanged: (val) {
                  setState(() {
                    _isAvailableNow = val;
                  });
                },
              ),
            ],
          ),

          const AppSizedBox(height: 32),

          /// APPLY BUTTON
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                  final criteria = FilterCriteria(
                    sortBy: _sortBy,
                    minPrice: _minPrice,
                    maxPrice: _maxPrice,
                    selectedAmenities: widget.initialCriteria.selectedAmenities,
                    isAvailableNow: _isAvailableNow,
                  );
                widget.onApply(criteria);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDarkGreen,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const AppText(
                text: "Apply Filters",
                textStyle: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
            ),
          ),
          const AppSizedBox(height: 12),
        ],
      ),
    );
  }

  String _getSortLabel(SortBy sort) {
    switch (sort) {
      case SortBy.nearMe:
        return "Near Me";
      case SortBy.topRated:
        return "Top Rated";
      case SortBy.priceLowToHigh:
        return "Price: Low to High";
      case SortBy.priceHighToLow:
        return "Price: High to Low";
    }
  }
}
