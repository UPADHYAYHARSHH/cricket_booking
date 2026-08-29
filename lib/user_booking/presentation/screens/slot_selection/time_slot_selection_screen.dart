import 'package:turfpro/common/constants/colors.dart';
import 'package:turfpro/user_booking/constants/widgets/app_sizedBox.dart';
import 'package:turfpro/user_booking/constants/widgets/app_text.dart';
import 'package:turfpro/user_booking/data/repositories/payment_repository.dart';
import 'package:turfpro/user_booking/domain/models/slot_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:turfpro/user_booking/presentation/screens/my_booking/my_booking_screen.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turfpro/user_booking/di/get_it/get_it.dart';
import 'package:turfpro/user_booking/constants/route_constants.dart';
import 'package:turfpro/user_booking/presentation/widgets/slot_selection_widgets.dart';
import 'package:turfpro/user_booking/presentation/blocs/slot_selection/slot_selection_cubit.dart';
import 'package:turfpro/user_booking/domain/models/booking_arguments.dart';
import 'package:turfpro/user_booking/presentation/blocs/slot_selection/slot_selection_state.dart';
import 'package:turfpro/user_booking/domain/repositories/loyalty_repository.dart';
import 'package:turfpro/user_booking/domain/repositories/wallet_repository.dart';
import 'package:turfpro/user_booking/domain/repositories/slot_repository.dart';
import 'package:turfpro/common/config/feature_config.dart';

import 'package:turfpro/common/services/cashfree_service.dart';
import 'package:turfpro/common/services/notification_service.dart';
import 'package:turfpro/common/services/live_activity_service.dart';
import 'package:intl/intl.dart';

class TimeSlotSelectionScreen extends StatefulWidget {
  const TimeSlotSelectionScreen({super.key});

  @override
  State<TimeSlotSelectionScreen> createState() => _TimeSlotSelectionScreenState();
}

class _TimeSlotSelectionScreenState extends State<TimeSlotSelectionScreen> {
  final _paymentRepo = getIt<PaymentRepository>();
  final _loyaltyRepo = getIt<LoyaltyRepository>();

  double? _pendingAmount;
  List<TimeSlot>? _pendingSlots;
  DateTime? _pendingDate;
  int _pendingAppliedPoints = 0;
  double _pendingAppliedWallet = 0.0;
  bool _isBookingInProgress = false;

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

