import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turfpro/common/services/audio_service.dart';
import '../../../data/repositories/notification_repository.dart';

abstract class NotificationState {
  final int unreadCount;
  NotificationState({this.unreadCount = 0});
}

class NotificationInitial extends NotificationState {
  NotificationInitial() : super(unreadCount: 0);
}

class NotificationLoading extends NotificationState {
  NotificationLoading({super.unreadCount});
}

class NotificationLoaded extends NotificationState {
  final List<NotificationModel> notifications;
  NotificationLoaded(this.notifications, {super.unreadCount});
}

class NotificationError extends NotificationState {
  final String message;
  NotificationError(this.message, {super.unreadCount});
}

class NotificationCubit extends Cubit<NotificationState> {
  final NotificationRepository _repository;
  final AudioService _audioService = AudioService();
  Set<String> _notifiedIds = {};

  NotificationCubit(this._repository) : super(NotificationInitial());

  Future<void> fetchNotifications() async {
    final bool isInitialFetch = state is NotificationInitial;
    
    // Don't show loading if we already have notifications (silent refresh)
    if (state is! NotificationLoaded) {
      emit(NotificationLoading(unreadCount: state.unreadCount));
    }
    
    try {
      final notifications = await _repository.getNotifications();
      final unreadCount = await _repository.getUnreadCount();

      // Detect new notifications to play sounds
      if (!isInitialFetch) {
        for (var notification in notifications) {
          if (!notification.isRead && !_notifiedIds.contains(notification.id)) {
            _audioService.playNotificationSound(notification.type);
            _notifiedIds.add(notification.id);
          }
        }
      } else {
        // Just populate the set on first load without playing sounds
        _notifiedIds = notifications.map((n) => n.id).toSet();
      }

      emit(NotificationLoaded(notifications, unreadCount: unreadCount));
    } catch (e) {
      emit(NotificationError(e.toString(), unreadCount: state.unreadCount));
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _repository.markAsRead(id);
      fetchNotifications(); // Refresh
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _repository.markAllAsRead();
      fetchNotifications(); // Refresh
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> deleteNotification(String id) async {
    try {
      await _repository.deleteNotification(id);
      fetchNotifications(); // Refresh
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> clearAll() async {
    try {
      await _repository.clearAll();
      fetchNotifications(); // Refresh
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> addDummyNotifications() async {
    try {
      await _repository.addDummyNotifications();
      fetchNotifications(); // Refresh
    } catch (e) {
      // Silently fail
    }
  }
}
