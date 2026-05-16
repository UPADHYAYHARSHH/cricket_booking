// Add for kIsWeb
import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:turfpro/common/constants/colors.dart';
import 'package:turfpro/user_booking/constants/text_theme.dart';
import 'package:turfpro/user_booking/constants/widgets/app_sizedBox.dart';
import 'package:turfpro/user_booking/constants/widgets/app_text.dart';
import 'package:turfpro/user_booking/domain/models/booking_arguments.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
// Already here, good for Web sharing
import 'package:turfpro/utils/toast_util.dart';
// Add our new helper
import 'package:turfpro/utils/ticket_util.dart'; // Add TicketUtil
import 'package:qr_flutter/qr_flutter.dart';
import 'package:turfpro/utils/id_util.dart';
import '../../widgets/ground_image_carousel.dart';
import '../../widgets/slot_selection_widgets.dart';

class BookingConfirmationScreen extends StatefulWidget {
  const BookingConfirmationScreen({super.key});

  @override
  State<BookingConfirmationScreen> createState() =>
      _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen> {
  bool _isSaving = false;

  Future<void> _captureAndSave(
    String groundName,
    String groundAddress,
    String groundImageUrl,
    DateTime date,
    String timeRange,
    String orderId,
    int displayId,
    double totalPrice,
    String sportName,
    String selectedPeriod,
    List<String>? amenities,
  ) async {
    await TicketUtil.downloadTicket(
      context,
      groundName: groundName,
      groundAddress: groundAddress,
      groundImageUrl: groundImageUrl,
      date: date,
      timeRange: timeRange,
      orderId: orderId,
      displayId: displayId,
      totalPrice: totalPrice,
      sportName: sportName,
      selectedPeriod: selectedPeriod,
      amenities: amenities,
      onLoadingStarted: () => setState(() => _isSaving = true),
      onLoadingFinished: () {
        if (mounted) setState(() => _isSaving = false);
      },
    );
  }

  DateTime _parseSlotTime(DateTime baseDate, String timeStr) {
    // Expected format: "09:00 AM" or "09:00 PM"
    try {
      final parts = timeStr.trim().split(' ');
      if (parts.length < 2) {
        // Fallback for formats without AM/PM
        final timeParts = timeStr.split(':');
        return DateTime(
          baseDate.year,
          baseDate.month,
          baseDate.day,
          int.parse(timeParts[0]),
          int.parse(timeParts[1]),
        );
      }

      final timeParts = parts[0].split(':');
      int hour = int.parse(timeParts[0]);
      int minute = int.parse(timeParts[1]);
      final amPm = parts[1].toUpperCase();

      if (amPm == 'PM' && hour < 12) hour += 12;
      if (amPm == 'AM' && hour == 12) hour = 0;

      return DateTime(baseDate.year, baseDate.month, baseDate.day, hour, minute);
    } catch (e) {
      debugPrint("Error parsing slot time '$timeStr': $e");
      return baseDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final rawArgs = ModalRoute.of(context)?.settings.arguments;

    if (rawArgs == null || rawArgs is! BookingSuccessArguments) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const AppSizedBox(height: 16),
              const AppText(text: "Booking information missing"),
              TextButton(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                    context, '/nav', (r) => false),
                child: const Text("Go to Home"),
              )
            ],
          ),
        ),
      );
    }

    final args = rawArgs;
    final ground = args.ground;
    final date = args.date;
    final slots = args.selectedSlots;
    final orderId = args.orderId;
    final displayId = args.displayId;
    final totalPrice = args.totalPrice;

    final timeRange = slots.isEmpty
        ? "No slots selected"
        : "${slots.first.startTime} - ${slots.last.endTime}";

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: colorScheme.onSurface,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: AppText(
          text: "Booking Status",
          textStyle: AppTextTheme.black16.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const AppSizedBox(height: 12),

              /// SUCCESS ICON
              AppSizedBox(
                height: 140,
                width: 140,
                child: Lottie.asset(
                  'assets/animations/Success.json',
                  repeat: false,
                ),
              ),

              const AppSizedBox(height: 8),

              /// TITLE
              AppText(
                text: "Slot Booked\nSuccessfully!",
                align: TextAlign.center,
                textStyle: AppTextTheme.black18.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  color: colorScheme.onSurface,
                ),
              ),

              const AppSizedBox(height: 12),

              /// SUBTITLE
              AppText(
                text:
                    "Get ready to hit some sixes! Your pitch is ready for action.",
                align: TextAlign.center,
                textStyle: AppTextTheme.grey13.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                  height: 1.5,
                  fontSize: 14,
                ),
              ),

              const AppSizedBox(height: 32),

              _VenueCard(ground: ground),
              const AppSizedBox(height: 20),
              _BookingDetailsCard(
                date: date,
                timeRange: timeRange,
                orderId: orderId,
                displayId: displayId,
                totalPrice: totalPrice,
                groundAddress: ground.address,
                sportName: args.sportName,
                period: args.selectedPeriod,
              ),

              const AppSizedBox(height: 20),
              _QRCodeCard(orderId: orderId, displayId: displayId),

              const AppSizedBox(height: 24),
              SlotSelectionWidgets.buildMapSection(
                context,
                latitude: ground.latitude,
                longitude: ground.longitude,
                address: ground.address,
              ),

              const AppSizedBox(height: 32),

              /// DOWNLOAD TICKET
              ElevatedButton.icon(
                onPressed: _isSaving
                    ? null
                    : () => _captureAndSave(
                          ground.name,
                          ground.address,
                          ground.imageUrl,
                          date,
                          timeRange,
                          orderId,
                          displayId,
                          totalPrice,
                          args.sportName,
                          args.selectedPeriod,
                          ground.amenities,
                        ),
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.download_rounded, color: Colors.white),
                label: AppText(
                  text: _isSaving ? "Generating PDF..." : "Download Ticket",
                  textStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDarkGreen,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),

              const AppSizedBox(height: 16),

              /// ADD TO CALENDAR
              OutlinedButton.icon(
                onPressed: () {
                  try {
                    DateTime eventStart = DateTime(
                        date.year, date.month, date.day, 9, 0); // Default 9 AM
                    DateTime eventEnd = DateTime(date.year, date.month,
                        date.day, 10, 0); // Default 10 AM

                    if (slots.isNotEmpty) {
                      eventStart = _parseSlotTime(date, slots.first.startTime);
                      eventEnd = _parseSlotTime(date, slots.last.endTime);

                      // Safety check: if start is after end (e.g. overnight), add a day to end
                      if (eventEnd.isBefore(eventStart)) {
                        eventEnd = eventEnd.add(const Duration(days: 1));
                      }
                    }

                    final Event event = Event(
                      title: 'Cricket Booking @ ${ground.name}',
                      description:
                          'Your turf booking is confirmed.\nOrder ID: #${IdUtil.formatDisplayId(displayId)}\nVenue: ${ground.name}\nAddress: ${ground.address}',
                      location: ground.address,
                      startDate: eventStart,
                      endDate: eventEnd,
                    );

                    Add2Calendar.addEvent2Cal(event).then((success) {
                      if (!success) {
                        ToastUtil.show(context,
                            message:
                                "Could not open calendar. Do you have a calendar app installed?",
                            type: ToastType.error);
                      }
                    });
                  } catch (e) {
                    debugPrint("Calendar Error: $e");
                    ToastUtil.show(context,
                        message:
                            "Failed to create calendar event. Please check formatting.",
                        type: ToastType.error);
                  }
                },
                icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedCalendar01,
                    color: Colors.blueAccent,
                    size: 20),
                label: const AppText(
                  text: "Add to Calendar",
                  textStyle: TextStyle(
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.blueAccent, width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),

              const AppSizedBox(height: 16),

              /// BACK TO HOME
              TextButton(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/nav',
                  (route) => false,
                ),
                child: AppText(
                  text: "Back to Home",
                  textStyle: AppTextTheme.black13.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),

              const AppSizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _VenueCard extends StatelessWidget {
  final dynamic ground;
  const _VenueCard({required this.ground});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
                alpha: theme.brightness == Brightness.dark ? 0.3 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Stack(
              children: [
                GroundImageCarousel(
                  images: ground.images ?? [],
                  fallbackImageUrl: ground.imageUrl ?? "",
                  height: 180,
                  borderRadius: BorderRadius.zero,
                ),
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        text: ground.name ?? "PowerPlay Arena",
                        textStyle: AppTextTheme.white15.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const AppSizedBox(height: 4),
                      GestureDetector(
                        onTap: () => TicketUtil.openMap(
                            ground.latitude, ground.longitude),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on,
                                size: 14, color: Colors.white70),
                            const AppSizedBox(width: 4),
                            Expanded(
                              child: AppText(
                                text: ground.address ?? "Ahmedabad, Gujarat",
                                textStyle: AppTextTheme.white10.copyWith(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.8),
                                  decoration: TextDecoration.underline,
                                  decorationColor:
                                      Colors.white.withValues(alpha: 0.5),
                                ),
                                maxLines: 2,
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
          ),
          if (ground.amenities != null && ground.amenities.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 12,
                runSpacing: 8,
                children: (ground.amenities as List<dynamic>).map<Widget>((amenity) {
                  return _buildAmenity(amenity.toString());
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAmenity(String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        HugeIcon(
          icon: SlotSelectionWidgets.getAmenityHugeIcon(label),
          size: 14,
          color: AppColors.primaryDarkGreen,
        ),
        const AppSizedBox(width: 6),
        AppText(
          text: label,
          textStyle: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}

class _BookingDetailsCard extends StatelessWidget {
  final DateTime date;
  final String timeRange;
  final String orderId;
  final int displayId;
  final double totalPrice;
  final String sportName;
  final String groundAddress;
  final String period;

  const _BookingDetailsCard({
    required this.date,
    required this.timeRange,
    required this.orderId,
    required this.displayId,
    required this.totalPrice,
    required this.groundAddress,
    required this.sportName,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          _buildDetailRow(
            context,
            "Venue Address",
            groundAddress,
            Icons.location_on_outlined,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          Row(
            children: [
              Expanded(
                child: _buildDetailRow(
                  context,
                  "Sport",
                  sportName,
                  Icons.sports_cricket_outlined,
                ),
              ),
              Expanded(
                child: _buildDetailRow(
                  context,
                  "Period",
                  period,
                  Icons.wb_sunny_outlined,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          _buildDetailRow(
            context,
            "Date",
            DateFormat('EEEE, d MMMM yyyy').format(date),
            Icons.calendar_today_outlined,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          _buildDetailRow(
            context,
            "Time Slot",
            timeRange,
            Icons.access_time_rounded,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          _buildDetailRow(
            context,
            "Booking ID",
            "#${IdUtil.formatDisplayId(displayId)}",
            Icons.confirmation_number_outlined,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText(
                text: "Total Amount",
                textStyle: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              AppText(
                text: "₹${totalPrice.toStringAsFixed(0)}",
                textStyle: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryDarkGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildDetailRow(
      BuildContext context, String label, String value, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryDarkGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColors.primaryDarkGreen),
        ),
        const AppSizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(
              text: label,
              textStyle: AppTextTheme.grey11.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
            const AppSizedBox(height: 2),
            AppText(
              text: value,
              textStyle: AppTextTheme.black13.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QRCodeCard extends StatelessWidget {
  final String orderId;
  final int displayId;
  const _QRCodeCard({required this.orderId, required this.displayId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          const AppText(
            text: "Entry QR Code",
            textStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const AppSizedBox(height: 4),
          AppText(
            text: "Show this at the venue for verification",
            textStyle: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const AppSizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: QrImageView(
              data: orderId,
              version: QrVersions.auto,
              size: 160.0,
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
            ),
          ),
          const AppSizedBox(height: 16),
          AppText(
            text: "#${IdUtil.formatDisplayId(displayId)}",
            textStyle: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              color: AppColors.primaryDarkGreen,
            ),
          ),
        ],
      ),
    );
  }
}

