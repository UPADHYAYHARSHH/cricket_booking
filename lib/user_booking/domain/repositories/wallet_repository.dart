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
}

class WalletRepositoryImpl implements WalletRepository {
  final SupabaseClient _supabase;

  WalletRepositoryImpl(this._supabase);

  @override
  Future<double> getBalance() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 0.0;

    try {
      final response = await _supabase
          .from('wallets')
          .select('balance')
          .eq('user_id', user.uid)
          .maybeSingle()
          .timeout(const Duration(seconds: 10));

      if (response == null) {
        // Create wallet if it doesn't exist
        await _supabase.from('wallets').insert({
          'user_id': user.uid,
          'balance': 0.0,
        });
        return 0.0;
      }

      return (response['balance'] as num).toDouble();
    } catch (e) {
      return 0.0;
    }
  }

  @override
  Future<void> updateBalance(double amount) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _supabase
        .from('wallets')
        .update({'balance': amount})
        .eq('user_id', user.uid);
  }

  @override
  Future<void> addTransaction({
    required double amount,
    required String type,
    required String description,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _supabase.from('wallet_transactions').insert({
      'user_id': user.uid,
      'amount': amount,
      'type': type, // 'credit' or 'debit'
      'description': description,
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}
