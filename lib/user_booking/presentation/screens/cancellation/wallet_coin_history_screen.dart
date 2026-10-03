import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:turfpro/common/constants/colors.dart';
import 'package:turfpro/common/services/remote_config_service.dart';
import 'package:turfpro/user_booking/di/get_it/get_it.dart';
import 'package:turfpro/user_booking/domain/repositories/wallet_repository.dart';
import 'package:turfpro/user_booking/presentation/screens/cancellation/user_cancellation_history_screen.dart';

class WalletCoinHistoryScreen extends StatefulWidget {
  const WalletCoinHistoryScreen({super.key});

  @override
  State<WalletCoinHistoryScreen> createState() => _WalletCoinHistoryScreenState();
}

class _WalletCoinHistoryScreenState extends State<WalletCoinHistoryScreen> {
  double _balance = 0.0;
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;
  String _filter = 'all'; // 'all', 'credit', 'debit'

  @override
  void initState() {
    super.initState();
    _loadWalletData();
  }

  Future<void> _loadWalletData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final repo = getIt<WalletRepository>();
      final bal = await repo.getBalance();
      final txs = await repo.getTransactions();
      if (mounted) {
        setState(() {
          _balance = bal;
          _transactions = txs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> get _filteredTransactions {
    if (_filter == 'credit') {
      return _transactions.where((t) {
        final type = (t['type'] ?? '').toString().toLowerCase();
        return type.contains('credit');
      }).toList();
    } else if (_filter == 'debit') {
      return _transactions.where((t) {
        final type = (t['type'] ?? '').toString().toLowerCase();
        return type == 'debit';
      }).toList();
    }
    return _transactions;
  }

  @override
  Widget build(BuildContext context) {
    final cfg = RemoteConfigService();
    final expiry = cfg.coinExpiryDays;
    final maxRedeem = cfg.maxCoinRedemptionPercent;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      appBar: AppBar(
        backgroundColor: AppColors.primaryDarkGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Playora Coins Wallet',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Cancellation History',
            icon: const Icon(Icons.history_rounded, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const UserCancellationHistoryScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryDarkGreen),
            )
          : RefreshIndicator(
              onRefresh: _loadWalletData,
              color: AppColors.primaryDarkGreen,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  // Gold Gradient Balance Card
                  _buildBalanceCard(),

                  const SizedBox(height: 16),

                  // Info Explainer Card
                  _buildCoinRulesBanner(expiry, maxRedeem),

                  const SizedBox(height: 20),

                  // Transactions Header + Filter Chips
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Coin History',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        '${_filteredTransactions.length} transactions',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Filter Chips
                  Row(
                    children: [
                      _buildFilterChip('All', 'all'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Earned / Credited (+)', 'credit'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Spent (-)', 'debit'),
                    ],
                  ),

                  const SizedBox(height: 14),

                  if (_filteredTransactions.isEmpty) ...[
                    const SizedBox(height: 40),
                    Center(
                      child: Column(
                        children: [
                          Icon(Icons.receipt_long_outlined, size: 54, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            _filter == 'all'
                                ? 'No Coin Transactions Yet'
                                : 'No ${_filter == 'credit' ? 'Credited' : 'Spent'} Transactions',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Cancelled bookings and promotions will credit coins here.',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ] else
                    ..._filteredTransactions.map(_buildTransactionTile),

                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFD97706), Color(0xFFF59E0B), Color(0xFFFBBF24)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD97706).withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.monetization_on_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Playora Coins',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bolt_rounded, size: 13, color: Colors.white),
                    SizedBox(width: 3),
                    Text(
                      '1 Coin = ₹1',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _balance.toStringAsFixed(0),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Coins',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                'Worth ₹${_balance.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: Colors.white24),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Usable for slot bookings',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const UserCancellationHistoryScreen(),
                    ),
                  );
                },
                child: const Row(
                  children: [
                    Text(
                      'Cancellations',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Colors.white),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCoinRulesBanner(int expiry, double maxRedeem) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryDarkGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.stars_rounded,
              color: AppColors.primaryDarkGreen,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'How Playora Coins Work',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '• 100% closed-loop platform currency.\n• Redeem up to ${maxRedeem.toStringAsFixed(0)}% of your coins per booking.\n• Valid for $expiry days from credit date.',
                  style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryDarkGreen : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryDarkGreen : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionTile(Map<String, dynamic> item) {
    final type = (item['type'] ?? '').toString().toLowerCase();
    final isCredit = type.contains('credit');
    final amount = (item['amount'] as num?)?.toDouble() ?? 0.0;
    final description = item['description']?.toString() ??
        (isCredit ? 'Coins Credited' : 'Coins Redeemed');

    DateTime? createdAt;
    if (item['created_at'] != null) {
      createdAt = DateTime.tryParse(item['created_at'].toString())?.toLocal();
    }

    final isCancellation = type == 'cancellation_credit';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: isCredit ? const Color(0xFFE8F5E9) : const Color(0xFFFBE9E7),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCredit
                  ? (isCancellation ? Icons.history_toggle_off_rounded : Icons.arrow_downward_rounded)
                  : Icons.arrow_upward_rounded,
              size: 18,
              color: isCredit ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        description,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isCancellation) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Refund',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE65100),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  createdAt != null
                      ? DateFormat('d MMM yyyy • h:mm a').format(createdAt)
                      : 'Recently',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${isCredit ? '+' : '-'}${amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: isCredit ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
            ),
          ),
        ],
      ),
    );
  }
}
