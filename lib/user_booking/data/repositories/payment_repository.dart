import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  }) async {
    debugPrint('PaymentRepository: saveBooking called');
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final bookingData = {
      'user_id': user.id,
      'ground_id': groundId,
      'slot_time': slotTime.toIso8601String(),
      'amount': amount,
      'status': 'paid',
      'razorpay_order_id': orderId,
      'razorpay_payment_id': paymentId,
      'razorpay_signature': signature,
    };
    
    debugPrint('PaymentRepository: Inserting booking: $bookingData');

    final response = await _supabase.from('bookings').insert(bookingData).select().single();
    debugPrint('PaymentRepository: saveBooking completed');
    return response;
  }

  /// SAVE DIRECT BOOKING (BYPASS PAYMENT)
  Future<Map<String, dynamic>> saveDirectBooking({
    required String groundId,
    required DateTime date,
    required List<String> slotStartTimes,
    required int amount,
  }) async {
    debugPrint('PaymentRepository: saveDirectBooking called - Ground: $groundId, Date: $date, Amount: $amount');
    final user = _supabase.auth.currentUser;
    if (user == null) {
      debugPrint('PaymentRepository: Error - User not authenticated');
      throw Exception('User not authenticated');
    }

    try {
      // 1. Create Booking Record
      final bookingData = {
        'user_id': user.id,
        'ground_id': groundId,
        'slot_time': date.toIso8601String(),
        'amount': amount,
        'status': 'confirmed',
      };

      debugPrint('PaymentRepository: Inserting into bookings... Data: $bookingData');
      final bookingResponse = await _supabase.from('bookings').insert(bookingData).select().single();
      debugPrint('PaymentRepository: Booking record created successfully');

      // 2. Block Slots in Database
      final formattedDate = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      debugPrint('PaymentRepository: Blocking ${slotStartTimes.length} slots for date: $formattedDate');

      for (final startTime in slotStartTimes) {
        debugPrint('PaymentRepository: Upserting slot: $startTime');
        await _supabase.from('slots').upsert({
          'ground_id': groundId,
          'date': formattedDate,
          'start_time': startTime,
          'status': 'booked',
          'price': (amount / slotStartTimes.length).toInt(),
        }, onConflict: 'ground_id, date, start_time');
        debugPrint('PaymentRepository: Slot $startTime upsert completed');
      }

      debugPrint('PaymentRepository: saveDirectBooking FULLY completed');
      return bookingResponse;
    } catch (e) {
      debugPrint('PaymentRepository: EXCEPTION in saveDirectBooking: $e');
      if (e is PostgrestException) {
        debugPrint('Postgrest Details - Message: ${e.message}, Code: ${e.code}, Hint: ${e.hint}');
      }
      rethrow;
    }
  }
}
