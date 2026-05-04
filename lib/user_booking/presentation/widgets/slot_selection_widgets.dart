import 'dart:ui' as ui;
import 'package:turfpro/common/constants/colors.dart';
import 'package:turfpro/user_booking/constants/widgets/app_sizedBox.dart';
import 'package:turfpro/user_booking/constants/widgets/app_text.dart';
import 'package:turfpro/user_booking/data/models/ground_model.dart';
import 'package:turfpro/user_booking/presentation/blocs/slot_selection/slot_selection_state.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:turfpro/user_booking/constants/widgets/app_network_image.dart';
import 'package:turfpro/user_booking/domain/models/slot_models.dart';
import 'package:turfpro/user_booking/data/models/review_model.dart';
import 'package:turfpro/user_booking/presentation/widgets/review_widgets.dart';
import 'package:turfpro/utils/toast_util.dart';
import 'package:turfpro/user_booking/constants/widgets/app_button.dart';
import 'package:shimmer/shimmer.dart';

class SlotSelectionWidgets {
  static const Color kOrange = AppColors.accentOrange;

  static Widget buildHeader(BuildContext context, GroundModel? ground,
      {bool isSaved = false, VoidCallback? onToggleFav, String? title}) {
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
                  text: title ?? ground?.name ?? 'Loading Turf...',
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
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    const AppSizedBox(width: 4),
                    Flexible(
                      child: AppText(
                        text: ground?.address ?? 'Loading Address...',
                        align: TextAlign.left,
                        textStyle: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
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

  static Widget buildSportSelection(BuildContext context, SlotSelectionState state,
      {required Function(String) onSportChanged}) {
    if (state.availableSports.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(
            bottom: BorderSide(color: theme.dividerColor.withOpacity(0.1))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: AppText(
              text: "SELECT SPORT",
              textStyle: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
                color: colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isDark
                    ? theme.cardColor.withOpacity(0.3)
                    : theme.scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: theme.dividerColor.withOpacity(isDark ? 0.1 : 0.05),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: state.availableSports
                    .asMap()
                    .entries
                    .map((entry) {
                      final index = entry.key;
                      final sport = entry.value;
                      final isSel = sport == state.selectedSport;
                      final color = _getSportColor(sport);

                      return [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => onSportChanged(sport),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isSel
                                    ? (isDark
                                        ? color.withOpacity(0.15)
                                        : color.withOpacity(0.1))
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSel
                                      ? color.withOpacity(0.8)
                                      : colorScheme.onSurface
                                          .withOpacity(isDark ? 0.2 : 0.1),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _getSportIcon(sport),
                                    size: 16,
                                    color: isSel
                                        ? color
                                        : colorScheme.onSurface
                                            .withOpacity(isDark ? 0.5 : 0.4),
                                  ),
                                  const AppSizedBox(width: 10),
                                  Flexible(
                                    child: AppText(
                                      text: sport,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textStyle: TextStyle(
                                        fontSize: 13,
                                        fontWeight: isSel
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                        color: isSel
                                            ? color
                                            : colorScheme.onSurface
                                                .withOpacity(
                                                    isDark ? 0.5 : 0.4),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (index < state.availableSports.length - 1)
                          Container(
                            width: 1,
                            height: 24,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            color: colorScheme.onSurface
                                .withOpacity(isDark ? 0.15 : 0.1),
                          ),
                      ];
                    })
                    .expand((x) => x)
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildGroundSelection(
      BuildContext context, SlotSelectionState state,
      {required Function(GroundModel) onTurfChanged}) {
    if (state.selectedSport == null || state.availableTurfs.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      color: theme.cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: AppText(
              text: "SELECT GROUND",
              textStyle: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
                color: colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ),
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: state.availableTurfs.length,
              itemBuilder: (context, index) {
                final turf = state.availableTurfs[index];
                final isSelected = state.selectedTurf?.id == turf.id;
                final isAvailable = turf.isAvailable;

                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  child: GestureDetector(
                    onTap: isAvailable ? () => onTurfChanged(turf) : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primaryDarkGreen
                            : (isAvailable
                                ? AppColors.primaryDarkGreen.withOpacity(0.05)
                                : Colors.grey.withOpacity(0.1)),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primaryDarkGreen
                              : (isAvailable
                                  ? AppColors.primaryDarkGreen
                                      .withOpacity(0.2)
                                  : Colors.grey.withOpacity(0.3)),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: isSelected
                                ? Colors.white
                                : (isAvailable
                                    ? AppColors.primaryDarkGreen
                                    : Colors.grey),
                          ),
                          const AppSizedBox(width: 8),
                          AppText(
                            text: turf.name,
                            textStyle: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Colors.white
                                  : (isAvailable
                                      ? AppColors.primaryDarkGreen
                                      : Colors.grey),
                              decoration: isAvailable
                                  ? null
                                  : TextDecoration.lineThrough,
                            ),
                          ),
                          if (!isAvailable) ...[
                            const AppSizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const AppText(
                                text: "BOOKED",
                                textStyle: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.red),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const AppSizedBox(height: 16),
        ],
      ),
    );
  }

  static Widget buildSelectionSummary(
      BuildContext context, SlotSelectionState state,
      {VoidCallback? onChangeSport, VoidCallback? onChangeTurf}) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(
            bottom: BorderSide(color: theme.dividerColor.withOpacity(0.1))),
      ),
      child: Row(
        children: [
          if (state.selectedSport != null)
            GestureDetector(
              onTap: onChangeSport,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _getSportColor(state.selectedSport!).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: _getSportColor(state.selectedSport!)
                          .withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(_getSportIcon(state.selectedSport!),
                        size: 16, color: _getSportColor(state.selectedSport!)),
                    const AppSizedBox(width: 8),
                    AppText(
                      text: state.selectedSport!,
                      textStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _getSportColor(state.selectedSport!)),
                    ),
                    const AppSizedBox(width: 4),
                    const Icon(Icons.keyboard_arrow_down,
                        size: 14, color: Colors.grey),
                  ],
                ),
              ),
            ),
          if (state.selectedTurf != null) ...[
            const AppSizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: onChangeTurf,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryDarkGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.primaryDarkGreen.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 16, color: AppColors.primaryDarkGreen),
                      const AppSizedBox(width: 8),
                      Expanded(
                        child: AppText(
                          text: state.selectedTurf!.name,
                          textStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryDarkGreen),
                          maxLines: 1,
                        ),
                      ),
                      const AppSizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down,
                          size: 14, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static Widget buildStepIndicator(
      BuildContext context, int currentStep, SlotSelectionState state) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Widget buildStep(int index, String label, bool isCompleted, bool isActive) {
      return Expanded(
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                    child: Divider(
                        color: index == 0
                            ? Colors.transparent
                            : (isActive || isCompleted
                                ? AppColors.primaryDarkGreen
                                : Colors.grey.withOpacity(0.3)),
                        thickness: 2)),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primaryDarkGreen
                        : (isCompleted
                            ? AppColors.primaryDarkGreen
                            : theme.cardColor),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isActive || isCompleted
                          ? AppColors.primaryDarkGreen
                          : Colors.grey.withOpacity(0.3),
                      width: 2,
                    ),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                                color:
                                    AppColors.primaryDarkGreen.withOpacity(0.3),
                                blurRadius: 8,
                                spreadRadius: 1)
                          ]
                        : null,
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : AppText(
                            text: (index + 1).toString(),
                            textStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isActive ? Colors.white : Colors.grey,
                            ),
                          ),
                  ),
                ),
                Expanded(
                    child: Divider(
                        color: index == 2
                            ? Colors.transparent
                            : (isCompleted && currentStep > index
                                ? AppColors.primaryDarkGreen
                                : Colors.grey.withOpacity(0.3)),
                        thickness: 2)),
              ],
            ),
            const AppSizedBox(height: 4),
            AppText(
              text: label,
              textStyle: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? AppColors.primaryDarkGreen : Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      color: theme.cardColor,
      child: Row(
        children: [
          buildStep(0, "SPORT", state.selectedSport != null, currentStep == 0),
          buildStep(1, "GROUND", state.selectedTurf != null, currentStep == 1),
          buildStep(2, "SLOTS", false, currentStep == 2),
        ],
      ),
    );
  }

  static Widget buildSportSelectionGrid(
      BuildContext context, List<String> sports, Function(String) onSelect) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppText(
            text: "WHAT ARE YOU PLAYING TODAY?",
            textStyle: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.5),
          ),
          const AppSizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sports.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
            ),
            itemBuilder: (context, index) {
              final sport = sports[index];
              final color = _getSportColor(sport);
              return GestureDetector(
                onTap: () => onSelect(sport),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color.withOpacity(0.8),
                        color,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      )
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -10,
                        bottom: -10,
                        child: Icon(
                          _getSportIcon(sport),
                          size: 80,
                          color: Colors.white.withOpacity(0.15),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _getSportIcon(sport),
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const Spacer(),
                            AppText(
                              text: sport.toUpperCase(),
                              textStyle: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  static Widget buildTurfSelectionList(BuildContext context, String sport,
      List<GroundModel> turfs, Function(GroundModel) onSelect) {
    final theme = Theme.of(context);
    final title =
        sport == 'Cricket' ? 'AVAILABLE BOX GROUNDS' : 'AVAILABLE TURFS';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            text: title,
            textStyle: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.5),
          ),
          const AppSizedBox(height: 20),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: turfs.length,
            itemBuilder: (context, index) {
              final turf = turfs[index];
              return GestureDetector(
                onTap: () => onSelect(turf),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            AppNetworkImage(
                              imageUrl: turf.imageUrl,
                              height: 140,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                            if (turf.rating >= 4.5)
                              Positioned(
                                top: 12,
                                left: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.star,
                                          color: Colors.amber, size: 14),
                                      AppSizedBox(width: 4),
                                      AppText(
                                        text: "TOP RATED",
                                        textStyle: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            Positioned(
                              bottom: 12,
                              right: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryDarkGreen,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: AppText(
                                  text: "₹${turf.pricePerHour}/hr",
                                  textStyle: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AppText(
                                      text: turf.name,
                                      textStyle: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w800),
                                    ),
                                    const AppSizedBox(height: 6),
                                    Row(
                                      children: [
                                        ..._getAmenityIcons(turf.amenities)
                                            .take(4),
                                        if ((turf.amenities?.length ?? 0) > 4)
                                          AppText(
                                            text:
                                                "+${turf.amenities!.length - 4}",
                                            textStyle: const TextStyle(
                                                fontSize: 10,
                                                color: Colors.grey),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryDarkGreen
                                      .withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.arrow_forward_ios,
                                    size: 14,
                                    color: AppColors.primaryDarkGreen),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  static List<Widget> _getAmenityIcons(List<String>? amenities) {
    if (amenities == null) return [];
    return amenities.map((a) {
      IconData icon;
      switch (a.toLowerCase()) {
        case 'wifi':
          icon = Icons.wifi;
          break;
        case 'parking':
          icon = Icons.local_parking;
          break;
        case 'water':
          icon = Icons.water_drop;
          break;
        case 'washroom':
          icon = Icons.wc;
          break;
        case 'changing room':
          icon = Icons.door_front_door;
          break;
        default:
          icon = Icons.check_circle_outline;
      }
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Icon(icon, size: 14, color: Colors.grey),
      );
    }).toList();
  }

  static Color _getSportColor(String sport) {
    switch (sport.toLowerCase()) {
      case 'cricket':
        return const Color(0xFF2E7D32); // Dark Green
      case 'football':
        return const Color(0xFF1B5E20); // Even Darker Green
      case 'badminton':
        return const Color(0xFF1976D2); // Blue
      case 'tennis':
        return const Color(0xFFC0CA33); // Lime
      case 'basketball':
        return const Color(0xFFE65100); // Orange
      default:
        return AppColors.primaryDarkGreen;
    }
  }

  static IconData _getSportIcon(String sport) {
    switch (sport.toLowerCase()) {
      case 'cricket':
        return Icons.sports_cricket;
      case 'football':
        return Icons.sports_soccer;
      case 'badminton':
        return Icons.sports_tennis;
      case 'tennis':
        return Icons.sports_tennis;
      case 'volleyball':
        return Icons.sports_volleyball;
      case 'basketball':
        return Icons.sports_basketball;
      default:
        return Icons.sports_score;
    }
  }

  // ── Turf Image Card ───────────────────────────────────────────────────────

  static Widget buildTurfImage(BuildContext context, GroundModel? ground,
      {double? rating, int? totalReviews}) {
    final theme = Theme.of(context);
    return Container(
      height: 175,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.brightness == Brightness.dark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.08),
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
                  Colors.black.withValues(alpha: 0.4),
                ],
              ),
            ),
          ),
          // Badges
          if ((totalReviews ?? ground?.totalReviews ?? 0) > 0)
            Positioned(
              bottom: 12,
              left: 12,
              child: _badge(
                icon: HugeIcons.strokeRoundedStar,
                iconColor: AppColors.goldenYellow,
                text:
                    '${(rating ?? ground?.rating ?? 0.0).toStringAsFixed(1)}  (${(totalReviews ?? ground?.totalReviews ?? 0)} REVIEWS)',
                bgColor: AppColors.black.withValues(alpha: 0.55),
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
              textColor: Colors.white,
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
                      duration: const Duration(milliseconds: 150),
                      width: 56,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: sel ? kOrange : kOrange.withValues(alpha: 0),
                        borderRadius: BorderRadius.circular(12),
                        border: sel
                            ? null
                            : Border.all(
                                color:
                                    theme.dividerColor.withValues(alpha: 0.5)),
                      ),
                      child: Column(
                        children: [
                          AppText(
                            text: d.day,
                            textStyle: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: sel
                                  ? Colors.white.withValues(alpha: 0.7)
                                  : colorScheme.onSurface
                                      .withValues(alpha: 0.5),
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
    final periods = ['Midnight', 'Morning', 'Evening', 'Night'];

    return Container(
      color: colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: periods.map((p) {
          final isSel = p == selectedPeriod;
          final accentColor = isDark ? AppColors.primaryLightGreen : AppColors.primaryDarkGreen;
          
          return Padding(
            padding: const EdgeInsets.only(right: 24),
            child: GestureDetector(
              onTap: () => onSelect(p),
              behavior: HitTestBehavior.opaque,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Radio Indicator
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSel ? accentColor : colorScheme.onSurface.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: isSel ? 10 : 0,
                        height: isSel ? 10 : 0,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accentColor,
                        ),
                      ),
                    ),
                  ),
                  const AppSizedBox(width: 10),
                  // Period Text
                  AppText(
                    text: p,
                    textStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                      color: isSel ? colorScheme.onSurface : colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
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
              childAspectRatio: 1.5,
            ),
            itemBuilder: (ctx, i) =>
                _buildSlotCard(context, slots[i], i, onToggleSlot),
          ),
        ],
      ),
    );
  }

  static Widget buildSlotShimmer(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      color: theme.colorScheme.surface,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      child: Shimmer.fromColors(
        baseColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[300]!,
        highlightColor:
            isDark ? Colors.white.withOpacity(0.1) : Colors.grey[100]!,
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 6,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
          ),
          itemBuilder: (ctx, i) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Start Time Placeholder
                Container(
                  width: 60,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Subtitle Placeholder
                    Container(
                      width: 80,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Price Placeholder
                    Container(
                      width: 50,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _buildSlotCard(BuildContext context, TimeSlot slot, int index,
      Function(int) onToggleSlot) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final bool isBooked = slot.status == SlotStatus.booked;
    final bool isSelected = slot.status == SlotStatus.selected;
    final bool isAdvance = slot.status == SlotStatus.advance;
    final bool isAvailable = slot.status == SlotStatus.available;

    Color borderColor;
    Color timeColor = colorScheme.onSurface;
    Color subColor = colorScheme.onSurface.withValues(alpha: 0.4);
    Color priceColor =
        isDark ? AppColors.primaryLightGreen : AppColors.primaryDarkGreen;
    IconData? statusIcon;
    Color? iconColor;

    if (isSelected) {
      borderColor = AppColors.primaryDarkGreen;
      statusIcon = Icons.radio_button_checked;
      iconColor = AppColors.accentOrange;
      priceColor = AppColors.accentOrange;
    } else if (isBooked) {
      borderColor = Colors.transparent;
      timeColor = colorScheme.onSurface.withOpacity(0.35);
      subColor = colorScheme.onSurface.withOpacity(0.25);
      priceColor = colorScheme.onSurface.withOpacity(0.25);
      statusIcon = null;
      iconColor = null;
    } else if (isAdvance) {
      borderColor = AppColors.goldenYellow;
      statusIcon = Icons.info;
      iconColor = AppColors.goldenYellow;
    } else {
      // Available
      borderColor =
          AppColors.slotAvailableBorder.withOpacity(isDark ? 0.3 : 0.15);
      statusIcon = Icons.check_circle;
      iconColor = AppColors.slotAvailableBorder;
    }

    return GestureDetector(
      key: ValueKey(slot.startTime),
      onTap: () {
        if (isBooked) {
          ToastUtil.show(
            context,
            message: "Oops! You missed that opportunity.",
            type: ToastType.info,
          );
        } else {
          onToggleSlot(index);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isBooked
              ? (isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.grey.withOpacity(0.08))
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isBooked ? Colors.transparent : borderColor, width: 2),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryDarkGreen.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                    const AppSizedBox(height: 4),
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
                shadowColor: kOrange.withValues(alpha: 0.4),
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
                      color: Colors.white,
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

  static Widget buildMapSection(BuildContext context,
      {required double latitude,
      required double longitude,
      required String address}) {
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
            onTap: () => _openMap(latitude, longitude),
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
                          color: kOrange.withValues(alpha: 0.1),
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
                              text: address,
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
                        color: colorScheme.onSurface.withValues(alpha: 0.4),
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
                              target: LatLng(latitude, longitude),
                              zoom: 15,
                            ),
                            markers: {
                              Marker(
                                markerId: const MarkerId('ground'),
                                position:
                                    LatLng(latitude, longitude),
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
                                  _openMap(latitude, longitude),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.15),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    )
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const HugeIcon(
                                      icon: HugeIcons.strokeRoundedLocation01,
                                      size: 16,
                                      color: kOrange,
                                    ),
                                    const AppSizedBox(width: 8),
                                    AppText(
                                      text: 'Open in Maps',
                                      align: TextAlign.left,
                                      textStyle: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
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

  static Widget buildReviewSection(
      BuildContext context, List<ReviewModel> reviews, bool isLoading) {
    if (!isLoading && reviews.isEmpty) return const SizedBox.shrink();

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText(
                text: 'REVIEWS',
                align: TextAlign.left,
                textStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: colorScheme.onSurface,
                ),
              ),
              if (!isLoading)
                AppText(
                  text: '${reviews.length} Reviews',
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: kOrange,
                  ),
                ),
            ],
          ),
          const AppSizedBox(height: 16),
          if (isLoading)
            const Center(child: CircularProgressIndicator(color: kOrange))
          else ...[
            if (reviews.isNotEmpty) ...[
              Row(
                children: [
                  const HugeIcon(
                    icon: HugeIcons.strokeRoundedStar,
                    size: 14,
                    color: AppColors.goldenYellow,
                  ),
                  const AppSizedBox(width: 4),
                  AppText(
                    text: (reviews.fold<double>(0, (sum, r) => sum + r.rating) /
                            reviews.length)
                        .toStringAsFixed(1),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.goldenYellow,
                    ),
                  ),
                  const AppSizedBox(width: 4),
                  AppText(
                    text: 'Average Rating',
                    textStyle: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withOpacity(0.5),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const AppSizedBox(height: 16),
            ],
            ReviewList(reviews: reviews.take(3).toList()),
          ],
        ],
      ),
    );
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
              color: colorScheme.onSurface.withValues(alpha: 0.6),
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
                color: colorScheme.onSurface.withValues(alpha: 0.6),
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
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
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
