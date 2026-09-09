import 'package:flutter/material.dart';
import 'package:turfpro/common/constants/colors.dart';
import 'package:turfpro/user_booking/constants/widgets/app_text.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final bool capitalize;

  const StatusBadge({
    super.key,
    required this.status,
    this.capitalize = true,
  });

  @override
  Widget build(BuildContext context) {
    if (status.isEmpty) return const SizedBox.shrink();
    final color = AppColors.bookingStatusColor(status);
    final bgColor = AppColors.bookingStatusBgColor(status);
    String displayText = status;
    if (status.toLowerCase() == 'requested') {
      displayText = 'Pending Approval';
    } else if (status.toLowerCase() == 'approved') {
      displayText = 'Approved - Pay Now';
    } else if (capitalize && status.isNotEmpty) {
      displayText = '${status[0].toUpperCase()}${status.substring(1)}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: AppText(
        text: displayText,
        color: color,
        size: 12,
        weight: FontWeight.w600,
      ),
    );
  }
}
