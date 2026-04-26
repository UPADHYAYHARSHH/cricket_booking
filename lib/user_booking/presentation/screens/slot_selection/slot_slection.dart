import 'package:turfpro/common/constants/colors.dart';
import 'package:turfpro/user_booking/presentation/blocs/connectivity/connectivity_cubit.dart';
import 'package:turfpro/user_booking/constants/widgets/app_sizedBox.dart';
import 'package:turfpro/user_booking/constants/widgets/app_text.dart';
import 'package:turfpro/user_booking/data/repositories/payment_repository.dart';
import 'package:turfpro/user_booking/domain/models/slot_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:turfpro/user_booking/presentation/blocs/saved_ground/saved_ground_cubit.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:turfpro/user_booking/di/get_it/get_it.dart';
import 'package:turfpro/user_booking/constants/route_constants.dart';
import 'package:turfpro/user_booking/presentation/widgets/slot_selection_widgets.dart';
import 'package:turfpro/user_booking/data/models/ground_model.dart';
import 'package:turfpro/user_booking/presentation/blocs/slot_selection/slot_selection_cubit.dart';
import 'package:turfpro/user_booking/domain/models/booking_arguments.dart';
import 'package:turfpro/user_booking/data/services/analytics_service.dart';
import 'package:turfpro/user_booking/presentation/blocs/slot_selection/slot_selection_state.dart';
import 'package:turfpro/user_booking/domain/repositories/review_repository.dart';
import 'package:turfpro/user_booking/data/models/review_model.dart';
import 'package:turfpro/user_booking/domain/repositories/loyalty_repository.dart';

class SlotSelectionScreen extends StatefulWidget {
  const SlotSelectionScreen({super.key});

  @override
  State<SlotSelectionScreen> createState() => _SlotSelectionScreenState();
}

class _SlotSelectionScreenState extends State<SlotSelectionScreen> {
  GroundModel? _ground;
  bool _isInitialized = false;
  late Razorpay _razorpay;
  final _paymentRepo = getIt<PaymentRepository>();
  final _loyaltyRepo = getIt<LoyaltyRepository>();
  List<ReviewModel> _reviews = [];
  bool _isLoadingReviews = true;

  // Store these to use in success handler
  double? _pendingAmount;
  List<TimeSlot>? _pendingSlots;
  DateTime? _pendingDate;

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
    debugPrint('--- RAZORPAY PAYMENT SUCCESS ---');
    debugPrint('Payment ID: ${response.paymentId}');
    debugPrint('Order ID: ${response.orderId}');
    debugPrint('Signature: ${response.signature}');

    // Show persistent loading overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppColors.primaryDarkGreen),
                AppSizedBox(height: 16),
                AppText(text: "Verifying your booking..."),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      debugPrint('Calling verifyPayment Edge Function...');
      final isValid = await _paymentRepo.verifyPayment(
        orderId: response.orderId!,
        paymentId: response.paymentId!,
        signature: response.signature!,
      );
      debugPrint('Verification Result: $isValid');

