import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:turfpro/common/constants/colors.dart';
import 'package:turfpro/user_booking/constants/widgets/app_button.dart';
import 'package:turfpro/common/config/feature_config.dart';
import 'package:turfpro/user_booking/constants/widgets/app_sizedBox.dart';
import 'package:turfpro/user_booking/constants/widgets/app_text.dart';
import 'package:turfpro/user_booking/data/models/ground_model.dart';
import 'package:turfpro/user_booking/domain/models/slot_models.dart';
import 'package:turfpro/user_booking/domain/models/booking_arguments.dart';
import 'package:turfpro/user_booking/presentation/widgets/ground_image_carousel.dart';
import 'package:turfpro/user_booking/presentation/widgets/slot_selection_widgets.dart';

import 'package:turfpro/user_booking/presentation/blocs/slot_selection/slot_selection_cubit.dart';
import 'package:turfpro/user_booking/presentation/blocs/slot_selection/slot_selection_state.dart';

class BookingSummaryScreen extends StatelessWidget {
  const BookingSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final rawArgs = ModalRoute.of(context)?.settings.arguments;

    if (rawArgs == null || rawArgs is! BookingSummaryArguments) {
      return Scaffold(
        body: Center(
          child: AppText(text: "Invalid booking data"),
        ),
      );
    }

    final args = rawArgs;
    final ground = args.ground;
    final selectedSlots = args.selectedSlots;
    final basePrice = args.basePrice;
    final activeDate = args.activeDate;
    final selectedSport = args.selectedSport;
    final selectedPeriod = args.selectedPeriod;

