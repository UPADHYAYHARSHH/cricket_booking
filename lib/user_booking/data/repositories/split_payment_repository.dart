import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/split_payment_model.dart';

class SplitPaymentRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Create a new split request and its members
  Future<String> createSplitRequest({
    required SplitRequestModel request,
    required List<SplitMemberModel> members,
    File? qrImage,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    String? qrUrl;

    // 1. Upload QR Code if provided
    if (qrImage != null) {
      final fileName = 'qr_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = '${user.id}/$fileName';
      
      await _supabase.storage.from('qr_codes').upload(path, qrImage);
      qrUrl = _supabase.storage.from('qr_codes').getPublicUrl(path);
    }

    // 2. Insert Split Request
    final splitResponse = await _supabase.from('split_requests').insert({
      'booking_id': request.bookingId,
      'user_id': user.id,
      'total_amount': request.totalAmount,
      'upi_id': request.upiId,
      'qr_code_url': qrUrl,
      'status': 'pending',
    }).select().single();

    final splitRequestId = splitResponse['id'];

    // 3. Insert Members
    final membersData = members.map((m) => {
      'split_request_id': splitRequestId,
      'name': m.name,
      'amount': m.amount,
      'is_received': m.isReceived,
      'member_user_id': m.memberUserId,
    }).toList();

    await _supabase.from('split_members').insert(membersData);

    // 4. Create Notifications for tagged users
    for (var member in members) {
      if (member.memberUserId != null) {
        await _supabase.from('notifications').insert({
          'user_id': member.memberUserId,
          'title': 'New Split Payment Request',
          'message': 'You have been tagged in a split request for ${request.totalAmount} at ${request.bookingId}.',
          'type': 'split_payment',
          'data': {
            'split_request_id': splitRequestId,
            'amount': member.amount,
            'booking_id': request.bookingId,
          },
        });
      }
    }

    return splitRequestId;
  }

  /// Fetch split request for a specific booking
  Future<SplitRequestModel?> getSplitForBooking(String bookingId) async {
    final response = await _supabase
        .from('split_requests')
        .select('*, split_members(*)')
        .eq('booking_id', bookingId)
        .maybeSingle();

    if (response == null) return null;
    return SplitRequestModel.fromJson(response);
  }

  /// Update a member's payment received status
  Future<void> updateMemberStatus(String memberId, bool isReceived) async {
    await _supabase
        .from('split_members')
        .update({'is_received': isReceived})
        .eq('id', memberId);
  }

  /// Get all split requests for the current user (as organizer or participant)
  Future<List<SplitRequestModel>> getUserSplits() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    // Fetch splits where user is organizer
    final organizedResponse = await _supabase
        .from('split_requests')
        .select('*, split_members(*)')
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    // Fetch splits where user is a member
    // We fetch the member records first to get the split_request_ids
    final memberRecords = await _supabase
        .from('split_members')
        .select('split_request_id')
        .eq('member_user_id', user.id);
    
    final List<String> participatedIds = (memberRecords as List)
        .map((m) => m['split_request_id'] as String)
        .toList();

    List<Map<String, dynamic>> allSplits = List<Map<String, dynamic>>.from(organizedResponse as List);

    if (participatedIds.isNotEmpty) {
      final participatedResponse = await _supabase
          .from('split_requests')
          .select('*, split_members(*)')
          .inFilter('id', participatedIds)
          .order('created_at', ascending: false);
      
      final List participatedSplits = participatedResponse as List;
      
      // Merge and remove duplicates
      for (var split in participatedSplits) {
        if (!allSplits.any((s) => s['id'] == split['id'])) {
          allSplits.add(Map<String, dynamic>.from(split));
        }
      }
    }

    // Sort by date
    allSplits.sort((a, b) => DateTime.parse(b['created_at']).compareTo(DateTime.parse(a['created_at'])));

    return allSplits.map((json) => SplitRequestModel.fromJson(json)).toList();
  }
}