      if (isValid && _ground != null && _pendingDate != null) {
        debugPrint('Saving booking to database...');
        // Save to DB
        await _paymentRepo.saveBooking(
          groundId: _ground!.id,
          slotTime: _pendingDate!,
          amount: (_pendingAmount! * 100).toInt(),
          orderId: response.orderId!,
          paymentId: response.paymentId!,
          signature: response.signature!,
        );
        debugPrint('Booking saved successfully!');

        if (!mounted) return;
        Navigator.pop(context); // Pop loading dialog

        // Log successful booking
        getIt<AnalyticsService>().logBookingSuccess(
          bookingId: response.orderId!,
          amount: _pendingAmount!,
          groundName: _ground!.name,
        );

        Navigator.pushReplacementNamed(
          context,
          AppRoutes.bookingConfirmationScreen,
          arguments: BookingSuccessArguments(
            ground: _ground!,
            date: _pendingDate!,
            selectedSlots: _pendingSlots ?? [],
            orderId: response.orderId!,
            totalPrice: _pendingAmount!,
          ),
        );
      } else {
        debugPrint('Invalid verification or missing internal state');
        if (!mounted) return;
        Navigator.pop(context); // Pop loading dialog

        Navigator.pushNamed(
          context,
          AppRoutes.paymentFailedScreen,
          arguments: BookingFailureArguments(
            errorMessage:
                "Payment verification failed. Please contact support.",
            onRetry: () => _retryPayment(),
          ),
        );
      }
    } catch (e) {
      debugPrint('Verification Handler Error: $e');
      if (!mounted) return;
      Navigator.pop(context); // Pop loading dialog

      Navigator.pushNamed(
        context,
        AppRoutes.paymentFailedScreen,
        arguments: BookingFailureArguments(
          errorMessage: "Error saving your booking: $e",
          onRetry: () => _retryPayment(),
        ),
      );
    }
  }

  void _retryPayment() {
    if (_pendingAmount == null || _pendingDate == null || _pendingSlots == null) {
      return;
    }
    _onConfirmBooking(_pendingAmount!, null, _pendingSlots!, fromRetry: true);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint('--- RAZORPAY PAYMENT FAILED ---');
    debugPrint('Error Code: ${response.code}');
    debugPrint('Error Message: ${response.message}');

    // Log payment failure
    getIt<AnalyticsService>().logBookingFailure(
      error: response.message ?? "Payment was cancelled or failed",
    );

    Navigator.pushNamed(
      context,
      AppRoutes.paymentFailedScreen,
      arguments: BookingFailureArguments(
        errorMessage: response.message ?? "Payment was cancelled or failed.",
        onRetry: () => _retryPayment(),
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('External Wallet: ${response.walletName}')),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is GroundModel) {
        _ground = args;
        // Log ground view
        getIt<AnalyticsService>().logGroundView(
          groundId: _ground!.id,
          groundName: _ground!.name,
        );
        // Initial load for today
        context.read<SlotSelectionCubit>().loadSlots(
              _ground!.id,
              DateTime.now(),
              openingTime: _ground!.openingTime,
              closingTime: _ground!.closingTime,
              pricePerSlot: _ground!.pricePerHour.toDouble(),
            );
        _loadReviews();
      }
      _isInitialized = true;
    }
  }

  Future<void> _loadReviews() async {
    if (_ground == null) return;
    try {
      final reviews = await getIt<ReviewRepository>().fetchGroundReviews(_ground!.id);
      if (mounted) {
        setState(() {
          _reviews = reviews;
          _isLoadingReviews = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingReviews = false);
    }
  }

  void _onConfirmBooking(double totalPrice, dynamic activeDate,
      List<TimeSlot> selectedSlots,
      {int appliedPoints = 0, bool fromRetry = false}) async {
    HapticFeedback.mediumImpact();
    debugPrint('--- USER TAPPED CONFIRM BOOKING ---');
    debugPrint('Total Price: $totalPrice');
    debugPrint('Slots Count: ${selectedSlots.length}');

    if (selectedSlots.isEmpty || _ground == null) {
      debugPrint('Error: No slots selected or ground missing');
      return;
    }

    // Show loading
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
      debugPrint('Step 1: Pending Date calculated - $_pendingDate');

      // 1. Save Direct Booking and Block Slots
      debugPrint('Step 2: Saving Direct Booking to Supabase...');
      await _paymentRepo.saveDirectBooking(
        groundId: _ground!.id,
        date: _pendingDate!,
        slotStartTimes: selectedSlots.map((s) => s.startTime).toList(),
        amount: totalPrice.toInt(),
      );
      debugPrint('Step 3: Supabase Booking & Slot updates completed');

      // 1.5 Handle Loyalty Points Redemption & Earning
      if (appliedPoints > 0) {
        debugPrint('Step 3.5: Redeeming $appliedPoints loyalty points...');
        await _loyaltyRepo.redeemPoints(appliedPoints);
      }
      
      // Earn 10 points per ₹100 spent (Rounding down)
      final pointsEarned = (totalPrice / 10).floor();
      if (pointsEarned > 0) {
        debugPrint('Step 3.6: Earning $pointsEarned loyalty points...');
        await _loyaltyRepo.earnPoints(pointsEarned);
      }

      // 2. Log successful booking (Wrapped in try-catch to avoid blocking UI)
      try {
        debugPrint('Step 4: Logging Analytics...');
        getIt<AnalyticsService>().logBookingSuccess(
          bookingId: 'DIRECT_${DateTime.now().millisecondsSinceEpoch}',
          amount: totalPrice,
          groundName: _ground!.name,
        );
        debugPrint('Step 5: Analytics logged');
      } catch (analyticsError) {
        debugPrint('Non-critical Error in Analytics: $analyticsError');
      }

      if (!mounted) return;
      debugPrint('Step 6: Closing loading dialog');
      Navigator.pop(context); // Pop loading dialog

      // 3. Navigate to Success Screen
      debugPrint('Step 7: Navigating to Success Screen...');
      final successArgs = BookingSuccessArguments(
        ground: _ground!,
        date: _pendingDate!,
        selectedSlots: selectedSlots,
        orderId: 'DIRECT_${DateTime.now().millisecondsSinceEpoch}',
        totalPrice: totalPrice,
      );

      Navigator.pushReplacementNamed(
        context,
        AppRoutes.bookingConfirmationScreen,
        arguments: successArgs,
      );
      debugPrint('Step 8: Navigation call completed');
    } catch (e) {
      debugPrint('CRITICAL ERROR in _onConfirmBooking: $e');
      if (!mounted) return;
      
      // Ensure dialog is closed even on error
      try { Navigator.pop(context); } catch (_) {}
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Booking Error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
      
      // Log failure (Now correctly inside the catch block)
      getIt<AnalyticsService>().logBookingFailure(error: e.toString());
    }
  }

  String _getSlotPeriod(String? time) {
    if (time == null || time.isEmpty) return 'Morning';
    try {
      final timeParts = time.split(' ');
      if (timeParts.isEmpty) return 'Morning';

      final timeH = timeParts[0].split(':');
      if (timeH.isEmpty) return 'Morning';

      int hour = int.parse(timeH[0]);
      final ampm = timeParts.length > 1 ? timeParts[1].toUpperCase() : 'AM';

      if (ampm == 'PM' && hour != 12) hour += 12;
      if (ampm == 'AM' && hour == 12) hour = 0;

      if (hour < 12) return 'Morning';
      if (hour < 18) return 'Evening';
      return 'Night';
    } catch (e) {
      return 'Morning';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: BlocListener<ConnectivityCubit, ConnectivityState>(
        listener: (context, connectivityState) async {
          if (connectivityState is ConnectivityConnected && _ground != null) {
            final slotCubit = context.read<SlotSelectionCubit>();
            
            // Automatically retry if there's an error when internet returns
            if (slotCubit.state.errorMessage != null) {
              debugPrint("[SLOT_SELECTION] Network restored, auto-retrying in 1.5s...");
              
              // Wait a bit for the network interface to be fully ready
              await Future.delayed(const Duration(milliseconds: 1500));
              
              if (mounted && context.read<ConnectivityCubit>().state is ConnectivityConnected) {
                slotCubit.loadSlots(
                  _ground!.id,
                  slotCubit.state.selectedDate ?? DateTime.now(),
                  openingTime: _ground!.openingTime,
                  closingTime: _ground!.closingTime,
                  pricePerSlot: _ground!.pricePerHour.toDouble(),
                );
              }
            }
          }
        },
        child: BlocBuilder<SlotSelectionCubit, SlotSelectionState>(
          builder: (context, state) {
          final selectedSlots = state.slots
              .where((s) => s.status == SlotStatus.selected)
              .toList();
          final totalPrice =
              selectedSlots.fold<double>(0, (sum, s) => sum + s.price);
          final activeDate = state.dates.firstWhere((d) => d.isSelected);

          return Column(
            children: [
              BlocBuilder<SavedGroundCubit, SavedGroundState>(
                  builder: (context, state) {
                final isSaved =
                    _ground != null && state.favoriteIds.contains(_ground!.id);
                return SlotSelectionWidgets.buildHeader(
                  context,
                  _ground,
                  isSaved: isSaved,
                  onToggleFav: () {
                    final user = Supabase.instance.client.auth.currentUser;
                    if (user != null && _ground != null) {
                      context
                          .read<SavedGroundCubit>()
                          .toggleFavorite(user.id, _ground!.id);
                    } else if (user == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                AppText(text: "Please login to save grounds")),
                      );
                    }
                  },
                );
              }),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Builder(builder: (context) {
                        final totalReviews = _isLoadingReviews
                            ? (_ground?.totalReviews ?? 0)
                            : _reviews.length;
                        final averageRating = _isLoadingReviews
                            ? (_ground?.rating ?? 0.0)
                            : (_reviews.isEmpty
                                ? 0.0
                                : _reviews.fold<double>(
                                        0, (sum, r) => sum + r.rating) /
                                    _reviews.length);

                        return SlotSelectionWidgets.buildTurfImage(
                          context,
                          _ground,
                          rating: averageRating,
                          totalReviews: totalReviews,
                        );
                      }),
                      SlotSelectionWidgets.buildDateSelector(
                          context, state.dates, (index) {
                        if (_ground != null) {
                          context.read<SlotSelectionCubit>().selectDate(
                                index,
                                _ground!.id,
                                openingTime: _ground!.openingTime,
                                closingTime: _ground!.closingTime,
                                pricePerSlot: _ground!.pricePerHour.toDouble(),
                              );
                        }
                      }),
                      SlotSelectionWidgets.buildPeriodFilter(
                        context,
                        state.selectedPeriod,
                        (p) =>
                            context.read<SlotSelectionCubit>().changePeriod(p),
                      ),
                      if (state.isLoading)
                        SlotSelectionWidgets.buildSlotShimmer(context)
                      else if (state.errorMessage != null)
                        Center(
                            child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            children: [
                              AppText(
                                text: state.errorMessage!,
                                textStyle: const TextStyle(color: Colors.red),
                                align: TextAlign.center,
                              ),
                              const AppSizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  if (_ground != null) {
                                    context.read<SlotSelectionCubit>().loadSlots(
                                          _ground!.id,
                                          state.selectedDate ?? DateTime.now(),
                                          openingTime: _ground!.openingTime,
                                          closingTime: _ground!.closingTime,
                                          pricePerSlot: _ground!.pricePerHour.toDouble(),
                                        );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryDarkGreen,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text("Retry"),
                              ),
                            ],
                          ),
                        ))
                      else ...[
                        // SlotSelectionWidgets.buildLegend(context),
                        Builder(builder: (context) {
                          // Filter slots based on period
                          final filteredWithOriginalIndex =
                              state.slots.asMap().entries.where((entry) {
                            final slot = entry.value;
                            final period = _getSlotPeriod(slot.startTime);
                            return period == state.selectedPeriod;
                          }).toList();

                          final filteredSlots = filteredWithOriginalIndex
                              .map((e) => e.value)
                              .toList();

                          return SlotSelectionWidgets.buildSlotSection(
                              context, filteredSlots, (indexInFiltered) {
                            // Find the original index to toggle correct slot
                            final originalIndex =
                                filteredWithOriginalIndex[indexInFiltered].key;
                            HapticFeedback.lightImpact();
                            context
                                .read<SlotSelectionCubit>()
                                .toggleSlot(originalIndex);
                          });
                        }),
                        const AppSizedBox(height: 20),
                      ],
                      SlotSelectionWidgets.buildDescriptionSection(
                          context, _ground?.description),
                      SlotSelectionWidgets.buildAmenitiesSection(
                          context, _ground?.amenities),
                      if (_ground != null)
                        SlotSelectionWidgets.buildMapSection(context, _ground!),
                      SlotSelectionWidgets.buildReviewSection(
                          context, _reviews, _isLoadingReviews),
                    ],
                  ),
                ),
              ),
              SlotSelectionWidgets.buildBottomBar(
                context,
                selectedSlots,
                activeDate,
                totalPrice,
                () {
                  final cubit = context.read<SlotSelectionCubit>();
                  SlotSelectionWidgets.showPriceBreakdown(
                    context: context,
                    ground: _ground,
                    selectedSlots: selectedSlots,
                    activeDate: activeDate,
                    totalPrice: totalPrice,
                    availablePoints: state.availableLoyaltyPoints,
                    useLoyaltyPoints: state.useLoyaltyPoints,
                    onTogglePoints: (val) => cubit.toggleLoyaltyPoints(),
                    onConfirm: (finalAmount, appliedPoints) {
                      _onConfirmBooking(finalAmount, activeDate, selectedSlots,
                          appliedPoints: appliedPoints);
                    },
                  );
                },
              ),
            ],
          );
        },
      ),
      ),
    );
  }
}
