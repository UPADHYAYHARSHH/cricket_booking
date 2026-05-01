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
import 'package:turfpro/user_booking/presentation/blocs/slot_selection/slot_selection_cubit.dart';
import 'package:turfpro/user_booking/presentation/blocs/slot_selection/slot_selection_state.dart';

class BookingSummaryScreen extends StatelessWidget {
  const BookingSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return BlocBuilder<SlotSelectionCubit, SlotSelectionState>(
      builder: (context, state) {
        final selectedSlots = state.slots.where((s) => s.status == SlotStatus.selected).toList();
        final basePrice = selectedSlots.fold<double>(0, (sum, s) => sum + s.price);
        final activeDate = state.dates.firstWhere((d) => d.isSelected);
        final ground = ModalRoute.of(context)?.settings.arguments as GroundModel?;

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

        final double grandTotal = (basePrice - pointsDiscount) + platformFee;

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
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _summaryRow(context, label: "Venue", value: ground?.name ?? "Turf", isBold: true),
                      const Divider(height: 24),
                      _summaryRow(context, label: "Date", value: "${activeDate.month} ${activeDate.date}, ${DateTime.now().year}"),
                      const AppSizedBox(height: 12),
                      _summaryRow(context, label: "Total Slots", value: "${selectedSlots.length} Selected"),
                      const AppSizedBox(height: 12),
                      _summaryRow(context, label: "Time", value: selectedSlots.isNotEmpty ? selectedSlots.first.startTime : "-"),
                    ],
                  ),
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

  Widget _summaryRow(BuildContext context, {required String label, required String value, bool isBold = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppText(
          text: label,
          textStyle: TextStyle(
            fontSize: 14,
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        AppText(
          text: value,
          textStyle: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _priceRow(BuildContext context, {required String label, required double amount, bool isDiscount = false, bool isFree = false}) {
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
              : (isDiscount ? AppColors.primaryDarkGreen : colorScheme.onSurface),
          ),
        ),
      ],
    );
  }
}
