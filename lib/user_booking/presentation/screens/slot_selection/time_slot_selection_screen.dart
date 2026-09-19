import 'package:hugeicons/hugeicons.dart';
import 'package:turfpro/common/constants/colors.dart';
import 'package:turfpro/common/widgets/discover_app_bar.dart';
import 'package:turfpro/user_booking/constants/widgets/app_sizedBox.dart';
import 'package:turfpro/user_booking/constants/widgets/app_text.dart';
import 'package:turfpro/user_booking/data/repositories/payment_repository.dart';
import 'package:turfpro/user_booking/domain/models/slot_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turfpro/user_booking/di/get_it/get_it.dart';
import 'package:turfpro/user_booking/constants/route_constants.dart';
import 'package:turfpro/user_booking/presentation/widgets/slot_selection_widgets.dart';
import 'package:turfpro/user_booking/presentation/blocs/slot_selection/slot_selection_cubit.dart';
import 'package:turfpro/user_booking/domain/models/booking_arguments.dart';
import 'package:turfpro/user_booking/presentation/blocs/slot_selection/slot_selection_state.dart';
import 'package:turfpro/user_booking/domain/repositories/slot_repository.dart';
import 'package:turfpro/common/services/cashfree_service.dart';
import 'package:turfpro/user_booking/domain/models/booking_summary_data.dart';
import 'package:turfpro/user_booking/presentation/screens/payment_status/booking_processing_screen.dart';

class TimeSlotSelectionScreen extends StatefulWidget {
  const TimeSlotSelectionScreen({super.key});

  @override
  State<TimeSlotSelectionScreen> createState() =>
      _TimeSlotSelectionScreenState();
}

class _TimeSlotSelectionScreenState extends State<TimeSlotSelectionScreen> {
  final _paymentRepo = getIt<PaymentRepository>();

  double? _pendingAmount;
  List<TimeSlot>? _pendingSlots;
  DateTime? _pendingDate;
  int _pendingAppliedPoints = 0;
  double _pendingAppliedWallet = 0.0;
  BookingSummaryData? _pendingSummaryData;
  bool _isBookingInProgress = false;
  bool _isPaymentHandled = false;
  bool _isAwaitingPaymentReturn = false;

