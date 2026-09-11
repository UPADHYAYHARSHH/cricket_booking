import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:turfpro/common/constants/colors.dart';
import 'package:turfpro/common/widgets/discover_app_bar.dart';
import 'package:turfpro/common/config/feature_config.dart';
import 'package:turfpro/common/services/remote_config_service.dart';
import 'package:turfpro/user_booking/constants/widgets/app_text.dart';
import 'package:turfpro/user_booking/domain/models/slot_models.dart';
import 'package:turfpro/user_booking/domain/models/booking_arguments.dart';
import 'package:turfpro/user_booking/presentation/blocs/slot_selection/slot_selection_cubit.dart';
import 'package:turfpro/user_booking/presentation/blocs/slot_selection/slot_selection_state.dart';
import 'package:turfpro/user_booking/presentation/widgets/ground_image_carousel.dart';
import 'package:turfpro/user_booking/presentation/widgets/slot_selection_widgets.dart';
import 'package:turfpro/user_booking/di/get_it/get_it.dart';
import 'package:turfpro/user_booking/data/repositories/payment_repository.dart';

class BookingSummaryScreen extends StatefulWidget {
  const BookingSummaryScreen({super.key});

  @override
  State<BookingSummaryScreen> createState() => _BookingSummaryScreenState();
}

