### lib\user_booking\presentation\screens\slot_selection\slot_slection.dart
```dart
import 'package:turfpro/common/constants/colors.dart';
import 'package:turfpro/user_booking/constants/widgets/app_sizedBox.dart';
import 'package:turfpro/user_booking/constants/widgets/app_text.dart';
import 'package:turfpro/user_booking/data/repositories/payment_repository.dart';
import 'package:turfpro/user_booking/domain/models/slot_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:turfpro/user_booking/di/get_it/get_it.dart';
import 'package:turfpro/user_booking/constants/route_constants.dart';
import 'package:turfpro/user_booking/presentation/widgets/slot_selection_widgets.dart';
import 'package:turfpro/user_booking/data/models/ground_model.dart';
import 'package:turfpro/user_booking/data/models/location_model.dart';
import 'package:turfpro/user_booking/presentation/blocs/slot_selection/slot_selection_cubit.dart';
import 'package:turfpro/user_booking/domain/models/booking_arguments.dart';
import 'package:turfpro/user_booking/presentation/blocs/slot_selection/slot_selection_state.dart';
import 'package:turfpro/user_booking/domain/repositories/review_repository.dart';
import 'package:turfpro/user_booking/data/models/review_model.dart';
import 'package:turfpro/user_booking/domain/repositories/loyalty_repository.dart';
import 'package:turfpro/user_booking/domain/repositories/wallet_repository.dart';
import 'package:turfpro/user_booking/domain/repositories/slot_repository.dart';
import 'package:turfpro/common/config/feature_config.dart';
import 'package:share_plus/share_plus.dart';
import 'package:hugeicons/hugeicons.dart';

class SlotSelectionScreen extends StatefulWidget {
  const SlotSelectionScreen({super.key});

  @override
  State<SlotSelectionScreen> createState() => _SlotSelectionScreenState();
}

class _SlotSelectionScreenState extends State<SlotSelectionScreen> {
  GroundModel? _ground;
  bool _isInitialized = false;
  List<ReviewModel> _reviews = [];
  bool _isLoadingReviews = true;

  @override
  void initState() {
    super.initState();
  }

  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is GroundModel) {
        _ground = args;
        context.read<SlotSelectionCubit>().initFacility(_ground!);
      } else if (args is LocationModel) {
        context.read<SlotSelectionCubit>().initForLocation(args);
      }
      _isInitialized = true;
    }
  }

  Future<void> _loadReviews(String groundId) async {
    if (!mounted) return;
    setState(() {
      _isLoadingReviews = true;
    });
    try {
      final reviews =
          await getIt<ReviewRepository>().fetchGroundReviews(groundId);
      if (mounted) {
        setState(() {
          _reviews = reviews;
          _isLoadingReviews = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingReviews = false);
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

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  Future<bool> _showClearSelectionDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const AppText(
              text: "Clear Selection?",
              textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            content: const AppText(
              text:
                  "Changing sport or ground will clear your currently selected slots. Do you want to proceed?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const AppText(
                    text: "Cancel", textStyle: TextStyle(color: Colors.grey)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const AppText(
                    text: "Clear & Proceed",
                    textStyle: TextStyle(
                        color: Colors.red, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _shareGround() {
    if (_ground == null) return;
    final String shareText = 'Check out ${_ground!.name} on TurfPro!\n'
        'Location: ${_ground!.address}\n'
        'Book your slots now for only ₹${_ground!.pricePerHour}/hr!';
    Share.share(shareText);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          context.read<SlotSelectionCubit>().clearSelections();
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        bottomNavigationBar: BlocBuilder<SlotSelectionCubit, SlotSelectionState>(
          builder: (context, state) {
            final isEnabled = state.selectedTurf != null;
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, -4),
                    blurRadius: 10,
                  )
                ]
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDarkGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    onPressed: isEnabled
                        ? () {
                            Navigator.pushNamed(context, AppRoutes.timeSlotSelection);
                          }
                        : null,
                    child: const AppText(
                      text: "Book",
                      textStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        body: BlocConsumer<SlotSelectionCubit, SlotSelectionState>(
          listenWhen: (previous, current) => previous.selectedTurf?.id != current.selectedTurf?.id,
          listener: (context, state) {
            if (state.selectedTurf != null) {
              _loadReviews(state.selectedTurf!.id);
            }
          },
          builder: (context, state) {
          final cubit = context.read<SlotSelectionCubit>();
          final selectedSlots = state.slots
              .where((s) => s.status == SlotStatus.selected)
              .toList();
          final totalPrice =
              selectedSlots.fold<double>(0, (sum, s) => sum + s.price);
          final activeDate = state.dates.isNotEmpty
              ? state.dates.firstWhere((d) => d.isSelected,
                  orElse: () => state.dates.first)
              : null;

          final displayVenue = _ground ?? (state.facilityGrounds.isNotEmpty ? state.facilityGrounds.first : null);

          return Column(
            children: [
              // Fixed Header
              SlotSelectionWidgets.buildHeader(
                  context, state.selectedTurf ?? _ground,
                  title: state.selectedTurf?.name ?? "Book Slots",
                  onShare: _shareGround,
                  ),

              if (state.isLoading && state.availableSports.isEmpty)
                Expanded(
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: SlotSelectionWidgets.buildSportGroundShimmer(context),
                  ),
                )
              else ...[
                // Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    child: Column(
                      children: [
                        // Venue Info
                        SlotSelectionWidgets.buildVenueImageCarousel(context, displayVenue),
                        SlotSelectionWidgets.buildVenueInfoHeader(context, displayVenue),

                        // Sport Selection
                        SlotSelectionWidgets.buildSportSelection(
                          context,
                          state,
                          onSportChanged: (sport) async {
                            if (selectedSlots.isNotEmpty && sport != state.selectedSport) {
                              final proceed = await _showClearSelectionDialog(context);
                              if (!proceed) return;
                              cubit.clearSelections();
                            }
                            cubit.selectSport(sport);
                          },
                        ),

                        // Ground Selection
                        SlotSelectionWidgets.buildGroundSelection(
                          context,
                          state,
                          onTurfChanged: (turf) async {
                            if (selectedSlots.isNotEmpty && turf.id != state.selectedTurf?.id) {
                              final proceed = await _showClearSelectionDialog(context);
                              if (!proceed) return;
                              cubit.clearSelections();
                            }
                            cubit.selectTurf(turf);
                          },
                        ),

                        // Amenities & Description
                        SlotSelectionWidgets.buildAmenitiesSection(context, state.selectedTurf?.amenities?.isNotEmpty == true ? state.selectedTurf?.amenities : displayVenue?.amenities),
                        SlotSelectionWidgets.buildDescriptionSection(context, (state.selectedTurf?.description ?? '').isNotEmpty ? state.selectedTurf?.description : displayVenue?.description),

                        // Map (if available)
                        if (displayVenue != null)
                          SlotSelectionWidgets.buildMapSection(
                            context,
                            latitude: displayVenue.latitude,
                            longitude: displayVenue.longitude,
                            address: displayVenue.address,
                          ),

                        // Reviews (we pass the displayVenue id or ground id to _reviews which are loaded separately)
                        SlotSelectionWidgets.buildReviewSection(context, _reviews, _isLoadingReviews),
                      ],
                    ),
                  ),
                ),
              ],

            ],
          );
        },
      ),
    ),
  );
}

}
```



