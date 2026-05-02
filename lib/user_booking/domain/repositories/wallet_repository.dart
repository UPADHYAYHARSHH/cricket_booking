import 'package:supabase_flutter/supabase_flutter.dart';

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
    final user = _supabase.auth.currentUser;
    if (user == null) return 0.0;

    final response = await _supabase
        .from('wallets')
        .select('balance')
        .eq('user_id', user.id)
        .maybeSingle();

    if (response == null) {
      // Create wallet if it doesn't exist
      await _supabase.from('wallets').insert({
        'user_id': user.id,
        'balance': 0.0,
      });
      return 0.0;
    }

    return (response['balance'] as num).toDouble();
  }

  @override
  Future<void> updateBalance(double amount) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    await _supabase
        .from('wallets')
        .update({'balance': amount})
        .eq('user_id', user.id);
  }

  @override
  Future<void> addTransaction({
    required double amount,
    required String type,
    required String description,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    await _supabase.from('wallet_transactions').insert({
      'user_id': user.id,
      'amount': amount,
      'type': type, // 'credit' or 'debit'
      'description': description,
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}
