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
import 'package:turfpro/common/config/feature_config.dart';

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

      if (isValid && _ground != null && _pendingDate != null) {
        final bookingData = await _paymentRepo.saveBooking(
          groundId: _ground!.id,
          slotTime: _pendingDate!,
          amount: (_pendingAmount! * 100).toInt(),
          orderId: response.orderId!,
          paymentId: response.paymentId!,
          signature: response.signature!,
        );

        final int displayId = bookingData['display_id'] ?? 0;
        if (!mounted) return;
        Navigator.pop(context);

        Navigator.pushReplacementNamed(
          context,
          AppRoutes.bookingConfirmationScreen,
          arguments: BookingSuccessArguments(
            ground: _ground!,
            date: _pendingDate!,
            selectedSlots: _pendingSlots ?? [],
            orderId: response.orderId!,
            displayId: displayId,
            totalPrice: _pendingAmount!,
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is GroundModel) {
        _ground = args;
        context.read<SlotSelectionCubit>().initFacility(_ground!);
        _loadReviews();
      }
      _isInitialized = true;
    }
  }

  Future<void> _loadReviews() async {
    if (_ground == null) return;
    try {
      final reviews =
          await getIt<ReviewRepository>().fetchGroundReviews(_ground!.id);
      if (mounted)
        setState(() {
          _reviews = reviews;
          _isLoadingReviews = false;
        });
    } catch (_) {
      if (mounted) setState(() => _isLoadingReviews = false);
    }
  }

  void _onConfirmBooking(
      double totalPrice, dynamic activeDate, List<TimeSlot> selectedSlots,
      {int appliedPoints = 0, bool fromRetry = false}) async {
    HapticFeedback.mediumImpact();
    if (selectedSlots.isEmpty || _ground == null) return;

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

      final bookingData = await _paymentRepo.saveDirectBooking(
        groundId: _ground!.id,
        date: _pendingDate!,
        slotStartTimes: selectedSlots.map((s) => s.startTime).toList(),
        amount: totalPrice.toInt(),
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
          ground: _ground!,
          date: _pendingDate!,
          selectedSlots: selectedSlots,
          orderId: 'DIRECT_${DateTime.now().millisecondsSinceEpoch}',
          displayId: displayId,
          totalPrice: totalPrice,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      try {
        Navigator.pop(context);
      } catch (_) {}
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Booking Error: $e'), backgroundColor: Colors.red));
    }
  }

  String _getSlotPeriod(String? time) {
    if (time == null || time.isEmpty) return 'Morning';
    try {
      final timeParts = time.split(' ');
      final timeH = timeParts[0].split(':');
      int hour = int.parse(timeH[0]);
      final ampm = timeParts.length > 1 ? timeParts[1].toUpperCase() : 'AM';
      if (ampm == 'PM' && hour != 12) hour += 12;
      if (ampm == 'AM' && hour == 12) hour = 0;
      if (hour < 12) return 'Morning';
      if (hour < 18) return 'Evening';
      return 'Night';
    } catch (_) {
      return 'Morning';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: BlocBuilder<SlotSelectionCubit, SlotSelectionState>(
        builder: (context, state) {
          final cubit = context.read<SlotSelectionCubit>();

          return Column(
            children: [
              SlotSelectionWidgets.buildHeader(
                  context, state.selectedTurf ?? _ground,
                  title: state.selectedTurf?.name ?? "Book Slots"),

              // Dropdowns Row
              SlotSelectionWidgets.buildSelectionDropdowns(
                context,
                state,
                onSportChanged: (sport) {
                  if (sport != null) cubit.selectSport(sport);
                },
                onTurfChanged: (turf) {
                  if (turf != null) cubit.selectTurf(turf);
                },
              ),

              Expanded(
                child: state.selectedTurf == null
                    ? _buildEmptyState(context, state)
                    : _buildSlotSelection(context, state, cubit),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, SlotSelectionState state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            state.selectedSport == null
                ? Icons.sports_tennis
                : Icons.location_on_outlined,
            size: 64,
            color: Colors.grey.withOpacity(0.3),
          ),
          const AppSizedBox(height: 16),
          AppText(
            text: state.selectedSport == null
                ? "Please select a sport first"
                : "Select a ground to see slots",
            textStyle:
                TextStyle(color: Colors.grey.withOpacity(0.7), fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotSelection(BuildContext context, SlotSelectionState state,
      SlotSelectionCubit cubit) {
    final currentTurf = state.selectedTurf!;
    final selectedSlots =
        state.slots.where((s) => s.status == SlotStatus.selected).toList();
    final totalPrice = selectedSlots.fold<double>(0, (sum, s) => sum + s.price);
    final activeDate = state.dates.firstWhere((d) => d.isSelected);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SlotSelectionWidgets.buildTurfImage(context, currentTurf,
                    rating: currentTurf.rating,
                    totalReviews: currentTurf.totalReviews),
                SlotSelectionWidgets.buildDateSelector(context, state.dates,
                    (index) {
                  cubit.selectDate(index, currentTurf.id,
                      openingTime: currentTurf.openingTime,
                      closingTime: currentTurf.closingTime,
                      pricePerSlot: currentTurf.pricePerHour.toDouble());
                }),
                SlotSelectionWidgets.buildPeriodFilter(context,
                    state.selectedPeriod, (p) => cubit.changePeriod(p)),
                if (state.isLoading)
                  SlotSelectionWidgets.buildSlotShimmer(context)
                else if (state.errorMessage != null)
                  Center(
                      child: AppText(
                          text: state.errorMessage!,
                          textStyle: const TextStyle(color: Colors.red)))
                else ...[
                  Builder(builder: (context) {
                    final filtered = state.slots
                        .asMap()
                        .entries
                        .where((e) =>
                            _getSlotPeriod(e.value.startTime) ==
                            state.selectedPeriod)
                        .toList();
                    return SlotSelectionWidgets.buildSlotSection(
                        context,
                        filtered.map((e) => e.value).toList(),
                        (i) => cubit.toggleSlot(filtered[i].key));
                  }),
                  const AppSizedBox(height: 20),
                ],
                SlotSelectionWidgets.buildDescriptionSection(
                    context, currentTurf.description),
                SlotSelectionWidgets.buildAmenitiesSection(
                    context, currentTurf.amenities),
                SlotSelectionWidgets.buildMapSection(context, currentTurf),
                SlotSelectionWidgets.buildReviewSection(
                    context, _reviews, _isLoadingReviews),
              ],
            ),
          ),
        ),
        SlotSelectionWidgets.buildBottomBar(
            context, selectedSlots, activeDate, totalPrice, () async {
          final result = await Navigator.pushNamed(
              context, AppRoutes.bookingSummary,
              arguments: currentTurf);
          if (result != null && result is Map<String, dynamic>) {
            _onConfirmBooking(result['finalAmount'], activeDate, selectedSlots,
                appliedPoints: result['appliedPoints']);
          }
        }),
      ],
    );
  }
}