### lib\user_booking\presentation\screens\slot_selection\time_slot_selection_screen.dart
```dart
import 'package:turfpro/common/constants/colors.dart';
import 'package:turfpro/user_booking/constants/widgets/app_sizedBox.dart';
import 'package:turfpro/user_booking/constants/widgets/app_text.dart';
import 'package:turfpro/user_booking/data/repositories/payment_repository.dart';
import 'package:turfpro/user_booking/domain/models/slot_models.dart';
import 'package:flutter/material.dart';
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
        );

        final int displayId = bookingData['display_id'] ?? 0;
        if (!mounted) return;
        Navigator.pop(context);

        Navigator.pushReplacementNamed(
          context,
          AppRoutes.bookingConfirmationScreen,
          arguments: BookingSuccessArguments(
            ground: ground,
            date: _pendingDate!,
            selectedSlots: _pendingSlots ?? [],
            orderId: response.orderId!,
            displayId: displayId,
            totalPrice: _pendingAmount!,
            sportName: cubit.state.selectedSport ?? "Sport",
            selectedPeriod: slotTimesPeriod,
          ),
        );
      } else {
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

      Navigator.pushReplacementNamed(
        context,
        AppRoutes.bookingConfirmationScreen,
        arguments: BookingSuccessArguments(
          ground: currentGround,
          date: _pendingDate!,
          selectedSlots: selectedSlots,
          orderId: 'DIRECT_${DateTime.now().millisecondsSinceEpoch}',
          displayId: displayId,
          totalPrice: totalPrice,
          sportName:
              cubit.state.selectedSport ?? "Sport",
          selectedPeriod: slotTimesPeriod,
        ),
      );
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
                            pricePerSlot: currentTurf.pricePerHour.toDouble());
                      }),
                      SlotSelectionWidgets.buildPeriodFilter(
                          context, state.selectedPeriod, (p) => cubit.changePeriod(p)),
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
                          ),
                        )
                      else ...[
                        Builder(builder: (context) {
                          final filtered = state.slots
                              .asMap()
                              .entries
                              .where((e) =>
                                  _getSlotPeriod(e.value.startTime) == state.selectedPeriod)
                              .toList();

                          if (filtered.isEmpty) {
                            return Container(
                              width: double.infinity,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: Theme.of(context).dividerColor.withOpacity(0.05)),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.event_busy_rounded,
                                    size: 48,
                                    color: Colors.grey.withOpacity(0.3),
                                  ),
                                  const AppSizedBox(height: 16),
                                  AppText(
                                    text: "No slots available for ${state.selectedPeriod}",
                                    textStyle: TextStyle(
                                      color: Colors.grey.withValues(alpha: 0.7),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const AppSizedBox(height: 4),
                                  AppText(
                                    text: "Try selecting a different time of day or date",
                                    textStyle: TextStyle(
                                      color: Colors.grey.withValues(alpha: 0.5),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return SlotSelectionWidgets.buildSlotSection(
                              context,
                              filtered.map((e) => e.value).toList(),
                              (i) => cubit.toggleSlot(filtered[i].key));
                        }),
                      ],
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
```