class _BookingSummaryScreenState extends State<BookingSummaryScreen> {
  bool _requiresApproval = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _checkApprovalRequirement();
    }
  }

  Future<void> _checkApprovalRequirement() async {
    final rawArgs = ModalRoute.of(context)?.settings.arguments;
    if (rawArgs != null && rawArgs is BookingSummaryArguments) {
      final ownerId = rawArgs.ground.ownerId;
      if (ownerId.isNotEmpty) {
        final isReq = await getIt<PaymentRepository>().checkOwnerRequiresApproval(ownerId);
        if (mounted) {
          setState(() {
            _requiresApproval = isReq;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final rawArgs = ModalRoute.of(context)?.settings.arguments;

    if (rawArgs == null || rawArgs is! BookingSummaryArguments) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Booking Summary", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const HugeIcon(icon: HugeIcons.strokeRoundedArrowLeft01, size: 20, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          flexibleSpace: const DiscoverAppBarBackground(),
        ),
        body: const Center(
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

    return BlocBuilder<SlotSelectionCubit, SlotSelectionState>(
      builder: (context, state) {
        final double platformFee = RemoteConfigService().platformFee;

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
        if (FeatureConfig.isWalletEnabled &&
            state.useWallet &&
            state.walletBalance > 0) {
          double remainingAfterLoyalty = basePrice - pointsDiscount;
          walletDiscount = state.walletBalance > remainingAfterLoyalty
              ? remainingAfterLoyalty
              : state.walletBalance;
        }

        final double totalDiscount = pointsDiscount + walletDiscount;
        final double grandTotal =
            ((basePrice - totalDiscount) + platformFee).clamp(0.0, double.infinity);

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF7F9FA),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            systemOverlayStyle: SystemUiOverlayStyle.light,
            flexibleSpace: const DiscoverAppBarBackground(),
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowLeft01,
                  size: 18,
                  color: Colors.white,
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Column(
              children: [
                const AppText(
                  text: "Review & Pay",
                  textStyle: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                AppText(
                  text: "Step 2 of 2 • Checkout",
                  textStyle: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Ground Details Hero Card
                _buildGroundHeroCard(
                  context,
                  ground: ground,
                  sport: selectedSport,
                  activeDate: activeDate,
                  slotsCount: selectedSlots.length,
                  basePrice: basePrice,
                  isDark: isDark,
                  colorScheme: colorScheme,
                ),
                const SizedBox(height: 20),

                // 2. Selected Time Slots Card
                _buildTimeSlotsCard(
                  context,
                  selectedSlots: selectedSlots,
                  activeDate: activeDate,
                  isDark: isDark,
                  colorScheme: colorScheme,
                ),
                const SizedBox(height: 20),

                // 3. Rewards & Wallet Discounts Section
                if (FeatureConfig.isLoyaltyEnabled || FeatureConfig.isWalletEnabled)
                  _buildOffersSection(
                    context,
                    state: state,
                    basePrice: basePrice,
                    pointsDiscount: pointsDiscount,
                    walletDiscount: walletDiscount,
                    isDark: isDark,
                    colorScheme: colorScheme,
                  ),

                // 4. Payment Breakdown Receipt
                _buildPriceBreakdownCard(
                  context,
                  basePrice: basePrice,
                  pointsDiscount: pointsDiscount,
                  walletDiscount: walletDiscount,
                  platformFee: platformFee,
                  grandTotal: grandTotal,
                  isDark: isDark,
                  colorScheme: colorScheme,
                ),
                const SizedBox(height: 20),

                // 5. Trust & Assurance Banner
                _buildTrustBanner(context, isDark, colorScheme),

                if (_requiresApproval) ...[
                  const SizedBox(height: 16),
                  _buildApprovalRequiredNotice(context, isDark, colorScheme),
                ],
              ],
            ),
          ),
          // 6. Fixed Sticky Checkout Bottom Bar
          bottomNavigationBar: _buildStickyBottomBar(
            context,
            grandTotal: grandTotal,
            totalDiscount: totalDiscount,
            isApprovalRequired: _requiresApproval,
            onConfirm: () {
              HapticFeedback.mediumImpact();
              Navigator.pop(context, {
                'finalAmount': grandTotal,
                'appliedPoints':
                    state.useLoyaltyPoints ? pointsDiscount.toInt() : 0,
                'appliedWallet': state.useWallet ? walletDiscount : 0.0,
                'isApprovalRequired': _requiresApproval,
              });
            },
            isDark: isDark,
            colorScheme: colorScheme,
          ),
        );
      },
    );
  }

  // ─── 1. GROUND HERO CARD ───────────────────────────────────────
  Widget _buildGroundHeroCard(
    BuildContext context, {
    required dynamic ground,
    required String sport,
    required dynamic activeDate,
    required int slotsCount,
    required double basePrice,
    required bool isDark,
    required ColorScheme colorScheme,
  }) {
    IconData getSportIcon() {
      final s = sport.toLowerCase();
      if (s.contains('cricket')) return Icons.sports_cricket_rounded;
      if (s.contains('football') || s.contains('soccer')) return Icons.sports_soccer_rounded;
      if (s.contains('tennis') || s.contains('badminton')) return Icons.sports_tennis_rounded;
      if (s.contains('basket')) return Icons.sports_basketball_rounded;
      if (s.contains('volley')) return Icons.sports_volleyball_rounded;
      if (s.contains('kabaddi')) return Icons.sports_kabaddi_rounded;
      return Icons.sports_rounded;
    }

    final images = (ground.images as List?)?.map((e) => e.toString()).toList() ?? <String>[];
    final fallbackImg = ground.imageUrl?.toString() ?? '';
    final sportDisplay = sport.replaceAll('_', ' ').toUpperCase();
    final addressText = ground.address.isNotEmpty
        ? ground.address
        : (ground.city.isNotEmpty ? ground.city : 'Location available in booking');

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Carousel Header with overlays
            Stack(
              children: [
                GroundImageCarousel(
                  images: images,
                  fallbackImageUrl: fallbackImg,
                  height: 190,
                  borderRadius: BorderRadius.zero,
                  allowFullScreen: true,
                ),

                // Gradient over carousel
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.3),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.65),
                        ],
                        stops: const [0.0, 0.45, 1.0],
                      ),
                    ),
                  ),
                ),

                // Top Chips Row
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Sport Chip
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.primaryDarkGreen,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(getSportIcon(), color: Colors.white, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              sportDisplay,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Verified / Rating Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                            const SizedBox(width: 3),
                            Text(
                              ground.rating > 0 ? ground.rating.toStringAsFixed(1) : '4.8',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom Overlay Info on Carousel
                Positioned(
                  bottom: 12,
                  left: 14,
                  right: 14,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ground.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    color: Colors.black54,
                                    blurRadius: 4,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (ground.locationName.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                ground.locationName,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Text(
                          "₹${basePrice.toStringAsFixed(0)}",
                          style: const TextStyle(
                            color: AppColors.primaryDarkGreen,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Card Body (Address & Amenities)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryDarkGreen.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const HugeIcon(
                            icon: HugeIcons.strokeRoundedLocation01,
                            size: 14,
                            color: AppColors.primaryDarkGreen,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          addressText,
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurface.withValues(alpha: 0.65),
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── 2. SELECTED TIME SLOTS CARD ───────────────────────────────
  Widget _buildTimeSlotsCard(
    BuildContext context, {
    required List<dynamic> selectedSlots,
    required dynamic activeDate,
    required bool isDark,
    required ColorScheme colorScheme,
  }) {
    String formattedDate = '';
    try {
      final day = activeDate?.day?.toString() ?? '';
      final date = activeDate?.date?.toString() ?? '';
      final month = activeDate?.month?.toString() ?? '';
      final year = activeDate?.fullDate?.year?.toString() ?? DateTime.now().year.toString();
      formattedDate = day.isNotEmpty ? "$day, $date $month $year" : "$date $month $year";
    } catch (_) {
      formattedDate = DateFormat('EEEE, MMM d, yyyy').format(DateTime.now());
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Title & Count Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryDarkGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.schedule_rounded,
                      size: 16,
                      color: AppColors.primaryDarkGreen,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Booking Schedule",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accentOrange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "${selectedSlots.length} ${selectedSlots.length == 1 ? 'Slot' : 'Slots'} (${selectedSlots.length} hrs)",
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accentOrange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Date Display Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.event_available_rounded, size: 16, color: AppColors.primaryDarkGreen),
                const SizedBox(width: 8),
                Text(
                  formattedDate,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Slot Pills
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: selectedSlots.map((slot) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primaryDarkGreen.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.primaryDarkGreen.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.access_time_rounded, size: 13, color: AppColors.primaryDarkGreen),
                    const SizedBox(width: 6),
                    Text(
                      "${slot.startTime} - ${slot.endTime}",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDarkGreen,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ─── 3. OFFERS & DISCOUNTS SECTION ─────────────────────────────
  Widget _buildOffersSection(
    BuildContext context, {
    required SlotSelectionState state,
    required double basePrice,
    required double pointsDiscount,
    required double walletDiscount,
    required bool isDark,
    required ColorScheme colorScheme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.local_offer_outlined, size: 16, color: AppColors.primaryDarkGreen),
            const SizedBox(width: 6),
            Text(
              "Offers & Balance",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Loyalty Points Card
        if (FeatureConfig.isLoyaltyEnabled) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: state.useLoyaltyPoints
                    ? AppColors.goldenYellow
                    : (isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.borderLight),
                width: state.useLoyaltyPoints ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: state.useLoyaltyPoints
                      ? AppColors.goldenYellow.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.goldenYellow.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.stars_rounded, color: AppColors.goldenYellow, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            "TurfPro Rewards",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          if (state.useLoyaltyPoints && pointsDiscount > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primaryDarkGreen.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                "-₹${pointsDiscount.toStringAsFixed(0)}",
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryDarkGreen,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        state.availableLoyaltyPoints >= 50
                            ? "Use ${state.availableLoyaltyPoints} pts for up to ₹${(basePrice * 0.5).toStringAsFixed(0)} off"
                            : "Have ${state.availableLoyaltyPoints} pts (Min 50 required)",
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: state.useLoyaltyPoints,
                  activeColor: AppColors.primaryDarkGreen,
                  onChanged: state.availableLoyaltyPoints >= 50
                      ? (_) {
                          HapticFeedback.selectionClick();
                          context.read<SlotSelectionCubit>().toggleLoyaltyPoints();
                        }
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Wallet Balance Card
        if (FeatureConfig.isWalletEnabled) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: state.useWallet
                    ? Colors.blue
                    : (isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.borderLight),
                width: state.useWallet ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: state.useWallet
                      ? Colors.blue.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.blue, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            "TurfPro Wallet",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          if (state.useWallet && walletDiscount > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                "-₹${walletDiscount.toStringAsFixed(0)}",
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        state.walletBalance > 0
                            ? "Available balance: ₹${state.walletBalance.toStringAsFixed(0)}"
                            : "No balance in wallet",
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: state.useWallet,
                  activeColor: Colors.blue,
                  onChanged: state.walletBalance > 0
                      ? (_) {
                          HapticFeedback.selectionClick();
                          context.read<SlotSelectionCubit>().toggleWallet();
                        }
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ],
    );
  }

  // ─── 4. PRICE BREAKDOWN CARD ───────────────────────────────────
  Widget _buildPriceBreakdownCard(
    BuildContext context, {
    required double basePrice,
    required double pointsDiscount,
    required double walletDiscount,
    required double platformFee,
    required double grandTotal,
    required bool isDark,
    required ColorScheme colorScheme,
  }) {
    final double totalSavings = pointsDiscount + walletDiscount;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                const Icon(Icons.receipt_long_rounded, size: 18, color: AppColors.primaryDarkGreen),
                const SizedBox(width: 8),
                Text(
                  "Price Breakdown",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInvoiceRow(
                  "Slot Booking Amount",
                  "₹${basePrice.toStringAsFixed(0)}",
                  colorScheme: colorScheme,
                ),
                if (pointsDiscount > 0) ...[
                  const SizedBox(height: 10),
                  _buildInvoiceRow(
                    "Loyalty Points Discount",
                    "- ₹${pointsDiscount.toStringAsFixed(0)}",
                    valueColor: AppColors.primaryDarkGreen,
                    colorScheme: colorScheme,
                  ),
                ],
                if (walletDiscount > 0) ...[
                  const SizedBox(height: 10),
                  _buildInvoiceRow(
                    "Wallet Balance Applied",
                    "- ₹${walletDiscount.toStringAsFixed(0)}",
                    valueColor: Colors.blue,
                    colorScheme: colorScheme,
                  ),
                ],
                const SizedBox(height: 10),
                _buildInvoiceRow(
                  "Platform Fee",
                  "₹${platformFee.toStringAsFixed(0)}",
                  colorScheme: colorScheme,
                ),
                const SizedBox(height: 10),
                _buildInvoiceRow(
                  "Taxes & Convenience",
                  "Included",
                  valueColor: colorScheme.onSurface.withValues(alpha: 0.6),
                  colorScheme: colorScheme,
                ),
                const SizedBox(height: 14),

                // Dashed Line Divider
                CustomPaint(
                  painter: _DashedLinePainter(
                    color: isDark ? Colors.white24 : Colors.black12,
                  ),
                  size: const Size(double.infinity, 1),
                ),
                const SizedBox(height: 14),

                // Total Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Total Amount to Pay",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      "₹${grandTotal.toStringAsFixed(0)}",
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDarkGreen,
                      ),
                    ),
                  ],
                ),

                // Savings Pill if any
                if (totalSavings > 0) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryDarkGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.primaryDarkGreen),
                        const SizedBox(width: 6),
                        Text(
                          "Total savings of ₹${totalSavings.toStringAsFixed(0)} applied!",
                          style: const TextStyle(
                            color: AppColors.primaryDarkGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceRow(
    String label,
    String value, {
    Color? valueColor,
    required ColorScheme colorScheme,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: valueColor ?? colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  // ─── 5. TRUST & ASSURANCE BANNER ───────────────────────────────
  Widget _buildTrustBanner(BuildContext context, bool isDark, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryDarkGreen.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.verified_user_rounded, color: AppColors.primaryDarkGreen, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "100% Secure Checkout",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  "Instant booking confirmation & slots lock",
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── 5b. APPROVAL REQUIRED NOTICE BANNER ──────────────────────────
  Widget _buildApprovalRequiredNotice(BuildContext context, bool isDark, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.amber.withValues(alpha: 0.4),
          width: 1.2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.info_outline_rounded, color: Colors.amber, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Owner Confirmation Required",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "The owner will review your booking request. Once requested, the owner has 45 minutes to confirm. You will only pay after confirmation.",
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── 6. STICKY BOTTOM CHECKOUT BAR ─────────────────────────────
  Widget _buildStickyBottomBar(
    BuildContext context, {
    required double grandTotal,
    required double totalDiscount,
    required VoidCallback onConfirm,
    required bool isDark,
    required ColorScheme colorScheme,
    bool isApprovalRequired = false,
  }) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.borderLight,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Total Amount Info
          Expanded(
            flex: 2,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isApprovalRequired ? "ESTIMATED TOTAL" : "TOTAL TO PAY",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                    if (totalDiscount > 0) ...[
                      const SizedBox(width: 4),
                      Text(
                        "• Save ₹${totalDiscount.toStringAsFixed(0)}",
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDarkGreen,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  "₹${grandTotal.toStringAsFixed(0)}",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDarkGreen,
                  ),
                ),
              ],
            ),
          ),

          // CTA Button (Request Booking or Proceed to Pay)
          Expanded(
            flex: 3,
            child: ElevatedButton(
              onPressed: onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: isApprovalRequired ? Colors.amber.shade700 : AppColors.primaryDarkGreen,
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: (isApprovalRequired ? Colors.amber.shade700 : AppColors.primaryDarkGreen).withValues(alpha: 0.4),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isApprovalRequired ? "Request Booking" : "Proceed to Pay",
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isApprovalRequired ? Icons.send_rounded : Icons.arrow_forward_rounded,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── DASHED LINE PAINTER ──────────────────────────────────────────
class _DashedLinePainter extends CustomPainter {
  final Color color;
  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const dashWidth = 5.0;
    const dashSpace = 4.0;
    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
