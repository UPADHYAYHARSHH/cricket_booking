import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String type;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.data,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      message: json['message'],
      type: json['type'],
      data: json['data'],
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class NotificationRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<NotificationModel>> getNotifications() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    final response = await _supabase
        .from('notifications')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    final List data = response as List;
    return data.map((json) => NotificationModel.fromJson(json)).toList();
  }

  Future<void> markAsRead(String notificationId) async {
    await _supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId);
  }

  Future<void> markAllAsRead() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    await _supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', user.id)
        .eq('is_read', false);
  }

  Future<void> deleteNotification(String id) async {
    await _supabase.from('notifications').delete().eq('id', id);
  }

  Future<void> clearAll() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    await _supabase.from('notifications').delete().eq('user_id', user.id);
  }

  Future<void> addDummyNotifications() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final dummyData = [
      {
        'user_id': user.id,
        'title': 'Booking Confirmed!',
        'message': 'Your booking for Mumbai Cricket Club is confirmed for tonight 8:00 PM.',
        'type': 'booking_confirmed',
        'is_read': false,
        'created_at': DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String(),
      },
      {
        'user_id': user.id,
        'title': 'Booking Cancelled',
        'message': 'The booking for Shivaji Park has been cancelled due to rain.',
        'type': 'booking_cancelled',
        'is_read': false,
        'created_at': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
      },
      {
        'user_id': user.id,
        'title': 'Payment Received',
        'message': 'Your payment of ₹1200 for the last match was successful.',
        'type': 'payment_received',
        'is_read': true,
        'created_at': DateTime.now().subtract(const Duration(hours: 5)).toIso8601String(),
      },
      {
        'user_id': user.id,
        'title': 'Split Bill Request',
        'message': 'Harsh has requested ₹300 for the match at Box Cricket Arena.',
        'type': 'split_payment',
        'data': {'booking_id': 'dummy_id'},
        'is_read': false,
        'created_at': DateTime.now().subtract(const Duration(hours: 12)).toIso8601String(),
      },
      {
        'user_id': user.id,
        'title': 'Match Reminder',
        'message': 'Don\'t forget your match at 9:00 PM tomorrow!',
        'type': 'reminder',
        'is_read': false,
        'created_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      },
      {
        'user_id': user.id,
        'title': 'Reward Points Earned!',
        'message': 'You earned 50 loyalty points for your last booking.',
        'type': 'loyalty_points',
        'is_read': true,
        'created_at': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
      },
      {
        'user_id': user.id,
        'title': 'Weekend Offer 🏏',
        'message': 'Get 20% off on all bookings this weekend. Use code CRICKET20.',
        'type': 'promotion',
        'is_read': false,
        'created_at': DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
      },
    ];

    await _supabase.from('notifications').insert(dummyData);
  }
  
  Future<int> getUnreadCount() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return 0;
    
    final response = await _supabase
        .from('notifications')
        .select('id')
        .eq('user_id', user.id)
        .eq('is_read', false);
    
    return (response as List).length;
  }
}