### lib\user_booking\presentation\screens\booking_summary\booking_summary_screen.dart
```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:turfpro/common/constants/colors.dart';
import 'package:turfpro/user_booking/constants/widgets/app_button.dart';
import 'package:turfpro/common/config/feature_config.dart';
import 'package:turfpro/user_booking/constants/widgets/app_sizedBox.dart';
import 'package:turfpro/user_booking/constants/widgets/app_text.dart';
import 'package:turfpro/user_booking/data/models/ground_model.dart';
import 'package:turfpro/user_booking/domain/models/slot_models.dart';
import 'package:turfpro/user_booking/domain/models/booking_arguments.dart';
import 'package:turfpro/user_booking/presentation/widgets/ground_image_carousel.dart';
import 'package:turfpro/user_booking/presentation/widgets/slot_selection_widgets.dart';

import 'package:turfpro/user_booking/presentation/blocs/slot_selection/slot_selection_cubit.dart';
import 'package:turfpro/user_booking/presentation/blocs/slot_selection/slot_selection_state.dart';

class BookingSummaryScreen extends StatelessWidget {
  const BookingSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final rawArgs = ModalRoute.of(context)?.settings.arguments;

    if (rawArgs == null || rawArgs is! BookingSummaryArguments) {
      return Scaffold(
        body: Center(
          child: AppText(text: "Invalid booking data"),
        ),
      );
    }

    final args = rawArgs;
    final ground = args.ground;
    final selectedSlots = args.selectedSlots;
    final basePrice = args.basePrice;
    final activeDate = args.activeDate;
    final selectedSport = args.selectedSport;
    final selectedPeriod = args.selectedPeriod;

    return BlocBuilder<SlotSelectionCubit, SlotSelectionState>(
      builder: (context, state) {
        const double platformFee = 25.0;

        // Loyalty Points Logic
        double pointsDiscount = 0.0;
        if (FeatureConfig.isLoyaltyEnabled) {
          bool canRedeem = state.availableLoyaltyPoints >= 50;
          if (state.useLoyaltyPoints && canRedeem) {
            double maxDiscount = basePrice * 0.5;
            pointsDiscount = state.availableLoyaltyPoints > maxDiscount 
                ? maxDiscount 
                : state.availableLoyaltyPoints.toDouble();
          }
        }
        // Wallet Balance Logic
        double walletDiscount = 0.0;
        if (FeatureConfig.isWalletEnabled && state.useWallet && state.walletBalance > 0) {
          double remainingAfterLoyalty = basePrice - pointsDiscount;
          walletDiscount = state.walletBalance > remainingAfterLoyalty 
              ? remainingAfterLoyalty 
              : state.walletBalance;
        }

        final double grandTotal = (basePrice - pointsDiscount - walletDiscount) + platformFee;

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios, color: colorScheme.onSurface),
              onPressed: () => Navigator.pop(context),
            ),
            title: AppText(
              text: "Booking Summary",
              textStyle: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ground Details Card
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Carousel Header
                        Stack(
                          children: [
                            GroundImageCarousel(
                              images: ground.images,
                              fallbackImageUrl: ground.imageUrl,
                              height: 180,
                              borderRadius: BorderRadius.zero,
                            ),
                            Positioned(
                              bottom: 12,
                              left: 14,
                              right: 14,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        const Icon(Icons.calendar_today_rounded, size: 14, color: Colors.white),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: AppText(
                                            text: "${activeDate.month} ${activeDate.date}, ${DateTime.now().year}",
                                            textStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                            maxLines: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.accentOrange,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: AppText(
                                      text: "${selectedSlots.length} Slots",
                                      textStyle: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        // Info Section
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        AppText(
                                          text: ground.name,
                                          textStyle: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: colorScheme.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            _buildBadge(
                                              text: selectedSport.toUpperCase(),
                                              color: AppColors.primaryDarkGreen,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  AppText(
                                    text: "₹${basePrice.toStringAsFixed(0)}",
                                    textStyle: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primaryDarkGreen,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2.0),
                                    child: HugeIcon(
                                      icon: HugeIcons.strokeRoundedLocation01,
                                      size: 14,
                                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: AppText(
                                      text: ground.address.isNotEmpty ? ground.address : (ground.city.isNotEmpty ? ground.city : 'Location unavailable'),
                                      textStyle: TextStyle(
                                        fontSize: 12,
                                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (ground.amenities.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                AppText(
                                  text: "AMENITIES",
                                  textStyle: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                    color: colorScheme.onSurface.withValues(alpha: 0.4),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: ground.amenities.take(4).map((amenity) {
                                    return SlotSelectionWidgets.amenityChip(context, amenity);
                                  }).toList(),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const AppSizedBox(height: 24),

                // Selected Slots chips
                AppText(
                  text: "Selected Slots",
                  textStyle: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const AppSizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: selectedSlots.map((slot) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryDarkGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primaryDarkGreen.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.access_time_rounded, size: 14, color: AppColors.primaryDarkGreen),
                          const AppSizedBox(width: 6),
                          AppText(
                            text: "${slot.startTime} - ${slot.endTime}",
                            textStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryDarkGreen,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const AppSizedBox(height: 28),

                // Loyalty Points Section
                if (FeatureConfig.isLoyaltyEnabled) ...[
                  AppText(
                    text: "Loyalty Rewards",
                    textStyle: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const AppSizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: state.useLoyaltyPoints 
                          ? AppColors.primaryDarkGreen 
                          : colorScheme.outline.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.goldenYellow.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.stars_rounded, color: AppColors.goldenYellow, size: 28),
                        ),
                        const AppSizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppText(
                                text: "Redeem Points",
                                textStyle: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              AppText(
                                text: state.availableLoyaltyPoints >= 50 
                                  ? "Use ${state.availableLoyaltyPoints} pts for ₹${pointsDiscount.toStringAsFixed(0)} off"
                                  : "Min. 50 points required",
                                textStyle: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: state.useLoyaltyPoints,
                          activeColor: AppColors.primaryDarkGreen,
                          onChanged: state.availableLoyaltyPoints >= 50 
                            ? (_) => context.read<SlotSelectionCubit>().toggleLoyaltyPoints() 
                            : null,
                        ),
                      ],
                    ),
                  ),
                  const AppSizedBox(height: 32),
                ],

                // Wallet Section
                if (FeatureConfig.isWalletEnabled) ...[
                  AppText(
                    text: "Wallet Balance",
                    textStyle: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const AppSizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: state.useWallet 
                          ? AppColors.primaryDarkGreen 
                          : colorScheme.outline.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.blue, size: 28),
                        ),
                        const AppSizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppText(
                                text: "Use Wallet Balance",
                                textStyle: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              AppText(
                                text: state.walletBalance > 0 
                                  ? "Available: ₹${state.walletBalance.toStringAsFixed(0)}"
                                  : "No balance available",
                                textStyle: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: state.useWallet,
                          activeColor: AppColors.primaryDarkGreen,
                          onChanged: state.walletBalance > 0 
                            ? (_) => context.read<SlotSelectionCubit>().toggleWallet() 
                            : null,
                        ),
                      ],
                    ),
                  ),
                  const AppSizedBox(height: 32),
                ],

                // Bill Details
                AppText(
                  text: "Bill Details",
                  textStyle: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const AppSizedBox(height: 16),
                _priceRow(context, label: "Base Amount", amount: basePrice),
                const AppSizedBox(height: 12),
                if (pointsDiscount > 0) ...[
                  _priceRow(context, label: "Loyalty Discount", amount: -pointsDiscount, isDiscount: true),
                  const AppSizedBox(height: 12),
                ],
                if (walletDiscount > 0) ...[
                  _priceRow(context, label: "Wallet Used", amount: -walletDiscount, isDiscount: true, isWallet: true),
                  const AppSizedBox(height: 12),
                ],
                _priceRow(context, label: "Platform Fee", amount: platformFee),
                const AppSizedBox(height: 12),
                _priceRow(context, label: "Taxes & Charges", amount: 0),
                const AppSizedBox(height: 20),
                const Divider(),
                const AppSizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppText(
                      text: "Grand Total",
                      textStyle: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    AppText(
                      text: "₹${grandTotal.toStringAsFixed(0)}",
                      textStyle: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppColors.accentOrange,
                      ),
                    ),
                  ],
                ),
                const AppSizedBox(height: 40),

                AppButton(
                  title: "Confirm & Proceed to Pay",
                  onTap: () {
                    // Pop this screen and return the final amount and points to the caller
                    Navigator.pop(context, {
                      'finalAmount': grandTotal,
                      'appliedPoints': state.useLoyaltyPoints ? pointsDiscount.toInt() : 0,
                      'appliedWallet': state.useWallet ? walletDiscount : 0.0,
                    });
                  },
                ),
                const AppSizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBadge({required String text, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: AppText(
        text: text,
        textStyle: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _priceRow(BuildContext context, {required String label, required double amount, bool isDiscount = false, bool isFree = false, bool isWallet = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppText(
          text: label,
          textStyle: TextStyle(
            fontSize: 14,
            color: colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        AppText(
          text: isFree ? "FREE" : "${isDiscount ? '- ' : ''}₹${amount.abs().toStringAsFixed(2)}",
          textStyle: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: isFree 
              ? Colors.green 
              : (isDiscount 
                  ? (isWallet ? Colors.blue : AppColors.primaryDarkGreen) 
                  : colorScheme.onSurface),
          ),
        ),
      ],
    );
  }
}
```



