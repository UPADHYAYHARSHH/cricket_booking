import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math';
import 'package:turfpro/common/widgets/status_badge.dart';
import 'package:turfpro/utils/ticket_util.dart';
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

  @override
  void initState() {
    super.initState();
    context.read<BookingCubit>().getBookings();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const AppSizedBox(height: 16),
            _buildTabBar(),
            const AppSizedBox(height: 16),
            Expanded(child: _buildBookingList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
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
        onTap: () => setState(() => _selectedTab = index),
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
    final theme = Theme.of(context);
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
          final now = DateTime.now();
          final bookings = state.bookings.where((b) {
            // A booking is considered "Completed" if its start time has passed.
            // For a better UX, we could also consider the end time (e.g. +1 hour),
            // but following the requirement: "once date or time... has gone".
            if (_selectedTab == 0) {
              return b.slotTime.isAfter(now);
            } else {
              return b.slotTime.isBefore(now);
            }
          }).toList();

          // Sort chronologically: earlier should first (ascending)
          bookings.sort((a, b) => a.slotTime.compareTo(b.slotTime));

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
                    text: "No bookings yet",
                    textStyle: AppTextTheme.black18.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                  const AppSizedBox(height: 8),
                  AppText(
                    text: "Your upcoming matches will appear here",
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

        return const SizedBox();
      },
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
    final groundId = widget.booking.groundId;

    if (user != null && groundId.isNotEmpty) {
      try {
        final rated = await getIt<ReviewRepository>()
            .hasUserRatedGround(user.uid, groundId);
        if (mounted) {
          setState(() {
            _hasRated = rated;
            _isLoadingRating = false;
          });
        }
        return;
      } catch (e) {
        debugPrint("Error checking user ground rating: $e");
      }
    }

    if (mounted) setState(() => _isLoadingRating = false);
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
    return Stack(
      children: [
        GroundImageCarousel(
          images: widget.booking.ground?.images ?? [],
          fallbackImageUrl: widget.booking.ground?.imageUrl ??
              "https://images.unsplash.com/photo-1540747913346-19e32dc3e97e",
          height: 160,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        ),

        // Status Badge
        Positioned(
          top: 12,
          right: 12,
          child: StatusBadge(status: widget.booking.status),
        ),
      ],
    );
  }

  Widget _buildDateSection(BuildContext context) {
    final theme = Theme.of(context);

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
          AppText(
            text: DateFormat('EEE, d MMM yyyy').format(widget.booking.slotTime),
            textStyle: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      text: widget.booking.ground?.name ?? "Venue Name",
                      textStyle: AppTextTheme.black16.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (widget.booking.sportName != null) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color:
                              AppColors.primaryDarkGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: AppText(
                          text: widget.booking.sportName!.toUpperCase(),
                          textStyle: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDarkGreen,
                          ),
                        ),
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
                  text: widget.booking.ground?.address ??
                      "Location not available",
                  textStyle: TextStyle(
                    fontSize: 12,
                    color: onSurface.withValues(alpha: 0.5),
                  ),
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow(BuildContext context) {
    final now = DateTime.now();
    final isPast = widget.booking.slotTime.isBefore(now);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: Row(
        children: [
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
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showRatingSheet(BuildContext context) async {
    if (widget.booking.groundId.isEmpty) {
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
        groundId: widget.booking.groundId,
        groundName: widget.booking.ground?.name ?? "Venue",
      ),
    );

    if (result == true) {
      if (mounted) {
        setState(() {
          _hasRated = true;
        });
      }
      _checkIfRated();
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
            pitchName: "Main Pitch",
            date: widget.booking.slotTime, // Keep as DateTime
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

  const ViewTicketScreen({super.key, required this.ticket});

  @override
  State<ViewTicketScreen> createState() => _ViewTicketScreenState();
}

class _ViewTicketScreenState extends State<ViewTicketScreen> {
  bool _isSaving = false;
  List<TimeSlot> _bookedSlots = [];
  bool _isLoadingSlots = true;

  @override
  void initState() {
    super.initState();
    _loadBookedSlots();
  }

  Future<void> _loadBookedSlots() async {
    try {
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
          _isLoadingSlots = false;
        });
      }
    } catch (e) {
      debugPrint("[VIEW_TICKET] Error loading slots: $e");
      if (mounted) {
        setState(() => _isLoadingSlots = false);
      }
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
        : widget.ticket.time;

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
      selectedPeriod: widget.ticket.period,
      groundId: widget.ticket.groundId,
      ownerId: widget.ticket.ownerId,
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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new,
              size: 20, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: const AppText(
          text: "My Ticket",
          textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          children: [
            _TicketCard(
              ticket: widget.ticket,
              onLocationTap: _openMap,
              bookedSlots: _bookedSlots,
              isLoadingSlots: _isLoadingSlots,
            ),
            const SizedBox(height: 24),
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
      ],
    );
  }
}

class _TicketCard extends StatefulWidget {
  final TicketModel ticket;
  final VoidCallback onLocationTap;
  final List<TimeSlot> bookedSlots;
  final bool isLoadingSlots;

  const _TicketCard({
    required this.ticket,
    required this.onLocationTap,
    required this.bookedSlots,
    required this.isLoadingSlots,
  });

  @override
  State<_TicketCard> createState() => _TicketCardState();
}

class _TicketCardState extends State<_TicketCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withValues(alpha: theme.brightness == Brightness.dark ? 0.3 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        children: [
          _buildVenueImage(context),
          _buildVenueDetails(context),
          _buildTicketInfo(context),
          _buildDashedDivider(context),
          _buildQrSection(context),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildVenueImage(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: GroundImageCarousel(
        images: widget.ticket.images,
        fallbackImageUrl: widget.ticket.imageUrl,
        height: 180,
        borderRadius: BorderRadius.zero,
      ),
    );
  }

  Widget _buildVenueDetails(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: AppText(
                  text: widget.ticket.venueName,
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryDarkGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: AppColors.primaryDarkGreen.withValues(alpha: 0.2)),
                ),
                child: AppText(
                  text: widget.ticket.sportName.toUpperCase(),
                  textStyle: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDarkGreen,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: widget.onLocationTap,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on,
                    size: 16, color: AppColors.primaryDarkGreen),
                const SizedBox(width: 4),
                Expanded(
                  child: AppText(
                    text: widget.ticket.location,
                    textStyle: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      decoration: TextDecoration.underline,
                      decorationColor:
                          theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
        ],
      ),
    );
  }

  Widget _buildSlotChip(TimeSlot slot) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryDarkGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppColors.primaryDarkGreen.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.access_time_rounded,
              size: 10, color: AppColors.primaryDarkGreen),
          const SizedBox(width: 3),
          AppText(
            text: "${slot.startTime} - ${slot.endTime}",
            textStyle: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDarkGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketInfo(BuildContext context) {
    final theme = Theme.of(context);
    final String timeStr;
    if (widget.bookedSlots.isNotEmpty) {
      timeStr = widget.bookedSlots
          .map((s) => "${s.startTime} - ${s.endTime}")
          .join(', ');
    } else {
      timeStr = widget.ticket.time;
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _infoColumn(context, "DATE",
                    DateFormat('EEE, d MMM yyyy').format(widget.ticket.date)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _infoColumn(
                  context,
                  "TIME",
                  timeStr,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  customValue: widget.bookedSlots.isNotEmpty
                      ? Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          alignment: WrapAlignment.end,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _buildSlotChip(widget.bookedSlots.first),
                            if (_isExpanded)
                              ...widget.bookedSlots
                                  .skip(1)
                                  .map((slot) => _buildSlotChip(slot)),
                            if (widget.bookedSlots.length > 1)
                              GestureDetector(
                                onTap: () =>
                                    setState(() => _isExpanded = !_isExpanded),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryDarkGreen
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: AppColors.primaryDarkGreen
                                          .withValues(alpha: 0.25),
                                    ),
                                  ),
                                  child: AppText(
                                    text: _isExpanded
                                        ? "Show less"
                                        : "+${widget.bookedSlots.length - 1} more",
                                    textStyle: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primaryDarkGreen,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        )
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _infoColumn(context, "ORDER ID",
                    "#${IdUtil.formatDisplayId(widget.ticket.displayId)}"),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _infoColumn(
                  context,
                  "PRICE",
                  "₹${widget.ticket.price.toStringAsFixed(0)}",
                  crossAxisAlignment: CrossAxisAlignment.end,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoColumn(BuildContext context, String title, String value,
      {CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start,
      Widget? customValue}) {
    final theme = Theme.of(context);
    final isEnd = crossAxisAlignment == CrossAxisAlignment.end;
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        AppText(
          text: title,
          align: isEnd ? TextAlign.end : TextAlign.start,
          textStyle: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              letterSpacing: 1),
        ),
        const SizedBox(height: 4),
        customValue ??
            AppText(
              text: value,
              textStyle:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              align: isEnd ? TextAlign.end : TextAlign.start,
            ),
      ],
    );
  }

  Widget _buildDashedDivider(BuildContext context) {
    return Row(
      children: [
        _halfCircle(context, isLeft: true),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Flex(
                  direction: Axis.horizontal,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    (constraints.constrainWidth() / 10).floor(),
                    (index) => SizedBox(
                        width: 5,
                        height: 1,
                        child: DecoratedBox(
                            decoration: BoxDecoration(
                                color: Theme.of(context).dividerColor))),
                  ),
                );
              },
            ),
          ),
        ),
        _halfCircle(context, isLeft: false),
      ],
    );
  }

  Widget _halfCircle(BuildContext context, {required bool isLeft}) {
    final theme = Theme.of(context);
    return Container(
      height: 20,
      width: 10,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor, // Use theme bg color
        borderRadius: isLeft
            ? const BorderRadius.only(
                topRight: Radius.circular(10), bottomRight: Radius.circular(10))
            : const BorderRadius.only(
                topLeft: Radius.circular(10), bottomLeft: Radius.circular(10)),
      ),
    );
  }

  Widget _buildQrSection(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: theme.dividerColor),
            borderRadius: BorderRadius.circular(12),
          ),
          child: _QrCodePainter(
            data:
                "${widget.ticket.bookingId} | Ground: ${widget.ticket.venueName} | Owner: ${widget.ticket.ownerId} | Ground ID: ${widget.ticket.groundId}",
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
    );
  }
}

class _QrCodePainter extends StatelessWidget {
  final String data;
  const _QrCodePainter({required this.data});

  @override
  Widget build(BuildContext context) {
    return QrImageView(
      data: data,
      version: QrVersions.auto,
      size: 120.0,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
    );
  }
}

class TicketModel {
  final String bookingId;
  final String groundId;
  final int displayId;
  final String venueName;
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

  TicketModel({
    required this.bookingId,
    required this.groundId,
    required this.displayId,
    required this.venueName,
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
  });
}
