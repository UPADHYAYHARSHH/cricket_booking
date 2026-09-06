import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:turfpro/user_booking/presentation/widgets/shared_booking_widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math';
import 'package:turfpro/common/widgets/status_badge.dart';
import 'package:turfpro/utils/ticket_util.dart';
import 'package:turfpro/utils/qr_crypto.dart';
import 'package:turfpro/utils/id_util.dart';

import '../../../../common/constants/colors.dart';
import '../../../constants/text_theme.dart';
import '../../../constants/widgets/app_sizedBox.dart';
import '../../../constants/widgets/app_text.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../constants/route_constants.dart';

import '../../blocs/booking/booking_cubit.dart';
import '../../blocs/booking/booking_state.dart';
import '../../../data/models/booking_model.dart';
import 'package:turfpro/user_booking/di/get_it/get_it.dart';
import 'package:turfpro/user_booking/domain/repositories/review_repository.dart';
import 'package:turfpro/user_booking/presentation/widgets/add_review_bottom_sheet.dart';
import 'package:turfpro/user_booking/presentation/widgets/slot_selection_widgets.dart';
import 'package:turfpro/user_booking/presentation/widgets/ground_image_carousel.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:turfpro/user_booking/domain/models/slot_models.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  int _selectedTab = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedTab);
    context.read<BookingCubit>().getBookings();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const AppSizedBox(height: 16),
          _buildTabBar(),
          const AppSizedBox(height: 16),
          Expanded(child: _buildBookingList()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 24,
          left: 20,
          right: 20,
          bottom: 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0B8457), Color(0xFF065B3C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppText(
            text: "My Bookings",
            size: 26,
            weight: FontWeight.w700,
            color: AppColors.white,
          ),
          const SizedBox(height: 6),
          AppText(
            text: "View and manage your reservations",
            size: 14,
            color: AppColors.white.withValues(alpha: 0.7),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            _tabItem("Upcoming", 0),
            _tabItem("Completed", 1),
          ],
        ),
      ),
    );
  }

  Widget _tabItem(String label, int index) {
    final theme = Theme.of(context);
    final isSelected = _selectedTab == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedTab = index);
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryDarkGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(26),
          ),
          alignment: Alignment.center,
          child: AppText(
            text: label,
            textStyle: AppTextTheme.black13.copyWith(
              color: isSelected
                  ? AppColors.white
                  : theme.colorScheme.onSurface.withValues(alpha: 0.6),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBookingList() {
    return BlocBuilder<BookingCubit, BookingState>(
      builder: (context, state) {
        if (state is BookingLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is BookingError) {
          return Center(
              child:
                  AppText(text: state.message, textStyle: AppTextTheme.grey13));
        }

        if (state is BookingLoaded) {
          return PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _selectedTab = index;
              });
            },
            children: [
              _buildSingleTabBookingList(state.bookings, isUpcoming: true),
              _buildSingleTabBookingList(state.bookings, isUpcoming: false),
            ],
          );
        }

        return const SizedBox();
      },
    );
  }

  Widget _buildSingleTabBookingList(List<BookingModel> allBookings, {required bool isUpcoming}) {
    final theme = Theme.of(context);
    final now = DateTime.now();

    final bookings = allBookings.where((b) {
      final localDate = b.slotTime.toLocal();
      DateTime endTime = localDate;
      if (b.period != null && b.period!.contains('|')) {
        final parts = b.period!.split('|');
        if (parts.length > 1) {
          final times = parts[1].split(',');
          if (times.isNotEmpty) {
            final lastTime = times.last.trim();
            final timeParts = lastTime.split(':');
            if (timeParts.length >= 2) {
              int h = int.tryParse(timeParts[0]) ?? 0;
              final mPart = timeParts[1].trim().split(' ');
              final m = int.tryParse(mPart[0]) ?? 0;
              final amPm = mPart.length > 1 ? mPart[1].toUpperCase() : '';
              if (amPm == 'PM' && h != 12) h += 12;
              if (amPm == 'AM' && h == 12) h = 0;
              endTime = DateTime(localDate.year, localDate.month, localDate.day, h + 1, m);
            }
          }
        }
      }

      if (isUpcoming) {
        return endTime.isAfter(now);
      } else {
        return endTime.isBefore(now);
      }
    }).toList();

    if (isUpcoming) {
      bookings.sort((a, b) => a.slotTime.compareTo(b.slotTime));
    } else {
      bookings.sort((a, b) => b.slotTime.compareTo(a.slotTime));
    }

    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                Icons.calendar_today_outlined,
                size: 64,
                color: AppColors.primaryDarkGreen.withValues(alpha: 0.3),
              ),
            ),
            const AppSizedBox(height: 24),
            AppText(
              text: isUpcoming ? "No upcoming bookings" : "No completed bookings",
              textStyle: AppTextTheme.black18.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
            const AppSizedBox(height: 8),
            AppText(
              text: isUpcoming
                  ? "Your upcoming matches will appear here"
                  : "Matches you have played will appear here",
              textStyle: AppTextTheme.grey13.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<BookingCubit>().getBookings(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: bookings.length,
        itemBuilder: (_, i) => _BookingCard(booking: bookings[i]),
      ),
    );
  }
}

