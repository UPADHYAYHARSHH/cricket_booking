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
import 'package:turfpro/user_booking/presentation/blocs/slot_selection/slot_selection_cubit.dart';
import 'package:turfpro/user_booking/domain/models/booking_arguments.dart';
import 'package:turfpro/user_booking/presentation/blocs/slot_selection/slot_selection_state.dart';
import 'package:turfpro/user_booking/domain/repositories/review_repository.dart';
import 'package:turfpro/user_booking/data/models/review_model.dart';
import 'package:turfpro/user_booking/domain/repositories/loyalty_repository.dart';
import 'package:turfpro/user_booking/domain/repositories/wallet_repository.dart';
import 'package:turfpro/common/config/feature_config.dart';
import 'package:share_plus/share_plus.dart';

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

  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _razorpay.clear();
    _scrollController.dispose();
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

  void _onConfirmBooking(
      double totalPrice, dynamic activeDate, List<TimeSlot> selectedSlots,
      {int appliedPoints = 0, double appliedWallet = 0.0, bool fromRetry = false}) async {
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

      // Deduct from wallet if used
      if (FeatureConfig.isWalletEnabled && appliedWallet > 0) {
        final walletRepo = getIt<WalletRepository>();
        final currentBalance = await walletRepo.getBalance();
        await walletRepo.updateBalance(currentBalance - appliedWallet);
        await walletRepo.addTransaction(
          amount: appliedWallet,
          type: 'debit',
          description: 'Used for booking @ ${_ground!.name}',
        );
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
      if (hour < 6) return 'Midnight';
      if (hour < 12) return 'Morning';
      if (hour < 18) return 'Evening';
      return 'Night';
    } catch (_) {
      return 'Morning';
    }
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
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
          text: "Changing sport or ground will clear your currently selected slots. Do you want to proceed?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const AppText(text: "Cancel", textStyle: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const AppText(text: "Clear & Proceed", textStyle: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ) ?? false;
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
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: BlocBuilder<SlotSelectionCubit, SlotSelectionState>(
        builder: (context, state) {
          final cubit = context.read<SlotSelectionCubit>();
          final selectedSlots = state.slots.where((s) => s.status == SlotStatus.selected).toList();
          final totalPrice = selectedSlots.fold<double>(0, (sum, s) => sum + s.price);
          final activeDate = state.dates.isNotEmpty ? state.dates.firstWhere((d) => d.isSelected, orElse: () => state.dates.first) : null;

          return Column(
            children: [
              // Fixed Header
              SlotSelectionWidgets.buildHeader(
                  context, state.selectedTurf ?? _ground,
                  title: state.selectedTurf?.name ?? "Book Slots",
                  onShare: _shareGround),

              // Fixed Sport Selection
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
                  _scrollToTop();
                },
              ),

              // Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      // Ground Selection (Now Scrollable)
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

                      if (state.selectedTurf == null)
                        _buildEmptyState(context, state)
                      else
                        _buildSlotSelectionContent(context, state, cubit),
                    ],
                  ),
                ),
              ),

              // Fixed Bottom Bar
              if (activeDate != null)
                SlotSelectionWidgets.buildBottomBar(
                  context, selectedSlots, activeDate, totalPrice, () async {
                    if (state.selectedTurf == null) return;
                    final result = await Navigator.pushNamed(
                        context, AppRoutes.bookingSummary,
                        arguments: state.selectedTurf);
                    if (result != null && result is Map<String, dynamic>) {
                      _onConfirmBooking(result['finalAmount'], activeDate, selectedSlots,
                          appliedPoints: result['appliedPoints'],
                          appliedWallet: result['appliedWallet'] ?? 0.0);
                    }
                  }
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, SlotSelectionState state) {
    return Container(
      height: 300, // Fixed height to show in the scrollable view
      alignment: Alignment.center,
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
            textStyle: TextStyle(color: Colors.grey.withValues(alpha: 0.7), fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotSelectionContent(BuildContext context, SlotSelectionState state,
      SlotSelectionCubit cubit) {
    final currentTurf = state.selectedTurf!;
    
    return Column(
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

            if (filtered.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.05)),
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
          const AppSizedBox(height: 20),
        ],
        SlotSelectionWidgets.buildDescriptionSection(
            context, currentTurf.description),
        SlotSelectionWidgets.buildAmenitiesSection(
            context, currentTurf.amenities),
        SlotSelectionWidgets.buildMapSection(
          context,
          latitude: currentTurf.latitude,
          longitude: currentTurf.longitude,
          address: currentTurf.address,
        ),
        SlotSelectionWidgets.buildReviewSection(
            context, _reviews, _isLoadingReviews),
      ],
    );
  }
}
