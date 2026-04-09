import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:bloc_structure/user_booking/presentation/blocs/notification/notification_cubit.dart';
import 'package:bloc_structure/user_booking/data/repositories/notification_repository.dart';
import 'package:bloc_structure/user_booking/constants/widgets/app_text.dart';
import 'package:bloc_structure/user_booking/constants/widgets/app_sizedBox.dart';
import 'package:bloc_structure/common/constants/colors.dart';
import 'package:bloc_structure/user_booking/constants/route_constants.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: const AppText(
          text: "Notifications",
          textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<NotificationCubit, NotificationState>(
        builder: (context, state) {
          if (state is NotificationLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is NotificationLoaded) {
            if (state.notifications.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedNotification01,
                      size: 64,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                    ),
                    const AppSizedBox(height: 16),
                    const AppText(text: "No notifications yet"),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: state.notifications.length,
              separatorBuilder: (_, __) => const AppSizedBox(height: 12),
              itemBuilder: (context, index) {
                final notification = state.notifications[index];
                return _NotificationTile(notification: notification);
              },
            );
          }

          if (state is NotificationError) {
            return Center(child: AppText(text: state.message));
          }

          return const SizedBox();
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;

  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;

    return InkWell(
      onTap: () {
        context.read<NotificationCubit>().markAsRead(notification.id);
        if (notification.type == 'split_payment') {
          // Navigate to split section as requested
          Navigator.pushNamed(
            context,
            AppRoutes.splitOverview,
            arguments: notification.data?['booking_id'],
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUnread 
              ? AppColors.primaryDarkGreen.withOpacity(0.05) 
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: isUnread 
              ? Border.all(color: AppColors.primaryDarkGreen.withOpacity(0.1))
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: notification.type == 'split_payment' 
                    ? AppColors.primaryDarkGreen.withOpacity(0.1)
                    : Colors.blue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                notification.type == 'split_payment' 
                    ? Icons.payments_outlined 
                    : Icons.notifications_none,
                color: notification.type == 'split_payment' 
                    ? AppColors.primaryDarkGreen 
                    : Colors.blue,
                size: 20,
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
                          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                      AppText(
                        text: DateFormat('MMM d, h:mm a').format(notification.createdAt),
                        textStyle: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                  const AppSizedBox(height: 4),
                  AppText(
                    text: notification.message,
                    textStyle: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            if (isUnread)
              Container(
                margin: const EdgeInsets.only(left: 8, top: 20),
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primaryDarkGreen,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
