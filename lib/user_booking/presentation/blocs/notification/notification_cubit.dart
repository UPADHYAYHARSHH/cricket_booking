import 'package:flutter_bloc/flutter_bloc.dart';
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

  NotificationCubit(this._repository) : super(NotificationInitial());

  Future<void> fetchNotifications() async {
    emit(NotificationLoading(unreadCount: state.unreadCount));
    try {
      final notifications = await _repository.getNotifications();
      final unreadCount = await _repository.getUnreadCount();
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
}
