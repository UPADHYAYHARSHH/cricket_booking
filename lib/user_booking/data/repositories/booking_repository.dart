import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../models/booking_model.dart';

class BookingRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<BookingModel>> getUserBookings() async {
    final user = fb.FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');

    debugPrint("[BOOKING_REPO] Fetching bookings via RPC for user: ${user.uid}");
    final response = await _supabase.rpc('get_user_bookings', params: {
      'p_user_id': user.uid,
    });

    final List data = response as List;
    debugPrint("[BOOKING_REPO] Bookings found: ${data.length}");
    return data.map((json) => BookingModel.fromJson(json)).toList();
  }
}
