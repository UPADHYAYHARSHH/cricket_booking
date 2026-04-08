import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'dart:math';

import '../../../../common/constants/colors.dart';
import '../../../constants/text_theme.dart';
import '../../../constants/widgets/app_sizedBox.dart';
import '../../../constants/widgets/app_text.dart';
import '../../blocs/booking/booking_cubit.dart';
import '../../blocs/booking/booking_state.dart';
import '../../../data/models/booking_model.dart';



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
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
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
              color: isSelected ? AppColors.white : theme.colorScheme.onSurface.withOpacity(0.6),
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
          return Center(child: AppText(text: state.message, textStyle: AppTextTheme.grey13));
        }

        if (state is BookingLoaded) {
          final now = DateTime.now();
          final bookings = state.bookings.where((b) {
            if (_selectedTab == 0) {
              return b.slotTime.isAfter(now);
            } else {
              return b.slotTime.isBefore(now);
            }
          }).toList();

          if (bookings.isEmpty) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today_outlined, size: 56, color: Theme.of(context).dividerColor),
                AppSizedBox(height: 12),
                AppText(
                  text: "No bookings yet",
                  textStyle: AppTextTheme.grey13,
                ),
              ],
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

class _BookingCard extends StatelessWidget {
  final BookingModel booking;

  const _BookingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImage(),
          _buildInfo(),
          _buildActions(context),
          const AppSizedBox(height: 14),
        ],
      ),
    );
  }

  Widget _buildImage() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: Image.network(
            booking.ground?.imageUrl ?? '',
            height: 150,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              height: 150,
              color: Colors.grey.shade200,
              child: const Icon(Icons.image_not_supported),
            ),
          ),
        ),
        Positioned(
          top: 12,
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.accentOrange,
              borderRadius: BorderRadius.circular(20),
            ),
            child: AppText(
              text: booking.status.toUpperCase(),
              textStyle: AppTextTheme.white10.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: .5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfo() {
    final title = booking.ground?.name ?? "Unknown Venue";
    final timeStr = DateFormat('EEE, d MMM • hh:mm a').format(booking.slotTime);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  text: title,
                  textStyle: AppTextTheme.black14.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const AppSizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 13, color: AppColors.textSecondaryLight),
                    const AppSizedBox(width: 5),
                    Expanded(
                      child: AppText(
                        text: timeStr,
                        textStyle: AppTextTheme.grey12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AppText(
                text: "PRICE",
                textStyle: AppTextTheme.grey12.copyWith(fontSize: 10),
              ),
              AppText(
                text: "₹${booking.amount.toStringAsFixed(0)}",
                textStyle: AppTextTheme.black16.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: _viewTicketButton(context),
    );
  }

  Widget _viewTicketButton(BuildContext context) {
    return OutlinedButton(
      onPressed: () {
        final userName = "User"; // Generic for now or fetch from Supabase if needed

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ViewTicketScreen(
              ticket: TicketModel(
                bookingId: booking.razorpayOrderId,
                venueName: booking.ground?.name ?? "Venue",
                pitchName: "Pitch", // Slot info not fully captured in booking table yet
                date: DateFormat('EEE, d MMM yyyy').format(booking.slotTime),
                time: DateFormat('hh:mm a').format(booking.slotTime),
                bookedBy: userName,
                location: booking.ground?.address ?? "Location",
                price: booking.amount,
                imageUrl: booking.ground?.imageUrl ?? "",
                isPaid: booking.status == 'paid',
              ),
            ),
          ),
        );
      },
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppColors.primaryDarkGreen, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: AppText(
        text: "View Ticket",
        textStyle: AppTextTheme.black13.copyWith(
          color: AppColors.primaryDarkGreen,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// Removing local _BookingModel in favor of the real BookingModel
// Removing local _paymentButton since payments are handled elsewhere now

class ViewTicketScreen extends StatelessWidget {
  final TicketModel ticket;

  const ViewTicketScreen({super.key, required this.ticket});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(Icons.arrow_back_ios_new, size: 16, color: theme.colorScheme.onSurface),
          ),
        ),
        title: AppText(
          text: "My Ticket",
          textStyle: AppTextTheme.black18.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Ticket shared!"),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.all(10),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(Icons.share_outlined, size: 16, color: theme.colorScheme.onSurface),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          children: [
            _TicketCard(ticket: ticket),
            const SizedBox(height: 24),
            _buildDownloadButton(context),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: () {
          HapticFeedback.mediumImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Ticket downloaded to gallery!"),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        icon: const Icon(Icons.download_rounded, color: Colors.white),
        label: const Text(
          "Download Ticket",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryDarkGreen,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}

// ─── Ticket Card ──────────────────────────────────────────────────────────────

class _TicketCard extends StatelessWidget {
  final TicketModel ticket;

  const _TicketCard({required this.ticket});
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        // ── Top half ──
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              _buildVenueImage(),
              _buildVenueInfo(context),
              _buildDividerRow(context),
              _buildDetailsGrid(context),
            ],
          ),
        ),

        // ── Tear line ──
        _TearLine(),

        // ── Bottom half ──
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
          child: Column(
            children: [
              _buildQrSection(context),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVenueImage() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: Image.network(
            ticket.imageUrl,
            height: 160,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              height: 160,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: const Icon(Icons.sports_cricket, size: 56, color: Colors.grey),
            ),
          ),
        ),
        // Dark gradient overlay
        Positioned.fill(
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.55),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Status badge
        Positioned(
          top: 14,
          right: 14,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: ticket.isPaid ? AppColors.primaryDarkGreen : AppColors.accentOrange,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  ticket.isPaid ? Icons.check_circle_outline : Icons.schedule,
                  size: 12,
                  color: Colors.white,
                ),
                const SizedBox(width: 4),
                Text(
                  ticket.isPaid ? "CONFIRMED" : "PENDING PAYMENT",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Booking ID badge
        Positioned(
          bottom: 12,
          left: 14,
          child: Text(
            "# ${ticket.bookingId}",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVenueInfo(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryDarkGreen.withOpacity(isDark ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.sports_cricket, color: AppColors.primaryDarkGreen, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  text: ticket.venueName,
                  textStyle: AppTextTheme.black17.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                AppText(
                  text: ticket.pitchName,
                  textStyle: AppTextTheme.grey13,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AppText(
                text: "PRICE",
                textStyle: AppTextTheme.grey11.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
              AppText(
                text: "₹${ticket.price.toStringAsFixed(0)}",
                textStyle: AppTextTheme.black18.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDividerRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(color: Theme.of(context).dividerColor.withOpacity(0.5), thickness: 1.5),
    );
  }

  Widget _buildDetailsGrid(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _DetailTile(
                  icon: Icons.calendar_today_outlined,
                  label: "Date",
                  value: ticket.date,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DetailTile(
                  icon: Icons.access_time_rounded,
                  label: "Time",
                  value: ticket.time,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _DetailTile(
                  icon: Icons.sports_score_outlined,
                  label: "Pitch",
                  value: ticket.pitchName,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DetailTile(
                  icon: Icons.person_outline_rounded,
                  label: "Booked By",
                  value: ticket.bookedBy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _DetailTile(
            icon: Icons.location_on_outlined,
            label: "Location",
            value: ticket.location,
            fullWidth: true,
          ),
        ],
      ),
    );
  }

  Widget _buildQrSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Column(
        children: [
          AppText(
            text: "Scan at Venue",
            textStyle: AppTextTheme.grey13.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primaryDarkGreen.withOpacity(0.18), width: 2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: _QrCodePainter(data: ticket.bookingId),
          ),
          const SizedBox(height: 14),
          AppText(
            text: ticket.bookingId,
            textStyle: AppTextTheme.black14.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 4),
          AppText(
            text: "Show this QR at the venue entrance",
            textStyle: AppTextTheme.grey11,
          ),
        ],
      ),
    );
  }
}

// ─── Detail Tile ──────────────────────────────────────────────────────────────

class _DetailTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool fullWidth;

  const _DetailTile({
    required this.icon,
    required this.label,
    required this.value,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark 
            ? theme.colorScheme.surface.withOpacity(0.5) 
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withOpacity(isDark ? 0.1 : 0.05)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primaryDarkGreen),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  text: label,
                  textStyle: AppTextTheme.grey11,
                ),
                AppText(
                  text: value,
                  textStyle: AppTextTheme.black12.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tear Line ────────────────────────────────────────────────────────────────

class _TearLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surface,
      child: Row(
        children: [
          _semiCircle(context, isLeft: true),
          Expanded(
            child: LayoutBuilder(
              builder: (_, constraints) {
                final count = (constraints.maxWidth / 10).floor();
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    count,
                    (_) => Container(
                      width: 5,
                      height: 1.5,
                      color: theme.dividerColor.withOpacity(0.2),
                    ),
                  ),
                );
              },
            ),
          ),
          _semiCircle(context, isLeft: false),
        ],
      ),
    );
  }

  Widget _semiCircle(BuildContext context, {required bool isLeft}) {
    return Container(
      width: 18,
      height: 36,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: isLeft
            ? const BorderRadius.only(
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
              )
            : const BorderRadius.only(
                topLeft: Radius.circular(18),
                bottomLeft: Radius.circular(18),
              ),
      ),
    );
  }
}

// ─── QR Code Painter (Fake) ───────────────────────────────────────────────────

class _QrCodePainter extends StatelessWidget {
  final String data;

  const _QrCodePainter({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CustomPaint(
      size: const Size(160, 160),
      painter: _QrPainter(
        seed: data.hashCode,
        color: theme.colorScheme.onSurface,
      ),
    );
  }
}

class _QrPainter extends CustomPainter {
  final int seed;
  final Color color;

  _QrPainter({required this.seed, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final rng = Random(seed);
    final cellSize = size.width / 21;

    // Draw QR-style grid
    for (int row = 0; row < 21; row++) {
      for (int col = 0; col < 21; col++) {
        bool draw = false;

        // Corner finder patterns
        if (_isFinderPattern(row, col)) {
          draw = _finderPatternCell(row, col);
        } else {
          draw = rng.nextBool();
        }

        if (draw) {
          canvas.drawRect(
            Rect.fromLTWH(
              col * cellSize + 0.5,
              row * cellSize + 0.5,
              cellSize - 1,
              cellSize - 1,
            ),
            paint,
          );
        }
      }
    }
  }

  bool _isFinderPattern(int row, int col) {
    return (row < 8 && col < 8) || (row < 8 && col >= 13) || (row >= 13 && col < 8);
  }

  bool _finderPatternCell(int row, int col) {
    // Normalize to 0-7
    int r = row < 8 ? row : row - 13;
    int c = col < 8 ? col : col - 13;
    if (r == 0 || r == 6) return c >= 0 && c <= 6;
    if (c == 0 || c == 6) return r >= 0 && r <= 6;
    if (r >= 2 && r <= 4 && c >= 2 && c <= 4) return true;
    return false;
  }

  @override
  bool shouldRepaint(covariant _QrPainter old) => old.seed != seed;
}

// ─── Model ────────────────────────────────────────────────────────────────────

class TicketModel {
  final String bookingId;
  final String venueName;
  final String pitchName;
  final String date;
  final String time;
  final String bookedBy;
  final String location;
  final double price;
  final String imageUrl;
  final bool isPaid;

  const TicketModel({
    required this.bookingId,
    required this.venueName,
    required this.pitchName,
    required this.date,
    required this.time,
    required this.bookedBy,
    required this.location,
    required this.price,
    required this.imageUrl,
    required this.isPaid,
  });
}
