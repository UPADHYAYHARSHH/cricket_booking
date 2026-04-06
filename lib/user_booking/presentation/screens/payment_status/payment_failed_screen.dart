import 'package:flutter/material.dart';
import '../../../../common/constants/colors.dart';
import '../../../constants/text_theme.dart';
import '../../../constants/widgets/app_sizedBox.dart';
import '../../../constants/widgets/app_text.dart';
import 'package:bloc_structure/user_booking/domain/models/booking_arguments.dart';

class PaymentFailedScreen extends StatelessWidget {
  const PaymentFailedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as BookingFailureArguments;

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
          text: "Payment Status",
          textStyle: AppTextTheme.black16.copyWith(
            color: AppColors.textPrimaryLight,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),

            /// FAILURE ICON
            Container(
              height: 100,
              width: 100,
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: AppColors.error,
                size: 60,
              ),
            ),

            const AppSizedBox(height: 32),

            /// TITLE
            AppText(
              text: "Payment Failed",
              align: TextAlign.center,
              textStyle: AppTextTheme.black18.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.error,
              ),
            ),

            const AppSizedBox(height: 12),

            /// SUBTITLE / ERROR MESSAGE
            AppText(
              text: args.errorMessage,
              align: TextAlign.center,
              textStyle: AppTextTheme.grey14.copyWith(
                color: AppColors.textSecondaryLight,
                height: 1.5,
              ),
            ),

            const AppSizedBox(height: 48),

            /// RETRY BUTTON
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                if (args.onRetry != null) {
                  args.onRetry!();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDarkGreen,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size(double.infinity, 52),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: AppText(
                text: "Retry Payment",
                textStyle: AppTextTheme.white15.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            const AppSizedBox(height: 16),

            /// BACK TO TURF DETAILS
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimaryLight,
                side: const BorderSide(color: AppColors.borderLight),
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: AppText(
                text: "Check Other Slots",
                textStyle: AppTextTheme.black15.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const Spacer(flex: 2),

            /// CUSTOMER SUPPORT
            AppText(
              text: "Facing issues? Contact Customer Support",
              textStyle: AppTextTheme.grey12.copyWith(
                color: AppColors.textSecondaryLight,
                decoration: TextDecoration.underline,
              ),
            ),

            const AppSizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
