import 'dart:ui' as ui;
import 'package:bloc_structure/common/constants/colors.dart';
import '../../constants/widgets/app_sizedBox.dart';
import '../../constants/widgets/app_text.dart';
import 'package:bloc_structure/user_booking/data/models/ground_model.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/widgets/app_network_image.dart';
import '../../domain/models/slot_models.dart';

class SlotSelectionWidgets {
  static const Color kOrange = AppColors.accentOrange;
  static const Color kLightOrange = Color(0xFFFFF3EE);

  static Widget buildHeader(BuildContext context, GroundModel? ground,
      {bool isSaved = false, VoidCallback? onToggleFav}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      color: colorScheme.surface,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 8,
        right: 8,
        bottom: 12,
      ),
      child: Row(
        children: [
          IconButton(
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedArrowLeft01,
              size: 20,
              color: colorScheme.onSurface,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  text: ground?.name ?? 'Loading Turf...',
                  align: TextAlign.left,
                  textStyle: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const AppSizedBox(height: 2),
                Row(
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedLocation01,
                      size: 12,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                    const AppSizedBox(width: 4),
                    Flexible(
                      child: AppText(
                        text: ground?.address ?? 'Loading Address...',
                        align: TextAlign.left,
                        textStyle: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: isSaved
                ? const Icon(
                    Icons.favorite,
                    size: 22,
                    color: AppColors.error,
                  )
                : HugeIcon(
                    icon: HugeIcons.strokeRoundedFavourite,
                    size: 22,
                    color: colorScheme.onSurface,
                  ),
            onPressed: onToggleFav,
          ),
          IconButton(
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedShare01,
              size: 22,
              color: colorScheme.onSurface,
            ),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  // ── Turf Image Card ───────────────────────────────────────────────────────

  static Widget buildTurfImage(GroundModel? ground) {
    return Container(
      height: 175,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Stack(
        children: [
          // Real Ground Image
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AppNetworkImage(
              imageUrl: (ground?.imageUrl != null &&
                      ground!.imageUrl.isNotEmpty)
                  ? ground.imageUrl
                  : "https://images.unsplash.com/photo-1540747913346-19e32dc3e97e",
              height: 175,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          // Dark overlay for better text contrast if needed
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.4),
                ],
              ),
            ),
          ),
          // Badges
          Positioned(
            bottom: 12,
            left: 12,
            child: _badge(
              icon: HugeIcons.strokeRoundedStar,
              iconColor: AppColors.goldenYellow,
              text:
                  '${ground?.rating ?? 0.0}  (${ground?.totalReviews ?? 0}+ REVIEWS)',
              bgColor: AppColors.black.withOpacity(0.55),
              textColor: AppColors.white,
            ),
          ),
          Positioned(
            bottom: 12,
            right: 12,
            child: _badge(
              text:
                  'From ₹${ground?.pricePerHour.toStringAsFixed(0) ?? '0'}/hr',
              bgColor: kOrange,
              textColor: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _badge({
    dynamic icon,
    Color? iconColor,
    required String text,
    required Color bgColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            HugeIcon(icon: icon, size: 13, color: iconColor ?? AppColors.white),
            const AppSizedBox(width: 4),
          ],
          AppText(
            text: text,
            textStyle: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  // ── Date Selector ─────────────────────────────────────────────────────────

  static Widget buildDateSelector(
      BuildContext context, List<DateItem> dates, Function(int) onSelectDate) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      color: colorScheme.surface,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText(
                text: 'SELECT DATE',
                align: TextAlign.left,
                textStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: colorScheme.onSurface,
                ),
              ),
              AppText(
                text: DateFormat('MMMM yyyy').format(DateTime.now()),
                align: TextAlign.left,
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: kOrange,
                ),
              ),
            ],
          ),
          const AppSizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: List.generate(dates.length, (i) {
                final d = dates[i];
                final bool sel = d.isSelected;
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () => onSelectDate(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 56,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: sel ? kOrange : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border:
                            sel ? null : Border.all(color: theme.dividerColor),
                      ),
                      child: Column(
                        children: [
                          AppText(
                            text: d.day,
                            textStyle: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: sel
                                  ? AppColors.white.withOpacity(0.7)
                                  : colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                          const AppSizedBox(height: 4),
                          AppText(
                            text: '${d.date}',
                            textStyle: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color:
                                  sel ? AppColors.white : colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // ── Period Filter ─────────────────────────────────────────────────────────
  static Widget buildPeriodFilter(
      BuildContext context, String selectedPeriod, Function(String) onSelect) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final periods = ['Morning', 'Evening', 'Night'];

    return Container(
      color: colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: periods.map((p) {
            final isSel = p == selectedPeriod;
            return Expanded(
              child: GestureDetector(
                onTap: () => onSelect(p),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSel ? colorScheme.surface : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: isSel
                        ? [
                            BoxShadow(
                              color:
                                  Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                          ]
                        : [],
                  ),
                  child: Center(
                    child: AppText(
                      text: p,
                      textStyle: TextStyle(
                        fontSize: 14,
                        fontWeight: isSel ? FontWeight.w700 : FontWeight.w600,
                        color: isSel
                            ? (isDark
                                ? const Color(0xFF81C784)
                                : const Color(0xFF4A7C59))
                            : colorScheme.onSurface.withOpacity(0.4),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── Legend ────────────────────────────────────────────────────────────────

  // static Widget buildLegend(BuildContext context) {
  //   final theme = Theme.of(context);
  //   final colorScheme = theme.colorScheme;

  //   return Container(
  //     color: colorScheme.surface,
  //     padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
  //     child: Row(
  //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //       children: [
  //         _legendItem(context, color: const Color(0xFF00C897), label: 'AVAILABLE'),
  //         _legendItem(context, color: const Color(0xFFFF5252), label: 'BOOKED'),
  //         _legendItem(context, color: const Color(0xFFFFD600), label: 'ADVANCE'),
  //         _legendItem(context, color: const Color(0xFFFF9800), label: 'SELECTED'),
  //       ],
  //     ),
  //   );
  // }

  static Widget _legendItem(BuildContext context,
      {required Color color, required String label}) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const AppSizedBox(width: 6),
        AppText(
          text: label,
          textStyle: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
      ],
    );
  }

  // ── Slot Section ──────────────────────────────────────────────────────────

  static Widget buildSlotSection(
      BuildContext context, List<TimeSlot> slots, Function(int) onToggleSlot) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      color: colorScheme.surface,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Remove the explicit title here as we have tabs now
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: slots.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.55,
            ),
            itemBuilder: (ctx, i) =>
                _buildSlotCard(context, slots[i], i, onToggleSlot),
          ),
        ],
      ),
    );
  }

  static Widget _buildSlotCard(BuildContext context, TimeSlot slot, int index,
      Function(int) onToggleSlot) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final bool isBooked = slot.status == SlotStatus.booked;
    final bool isSelected = slot.status == SlotStatus.selected;
    final bool isAdvance = slot.status == SlotStatus.advance;
    final bool isAvailable = slot.status == SlotStatus.available;

    Color borderColor;
    Color timeColor = colorScheme.onSurface;
    Color subColor = colorScheme.onSurface.withOpacity(0.4);
    Color priceColor = const Color(0xFF4A7C59);
    IconData? statusIcon;
    Color? iconColor;

    if (isSelected) {
      borderColor = const Color(0xFFFF9800);
      statusIcon = Icons.radio_button_checked;
      iconColor = const Color(0xFFFF9800);
      priceColor = const Color(0xFFFF9800);
    } else if (isBooked) {
      borderColor = Colors.transparent;
      timeColor = colorScheme.onSurface.withOpacity(0.3);
      subColor = colorScheme.onSurface.withOpacity(0.2);
      priceColor = colorScheme.onSurface.withOpacity(0.2);
      statusIcon = Icons.block;
      iconColor = colorScheme.onSurface.withOpacity(0.3);
    } else if (isAdvance) {
      borderColor = const Color(0xFFFFD600);
      statusIcon = Icons.info;
      iconColor = const Color(0xFFFFD600);
    } else {
      // Available
      borderColor = const Color(0xFF00C897).withOpacity(0.15);
      statusIcon = Icons.check_circle;
      iconColor = const Color(0xFF00C897);
    }

    return GestureDetector(
      onTap: () => onToggleSlot(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isBooked
              ? colorScheme.onSurface.withOpacity(0.08)
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isBooked ? Colors.transparent : borderColor,
              width: 2),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFFF9800).withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ],
        ),
        padding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppText(
                  text: slot.startTime.split(' ')[0], // Just show HH:MM
                  textStyle: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: timeColor,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      text: '1 Hour Slot',
                      textStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: subColor,
                      ),
                    ),
                    const AppSizedBox(height: 8),
                    if (isBooked)
                      AppText(
                        text: 'Booked',
                        textStyle: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: subColor,
                        ),
                      )
                    else
                      AppText(
                        text: '₹${slot.price.toStringAsFixed(2)}',
                        textStyle: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: priceColor,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            Positioned(
              top: 0,
              right: 0,
              child: Icon(
                statusIcon,
                size: 18,
                color: iconColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Bottom Bar ────────────────────────────────────────────────────────────

  static Widget buildBottomBar(
      BuildContext context,
      List<TimeSlot> selectedSlots,
      DateItem activeDate,
      double totalPrice,
      VoidCallback onConfirm) {
    if (selectedSlots.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final firstSlot = selectedSlots.first;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withOpacity(theme.brightness == Brightness.dark ? 0.3 : 0.1),
            blurRadius: 16,
            offset: const Offset(0, -4),
          )
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText(
                text: 'SELECTED SLOTS',
                textStyle: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
              AppText(
                text: 'TOTAL PRICE',
                textStyle: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ],
          ),
          const AppSizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText(
                text:
                    '${selectedSlots.length} Slot • ${activeDate.month} ${activeDate.date}, ${firstSlot.startTime}',
                textStyle: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              AppText(
                text: '₹${totalPrice.toStringAsFixed(0)}',
                textStyle: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: kOrange,
                ),
              ),
            ],
          ),
          const AppSizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 2,
                shadowColor: kOrange.withOpacity(0.4),
              ),
              onPressed: onConfirm,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppText(
                    text: 'Confirm Booking',
                    textStyle: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Description Section ───────────────────────────────────────────────────

  static Widget buildDescriptionSection(
      BuildContext context, String? description) {
    if (description == null || description.isEmpty) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      color: colorScheme.surface,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            text: 'DESCRIPTION',
            align: TextAlign.left,
            textStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: colorScheme.onSurface,
            ),
          ),
          const AppSizedBox(height: 12),
          _ExpandableDescription(description: description),
        ],
      ),
    );
  }

  // ── Amenities Section ──────────────────────────────────────────────────────

  static Widget buildAmenitiesSection(
      BuildContext context, List<String>? amenities) {
    if (amenities == null || amenities.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      color: colorScheme.surface,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            text: 'AMENITIES',
            align: TextAlign.left,
            textStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: colorScheme.onSurface,
            ),
          ),
          const AppSizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: amenities.map((a) => _amenityChip(context, a)).toList(),
          ),
        ],
      ),
    );
  }

  static Widget _amenityChip(BuildContext context, String label) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    dynamic icon;
    switch (label.toLowerCase()) {
      case 'parking':
        icon = HugeIcons.strokeRoundedLocation01; // Use a known working one
        break;
      case 'washroom':
      case 'toilet':
        icon = HugeIcons.strokeRoundedLocation01;
        break;
      case 'water':
      case 'drinking water':
        icon = HugeIcons.strokeRoundedLocation01;
        break;
      case 'changing room':
        icon = HugeIcons.strokeRoundedLocation01;
        break;
      case 'cafeteria':
      case 'canteen':
        icon = HugeIcons.strokeRoundedLocation01;
        break;
      case 'first aid':
        icon = HugeIcons.strokeRoundedLocation01;
        break;
      default:
        icon = HugeIcons.strokeRoundedLocation01;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(icon: icon, size: 16, color: kOrange),
          const AppSizedBox(width: 8),
          AppText(
            text: label,
            align: TextAlign.left,
            textStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  // ── Address & Map Section ──────────────────────────────────────────────────

  static Widget buildMapSection(BuildContext context, GroundModel ground) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      color: colorScheme.surface,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            text: 'LOCATION',
            align: TextAlign.left,
            textStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: colorScheme.onSurface,
            ),
          ),
          const AppSizedBox(height: 12),
          GestureDetector(
            onTap: () => _openMap(ground.latitude, ground.longitude),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: kOrange.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const HugeIcon(
                          icon: HugeIcons.strokeRoundedLocation01,
                          size: 20,
                          color: kOrange,
                        ),
                      ),
                      const AppSizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText(
                              text: ground.address,
                              align: TextAlign.left,
                              textStyle: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const AppSizedBox(height: 2),
                            const AppText(
                              text: 'Tap to view on Maps',
                              align: TextAlign.left,
                              textStyle: TextStyle(
                                fontSize: 11,
                                color: kOrange,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedArrowRight01,
                        size: 18,
                        color: colorScheme.onSurface.withOpacity(0.4),
                      ),
                    ],
                  ),
                  const AppSizedBox(height: 12),
                  // Static Map Placeholder (Styled to look like a map)
                  SizedBox(
                    height: 160,
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: LatLng(ground.latitude, ground.longitude),
                              zoom: 15,
                            ),
                            markers: {
                              Marker(
                                markerId: const MarkerId('ground'),
                                position:
                                    LatLng(ground.latitude, ground.longitude),
                              ),
                            },
                            zoomControlsEnabled: false,
                            myLocationButtonEnabled: false,
                            liteModeEnabled:
                                true, // IMPORTANT for performance in lists/scrolls
                          ),
                        ),

                        /// Overlay Button (Open in Maps)
                        Positioned.fill(
                          child: Center(
                            child: GestureDetector(
                              onTap: () =>
                                  _openMap(ground.latitude, ground.longitude),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.black.withOpacity(0.15),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    )
                                  ],
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    HugeIcon(
                                      icon: HugeIcons.strokeRoundedLocation01,
                                      size: 16,
                                      color: kOrange,
                                    ),
                                    AppSizedBox(width: 8),
                                    AppText(
                                      text: 'Open in Maps',
                                      align: TextAlign.left,
                                      textStyle: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimaryLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> _openMap(double lat, double lng) async {
    final String googleUrl =
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    final Uri url = Uri.parse(googleUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $googleUrl';
    }
  }
}

class _ExpandableDescription extends StatefulWidget {
  final String description;
  const _ExpandableDescription({required this.description});

  @override
  State<_ExpandableDescription> createState() => _ExpandableDescriptionState();
}

class _ExpandableDescriptionState extends State<_ExpandableDescription> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(builder: (context, constraints) {
          final span = TextSpan(
            text: widget.description,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          );

          final tp = TextPainter(
            text: span,
            maxLines: 3,
            textDirection: ui.TextDirection.ltr,
          );
          tp.layout(maxWidth: constraints.maxWidth);

          if (!tp.didExceedMaxLines) {
            return AppText(
              text: widget.description,
              align: TextAlign.left,
              textStyle: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.description,
                maxLines: _isExpanded ? null : 3,
                overflow:
                    _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const AppSizedBox(height: 4),
              GestureDetector(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                child: AppText(
                  text: _isExpanded ? "See Less" : "See More",
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accentOrange,
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }
}
