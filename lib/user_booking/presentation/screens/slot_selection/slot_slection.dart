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
                        SlotSelectionWidgets.buildAmenitiesSection(context, displayVenue?.amenities),
                        SlotSelectionWidgets.buildDescriptionSection(context, displayVenue?.description),

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
