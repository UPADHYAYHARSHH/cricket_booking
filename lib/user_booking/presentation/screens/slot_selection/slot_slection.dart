import 'package:bloc_structure/common/constants/colors.dart';
import 'package:bloc_structure/user_booking/constants/widgets/app_sizedBox.dart';
import 'package:bloc_structure/user_booking/constants/widgets/app_text.dart';
import 'package:bloc_structure/user_booking/data/repositories/payment_repository.dart';
import 'package:bloc_structure/user_booking/domain/models/slot_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bloc_structure/user_booking/presentation/blocs/saved_ground/saved_ground_cubit.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../di/get_it/get_it.dart';
import '../../../constants/route_constants.dart';
import '../../widgets/slot_selection_widgets.dart';
import '../../../data/models/ground_model.dart';
import '../../blocs/slot_selection/slot_selection_cubit.dart';
import 'package:bloc_structure/user_booking/domain/models/booking_arguments.dart';
import '../../blocs/slot_selection/slot_selection_state.dart';

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
            errorMessage: "Payment verification failed. Please contact support.",
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
    if (_pendingAmount == null || _pendingDate == null || _pendingSlots == null) return;
    _onConfirmBooking(_pendingAmount!, null, _pendingSlots!, fromRetry: true);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint('--- RAZORPAY PAYMENT FAILED ---');
    debugPrint('Error Code: ${response.code}');
    debugPrint('Error Message: ${response.message}');

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
        // Initial load for today
        context.read<SlotSelectionCubit>().loadSlots(
              _ground!.id,
              DateTime.now(),
              openingTime: _ground!.openingTime,
              closingTime: _ground!.closingTime,
              pricePerSlot: _ground!.pricePerHour.toDouble(),
            );
      }
      _isInitialized = true;
    }
  }

  void _onConfirmBooking(double totalPrice, dynamic activeDate,
      List<TimeSlot> selectedSlots, {bool fromRetry = false}) async {
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
      debugPrint('Calling create-order Edge Function...');
      final orderData = await _paymentRepo.createOrder(totalPrice.toInt());
      debugPrint('Order Data Received: $orderData');
      
      final orderId = orderData['id'];

      _pendingAmount = totalPrice;
      _pendingSlots = selectedSlots;

      if (!fromRetry) {
        final now = DateTime.now();
        _pendingDate = DateTime(now.year, now.month, activeDate.date);
        if (_pendingDate!.isBefore(DateTime(now.year, now.month, now.day))) {
          _pendingDate = DateTime(now.year, now.month + 1, activeDate.date);
        }
      }
      debugPrint('Pending Date: $_pendingDate');

      if (!mounted) return;
      Navigator.pop(context);

      var options = {
        'key': 'rzp_test_SZQGlX68eXuGzw',
        'amount': totalPrice * 100,
        'name': 'TurfPro Booking',
        'description': '${_ground!.name} - ${selectedSlots.length} slot(s)',
        'order_id': orderId,
        'prefill': {'contact': '9999999999', 'email': 'test@test.com'},
        'external': {
          'wallets': ['paytm']
        }
      };

      debugPrint('Opening Razorpay Modal for Order ID: $orderId');
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Confirmation Flow Error: $e');
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Booking Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  String _getSlotPeriod(String time) {
    try {
      // time is in format "HH:MM AM/PM"
      final parts = time.split(' ');
      final hm = parts[0].split(':');
      var hour = int.parse(hm[0]);
      final ampm = parts[1].toUpperCase();

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
      body: BlocBuilder<SlotSelectionCubit, SlotSelectionState>(
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
                final isSaved = _ground != null &&
                    state.favoriteIds.contains(_ground!.id);
                return SlotSelectionWidgets.buildHeader(
                  context,
                  _ground,
                  isSaved: isSaved,
                  onToggleFav: () {
                    final user =
                        Supabase.instance.client.auth.currentUser;
                    if (user != null && _ground != null) {
                      context
                          .read<SavedGroundCubit>()
                          .toggleFavorite(user.id, _ground!.id);
                    } else if (user == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: AppText(
                                text: "Please login to save grounds")),
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
                      SlotSelectionWidgets.buildTurfImage(_ground),
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
                        (p) => context.read<SlotSelectionCubit>().changePeriod(p),
                      ),
                      if (state.isLoading)
                        const Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Center(
                              child: CircularProgressIndicator(
                                  color: AppColors.accentOrange)),
                        )
                      else if (state.errorMessage != null)
                        Center(
                            child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: AppText(text: state.errorMessage!),
                        ))
                      else ...[
                        SlotSelectionWidgets.buildLegend(context),
                        Builder(builder: (context) {
                          // Filter slots based on period
                          final filteredWithOriginalIndex = state.slots
                              .asMap()
                              .entries
                              .where((entry) {
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
                            final originalIndex = filteredWithOriginalIndex[indexInFiltered].key;
                            context.read<SlotSelectionCubit>().toggleSlot(originalIndex);
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
                    ],
                  ),
                ),
              ),
              SlotSelectionWidgets.buildBottomBar(
                context,
                selectedSlots,
                activeDate,
                totalPrice,
                () => _onConfirmBooking(totalPrice, activeDate, selectedSlots),
              ),
            ],
          );
        },
      ),
    );
  }
}