### lib\user_booking\presentation\screens\booking_confirmation\booking_confirmation_screen.dart
```dart
// Add for kIsWeb
import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:turfpro/common/constants/colors.dart';
import 'package:turfpro/user_booking/constants/text_theme.dart';
import 'package:turfpro/user_booking/constants/widgets/app_sizedBox.dart';
import 'package:turfpro/user_booking/constants/widgets/app_text.dart';
import 'package:turfpro/user_booking/domain/models/booking_arguments.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
// Already here, good for Web sharing
import 'package:turfpro/utils/toast_util.dart';
// Add our new helper
import 'package:turfpro/utils/ticket_util.dart'; // Add TicketUtil
import 'package:qr_flutter/qr_flutter.dart';
import 'package:turfpro/utils/id_util.dart';
import '../../widgets/ground_image_carousel.dart';
import '../../widgets/slot_selection_widgets.dart';

class BookingConfirmationScreen extends StatefulWidget {
  const BookingConfirmationScreen({super.key});

  @override
  State<BookingConfirmationScreen> createState() =>
      _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen> {
  bool _isSaving = false;

  Future<void> _captureAndSave(
    String groundName,
    String groundAddress,
    String groundImageUrl,
    DateTime date,
    String timeRange,
    String orderId,
    int displayId,
    double totalPrice,
    String sportName,
    String selectedPeriod,
    String groundId,
    String ownerId,
    List<String>? amenities,
  ) async {
    await TicketUtil.downloadTicket(
      context,
      groundName: groundName,
      groundAddress: groundAddress,
      groundImageUrl: groundImageUrl,
      date: date,
      timeRange: timeRange,
      orderId: orderId,
      displayId: displayId,
      totalPrice: totalPrice,
      sportName: sportName,
      selectedPeriod: selectedPeriod,
      groundId: groundId,
      ownerId: ownerId,
      amenities: amenities,
      onLoadingStarted: () => setState(() => _isSaving = true),
      onLoadingFinished: () {
        if (mounted) setState(() => _isSaving = false);
      },
    );
  }

  DateTime _parseSlotTime(DateTime baseDate, String timeStr) {
    // Expected format: "09:00 AM" or "09:00 PM"
    try {
      final parts = timeStr.trim().split(' ');
      if (parts.length < 2) {
        // Fallback for formats without AM/PM
        final timeParts = timeStr.split(':');
        return DateTime(
          baseDate.year,
          baseDate.month,
          baseDate.day,
          int.parse(timeParts[0]),
          int.parse(timeParts[1]),
        );
      }

      final timeParts = parts[0].split(':');
      int hour = int.parse(timeParts[0]);
      int minute = int.parse(timeParts[1]);
      final amPm = parts[1].toUpperCase();

      if (amPm == 'PM' && hour < 12) hour += 12;
      if (amPm == 'AM' && hour == 12) hour = 0;

      return DateTime(baseDate.year, baseDate.month, baseDate.day, hour, minute);
    } catch (e) {
      debugPrint("Error parsing slot time '$timeStr': $e");
      return baseDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final rawArgs = ModalRoute.of(context)?.settings.arguments;

    if (rawArgs == null || rawArgs is! BookingSuccessArguments) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const AppSizedBox(height: 16),
              const AppText(text: "Booking information missing"),
              TextButton(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                    context, '/nav', (r) => false),
                child: const Text("Go to Home"),
              )
            ],
          ),
        ),
      );
    }

    final args = rawArgs;
    final ground = args.ground;
    final date = args.date;
    final slots = args.selectedSlots;
    final orderId = args.orderId;
    final displayId = args.displayId;
    final totalPrice = args.totalPrice;

    final timeRange = slots.isEmpty
        ? "No slots selected"
        : slots.map((s) => "${s.startTime} - ${s.endTime}").join(", ");

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: AppText(
          text: "Booking Status",
          textStyle: AppTextTheme.black16.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const AppSizedBox(height: 12),

              /// SUCCESS ICON
              AppSizedBox(
                height: 140,
                width: 140,
                child: Lottie.asset(
                  'assets/animations/Success.json',
                  repeat: false,
                ),
              ),

              const AppSizedBox(height: 8),

              /// TITLE
              AppText(
                text: "Slot Booked\nSuccessfully!",
                align: TextAlign.center,
                textStyle: AppTextTheme.black18.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  color: colorScheme.onSurface,
                ),
              ),

              const AppSizedBox(height: 12),

              /// SUBTITLE
              AppText(
                text:
                    "Get ready to hit some sixes! Your pitch is ready for action.",
                align: TextAlign.center,
                textStyle: AppTextTheme.grey13.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                  height: 1.5,
                  fontSize: 14,
                ),
              ),

              const AppSizedBox(height: 32),

              _VenueCard(ground: ground),
              const AppSizedBox(height: 20),
              _BookingDetailsCard(
                date: date,
                timeRange: timeRange,
                orderId: orderId,
                displayId: displayId,
                totalPrice: totalPrice,
                groundAddress: ground.address.isNotEmpty ? ground.address : (ground.city.isNotEmpty ? ground.city : 'Location unavailable'),
                sportName: args.sportName,
                period: args.selectedPeriod,
              ),

              const AppSizedBox(height: 20),
              _QRCodeCard(
                qrData: "$orderId | Ground: ${ground.name} | Owner: ${ground.ownerId} | Ground ID: ${ground.id}",
                displayId: displayId,
              ),

              const AppSizedBox(height: 24),
              SlotSelectionWidgets.buildMapSection(
                context,
                latitude: ground.latitude,
                longitude: ground.longitude,
                address: ground.address.isNotEmpty ? ground.address : (ground.city.isNotEmpty ? ground.city : 'Location unavailable'),
              ),

              const AppSizedBox(height: 32),

              /// DOWNLOAD TICKET
              ElevatedButton.icon(
                onPressed: _isSaving
                    ? null
                    : () => _captureAndSave(
                          ground.name,
                          ground.address.isNotEmpty ? ground.address : (ground.city.isNotEmpty ? ground.city : 'Location unavailable'),
                          ground.imageUrl,
                          date,
                          timeRange,
                          orderId,
                          displayId,
                          totalPrice,
                          args.sportName,
                          args.selectedPeriod,
                          ground.id,
                          ground.ownerId,
                          ground.amenities,
                        ),
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.download_rounded, color: Colors.white),
                label: AppText(
                  text: _isSaving ? "Generating PDF..." : "Download Ticket",
                  textStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDarkGreen,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),

              const AppSizedBox(height: 16),

              /// ADD TO CALENDAR
              OutlinedButton.icon(
                onPressed: () {
                  try {
                    DateTime eventStart = DateTime(
                        date.year, date.month, date.day, 9, 0); // Default 9 AM
                    DateTime eventEnd = DateTime(date.year, date.month,
                        date.day, 10, 0); // Default 10 AM

                    if (slots.isNotEmpty) {
                      eventStart = _parseSlotTime(date, slots.first.startTime);
                      eventEnd = _parseSlotTime(date, slots.last.endTime);

                      // Safety check: if start is after end (e.g. overnight), add a day to end
                      if (eventEnd.isBefore(eventStart)) {
                        eventEnd = eventEnd.add(const Duration(days: 1));
                      }
                    }

                    final Event event = Event(
                      title: 'Cricket Booking @ ${ground.name}',
                      description:
                          'Your turf booking is confirmed.\nOrder ID: #${IdUtil.formatDisplayId(displayId)}\nVenue: ${ground.name}\nAddress: ${ground.address.isNotEmpty ? ground.address : (ground.city.isNotEmpty ? ground.city : 'Location unavailable')}',
                      location: ground.address.isNotEmpty ? ground.address : (ground.city.isNotEmpty ? ground.city : 'Location unavailable'),
                      startDate: eventStart,
                      endDate: eventEnd,
                    );

                    Add2Calendar.addEvent2Cal(event).then((success) {
                      if (!success) {
                        ToastUtil.show(context,
                            message:
                                "Could not open calendar. Do you have a calendar app installed?",
                            type: ToastType.error);
                      }
                    });
                  } catch (e) {
                    debugPrint("Calendar Error: $e");
                    ToastUtil.show(context,
                        message:
                            "Failed to create calendar event. Please check formatting.",
                        type: ToastType.error);
                  }
                },
                icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedCalendar01,
                    color: Colors.blueAccent,
                    size: 20),
                label: const AppText(
                  text: "Add to Calendar",
                  textStyle: TextStyle(
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.blueAccent, width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),

              const AppSizedBox(height: 16),

              /// BACK TO HOME
              TextButton(
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/nav',
                      (route) => false,
                    );
                  }
                },
                child: AppText(
                  text: "Back to Home",
                  textStyle: AppTextTheme.black13.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),

              const AppSizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _VenueCard extends StatelessWidget {
  final dynamic ground;
  const _VenueCard({required this.ground});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
                alpha: theme.brightness == Brightness.dark ? 0.3 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Stack(
              children: [
                GroundImageCarousel(
                  images: ground.images ?? [],
                  fallbackImageUrl: ground.imageUrl ?? "",
                  height: 180,
                  borderRadius: BorderRadius.zero,
                ),
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       AppText(
                        text: ground.name ?? "PowerPlay Arena",
                        textStyle: AppTextTheme.white15.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (ground.amenities != null && ground.amenities.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 12,
                runSpacing: 8,
                children: (ground.amenities as List<dynamic>).map<Widget>((amenity) {
                  return _buildAmenity(amenity.toString());
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAmenity(String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        HugeIcon(
          icon: SlotSelectionWidgets.getAmenityHugeIcon(label),
          size: 14,
          color: AppColors.primaryDarkGreen,
        ),
        const AppSizedBox(width: 6),
        AppText(
          text: label,
          textStyle: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}

class _BookingDetailsCard extends StatelessWidget {
  final DateTime date;
  final String timeRange;
  final String orderId;
  final int displayId;
  final double totalPrice;
  final String sportName;
  final String groundAddress;
  final String period;

  const _BookingDetailsCard({
    required this.date,
    required this.timeRange,
    required this.orderId,
    required this.displayId,
    required this.totalPrice,
    required this.groundAddress,
    required this.sportName,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          _buildDetailRow(
            context,
            "Venue Address",
            groundAddress,
            Icons.location_on_outlined,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          _buildDetailRow(
            context,
            "Sport",
            sportName,
            Icons.sports_cricket_outlined,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          _buildDetailRow(
            context,
            "Date",
            DateFormat('EEEE, d MMMM yyyy').format(date),
            Icons.calendar_today_outlined,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          _buildDetailRow(
            context,
            "Time Slot",
            timeRange,
            Icons.access_time_rounded,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          _buildDetailRow(
            context,
            "Booking ID",
            "#${IdUtil.formatDisplayId(displayId)}",
            Icons.confirmation_number_outlined,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText(
                text: "Total Amount",
                textStyle: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              AppText(
                text: "₹${totalPrice.toStringAsFixed(0)}",
                textStyle: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryDarkGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildDetailRow(
      BuildContext context, String label, String value, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryDarkGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColors.primaryDarkGreen),
        ),
        const AppSizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(
              text: label,
              textStyle: AppTextTheme.grey11.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
            const AppSizedBox(height: 2),
            AppText(
              text: value,
              textStyle: AppTextTheme.black13.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QRCodeCard extends StatelessWidget {
  final String qrData;
  final int displayId;
  const _QRCodeCard({required this.qrData, required this.displayId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          const AppText(
            text: "Entry QR Code",
            textStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const AppSizedBox(height: 4),
          AppText(
            text: "Show this at the venue for verification",
            textStyle: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const AppSizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: QrImageView(
              data: qrData,
              version: QrVersions.auto,
              size: 160.0,
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
            ),
          ),
          const AppSizedBox(height: 16),
          AppText(
            text: "#${IdUtil.formatDisplayId(displayId)}",
            textStyle: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              color: AppColors.primaryDarkGreen,
            ),
          ),
        ],
      ),
    );
  }
}

```



