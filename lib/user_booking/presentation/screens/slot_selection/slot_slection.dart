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
import 'package:firebase_auth/firebase_auth.dart';
import 'package:turfpro/user_booking/presentation/blocs/saved_ground/saved_ground_cubit.dart';

class SlotSelectionScreen extends StatefulWidget {
  const SlotSelectionScreen({super.key});

  @override
  State<SlotSelectionScreen> createState() => _SlotSelectionScreenState();
}

class _SlotSelectionScreenState extends State<SlotSelectionScreen> {
  GroundModel? _ground;
  LocationModel? _location;
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
      if (args is Map) {
        _ground = args['ground'] as GroundModel?;
        _location = args['location'] as LocationModel?;
        final explicitSport = args['preferredSport'] as String?;
        if (_ground != null) {
          context.read<SlotSelectionCubit>().initFacility(_ground!, explicitPreferredSport: explicitSport);
          final locationId = _ground!.locationId;
          if (locationId.isNotEmpty) {
            _loadLocationReviews(locationId);
          }
        } else if (_location != null) {
          context.read<SlotSelectionCubit>().initForLocation(_location!);
          _loadLocationReviews(_location!.id);
        }
      } else if (args is GroundModel) {
        _ground = args;
        context.read<SlotSelectionCubit>().initFacility(_ground!);
        // Load reviews using locationId
        final locationId = _ground!.locationId;
        if (locationId.isNotEmpty) {
          _loadLocationReviews(locationId);
        }
      } else if (args is LocationModel) {
        _location = args;
        context.read<SlotSelectionCubit>().initForLocation(args);
        _loadLocationReviews(args.id);
      } else {
        setState(() => _isLoadingReviews = false);
      }
      _isInitialized = true;
    }
  }

  Future<void> _loadLocationReviews(String locationId) async {
    if (!mounted) return;
    setState(() {
      _isLoadingReviews = true;
    });
    try {
      final reviews =
          await getIt<ReviewRepository>().fetchLocationReviews(locationId);
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
        bottomNavigationBar:
            BlocBuilder<SlotSelectionCubit, SlotSelectionState>(
          builder: (context, state) {
            final isEnabled = state.selectedTurf != null;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  border: Border(
                    top: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      offset: const Offset(0, -4),
                      blurRadius: 10,
                    )
                  ]),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
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
                            Navigator.pushNamed(
                                context, AppRoutes.timeSlotSelection);
                          }
                        : null,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppText(
                          text: "Book Now",
                          textStyle: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward,
                            color: Colors.white, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        body: BlocConsumer<SlotSelectionCubit, SlotSelectionState>(
          listenWhen: (previous, current) =>
              previous.selectedTurf?.id != current.selectedTurf?.id,
          listener: (context, state) {
            if (state.selectedTurf != null) {
              // Load reviews - prefer location reviews if locationId is available
              final locationId = state.selectedTurf!.locationId;
              if (locationId.isNotEmpty) {
                _loadLocationReviews(locationId);
              }
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

            final displayVenue = _ground ??
                (state.facilityGrounds.isNotEmpty
                    ? state.facilityGrounds.first
                    : null);

            return Column(
              children: [
                // Fixed Header
                BlocBuilder<SavedGroundCubit, SavedGroundState>(
                  builder: (context, savedState) {
                    final displayLocationId = (state.selectedTurf ?? _ground)?.locationId;
                    final isSaved = displayLocationId != null
                        ? savedState.favoriteIds.contains(displayLocationId)
                        : false;
                    return SlotSelectionWidgets.buildHeader(
                      context,
                      state.selectedTurf ?? _ground,
                      title: displayVenue?.locationName.isNotEmpty == true
                          ? displayVenue!.locationName
                          : '---',
                      isSaved: isSaved,
                      onToggleFav: () {
                        if (displayLocationId == null) return;
                        HapticFeedback.lightImpact();
                        final user = FirebaseAuth.instance.currentUser;
                        if (user != null) {
                          context
                              .read<SavedGroundCubit>()
                              .toggleFavorite(user.uid, displayLocationId);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("Please login to save grounds")),
                          );
                        }
                      },
                      onShare: _shareGround,
                    );
                  },
                ),

                if (state.isLoading && state.availableSports.isEmpty)
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child:
                          SlotSelectionWidgets.buildSportGroundShimmer(context),
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
                          SlotSelectionWidgets.buildVenueInfoCard(context, displayVenue, reviews: _reviews),

                          // Sport & Ground Selection
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            child: SlotSelectionWidgets.buildPremiumCard(
                              context: context,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
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
                                  if (state.facilityGrounds.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                      child: Divider(height: 1, color: Theme.of(context).dividerColor.withOpacity(0.1)),
                                    ),
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
                                ],
                              ),
                            ),
                          ),

                          // Amenities
                          if (state.selectedTurf?.amenities.isNotEmpty == true || displayVenue?.amenities.isNotEmpty == true)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                              child: SlotSelectionWidgets.buildPremiumCard(
                                context: context,
                                child: SlotSelectionWidgets.buildAmenitiesSection(
                                    context,
                                    state.selectedTurf?.amenities.isNotEmpty == true
                                        ? state.selectedTurf?.amenities
                                        : displayVenue?.amenities),
                              ),
                            ),

                          // Privacy Policy
                          if ((state.selectedTurf?.privacyPolicy ?? '').isNotEmpty || (displayVenue?.privacyPolicy ?? '').isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                              child: SlotSelectionWidgets.buildPremiumCard(
                                context: context,
                                child: SlotSelectionWidgets.buildPrivacyPolicySection(
                                    context,
                                    (state.selectedTurf?.privacyPolicy ?? '').isNotEmpty
                                        ? state.selectedTurf?.privacyPolicy
                                        : displayVenue?.privacyPolicy),
                              ),
                            ),

                          // Description
                          Builder(
                            builder: (context) {
                              final descText = [
                                if ((displayVenue?.locationDescription ?? '').isNotEmpty)
                                  displayVenue!.locationDescription.trim(),
                                if ((state.selectedTurf?.description ?? '').isNotEmpty)
                                  state.selectedTurf!.description.trim()
                                else if ((displayVenue?.description ?? '').isNotEmpty)
                                  displayVenue!.description.trim(),
                              ].where((s) => s.isNotEmpty).join('\n\n');
                              
                              if (descText.isEmpty) return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                child: SlotSelectionWidgets.buildPremiumCard(
                                  context: context,
                                  child: SlotSelectionWidgets.buildDescriptionSection(
                                    context, 
                                    descText,
                                    locationName: displayVenue?.locationName,
                                  ),
                                ),
                              );
                            }
                          ),

                          // Map (if available)
                          if (displayVenue != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                              child: SlotSelectionWidgets.buildPremiumCard(
                                context: context,
                                child: SlotSelectionWidgets.buildMapSection(
                                  context,
                                  latitude: displayVenue.latitude,
                                  longitude: displayVenue.longitude,
                                  address: displayVenue.address,
                                ),
                              ),
                            ),

                          // Reviews
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            child: SlotSelectionWidgets.buildPremiumCard(
                              context: context,
                              child: SlotSelectionWidgets.buildReviewSection(
                                  context, _reviews, _isLoadingReviews),
                            ),
                          ),
                          const SizedBox(height: 24),
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
