import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/support_message_model.dart';

class SupportRepository {
  final SupabaseClient _supabase;

  SupportRepository({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  /// Fetches the user's most recent booking for context in the Help & Support screen
  Future<Map<String, dynamic>?> fetchLatestBooking() async {
    final uid = currentUserId;
    if (uid == null) return null;

    try {
      final res = await _supabase
          .from('bookings')
          .select('*, grounds(name, category, location_id)')
          .eq('user_id', uid)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      return res;
    } catch (e) {
      debugPrint('[SupportRepository] Error fetching latest booking: $e');
      return null;
    }
  }

  /// Sends a message to the support-chat-bot edge function
  Future<SupportMessageModel> sendChatMessage({
    required String message,
    String? bookingId,
    List<SupportMessageModel> conversationHistory = const [],
    String role = 'user',
  }) async {
    final uid = currentUserId ?? 'guest_user';

    final historyList = conversationHistory.map((m) {
      return {
        'role': m.isUser ? 'user' : 'model',
        'text': m.text,
      };
    }).toList();

    try {
      final res = await _supabase.functions.invoke(
        'support-chat-bot',
        body: {
          'user_id': uid,
          'role': role,
          'message': message,
          'booking_id': bookingId,
          'conversation_history': historyList,
        },
      );

      if (res.status == 200 && res.data != null) {
        dynamic data = res.data;
        if (data is String) {
          try {
            data = jsonDecode(data);
          } catch (_) {}
        }

        final replyText = data['reply']?.toString() ??
            "I'm here to help with your booking and payment questions!";

        final List<String> quickReplies = [];
        if (data['quick_replies'] is List) {
          for (final qr in data['quick_replies']) {
            if (qr != null) quickReplies.add(qr.toString());
          }
        }

        final List<SupportAction> actions = [];
        if (data['actions'] is List) {
          for (final act in data['actions']) {
            if (act is Map) {
              actions.add(SupportAction.fromJson(Map<String, dynamic>.from(act)));
            }
          }
        }

        return SupportMessageModel.bot(
          text: replyText,
          quickReplies: quickReplies,
          actions: actions,
        );
      }
    } catch (e) {
      debugPrint('[SupportRepository] Edge function call failed: $e');
    }

    // Client fallback if edge function call fails
    return SupportMessageModel.bot(
      text:
          "I'm having trouble connecting to the network right now. You can reach our support team directly on WhatsApp or try again shortly!",
      quickReplies: ["WhatsApp Support", "Check My Bookings", "Retry"],
      actions: [
        SupportAction(
          type: "whatsapp_support",
          label: "Chat on WhatsApp",
          url: "https://wa.me/919876543210?text=Hi%20TurfPro%20Support",
        )
      ],
    );
  }
}
