import 'package:hugeicons/hugeicons.dart';
import 'package:flutter/material.dart';
import '../../../../common/constants/colors.dart';
import 'package:turfpro/common/widgets/discover_app_bar.dart';
import '../../../constants/text_theme.dart';
import '../../../constants/widgets/app_sizedBox.dart';
import '../../../constants/widgets/app_text.dart';
import 'package:turfpro/user_booking/domain/models/booking_arguments.dart';

class PaymentFailedScreen extends StatelessWidget {
  const PaymentFailedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final args =
        ModalRoute.of(context)!.settings.arguments as BookingFailureArguments;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: const DiscoverAppBarBackground(),
        leading: IconButton(
          icon: const HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            size: 20,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const AppText(
          text: "Payment Status",
          textStyle: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
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
              text: _formatErrorMessage(args.errorMessage),
              align: TextAlign.center,
              textStyle: AppTextTheme.grey14.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
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
                foregroundColor: theme.colorScheme.onSurface,
                side: BorderSide(color: theme.dividerColor),
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
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),

            const Spacer(),
          ],
        ),
      ),
    );
  }

  String _formatErrorMessage(String? message) {
    if (message == null || message.trim().isEmpty) {
      return "Your payment could not be processed. If any amount was deducted, it will be automatically refunded to your account within 5-7 business days.";
    }

    final lower = message.toLowerCase();
    if (lower.contains("cferrorresponse") ||
        lower.contains("instance of") ||
        lower.contains("exception") ||
        lower.contains("error:") ||
        lower == "payment failed") {
      return "Your payment could not be processed. If any amount was deducted, it will be automatically refunded to your account within 5-7 business days.";
    }

    if (message.startsWith("Payment Failed: ")) {
      final clean = message.substring("Payment Failed: ".length).trim();
      if (clean.toLowerCase().contains("cferrorresponse") ||
          clean.toLowerCase().contains("instance of") ||
          clean.isEmpty) {
        return "Your payment could not be processed. If any amount was deducted, it will be automatically refunded to your account within 5-7 business days.";
      }
      return clean;
    }

    return message;
  }
}
