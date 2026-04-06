import 'package:bloc_structure/user_booking/domain/models/booking_arguments.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../../../common/constants/colors.dart';
import '../../../constants/text_theme.dart';
import '../../../constants/widgets/app_sizedBox.dart';
import '../../../constants/widgets/app_text.dart';

import 'package:intl/intl.dart';

class BookingConfirmationScreen extends StatelessWidget {
  const BookingConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as BookingSuccessArguments;
    final ground = args.ground;
    final date = args.date;
    final slots = args.selectedSlots;
    final orderId = args.orderId;
    final totalPrice = args.totalPrice;

    final timeRange = slots.isEmpty
        ? "No slots selected"
        : "${slots.first.startTime} - ${slots.last.endTime}";
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: AppColors.textPrimaryLight,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: AppText(
          text: "Booking Status",
          textStyle: AppTextTheme.black16.copyWith(
            color: AppColors.textPrimaryLight,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const AppSizedBox(height: 24),

              /// SUCCESS ICON
              AppSizedBox(
                height: 120,
                width: 120,
                child: Lottie.asset(
                  'assets/animations/success.json',
                  repeat: false,
                ),
              ),

              const AppSizedBox(height: 16),

              /// TITLE
              AppText(
                text: "Slot Booked\nSuccessfully!",
                align: TextAlign.center,
                textStyle: AppTextTheme.black18.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                  color: AppColors.textPrimaryLight,
                ),
              ),

              const AppSizedBox(height: 8),

              /// SUBTITLE
              AppText(
                text: "Get ready to hit some sixes! Your pitch is ready.",
                align: TextAlign.center,
                textStyle: AppTextTheme.grey13.copyWith(
                  color: AppColors.textSecondaryLight,
                  height: 1.4,
                ),
              ),

              const AppSizedBox(height: 24),

              _VenueCard(ground: ground),

              const AppSizedBox(height: 20),

              _BookingDetailsCard(
                date: date,
                timeRange: timeRange,
                orderId: orderId,
                totalPrice: totalPrice,
              ),

              const AppSizedBox(height: 24),

              /// DOWNLOAD RECEIPT
              OutlinedButton.icon(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.success,
                  side: const BorderSide(color: AppColors.success, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.download_rounded, size: 18),
                label: AppText(
                  text: "Download Receipt",
                  textStyle: AppTextTheme.black14.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const AppSizedBox(height: 12),

              /// BACK TO HOME
              ElevatedButton(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/nav',
                  (route) => false,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDarkGreen,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(double.infinity, 52),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: AppText(
                  text: "Back to Home",
                  textStyle: AppTextTheme.white15.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              const AppSizedBox(height: 12),

              /// VIEW BOOKINGS
              TextButton(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/nav',
                  (route) => false,
                  arguments: 1, // Go to bookings tab
                ),
                child: AppText(
                  text: "View My Bookings",
                  textStyle: AppTextTheme.black13.copyWith(
                    color: AppColors.textSecondaryLight,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),

              const AppSizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _VenueCard extends StatelessWidget {
  final dynamic ground;
  const _VenueCard({required this.ground});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        children: [
          Container(
            height: 140,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryDarkGreen,
                  AppColors.primaryLightGreen
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success,
                borderRadius: BorderRadius.circular(4),
              ),
              child: AppText(
                text: "CONFIRMED",
                textStyle: AppTextTheme.white10.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: .8,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 12,
            left: 12,
            child: AppText(
              text: ground.name,
              textStyle: AppTextTheme.white15.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingDetailsCard extends StatelessWidget {
  final DateTime date;
  final String timeRange;
  final String orderId;
  final double totalPrice;

  const _BookingDetailsCard({
    required this.date,
    required this.timeRange,
    required this.orderId,
    required this.totalPrice,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          _DetailRow(
            icon: Icons.calendar_today_rounded,
            label: "DATE",
            value: DateFormat('EEEE, d MMM yyyy').format(date),
          ),
          const Divider(),
          _DetailRow(
            icon: Icons.access_time_rounded,
            label: "TIME SLOT",
            value: timeRange,
          ),
          const Divider(),
          _DetailRow(
            label: "Order ID",
            value: "#$orderId",
            isSmall: true,
          ),
          const AppSizedBox(height: 8),
          _DetailRow(
            label: "Amount Paid",
            value: "₹${totalPrice.toStringAsFixed(0)}",
            isSmall: true,
            valueBold: true,
          ),
          const AppSizedBox(height: 8),
          const _DetailRow(
            label: "Payment Method",
            value: "Razorpay Success",
            isSmall: true,
            valueColor: AppColors.success,
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData? icon;
  final String label;
  final String value;
  final bool isSmall;
  final bool valueBold;
  final Color? valueColor;

  const _DetailRow({
    this.icon,
    required this.label,
    required this.value,
    this.isSmall = false,
    this.valueBold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    if (!isSmall) {
      return Row(
        children: [
          if (icon != null)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryLightGreen.withValues(alpha: .15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.primaryDarkGreen, size: 18),
            ),
          const AppSizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                text: label,
                textStyle: AppTextTheme.grey12.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const AppSizedBox(height: 2),
              AppText(
                text: value,
                textStyle: AppTextTheme.black14.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppText(
          text: label,
          textStyle: AppTextTheme.grey12,
        ),
        AppText(
          text: value,
          textStyle: AppTextTheme.black12.copyWith(
            color: valueColor ?? AppColors.textPrimaryLight,
            fontWeight: valueBold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
