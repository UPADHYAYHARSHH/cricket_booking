import 'package:bloc_structure/user_booking/domain/models/booking_arguments.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../../constants/route_constants.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../common/constants/colors.dart';
import '../../../constants/text_theme.dart';
import '../../../constants/widgets/app_sizedBox.dart';
import '../../../constants/widgets/app_text.dart';

import 'package:intl/intl.dart';

class BookingConfirmationScreen extends StatelessWidget {
  const BookingConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final rawArgs = ModalRoute.of(context)!.settings.arguments;
    if (rawArgs == null || rawArgs is! BookingSuccessArguments) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const AppSizedBox(height: 16),
              const AppText(text: "Booking information missing"),
              TextButton(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                    context, '/nav', (r) => false),
                child: const Text("Go to Home"),
              )
            ],
          ),
        ),
      );
    }

    final args = rawArgs;
    final ground = args.ground;
    final date = args.date;
    final slots = args.selectedSlots;
    final orderId = args.orderId;
    final totalPrice = args.totalPrice;

    final timeRange = slots.isEmpty
        ? "No slots selected"
        : "${slots.first.startTime} - ${slots.last.endTime}";

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: colorScheme.onSurface,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: AppText(
          text: "Booking Status",
          textStyle: AppTextTheme.black16.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const AppSizedBox(height: 12),

              /// SUCCESS ICON
              AppSizedBox(
                height: 140,
                width: 140,
                child: Lottie.asset(
                  'assets/animations/Success.json', // Fixed case-sensitivity
                  repeat: false,
                ),
              ),

              const AppSizedBox(height: 8),

              /// TITLE
              AppText(
                text: "Slot Booked\nSuccessfully!",
                align: TextAlign.center,
                textStyle: AppTextTheme.black18.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  color: colorScheme.onSurface,
                ),
              ),

              const AppSizedBox(height: 12),

              /// SUBTITLE
              AppText(
                text:
                    "Get ready to hit some sixes! Your pitch is ready for action.",
                align: TextAlign.center,
                textStyle: AppTextTheme.grey13.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.6),
                  height: 1.5,
                  fontSize: 14,
                ),
              ),

              const AppSizedBox(height: 32),

              _VenueCard(ground: ground),

              const AppSizedBox(height: 20),

              _BookingDetailsCard(
                date: date,
                timeRange: timeRange,
                orderId: orderId,
                totalPrice: totalPrice,
              ),

              const AppSizedBox(height: 32),

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
                  minimumSize: const Size(double.infinity, 56),
                  elevation: 4,
                  shadowColor: AppColors.primaryDarkGreen.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: AppText(
                  text: "Back to Home",
                  textStyle: AppTextTheme.white15.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),

              const AppSizedBox(height: 16),

              /// SPLIT BILL
              OutlinedButton(
                onPressed: () => Navigator.pushNamed(
                  context,
                  AppRoutes.splitSetup,
                  arguments: args,
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(
                      color: AppColors.primaryDarkGreen, width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const HugeIcon(
                        icon: HugeIcons.strokeRoundedUserGroup,
                        color: AppColors.primaryDarkGreen,
                        size: 20),
                    const AppSizedBox(width: 8),
                    AppText(
                      text: "Split Bill with Teammates",
                      textStyle: AppTextTheme.black15.copyWith(
                        color: AppColors.primaryDarkGreen,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),

              const AppSizedBox(height: 16),

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
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),

              const AppSizedBox(height: 32),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withOpacity(theme.brightness == Brightness.dark ? 0.3 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Stack(
              children: [
                SizedBox(
                  height: 160,
                  width: double.infinity,
                  child: Image.network(
                    ground.imageUrl ??
                        "https://images.unsplash.com/photo-1540747913346-19e32dc3e97e",
                    fit: BoxFit.cover,
                  ),
                ),
                Container(
                  height: 160,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle,
                            color: Colors.white, size: 14),
                        const AppSizedBox(width: 4),
                        AppText(
                          text: "CONFIRMED",
                          textStyle: AppTextTheme.white10.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: .5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 16,
                  child: AppText(
                    text: ground.name,
                    textStyle: AppTextTheme.white15.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.location_on, color: colorScheme.primary, size: 16),
                const AppSizedBox(width: 6),
                Expanded(
                  child: AppText(
                    text: ground.address ??
                        "Location details available in ticket",
                    maxLines: 1,
                    textStyle: AppTextTheme.grey12.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
              ],
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          _DetailRow(
            icon: Icons.calendar_today_rounded,
            label: "DATE",
            value: DateFormat('EEEE, d MMM yyyy').format(date),
          ),
          const AppSizedBox(height: 16),
          _DetailRow(
            icon: Icons.access_time_rounded,
            label: "TIME SLOT",
            value: timeRange,
          ),
          const AppSizedBox(height: 20),
          Divider(color: colorScheme.outlineVariant.withOpacity(0.5)),
          const AppSizedBox(height: 20),
          _DetailRow(
            label: "Booking ID",
            value: "#$orderId",
            isSmall: true,
          ),
          const AppSizedBox(height: 12),
          _DetailRow(
            label: "Total Amount",
            value: "₹${totalPrice.toStringAsFixed(0)}",
            isSmall: true,
            valueBold: true,
          ),
          const AppSizedBox(height: 12),
          _DetailRow(
            label: "Payment Status",
            value: "PAID",
            isSmall: true,
            valueColor: AppColors.success,
            valueBold: true,
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (!isSmall) {
      return Row(
        children: [
          if (icon != null)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: colorScheme.primary, size: 20),
            ),
          const AppSizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                text: label,
                textStyle: AppTextTheme.grey12.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  fontSize: 10,
                  color: colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
              const AppSizedBox(height: 4),
              AppText(
                text: value,
                textStyle: AppTextTheme.black14.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
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
          textStyle: AppTextTheme.grey12.copyWith(
            color: colorScheme.onSurface.withOpacity(0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
        AppText(
          text: value,
          textStyle: AppTextTheme.black12.copyWith(
            color: valueColor ?? colorScheme.onSurface,
            fontWeight: valueBold ? FontWeight.w800 : FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
