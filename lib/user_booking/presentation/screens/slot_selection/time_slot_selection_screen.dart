import 'package:turfpro/common/constants/colors.dart';
import 'package:turfpro/user_booking/constants/widgets/app_sizedBox.dart';
import 'package:turfpro/user_booking/constants/widgets/app_text.dart';
import 'package:turfpro/user_booking/data/repositories/payment_repository.dart';
import 'package:turfpro/user_booking/domain/models/slot_models.dart';
import 'package:flutter/material.dart';
import 'package:turfpro/user_booking/presentation/screens/my_booking/my_booking_screen.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
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

class TimeSlotSelectionScreen extends StatefulWidget {
  const TimeSlotSelectionScreen({super.key});

  @override
  State<TimeSlotSelectionScreen> createState() => _TimeSlotSelectionScreenState();
}

class _TimeSlotSelectionScreenState extends State<TimeSlotSelectionScreen> {
  late Razorpay _razorpay;
  final _paymentRepo = getIt<PaymentRepository>();
  final _loyaltyRepo = getIt<LoyaltyRepository>();

  double? _pendingAmount;
  List<TimeSlot>? _pendingSlots;
  DateTime? _pendingDate;
  bool _isBookingInProgress = false;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryDarkGreen)),
    );

    try {
      final isValid = await _paymentRepo.verifyPayment(
        orderId: response.orderId!,
        paymentId: response.paymentId!,
        signature: response.signature!,
      );

      final cubit = context.read<SlotSelectionCubit>();
      final ground = cubit.state.selectedTurf;

      if (isValid && ground != null && _pendingDate != null) {
        final slotTimesPeriod = (_pendingSlots != null && _pendingSlots!.isNotEmpty)
            ? _pendingSlots!.map((s) => "${s.startTime} - ${s.endTime}").join(', ')
            : cubit.state.selectedPeriod;

        final bookingData = await _paymentRepo.saveBooking(
          groundId: ground.id,
          slotTime: _pendingDate!,
          amount: (_pendingAmount! * 100).toInt(),
          orderId: response.orderId!,
          paymentId: response.paymentId!,
          signature: response.signature!,
          sportName: cubit.state.selectedSport,
          period: slotTimesPeriod,
          slotStartTimes: _pendingSlots?.map((s) => s.startTime).toList(),
        );

        final int displayId = bookingData['display_id'] ?? 0;
        if (!mounted) return;
        Navigator.pop(context);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ViewTicketScreen(
              isFromBookingFlow: true,
              ticket: TicketModel(
                bookingId: bookingData['id'] ?? response.orderId ?? 'N/A',
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
        );} else {
        if (!mounted) return;
        Navigator.pop(context);
        Navigator.pushNamed(context, AppRoutes.paymentFailedScreen);
      }
    } catch (_) {
      if (!mounted) return;
      Navigator.pop(context);
      Navigator.pushNamed(context, AppRoutes.paymentFailedScreen);
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    Navigator.pushNamed(context, AppRoutes.paymentFailedScreen);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('External Wallet: ${response.walletName}')));
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

      // Deduct from wallet if used
      if (FeatureConfig.isWalletEnabled && appliedWallet > 0) {
        final walletRepo = getIt<WalletRepository>();
        final currentBalance = await walletRepo.getBalance();
        await walletRepo.updateBalance(currentBalance - appliedWallet);
        await walletRepo.addTransaction(
          amount: appliedWallet,
          type: 'debit',
          description: 'Used for booking @ ${currentGround.name}',
        );
      }

      final slotTimesPeriod = selectedSlots.isNotEmpty
          ? selectedSlots.map((s) => "${s.startTime} - ${s.endTime}").join(', ')
          : cubit.state.selectedPeriod;

      final bookingData = await _paymentRepo.saveDirectBooking(
        groundId: currentGround.id,
        date: _pendingDate!,
        slotStartTimes: selectedSlots.map((s) => s.startTime).toList(),
        amount: totalPrice.toInt(),
        sportName: cubit.state.selectedSport,
        period: slotTimesPeriod,
      );

      final int displayId = bookingData['display_id'] ?? 0;

      if (FeatureConfig.isLoyaltyEnabled) {
        if (appliedPoints > 0) await _loyaltyRepo.redeemPoints(appliedPoints);
        final pointsEarned = (totalPrice / 10).floor();
        if (pointsEarned > 0) await _loyaltyRepo.earnPoints(pointsEarned);
      }

      if (!mounted) return;
      Navigator.pop(context);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ViewTicketScreen(
            isFromBookingFlow: true,
            ticket: TicketModel(
              bookingId: bookingData['id'] ?? 'DIRECT_${DateTime.now().millisecondsSinceEpoch}',
              groundId: currentGround.id,
              displayId: displayId,
              venueName: currentGround.name,
              pitchName: "Main Pitch",
              date: _pendingDate!,
              time: slotTimesPeriod,
              bookedBy: "User",
              location: currentGround.address.isNotEmpty ? currentGround.address : (currentGround.city.isNotEmpty ? currentGround.city : "Location"),
              latitude: currentGround.latitude,
              longitude: currentGround.longitude,
              price: totalPrice,
              imageUrl: currentGround.imageUrl,
              images: currentGround.images,
              isPaid: true,
              sportName: cubit.state.selectedSport ?? "Sport",
              period: slotTimesPeriod,
              ownerId: currentGround.ownerId,
              amenities: currentGround.amenities,
            ),
          ),
        ),
      );} catch (e) {
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

  String _getSlotPeriod(String? time) {
    if (time == null || time.isEmpty) return 'Day';
    try {
      final timeParts = time.split(' ');
      final timeH = timeParts[0].split(':');
      int hour = int.parse(timeH[0]);
      final ampm = timeParts.length > 1 ? timeParts[1].toUpperCase() : 'AM';
      if (ampm == 'PM' && hour != 12) hour += 12;
      if (ampm == 'AM' && hour == 12) hour = 0;
      if (hour < 6) return 'Midnight';
      if (hour < 12) return 'Day';
      if (hour < 18) return 'Evening';
      return 'Night';
    } catch (_) {
      return 'Day';
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