class _BookingCard extends StatefulWidget {
  final BookingModel booking;

  const _BookingCard({required this.booking});

  @override
  State<_BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends State<_BookingCard> {
  bool _hasRated = false;
  bool _isLoadingRating = true;

  @override
  void initState() {
    super.initState();
    _checkIfRated();
  }

  Future<void> _checkIfRated() async {
    final user = FirebaseAuth.instance.currentUser;
    final locationId = widget.booking.ground?.locationId ?? '';

    // If no locationId or no user, can't rate — hide the button
    if (user == null || locationId.isEmpty) {
      if (mounted)
        setState(() {
          _hasRated = true; // treat as "already rated" to hide the button
          _isLoadingRating = false;
        });
      return;
    }

    try {
      final rated = await getIt<ReviewRepository>()
          .hasUserRatedLocation(user.uid, locationId);
      if (mounted) {
        setState(() {
          _hasRated = rated;
          _isLoadingRating = false;
        });
      }
    } catch (e) {
      debugPrint("Error checking user rating: $e");
      // On error, hide button to avoid confusion
      if (mounted)
        setState(() {
          _hasRated = true;
          _isLoadingRating = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _viewTicket(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopSection(context),
              _buildDateSection(context),
              _buildInfoSection(context, onSurface),
              _buildActionRow(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopSection(BuildContext context) {
    final rawSport = widget.booking.sportName ?? widget.booking.ground?.categories.firstOrNull ?? '';
    final sportFormatted = rawSport.replaceAll('_', ' ').toUpperCase();

    return Stack(
      children: [
        GroundImageCarousel(
          images: widget.booking.ground?.images ?? [],
          fallbackImageUrl: widget.booking.ground?.imageUrl ??
              "https://images.unsplash.com/photo-1540747913346-19e32dc3e97e",
          height: 165,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
          allowFullScreen: true,
        ),

        // Gradient overlay at bottom of image
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 44,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.35),
                ],
              ),
            ),
          ),
        ),

        // Sport badge on top-left
        if (sportFormatted.isNotEmpty)
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryDarkGreen.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Text(
                sportFormatted,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),

        // Status Badge
        Positioned(
          top: 12,
          right: 12,
          child: StatusBadge(status: widget.booking.status),
        ),

        // Check-in Badge
        if (widget.booking.checkedIn)
          Positioned(
            bottom: 10,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primaryDarkGreen,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text(
                    'Checked In',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  String _getFormattedTimeRange() {
    if (widget.booking.period == null ||
        !widget.booking.period!.contains('|')) {
      return '';
    }
    final parts = widget.booking.period!.split('|');
    if (parts.length <= 1) return '';
    final times = parts[1]
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (times.isEmpty) return '';

    List<int> hours24 = [];
    for (String time in times) {
      final timeParts = time.split(':');
      if (timeParts.length >= 2) {
        int h = int.tryParse(timeParts[0]) ?? 0;
        final mPart = timeParts[1].trim().split(' ');
        final amPm = mPart.length > 1 ? mPart[1].toUpperCase() : '';
        if (amPm == 'PM' && h != 12) h += 12;
        if (amPm == 'AM' && h == 12) h = 0;
        hours24.add(h);
      }
    }
    hours24.sort();

    if (hours24.isEmpty) return '';

    List<String> ranges = [];
    int blockStart = hours24.first;
    int prevHour = hours24.first;

    String formatHour(int h) {
      int wrappedH = h % 24;
      final amPm = wrappedH >= 12 ? 'PM' : 'AM';
      int hour12 =
          wrappedH > 12 ? wrappedH - 12 : (wrappedH == 0 ? 12 : wrappedH);
      return '${hour12.toString().padLeft(2, '0')}:00 $amPm';
    }

    for (int i = 1; i < hours24.length; i++) {
      if (hours24[i] == prevHour + 1) {
        prevHour = hours24[i];
      } else {
        ranges.add('${formatHour(blockStart)} - ${formatHour(prevHour + 1)}');
        blockStart = hours24[i];
        prevHour = hours24[i];
      }
    }
    ranges.add('${formatHour(blockStart)} - ${formatHour(prevHour + 1)}');

    final count = hours24.length;
    final slotText = count == 1 ? '1 slot' : '$count slots';
    return '${ranges.join(', ')} ($slotText)';
  }

  Widget _buildDateSection(BuildContext context) {
    final theme = Theme.of(context);
    final timeRange = _getFormattedTimeRange();

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.calendar_today_rounded,
                size: 16, color: AppColors.primaryDarkGreen),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: AppText(
              text: DateFormat('EEE, d MMM yyyy')
                      .format(widget.booking.slotTime) +
                  (timeRange.isNotEmpty ? '  •  $timeRange' : ''),
              textStyle: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context, Color onSurface) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedLocation01,
                size: 14,
                color: onSurface.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: AppText(
                  text: (widget.booking.ground?.address != null && widget.booking.ground!.address.isNotEmpty)
                      ? widget.booking.ground!.address
                      : "Location not available",
                  textStyle: TextStyle(
                    fontSize: 12,
                    color: onSurface.withValues(alpha: 0.5),
                  ),
                  maxLines: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      text: (widget.booking.ground?.locationName != null && widget.booking.ground!.locationName.isNotEmpty)
                          ? widget.booking.ground!.locationName
                          : (widget.booking.ground?.name ?? "Venue Name"),
                      textStyle: AppTextTheme.black16.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (widget.booking.sportName != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.primaryDarkGreen.withValues(alpha: 0.5),
                                width: 1,
                              ),
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                SlotSelectionWidgets.getSportImage(widget.booking.sportName!),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.sports, size: 14, color: AppColors.primaryDarkGreen),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          AppText(
                            text: widget.booking.ground?.name ?? "Venue Name",
                            textStyle: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              AppText(
                text: "₹${widget.booking.amount}",
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDarkGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedLocation01,
                size: 14,
                color: onSurface.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: AppText(
                  text: (widget.booking.ground?.address != null &&
                          widget.booking.ground!.address.isNotEmpty)
                      ? widget.booking.ground!.address
                      : "Location not available",
                  textStyle: TextStyle(
                    fontSize: 12,
                    color: onSurface.withValues(alpha: 0.5),
                  ),
                  maxLines: 2,
                ),
              ),
            ],
          ),

          // Check-in time display
          if (widget.booking.checkedIn &&
              widget.booking.checkedInAt != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.access_time_filled,
                  size: 14,
                  color: AppColors.primaryDarkGreen,
                ),
                const SizedBox(width: 4),
                AppText(
                  text: "Checked in at ${DateFormat('h:mm a').format(widget.booking.checkedInAt!)}",
                  textStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDarkGreen,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionRow(BuildContext context) {
    final now = DateTime.now();
    final localDate = widget.booking.slotTime.toLocal();
    DateTime endTime = localDate;
    if (widget.booking.period != null && widget.booking.period!.contains('|')) {
      final parts = widget.booking.period!.split('|');
      if (parts.length > 1) {
        final times = parts[1].split(',');
        if (times.isNotEmpty) {
          final lastTime = times.last.trim();
          final timeParts = lastTime.split(':');
          if (timeParts.length >= 2) {
            int h = int.tryParse(timeParts[0]) ?? 0;
            final mPart = timeParts[1].trim().split(' ');
            final m = int.tryParse(mPart[0]) ?? 0;
            final amPm = mPart.length > 1 ? mPart[1].toUpperCase() : '';
            if (amPm == 'PM' && h != 12) h += 12;
            if (amPm == 'AM' && h == 12) h = 0;
            endTime = DateTime(
                localDate.year, localDate.month, localDate.day, h + 1, m);
          }
        }
      }
    }
    final isPast = endTime.isBefore(now);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: Row(children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () => _viewTicket(context),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  AppColors.primaryDarkGreen.withValues(alpha: 0.1),
              foregroundColor: AppColors.primaryDarkGreen,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text("View Ticket",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ),
        if (isPast) ...[
          const SizedBox(width: 8),
          if (!_hasRated && !_isLoadingRating) ...[
            Expanded(
              child: ElevatedButton(
                onPressed: () => _showRatingSheet(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade700,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text("Rate Venue",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: ElevatedButton(
              onPressed: () => _rebook(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDarkGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text("Rebook",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ),
        ],
      ]),
    );
  }

  void _showRatingSheet(BuildContext context) async {
    final groundId = widget.booking.groundId;
    final locationId = widget.booking.ground?.locationId ?? '';

    if (groundId.isEmpty && locationId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Venue information not available.")),
      );
      return;
    }

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddReviewBottomSheet(
        groundId: groundId,
        groundName: widget.booking.ground?.name ?? "Venue",
        locationId: locationId.isNotEmpty ? locationId : null,
        locationName: locationId.isNotEmpty
            ? (widget.booking.ground?.name ?? "Venue")
            : null,
      ),
    );

    if (result == true) {
      if (mounted) {
        setState(() {
          _hasRated = true;
        });
        context.read<BookingCubit>().getBookings();
      }
    }
  }

  void _viewTicket(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ViewTicketScreen(
          ticket: TicketModel(
            bookingId: widget.booking.id,
            groundId: widget.booking.groundId,
            displayId: widget.booking.displayId,
            venueName: widget.booking.ground?.name ?? "Venue",
            locationName: widget.booking.ground?.locationName ?? '',
            pitchName: "Main Pitch",
            date: widget.booking.slotTime,
            time: DateFormat('hh:mm a').format(widget.booking.slotTime),
            bookedBy: "User",
            location: widget.booking.ground?.address ?? "Location",
            latitude: widget.booking.ground?.latitude ?? 0.0,
            longitude: widget.booking.ground?.longitude ?? 0.0,
            price: widget.booking.amount,
            imageUrl: widget.booking.ground?.imageUrl ?? "",
            images: widget.booking.ground?.images ?? [],
            isPaid: widget.booking.status == 'paid' ||
                widget.booking.status == 'confirmed',
            sportName: widget.booking.sportName ?? "Sport",
            period: widget.booking.period ?? "Day",
            amenities: widget.booking.ground?.amenities,
            ownerId: widget.booking.ground?.ownerId ?? "N/A",
            platformFee: widget.booking.platformFee,
          ),
        ),
      ),
    );
  }

  void _rebook(BuildContext context) {
    if (widget.booking.ground != null) {
      Navigator.pushNamed(
        context,
        AppRoutes.slotSelection,
        arguments: widget.booking.ground,
      );
    }
  }
}

class ViewTicketScreen extends StatefulWidget {
  final TicketModel ticket;

  final bool isFromBookingFlow;
  const ViewTicketScreen(
      {super.key, required this.ticket, this.isFromBookingFlow = false});

  @override
  State<ViewTicketScreen> createState() => _ViewTicketScreenState();
}

class _ViewTicketScreenState extends State<ViewTicketScreen> {
  bool _isSaving = false;
  List<TimeSlot> _bookedSlots = [];

  @override
  void initState() {
    super.initState();
    _loadBookedSlots();
  }

  Future<void> _loadBookedSlots() async {
    try {
      final periodParts = (widget.ticket.period).split('|');
      if (periodParts.length > 1 && periodParts[1].isNotEmpty) {
        final slotTimes =
            periodParts[1].split(',').map((s) => s.trim()).toList();
        final pricePerSlot =
            widget.ticket.price / (slotTimes.isEmpty ? 1 : slotTimes.length);

        final slots = slotTimes.map((st) {
          final endTime = _calculateEndTime(st);
          return TimeSlot(
            startTime: st,
            endTime: endTime,
            price: pricePerSlot,
            status: SlotStatus.booked,
          );
        }).toList();

        if (mounted) {
          setState(() {
            _bookedSlots = slots;
          });
        }
        return; // We got the slots locally!
      }

      // Fallback for old bookings
      final formattedDate =
          "${widget.ticket.date.year}-${widget.ticket.date.month.toString().padLeft(2, '0')}-${widget.ticket.date.day.toString().padLeft(2, '0')}";
      final response = await Supabase.instance.client
          .from('slots')
          .select('*')
          .eq('ground_id', widget.ticket.groundId)
          .eq('date', formattedDate)
          .eq('status', 'booked');

      final List data = response as List;
      final slots = data.map((json) {
        final startTime = _formatTime(json['start_time']);
        var endTime = _formatTime(json['end_time']);
        if (endTime.isEmpty && startTime.isNotEmpty) {
          endTime = _calculateEndTime(startTime);
        }
        return TimeSlot(
          startTime: startTime,
          endTime: endTime,
          price: (json['price'] ?? 0).toDouble(),
          status: SlotStatus.booked,
        );
      }).toList();

      if (mounted) {
        setState(() {
          _bookedSlots = slots;
        });
      }
    } catch (e) {
      debugPrint("[VIEW_TICKET] Error loading slots: $e");
      if (mounted) {}
    }
  }

  String _calculateEndTime(String startTime) {
    try {
      final cleanTime = startTime.trim();
      final parts = cleanTime.split(' ');
      if (parts.length != 2) return '';

      final timeParts = parts[0].split(':');
      if (timeParts.isEmpty) return '';

      int hour = int.parse(timeParts[0]);
      int minute = timeParts.length > 1 ? int.parse(timeParts[1]) : 0;
      String amPm = parts[1].toUpperCase();

      hour += 1;
      if (hour == 12) {
        amPm = amPm == 'AM' ? 'PM' : 'AM';
      } else if (hour > 12) {
        hour -= 12;
      }

      final minuteStr = minute.toString().padLeft(2, '0');
      final hourStr = hour.toString().padLeft(2, '0');
      return '$hourStr:$minuteStr $amPm';
    } catch (_) {
      return '';
    }
  }

  String _formatTime(String? timeString) {
    if (timeString == null || timeString.isEmpty) return '';
    try {
      if (timeString.contains('T')) {
        final date = DateTime.parse(timeString);
        final hour =
            date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
        final amPm = date.hour >= 12 ? 'PM' : 'AM';
        final minute = date.minute.toString().padLeft(2, '0');
        return '$hour:$minute $amPm';
      } else {
        final parts = timeString.split(':');
        if (parts.length < 2) return timeString;
        int hour = int.parse(parts[0]);
        final minute = parts[1];
        final amPm = hour >= 12 ? 'PM' : 'AM';
        if (hour > 12) hour -= 12;
        if (hour == 0) hour = 12;
        return '${hour.toString().padLeft(2, '0')}:$minute $amPm';
      }
    } catch (_) {
      return timeString;
    }
  }

  Future<void> _generateAndDownload() async {
    final timeStr = _bookedSlots.isNotEmpty
        ? _bookedSlots.map((s) => "${s.startTime} - ${s.endTime}").join(', ')
        : widget.ticket.period.split('|').first;

    await TicketUtil.downloadTicket(
      context,
      groundName: widget.ticket.venueName,
      groundAddress: widget.ticket.location,
      groundImageUrl: widget.ticket.imageUrl,
      date: widget.ticket.date,
      timeRange: timeStr,
      orderId: widget.ticket.bookingId,
      displayId: widget.ticket.displayId,
      totalPrice: widget.ticket.price,
      sportName: widget.ticket.sportName,
      selectedPeriod: widget.ticket.period.split('|').first,
      groundId: widget.ticket.groundId,
      ownerId: widget.ticket.ownerId,
      platformFee: widget.ticket.platformFee,
      amenities: widget.ticket.amenities,
      onLoadingStarted: () => setState(() => _isSaving = true),
      onLoadingFinished: () {
        if (mounted) setState(() => _isSaving = false);
      },
    );
  }

  Future<void> _openMap() async {
    await TicketUtil.openMap(widget.ticket.latitude, widget.ticket.longitude);
  }

  @override
  Widget build(BuildContext context) {
    final double discountAmount = 0.0; // TODO: Fetch from actual booking model
    final theme = Theme.of(context);
    final String timeStr = widget.ticket.period.split('|').first;
    final String displayIdStr = (widget.ticket.displayId != 0)
        ? widget.ticket.displayId.toString().padLeft(3, '0')
        : IdUtil.getShortId(widget.ticket.bookingId);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            icon: const HugeIcon(icon: HugeIcons.strokeRoundedArrowLeft01, size: 20,
              color: Colors.white,

            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: const AppText(
          text: "Booking Details",
          textStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.white),
        ),
        titleSpacing: 0,
      ),
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Green gradient header with status badge glow
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryDarkGreen,
                    Color(0xFF0FA968),
                  ],
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                24,
                MediaQuery.of(context).padding.top + 60,
                24,
                24,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          text: "Booking #CB$displayIdStr",
                          textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: widget.ticket.isPaid ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: [
                        BoxShadow(
                          color: (widget.ticket.isPaid ? const Color(0xFF4CAF50) : const Color(0xFFFF9800)).withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: AppText(
                      text: widget.ticket.isPaid ? "Confirmed" : "Pending",
                      textStyle: TextStyle(
                        color: widget.ticket.isPaid ? const Color(0xFF4CAF50) : const Color(0xFFFF9800),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.isFromBookingFlow) ...[
                    Center(
                      child: Column(
                        children: [
                          SizedBox(
                            height: 140,
                            width: 140,
                            child: Lottie.asset(
                              'assets/animations/Success.json',
                              repeat: false,
                            ),
                          ),
                          const SizedBox(height: 8),
                          AppText(
                            text: "Slot Booked Successfully!",
                            textStyle: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  const SectionLabel(title: "BOOKING DETAILS"),
                  const SizedBox(height: 12),

                  SectionCard(
                    child: Column(
                      children: [
                        if (widget.ticket.locationName.isNotEmpty) ...[
                          DetailRow(
                            label: "Venue",
                            value: widget.ticket.locationName,
                            iconData: Icons.business_rounded,
                          ),
                          const RowDivider(),
                        ],
                        DetailRow(
                          label: "Court",
                          value: widget.ticket.venueName,
                          iconData: Icons.sports_tennis_rounded,
                        ),
                        const RowDivider(),
                        DetailRow(
                          label: "Sport",
                          value: widget.ticket.sportName.split('_').map((e) => e.isNotEmpty ? e[0].toUpperCase() + e.substring(1).toLowerCase() : '').join(' '),
                          iconData: Icons.sports_volleyball,
                        ),
                        const RowDivider(),
                        DetailRow(
                          label: "Date",
                          value: DateFormat('EEEE, MMM d, yyyy').format(widget.ticket.date),
                          iconData: Icons.calendar_today_rounded,
                        ),
                        const RowDivider(),
                        DetailRow(
                          label: "Time",
                          value: timeStr.replaceAll('', ''),
                          iconData: Icons.access_time_rounded,
                        ),
                        const RowDivider(),
                        DetailRow(
                          label: "Booking ID",
                          value: "CB$displayIdStr",
                          iconData: Icons.tag_rounded,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  const SectionLabel(title: "PAYMENT SUMMARY"),
                  const SizedBox(height: 12),

                  SectionCard(
                    child: Column(
                      children: [
                        PaymentRow(
                          label: "Slot Booking Amount",
                          value: "₹${(widget.ticket.price - widget.ticket.platformFee).clamp(0.0, widget.ticket.price).toStringAsFixed(0)}",
                        ),
                        const RowDivider(),
                        PaymentRow(
                          label: "Platform Fee",
                          value: "+ ₹${widget.ticket.platformFee.toStringAsFixed(0)}",
                        ),
                        const RowDivider(),
                        if (discountAmount > 0) ...[
                          PaymentRow(
                            label: "Discount",
                            value: "- ₹${discountAmount.toStringAsFixed(0)}",
                            valueColor: const Color(0xFFE53935),
                          ),
                          const RowDivider(),
                        ],

                        const PaymentRow(
                          label: "Taxes & Charges",
                          value: "Included",
                        ),
                        const RowDivider(),
                        PaymentRow(
                          label: "Total Paid",
                          value: "₹${widget.ticket.price.toStringAsFixed(0)}",
                          valueColor: AppColors.primaryDarkGreen,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  const SectionLabel(title: "ACCESS CODE"),
                  const SizedBox(height: 12),
                  
                  SectionCard(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: theme.dividerColor),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: QrCodePainter(
                                data: QrCrypto.encryptQrData(
                                    "${widget.ticket.bookingId} | Ground: ${widget.ticket.venueName} | Owner: ${widget.ticket.ownerId} | Ground ID: ${widget.ticket.groundId}"),
                              ),
                            ),
                            const SizedBox(height: 12),
                            AppText(
                              text: "Scan at entrance",
                              textStyle: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  const SectionLabel(title: "LOCATION"),
                  const SizedBox(height: 12),
                  SlotSelectionWidgets.buildMapSection(
                    context,
                    latitude: widget.ticket.latitude,
                    longitude: widget.ticket.longitude,
                    address: widget.ticket.location,
                  ),

                  const SizedBox(height: 24),
                  _buildActionButtons(context),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : _generateAndDownload,
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.download_rounded, color: Colors.white),
            label: Text(
              _isSaving ? "Generating PDF..." : "Download Ticket",
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDarkGreen,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.share_outlined,
                color: AppColors.primaryDarkGreen),
            label: const Text("Share with Friends",
                style: TextStyle(
                    color: AppColors.primaryDarkGreen,
                    fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primaryDarkGreen),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        if (widget.isFromBookingFlow) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.nav,
                  (route) => false,
                );
              },
              icon: const Icon(Icons.home_rounded, color: Colors.white),
              label: const Text(
                "Back to Home",
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDarkGreen,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class TicketModel {
  final String bookingId;
  final String groundId;
  final int displayId;
  final String venueName;
  final String locationName;
  final String pitchName;
  final DateTime date;
  final String time;
  final String bookedBy;
  final String location;
  final double latitude;
  final double longitude;
  final double price;
  final String imageUrl;
  final List<String> images;
  final bool isPaid;
  final String sportName;
  final String period;
  final List<String>? amenities;
  final String ownerId;
  final double platformFee;

  TicketModel({
    required this.bookingId,
    required this.groundId,
    required this.displayId,
    required this.venueName,
    this.locationName = '',
    required this.pitchName,
    required this.date,
    required this.time,
    required this.bookedBy,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.price,
    required this.imageUrl,
    required this.images,
    required this.isPaid,
    this.sportName = "Sport",
    this.period = "Day",
    this.amenities,
    this.ownerId = "N/A",
    this.platformFee = 0.0,
  });
}


