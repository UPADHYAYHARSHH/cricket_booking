import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:turfpro/common/constants/colors.dart';
import 'package:turfpro/common/services/remote_config_service.dart';
import 'package:turfpro/user_booking/data/repositories/payment_repository.dart';
import 'package:turfpro/user_booking/di/get_it/get_it.dart';
import 'package:turfpro/user_booking/presentation/screens/cancellation/wallet_coin_history_screen.dart';

class UserCancellationHistoryScreen extends StatefulWidget {
  const UserCancellationHistoryScreen({super.key});

  @override
  State<UserCancellationHistoryScreen> createState() =>
      _UserCancellationHistoryScreenState();
}

class _UserCancellationHistoryScreenState
    extends State<UserCancellationHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _cancellations = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = getIt<PaymentRepository>();
      final list = await repo.getCancellationHistory();
      if (mounted) {
        setState(() {
          _cancellations = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
          'Cancellations & Policy',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amberAccent,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: [
            Tab(
              text: _cancellations.isNotEmpty
                  ? 'History (${_cancellations.length})'
                  : 'History',
            ),
            const Tab(text: 'Policy & Rules'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'View Playora Coins',
            icon: const Icon(Icons.monetization_on_rounded, color: Colors.amberAccent),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const WalletCoinHistoryScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildHistoryTab(),
          _buildPolicyTab(),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryDarkGreen),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 48, color: Colors.red.shade400),
              const SizedBox(height: 12),
              Text(
                'Failed to load cancellation history',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade800),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadHistory,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryDarkGreen),
                child: const Text('Retry', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    if (_cancellations.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadHistory,
        color: AppColors.primaryDarkGreen,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(32),
          children: [
            const SizedBox(height: 60),
            Icon(Icons.event_available_rounded, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'No Cancellations Found',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'You have not cancelled any bookings yet.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: OutlinedButton.icon(
                onPressed: () => _tabController.animateTo(1),
                icon: const Icon(Icons.info_outline, size: 16, color: AppColors.primaryDarkGreen),
                label: const Text('View Cancellation Policy', style: TextStyle(color: AppColors.primaryDarkGreen)),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHistory,
      color: AppColors.primaryDarkGreen,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: _cancellations.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = _cancellations[index];
          return _buildCancellationCard(item);
        },
      ),
    );
  }

  Widget _buildCancellationCard(Map<String, dynamic> item) {
    final groundName = item['ground_name']?.toString() ?? 'Venue';
    final sportName = item['sport_name']?.toString() ?? 'Box Cricket';
    final bookingId = item['booking_id']?.toString() ?? '';
    final reason = item['cancellation_reason']?.toString() ?? 'Cancelled';
    final cancelledBy = (item['cancelled_by']?.toString() ?? 'user').toLowerCase();
    final isByUser = cancelledBy == 'user';
    final coins = (item['coins_issued'] as num?)?.toDouble() ?? 0.0;
    final refundPct = (item['refund_percent'] as num?)?.toInt() ?? 0;
    final totalAmount = (item['total_booking_amount'] as num?)?.toDouble() ?? 0.0;

    DateTime? cancelledAt;
    if (item['cancelled_at'] != null) {
      cancelledAt = DateTime.tryParse(item['cancelled_at'].toString())?.toLocal();
    }

    DateTime? slotTime;
    if (item['slot_time'] != null) {
      slotTime = DateTime.tryParse(item['slot_time'].toString())?.toLocal();
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Ground Name + Status Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        groundName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        sportName,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFEF9A9A)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cancel_outlined, size: 12, color: Color(0xFFD32F2F)),
                      const SizedBox(width: 4),
                      Text(
                        isByUser ? 'You Cancelled' : 'Venue Cancelled',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD32F2F),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 12),

            // Slot Date & Cancelled Date
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month_outlined, size: 14, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(
                        slotTime != null
                            ? DateFormat('EEE, d MMM • h:mm a').format(slotTime)
                            : 'Slot Time N/A',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF334155), fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                if (cancelledAt != null)
                  Text(
                    'Cancelled ${DateFormat('d MMM, h:mm a').format(cancelledAt)}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
              ],
            ),

            const SizedBox(height: 10),

            // Reason Bubble
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.help_outline_rounded, size: 14, color: Colors.blueGrey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Reason: $reason',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF475569),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Recovery & Coins Row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: coins > 0
                      ? [const Color(0xFFFFFDE7), const Color(0xFFFFF9C4)]
                      : [const Color(0xFFF1F5F9), const Color(0xFFE2E8F0)],
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: coins > 0 ? const Color(0xFFFFE082) : Colors.grey.shade300,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        coins > 0 ? Icons.monetization_on_rounded : Icons.info_outline,
                        size: 18,
                        color: coins > 0 ? const Color(0xFFB78103) : Colors.blueGrey,
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            coins > 0
                                ? '+${coins.toStringAsFixed(0)} Playora Coins'
                                : 'No Coins Issued',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: coins > 0 ? const Color(0xFF7A5200) : Colors.black87,
                            ),
                          ),
                          if (refundPct > 0)
                            Text(
                              '$refundPct% Refund Tier Applied',
                              style: const TextStyle(fontSize: 10.5, color: Color(0xFF8D6E63)),
                            ),
                        ],
                      ),
                    ],
                  ),
                  if (totalAmount > 0)
                    Text(
                      'Paid: ₹${totalAmount.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                ],
              ),
            ),

            if (bookingId.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Booking #CB${bookingId.length > 8 ? bookingId.substring(0, 8).toUpperCase() : bookingId.toUpperCase()}',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade400, fontWeight: FontWeight.w500),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPolicyTab() {
    final cfg = RemoteConfigService();
    final t1h = cfg.cancellationTier1Hours;
    final t1p = cfg.cancellationTier1Percent;
    final t2h = cfg.cancellationTier2Hours;
    final t2p = cfg.cancellationTier2Percent;
    final t3h = cfg.cancellationTier3Hours;
    final t3p = cfg.cancellationTier3Percent;
    final t4p = cfg.cancellationTier4Percent;
    final expiry = cfg.coinExpiryDays;
    final maxRedeem = cfg.maxCoinRedemptionPercent;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryDarkGreen, Color(0xFF0FA968)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryDarkGreen.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.shield_outlined, color: Colors.white, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Cancellation & Recovery Policy',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'Cancel risk-free with automated Playora Coin recovery. Instant wallet credits with no waiting for bank processing.',
                  style: TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.4),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'Refund Tiers by Slot Time Remaining',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 10),

          // Dynamic Tier 1
          _buildTierCard(
            title: 'Early Cancellation (> ${t1h.toStringAsFixed(0)}h before slot)',
            percent: '${t1p.toStringAsFixed(0)}%',
            description: 'Full venue amount credited to your wallet in Playora Coins.',
            badgeColor: Colors.green.shade700,
            bgColor: Colors.green.shade50,
          ),
          const SizedBox(height: 8),

          // Dynamic Tier 2
          _buildTierCard(
            title: 'Standard (${t2h.toStringAsFixed(0)}h – ${t1h.toStringAsFixed(0)}h before slot)',
            percent: '${t2p.toStringAsFixed(0)}%',
            description: 'Generous recovery in Playora Coins. Released slot is re-listed.',
            badgeColor: Colors.teal.shade700,
            bgColor: Colors.teal.shade50,
          ),
          const SizedBox(height: 8),

          // Dynamic Tier 3
          _buildTierCard(
            title: 'Short Notice (${t3h.toStringAsFixed(0)}h – ${t2h.toStringAsFixed(0)}h before slot)',
            percent: '${t3p.toStringAsFixed(0)}%',
            description: 'Partial recovery in Playora Coins to support venue availability.',
            badgeColor: Colors.amber.shade800,
            bgColor: Colors.amber.shade50,
          ),
          const SizedBox(height: 8),

          // Dynamic Tier 4
          _buildTierCard(
            title: 'Last-minute (< ${t3h.toStringAsFixed(0)}h before slot)',
            percent: '${t4p.toStringAsFixed(0)}%',
            description: t4p > 0
                ? 'Minimal recovery. Venue slot is immediately freed.'
                : 'Non-refundable period due to locked court preparations.',
            badgeColor: Colors.deepOrange.shade700,
            bgColor: Colors.deepOrange.shade50,
          ),

          const SizedBox(height: 20),

          const Text(
            'Important Rules & Guidelines',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 10),

          _buildInstructionBullet(
            icon: Icons.monetization_on_outlined,
            title: 'Playora Coins (1 Coin = ₹1)',
            content: 'Recovered coins are instantly credited to your wallet and can be used on any future booking on the platform.',
          ),
          _buildInstructionBullet(
            icon: Icons.timer_outlined,
            title: 'Coin Validity ($expiry Days)',
            content: 'Playora Coins expire after $expiry days from the issue date. Be sure to redeem them on your upcoming games!',
          ),
          _buildInstructionBullet(
            icon: Icons.percent_rounded,
            title: 'Max Redemption (${maxRedeem.toStringAsFixed(0)}%)',
            content: 'You can redeem Playora Coins up to ${maxRedeem.toStringAsFixed(0)}% of your available coins on any booking.',
          ),
          _buildInstructionBullet(
            icon: Icons.lock_clock_outlined,
            title: 'Immediate Slot Liberation',
            content: 'Once you cancel, the slot is immediately released and made available for other players to book.',
          ),
          _buildInstructionBullet(
            icon: Icons.receipt_long_outlined,
            title: 'Platform Convenience Fee',
            content: 'Platform convenience fees cover payment gateway and server operations and are strictly non-refundable.',
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildTierCard({
    required String title,
    required String percent,
    required String description,
    required Color badgeColor,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              percent,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: badgeColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionBullet({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primaryDarkGreen.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: AppColors.primaryDarkGreen),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 2),
                Text(
                  content,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
