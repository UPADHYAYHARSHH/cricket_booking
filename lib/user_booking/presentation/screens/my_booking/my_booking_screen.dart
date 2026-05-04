import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math';
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
import 'package:supabase_flutter/supabase_flutter.dart';

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
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: AppText(
        text: "My Bookings",
        textStyle: AppTextTheme.black18.copyWith(
          fontSize: 26,
          fontWeight: FontWeight.w700,
        ),
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
              color: isSelected ? AppColors.white : theme.colorScheme.onSurface.withValues(alpha: 0.6),
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
          return Center(child: AppText(text: state.message, textStyle: AppTextTheme.grey13));
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
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final rated = await getIt<ReviewRepository>().hasUserRatedGround(user.id, widget.booking.groundId);
      if (mounted) {
        setState(() {
          _hasRated = rated;
          _isLoadingRating = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoadingRating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopRow(context),
          const Divider(height: 1, thickness: 0.5),
          _buildDetailsRow(context),
          _buildFooterRow(context),
        ],
      ),
    );
  }

  Widget _buildTopRow(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: widget.booking.ground?.imageUrl != null
                  ? DecorationImage(
                      image: NetworkImage(widget.booking.ground!.imageUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
              color: theme.brightness == Brightness.dark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
            ),
            child: widget.booking.ground?.imageUrl == null ? Icon(Icons.sports_cricket, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  text: widget.booking.ground?.name ?? "Venue Name",
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                AppText(
                  text: widget.booking.ground?.address ?? "Location not available",
                  textStyle: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                  maxLines: 1,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: widget.booking.status.toLowerCase() == 'confirmed' || widget.booking.status.toLowerCase() == 'paid' ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: AppText(
              text: widget.booking.status.toUpperCase(),
              textStyle: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: widget.booking.status.toLowerCase() == 'confirmed' || widget.booking.status.toLowerCase() == 'paid' ? Colors.green : Colors.orange,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsRow(BuildContext context) {
    final dateStr = DateFormat('EEE, d MMM yyyy').format(widget.booking.slotTime);
    final timeStr = DateFormat('hh:mm a').format(widget.booking.slotTime);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _infoItem(context, Icons.calendar_today_outlined, dateStr),
          _infoItem(context, Icons.access_time, timeStr),
          _infoItem(context, Icons.payments_outlined, "₹${widget.booking.amount}"),
        ],
      ),
    );
  }

  Widget _infoItem(BuildContext context, IconData icon, String label) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 14, color: theme.colorScheme.primary),
        const SizedBox(width: 6),
        AppText(
          text: label,
          textStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFooterRow(BuildContext context) {
    final now = DateTime.now();
    // Rating button only appears if the booking time has fully passed
    final isPast = widget.booking.slotTime.isBefore(now);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _viewTicket(context),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const AppText(
                    text: "View Ticket",
                    textStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              if (isPast) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _rebook(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDarkGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      elevation: 0,
                    ),
                    child: const AppText(
                      text: "Rebook",
                      textStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (isPast && !_isLoadingRating && !_hasRated) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showRatingSheet(context),
                icon: const Icon(Icons.star_rate_rounded, size: 18),
                label: const Text("Rate Your Match Experience"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showRatingSheet(BuildContext context) async {
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
            isPaid: widget.booking.status == 'paid' || widget.booking.status == 'confirmed',
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

  Future<void> _generateAndDownload() async {
    await TicketUtil.downloadTicket(
      context,
      groundName: widget.ticket.venueName,
      groundAddress: widget.ticket.location,
      groundImageUrl: widget.ticket.imageUrl,
      date: widget.ticket.date,
      timeRange: widget.ticket.time,
      orderId: widget.ticket.bookingId,
      displayId: widget.ticket.displayId,
      totalPrice: widget.ticket.price,
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
          icon: Icon(Icons.arrow_back_ios_new, size: 20, color: theme.colorScheme.onSurface),
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
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.download_rounded, color: Colors.white),
            label: Text(
              _isSaving ? "Generating PDF..." : "Download Ticket",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDarkGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.share_outlined, color: AppColors.primaryDarkGreen),
            label: const Text("Share with Friends", style: TextStyle(color: AppColors.primaryDarkGreen, fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primaryDarkGreen),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }
}

class _TicketCard extends StatelessWidget {
  final TicketModel ticket;
  final VoidCallback onLocationTap;

  const _TicketCard({required this.ticket, required this.onLocationTap});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(theme.brightness == Brightness.dark ? 0.3 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        children: [
          _buildVenueImage(context),
          _buildTicketInfo(context),
          _buildDashedDivider(context),
          _buildQrSection(context),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildVenueImage(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Stack(
        children: [
          Image.network(
            ticket.imageUrl,
            height: 150,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: theme.brightness == Brightness.dark ? Colors.white10 : Colors.black.withOpacity(0.05), height: 150),
          ),
          Container(
            height: 150,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
              ),
            ),
          ),
          Positioned(
            bottom: 12,
            left: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: onLocationTap,
                  child: Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.white.withOpacity(0.8), size: 14),
                      const SizedBox(width: 4),
                      Expanded(
                        child: AppText(
                          text: ticket.location,
                          textStyle: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.white.withOpacity(0.5),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketInfo(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _infoColumn(context, "DATE", DateFormat('EEE, d MMM yyyy').format(ticket.date)),
              _infoColumn(context, "TIME", ticket.time),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _infoColumn(context, "ORDER ID", "#${IdUtil.formatDisplayId(ticket.displayId)}"),
              _infoColumn(context, "PRICE", "₹${ticket.price.toStringAsFixed(0)}"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoColumn(BuildContext context, String title, String value) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          text: title,
          textStyle: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface.withOpacity(0.4),
              letterSpacing: 1),
        ),
        const SizedBox(height: 4),
        AppText(
          text: value,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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
                    (index) => SizedBox(width: 5, height: 1, child: DecoratedBox(decoration: BoxDecoration(color: Theme.of(context).dividerColor))),
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
          child: _QrCodePainter(data: ticket.bookingId),
        ),
        const SizedBox(height: 12),
        AppText(
          text: "Scan at entrance",
          textStyle: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.4)),
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
  final bool isPaid;

  TicketModel({
    required this.bookingId,
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
    required this.isPaid,
  });
}
