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
    final Map<String, dynamic> uniqueBookings = {};
    final Set<String> groundIds = {};
    for (var json in data) {
      final id = json['id']?.toString() ?? '';
      if (id.isNotEmpty) {
        uniqueBookings[id] = json;
        if (json['ground_id'] != null) {
          groundIds.add(json['ground_id'].toString());
        }
      }
    }

    if (groundIds.isNotEmpty) {
      try {
        final groundsResponse = await _supabase
            .from('grounds')
            .select('id, name, locations(name)')
            .inFilter('id', groundIds.toList());
        
        final Map<String, dynamic> groundDataMap = {};
        for (var row in (groundsResponse as List)) {
           groundDataMap[row['id'].toString()] = {
             'name': row['name'],
             'location_name': (row['locations'] is Map) ? row['locations']['name'] : null,
           };
        }
        
        for (var booking in uniqueBookings.values) {
           final gid = booking['ground_id']?.toString();
           if (gid != null && groundDataMap.containsKey(gid)) {
              if (booking['grounds'] == null) {
                 booking['grounds'] = {};
              }
              if (booking['grounds']['location_name'] == null) {
                 booking['grounds']['location_name'] = groundDataMap[gid]['location_name'];
              }
              if (booking['grounds']['name'] == null) {
                 booking['grounds']['name'] = groundDataMap[gid]['name'];
              }
           }
        }
      } catch (e) {
        debugPrint("[BOOKING_REPO] Failed to fetch ground locations: $e");
      }
    }

    debugPrint("[BOOKING_REPO] Bookings fetched: ${data.length}, Unique: ${uniqueBookings.length}");
    return uniqueBookings.values.map((json) => BookingModel.fromJson(json)).toList();
  }
}
