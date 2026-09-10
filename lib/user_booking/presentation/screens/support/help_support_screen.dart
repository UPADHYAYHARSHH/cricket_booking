import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../common/constants/colors.dart';
import '../../blocs/support/support_cubit.dart';
import '../../blocs/support/support_state.dart';
import 'support_chat_screen.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  Future<void> _launchUrl(String urlString) async {
    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _openChat(BuildContext context, {String? query, Map<String, dynamic>? booking}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<SupportCubit>(),
          child: SupportChatScreen(
            initialBooking: booking,
            initialQuery: query,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocProvider(
      create: (_) => SupportCubit()..initSupport(),
      child: Builder(
        builder: (context) {
          return Scaffold(
            backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
            appBar: AppBar(
              backgroundColor: isDark ? AppColors.surfaceDark : AppColors.white,
              elevation: 0.5,
              title: Text(
                "Help & Support",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              centerTitle: true,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                IconButton(
                  icon: const Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: Color(0xFF25D366),
                    size: 22,
                  ),
                  tooltip: "WhatsApp Support",
                  onPressed: () => _launchUrl(
                    "https://wa.me/919876543210?text=Hi%20TurfPro%20Support,%20I%20need%20help",
                  ),
                ),
              ],
            ),
            body: BlocBuilder<SupportCubit, SupportState>(
              builder: (context, state) {
                Map<String, dynamic>? recentBooking;
                if (state is SupportLoaded) {
                  recentBooking = state.recentBooking;
                }

                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  children: [
                    // Hero AI Banner
                    _buildHeroBanner(context, isDark),

                    const SizedBox(height: 18),

                    // Recent Booking Context Card (if available)
                    if (recentBooking != null) ...[
                      _buildRecentBookingCard(context, recentBooking, isDark),
                      const SizedBox(height: 20),
                    ],

                    // High-Frequency Topic Categories
                    Text(
                      "Frequently Asked Questions",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 10),

                    _buildFaqTile(
                      context,
                      icon: Icons.access_time_rounded,
                      title: "How does the 45-minute booking approval work?",
                      subtitle: "Understand owner review timer and slot locking",
                      query: "How does the 45 minute approval timer work?",
                      isDark: isDark,
                    ),
                    _buildFaqTile(
                      context,
                      icon: Icons.credit_card_rounded,
                      title: "Payment deducted but booking pending / failed?",
                      subtitle: "Refund timelines and transaction checks",
                      query: "My money was deducted but booking is not confirmed, how to get refund?",
                      isDark: isDark,
                    ),
                    _buildFaqTile(
                      context,
                      icon: Icons.qr_code_scanner_rounded,
                      title: "How do I check-in at the turf venue?",
                      subtitle: "Using QR code and Entry Ticket ID at the counter",
                      query: "How do I check-in at the venue with my ticket?",
                      isDark: isDark,
                    ),
                    _buildFaqTile(
                      context,
                      icon: Icons.group_outlined,
                      title: "How to split bill with teammates?",
                      subtitle: "Invite friends and split payment link rules",
                      query: "How does split payment work for box cricket?",
                      isDark: isDark,
                    ),
                    _buildFaqTile(
                      context,
                      icon: Icons.cancel_outlined,
                      title: "Can I cancel or reschedule my booking?",
                      subtitle: "Cancellation policy and rescheduling guidelines",
                      query: "What is the cancellation and refund policy?",
                      isDark: isDark,
                    ),

                    const SizedBox(height: 24),

                    // Direct Contact Channels
                    Text(
                      "Need Human Assistance?",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildContactCard(
                      icon: Icons.chat_rounded,
                      iconColor: const Color(0xFF25D366),
                      title: "Chat with Us on WhatsApp",
                      subtitle: "Available 7 days a week • 8:00 AM - 11:00 PM",
                      onTap: () => _launchUrl(
                        "https://wa.me/919876543210?text=Hi%20TurfPro%20Support,%20I%20need%20help",
                      ),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 10),
                    _buildContactCard(
                      icon: Icons.phone_rounded,
                      iconColor: AppColors.primaryDarkGreen,
                      title: "Call Support Helpline",
                      subtitle: "+91 98765 43210",
                      onTap: () => _launchUrl("tel:+919876543210"),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 30),
                  ],
                );
              },
            ),
            bottomNavigationBar: Container(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () => _openChat(context),
                icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 20),
                label: const Text(
                  "Chat with AI Assistant",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDarkGreen,
                  elevation: 0,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeroBanner(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0B8457),
            Color(0xFF1B5E20),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B8457).withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "⚡ 24/7 AI SUPPORT",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "How can we help you today?",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Instant answers for bookings, payments, refunds, and venue rules.",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.support_agent_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentBookingCard(
    BuildContext context,
    Map<String, dynamic> booking,
    bool isDark,
  ) {
    final groundName = booking['grounds']?['name'] ?? 'Sports Venue';
    final status = (booking['status'] ?? 'pending').toString().toLowerCase();
    final amount = booking['amount'] ?? 0;
    final slotTimeStr = booking['slot_time']?.toString() ?? '';

    String dateFormatted = 'Upcoming';
    if (slotTimeStr.isNotEmpty) {
      final dt = DateTime.tryParse(slotTimeStr);
      if (dt != null) {
        dateFormatted = DateFormat('EEE, d MMM • hh:mm a').format(dt.toLocal());
      }
    }

    Color statusColor = AppColors.statusPending;
    Color statusBg = AppColors.statusPendingBg;
    if (status == 'paid' || status == 'confirmed') {
      statusColor = AppColors.statusConfirmed;
      statusBg = AppColors.statusConfirmedBg;
    } else if (status == 'declined' || status == 'cancelled' || status == 'expired') {
      statusColor = AppColors.statusCancelled;
      statusBg = AppColors.statusCancelledBg;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "ISSUE WITH RECENT BOOKING?",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            groundName,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 13,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
              const SizedBox(width: 4),
              Text(
                dateFormatted,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
              const Spacer(),
              Text(
                "₹$amount",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDarkGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _openChat(
                context,
                query: "I need help with my booking at $groundName (Status: $status)",
                booking: booking,
              ),
              icon: const Icon(Icons.help_outline_rounded, size: 16),
              label: const Text(
                "Get Help with This Booking",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryDarkGreen,
                side: const BorderSide(color: AppColors.primaryDarkGreen),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String query,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: ListTile(
        onTap: () => _openChat(context, query: query),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.primaryLightGreen.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primaryDarkGreen, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 13,
          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
        ),
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
        ),
        trailing: const Icon(
          Icons.open_in_new_rounded,
          size: 16,
          color: AppColors.primaryDarkGreen,
        ),
      ),
    );
  }
}
