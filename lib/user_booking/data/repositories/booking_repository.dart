import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/booking_model.dart';

class BookingRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<BookingModel>> getUserBookings() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final response = await _supabase
        .from('bookings')
        .select('*, grounds(*, ground_images(image_url))')
        .eq('user_id', user.id)
        .order('slot_time', ascending: false);

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
