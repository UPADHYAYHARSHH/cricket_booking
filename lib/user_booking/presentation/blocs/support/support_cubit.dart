import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turfpro/user_booking/data/models/support_message_model.dart';
import 'package:turfpro/user_booking/data/repositories/support_repository.dart';
import 'support_state.dart';

class SupportCubit extends Cubit<SupportState> {
  final SupportRepository _supportRepository;

  SupportCubit({SupportRepository? supportRepository})
      : _supportRepository = supportRepository ?? SupportRepository(),
        super(SupportInitial());

  Future<void> initSupport({Map<String, dynamic>? initialBooking}) async {
    emit(SupportLoading());

    Map<String, dynamic>? recentBooking = initialBooking ?? await _supportRepository.fetchLatestBooking();

    String initialGreeting =
        "Hi there! 👋 I'm your TurfPro Assistant. How can I help you today?";
    List<String> initialQuickReplies = [
      "Why is my booking pending?",
      "Refund Status",
      "Check-in at Venue",
      "Reschedule / Cancel",
      "WhatsApp Support",
    ];

    if (recentBooking != null) {
      final groundName = recentBooking['grounds']?['name'] ?? 'your turf';
      final status = recentBooking['status']?.toString() ?? '';
      if (status == 'requested') {
        initialGreeting =
            "Hi! 👋 I see you recently requested a slot at **$groundName**. The venue owner has 45 minutes to accept your request. How can I help with this booking?";
        initialQuickReplies = [
          "How 45m Timer Works",
          "What if owner declines?",
          "Cancel My Request",
          "WhatsApp Support",
        ];
      } else if (status == 'approved') {
        initialGreeting =
            "Good news! 🎉 Your booking for **$groundName** is approved! Please complete payment within 45 minutes to lock your slot. Need any assistance with payment?";
        initialQuickReplies = [
          "Payment Options",
          "Split Bill Help",
          "How 45m Payment Works",
          "WhatsApp Support",
        ];
      }
    }

    final welcomeMessage = SupportMessageModel.bot(
      text: initialGreeting,
      quickReplies: initialQuickReplies,
      actions: recentBooking != null && recentBooking['id'] != null
          ? [
              SupportAction(
                type: "view_booking",
                label:
                    "View Booking #${recentBooking['id'].toString().substring(0, 8).toUpperCase()}",
                bookingId: recentBooking['id'].toString(),
              )
            ]
          : [],
    );

    emit(SupportLoaded(
      messages: [welcomeMessage],
      recentBooking: recentBooking,
      currentQuickReplies: initialQuickReplies,
    ));
  }

  Future<void> sendMessage(String text, {String? bookingId}) async {
    final currentState = state;
    if (currentState is! SupportLoaded) return;
    if (text.trim().isEmpty) return;

    final userMessage = SupportMessageModel.user(text: text.trim());
    final updatedMessages = List<SupportMessageModel>.from(currentState.messages)
      ..add(userMessage);

    emit(currentState.copyWith(
      messages: updatedMessages,
      isSending: true,
      currentQuickReplies: [],
    ));

    final activeBookingId =
        bookingId ?? currentState.recentBooking?['id']?.toString();

    final botReply = await _supportRepository.sendChatMessage(
      message: text.trim(),
      bookingId: activeBookingId,
      conversationHistory: updatedMessages,
      role: 'user',
    );

    final finalMessages = List<SupportMessageModel>.from(updatedMessages)
      ..add(botReply);

    emit(currentState.copyWith(
      messages: finalMessages,
      isSending: false,
      currentQuickReplies: botReply.quickReplies,
    ));
  }
}
