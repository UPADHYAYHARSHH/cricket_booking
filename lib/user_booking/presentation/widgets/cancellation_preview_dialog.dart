import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:turfpro/common/constants/colors.dart';
import '../../../../common/services/remote_config_service.dart';
import '../../../../common/services/audio_service.dart';
import '../../data/models/booking_model.dart';
import '../../data/repositories/payment_repository.dart';
import 'package:turfpro/user_booking/di/get_it/get_it.dart';

class CancellationPreviewDialog extends StatefulWidget {
  final BookingModel booking;

  const CancellationPreviewDialog({
    super.key,
    required this.booking,
  });

  static Future<bool?> show(BuildContext context, BookingModel booking) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CancellationPreviewDialog(booking: booking),
    );
  }

  @override
  State<CancellationPreviewDialog> createState() =>
      _CancellationPreviewDialogState();
}

class _CancellationPreviewDialogState extends State<CancellationPreviewDialog> {
  final List<String> _reasons = [
    'Changed my plans',
    'Schedule conflict',
    'Booked by mistake',
    'Weather concern',
    'Personal emergency',
    'Other',
  ];

  late String _selectedReason;
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
    _selectedReason = _reasons.first;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final booking = widget.booking;
    final groundName = (booking.ground?.locationName != null &&
            booking.ground!.locationName.isNotEmpty)
        ? booking.ground!.locationName
        : (booking.ground?.name ?? "Venue");

    final amount = booking.amount;
    final platformFee = booking.platformFee;
    final baseAmount = booking.baseAmount > 0
        ? booking.baseAmount
        : (amount - platformFee);
    final eligibleAmount = baseAmount > 0 ? baseAmount : amount;

    final actualSlotTime = booking.actualSlotStartTime;

    final quote = RemoteConfigService().getCancellationQuote(
      slotTime: actualSlotTime,
      eligibleAmount: eligibleAmount,
    );

    final formattedSlotDate =
        DateFormat('EEE, dd MMM yyyy, hh:mm a').format(actualSlotTime);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.cancel_outlined,
                      color: Colors.red,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cancel Booking?',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          groundName,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Match Time Info Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 20,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Slot Schedule',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            formattedSlotDate,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: quote.refundPercent > 0
                            ? AppColors.primaryDarkGreen.withValues(alpha: 0.12)
                            : Colors.red.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        quote.hoursRemaining > 0
                            ? '${quote.hoursRemaining.toStringAsFixed(1)}h away'
                            : 'Started',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: quote.refundPercent > 0
                              ? AppColors.primaryDarkGreen
                              : Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Dynamic Cancellation Refund Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryDarkGreen.withValues(alpha: 0.08),
                      AppColors.primaryDarkGreen.withValues(alpha: 0.02),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primaryDarkGreen.withValues(alpha: 0.25),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Cancellation Policy Tier',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primaryDarkGreen,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            quote.tierName,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Eligible Slot Amount:',
                          style: TextStyle(fontSize: 13),
                        ),
                        Text(
                          '₹${eligibleAmount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recovery Rate:',
                          style: TextStyle(fontSize: 13),
                        ),
                        Text(
                          '${quote.refundPercent.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDarkGreen,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Coins to Receive',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Valid for ${quote.coinExpiryDays} days',
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.monetization_on_rounded,
                              color: Colors.amber,
                              size: 22,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${quote.coinsToReceive.toStringAsFixed(0)} Coins',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primaryDarkGreen,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Non-refundable platform fee footnote
              if (platformFee > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    '• Platform fee (₹${platformFee.toStringAsFixed(0)}) is non-refundable.',
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                ),

              // Reason dropdown
              Text(
                'Reason for cancellation',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedReason,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                    items: _reasons.map((r) {
                      return DropdownMenuItem<String>(
                        value: r,
                        child: Text(r, style: const TextStyle(fontSize: 13)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedReason = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isCancelling
                          ? null
                          : () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.2),
                        ),
                      ),
                      child: const Text('Keep Booking'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isCancelling
                          ? null
                          : () => _confirmCancel(context, quote.coinsToReceive),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isCancelling
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Confirm Cancel',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmCancel(BuildContext context, double coinsToReceive) async {
    setState(() => _isCancelling = true);

    try {
      final paymentRepo = getIt<PaymentRepository>();
      await paymentRepo.cancelBookingByUser(
        bookingId: widget.booking.id,
        reason: _selectedReason,
      );

      // Play coin sound
      try {
        AudioService().playNotificationSound('loyalty_points');
      } catch (_) {}

      if (!mounted) return;
      Navigator.pop(context, true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.primaryDarkGreen,
          behavior: SnackBarBehavior.floating,
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  coinsToReceive > 0
                      ? 'Booking cancelled! ${coinsToReceive.toStringAsFixed(0)} Playora Coins added to your wallet.'
                      : 'Booking has been cancelled.',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isCancelling = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text('Failed to cancel booking: $e'),
        ),
      );
    }
  }
}