    return BlocBuilder<SlotSelectionCubit, SlotSelectionState>(
      builder: (context, state) {
        const double platformFee = 25.0;

        // Loyalty Points Logic
        double pointsDiscount = 0.0;
        if (FeatureConfig.isLoyaltyEnabled) {
          bool canRedeem = state.availableLoyaltyPoints >= 50;
          if (state.useLoyaltyPoints && canRedeem) {
            double maxDiscount = basePrice * 0.5;
            pointsDiscount = state.availableLoyaltyPoints > maxDiscount 
                ? maxDiscount 
                : state.availableLoyaltyPoints.toDouble();
          }
        }
        // Wallet Balance Logic
        double walletDiscount = 0.0;
        if (FeatureConfig.isWalletEnabled && state.useWallet && state.walletBalance > 0) {
          double remainingAfterLoyalty = basePrice - pointsDiscount;
          walletDiscount = state.walletBalance > remainingAfterLoyalty 
              ? remainingAfterLoyalty 
              : state.walletBalance;
        }

        final double grandTotal = (basePrice - pointsDiscount - walletDiscount) + platformFee;

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios, color: colorScheme.onSurface),
              onPressed: () => Navigator.pop(context),
            ),
            title: AppText(
              text: "Booking Summary",
              textStyle: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ground Details Card
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Carousel Header
                        Stack(
                          children: [
                            GroundImageCarousel(
                              images: ground.images,
                              fallbackImageUrl: ground.imageUrl,
                              height: 180,
                              borderRadius: BorderRadius.zero,
                            ),
                            Positioned(
                              bottom: 12,
                              left: 14,
                              right: 14,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        const Icon(Icons.calendar_today_rounded, size: 14, color: Colors.white),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: AppText(
                                            text: "${activeDate.month} ${activeDate.date}, ${DateTime.now().year}",
                                            textStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                            maxLines: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.accentOrange,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: AppText(
                                      text: "${selectedSlots.length} Slots",
                                      textStyle: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        // Info Section
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        AppText(
                                          text: ground.name,
                                          textStyle: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: colorScheme.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            _buildBadge(
                                              text: selectedSport.toUpperCase(),
                                              color: AppColors.primaryDarkGreen,
                                            ),
                                            const SizedBox(width: 8),
                                            _buildBadge(
                                              text: selectedPeriod.toUpperCase(),
                                              color: AppColors.accentOrange,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  AppText(
                                    text: "₹${basePrice.toStringAsFixed(0)}",
                                    textStyle: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primaryDarkGreen,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  HugeIcon(
                                    icon: HugeIcons.strokeRoundedLocation01,
                                    size: 14,
                                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: AppText(
                                      text: ground.address,
                                      maxLines: 1,
                                      textStyle: TextStyle(
                                        fontSize: 12,
                                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (ground.amenities.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                AppText(
                                  text: "AMENITIES",
                                  textStyle: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                    color: colorScheme.onSurface.withValues(alpha: 0.4),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: ground.amenities.take(4).map((amenity) {
                                    return SlotSelectionWidgets.amenityChip(context, amenity);
                                  }).toList(),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const AppSizedBox(height: 24),

                // Selected Slots chips
                AppText(
                  text: "Selected Slots",
                  textStyle: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const AppSizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: selectedSlots.map((slot) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryDarkGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primaryDarkGreen.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.access_time_rounded, size: 14, color: AppColors.primaryDarkGreen),
                          const AppSizedBox(width: 6),
                          AppText(
                            text: slot.startTime,
                            textStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryDarkGreen,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const AppSizedBox(height: 28),

                // Loyalty Points Section
                if (FeatureConfig.isLoyaltyEnabled) ...[
                  AppText(
                    text: "Loyalty Rewards",
                    textStyle: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const AppSizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: state.useLoyaltyPoints 
                          ? AppColors.primaryDarkGreen 
                          : colorScheme.outline.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.goldenYellow.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.stars_rounded, color: AppColors.goldenYellow, size: 28),
                        ),
                        const AppSizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppText(
                                text: "Redeem Points",
                                textStyle: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              AppText(
                                text: state.availableLoyaltyPoints >= 50 
                                  ? "Use ${state.availableLoyaltyPoints} pts for ₹${pointsDiscount.toStringAsFixed(0)} off"
                                  : "Min. 50 points required",
                                textStyle: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: state.useLoyaltyPoints,
                          activeColor: AppColors.primaryDarkGreen,
                          onChanged: state.availableLoyaltyPoints >= 50 
                            ? (_) => context.read<SlotSelectionCubit>().toggleLoyaltyPoints() 
                            : null,
                        ),
                      ],
                    ),
                  ),
                  const AppSizedBox(height: 32),
                ],

                // Wallet Section
                if (FeatureConfig.isWalletEnabled) ...[
                  AppText(
                    text: "Wallet Balance",
                    textStyle: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const AppSizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: state.useWallet 
                          ? AppColors.primaryDarkGreen 
                          : colorScheme.outline.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.blue, size: 28),
                        ),
                        const AppSizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppText(
                                text: "Use Wallet Balance",
                                textStyle: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              AppText(
                                text: state.walletBalance > 0 
                                  ? "Available: ₹${state.walletBalance.toStringAsFixed(0)}"
                                  : "No balance available",
                                textStyle: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: state.useWallet,
                          activeColor: AppColors.primaryDarkGreen,
                          onChanged: state.walletBalance > 0 
                            ? (_) => context.read<SlotSelectionCubit>().toggleWallet() 
                            : null,
                        ),
                      ],
                    ),
                  ),
                  const AppSizedBox(height: 32),
                ],

                // Bill Details
                AppText(
                  text: "Bill Details",
                  textStyle: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const AppSizedBox(height: 16),
                _priceRow(context, label: "Base Amount", amount: basePrice),
                const AppSizedBox(height: 12),
                if (pointsDiscount > 0) ...[
                  _priceRow(context, label: "Loyalty Discount", amount: -pointsDiscount, isDiscount: true),
                  const AppSizedBox(height: 12),
                ],
                if (walletDiscount > 0) ...[
                  _priceRow(context, label: "Wallet Used", amount: -walletDiscount, isDiscount: true, isWallet: true),
                  const AppSizedBox(height: 12),
                ],
                _priceRow(context, label: "Platform Fee", amount: platformFee),
                const AppSizedBox(height: 12),
                _priceRow(context, label: "Taxes & Charges", amount: 0, isFree: true),
                const AppSizedBox(height: 20),
                const Divider(),
                const AppSizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppText(
                      text: "Grand Total",
                      textStyle: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    AppText(
                      text: "₹${grandTotal.toStringAsFixed(0)}",
                      textStyle: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppColors.accentOrange,
                      ),
                    ),
                  ],
                ),
                const AppSizedBox(height: 40),

                AppButton(
                  title: "Confirm & Proceed to Pay",
                  onTap: () {
                    // Pop this screen and return the final amount and points to the caller
                    Navigator.pop(context, {
                      'finalAmount': grandTotal,
                      'appliedPoints': state.useLoyaltyPoints ? pointsDiscount.toInt() : 0,
                      'appliedWallet': state.useWallet ? walletDiscount : 0.0,
                    });
                  },
                ),
                const AppSizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBadge({required String text, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: AppText(
        text: text,
        textStyle: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _priceRow(BuildContext context, {required String label, required double amount, bool isDiscount = false, bool isFree = false, bool isWallet = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppText(
          text: label,
          textStyle: TextStyle(
            fontSize: 14,
            color: colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        AppText(
          text: isFree ? "FREE" : "${isDiscount ? '- ' : ''}₹${amount.abs().toStringAsFixed(2)}",
          textStyle: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: isFree 
              ? Colors.green 
              : (isDiscount 
                  ? (isWallet ? Colors.blue : AppColors.primaryDarkGreen) 
                  : colorScheme.onSurface),
          ),
        ),
      ],
    );
  }
}
