import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract class WalletRepository {
  Future<double> getBalance();
  Future<void> updateBalance(double amount);
  Future<void> addTransaction({
    required double amount,
    required String type,
    required String description,
  });
  Future<List<Map<String, dynamic>>> getTransactions();
}

class WalletRepositoryImpl implements WalletRepository {
  final SupabaseClient _supabase;

  WalletRepositoryImpl(this._supabase);

  @override
  Future<double> getBalance() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 0.0;

    double? dbBalance;

    // 1. Try fetching balance from wallets table
    try {
      final response = await _supabase
          .from('wallets')
          .select('balance')
          .eq('user_id', user.uid)
          .maybeSingle()
          .timeout(const Duration(seconds: 8));

      if (response != null && response['balance'] != null) {
        dbBalance = (response['balance'] as num).toDouble();
      }
    } catch (e) {
      // Wallets table query might fail or return null due to RLS
    }

    // 2. Fetch cancellation coins from cancellation_history as resilient fallback
    double cancellationCoins = 0.0;
    try {
      final cancelHist = await _supabase
          .from('cancellation_history')
          .select('coins_issued')
          .eq('user_id', user.uid);
      for (final row in cancelHist) {
        cancellationCoins += (row['coins_issued'] as num?)?.toDouble() ?? 0.0;
      }
    } catch (_) {}

    // 3. Fetch spent coins (debits) from wallet_transactions
    double debits = 0.0;
    try {
      final debRows = await _supabase
          .from('wallet_transactions')
          .select('amount')
          .eq('user_id', user.uid)
          .eq('type', 'debit');
      for (final row in debRows) {
        debits += (row['amount'] as num?)?.toDouble() ?? 0.0;
      }
    } catch (_) {}

    final netCancelCoins =
        (cancellationCoins - debits).clamp(0.0, double.infinity);

    // If dbBalance is positive and matches or exceeds netCancelCoins, use dbBalance.
    // If dbBalance is null or 0 (e.g. RLS blocked or wallets not synced), use netCancelCoins.
    final effectiveBal = (dbBalance != null && dbBalance > 0)
        ? (dbBalance > netCancelCoins ? dbBalance : netCancelCoins)
        : netCancelCoins;

    return effectiveBal;
  }

  @override
  Future<void> updateBalance(double amount) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await _supabase.from('wallets').upsert({
        'user_id': user.uid,
        'balance': amount,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'user_id');
    } catch (_) {}
  }

  @override
  Future<void> addTransaction({
    required double amount,
    required String type,
    required String description,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final normalizedType =
        type.toLowerCase().contains('credit') ? 'credit' : 'debit';

    try {
      await _supabase.from('wallet_transactions').insert({
        'user_id': user.uid,
        'amount': amount,
        'type': normalizedType,
        'description': description,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (_) {}
  }

  @override
  Future<List<Map<String, dynamic>>> getTransactions() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final List<Map<String, dynamic>> list = [];

    // 1. Fetch from wallet_transactions if available
    try {
      final response = await _supabase
          .from('wallet_transactions')
          .select('*')
          .eq('user_id', user.uid)
          .order('created_at', ascending: false)
          .timeout(const Duration(seconds: 8));

      list.addAll(List<Map<String, dynamic>>.from(response as List));
    } catch (_) {}

    // 2. Supplement from cancellation_history so cancellation coin credits are NEVER missed
    try {
      final cancelHist = await _supabase
          .from('cancellation_history')
          .select('*')
          .eq('user_id', user.uid)
          .order('cancelled_at', ascending: false);

      final existingIds = list.map((t) => t['id']?.toString() ?? '').toSet();
      final existingBookings = list
          .map((t) => t['reference_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet();

      for (final ch in cancelHist) {
        final coins = (ch['coins_issued'] as num?)?.toDouble() ?? 0.0;
        final bookingId = ch['booking_id']?.toString() ?? '';
        final chId = ch['id']?.toString() ?? '';

        if (coins > 0 &&
            !existingIds.contains(chId) &&
            !existingBookings.contains(bookingId)) {
          final ground = ch['ground_name'] ?? 'Ground';
          final pct = (ch['refund_percent'] as num?)?.toInt() ?? 100;
          list.add({
            'id': chId,
            'user_id': user.uid,
            'amount': coins,
            'type': 'cancellation_credit',
            'description': 'Booking cancelled ($pct% refund) - $ground',
            'reference_id': bookingId,
            'created_at': ch['cancelled_at'] ?? ch['created_at'],
          });
        }
      }
    } catch (_) {}

    // Sort by created_at DESC
    list.sort((a, b) {
      final tA = DateTime.tryParse(a['created_at']?.toString() ?? '') ??
          DateTime(1970);
      final tB = DateTime.tryParse(b['created_at']?.toString() ?? '') ??
          DateTime(1970);
      return tB.compareTo(tA);
    });

    return list;
  }
}
