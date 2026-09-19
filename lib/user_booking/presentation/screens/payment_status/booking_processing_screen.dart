import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:turfpro/common/config/feature_config.dart';
import 'package:turfpro/common/constants/colors.dart';
import 'package:turfpro/common/services/live_activity_service.dart';
import 'package:turfpro/common/services/notification_service.dart';
import 'package:turfpro/common/services/remote_config_service.dart';
import 'package:turfpro/user_booking/constants/route_constants.dart';
import 'package:turfpro/user_booking/data/models/ground_model.dart';
import 'package:turfpro/user_booking/data/repositories/payment_repository.dart';
import 'package:turfpro/user_booking/di/get_it/get_it.dart';
import 'package:turfpro/user_booking/domain/models/booking_arguments.dart';
import 'package:turfpro/user_booking/domain/models/booking_summary_data.dart';
import 'package:turfpro/user_booking/domain/models/slot_models.dart';
import 'package:turfpro/user_booking/domain/repositories/loyalty_repository.dart';
import 'package:turfpro/user_booking/domain/repositories/wallet_repository.dart';
import 'package:turfpro/user_booking/presentation/screens/my_booking/my_booking_screen.dart';

class BookingProcessingScreen extends StatefulWidget {
  final String orderId;
  final GroundModel ground;
  final DateTime selectedDate;
  final double totalAmount;
  final String selectedSport;
  final String selectedPeriod;
  final List<TimeSlot> selectedSlots;
  final BookingSummaryData? summaryData;
  final double appliedWallet;
  final int appliedPoints;
  final VoidCallback? onRetry;

  const BookingProcessingScreen({
    super.key,
    required this.orderId,
    required this.ground,
    required this.selectedDate,
    required this.totalAmount,
    required this.selectedSport,
    required this.selectedPeriod,
    required this.selectedSlots,
    this.summaryData,
    this.appliedWallet = 0.0,
    this.appliedPoints = 0,
    this.onRetry,
  });

  @override
  State<BookingProcessingScreen> createState() =>
      _BookingProcessingScreenState();
}

