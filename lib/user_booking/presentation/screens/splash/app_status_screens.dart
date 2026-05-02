import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turfpro/user_booking/presentation/blocs/config/config_cubit.dart';
import 'package:turfpro/common/constants/colors.dart';
import 'package:turfpro/user_booking/constants/widgets/app_text.dart';
import 'package:turfpro/user_booking/constants/widgets/app_sizedBox.dart';


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
