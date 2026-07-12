import 'dart:ui' as ui;
import 'package:turfpro/common/constants/colors.dart';
import 'package:turfpro/user_booking/constants/widgets/app_sizedBox.dart';
import 'package:turfpro/user_booking/constants/widgets/app_text.dart';
import 'package:turfpro/user_booking/data/models/ground_model.dart';
import 'package:turfpro/user_booking/presentation/blocs/slot_selection/slot_selection_state.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:turfpro/user_booking/presentation/blocs/location/location_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/widgets/app_network_image.dart';
import 'package:turfpro/user_booking/domain/models/slot_models.dart';
import 'package:turfpro/user_booking/data/models/review_model.dart';
import 'package:turfpro/user_booking/presentation/widgets/review_widgets.dart';
import 'package:turfpro/utils/toast_util.dart';
import 'package:shimmer/shimmer.dart';
import 'ground_image_carousel.dart';

class SlotSelectionWidgets {
  static const Color kOrange = AppColors.accentOrange;

  static Widget buildHeader(BuildContext context, GroundModel? ground,
      {bool isSaved = false,
      VoidCallback? onToggleFav,
      VoidCallback? onShare,
      VoidCallback? onLocationTap,
      String? title}) {
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
                GestureDetector(
                  onTap: onLocationTap,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2.0),
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedLocation01,
                          size: 12,
                          color: onLocationTap != null
                              ? AppColors.primaryDarkGreen
                              : colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      const AppSizedBox(width: 4),
                      Flexible(
                        child: AppText(
                          text: (ground?.address != null &&
                                  ground!.address.isNotEmpty)
                              ? ground.address
                              : (ground != null && ground.city.isNotEmpty
                                  ? ground.city
                                  : 'Location unavailable'),
                          align: TextAlign.left,
                          textStyle: TextStyle(
                            fontSize: 12,
                            color: onLocationTap != null
                                ? AppColors.primaryDarkGreen
                                : colorScheme.onSurface.withValues(alpha: 0.6),
                            fontWeight: onLocationTap != null
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (onLocationTap != null) ...[
                        const AppSizedBox(width: 4),
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedArrowDown01,
                          size: 14,
                          color: AppColors.primaryDarkGreen,
                        ),
                      ],
                    ],
                  ),
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
            onPressed: onShare,
          ),
        ],
      ),
    );
  }

  static Widget buildSportSelection(
      BuildContext context, SlotSelectionState state,
      {required Function(String) onSportChanged}) {
    if (state.availableSports.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppText(
            text: "SELECT SPORT",
            textStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.5,
            ),
            itemCount: state.availableSports.length,
            itemBuilder: (context, index) {
              final sport = state.availableSports[index];
              final isSel = sport == state.selectedSport;

              return GestureDetector(
                onTap: () => onSportChanged(sport),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSel
                        ? AppColors.primaryDarkGreen.withOpacity(0.05)
                        : Colors.white,
                    border: Border.all(
                      color: isSel
                          ? AppColors.primaryDarkGreen
                          : Theme.of(context).dividerColor.withOpacity(0.2),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isSel
                              ? AppColors.primaryDarkGreen
                              : AppColors.primaryDarkGreen.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            _getSportImage(sport),
                            width: 24,
                            height: 24,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Icon(Icons.sports, size: 18, color: isSel ? Colors.white : AppColors.primaryDarkGreen),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: AppText(
                          text: sport,
                          textStyle: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
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

  static Widget buildSportGroundShimmer(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sport Selection Shimmer
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.cardColor,
              border: Border(
                  bottom:
                      BorderSide(color: theme.dividerColor.withOpacity(0.1))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Container(width: 100, height: 12, color: Colors.white),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Row(
                    children: List.generate(
                        4,
                        (index) => Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: Container(
                                width: 100,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            )),
                  ),
                ),
              ],
            ),
          ),

          // Ground Selection Shimmer
          Container(
            width: double.infinity,
            color: theme.cardColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Container(width: 120, height: 12, color: Colors.white),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Row(
                    children: List.generate(
                        3,
                        (index) => Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: Container(
                                width: 150,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            )),
                  ),
                ),
              ],
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppText(
            text: "SELECT GROUND",
            textStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: state.availableTurfs.length,
              itemBuilder: (context, index) {
                final turf = state.availableTurfs[index];
                final isSelected = state.selectedTurf?.id == turf.id;
                final isAvailable = turf.isAvailable;

                return GestureDetector(
                  onTap: isAvailable ? () => onTurfChanged(turf) : null,
                  child: Container(
                    width: 260,
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryDarkGreen
                            : Theme.of(context).dividerColor.withOpacity(0.2),
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.stadium_outlined,
                          color: isSelected
                              ? AppColors.primaryDarkGreen
                              : Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6),
                          size: 24,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AppText(
                                text: turf.name,
                                textStyle: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? AppColors.primaryDarkGreen
                                      : Theme.of(context).colorScheme.onSurface,
                                  decoration: isAvailable
                                      ? null
                                      : TextDecoration.lineThrough,
                                ),
                                maxLines: 1,
                              ),
                              AppText(
                                text: turf.categories.isNotEmpty
                                    ? turf.categories.first
                                    : "Turf Pitch",
                                textStyle: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle,
                              color: AppColors.primaryDarkGreen, size: 24)
                        else
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Theme.of(context)
                                    .dividerColor
                                    .withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
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
            bottom:
                BorderSide(color: theme.dividerColor.withValues(alpha: 0.1))),
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
                  color: _getSportColor(state.selectedSport!)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: _getSportColor(state.selectedSport!)
                          .withValues(alpha: 0.3)),
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
                    color: AppColors.primaryDarkGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color:
                            AppColors.primaryDarkGreen.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const HugeIcon(
                          icon: HugeIcons.strokeRoundedLocation01,
                          size: 16,
                          color: AppColors.primaryDarkGreen),
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
                                : Colors.grey.withValues(alpha: 0.3)),
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
                          : Colors.grey.withValues(alpha: 0.3),
                      width: 2,
                    ),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                                color: AppColors.primaryDarkGreen
                                    .withValues(alpha: 0.3),
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
                                : Colors.grey.withValues(alpha: 0.3)),
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
                        color.withValues(alpha: 0.8),
                        color,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
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
                          color: Colors.white.withValues(alpha: 0.15),
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
                                color: Colors.white.withValues(alpha: 0.2),
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
                        color: Colors.black.withValues(alpha: 0.04),
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
                                    color: Colors.black.withValues(alpha: 0.5),
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
                                      .withValues(alpha: 0.1),
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
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Icon(_getAmenityIconData(a), size: 14, color: Colors.grey),
      );
    }).toList();
  }

  static IconData _getAmenityIconData(String label) {
    switch (label.toLowerCase()) {
      case 'wifi':
        return Icons.wifi;
      case 'parking':
        return Icons.local_parking;
      case 'water':
      case 'drinking water':
        return Icons.water_drop;
      case 'washroom':
      case 'toilet':
        return Icons.wc;
      case 'changing room':
        return Icons.door_front_door;
      case 'cafeteria':
      case 'canteen':
        return Icons.restaurant;
      case 'first aid':
        return Icons.medical_services;
      case 'cctv':
        return Icons.videocam;
      default:
        return Icons.check_circle_outline;
    }
  }

  static dynamic getAmenityHugeIcon(String label) {
    switch (label.toLowerCase()) {
      case 'wifi':
        return HugeIcons.strokeRoundedWifi01;
      case 'parking':
        return HugeIcons.strokeRoundedCarParking01;
      case 'water':
      case 'drinking water':
        return HugeIcons.strokeRoundedDroplet;
      case 'washroom':
      case 'toilet':
        return HugeIcons.strokeRoundedToilet01;
      case 'changing room':
        return HugeIcons.strokeRoundedDoor01;
      case 'cafeteria':
      case 'canteen':
        return HugeIcons.strokeRoundedRestaurant01;
      case 'first aid':
        return HugeIcons.strokeRoundedFirstAidKit;
      case 'cctv':
        return HugeIcons.strokeRoundedCctvCamera;
      default:
        return HugeIcons.strokeRoundedCheckList;
    }
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

  static String _getSportImage(String sport) {
    switch (sport.toLowerCase()) {
      case 'cricket':
      case 'box_cricket':
        return 'assets/images/sports/sport6.png';
      case 'football':
        return 'assets/images/sports/sport1.png';
      case 'volleyball':
        return 'assets/images/sports/sport3.png';
      case 'pickleball':
        return 'assets/images/sports/sport4.png';
      case 'badminton':
        return 'assets/images/sports/sport5.png'; 
      case 'tennis':
        return 'assets/images/sports/sport2.png'; 
      default:
        return 'assets/images/sports/sport6.png';
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

  static double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295;
    var a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  static Widget buildVenueImageCarousel(
      BuildContext context, GroundModel? venue) {
    if (venue == null) return const SizedBox.shrink();
    return Stack(
      children: [
        SizedBox(
          height: 320,
          width: double.infinity,
          child: GroundImageCarousel(
            images: venue.images,
            fallbackImageUrl: venue.imageUrl,
            height: 320,
            borderRadius: BorderRadius.zero,
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withOpacity(0.8),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.5],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 24,
          left: 24,
          right: 24,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      text: venue.name,
                      textStyle: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        Expanded(
                          child: AppText(
                            text: venue.address.isNotEmpty
                                ? venue.address
                                : venue.city,
                            textStyle: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () async {
                  final url =
                      "geo:${venue.latitude},${venue.longitude}?q=${venue.latitude},${venue.longitude}(${Uri.encodeComponent(venue.name)})";
                  if (await canLaunchUrlString(url)) {
                    await launchUrlString(url);
                  } else {
                    final webUrl =
                        "https://www.google.com/maps/search/?api=1&query=${venue.latitude},${venue.longitude}";
                    if (await canLaunchUrlString(webUrl)) {
                      await launchUrlString(webUrl);
                    }
                  }
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const HugeIcon(
                          icon: HugeIcons.strokeRoundedLocation01,
                          color: AppColors.goldenYellow,
                          size: 18),
                      const SizedBox(width: 8),
                      AppText(
                        text: "Open in Maps",
                        textStyle: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Widget buildQuickSummarySection(
      BuildContext context, GroundModel? venue) {
    if (venue == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.goldenYellow.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        color: AppColors.goldenYellow, size: 18),
                    const SizedBox(width: 4),
                    AppText(
                      text: venue.rating.toStringAsFixed(1),
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.goldenYellow,
                      ),
                    ),
                  ],
                ),
              ),
              if (venue.totalReviews > 0) ...[
                const SizedBox(width: 12),
                Container(
                  height: 16,
                  width: 1,
                  color: Theme.of(context).dividerColor.withOpacity(0.2),
                ),
                const SizedBox(width: 12),
                AppText(
                  text: "${venue.totalReviews} Reviews",
                  textStyle: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                  ),
                ),
              ],
            ],
          ),
          BlocBuilder<LocationCubit, LocationState>(
            builder: (context, state) {
              final double? originLat = state.gpsLatitude ?? state.latitude;
              final double? originLng = state.gpsLongitude ?? state.longitude;

              if (originLat != null && originLng != null) {
                final distance = _calculateDistance(
                  originLat,
                  originLng,
                  venue.latitude,
                  venue.longitude,
                );
                return AppText(
                  text: "${distance.toStringAsFixed(1)} km away",
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDarkGreen,
                  ),
                );
              }
              return const SizedBox();
            },
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
    final periods = ['Midnight', 'Day', 'Evening', 'Night'];

    return Container(
      width: double.infinity,
      color: colorScheme.surface,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: periods.asMap().entries.map((entry) {
            final p = entry.value;
            final index = entry.key;
            final isSel = p == selectedPeriod;
            final accentColor = isDark
                ? AppColors.primaryLightGreen
                : AppColors.primaryDarkGreen;

            return Padding(
              padding:
                  EdgeInsets.only(right: index == periods.length - 1 ? 0 : 10),
              child: GestureDetector(
                onTap: () => onSelect(p),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSel
                        ? accentColor
                        : accentColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSel
                          ? accentColor
                          : accentColor.withValues(alpha: 0.1),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getPeriodIcon(p),
                        size: 14,
                        color: isSel
                            ? (isDark ? Colors.black : Colors.white)
                            : colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                      const SizedBox(width: 8),
                      AppText(
                        text: p,
                        textStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: isSel ? FontWeight.w700 : FontWeight.w600,
                          color: isSel
                              ? (isDark ? Colors.black : Colors.white)
                              : colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  static IconData _getPeriodIcon(String period) {
    switch (period.toLowerCase()) {
      case 'midnight':
        return Icons.nights_stay;
      case 'day':
        return Icons.wb_sunny;
      case 'evening':
        return Icons.wb_twilight;
      case 'night':
        return Icons.bedtime;
      default:
        return Icons.access_time;
    }
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

  static Widget buildErrorWidget(
      BuildContext context, String message, VoidCallback onRetry) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.wifi_off_rounded,
              size: 48,
              color: Colors.red,
            ),
          ),
          const AppSizedBox(height: 24),
          AppText(
            text: "Connection Error",
            textStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const AppSizedBox(height: 12),
          AppText(
            text: message,
            textStyle: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
              height: 1.5,
            ),
            align: TextAlign.center,
          ),
          const AppSizedBox(height: 32),
          SizedBox(
            width: 160,
            child: ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDarkGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.refresh_rounded, size: 20),
                  SizedBox(width: 8),
                  AppText(
                    text: "Retry",
                    textStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
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

  static Widget buildSlotShimmer(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      color: theme.colorScheme.surface,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      child: Shimmer.fromColors(
        baseColor:
            isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[300]!,
        highlightColor:
            isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey[100]!,
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
      timeColor = colorScheme.onSurface.withValues(alpha: 0.35);
      subColor = colorScheme.onSurface.withValues(alpha: 0.25);
      priceColor = colorScheme.onSurface.withValues(alpha: 0.25);
      statusIcon = null;
      iconColor = null;
    } else if (isAdvance) {
      borderColor = AppColors.goldenYellow;
      statusIcon = Icons.info;
      iconColor = AppColors.goldenYellow;
    } else {
      // Available
      borderColor =
          AppColors.slotAvailableBorder.withValues(alpha: isDark ? 0.3 : 0.15);
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
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.grey.withValues(alpha: 0.08))
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
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.03),
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
            color: Colors.black.withValues(
                alpha: theme.brightness == Brightness.dark ? 0.3 : 0.1),
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
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              AppText(
                text: 'TOTAL PRICE',
                textStyle: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
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
    if (amenities == null || amenities.isEmpty) {
      return const SizedBox.shrink();
    }
    
    final displayAmenities = amenities.take(4).toList();
    final hasMore = amenities.length > 4;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText(
                text: "Amenities",
                textStyle: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              if (hasMore)
                GestureDetector(
                  onTap: () => _showAmenitiesBottomSheet(context, amenities),
                  child: const AppText(
                    text: "View all",
                    textStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryDarkGreen,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 16,
              childAspectRatio: 0.85,
            ),
            itemCount: displayAmenities.length,
            itemBuilder: (context, index) {
              final amenity = displayAmenities[index];
              return Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: HugeIcon(
                        icon: getAmenityHugeIcon(amenity),
                        color: AppColors.primaryDarkGreen,
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: AppText(
                      text: amenity.toUpperCase(),
                      align: TextAlign.center,
                      textStyle: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.8),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  static void _showAmenitiesBottomSheet(BuildContext context, List<String> amenities) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const AppText(
                    text: "All Amenities",
                    textStyle: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.85,
                ),
                itemCount: amenities.length,
                itemBuilder: (context, index) {
                  final amenity = amenities[index];
                  return Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: HugeIcon(
                            icon: getAmenityHugeIcon(amenity),
                            color: AppColors.primaryDarkGreen,
                            size: 28,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: AppText(
                          text: amenity.toUpperCase(),
                          align: TextAlign.center,
                          textStyle: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.8),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  static Widget amenityChip(BuildContext context, String label) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final icon = getAmenityHugeIcon(label);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryDarkGreen.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryDarkGreen.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(
            icon: icon,
            size: 16,
            color: AppColors.primaryDarkGreen,
          ),
          const AppSizedBox(width: 8),
          AppText(
            text: label,
            textStyle: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withValues(alpha: 0.8),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppText(
            text: "LOCATION",
            textStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () async {
              final url =
                  "geo:$latitude,$longitude?q=$latitude,$longitude(${Uri.encodeComponent(address)})";
              if (await canLaunchUrlString(url)) {
                await launchUrlString(url);
              }
            },
            child: Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: Theme.of(context).dividerColor.withOpacity(0.2)),
                color: Colors.grey.withOpacity(0.1),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.5,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          image: const DecorationImage(
                            image: NetworkImage(
                                "https://maps.googleapis.com/maps/api/staticmap?center=0,0&zoom=15&size=600x300"), // Fallback dummy visual
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primaryDarkGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on,
                              color: Colors.red, size: 16),
                          const SizedBox(width: 8),
                          AppText(
                            text: address.length > 25
                                ? "${address.substring(0, 25)}..."
                                : address,
                            textStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
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

  static Widget _buildReviewCard(BuildContext context, ReviewModel review, int index) {
    // Dynamic color for avatar background
    final colors = [AppColors.primaryDarkGreen, Colors.orange, Colors.blue, Colors.purple];
    final color = colors[index % colors.length];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6F9), // Light greyish background from screenshot
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.primaryDarkGreen.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: AppText(
                        text: review.userName.length >= 2 
                          ? review.userName.substring(0, 2).toUpperCase()
                          : (review.userName.isNotEmpty ? review.userName[0].toUpperCase() : "?"),
                        textStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        text: review.userName,
                        textStyle: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      AppText(
                        text: "Recent", // In a real app, calculate time ago
                        textStyle: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: List.generate(5, (starIndex) {
                  return Icon(
                    Icons.star,
                    size: 14,
                    color: starIndex < review.rating
                        ? AppColors.goldenYellow
                        : Theme.of(context)
                            .dividerColor
                            .withOpacity(0.2),
                  );
                }),
              ),
            ],
          ),
          if (review.reviewText.isNotEmpty) ...[
            const SizedBox(height: 12),
            AppText(
              text: review.reviewText,
              textStyle: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withOpacity(0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static Widget buildReviewSection(
      BuildContext context, List<ReviewModel> reviews, bool isLoading) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (reviews.isEmpty) return const SizedBox.shrink();

    return _ReviewSectionWidget(reviews: reviews);
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

class _ReviewSectionWidget extends StatefulWidget {
  final List<ReviewModel> reviews;
  const _ReviewSectionWidget({required this.reviews});

  @override
  State<_ReviewSectionWidget> createState() => _ReviewSectionWidgetState();
}

class _ReviewSectionWidgetState extends State<_ReviewSectionWidget> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final averageRating =
        widget.reviews.fold(0.0, (sum, review) => sum + review.rating) /
            widget.reviews.length;
    
    final displayCount = _showAll ? widget.reviews.length : (widget.reviews.length > 2 ? 2 : widget.reviews.length);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText(
                text: "Reviews",
                textStyle: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.star,
                      color: AppColors.goldenYellow, size: 20),
                  const SizedBox(width: 6),
                  AppText(
                    text: averageRating.toStringAsFixed(1),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(width: 4),
                  AppText(
                    text: "(${widget.reviews.length})",
                    textStyle: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.5)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayCount,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return SlotSelectionWidgets._buildReviewCard(context, widget.reviews[index], index);
            },
          ),
          if (widget.reviews.length > 2 && !_showAll)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _showAll = true;
                    });
                  },
                  child: AppText(
                    text: "View all ${widget.reviews.length} reviews",
                    textStyle: const TextStyle(
                      color: AppColors.primaryDarkGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