  void _handlePaymentSuccess(String orderId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryDarkGreen)),
    );

    try {
      // In a real app, verify payment on the backend here
      final isValid = await _paymentRepo.verifyPayment(orderId: orderId);

      final cubit = context.read<SlotSelectionCubit>();
      final ground = cubit.state.selectedTurf;

      if (isValid && ground != null && _pendingDate != null) {
        final slotTimesPeriod = (_pendingSlots != null && _pendingSlots!.isNotEmpty)
            ? _pendingSlots!.map((s) => "${s.startTime} - ${s.endTime}").join(', ')
            : cubit.state.selectedPeriod;

        // Save booking using bypass for now until backend is ready
        final bookingData = await _paymentRepo.saveDirectBooking(
          groundId: ground.id,
          date: _pendingDate!,
          amount: (_pendingAmount!).toInt(),
          sportName: cubit.state.selectedSport,
          period: slotTimesPeriod,
          slotStartTimes: _pendingSlots?.map((s) => s.startTime).toList() ?? [],
        );

        final int displayId = bookingData['display_id'] ?? 0;
        if (!mounted) return;
        Navigator.pop(context); // pop loading

        // Deduct from wallet if used
        if (FeatureConfig.isWalletEnabled && _pendingAppliedWallet > 0) {
          final walletRepo = getIt<WalletRepository>();
          final currentBalance = await walletRepo.getBalance();
          await walletRepo.updateBalance(currentBalance - _pendingAppliedWallet);
          await walletRepo.addTransaction(
            amount: _pendingAppliedWallet,
            type: 'debit',
            description: 'Used for booking @ ${ground.name}',
          );
        }

        if (FeatureConfig.isLoyaltyEnabled) {
          if (_pendingAppliedPoints > 0) await _loyaltyRepo.redeemPoints(_pendingAppliedPoints);
          final pointsEarned = ((_pendingAmount ?? 0) / 10).floor();
          if (pointsEarned > 0) await _loyaltyRepo.earnPoints(pointsEarned);
        }

        // Trigger Notification and Live Activity
        try {
          if (_pendingSlots != null && _pendingSlots!.isNotEmpty && _pendingDate != null) {
            final timeFormat = DateFormat("h:mm a");
            final startTimeParsed = timeFormat.parse(_pendingSlots!.first.startTime);
            final bookingStartDateTime = DateTime(
              _pendingDate!.year,
              _pendingDate!.month,
              _pendingDate!.day,
              startTimeParsed.hour,
              startTimeParsed.minute,
            );
            
            NotificationService.scheduleBookingReminder(
              id: displayId,
              title: "Upcoming Booking!",
              body: "Your game at ${ground.name} starts in 30 minutes.",
              bookingStartTime: bookingStartDateTime,
            );

            LiveActivityService().startBookingActivity(
              groundName: ground.name,
              startTime: bookingStartDateTime,
            );
          }
        } catch (e) {
          debugPrint("Error scheduling notification/live activity: $e");
        }

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ViewTicketScreen(
              isFromBookingFlow: true,
              ticket: TicketModel(
                bookingId: bookingData['id'] ?? orderId,
                groundId: ground.id,
                displayId: displayId,
                venueName: ground.name,
                pitchName: "Main Pitch",
                date: _pendingDate!,
                time: slotTimesPeriod,
                bookedBy: "User",
                location: ground.address.isNotEmpty ? ground.address : (ground.city.isNotEmpty ? ground.city : "Location"),
                latitude: ground.latitude,
                longitude: ground.longitude,
                price: _pendingAmount!,
                imageUrl: ground.imageUrl,
                images: ground.images,
                isPaid: true,
                sportName: cubit.state.selectedSport ?? "Sport",
                period: slotTimesPeriod,
                ownerId: ground.ownerId,
                amenities: ground.amenities,
              ),
            ),
          ),
        );
      } else {
        if (!mounted) return;
        Navigator.pop(context);
        Navigator.pushNamed(
          context, 
          AppRoutes.paymentFailedScreen,
          arguments: BookingFailureArguments(
            errorMessage: 'Payment verification failed or was cancelled.',
            groundId: ground?.id,
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      Navigator.pop(context);
      Navigator.pushNamed(
        context, 
        AppRoutes.paymentFailedScreen,
        arguments: BookingFailureArguments(
          errorMessage: 'An unexpected error occurred during payment.',
        ),
      );
    }
  }

  void _handlePaymentError(dynamic error, String orderId) {
    Navigator.pushNamed(
      context, 
      AppRoutes.paymentFailedScreen,
      arguments: BookingFailureArguments(
        errorMessage: 'Payment Failed: ${error.toString()}',
      ),
    );
  }

  void _onConfirmBooking(
      double totalPrice, dynamic activeDate, List<TimeSlot> selectedSlots,
      {int appliedPoints = 0,
      double appliedWallet = 0.0,
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

      if (!fromRetry) {
        final now = DateTime.now();
        _pendingDate = DateTime(now.year, now.month, activeDate.date);
        if (_pendingDate!.isBefore(DateTime(now.year, now.month, now.day))) {
          _pendingDate = DateTime(now.year, now.month + 1, activeDate.date);
        }
      }

      // 1. Double check availability in DB to prevent duplicate bookings
      final slotRepo = getIt<SlotRepository>();
      final dbSlots = await slotRepo.fetchSlotsForGround(currentGround.id, _pendingDate!);
      
      final alreadyBookedSlots = <String>[];
      for (final selectedSlot in selectedSlots) {
        final matchedDbSlot = dbSlots.firstWhere(
          (dbSlot) => dbSlot.startTime == selectedSlot.startTime,
          orElse: () => TimeSlot(startTime: '', endTime: '', price: 0, status: SlotStatus.available),
        );
        if (matchedDbSlot.startTime.isNotEmpty && 
            (matchedDbSlot.status == SlotStatus.booked || matchedDbSlot.status == SlotStatus.blocked)) {
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
                text: "The following slots have already been booked by another user:\n\n${alreadyBookedSlots.join(', ')}\n\nPlease choose different slots.",
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const AppText(
                    text: "OK",
                    textStyle: TextStyle(color: AppColors.primaryDarkGreen, fontWeight: FontWeight.bold),
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
      
      final String orderId = orderResponse['order_id'] ?? orderResponse['orderId'];
      final String sessionId = orderResponse['payment_session_id'] ?? orderResponse['paymentSessionId'];

      if (!mounted) return;
      Navigator.pop(context); // Pop the loading dialog

      // Setup Polling as a fallback (Very useful for Web where callbacks might drop)
      bool isPolling = true;
      int pollCount = 0;
      void startPolling() async {
        while (isPolling && pollCount < 60) { // Poll for up to 5 minutes (60 * 5s)
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cubit = context.read<SlotSelectionCubit>();
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: AppText(
          text: cubit.state.selectedTurf?.name ?? "Select Slots",
          textStyle: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
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

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SlotSelectionWidgets.buildDateSelector(context, state.dates, (index) {
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
                          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
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
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error: No turf selected")));
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
                      _onConfirmBooking(
                          result['finalAmount'], activeDate, selectedSlots,
                          appliedPoints: result['appliedPoints'],
                          appliedWallet: result['appliedWallet'] ?? 0.0);
                    }
                  } catch (e, st) {
                    debugPrint("Error pushing BookingSummaryScreen: $e\n$st");
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                  }
                }),
            ],
          );
        },
      ),
    );
  }
}
