import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turfpro/user_booking/presentation/blocs/config/config_cubit.dart';
import 'package:turfpro/common/constants/colors.dart';
import 'package:turfpro/user_booking/constants/widgets/app_text.dart';
import 'package:turfpro/user_booking/constants/widgets/app_sizedBox.dart';

class MaintenanceScreen extends StatelessWidget {
  const MaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.accentOrange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const HugeIcon(
                icon: HugeIcons.strokeRoundedTools,
                size: 64,
                color: AppColors.accentOrange,
              ),
            ),
            const AppSizedBox(height: 32),
            const AppText(
              text: "Under Maintenance",
              size: 24,
              weight: FontWeight.bold,
            ),
            const AppSizedBox(height: 16),
            AppText(
              text: "TurfPro is currently undergoing scheduled maintenance to improve your experience. We'll be back shortly!",
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              align: TextAlign.center,
            ),
            const AppSizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.read<ConfigCubit>().refresh(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDarkGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Check Again"),
            ),
          ],
        ),
      ),
    );
  }
}

class ForceUpdateDialog extends StatelessWidget {
  final String updateUrl;
  const ForceUpdateDialog({super.key, required this.updateUrl});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("New Version Available"),
        content: const Text(
          "A new version of TurfPro is available with important updates and improvements. Please update to continue using the app.",
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final uri = Uri.parse(updateUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            child: const Text(
              "Update Now",
              style: TextStyle(color: AppColors.primaryDarkGreen, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
