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
            .select('id, name, images, image_urls, ground_images(image_url), locations(name, address, city, location_images(image_url))')
            .inFilter('id', groundIds.toList());
        
        final Map<String, dynamic> groundDataMap = {};
        for (var row in (groundsResponse as List)) {
          final List<String> allImages = [];
          if (row['ground_images'] is List) {
            for (var img in (row['ground_images'] as List)) {
              if (img is Map && img['image_url'] != null) {
                allImages.add(img['image_url'].toString());
              }
            }
          }
          if (row['images'] is List) {
            allImages.addAll((row['images'] as List).map((i) => i.toString()));
          }
          if (row['image_urls'] is List) {
            allImages.addAll((row['image_urls'] as List).map((i) => i.toString()));
          }
          if (row['locations'] is Map && row['locations']['location_images'] is List) {
            for (var img in (row['locations']['location_images'] as List)) {
              if (img is Map && img['image_url'] != null) {
                allImages.add(img['image_url'].toString());
              }
            }
          }
          final uniqueImages = allImages.where((url) => url.isNotEmpty).toSet().toList();
          final mainImg = uniqueImages.isNotEmpty ? uniqueImages.first : '';

          groundDataMap[row['id'].toString()] = {
            'name': row['name'],
            'location_name': (row['locations'] is Map) ? row['locations']['name'] : null,
            'address': (row['locations'] is Map) ? row['locations']['address'] : null,
            'city': (row['locations'] is Map) ? row['locations']['city'] : null,
            'images': uniqueImages,
            'imageUrl': mainImg,
          };
        }
        
        for (var booking in uniqueBookings.values) {
          final gid = booking['ground_id']?.toString();
          if (gid != null && groundDataMap.containsKey(gid)) {
            if (booking['grounds'] == null) {
              booking['grounds'] = <String, dynamic>{};
            } else if (booking['grounds'] is Map) {
              booking['grounds'] = Map<String, dynamic>.from(booking['grounds'] as Map);
            }
            final gData = groundDataMap[gid] as Map<String, dynamic>;
            if (booking['grounds']['location_name'] == null) {
              booking['grounds']['location_name'] = gData['location_name'];
            }
            if (booking['grounds']['name'] == null) {
              booking['grounds']['name'] = gData['name'];
            }
            if (booking['grounds']['address'] == null && gData['address'] != null) {
              booking['grounds']['address'] = gData['address'];
            }
            if (booking['grounds']['city'] == null && gData['city'] != null) {
              booking['grounds']['city'] = gData['city'];
            }
            final existingImages = booking['grounds']['images'];
            if (existingImages == null || (existingImages is List && existingImages.isEmpty)) {
              booking['grounds']['images'] = gData['images'];
            }
            final existingImgUrl = booking['grounds']['imageUrl'];
            if (existingImgUrl == null || existingImgUrl.toString().isEmpty) {
              booking['grounds']['imageUrl'] = gData['imageUrl'];
            }
          }
        }
      } catch (e) {
        debugPrint("[BOOKING_REPO] Failed to fetch ground details: $e");
      }
    }

    debugPrint("[BOOKING_REPO] Bookings fetched: ${data.length}, Unique: ${uniqueBookings.length}");
    return uniqueBookings.values.map((json) => BookingModel.fromJson(json)).toList();
  }
}
