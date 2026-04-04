import 'package:bloc_structure/common/constants/colors.dart';
import '../../constants/widgets/app_sizedBox.dart';
import '../../constants/widgets/app_text.dart';
import 'package:bloc_structure/user_booking/data/models/ground_model.dart';
import 'package:bloc_structure/user_booking/presentation/widgets/pitch_painter.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/models/slot_models.dart';

class SlotSelectionWidgets {
  static const Color kOrange = AppColors.accentOrange;
  static const Color kLightOrange = Color(0xFFFFF3EE);

  // ── App Bar + Header ──────────────────────────────────────────────────────

  static Widget buildHeader(BuildContext context, GroundModel? ground,
      {bool isSaved = false, VoidCallback? onToggleFav}) {
    return Container(
      color: AppColors.surfaceLight,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 8,
        right: 8,
        bottom: 12,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedArrowLeft01,
              size: 20,
              color: AppColors.textPrimaryLight,
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
                  textStyle: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
                const AppSizedBox(height: 2),
                Row(
                  children: [
                    const HugeIcon(
                      icon: HugeIcons.strokeRoundedLocation01,
                      size: 12,
                      color: AppColors.textSecondaryLight,
                    ),
                    const AppSizedBox(width: 4),
                    Flexible(
                      child: AppText(
                        text: ground?.address ?? 'Loading Address...',
                        align: TextAlign.left,
                        textStyle: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedFavourite,
              size: 22,
              color: isSaved ? AppColors.error : AppColors.textPrimaryLight,
            ),
            onPressed: onToggleFav,
          ),
          IconButton(
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedShare01,
              size: 22,
              color: AppColors.textPrimaryLight,
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
        color: const Color(0xFF4A7C59),
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
          // Grass texture overlay
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF2D5A3D),
                    Color(0xFF4A7C59),
                    Color(0xFF3A6B47),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          // Pitch lines
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: CustomPaint(
              size: const Size(double.infinity, 175),
              painter: PitchPainter(),
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
      List<DateItem> dates, Function(int) onSelectDate) {
    return Container(
      color: AppColors.surfaceLight,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const AppText(
                text: 'SELECT DATE',
                align: TextAlign.left,
                textStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: AppColors.textPrimaryLight,
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
                            sel ? null : Border.all(color: AppColors.borderLight),
                      ),
                      child: Column(
                        children: [
                          AppText(
                            text: d.day,
                            textStyle: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: sel ? AppColors.white.withOpacity(0.7) : AppColors.textSecondaryLight,
                            ),
                          ),
                          const AppSizedBox(height: 4),
                          AppText(
                            text: '${d.date}',
                            textStyle: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: sel ? AppColors.white : AppColors.textPrimaryLight,
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

  // ── Legend ────────────────────────────────────────────────────────────────

  static Widget buildLegend() {
    return Container(
      color: AppColors.surfaceLight,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          _legendItem(color: AppColors.success, label: 'Available'),
          const AppSizedBox(width: 16),
          _legendItem(color: AppColors.textSecondaryLight, label: 'Booked'),
          const AppSizedBox(width: 16),
          _legendItem(color: kOrange, label: 'Selected'),
          const AppSizedBox(width: 16),
          _legendItem(color: AppColors.error.withOpacity(0.5), label: 'Blocked'),
        ],
      ),
    );
  }

  static Widget _legendItem({required Color color, required String label}) {
    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const AppSizedBox(width: 5),
        AppText(
            text: label,
            textStyle: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
      ],
    );
  }

  // ── Slot Section ──────────────────────────────────────────────────────────

  static Widget buildSlotSection(
      List<TimeSlot> slots, Function(int) onToggleSlot) {
    return Container(
      color: AppColors.surfaceLight,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppText(
            text: 'EVENING SLOTS',
            align: TextAlign.left,
            textStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: AppColors.textPrimaryLight,
            ),
          ),
          const AppSizedBox(height: 14),
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
            itemBuilder: (ctx, i) => _buildSlotCard(slots[i], i, onToggleSlot),
          ),
        ],
      ),
    );
  }

  static Widget _buildSlotCard(
      TimeSlot slot, int index, Function(int) onToggleSlot) {
    final bool isBooked = slot.status == SlotStatus.booked;
    final bool isSelected = slot.status == SlotStatus.selected;
    final bool isBlocked = slot.status == SlotStatus.blocked;
    final bool isAvailable = slot.status == SlotStatus.available;

    Color bgColor;
    Color borderColor;
    Color textColor;
    Color timeColor;

    if (isSelected) {
      bgColor = kOrange;
      borderColor = kOrange;
      textColor = AppColors.white.withOpacity(0.7);
      timeColor = AppColors.white;
    } else if (isBooked || isBlocked) {
      bgColor = AppColors.bgLight;
      borderColor = AppColors.borderLight;
      textColor = AppColors.textSecondaryLight.withOpacity(0.5);
      timeColor = AppColors.textSecondaryLight.withOpacity(0.5);
    } else {
      bgColor = AppColors.surfaceLight;
      borderColor = AppColors.borderLight;
      textColor = AppColors.textSecondaryLight;
      timeColor = AppColors.textPrimaryLight;
    }

    return GestureDetector(
      onTap: () => onToggleSlot(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: kOrange.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3))
                ]
              : [],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      text: slot.startTime,
                      textStyle: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: timeColor,
                      ),
                    ),
                    const AppSizedBox(height: 1),
                    AppText(
                      text: slot.endTime,
                      textStyle: TextStyle(fontSize: 11, color: textColor),
                    ),
                  ],
                ),
                // Status dot
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? AppColors.white
                        : isAvailable
                            ? AppColors.success
                            : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
            if (isBooked)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.bgLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: AppText(
                  text: 'Booked',
                  textStyle: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondaryLight,
                      fontWeight: FontWeight.w500),
                ),
              )
            else
              AppText(
                text: '₹${slot.price.toStringAsFixed(0)}',
                textStyle: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? AppColors.white : kOrange,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Bottom Bar ────────────────────────────────────────────────────────────

  static Widget buildBottomBar(List<TimeSlot> selectedSlots,
      DateItem activeDate, double totalPrice, VoidCallback onConfirm) {
    if (selectedSlots.isEmpty) return const SizedBox.shrink();

    final firstSlot = selectedSlots.first;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.10),
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
              const AppText(
                text: 'SELECTED SLOTS',
                textStyle: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: AppColors.textSecondaryLight,
                ),
              ),
              const AppText(
                text: 'TOTAL PRICE',
                textStyle: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: AppColors.textSecondaryLight,
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
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimaryLight,
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

  static Widget buildDescriptionSection(String? description) {
    if (description == null || description.isEmpty) return const SizedBox.shrink();

    return Container(
      color: AppColors.surfaceLight,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppText(
            text: 'DESCRIPTION',
            align: TextAlign.left,
            textStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: AppColors.textPrimaryLight,
            ),
          ),
          const AppSizedBox(height: 12),
          AppText(
            text: description,
            align: TextAlign.left,
            textStyle: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  // ── Amenities Section ──────────────────────────────────────────────────────

  static Widget buildAmenitiesSection(List<String>? amenities) {
    if (amenities == null || amenities.isEmpty) return const SizedBox.shrink();

    return Container(
      color: AppColors.surfaceLight,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppText(
            text: 'AMENITIES',
            align: TextAlign.left,
            textStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: AppColors.textPrimaryLight,
            ),
          ),
          const AppSizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: amenities.map((a) => _amenityChip(a)).toList(),
          ),
        ],
      ),
    );
  }

  static Widget _amenityChip(String label) {
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
        color: AppColors.bgLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(icon: icon, size: 16, color: kOrange),
          const AppSizedBox(width: 8),
          AppText(
            text: label,
            align: TextAlign.left,
            textStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimaryLight,
            ),
          ),
        ],
      ),
    );
  }

  // ── Address & Map Section ──────────────────────────────────────────────────

  static Widget buildMapSection(GroundModel ground) {
    return Container(
      color: AppColors.surfaceLight,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppText(
            text: 'LOCATION',
            align: TextAlign.left,
            textStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: AppColors.textPrimaryLight,
            ),
          ),
          const AppSizedBox(height: 12),
          GestureDetector(
            onTap: () => _openMap(ground.latitude, ground.longitude),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bgLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
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
                              textStyle: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimaryLight,
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
                      const HugeIcon(
                        icon: HugeIcons.strokeRoundedArrowRight01,
                        size: 18,
                        color: AppColors.textSecondaryLight,
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
                                  position: LatLng(ground.latitude, ground.longitude),
                                ),
                              },
                              zoomControlsEnabled: false,
                              myLocationButtonEnabled: false,
                              liteModeEnabled: true, // IMPORTANT for performance in lists/scrolls
                            ),
                          ),

                          /// Overlay Button (Open in Maps)
                          Positioned.fill(
                            child: Center(
                              child: GestureDetector(
                                onTap: () => _openMap(ground.latitude, ground.longitude),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
    final String googleUrl = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    final Uri url = Uri.parse(googleUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $googleUrl';
    }
  }
}
