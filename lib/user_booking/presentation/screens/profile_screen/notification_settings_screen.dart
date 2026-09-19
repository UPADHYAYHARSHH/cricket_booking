import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:turfpro/common/constants/colors.dart';
import 'package:turfpro/common/widgets/discover_app_bar.dart';
import '../../../di/get_it/get_it.dart';
import '../../blocs/profile/profile_cubit.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ProfileCubit>()..loadProfile(),
      child: const _NotificationSettingsView(),
    );
  }
}

class _NotificationSettingsView extends StatelessWidget {
  const _NotificationSettingsView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return BlocConsumer<ProfileCubit, ProfileState>(
      listener: (context, state) {
        if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error!),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        final isEnabled = state.isNotificationEnabled;

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
            title: const Text(
              'Notification Settings',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── MASTER TOGGLE CARD ─────────────────────────────
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isEnabled
                          ? AppColors.primaryDarkGreen.withValues(alpha: 0.3)
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : AppColors.borderLight),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isEnabled
                            ? AppColors.primaryDarkGreen.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isEnabled
                              ? AppColors.primaryDarkGreen
                                  .withValues(alpha: isDark ? 0.25 : 0.12)
                              : Colors.grey.withValues(alpha: isDark ? 0.2 : 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: HugeIcon(
                            icon: isEnabled
                                ? HugeIcons.strokeRoundedNotification01
                                : HugeIcons.strokeRoundedNotificationOff01,
                            size: 24,
                            color: isEnabled
                                ? (isDark
                                    ? AppColors.primaryLightGreen
                                    : AppColors.primaryDarkGreen)
                                : Colors.grey,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Push Notifications",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isEnabled
                                  ? "All alerts and game reminders are active"
                                  : "All notifications are currently turned off",
                              style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Switch.adaptive(
                        value: isEnabled,
                        activeTrackColor: AppColors.primaryDarkGreen,
                        onChanged: (val) {
                          HapticFeedback.lightImpact();
                          context
                              .read<ProfileCubit>()
                              .toggleNotificationSetting(val);
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ─── WHAT YOU RECEIVE SECTION ───────────────────────
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 12),
                  child: Text(
                    "WHAT'S INCLUDED",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                      letterSpacing: 0.8,
                    ),
                  ),
                ),

                Container(
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : AppColors.borderLight,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildFeatureTile(
                        context,
                        icon: HugeIcons.strokeRoundedCalendar03,
                        title: "Booking Confirmations",
                        description:
                            "Instant confirmation alerts and slot approval updates",
                        isEnabled: isEnabled,
                        isFirst: true,
                      ),
                      Divider(
                        height: 1,
                        indent: 64,
                        color: theme.dividerColor.withValues(alpha: 0.4),
                      ),
                      _buildFeatureTile(
                        context,
                        icon: HugeIcons.strokeRoundedClock01,
                        title: "Match & Game Reminders",
                        description:
                            "Upcoming game alerts 30 minutes before kickoff",
                        isEnabled: isEnabled,
                      ),
                      Divider(
                        height: 1,
                        indent: 64,
                        color: theme.dividerColor.withValues(alpha: 0.4),
                      ),
                      _buildFeatureTile(
                        context,
                        icon: HugeIcons.strokeRoundedMegaphone01,
                        title: "Exclusive Offers & Discounts",
                        description:
                            "Special match deals, turf discounts, and reward alerts",
                        isEnabled: isEnabled,
                        isLast: true,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ─── INFO BANNER ────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: (isEnabled ? AppColors.primaryDarkGreen : Colors.grey)
                        .withValues(alpha: isDark ? 0.12 : 0.07),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: (isEnabled ? AppColors.primaryDarkGreen : Colors.grey)
                          .withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 20,
                        color: isEnabled
                            ? (isDark
                                ? AppColors.primaryLightGreen
                                : AppColors.primaryDarkGreen)
                            : Colors.grey,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isEnabled
                              ? "Your preferences are synced with your account. You can disable notifications anytime."
                              : "Notifications are disabled. You will not receive game reminders or booking updates until re-enabled.",
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.4,
                            color: colorScheme.onSurface.withValues(alpha: 0.75),
                          ),
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
    );
  }

  Widget _buildFeatureTile(
    BuildContext context, {
    required dynamic icon,
    required String title,
    required String description,
    required bool isEnabled,
    bool isFirst = false,
    bool isLast = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final tileOpacity = isEnabled ? 1.0 : 0.45;

    return Opacity(
      opacity: tileOpacity,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFFF0F4F2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: icon is IconData
                    ? Icon(icon, size: 20, color: colorScheme.primary)
                    : HugeIcon(icon: icon, size: 20, color: colorScheme.primary),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isEnabled ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 20,
              color: isEnabled
                  ? AppColors.primaryDarkGreen
                  : colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }
}