  @override
  void initState() {
    super.initState();
    // Configure Cashfree callbacks
    CashfreeService().setCheckoutCallbacks(
      onSuccess: _handlePaymentSuccess,
      onError: _handlePaymentError,
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _handlePaymentSuccess(String orderId) {
    if (_isPaymentHandled) return;
    _isPaymentHandled = true;

    final cubit = context.read<SlotSelectionCubit>();
    final ground = cubit.state.selectedTurf;

    if (mounted) {
      setState(() {
        _isAwaitingPaymentReturn = false;
      });
    }

    if (ground != null && _pendingDate != null && _pendingAmount != null) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, anim, secAnim) => BookingProcessingScreen(
            orderId: orderId,
            ground: ground,
            selectedDate: _pendingDate!,
            totalAmount: _pendingAmount!,
            selectedSport: cubit.state.selectedSport ?? "Sport",
            selectedPeriod: cubit.state.selectedPeriod,
            selectedSlots: _pendingSlots ?? [],
            summaryData: _pendingSummaryData,
            appliedWallet: _pendingAppliedWallet,
            appliedPoints: _pendingAppliedPoints,
            onRetry: () {
              if (_pendingAmount != null &&
                  _pendingSlots != null &&
                  _pendingSlots!.isNotEmpty &&
                  _pendingDate != null) {
                final activeDate = cubit.state.dates.isNotEmpty
                    ? cubit.state.dates.firstWhere((d) => d.isSelected,
                        orElse: () => cubit.state.dates.first)
                    : null;
                if (activeDate != null) {
                  _onConfirmBooking(
                    _pendingAmount!,
                    activeDate,
                    _pendingSlots!,
                    fromRetry: true,
                    appliedPoints: _pendingAppliedPoints,
                    appliedWallet: _pendingAppliedWallet,
                    summaryData: _pendingSummaryData,
                  );
                }
              }
            },
          ),
          transitionsBuilder: (context, anim, secAnim, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 250),
        ),
      );
    } else {
      Navigator.pushNamed(
        context,
        AppRoutes.paymentFailedScreen,
        arguments: BookingFailureArguments(
          errorMessage: 'Payment verification failed or session expired.',
          groundId: ground?.id,
        ),
      );
    }
  }

  void _handlePaymentError(dynamic error, String orderId) {
    if (mounted) {
      setState(() {
        _isAwaitingPaymentReturn = false;
        _isBookingInProgress = false;
        _isPaymentHandled = false;
      });
    }

    String message =
        'Your payment could not be processed. If any amount was deducted, it will be automatically refunded within 5-7 business days.';
    try {
      if (error != null) {
        final errStr = error.toString();
        // If error object provides getMessage or a clean string that is not raw instance dump
        dynamic msg;
        try {
          msg = (error as dynamic).getMessage?.call();
        } catch (_) {}
        if (msg is String && msg.trim().isNotEmpty) {
          message = msg.trim();
        } else if (!errStr.toLowerCase().contains('cferrorresponse') &&
            !errStr.toLowerCase().contains('instance of')) {
          message = errStr;
        }
      }
    } catch (_) {}

    Navigator.pushNamed(
      context,
      AppRoutes.paymentFailedScreen,
      arguments: BookingFailureArguments(
        errorMessage: message,
      ),
    );
  }

  void _onConfirmBooking(
      double totalPrice, dynamic activeDate, List<TimeSlot> selectedSlots,
      {int appliedPoints = 0,
      double appliedWallet = 0.0,
      BookingSummaryData? summaryData,
      bool fromRetry = false}) async {
    HapticFeedback.mediumImpact();
    final cubit = context.read<SlotSelectionCubit>();
    final currentGround = cubit.state.selectedTurf;
    if (selectedSlots.isEmpty || currentGround == null) return;
    if (_isBookingInProgress) return;

    setState(() {
      _isBookingInProgress = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
          child: CircularProgressIndicator(color: AppColors.accentOrange)),
    );

    try {
      _pendingAmount = totalPrice;
      _pendingSlots = selectedSlots;
      _pendingSummaryData = summaryData;

      if (!fromRetry) {
        final now = DateTime.now();
        _pendingDate = DateTime(now.year, now.month, activeDate.date);
        if (_pendingDate!.isBefore(DateTime(now.year, now.month, now.day))) {
          _pendingDate = DateTime(now.year, now.month + 1, activeDate.date);
        }
      }

      // 1. Double check availability in DB to prevent duplicate bookings
      final slotRepo = getIt<SlotRepository>();
      final dbSlots =
          await slotRepo.fetchSlotsForGround(currentGround.id, _pendingDate!);

      final alreadyBookedSlots = <String>[];
      for (final selectedSlot in selectedSlots) {
        final matchedDbSlot = dbSlots.firstWhere(
          (dbSlot) => dbSlot.startTime == selectedSlot.startTime,
          orElse: () => TimeSlot(
              startTime: '',
              endTime: '',
              price: 0,
              status: SlotStatus.available),
        );
        if (matchedDbSlot.startTime.isNotEmpty &&
            (matchedDbSlot.status == SlotStatus.booked ||
                matchedDbSlot.status == SlotStatus.blocked ||
                matchedDbSlot.status == SlotStatus.requested)) {
          alreadyBookedSlots.add(selectedSlot.startTime);
        }
      }

      if (alreadyBookedSlots.isNotEmpty) {
        if (mounted) {
          Navigator.pop(context); // Pop the progress indicator
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const AppText(
                text: "Slots Already Booked",
                textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              content: AppText(
                text:
                    "The following slots have already been booked by another user:\n\n${alreadyBookedSlots.join(', ')}\n\nPlease choose different slots.",
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const AppText(
                    text: "OK",
                    textStyle: TextStyle(
                        color: AppColors.primaryDarkGreen,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          );

          // Refresh the slots stream/list to display the newly booked slots
          cubit.loadSlots(
            currentGround.id,
            _pendingDate!,
            openingTime: currentGround.openingTime,
            closingTime: currentGround.closingTime,
            pricePerSlot: currentGround.pricePerHour.toDouble(),
          );
        }
        setState(() {
          _isBookingInProgress = false;
        });
        return;
      }

      _pendingAppliedPoints = appliedPoints;
      _pendingAppliedWallet = appliedWallet;

      // Note: Wallet deduction and Loyalty points are now processed in _handlePaymentSuccess

      // Call backend to create Cashfree order and fetch session ID
      // We do NOT send returnUrl for Web anymore because we want to enforce the modal drop-in
      // without reloading the Flutter Web app.
      final orderResponse = await _paymentRepo.createOrder(totalPrice.toInt());

      final String orderId =
          orderResponse['order_id'] ?? orderResponse['orderId'];
      final String sessionId = orderResponse['payment_session_id'] ??
          orderResponse['paymentSessionId'];

      if (!mounted) return;
      Navigator.pop(context); // Pop the loading dialog

      // Setup Polling as a fallback (Very useful for Web where callbacks might drop)
      bool isPolling = true;
      int pollCount = 0;
      void startPolling() async {
        while (isPolling && pollCount < 60) {
          // Poll for up to 5 minutes (60 * 5s)
          await Future.delayed(const Duration(seconds: 5));
          if (!mounted || !isPolling) break;
          pollCount++;
          try {
            final isValid = await _paymentRepo.verifyPayment(orderId: orderId);
            if (isValid && isPolling && mounted) {
              isPolling = false;
              _handlePaymentSuccess(orderId);
              break;
            }
          } catch (_) {}
        }
      }

      startPolling();

      // Ensure polling stops if we get the callback directly or user leaves
      CashfreeService().setCheckoutCallbacks(
        onSuccess: (id) {
          isPolling = false;
          _handlePaymentSuccess(id);
        },
        onError: (error, id) {
          isPolling = false;
          _handlePaymentError(error, id);
        },
      );

      if (mounted) {
        setState(() {
          _isAwaitingPaymentReturn = true;
        });
      }

      // Call Cashfree Service with actual backend session
      CashfreeService().doPayment(
        orderId: orderId,
        paymentSessionId: sessionId,
      );

      // Note: The rest of the booking save logic and navigation to ViewTicketScreen
      // has been moved to _handlePaymentSuccess() at the top of this file!
    } catch (e) {
      if (mounted) {
        try {
          Navigator.pop(context);
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Booking Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBookingInProgress = false;
        });
      }
    }
  }

  void _onRequestBooking(
    double totalPrice,
    dynamic activeDate,
    List<TimeSlot> selectedSlots, {
    int appliedPoints = 0,
    double appliedWallet = 0.0,
    BookingSummaryData? summaryData,
  }) async {
    HapticFeedback.mediumImpact();
    final cubit = context.read<SlotSelectionCubit>();
    final currentGround = cubit.state.selectedTurf;
    if (selectedSlots.isEmpty || currentGround == null) return;
    if (_isBookingInProgress) return;

    setState(() {
      _isBookingInProgress = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
          child: CircularProgressIndicator(color: AppColors.accentOrange)),
    );

    try {
      final now = DateTime.now();
      DateTime bookingDate = DateTime(now.year, now.month, activeDate.date);
      if (bookingDate.isBefore(DateTime(now.year, now.month, now.day))) {
        bookingDate = DateTime(now.year, now.month + 1, activeDate.date);
      }

      // 1. Check slot availability
      final slotRepo = getIt<SlotRepository>();
      final dbSlots =
          await slotRepo.fetchSlotsForGround(currentGround.id, bookingDate);

      final alreadyBookedSlots = <String>[];
      for (final selectedSlot in selectedSlots) {
        final matchedDbSlot = dbSlots.firstWhere(
          (dbSlot) => dbSlot.startTime == selectedSlot.startTime,
          orElse: () => TimeSlot(
              startTime: '',
              endTime: '',
              price: 0,
              status: SlotStatus.available),
        );
        if (matchedDbSlot.startTime.isNotEmpty &&
            (matchedDbSlot.status == SlotStatus.booked ||
                matchedDbSlot.status == SlotStatus.blocked ||
                matchedDbSlot.status == SlotStatus.requested)) {
          alreadyBookedSlots.add(selectedSlot.startTime);
        }
      }

      if (alreadyBookedSlots.isNotEmpty) {
        if (mounted) {
          Navigator.pop(context); // Pop loading
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const AppText(
                text: "Slots Already Booked",
                textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              content: AppText(
                text:
                    "The following slots have already been booked:\n\n${alreadyBookedSlots.join(', ')}\n\nPlease choose different slots.",
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const AppText(
                    text: "OK",
                    textStyle: TextStyle(
                        color: AppColors.primaryDarkGreen,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          );
          cubit.loadSlots(
            currentGround.id,
            bookingDate,
            openingTime: currentGround.openingTime,
            closingTime: currentGround.closingTime,
            pricePerSlot: currentGround.pricePerHour.toDouble(),
          );
        }
        setState(() {
          _isBookingInProgress = false;
        });
        return;
      }

      // 2. Request booking via repository
      await _paymentRepo.requestBooking(
        groundId: currentGround.id,
        groundName: currentGround.name,
        groundAddress: currentGround.address,
        sport: cubit.state.selectedSport ?? "Sport",
        bookingDate: bookingDate,
        selectedSlots: selectedSlots,
        totalAmount: totalPrice,
        appliedPoints: appliedPoints,
        appliedWallet: appliedWallet,
        summaryData: summaryData,
      );

      if (!mounted) return;
      Navigator.pop(context); // Pop loading

      // 3. Show dialog confirming request sent
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogCtx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          icon: const Icon(Icons.timer_outlined, color: Colors.amber, size: 48),
          title: const Text(
            "Booking Requested!",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Your booking request has been submitted to the turf owner.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.schedule, color: Colors.amber, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "The owner has 45 minutes to confirm. Once confirmed, you will have 45 minutes to complete payment.",
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDarkGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                minimumSize: const Size(double.infinity, 44),
              ),
              onPressed: () {
                Navigator.pop(dialogCtx);
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.nav,
                  (route) => false,
                  arguments: 1,
                );
              },
              child: const Text("View My Bookings", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        try {
          Navigator.pop(context);
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error requesting booking: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBookingInProgress = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cubit = context.read<SlotSelectionCubit>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: AppText(
          text: cubit.state.selectedTurf?.name ?? "Select Slots",
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            size: 20,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: const DiscoverAppBarBackground(),
      ),
      body: BlocBuilder<SlotSelectionCubit, SlotSelectionState>(
        builder: (context, state) {
          final currentTurf = state.selectedTurf;
          if (currentTurf == null) {
            return const Center(child: Text("Error: No turf selected"));
          }

          final selectedSlots = state.slots
              .where((s) => s.status == SlotStatus.selected)
              .toList();
          final totalPrice =
              selectedSlots.fold<double>(0, (sum, s) => sum + s.price);
          final activeDate = state.dates.isNotEmpty
              ? state.dates.firstWhere((d) => d.isSelected,
                  orElse: () => state.dates.first)
              : null;

          return Stack(
            children: [
              Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SlotSelectionWidgets.buildDateSelector(
                          context, state.dates, (index) {
                        cubit.selectDate(index, currentTurf.id,
                            openingTime: currentTurf.openingTime,
                            closingTime: currentTurf.closingTime,
                            pricePerSlot: currentTurf.pricePerHour.toDouble(),
                            slotDuration: currentTurf.slotDuration);
                      }),
                      if (state.isLoading)
                        SlotSelectionWidgets.buildSlotShimmer(context)
                      else if (state.errorMessage != null)
                        SlotSelectionWidgets.buildErrorWidget(
                          context,
                          state.errorMessage!,
                          () => cubit.loadSlots(
                            currentTurf.id,
                            state.selectedDate ?? DateTime.now(),
                            openingTime: currentTurf.openingTime,
                            closingTime: currentTurf.closingTime,
                            pricePerSlot: currentTurf.pricePerHour.toDouble(),
                            slotDuration: currentTurf.slotDuration,
                          ),
                        )
                      else if (state.slots.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              vertical: 40, horizontal: 20),
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Theme.of(context)
                                  .dividerColor
                                  .withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.event_busy_rounded,
                                size: 48,
                                color: Colors.grey.withValues(alpha: 0.3),
                              ),
                              const AppSizedBox(height: 16),
                              AppText(
                                text: "No slots available",
                                textStyle: TextStyle(
                                  color: Colors.grey.withValues(alpha: 0.7),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const AppSizedBox(height: 4),
                              AppText(
                                text: "Try selecting a different date",
                                textStyle: TextStyle(
                                  color: Colors.grey.withValues(alpha: 0.5),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        SlotSelectionWidgets.buildGroupedSlotSection(
                            context, state.slots, (i) => cubit.toggleSlot(i),
                            selectedDate: state.selectedDate),
                    ],
                  ),
                ),
              ),

              // Fixed Bottom Bar
              if (activeDate != null)
                SlotSelectionWidgets.buildBottomBar(
                    context, selectedSlots, activeDate, totalPrice, () async {
                  if (state.selectedTurf == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text("Error: No turf selected")));
                    return;
                  }
                  try {
                    final result = await Navigator.pushNamed(
                        context, AppRoutes.bookingSummary,
                        arguments: BookingSummaryArguments(
                          ground: state.selectedTurf!,
                          selectedSport: state.selectedSport ?? "Sport",
                          selectedSlots: selectedSlots,
                          activeDate: activeDate,
                          selectedPeriod: state.selectedPeriod,
                          basePrice: totalPrice,
                        ));
                    if (result != null && result is Map<String, dynamic>) {
                      final summaryData =
                          result['summaryData'] as BookingSummaryData?;
                      if (result['isApprovalRequired'] == true) {
                        _onRequestBooking(
                          (result['finalAmount'] as num).toDouble(),
                          activeDate,
                          selectedSlots,
                          appliedPoints: result['appliedPoints'] ?? 0,
                          appliedWallet:
                              (result['appliedWallet'] as num?)?.toDouble() ?? 0.0,
                          summaryData: summaryData,
                        );
                      } else {
                        _onConfirmBooking(
                          (result['finalAmount'] as num).toDouble(),
                          activeDate,
                          selectedSlots,
                          appliedPoints: result['appliedPoints'] ?? 0,
                          appliedWallet:
                              (result['appliedWallet'] as num?)?.toDouble() ?? 0.0,
                          summaryData: summaryData,
                        );
                      }
                    }
                  } catch (e, st) {
                    debugPrint("Error pushing BookingSummaryScreen: $e\n$st");
                    if (context.mounted) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text("Error: $e")));
                    }
                  }
                }),
              ],
            ),
            if (_isAwaitingPaymentReturn)
              Positioned.fill(
                child: Container(
                  color: theme.scaffoldBackgroundColor,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            color: AppColors.primaryDarkGreen
                                .withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: SizedBox(
                              width: 32,
                              height: 32,
                              child: CircularProgressIndicator(
                                color: AppColors.primaryDarkGreen,
                                strokeWidth: 3,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "Processing Payment...",
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            "Please wait while we receive confirmation from your bank",
                            style: TextStyle(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.6),
                              fontSize: 12.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
        },
      ),
    );
  }
}


