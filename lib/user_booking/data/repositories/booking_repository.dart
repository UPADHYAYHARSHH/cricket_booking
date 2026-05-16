import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../models/booking_model.dart';

class BookingRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<BookingModel>> getUserBookings() async {
    final user = fb.FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final response = await _supabase
        .from('bookings')
        .select('*, grounds(*, ground_images(image_url))')
        .eq('user_id', user.uid)
        .order('slot_time', ascending: false);

    debugPrint("[BOOKING_REPO] Bookings found for ${user.uid}: ${response.length}");
    final List data = response as List;
    return data.map((json) {
      // Extract ground image if available
      if (json['grounds'] != null) {
        final groundData = json['grounds'] as Map<String, dynamic>;
        final images = groundData['ground_images'] as List?;
        if (images != null && images.isNotEmpty) {
          groundData['imageUrl'] = images[0]['image_url'];
        }
      }
      return BookingModel.fromJson(json);
    }).toList();
  }
}
