import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:turfpro/common/services/remote_config_service.dart';
import 'package:turfpro/common/utils/booking_time_util.dart';
import 'package:turfpro/user_booking/domain/models/slot_models.dart';
import 'package:turfpro/user_booking/domain/models/booking_summary_data.dart';

class PaymentRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<String> _fetchUserName(String uid) async {
    try {
      final res = await _supabase.from('users').select('name').eq('id', uid).maybeSingle();
      if (res != null && res['name']?.toString().trim().isNotEmpty == true) {
        return res['name'].toString().trim();
      }
    } catch (_) {}
    return 'A player';
  }

  // TEMPORARILY DISABLED: Commented out to prevent duplicate push notifications.
  // The backend database trigger handles notification dispatch automatically,
  // or client invocation is silenced so only 1 notification is received.
  Future<void> _invokePushNotification(String notificationId) async {
    /*
    try {
      final res = await _supabase.functions.invoke('send-push-notification', body: {
        'notification_id': notificationId,
      });
      debugPrint('[PaymentRepository] Push notification response: ${res.data}');
    } catch (e) {
      debugPrint('[PaymentRepository] Push notification invoke error: $e');
    }
    */
  }

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
    BookingSummaryData? summaryData,
  }) async {
    debugPrint('PaymentRepository: saveBooking called');
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');

    debugPrint('PaymentRepository: Inserting booking via RPC');

    final String cleanPeriodLabel;
    if (period != null &&
        {'morning', 'afternoon', 'evening', 'night'}.contains(period.trim().toLowerCase())) {
      cleanPeriodLabel = '${period.trim()[0].toUpperCase()}${period.trim().substring(1).toLowerCase()}';
    } else {
      cleanPeriodLabel = BookingTimeUtil.resolvePeriodLabel(
          slotStartTimes?.isNotEmpty == true ? slotStartTimes!.first : null);
    }
    final combinedPeriod =
        "$cleanPeriodLabel|${slotStartTimes?.join(',') ?? ''}";

    DateTime finalSlotDateTime = slotTime;
    if (slotStartTimes != null && slotStartTimes.isNotEmpty) {
      String firstSlot = slotStartTimes.first.trim();
      if (firstSlot.contains('-')) {
        firstSlot = firstSlot.split('-').first.trim();
      }
      final timeParts = firstSlot.split(':');
      if (timeParts.length >= 2) {
        int h = int.tryParse(timeParts[0]) ?? 0;
        final mPart = timeParts[1].trim().split(' ');
        final m = int.tryParse(mPart[0]) ?? 0;
        final amPm = mPart.length > 1 ? mPart[1].toUpperCase() : '';
        if (amPm == 'PM' && h != 12) h += 12;
        if (amPm == 'AM' && h == 12) h = 0;
        finalSlotDateTime =
            DateTime(slotTime.year, slotTime.month, slotTime.day, h, m);
      }
    }

    final response = await _supabase.rpc('save_booking', params: {
      'p_user_id': user.uid,
      'p_ground_id': groundId,
      'p_slot_time': finalSlotDateTime.toUtc().toIso8601String(),
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

    // Notify owner of new booking and payment
    try {
      final groundRes = await _supabase
          .from('grounds')
          .select('name, owner_id, locations(owner_id)')
          .eq('id', groundId)
          .maybeSingle();
      final ownerId = groundRes?['owner_id']?.toString() ??
          groundRes?['locations']?['owner_id']?.toString();
      final targetGroundName = groundRes?['name']?.toString() ?? 'your venue';
      final playerName = user.displayName?.trim().isNotEmpty == true
          ? user.displayName!
          : await _fetchUserName(user.uid);

      String? bookingId;
      if (response is Map) {
        bookingId = response['id']?.toString();
      } else if (response is String) {
        try {
          final decoded = jsonDecode(response);
          if (decoded is Map) bookingId = decoded['id']?.toString();
        } catch (_) {}
      }

      if (ownerId != null && ownerId.isNotEmpty) {
        final notifInsert = await _supabase.from('notifications').insert({
          'user_id': ownerId,
          'title': 'New Booking! ⚡ Confirmed',
          'message':
              '$playerName booked a slot at $targetGroundName for ₹$amount.',
          'type': 'booking_confirmed',
          'data': {
            'booking_id': bookingId,
            'ground_id': groundId,
            'amount': amount,
          },
          'is_read': false,
          'created_at': DateTime.now().toUtc().toIso8601String(),
        }).select('id').maybeSingle();

        final notifId = notifInsert?['id']?.toString();
        if (notifId != null) {
          _invokePushNotification(notifId);
        }
      }
    } catch (e) {
      debugPrint('Error sending owner notification for saveBooking: $e');
    }

    await _updateBookingFinancialSnapshot(response, amount.toDouble(),
        summaryData: summaryData);

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
    BookingSummaryData? summaryData,
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

    // ---- Canonical period-label resolver (SINGLE SOURCE OF TRUTH).
    // Mirrors slot_selection_widgets._getSlotPeriod so the DB label
    // always matches what the user saw in the UI grid:
    //   Morning   = 06:00 – 12:00
    //   Afternoon = 12:00 – 16:00
    //   Evening   = 16:00 – 20:00
    //   Night     = 20:00 – 06:00   (includes midnight hours)
    //   Midnight  = fallback for empty strings
    String resolvePeriodLabel(String? startTimeLabel) {
      if (startTimeLabel == null || startTimeLabel.trim().isEmpty) {
        return 'Night';
      }
      final t = startTimeLabel.trim().toUpperCase();
      final parts = t.split(' ');
      final hhmm = parts.first.split(':');
      int h;
      try {
        h = int.parse(hhmm.first);
      } catch (_) {
        return 'Night';
      }
      final ampm = parts.length > 1 ? parts[1] : '';
      if (ampm == 'PM' && h != 12) h += 12;
      if (ampm == 'AM' && h == 12) h = 0;
      if (h >= 6 && h < 12) return 'Morning';
      if (h >= 12 && h < 16) return 'Afternoon';
      if (h >= 16 && h < 20) return 'Evening';
      return 'Night';
    }

    // Choose the period label:
    //   1) explicit caller-provided `period` wins
    //   2) else derive from the FIRST slot's start time (matches grid grouping)
    //   3) else fall back to "Night" (covers midnight / legacy case)
    String derivedLabel;
    if (period != null && period.trim().isNotEmpty) {
      derivedLabel = period.trim();
    } else if (effectiveSlotTimes.isNotEmpty) {
      derivedLabel = resolvePeriodLabel(effectiveSlotTimes.first);
    } else {
      derivedLabel = resolvePeriodLabel(null);
    }
    debugPrint('[PAYMENT_REPO] slotStartTimes=$effectiveSlotTimes period=$period -> derivedLabel=$derivedLabel');

    final combinedPeriod = "$derivedLabel|${effectiveSlotTimes.join(',')}";
    debugPrint('[PAYMENT_REPO] combinedPeriod stored in DB = $combinedPeriod');

    final rc = RemoteConfigService();
    final double earlyPlatformFee = summaryData?.platformFee ?? rc.platformFee;
    final bool earlyIsPlatformFeeFree = summaryData?.isPlatformFeeFree ?? rc.isPlatformFeeFree;
    final double earlyGstAmount = summaryData?.gstAmount ?? rc.calculateGst(effectiveAmount.toDouble());
    final double earlyCommissionRate = rc.commissionRate;
    final bool earlyCommissionIsPercentage = rc.commissionIsPercentage;
    final double earlyBaseAmount = summaryData != null && summaryData.slotPrice > 0
        ? summaryData.slotPrice
        : (earlyIsPlatformFeeFree
            ? (effectiveAmount - earlyGstAmount).clamp(0.0, effectiveAmount.toDouble())
            : (effectiveAmount - earlyPlatformFee - earlyGstAmount).clamp(0.0, effectiveAmount.toDouble()));
    final double earlyCommissionDeduction = earlyCommissionIsPercentage
        ? (earlyBaseAmount * (earlyCommissionRate / 100.0))
        : earlyCommissionRate;
    final double earlyOwnerEarnings = (earlyBaseAmount - earlyCommissionDeduction).clamp(0.0, earlyBaseAmount);

    dynamic response;
    // request_booking RPC already inserts the owner 'booking_request'
    // notification server-side (atomic). Client must NOT insert a second one:
    // the old 4-sec dedup guard queried notifications via anon client, but RLS
    // (notifications_select_own needs auth.email()) returns 0 rows for
    // Firebase-Auth users, so the guard never fired -> owner got 2x pushes.
    bool serverInsertedRequestNotif = false;
    try {
      response = await _supabase.rpc('request_booking', params: {
        'p_user_id': user.uid,
        'p_ground_id': groundId,
        'p_slot_time': effectiveSlotTime.toUtc().toIso8601String(),
        'p_amount': effectiveAmount,
        'p_sport_name': effectiveSport,
        'p_period': combinedPeriod,
        'p_platform_fee': earlyPlatformFee,
        'p_commission_rate': earlyCommissionRate,
        'p_commission_is_percentage': earlyCommissionIsPercentage,
        'p_base_amount': earlyBaseAmount,
        'p_owner_earnings': earlyOwnerEarnings,
        'p_player_name': user.displayName ?? 'Player',
        'p_player_phone': user.phoneNumber ?? '',
      });
      serverInsertedRequestNotif = true;
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
        final notesData = summaryData != null
            ? Map<String, dynamic>.from(summaryData.toJson())
            : <String, dynamic>{
                'slot_price': earlyBaseAmount,
                'gst_amount': earlyGstAmount,
                'platform_fee': earlyPlatformFee,
                'is_platform_fee_free': earlyIsPlatformFeeFree,
                'points_discount': 0.0,
                'wallet_discount': 0.0,
                'grand_total': effectiveAmount,
              };
        notesData['owner_earnings'] = earlyOwnerEarnings;
        notesData['commission_fee'] = earlyCommissionDeduction;
        notesData['commission_rate'] = earlyCommissionRate;
        notesData['commission_is_percentage'] = earlyCommissionIsPercentage;
        notesData['is_platform_fee_free'] = earlyIsPlatformFeeFree;
        notesData['gst_amount'] = earlyGstAmount;

        final res = await _supabase.from('bookings').insert({
          'user_id': user.uid,
          'ground_id': groundId,
          'slot_time': effectiveSlotTime.toUtc().toIso8601String(),
          'amount': effectiveAmount,
          'status': 'requested',
          'sport_name': effectiveSport,
          'period': combinedPeriod,
          'platform_fee': earlyPlatformFee,
          'commission_rate': earlyCommissionRate,
          'commission_is_percentage': earlyCommissionIsPercentage,
          'base_amount': earlyBaseAmount,
          'owner_earnings': earlyOwnerEarnings,
          'notes': jsonEncode(notesData),
          'created_at': DateTime.now().toUtc().toIso8601String(),
        }).select().single();
        response = res;

        // Block the requested slots
        final dateStr = "${effectiveSlotTime.year}-${effectiveSlotTime.month.toString().padLeft(2, '0')}-${effectiveSlotTime.day.toString().padLeft(2, '0')}";
        for (final startTime in effectiveSlotTimes) {
          try {
            await _supabase.rpc('upsert_slot', params: {
              'p_ground_id': groundId,
              'p_date': dateStr,
              'p_start_time': startTime,
              'p_status': 'requested',
              'p_price': effectiveAmount > 0 ? (effectiveAmount / effectiveSlotTimes.length).round() : 0,
            });
          } catch (e) {
            debugPrint('Error updating slot status to requested: $e');
          }
        }
      }
    }

    // Extract bookingId from response
    String? bookingId;
    if (response is Map) {
      bookingId = response['id']?.toString();
    } else if (response is String) {
      try {
        final decoded = jsonDecode(response);
        if (decoded is Map) bookingId = decoded['id']?.toString();
      } catch (_) {}
    }

    // Notify owner of new booking request ONLY if the server RPC did not
    // already do it (fallback paths: save_booking / direct insert).
    // When request_booking RPC succeeded, its INSERT is the single source.
    if (!serverInsertedRequestNotif) {
    try {
      final groundRes = await _supabase
          .from('grounds')
          .select('name, owner_id, location_id, locations(owner_id)')
          .eq('id', groundId)
          .maybeSingle();
      final ownerId = groundRes?['owner_id']?.toString() ??
          groundRes?['locations']?['owner_id']?.toString();
      final targetGroundName = groundName ?? groundRes?['name']?.toString() ?? 'the venue';

      String playerName = user.displayName?.trim() ?? '';
      if (playerName.isEmpty) {
        playerName = await _fetchUserName(user.uid);
      }

      if (ownerId != null && ownerId.isNotEmpty) {
        // Fallback path only (server RPC unavailable): insert directly.
        // No recents-check here: RLS hides other rows from anon client,
        // so the check always looked empty and caused duplicates.
        final notifInsert = await _supabase.from('notifications').insert({
          'user_id': ownerId,
          'title': 'New Booking Request! ⚡',
          'message':
              '$playerName requested a slot at $targetGroundName. You have 45 minutes to confirm.',
          'type': 'booking_request',
          'data': {
            'booking_id': bookingId,
            'ground_id': groundId,
            'amount': effectiveAmount,
            'action': 'owner_approval_required',
          },
          'is_read': false,
          'created_at': DateTime.now().toUtc().toIso8601String(),
        }).select('id').maybeSingle();
        final notifId = notifInsert?['id']?.toString();

        if (notifId != null) {
          _invokePushNotification(notifId);
        }
      }
    } catch (notifErr) {
      debugPrint('Error sending owner request notification: $notifErr');
    }
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
            'p_status': 'requested',
            'p_price': (effectiveAmount / effectiveSlotTimes.length).toInt(),
          });
        } catch (_) {}
      }
    }

    await _updateBookingFinancialSnapshot(response, effectiveAmount.toDouble(),
        summaryData: summaryData);

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
    BookingSummaryData? summaryData,
  }) async {
    // Idempotency: if this booking is already paid (retry / double callback),
    // return it WITHOUT inserting a second owner notification.
    try {
      final existing = await _supabase
          .from('bookings')
          .select('id, status')
          .eq('id', bookingId)
          .maybeSingle();
      if (existing != null && existing['status'] == 'paid') {
        debugPrint('confirmApprovedBookingPayment: booking $bookingId already paid, skipping duplicate notification');
        return Map<String, dynamic>.from(existing);
      }
    } catch (_) {}
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

    // Notify owner of payment completion & booking confirmation (3. User do payment -> owner gets notification)
    try {
      final groundRes = await _supabase
          .from('grounds')
          .select('name, owner_id, location_id, locations(owner_id)')
          .eq('id', effectiveGroundId)
          .maybeSingle();
      final ownerId = groundRes?['owner_id']?.toString() ??
          groundRes?['locations']?['owner_id']?.toString();
      final targetGroundName = groundRes?['name']?.toString() ?? 'your venue';

      final user = FirebaseAuth.instance.currentUser;
      String playerName = user?.displayName?.trim() ?? '';
      if (playerName.isEmpty && user != null) {
        playerName = await _fetchUserName(user.uid);
      }
      if (playerName.isEmpty) playerName = 'A player';

      if (ownerId != null && ownerId.isNotEmpty) {
        final notifInsert = await _supabase.from('notifications').insert({
          'user_id': ownerId,
          'title': 'Payment Received! 💰 Booking Confirmed',
          'message':
              '$playerName completed payment of ₹${amount.toInt()} for $targetGroundName. Booking is confirmed!',
          'type': 'booking_confirmed',
          'data': {
            'booking_id': bookingId,
            'ground_id': effectiveGroundId,
            'amount': amount,
          },
          'is_read': false,
          'created_at': DateTime.now().toUtc().toIso8601String(),
        }).select('id').maybeSingle();

        final notifId = notifInsert?['id']?.toString();
        if (notifId != null) {
          _invokePushNotification(notifId);
        }
      }
    } catch (e) {
      debugPrint('Error notifying owner of approved booking payment: $e');
    }

    await _updateBookingFinancialSnapshot(updateRes, amount,
        summaryData: summaryData);
    return updateRes;
  }

  /// Deletes or expires a booking and frees the slot
  Future<void> deleteOrExpireBooking(String bookingId, {String reason = 'expired'}) async {
    debugPrint('=== [USER APP] [DELETE/EXPIRE BOOKING START] bookingId: $bookingId, reason: $reason ===');
    // 1. Fetch booking to get details needed to free the slots
    Map<String, dynamic>? bookingData;
    try {
      debugPrint('[deleteOrExpireBooking] Fetching booking details...');
      final fetched = await _supabase.from('bookings').select('*').eq('id', bookingId).maybeSingle();
      if (fetched != null) {
        bookingData = Map<String, dynamic>.from(fetched);
        debugPrint('[deleteOrExpireBooking] Fetched bookingData: $bookingData');
      } else {
        debugPrint('[deleteOrExpireBooking] Booking not found in DB before delete!');
      }
    } catch (e) {
      debugPrint('[deleteOrExpireBooking] Error fetching booking: $e');
    }

    try {
      debugPrint('[deleteOrExpireBooking] Calling delete_or_expire_booking RPC...');
      await _supabase.rpc('delete_or_expire_booking', params: {
        'p_booking_id': bookingId,
        'p_reason': reason,
      });
      debugPrint('[deleteOrExpireBooking] RPC succeeded.');
    } catch (e) {
      debugPrint('[deleteOrExpireBooking] RPC failed, falling back to direct delete: $e');
      try {
        await _supabase.from('bookings').delete().eq('id', bookingId);
        debugPrint('[deleteOrExpireBooking] Direct delete succeeded.');
      } catch (e2) {
        debugPrint('[deleteOrExpireBooking] Direct delete failed: $e2');
      }
    }

    // 2. Free the specific slots
    if (bookingData != null) {
      final groundId = bookingData['ground_id'];
      final slotTimeStr = bookingData['slot_time']?.toString();
      final periodStr = bookingData['period']?.toString();
      debugPrint('[deleteOrExpireBooking] Data to free slots -> groundId: $groundId, slotTimeStr: $slotTimeStr, periodStr: $periodStr');

      if (slotTimeStr != null && groundId != null && periodStr != null) {
        final slotDate = DateTime.tryParse(slotTimeStr)?.toLocal();
        debugPrint('[deleteOrExpireBooking] Parsed slotDate (local): $slotDate');
        if (slotDate != null) {
          final dateStr = "${slotDate.year}-${slotDate.month.toString().padLeft(2, '0')}-${slotDate.day.toString().padLeft(2, '0')}";
          debugPrint('[deleteOrExpireBooking] Formatted dateStr: $dateStr');
          
          if (periodStr.contains('|')) {
            final parts = periodStr.split('|');
            if (parts.length > 1) {
              final startTimes = parts[1].split(',').map((s) => s.trim()).where((s) => s.isNotEmpty);
              final amount = double.tryParse(bookingData['amount']?.toString() ?? '0') ?? 0;
              final startTimesList = startTimes.toList();
              final slotPrice = startTimesList.isNotEmpty ? (amount / startTimesList.length).toInt() : 0;
              debugPrint('[deleteOrExpireBooking] startTimesList: $startTimesList, calculated slotPrice: $slotPrice');

              for (final startTime in startTimesList) {
                try {
                  debugPrint('[deleteOrExpireBooking] Calling upsert_slot for $startTime...');
                  final res = await _supabase.rpc('upsert_slot', params: {
                    'p_ground_id': groundId,
                    'p_date': dateStr,
                    'p_start_time': startTime,
                    'p_status': 'available',
                    'p_price': slotPrice,
                  });
                  debugPrint('[deleteOrExpireBooking] upsert_slot success for $startTime. Res: $res');
                } catch (e) {
                  debugPrint('[deleteOrExpireBooking] Error in upsert_slot for $startTime: $e');
                }
              }
            } else {
              debugPrint('[deleteOrExpireBooking] periodStr parts length <= 1');
            }
          } else {
            debugPrint('[deleteOrExpireBooking] periodStr does not contain |');
          }
        } else {
          debugPrint('[deleteOrExpireBooking] slotDate parsing failed for $slotTimeStr');
        }
      } else {
        debugPrint('[deleteOrExpireBooking] Missing groundId, slotTimeStr, or periodStr');
      }
    } else {
      debugPrint('[deleteOrExpireBooking] Skipping slot free because bookingData is null.');
    }
    debugPrint('=== [USER APP] [DELETE/EXPIRE BOOKING END] ===');
  }

  Future<void> _updateBookingFinancialSnapshot(
      dynamic bookingResponse, double totalAmount,
      {BookingSummaryData? summaryData}) async {
    try {
      debugPrint(
          '🔍 _updateBookingFinancialSnapshot called with totalAmount: $totalAmount');
      debugPrint(
          '🔍 Raw bookingResponse: $bookingResponse (${bookingResponse.runtimeType})');

      String? bookingId;
      Map<String, dynamic>? responseMap;
      if (bookingResponse is Map) {
        responseMap = Map<String, dynamic>.from(bookingResponse);
        bookingId = responseMap['id']?.toString() ??
            responseMap['booking_id']?.toString();
      } else if (bookingResponse is String) {
        try {
          final decoded = jsonDecode(bookingResponse);
          if (decoded is Map) {
            responseMap = Map<String, dynamic>.from(decoded);
            bookingId =
                responseMap['id']?.toString() ?? responseMap['booking_id']?.toString();
          }
        } catch (e) {
          debugPrint('⚠️ Error decoding bookingResponse JSON: $e');
        }
      }

      final user = FirebaseAuth.instance.currentUser;

      // Fallback: If bookingId couldn't be extracted from RPC response, find latest booking for user
      if ((bookingId == null || bookingId.isEmpty) && user != null) {
        debugPrint(
            '🔍 bookingId not found in RPC response, querying latest booking for user ${user.uid}...');
        final List latestRows = await _supabase
            .from('bookings')
            .select('*')
            .eq('user_id', user.uid)
            .order('created_at', ascending: false)
            .limit(1);
        if (latestRows.isNotEmpty) {
          responseMap = Map<String, dynamic>.from(latestRows.first);
          bookingId = responseMap['id']?.toString();
          debugPrint('🔍 Found latest bookingId from DB query: $bookingId');
        }
      }

      // If summaryData was not directly passed, attempt to parse from booking notes
      BookingSummaryData? effectiveSummary = summaryData;
      if (effectiveSummary == null && responseMap != null && responseMap['notes'] != null) {
        try {
          final notesStr = responseMap['notes'].toString().trim();
          if (notesStr.startsWith('{') && notesStr.endsWith('}')) {
            effectiveSummary = BookingSummaryData.fromJson(jsonDecode(notesStr));
          }
        } catch (_) {}
      }

      // If still null, try fetching existing booking from DB to see if notes were stored earlier
      if (effectiveSummary == null && bookingId != null) {
        try {
          final existing = await _supabase.from('bookings').select('notes').eq('id', bookingId).maybeSingle();
          if (existing != null && existing['notes'] != null) {
            final notesStr = existing['notes'].toString().trim();
            if (notesStr.startsWith('{') && notesStr.endsWith('}')) {
              effectiveSummary = BookingSummaryData.fromJson(jsonDecode(notesStr));
            }
          }
        } catch (_) {}
      }

      final double currentPlatformFee = effectiveSummary?.platformFee ?? RemoteConfigService().platformFee;
      final bool isPlatformFeeFree = effectiveSummary?.isPlatformFeeFree ??
          RemoteConfigService().isPlatformFeeFree;
      final double currentGstAmount = effectiveSummary?.gstAmount ??
          RemoteConfigService().calculateGst(totalAmount);
      final double currentCommissionRate = RemoteConfigService().commissionRate;
      final bool currentCommissionIsPercentage =
          RemoteConfigService().commissionIsPercentage;

      // Deduct platform fee (if not free) and GST to resolve owner's gross slot base price
      final double baseAmount;
      if (effectiveSummary != null && effectiveSummary.slotPrice > 0) {
        baseAmount = effectiveSummary.slotPrice;
      } else if (isPlatformFeeFree) {
        baseAmount = (totalAmount - currentGstAmount).clamp(0.0, totalAmount);
      } else {
        baseAmount = (totalAmount - currentPlatformFee - currentGstAmount).clamp(0.0, totalAmount);
      }

      final double commissionDeduction = currentCommissionIsPercentage
          ? (baseAmount * (currentCommissionRate / 100.0))
          : currentCommissionRate;

      final double calculatedOwnerEarnings =
          (baseAmount - commissionDeduction).clamp(0.0, baseAmount);

      final Map<String, dynamic> notesMap = effectiveSummary != null
          ? Map<String, dynamic>.from(effectiveSummary.toJson())
          : <String, dynamic>{
              'slot_price': baseAmount,
              'gst_amount': currentGstAmount,
              'platform_fee': currentPlatformFee,
              'is_platform_fee_free': isPlatformFeeFree,
              'points_discount': 0.0,
              'wallet_discount': 0.0,
              'grand_total': totalAmount,
            };
      notesMap['owner_earnings'] = calculatedOwnerEarnings;
      notesMap['commission_fee'] = commissionDeduction;
      notesMap['commission_rate'] = currentCommissionRate;
      notesMap['commission_is_percentage'] = currentCommissionIsPercentage;
      notesMap['is_platform_fee_free'] = isPlatformFeeFree;
      notesMap['gst_amount'] = currentGstAmount;

      final Map<String, dynamic> updateFields = {
        'platform_fee': currentPlatformFee,
        'commission_rate': currentCommissionRate,
        'commission_is_percentage': currentCommissionIsPercentage,
        'base_amount': baseAmount,
        'owner_earnings': calculatedOwnerEarnings,
        'notes': jsonEncode(notesMap),
      };

      if (bookingId != null && bookingId.isNotEmpty) {
        final updateRes = await _supabase
            .from('bookings')
            .update(updateFields)
            .eq('id', bookingId)
            .select();
        debugPrint(
            '✅ FINANCIAL SNAPSHOT UPDATED FOR BOOKING $bookingId: $updateRes');
      } else {
        debugPrint('⚠️ FAILED TO RESOLVE BOOKING ID FOR FINANCIAL SNAPSHOT!');
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
    BookingSummaryData? summaryData,
  }) async {
    debugPrint(
        'PaymentRepository: saveDirectBooking called - Ground: $groundId, Date: $date, Amount: $amount');
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('PaymentRepository: Error - User not authenticated');
      throw Exception('User not authenticated');
    }

    try {
      final String cleanPeriodLabel;
      if (period != null &&
          {'morning', 'afternoon', 'evening', 'night'}.contains(period.trim().toLowerCase())) {
        cleanPeriodLabel = '${period.trim()[0].toUpperCase()}${period.trim().substring(1).toLowerCase()}';
      } else {
        cleanPeriodLabel = BookingTimeUtil.resolvePeriodLabel(
            slotStartTimes.isNotEmpty ? slotStartTimes.first : null);
      }
      final combinedPeriod = "$cleanPeriodLabel|${slotStartTimes.join(',')}";

      // Idempotency check: if a booking for this orderId already exists, return it
      if (orderId != null && orderId.isNotEmpty) {
        try {
          final existing = await _supabase
              .from('bookings')
              .select('*')
              .eq('razorpay_order_id', orderId)
              .maybeSingle();
          if (existing != null) {
            debugPrint(
                'PaymentRepository: Booking already exists for orderId: $orderId. Returning existing record.');
            return existing;
          }
        } catch (e) {
          debugPrint('PaymentRepository: Idempotency check error (ignoring): $e');
        }
      }

      DateTime finalSlotDateTime = date;
      if (slotStartTimes.isNotEmpty) {
        String firstSlot = slotStartTimes.first.trim();
        if (firstSlot.contains('-')) {
          firstSlot = firstSlot.split('-').first.trim();
        }
        final timeParts = firstSlot.split(':');
        if (timeParts.length >= 2) {
          int h = int.tryParse(timeParts[0]) ?? 0;
          final mPart = timeParts[1].trim().split(' ');
          final m = int.tryParse(mPart[0]) ?? 0;
          final amPm = mPart.length > 1 ? mPart[1].toUpperCase() : '';
          if (amPm == 'PM' && h != 12) h += 12;
          if (amPm == 'AM' && h == 12) h = 0;
          finalSlotDateTime =
              DateTime(date.year, date.month, date.day, h, m);
        }
      }

      debugPrint('PaymentRepository: Inserting booking via RPC');
      final Map<String, dynamic> rpcParams = {
        'p_user_id': user.uid,
        'p_ground_id': groundId,
        'p_slot_time': finalSlotDateTime.toUtc().toIso8601String(),
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

      await _updateBookingFinancialSnapshot(bookingResponse, amount.toDouble(),
          summaryData: summaryData);

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
          final notifInsert = await _supabase.from('notifications').insert({
            'user_id': ownerId,
            'title': 'New Booking',
            'message': 'You have a new booking at $groundName.',
            'type': 'booking_confirmed',
            'data': {'booking_id': bookingId},
            'is_read': false,
            'created_at': DateTime.now().toUtc().toIso8601String(),
          }).select('id').maybeSingle();
          final notifId = notifInsert?['id']?.toString();
          if (notifId != null) {
            _invokePushNotification(notifId);
          }
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

  /// Combines the date with the first slot start time from period (e.g. "Evening|09:00 PM")
  static DateTime resolveActualSlotStartTime(DateTime baseDate, String? period) {
    if (period != null && period.contains('|')) {
      final parts = period.split('|');
      if (parts.length > 1) {
        final times = parts[1]
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
        if (times.isNotEmpty) {
          String firstTime = times.first;
          if (firstTime.contains('-')) {
            firstTime = firstTime.split('-').first.trim();
          }
          final timeParts = firstTime.split(':');
          if (timeParts.length >= 2) {
            int h = int.tryParse(timeParts[0]) ?? 0;
            final mPart = timeParts[1].trim().split(' ');
            final m = int.tryParse(mPart[0]) ?? 0;
            final amPm = mPart.length > 1 ? mPart[1].toUpperCase() : '';
            if (amPm == 'PM' && h != 12) h += 12;
            if (amPm == 'AM' && h == 12) h = 0;
            final d = baseDate.toLocal();
            return DateTime(d.year, d.month, d.day, h, m);
          }
        }
      }
    }
    return baseDate;
  }

  /// Cancels an upcoming paid/confirmed booking and issues Playora Coins to wallet.
  Future<Map<String, dynamic>> cancelBookingByUser({
    required String bookingId,
    String reason = 'Changed my plans',
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('You must be logged in to cancel a booking.');
    }

    try {
      debugPrint('[PaymentRepository] Calling cancel_booking_by_user RPC for booking $bookingId...');
      final rpcRes = await _supabase.rpc('cancel_booking_by_user', params: {
        'p_booking_id': bookingId,
        'p_user_id': user.uid,
        'p_reason': reason,
      });

      if (rpcRes != null) {
        final Map<String, dynamic> resultMap = rpcRes is String
            ? jsonDecode(rpcRes)
            : Map<String, dynamic>.from(rpcRes as Map);
        if (resultMap['success'] == true) {
          debugPrint('[PaymentRepository] cancel_booking_by_user RPC succeeded: $resultMap');
          return resultMap;
        } else if (resultMap['error'] != null) {
          final errStr = resultMap['error'].toString().toLowerCase();
          // If the DB rejected because slot_time stored the creation time instead of actual slot time,
          // don't throw yet! Allow fallback to verify the actual slot time from period!
          if (!errStr.contains('after slot start time')) {
            throw Exception(resultMap['error']);
          }
          debugPrint('[PaymentRepository] RPC rejected for slot start time, verifying via period in fallback...');
        }
      }
    } catch (e) {
      debugPrint('[PaymentRepository] cancel_booking_by_user RPC error / checking fallback: $e');
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('already cancelled') ||
          errStr.contains('unauthorized')) {
        rethrow;
      }
    }

    // Direct fallback implementation if RPC was not deployed yet in DB
    try {
      debugPrint('[PaymentRepository] Executing direct cancellation fallback for $bookingId...');
      final fetched = await _supabase
          .from('bookings')
          .select('*, grounds(name, owner_id)')
          .eq('id', bookingId)
          .maybeSingle();
      if (fetched == null) throw Exception('Booking not found');

      final bookingData = Map<String, dynamic>.from(fetched);
      if (bookingData['user_id'] != user.uid) {
        throw Exception('Unauthorized: You can only cancel your own booking');
      }
      final currentStatus = (bookingData['status'] ?? '').toString().toLowerCase();
      if (currentStatus == 'cancelled') {
        throw Exception('Booking is already cancelled');
      }

      final rawSlotTime = bookingData['slot_time'] != null
          ? DateTime.tryParse(bookingData['slot_time'].toString())
          : null;
      final periodStr = bookingData['period']?.toString() ?? '';
      final actualSlotTime = resolveActualSlotStartTime(rawSlotTime ?? DateTime.now(), periodStr);

      if (actualSlotTime.isBefore(DateTime.now())) {
        throw Exception('Cannot cancel booking after slot start time');
      }

      final amount =
          double.tryParse(bookingData['amount']?.toString() ?? '0') ?? 0.0;
      final platformFee =
          double.tryParse(bookingData['platform_fee']?.toString() ?? '0') ?? 0.0;
      final baseAmount =
          double.tryParse(bookingData['base_amount']?.toString() ?? '0') ??
              (amount - platformFee);
      final eligibleAmount = baseAmount > 0 ? baseAmount : amount;

      // Compute quote dynamically using RemoteConfigService with actualSlotTime
      final quote = RemoteConfigService().getCancellationQuote(
        slotTime: actualSlotTime,
        eligibleAmount: eligibleAmount,
      );

      final coinsToIssue = quote.coinsToReceive;
      final ownerComp =
          (eligibleAmount - coinsToIssue).clamp(0.0, eligibleAmount);
      final nowUtc = DateTime.now().toUtc();

      // 1. Update booking record
      try {
        await _supabase.from('bookings').update({
          'status': 'cancelled',
          'cancelled_at': nowUtc.toIso8601String(),
          'cancellation_reason': reason,
          'cancelled_by': 'user',
          'cancellation_coins_issued': coinsToIssue,
          'owner_compensation': ownerComp,
          'owner_earnings': ownerComp,
        }).eq('id', bookingId);
      } catch (colErr) {
        debugPrint('[PaymentRepository] Full booking cancellation update failed (missing columns?): $colErr');
        // Gracefully update just status so booking is cancelled even if migration hasn't been run
        try {
          await _supabase.from('bookings').update({
            'status': 'cancelled',
          }).eq('id', bookingId);
          debugPrint('[PaymentRepository] Successfully updated booking status to cancelled via fallback');
        } catch (minErr) {
          debugPrint('[PaymentRepository] Failed to update booking status: $minErr');
          rethrow;
        }
      }

      // 2. Free the reserved slots
      final groundId = bookingData['ground_id']?.toString() ?? '';
      if (groundId.isNotEmpty && rawSlotTime != null && periodStr.contains('|')) {
        final parts = periodStr.split('|');
        if (parts.length > 1) {
          final slotDate = rawSlotTime.toLocal();
          final dateStr =
              "${slotDate.year}-${slotDate.month.toString().padLeft(2, '0')}-${slotDate.day.toString().padLeft(2, '0')}";
          final startTimes = parts[1]
              .split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList();
          final slotPrice = startTimes.isNotEmpty
              ? (eligibleAmount / startTimes.length).toInt()
              : eligibleAmount.toInt();

          for (final st in startTimes) {
            try {
              await _supabase.rpc('upsert_slot', params: {
                'p_ground_id': groundId,
                'p_date': dateStr,
                'p_start_time': st,
                'p_status': 'available',
                'p_price': slotPrice,
              });
            } catch (_) {
              try {
                await _supabase
                    .from('slots')
                    .update({'status': 'available'})
                    .eq('ground_id', groundId)
                    .eq('date', dateStr)
                    .eq('start_time', st);
              } catch (_) {}
            }
          }
        }
      }

      // 3. Credit wallet balance
      if (coinsToIssue > 0) {
        try {
          final walletRow = await _supabase
              .from('wallets')
              .select('balance')
              .eq('user_id', user.uid)
              .maybeSingle();
          final currentBal =
              (walletRow?['balance'] as num?)?.toDouble() ?? 0.0;
          final newBal = currentBal + coinsToIssue;
          await _supabase.from('wallets').upsert({
            'user_id': user.uid,
            'balance': newBal,
            'updated_at': nowUtc.toIso8601String(),
          }, onConflict: 'user_id');

          try {
            await _supabase.from('wallet_transactions').insert({
              'user_id': user.uid,
              'amount': coinsToIssue,
              'type': 'cancellation_credit',
              'description':
                  'Booking cancelled (${quote.refundPercent.toInt()}% refund)',
              'reference_id': bookingId,
              'created_at': nowUtc.toIso8601String(),
            });
          } catch (_) {
            // Fallback for tables without reference_id or with type IN ('credit', 'debit')
            try {
              await _supabase.from('wallet_transactions').insert({
                'user_id': user.uid,
                'amount': coinsToIssue,
                'type': 'credit',
                'description':
                    'Booking cancelled (${quote.refundPercent.toInt()}% refund)',
                'created_at': nowUtc.toIso8601String(),
              });
            } catch (innerErr) {
              debugPrint('Error inserting wallet transaction: $innerErr');
            }
          }
        } catch (wErr) {
          debugPrint('Error updating wallet: $wErr');
        }
      }

      // 3b. Deduct difference from owner_wallets in database
      final ownerIdForWallet = (bookingData['grounds'] is Map &&
              bookingData['grounds']['owner_id'] != null)
          ? bookingData['grounds']['owner_id'].toString()
          : null;
      final previousEarnings =
          (bookingData['owner_earnings'] as num?)?.toDouble() ??
          (bookingData['base_amount'] as num?)?.toDouble() ??
          amount;
      if (ownerIdForWallet != null && ownerIdForWallet.isNotEmpty && previousEarnings > ownerComp) {
        try {
          final diff = previousEarnings - ownerComp;
          final existingOwnerWallet = await _supabase
              .from('owner_wallets')
              .select()
              .eq('owner_id', ownerIdForWallet)
              .maybeSingle();

          if (existingOwnerWallet != null) {
            final curTotal = (existingOwnerWallet['total_earnings'] as num?)?.toDouble() ?? 0.0;
            final curAvail = (existingOwnerWallet['available_balance'] as num?)?.toDouble() ?? 0.0;

            final newTotal = (curTotal - diff).clamp(0.0, double.infinity);
            final newAvail = (curAvail - diff).clamp(0.0, double.infinity);

            await _supabase.from('owner_wallets').update({
              'total_earnings': newTotal,
              'available_balance': newAvail,
              'updated_at': nowUtc.toIso8601String(),
            }).eq('owner_id', ownerIdForWallet);
          }
        } catch (owErr) {
          debugPrint('Error deducting from owner_wallets in fallback: $owErr');
        }
      }

      // 4. Send Notifications
      try {
        final groundName = (bookingData['grounds'] is Map &&
                bookingData['grounds']['name'] != null)
            ? bookingData['grounds']['name'].toString()
            : 'the venue';
        final ownerId = (bookingData['grounds'] is Map &&
                bookingData['grounds']['owner_id'] != null)
            ? bookingData['grounds']['owner_id'].toString()
            : null;

        if (ownerId != null && ownerId.isNotEmpty) {
          await _supabase.from('notifications').insert({
            'user_id': ownerId,
            'title': 'Slot Re-opened (Booking Cancelled)',
            'message':
                'Booking #${bookingData['display_id'] ?? ''} for $groundName was cancelled by player. The slot is now available.',
            'type': 'booking_cancelled',
            'data': {
              'booking_id': bookingId,
              'ground_name': groundName,
              'reason': reason,
            },
            'is_read': false,
            'created_at': nowUtc.toIso8601String(),
          });
        }

        await _supabase.from('notifications').insert({
          'user_id': user.uid,
          'title': 'Booking Cancelled',
          'message':
              'Your booking for $groundName was cancelled. ₹${coinsToIssue.toStringAsFixed(0)} Playora Coins added to your wallet.',
          'type': 'cancellation_coins_credited',
          'data': {
            'booking_id': bookingId,
            'coins_issued': coinsToIssue,
          },
          'is_read': false,
          'created_at': nowUtc.toIso8601String(),
        });
      } catch (nErr) {
        debugPrint('Error inserting cancellation notifications: $nErr');
      }

      // Record in cancellation_history
      try {
        final groundName = (bookingData['grounds'] is Map &&
                bookingData['grounds']['name'] != null)
            ? bookingData['grounds']['name'].toString()
            : (bookingData['ground_name']?.toString() ?? 'Venue');
        await _supabase.from('cancellation_history').insert({
          'booking_id': bookingId,
          'user_id': user.uid,
          'ground_id': bookingData['ground_id'],
          'ground_name': groundName,
          'sport_name': bookingData['sport_name'] ?? bookingData['sport'],
          'slot_time': bookingData['slot_time'],
          'cancelled_by': 'user',
          'cancellation_reason': reason,
          'refund_percent': quote.refundPercent,
          'coins_issued': coinsToIssue,
          'owner_compensation': ownerComp,
          'total_booking_amount': amount,
          'cancelled_at': nowUtc.toIso8601String(),
        });
      } catch (histErr) {
        debugPrint('Error recording cancellation history in fallback: $histErr');
      }

      return {
        'success': true,
        'booking_id': bookingId,
        'status': 'cancelled',
        'refund_percent': quote.refundPercent,
        'coins_issued': coinsToIssue,
        'owner_compensation': ownerComp,
      };
    } catch (fallbackErr) {
      debugPrint('Cancellation direct fallback error: $fallbackErr');
      rethrow;
    }
  }

  /// Fetches cancellation history for the current user.
  /// Queries cancellation_history first, and supplements/falls back to bookings with status = 'cancelled'.
  Future<List<Map<String, dynamic>>> getCancellationHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    try {
      final res = await _supabase
          .from('cancellation_history')
          .select('*')
          .eq('user_id', user.uid)
          .order('cancelled_at', ascending: false);
      if (res.isNotEmpty) {
        return List<Map<String, dynamic>>.from(res);
      }
    } catch (e) {
      debugPrint('[PaymentRepository] cancellation_history select error: $e');
    }

    // Fallback: Query bookings table directly for cancelled bookings
    try {
      final bRes = await _supabase
          .from('bookings')
          .select('*, grounds(name, address)')
          .eq('user_id', user.uid)
          .eq('status', 'cancelled')
          .order('cancelled_at', ascending: false);

      if (bRes.isNotEmpty) {
        return List<Map<String, dynamic>>.from(bRes.map((b) {
          final m = Map<String, dynamic>.from(b as Map);
          return {
            'booking_id': m['id']?.toString() ?? '',
            'user_id': m['user_id']?.toString() ?? '',
            'ground_id': m['ground_id']?.toString(),
            'ground_name': (m['grounds'] is Map ? m['grounds']['name'] : null) ?? m['ground_name'] ?? 'Box Cricket',
            'sport_name': m['sport_name'] ?? m['sport'] ?? 'Box Cricket',
            'slot_time': m['slot_time'],
            'cancelled_by': m['cancelled_by'] ?? 'user',
            'cancellation_reason': m['cancellation_reason'] ?? 'Cancelled',
            'refund_percent': m['refund_percent'] ?? 0,
            'coins_issued': (m['cancellation_coins_issued'] as num?)?.toDouble() ?? 0.0,
            'total_booking_amount': (m['amount'] as num?)?.toDouble() ?? 0.0,
            'cancelled_at': m['cancelled_at'] ?? m['created_at'],
          };
        }));
      }
    } catch (e) {
      debugPrint('[PaymentRepository] fallback cancelled bookings fetch error: $e');
    }

    return [];
  }
}