class _BookingProcessingScreenState extends State<BookingProcessingScreen>
    with SingleTickerProviderStateMixin {
  final _paymentRepo = getIt<PaymentRepository>();
  final _loyaltyRepo = getIt<LoyaltyRepository>();

  late AnimationController _pulseController;
  int _currentStep = 0; // 0: verify payment, 1: lock slots, 2: pass & notifs, 3: success
  bool _isSuccess = false;
  bool _hasError = false;
  String _errorMessage = "";
  int _confirmedDisplayId = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _executeBookingFlow();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _executeBookingFlow() async {
    try {
      // Step 0: Payment Verification
      setState(() {
        _currentStep = 0;
      });
      await Future.delayed(const Duration(milliseconds: 500));

      final isValid = await _paymentRepo.verifyPayment(orderId: widget.orderId);
      if (!isValid) {
        throw Exception("Payment verification failed with the payment gateway.");
      }

      // Step 1: Securing & Locking Turf Slots in DB
      if (!mounted) return;
      setState(() {
        _currentStep = 1;
      });
      await Future.delayed(const Duration(milliseconds: 400));

      final slotTimesPeriod = widget.selectedSlots.isNotEmpty
          ? widget.selectedSlots
              .map((s) => "${s.startTime} - ${s.endTime}")
              .join(', ')
          : widget.selectedPeriod;

      final bookingData = await _paymentRepo.saveDirectBooking(
        groundId: widget.ground.id,
        date: widget.selectedDate,
        amount: widget.totalAmount.toInt(),
        sportName: widget.selectedSport,
        period: widget.selectedPeriod,
        slotStartTimes:
            widget.selectedSlots.map((s) => s.startTime).toList(),
        orderId: widget.orderId,
        summaryData: widget.summaryData,
      );

      _confirmedDisplayId = bookingData['display_id'] ?? 0;

      // Step 2: Finalizing Rewards, Reminders & Live Activity
      if (!mounted) return;
      setState(() {
        _currentStep = 2;
      });

      // Wallet deduction if used
      if (FeatureConfig.isWalletEnabled && widget.appliedWallet > 0) {
        try {
          final walletRepo = getIt<WalletRepository>();
          final currentBalance = await walletRepo.getBalance();
          await walletRepo
              .updateBalance(currentBalance - widget.appliedWallet);
          await walletRepo.addTransaction(
            amount: widget.appliedWallet,
            type: 'debit',
            description: 'Used for booking @ ${widget.ground.name}',
          );
        } catch (e) {
          debugPrint("Wallet processing error: $e");
        }
      }

      // Loyalty points redemption & earning
      if (FeatureConfig.isLoyaltyEnabled) {
        try {
          if (widget.appliedPoints > 0) {
            await _loyaltyRepo.redeemPoints(widget.appliedPoints);
          }
          final pointsEarned = (widget.totalAmount / 10).floor();
          if (pointsEarned > 0) {
            await _loyaltyRepo.earnPoints(pointsEarned);
          }
        } catch (e) {
          debugPrint("Loyalty processing error: $e");
        }
      }

      // Notification & Live Activity
      try {
        if (widget.selectedSlots.isNotEmpty) {
          final rawStartTime =
              widget.selectedSlots.first.startTime.trim().toUpperCase();
          DateTime startTimeParsed;
          try {
            startTimeParsed = DateFormat("h:mm a").parse(rawStartTime);
          } catch (_) {
            try {
              startTimeParsed = DateFormat("hh:mm a").parse(rawStartTime);
            } catch (_) {
              try {
                startTimeParsed = DateFormat("HH:mm").parse(rawStartTime);
              } catch (_) {
                startTimeParsed = DateFormat("HH:mm:ss").parse(rawStartTime);
              }
            }
          }

          final bookingStartDateTime = DateTime(
            widget.selectedDate.year,
            widget.selectedDate.month,
            widget.selectedDate.day,
            startTimeParsed.hour,
            startTimeParsed.minute,
          );

          final notifId = (_confirmedDisplayId > 0)
              ? _confirmedDisplayId
              : ((bookingData['id']?.toString().hashCode ??
                      bookingStartDateTime.millisecondsSinceEpoch) &
                  0x7FFFFFFF);

          NotificationService.scheduleBookingReminder(
            id: notifId,
            title: "Upcoming Booking!",
            body: "Your game at ${widget.ground.name} starts in 30 minutes.",
            bookingStartTime: bookingStartDateTime,
          );

          await LiveActivityService().startBookingActivity(
            groundName: widget.ground.name,
            startTime: bookingStartDateTime,
          );
        }
      } catch (e) {
        debugPrint("Error scheduling reminder/live activity: $e");
      }

      // Step 3: All done -> Celebration state!
      if (!mounted) return;
      setState(() {
        _currentStep = 3;
        _isSuccess = true;
      });
      HapticFeedback.heavyImpact();

      // Give the user 1.6s to enjoy the success confirmation and Lottie animation
      await Future.delayed(const Duration(milliseconds: 1600));

      if (!mounted) return;
      _navigateToTicket(slotTimesPeriod, bookingData);
    } catch (e) {
      debugPrint("Booking processing failure: $e");
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _errorMessage = e.toString().replaceAll("Exception: ", "");
      });
    }
  }

  void _navigateToTicket(
      String slotTimesPeriod, Map<String, dynamic> bookingData) {
    final ticket = TicketModel(
      bookingId: bookingData['id'] ?? widget.orderId,
      groundId: widget.ground.id,
      displayId: _confirmedDisplayId,
      venueName: widget.ground.name,
      locationName: widget.ground.locationName,
      pitchName: "Main Pitch",
      date: widget.selectedDate,
      time: slotTimesPeriod,
      bookedBy: "User",
      location: widget.ground.address.isNotEmpty
          ? widget.ground.address
          : (widget.ground.city.isNotEmpty
              ? widget.ground.city
              : "Location"),
      latitude: widget.ground.latitude,
      longitude: widget.ground.longitude,
      price: widget.totalAmount,
      imageUrl: widget.ground.imageUrl,
      images: widget.ground.images,
      isPaid: true,
      sportName: widget.selectedSport,
      period:
          "${widget.selectedPeriod}|${widget.selectedSlots.map((s) => s.startTime).join(',')}",
      ownerId: widget.ground.ownerId,
      platformFee: RemoteConfigService().platformFee,
      amenities: widget.ground.amenities,
      createdAt: DateTime.tryParse(bookingData['created_at']?.toString() ?? '')
              ?.toLocal() ??
          DateTime.now(),
      status: 'paid',
      summaryData: widget.summaryData,
    );

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, anim, secAnim) => ViewTicketScreen(
          isFromBookingFlow: true,
          ticket: ticket,
        ),
        transitionsBuilder: (context, anim, secAnim, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Top Branding & Turf Quick Overview
                        _buildTopVenueCard(theme, isDark),

                        const SizedBox(height: 24),

                        // Center Animated Hero
                        if (_hasError)
                          _buildErrorView(theme, isDark)
                        else if (_isSuccess)
                          _buildSuccessView(theme, isDark)
                        else
                          _buildProcessingHero(theme, isDark),

                        const SizedBox(height: 28),

                        // Progress Step Checklist
                        if (!_hasError) _buildMilestoneChecklist(theme, isDark),

                        const SizedBox(height: 24),

                        // Bottom Reassurance Footer
                        _buildBottomFooter(theme, isDark),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTopVenueCard(ThemeData theme, bool isDark) {
    final formattedDate =
        DateFormat('EEE, d MMM yyyy').format(widget.selectedDate);
    final slotCount = widget.selectedSlots.length;
    final slotSummary = slotCount > 0
        ? "$slotCount ${slotCount == 1 ? 'Slot' : 'Slots'} (${widget.selectedSlots.first.startTime})"
        : widget.selectedPeriod;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryDarkGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.sports_cricket,
              color: AppColors.primaryDarkGreen,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.ground.name,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 15.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  "$formattedDate • $slotSummary",
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryDarkGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              "₹${widget.totalAmount.toStringAsFixed(0)}",
              style: const TextStyle(
                color: AppColors.primaryDarkGreen,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingHero(ThemeData theme, bool isDark) {
    return Column(
      children: [
        // Pulsing Rings Radar Animation
        SizedBox(
          width: 170,
          height: 170,
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Outer Ripple
                  Container(
                    width: 90 + (80 * _pulseController.value),
                    height: 90 + (80 * _pulseController.value),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryDarkGreen.withValues(
                        alpha: (1.0 - _pulseController.value) * 0.18,
                      ),
                    ),
                  ),
                  // Middle Ripple
                  Container(
                    width: 90 + (45 * _pulseController.value),
                    height: 90 + (45 * _pulseController.value),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryDarkGreen.withValues(
                        alpha: (1.0 - _pulseController.value) * 0.28,
                      ),
                    ),
                  ),
                  // Circular Rotating Progress Ring
                  SizedBox(
                    width: 96,
                    height: 96,
                    child: CircularProgressIndicator(
                      strokeWidth: 3.5,
                      color: AppColors.primaryDarkGreen,
                      backgroundColor:
                          AppColors.primaryDarkGreen.withValues(alpha: 0.15),
                    ),
                  ),
                  // Center Core Emblem
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.primaryDarkGreen,
                          Color(0xFF0F5A28),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryDarkGreen
                              .withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.lock_clock_rounded,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
                ],
              );
            },
          ),
        ),

        const SizedBox(height: 20),

        Text(
          "Securing Your Booking...",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: 21,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            "Payment received! We're locking your slots and preparing your official match pass.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessView(ThemeData theme, bool isDark) {
    final displayTag =
        _confirmedDisplayId > 0 ? " #CB$_confirmedDisplayId" : "";

    return Column(
      children: [
        SizedBox(
          width: 140,
          height: 140,
          child: Lottie.asset(
            'assets/animations/Success.json',
            repeat: false,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          "Booking Confirmed! 🎉",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: 23,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primaryDarkGreen.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            "Match Pass$displayTag",
            style: const TextStyle(
              color: AppColors.primaryDarkGreen,
              fontWeight: FontWeight.bold,
              fontSize: 13.5,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          "Redirecting to your match ticket details...",
          style: TextStyle(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            fontSize: 12.5,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorView(ThemeData theme, bool isDark) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.error_outline_rounded,
            color: Colors.red,
            size: 44,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          "Payment Processing Issue",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            _errorMessage.isNotEmpty
                ? _errorMessage
                : "We could not finalize the booking in real-time. If money was deducted, your slots or refund will be reconciled.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.nav,
                    (route) => false,
                    arguments: 1,
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("My Bookings"),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _hasError = false;
                    _errorMessage = "";
                  });
                  _executeBookingFlow();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDarkGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Retry Check"),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMilestoneChecklist(ThemeData theme, bool isDark) {
    final steps = [
      {
        "title": "Payment Verified",
        "subtitle": "Order #${widget.orderId.length > 8 ? widget.orderId.substring(0, 8) : widget.orderId} verified",
      },
      {
        "title": "Locking Turf Slots",
        "subtitle": "Blocking selected slots on turf schedule",
      },
      {
        "title": "Generating Match Pass",
        "subtitle": "Creating digital QR entry pass & reminders",
      },
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < steps.length; i++) ...[
            _buildStepRow(
              index: i,
              title: steps[i]["title"]!,
              subtitle: steps[i]["subtitle"]!,
              theme: theme,
              isDark: isDark,
            ),
            if (i < steps.length - 1)
              Padding(
                padding: const EdgeInsets.only(left: 17),
                child: Container(
                  width: 2,
                  height: 18,
                  color: _currentStep > i
                      ? AppColors.primaryDarkGreen
                      : (isDark ? Colors.white12 : Colors.black12),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildStepRow({
    required int index,
    required String title,
    required String subtitle,
    required ThemeData theme,
    required bool isDark,
  }) {
    final bool isDone = _currentStep > index || _isSuccess;
    final bool isInProgress = _currentStep == index && !_isSuccess;

    Widget iconWidget;
    if (isDone) {
      iconWidget = Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: AppColors.primaryDarkGreen.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check_circle_rounded,
          color: AppColors.primaryDarkGreen,
          size: 22,
        ),
      );
    } else if (isInProgress) {
      iconWidget = Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: AppColors.primaryDarkGreen.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primaryDarkGreen,
            ),
          ),
        ),
      );
    } else {
      iconWidget = Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            "${index + 1}",
            style: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        iconWidget,
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: isDone || isInProgress
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurface.withValues(alpha: 0.45),
                  fontWeight:
                      isInProgress || isDone ? FontWeight.bold : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(
                    alpha: isInProgress || isDone ? 0.6 : 0.35,
                  ),
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomFooter(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock_rounded,
            size: 15,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              "Please do not press back or close the app while booking is finalizing",
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
