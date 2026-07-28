import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PaymentRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// CREATE RAZORPAY ORDER VIA EDGE FUNCTION
  Future<Map<String, dynamic>> createOrder(int amount) async {
    debugPrint('PaymentRepository: createOrder called with amount: $amount');
    try {
      final response = await _supabase.functions.invoke(
        'create-order',
        body: {'amount': amount},
      );
      debugPrint('PaymentRepository: create-order Response Status: ${response.status}');

      if (response.status != 200) {
        debugPrint('PaymentRepository: create-order Error Data: ${response.data}');
        throw Exception('Failed to create order: ${response.data}');
      }

      return response.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('PaymentRepository: createOrder catch error: $e');
      throw Exception('Payment Order Error: $e');
    }
  }

  /// VERIFY PAYMENT VIA EDGE FUNCTION
  Future<bool> verifyPayment({
    required String orderId,
    required String paymentId,
    required String signature,
  }) async {
    debugPrint('PaymentRepository: verifyPayment called');
    try {
      final response = await _supabase.functions.invoke(
        'verify-payment',
        body: {
          'razorpay_order_id': orderId,
          'razorpay_payment_id': paymentId,
          'razorpay_signature': signature,
        },
      );
      debugPrint('PaymentRepository: verify-payment Response Status: ${response.status}');

      if (response.status != 200) {
        debugPrint('PaymentRepository: verify-payment Error: ${response.data}');
        return false;
      }

      final success = response.data['success'] == true;
      debugPrint('PaymentRepository: verify-payment Success flag: $success');
      return success;
    } catch (e) {
      debugPrint('PaymentRepository: verifyPayment catch error: $e');
      return false;
    }
  }

  /// SAVE BOOKING TO DATABASE
  Future<Map<String, dynamic>> saveBooking({
    required String groundId,
    required DateTime slotTime,
    required int amount,
    required String orderId,
    required String paymentId,
    required String signature,
    String? sportName,
    String? period,
    List<String>? slotStartTimes,
  }) async {
    debugPrint('PaymentRepository: saveBooking called');
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final bookingData = {
      'user_id': user.uid,
      'ground_id': groundId,
      'slot_time': slotTime.toUtc().toIso8601String(),
      'amount': amount,
      'status': 'paid',
      'razorpay_order_id': orderId,
      'razorpay_payment_id': paymentId,
      'razorpay_signature': signature,
      'sport_name': sportName,
      'period': period,
    };
    
    debugPrint('PaymentRepository: Inserting booking via RPC');

    final combinedPeriod = "${period ?? 'Day'}|${slotStartTimes?.join(',') ?? ''}";

    final response = await _supabase.rpc('save_booking', params: {
      'p_user_id': user.uid,
      'p_ground_id': groundId,
      'p_slot_time': slotTime.toUtc().toIso8601String(),
      'p_amount': amount,
      'p_status': 'paid',
      'p_sport_name': sportName,
      'p_period': combinedPeriod,
      'p_razorpay_order_id': orderId,
      'p_razorpay_payment_id': paymentId,
      'p_razorpay_signature': signature,
    });
    debugPrint('PaymentRepository: saveBooking completed');

    // Sync: Update slots table to mark as booked
    if (slotStartTimes != null && slotStartTimes.isNotEmpty) {
      final formattedDate = "${slotTime.year}-${slotTime.month.toString().padLeft(2, '0')}-${slotTime.day.toString().padLeft(2, '0')}";
      for (final startTime in slotStartTimes) {
        await _supabase.rpc('upsert_slot', params: {
          'p_ground_id': groundId,
          'p_date': formattedDate,
          'p_start_time': startTime,
          'p_status': 'booked',
          'p_price': (amount / slotStartTimes.length).toInt(),
        });
      }
    }

    return response as Map<String, dynamic>;
  }

  /// SAVE DIRECT BOOKING (BYPASS PAYMENT)
  Future<Map<String, dynamic>> saveDirectBooking({
    required String groundId,
    required DateTime date,
    required List<String> slotStartTimes,
    required int amount,
    String? sportName,
    String? period,
  }) async {
    debugPrint('PaymentRepository: saveDirectBooking called - Ground: $groundId, Date: $date, Amount: $amount');
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('PaymentRepository: Error - User not authenticated');
      throw Exception('User not authenticated');
    }

    try {
      final combinedPeriod = "${period ?? 'Day'}|${slotStartTimes.join(',')}";

      debugPrint('PaymentRepository: Inserting booking via RPC');
      final bookingResponse = await _supabase.rpc('save_booking', params: {
        'p_user_id': user.uid,
        'p_ground_id': groundId,
        'p_slot_time': date.toUtc().toIso8601String(),
        'p_amount': amount,
        'p_status': 'confirmed',
        'p_sport_name': sportName,
        'p_period': combinedPeriod,
      });
      debugPrint('PaymentRepository: Booking record created successfully');

      // 2. Block Slots in Database via RPC
      final formattedDate = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      debugPrint('PaymentRepository: Blocking ${slotStartTimes.length} slots for date: $formattedDate');

      for (final startTime in slotStartTimes) {
        debugPrint('PaymentRepository: Upserting slot: $startTime');
        await _supabase.rpc('upsert_slot', params: {
          'p_ground_id': groundId,
          'p_date': formattedDate,
          'p_start_time': startTime,
          'p_status': 'booked',
          'p_price': (amount / slotStartTimes.length).toInt(),
        });
        debugPrint('PaymentRepository: Slot $startTime upsert completed');
      }

      debugPrint('PaymentRepository: saveDirectBooking FULLY completed');
      return bookingResponse as Map<String, dynamic>;
    } catch (e) {
      debugPrint('PaymentRepository: EXCEPTION in saveDirectBooking: $e');
      if (e is PostgrestException) {
        debugPrint('Postgrest Details - Message: ${e.message}, Code: ${e.code}, Hint: ${e.hint}');
      }
      rethrow;
    }
  }
}
