import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:turfpro/user_booking/presentation/blocs/notification/notification_cubit.dart';
import 'package:turfpro/user_booking/data/repositories/notification_repository.dart';
import 'package:turfpro/user_booking/constants/widgets/app_text.dart';
import 'package:turfpro/user_booking/constants/widgets/app_sizedBox.dart';
import 'package:turfpro/user_booking/constants/text_theme.dart';
import 'package:turfpro/common/constants/colors.dart';
import 'package:turfpro/user_booking/constants/route_constants.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    context.read<NotificationCubit>().fetchNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 20, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: const AppText(
          text: "Notifications",
          textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          BlocBuilder<NotificationCubit, NotificationState>(
            builder: (context, state) {
              if (state is! NotificationLoaded || state.notifications.isEmpty) return const SizedBox();
              
              return PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'mark_read') {
                    context.read<NotificationCubit>().markAllAsRead();
                  } else if (value == 'clear_all') {
                    context.read<NotificationCubit>().clearAll();
                  }
                },
                icon: Icon(Icons.more_vert, color: theme.colorScheme.onSurface),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'mark_read',
                    child: Row(
                      children: [
                        Icon(Icons.done_all, size: 20),
                        SizedBox(width: 12),
                        Text("Mark all as read"),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'clear_all',
                    child: Row(
                      children: [
                        Icon(Icons.delete_sweep, size: 20, color: AppColors.error),
                        SizedBox(width: 12),
                        Text("Clear all", style: TextStyle(color: AppColors.error)),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<NotificationCubit>().fetchNotifications(),
        color: AppColors.primaryDarkGreen,
        child: BlocBuilder<NotificationCubit, NotificationState>(
          builder: (context, state) {
            if (state is NotificationLoading && state.unreadCount == 0) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is NotificationLoaded) {
              if (state.notifications.isEmpty) {
                return _buildEmptyState(context);
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: state.notifications.length,
                separatorBuilder: (_, __) => const AppSizedBox(height: 12),
                itemBuilder: (context, index) {
                  final notification = state.notifications[index];
                  return Dismissible(
                    key: Key(notification.id),
                    direction: DismissDirection.horizontal,
                    onDismissed: (direction) {
                      if (direction == DismissDirection.endToStart) {
                        context.read<NotificationCubit>().deleteNotification(notification.id);
                      } else if (direction == DismissDirection.startToEnd) {
                        context.read<NotificationCubit>().markAsRead(notification.id);
                      }
                    },
                    background: _buildSwipeBackground(
                      context, 
                      alignment: Alignment.centerLeft,
                      color: Colors.green,
                      icon: Icons.done,
                      label: "Read"
                    ),
                    secondaryBackground: _buildSwipeBackground(
                      context, 
                      alignment: Alignment.centerRight,
                      color: AppColors.error,
                      icon: Icons.delete_outline,
                      label: "Delete"
                    ),
                    child: _NotificationTile(notification: notification),
                  );
                },
              );
            }

            if (state is NotificationError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    HugeIcon(icon: HugeIcons.strokeRoundedAlert01, color: AppColors.error, size: 48),
                    const SizedBox(height: 16),
                    AppText(text: state.message, textStyle: AppTextTheme.grey13),
                    TextButton(
                      onPressed: () => context.read<NotificationCubit>().fetchNotifications(),
                      child: const Text("Retry"),
                    ),
                  ],
                ),
              );
            }

            return const SizedBox();
          },
        ),
      ),
    );
  }

  Widget _buildSwipeBackground(BuildContext context, {
    required Alignment alignment, 
    required Color color, 
    required IconData icon,
    required String label
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      alignment: alignment,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedNotification02,
              size: 64,
              color: AppColors.primaryDarkGreen.withOpacity(0.2),
            ),
          ),
          const AppSizedBox(height: 24),
          AppText(
            text: "All caught up!",
            textStyle: AppTextTheme.black8718.copyWith(fontWeight: FontWeight.bold),
          ),
          const AppSizedBox(height: 8),
          AppText(
            text: "You don't have any new notifications",
            textStyle: AppTextTheme.grey13.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const AppSizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => context.read<NotificationCubit>().addDummyNotifications(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDarkGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.add_circle_outline),
            label: const Text("Add Dummy Notifications"),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;

  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUnread = !notification.isRead;
    final config = _getNotificationConfig(notification.type);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleTap(context),
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isUnread 
                ? config.color.withOpacity(theme.brightness == Brightness.dark ? 0.15 : 0.08)
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isUnread 
                  ? config.color.withOpacity(0.2)
                  : theme.dividerColor.withOpacity(0.1),
              width: 1,
            ),
            boxShadow: [
              if (!isUnread)
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: config.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: HugeIcon(
                  icon: config.icon,
                  color: config.color,
                  size: 22,
                ),
              ),
              const AppSizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: AppText(
                            text: notification.title,
                            textStyle: TextStyle(
                              fontWeight: isUnread ? FontWeight.w800 : FontWeight.w600,
                              fontSize: 15,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        AppText(
                          text: _formatDate(notification.createdAt),
                          textStyle: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurface.withOpacity(0.4),
                          ),
                        ),
                      ],
                    ),
                    const AppSizedBox(height: 6),
                    AppText(
                      text: notification.message,
                      textStyle: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: theme.colorScheme.onSurface.withOpacity(isUnread ? 0.9 : 0.6),
                        fontWeight: isUnread ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              if (isUnread)
                Container(
                  margin: const EdgeInsets.only(left: 12, top: 4),
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: config.color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: config.color.withOpacity(0.4),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleTap(BuildContext context) {
    context.read<NotificationCubit>().markAsRead(notification.id);
    
    // Custom navigation based on type
    switch (notification.type) {
      case 'split_payment':
        Navigator.pushNamed(
          context,
          AppRoutes.splitOverview,
          arguments: notification.data?['booking_id'],
        );
        break;
      case 'booking_confirmed':
      case 'booking_cancelled':
        // Navigate to bookings tab if possible or specific booking
        Navigator.pushNamed(context, AppRoutes.myBookingScreen);
        break;
      case 'loyalty_points':
        // Navigate to profile or rewards section
        Navigator.pushNamed(context, AppRoutes.nav);
        break;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return "${difference.inMinutes}m ago";
    } else if (difference.inHours < 24) {
      return "${difference.inHours}h ago";
    } else if (difference.inDays < 7) {
      return DateFormat('EEE, h:mm a').format(date);
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }

  _NotificationConfig _getNotificationConfig(String type) {
    switch (type) {
      case 'booking_confirmed':
        return _NotificationConfig(
          icon: HugeIcons.strokeRoundedCalendar01,
          color: Colors.green.shade600,
        );
      case 'booking_cancelled':
        return _NotificationConfig(
          icon: HugeIcons.strokeRoundedCalendar01,
          color: AppColors.error,
        );
      case 'split_payment':
      case 'payment_received':
        return _NotificationConfig(
          icon: HugeIcons.strokeRoundedCreditCard,
          color: Colors.blue.shade600,
        );
      case 'loyalty_points':
        return _NotificationConfig(
          icon: HugeIcons.strokeRoundedStar,
          color: Colors.amber.shade700,
        );
      case 'reminder':
        return _NotificationConfig(
          icon: HugeIcons.strokeRoundedClock01,
          color: Colors.orange.shade700,
        );
      case 'promotion':
        return _NotificationConfig(
          icon: HugeIcons.strokeRoundedGift,
          color: Colors.purple.shade600,
        );
      default:
        return _NotificationConfig(
          icon: HugeIcons.strokeRoundedNotification01,
          color: AppColors.primaryDarkGreen,
        );
    }
  }
}

class _NotificationConfig {
  final dynamic icon;
  final Color color;

  _NotificationConfig({required this.icon, required this.color});
}
