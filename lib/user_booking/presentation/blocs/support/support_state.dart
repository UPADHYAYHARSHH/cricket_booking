import 'package:turfpro/user_booking/data/models/support_message_model.dart';

abstract class SupportState {}

class SupportInitial extends SupportState {}

class SupportLoading extends SupportState {}

class SupportLoaded extends SupportState {
  final List<SupportMessageModel> messages;
  final bool isSending;
  final Map<String, dynamic>? recentBooking;
  final List<String> currentQuickReplies;

  SupportLoaded({
    required this.messages,
    this.isSending = false,
    this.recentBooking,
    this.currentQuickReplies = const [],
  });

  SupportLoaded copyWith({
    List<SupportMessageModel>? messages,
    bool? isSending,
    Map<String, dynamic>? recentBooking,
    List<String>? currentQuickReplies,
  }) {
    return SupportLoaded(
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
      recentBooking: recentBooking ?? this.recentBooking,
      currentQuickReplies: currentQuickReplies ?? this.currentQuickReplies,
    );
  }
}
