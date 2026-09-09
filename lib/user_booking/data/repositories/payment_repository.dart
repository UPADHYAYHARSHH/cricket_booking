import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:turfpro/common/services/remote_config_service.dart';
import 'package:turfpro/user_booking/domain/models/slot_models.dart';

class PaymentRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// CREATE CASHFREE ORDER VIA EDGE FUNCTION
  Future<Map<String, dynamic>> createOrder(int amount,
      {String? returnUrl}) async {
    debugPrint(
        'PaymentRepository: createOrder called with amount: $amount, returnUrl: $returnUrl');
    try {
      final Map<String, dynamic> body = {'amount': amount};
      if (returnUrl != null) {
        body['return_url'] = returnUrl;
      }

      final response = await _supabase.functions.invoke(
        'create-order',
        body: body,
      );
      debugPrint(
          'PaymentRepository: create-order Response Status: ${response.status}');

      if (response.status != 200) {
        debugPrint(
            'PaymentRepository: create-order Error Data: ${response.data}');
        throw Exception('Failed to create order: ${response.data}');
      }

      return response.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('PaymentRepository: createOrder catch error: $e');
      throw Exception('Payment Order Error: $e');
    }
  }

  /// VERIFY PAYMENT VIA EDGE FUNCTION
  Future<bool> verifyPayment({required String orderId}) async {
    debugPrint('PaymentRepository: verifyPayment called for order: $orderId');
    try {
      final response = await _supabase.functions.invoke(
        'verify-payment',
        body: {
          'order_id': orderId,
        },
      );
      debugPrint(
          'PaymentRepository: verify-payment Response Status: ${response.status}');

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

    debugPrint('PaymentRepository: Inserting booking via RPC');

    final combinedPeriod =
        "${period ?? 'Day'}|${slotStartTimes?.join(',') ?? ''}";

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
      final formattedDate =
          "${slotTime.year}-${slotTime.month.toString().padLeft(2, '0')}-${slotTime.day.toString().padLeft(2, '0')}";
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

    await _updateBookingFinancialSnapshot(response, amount.toDouble());

    if (response is String) {
      return jsonDecode(response) as Map<String, dynamic>;
    }
    return response as Map<String, dynamic>;
  }

  /// Checks if a ground owner has enabled require_booking_approval
  Future<bool> checkOwnerRequiresApproval(String ownerId) async {
    if (ownerId.isEmpty) return false;
    try {
      final res = await _supabase
          .from('owner_details')
          .select('require_booking_approval')
          .eq('id', ownerId)
          .maybeSingle();
      return res?['require_booking_approval'] == true;
    } catch (e) {
      debugPrint('Error checking owner approval setting: $e');
      return false;
    }
  }

  /// Saves a booking request (status = 'requested') when owner approval is required
  Future<Map<String, dynamic>> requestBooking({
    required String groundId,
    DateTime? slotTime,
    DateTime? bookingDate,
    num? amount,
    num? totalAmount,
    String? sportName,
    String? sport,
    String? period,
    List<String>? slotStartTimes,
    List<TimeSlot>? selectedSlots,
    String? groundName,
    String? groundAddress,
    int appliedPoints = 0,
    double appliedWallet = 0.0,
  }) async {
    debugPrint('PaymentRepository: requestBooking called');
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final effectiveSlotTime = slotTime ?? bookingDate ?? DateTime.now();
    final effectiveAmount = (amount ?? totalAmount ?? 0).toInt();
    final effectiveSport = sportName ?? sport ?? 'Sport';
    final effectiveSlotTimes = slotStartTimes ??
        selectedSlots?.map((s) => s.startTime).toList() ??
        <String>[];

    final combinedPeriod =
        "${period ?? 'Day'}|${effectiveSlotTimes.join(',')}";

    dynamic response;
    try {
      response = await _supabase.rpc('request_booking', params: {
        'p_user_id': user.uid,
        'p_ground_id': groundId,
        'p_slot_time': effectiveSlotTime.toUtc().toIso8601String(),
        'p_amount': effectiveAmount,
        'p_sport_name': effectiveSport,
        'p_period': combinedPeriod,
        'p_player_name': user.displayName ?? 'Player',
        'p_player_phone': user.phoneNumber ?? '',
      });
    } catch (e) {
      debugPrint('request_booking RPC not found, trying save_booking with status requested: $e');
      try {
        response = await _supabase.rpc('save_booking', params: {
          'p_user_id': user.uid,
          'p_ground_id': groundId,
          'p_slot_time': effectiveSlotTime.toUtc().toIso8601String(),
          'p_amount': effectiveAmount,
          'p_status': 'requested',
          'p_sport_name': effectiveSport,
          'p_period': combinedPeriod,
          'p_razorpay_order_id': 'REQUESTED',
          'p_razorpay_payment_id': 'PENDING',
          'p_razorpay_signature': '',
        });
      } catch (saveErr) {
        debugPrint('Fallback to direct insert for requestBooking: $saveErr');
        final res = await _supabase.from('bookings').insert({
          'user_id': user.uid,
          'ground_id': groundId,
          'slot_time': effectiveSlotTime.toUtc().toIso8601String(),
          'amount': effectiveAmount,
          'status': 'requested',
          'sport_name': effectiveSport,
          'period': combinedPeriod,
          'created_at': DateTime.now().toIso8601String(),
        }).select().single();
        response = res;
      }

      // Notify owner of new booking request
      try {
        final groundRes = await _supabase
            .from('grounds')
            .select('name, owner_id')
            .eq('id', groundId)
            .maybeSingle();
        final ownerId = groundRes?['owner_id'];
        final targetGroundName = groundName ?? groundRes?['name'] ?? 'the ground';
        if (ownerId != null) {
          final bookingId = response is Map ? response['id'] : null;
          await _supabase.from('notifications').insert({
            'user_id': ownerId,
            'title': 'New Booking Request! ⚡',
            'message':
                '${user.displayName ?? "A player"} requested a slot at $targetGroundName. You have 45 minutes to confirm.',
            'type': 'booking_request',
            'data': {
              'booking_id': bookingId,
              'ground_id': groundId,
              'amount': effectiveAmount,
            },
            'is_read': false,
            'created_at': DateTime.now().toIso8601String(),
          });
        }
      } catch (_) {}
    }

    // Sync: Update slots table to mark as held/requested
    if (effectiveSlotTimes.isNotEmpty) {
      final formattedDate =
          "${effectiveSlotTime.year}-${effectiveSlotTime.month.toString().padLeft(2, '0')}-${effectiveSlotTime.day.toString().padLeft(2, '0')}";
      for (final startTime in effectiveSlotTimes) {
        try {
          await _supabase.rpc('upsert_slot', params: {
            'p_ground_id': groundId,
            'p_date': formattedDate,
            'p_start_time': startTime,
            'p_status': 'held',
            'p_price': (effectiveAmount / effectiveSlotTimes.length).toInt(),
          });
        } catch (_) {}
      }
    }

    await _updateBookingFinancialSnapshot(response, effectiveAmount.toDouble());

    if (response is String) {
      return jsonDecode(response) as Map<String, dynamic>;
    }
    return response as Map<String, dynamic>;
  }

  /// Updates an approved booking to paid after user completes payment
  Future<Map<String, dynamic>> confirmApprovedBookingPayment({
    required String bookingId,
    required String paymentId,
    String? orderId,
    String signature = '',
    String? groundId,
    DateTime? slotTime,
    required double amount,
    List<String>? slotStartTimes,
  }) async {
    final Map<String, dynamic> updateData = {
      'status': 'paid',
      'razorpay_payment_id': paymentId,
    };
    if (orderId != null && orderId.isNotEmpty) {
      updateData['razorpay_order_id'] = orderId;
    }
    if (signature.isNotEmpty) {
      updateData['razorpay_signature'] = signature;
    }

    final updateRes = await _supabase
        .from('bookings')
        .update(updateData)
        .eq('id', bookingId)
        .select('*, grounds(name, owner_id)')
        .single();

    final effectiveGroundId =
        groundId ?? updateRes['ground_id']?.toString() ?? '';
    final rawSlotTime = slotTime ??
        (updateRes['slot_time'] != null
            ? DateTime.tryParse(updateRes['slot_time'].toString())
            : null);

    // Parse slotStartTimes from period if not provided
    List<String> effectiveSlotTimes = slotStartTimes ?? [];
    if (effectiveSlotTimes.isEmpty && updateRes['period'] != null) {
      final periodStr = updateRes['period'].toString();
      if (periodStr.contains('|')) {
        final parts = periodStr.split('|');
        if (parts.length > 1) {
          effectiveSlotTimes = parts[1]
              .split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList();
        }
      }
    }

    // Mark slot as permanently booked
    if (effectiveSlotTimes.isNotEmpty &&
        rawSlotTime != null &&
        effectiveGroundId.isNotEmpty) {
      final formattedDate =
          "${rawSlotTime.year}-${rawSlotTime.month.toString().padLeft(2, '0')}-${rawSlotTime.day.toString().padLeft(2, '0')}";
      for (final startTime in effectiveSlotTimes) {
        try {
          await _supabase.rpc('upsert_slot', params: {
            'p_ground_id': effectiveGroundId,
            'p_date': formattedDate,
            'p_start_time': startTime,
            'p_status': 'booked',
            'p_price': (amount / effectiveSlotTimes.length).toInt(),
          });
        } catch (_) {}
      }
    }

    await _updateBookingFinancialSnapshot(updateRes, amount);
    return updateRes;
  }

  /// Deletes or expires a booking and frees the slot
  Future<void> deleteOrExpireBooking(String bookingId, {String reason = 'expired'}) async {
    try {
      await _supabase.rpc('delete_or_expire_booking', params: {
        'p_booking_id': bookingId,
        'p_reason': reason,
      });
    } catch (_) {
      try {
        await _supabase.from('bookings').delete().eq('id', bookingId);
      } catch (_) {}
    }
  }

  Future<void> _updateBookingFinancialSnapshot(
      dynamic bookingResponse, double totalAmount) async {
    try {
      debugPrint(
          '?? _updateBookingFinancialSnapshot called with totalAmount: $totalAmount');
      debugPrint(
          '?? Raw bookingResponse: $bookingResponse (${bookingResponse.runtimeType})');

      String? bookingId;
      if (bookingResponse is Map) {
        bookingId = bookingResponse['id']?.toString() ??
            bookingResponse['booking_id']?.toString();
      } else if (bookingResponse is String) {
        try {
          final decoded = jsonDecode(bookingResponse);
          if (decoded is Map) {
            bookingId =
                decoded['id']?.toString() ?? decoded['booking_id']?.toString();
          }
        } catch (e) {
          debugPrint('?? Error decoding bookingResponse JSON: $e');
        }
      }

      final user = FirebaseAuth.instance.currentUser;

      // Fallback: If bookingId couldn't be extracted from RPC response, find latest booking for user
      if ((bookingId == null || bookingId.isEmpty) && user != null) {
        debugPrint(
            '?? bookingId not found in RPC response, querying latest booking for user ${user.uid}...');
        final List latestRows = await _supabase
            .from('bookings')
            .select('id')
            .eq('user_id', user.uid)
            .order('created_at', ascending: false)
            .limit(1);
        if (latestRows.isNotEmpty) {
          bookingId = latestRows.first['id']?.toString();
          debugPrint('?? Found latest bookingId from DB query: $bookingId');
        }
      }

      double currentPlatformFee = RemoteConfigService().platformFee;
            double currentCommissionRate = RemoteConfigService().commissionRate;
      bool currentCommissionIsPercentage =
          RemoteConfigService().commissionIsPercentage;

      final double baseAmount =
          (totalAmount - currentPlatformFee).clamp(0.0, totalAmount);
      final double commissionDeduction = currentCommissionIsPercentage
          ? (baseAmount * (currentCommissionRate / 100.0))
          : currentCommissionRate;
      final double ownerEarnings =
          (baseAmount - commissionDeduction).clamp(0.0, baseAmount);

      if (bookingId != null && bookingId.isNotEmpty) {
        final updateRes = await _supabase
            .from('bookings')
            .update({
              'platform_fee': currentPlatformFee,
              'commission_rate': currentCommissionRate,
              'commission_is_percentage': currentCommissionIsPercentage,
              'base_amount': baseAmount,
              'owner_earnings': ownerEarnings,
            })
            .eq('id', bookingId)
            .select();
        debugPrint(
            '? FINANCIAL SNAPSHOT UPDATED FOR BOOKING $bookingId: $updateRes');
      } else {
        debugPrint('? FAILED TO RESOLVE BOOKING ID FOR FINANCIAL SNAPSHOT!');
      }
    } catch (e, stack) {
      debugPrint('? EXCEPTION IN _updateBookingFinancialSnapshot: $e\n$stack');
    }
  }

  /// SAVE DIRECT BOOKING (BYPASS PAYMENT)
  Future<Map<String, dynamic>> saveDirectBooking({
    required String groundId,
    required DateTime date,
    required List<String> slotStartTimes,
    required int amount,
    String? sportName,
    String? period,
    String? orderId,
  }) async {
    debugPrint(
        'PaymentRepository: saveDirectBooking called - Ground: $groundId, Date: $date, Amount: $amount');
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('PaymentRepository: Error - User not authenticated');
      throw Exception('User not authenticated');
    }

    try {
      final combinedPeriod = "${period ?? 'Day'}|${slotStartTimes.join(',')}";

      debugPrint('PaymentRepository: Inserting booking via RPC');
      final Map<String, dynamic> rpcParams = {
        'p_user_id': user.uid,
        'p_ground_id': groundId,
        'p_slot_time': date.toUtc().toIso8601String(),
        'p_amount': amount,
        'p_status': 'paid',
        'p_sport_name': sportName,
        'p_period': combinedPeriod,
      };

      if (orderId != null) {
        rpcParams['p_razorpay_order_id'] = orderId;
      }

      debugPrint('PaymentRepository: Inserting booking via RPC with params: $rpcParams');
      final bookingResponse =
          await _supabase.rpc('save_booking', params: rpcParams);
      debugPrint('PaymentRepository: Booking record created successfully. Response: $bookingResponse');

      await _updateBookingFinancialSnapshot(bookingResponse, amount.toDouble());

      // 2. Block Slots in Database via RPC
      final formattedDate =
          "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      debugPrint(
          'PaymentRepository: Blocking ${slotStartTimes.length} slots for date: $formattedDate');

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

      // 3. Manually send push notification to owner
      try {
        final groundData = await _supabase
            .from('grounds')
            .select('owner_id, name')
            .eq('id', groundId)
            .single();
            
        final String ownerId = groundData['owner_id']?.toString() ?? '';
        final String groundName = groundData['name']?.toString() ?? 'your turf';
        
        String bookingId = '';
        if (bookingResponse is Map) {
          bookingId = bookingResponse['id']?.toString() ?? '';
        } else if (bookingResponse is String) {
          try {
            final decoded = jsonDecode(bookingResponse);
            bookingId = decoded['id']?.toString() ?? '';
          } catch (_) {}
        }

        if (ownerId.isNotEmpty) {
          await _supabase.from('notifications').insert({
            'user_id': ownerId,
            'title': 'New Booking',
            'message': 'You have a new booking at $groundName.',
            'type': 'booking',
            'data': {'booking_id': bookingId},
            'is_read': false,
            'created_at': DateTime.now().toUtc().toIso8601String(),
          });
          debugPrint('PaymentRepository: Manually inserted push notification for owner.');
        }
      } catch (e) {
        debugPrint('PaymentRepository: Error sending owner notification: $e');
      }

      debugPrint('PaymentRepository: saveDirectBooking FULLY completed');

      if (bookingResponse is String) {
        return jsonDecode(bookingResponse) as Map<String, dynamic>;
      }
      return bookingResponse as Map<String, dynamic>;
    } catch (e) {
      debugPrint('PaymentRepository: EXCEPTION in saveDirectBooking: $e');
      if (e is PostgrestException) {
        debugPrint(
            'Postgrest Details - Message: ${e.message}, Code: ${e.code}, Hint: ${e.hint}');
      }
      rethrow;
    }
  }
}

