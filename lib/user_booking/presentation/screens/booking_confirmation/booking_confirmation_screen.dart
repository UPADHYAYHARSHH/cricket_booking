// Add for kIsWeb
import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:bloc_structure/common/constants/colors.dart';
import 'package:bloc_structure/user_booking/constants/text_theme.dart';
import 'package:bloc_structure/user_booking/constants/widgets/app_sizedBox.dart';
import 'package:bloc_structure/user_booking/constants/widgets/app_text.dart';
import 'package:bloc_structure/user_booking/domain/models/booking_arguments.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
// Already here, good for Web sharing
import 'package:bloc_structure/utils/toast_util.dart';
// Add our new helper
import 'package:bloc_structure/utils/ticket_util.dart'; // Add TicketUtil

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
    double totalPrice,
  ) async {
    await TicketUtil.downloadTicket(
      context,
      groundName: groundName,
      groundAddress: groundAddress,
      groundImageUrl: groundImageUrl,
      date: date,
      timeRange: timeRange,
      orderId: orderId,
      totalPrice: totalPrice,
      onLoadingStarted: () => setState(() => _isSaving = true),
      onLoadingFinished: () {
        if (mounted) setState(() => _isSaving = false);
      },
    );
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
    final totalPrice = args.totalPrice;

    final timeRange = slots.isEmpty
        ? "No slots selected"
        : "${slots.first.startTime} - ${slots.last.endTime}";

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
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
        physics: const BouncingScrollPhysics(),
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
                totalPrice: totalPrice,
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
                          totalPrice,
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
                      // Parse start time (Expected format "HH:mm" or "H:mm")
                      final startStr = slots.first.startTime;
                      final startParts = startStr.contains(':')
                          ? startStr.split(':')
                          : [startStr, "00"];
                      eventStart = DateTime(
                        date.year,
                        date.month,
                        date.day,
                        int.parse(startParts[0]),
                        int.parse(startParts[1]),
                      );

                      // Parse end time
                      final endStr = slots.last.endTime;
                      final endParts = endStr.contains(':')
                          ? endStr.split(':')
                          : [endStr, "00"];
                      eventEnd = DateTime(
                        date.year,
                        date.month,
                        date.day,
                        int.parse(endParts[0]),
                        int.parse(endParts[1]),
                      );

                      // Safety check: if start is after end (e.g. overnight), add a day to end
                      if (eventEnd.isBefore(eventStart)) {
                        eventEnd = eventEnd.add(const Duration(days: 1));
                      }
                    }

                    final Event event = Event(
                      title: 'Cricket Booking @ ${ground.name}',
                      description:
                          'Your turf booking is confirmed.\nOrder ID: #$orderId\nVenue: ${ground.name}\nAddress: ${ground.address}',
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
                SizedBox(
                  height: 160,
                  width: double.infinity,
                  child: Image.network(
                    ground.imageUrl ??
                        "https://images.unsplash.com/photo-1540747913346-19e32dc3e97e",
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: Icon(Icons.sports_cricket,
                            size: 40, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
                Container(
                  height: 160,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.6),
                      ],
                    ),
                  ),
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
                      Row(
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
                              ),
                              maxLines: 1,
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildAmenity(Icons.wifi, "Free WiFi"),
                const AppSizedBox(width: 16),
                _buildAmenity(Icons.local_parking, "Parking"),
                const AppSizedBox(width: 16),
                _buildAmenity(Icons.wc, "Washroom"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmenity(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primaryDarkGreen),
        const AppSizedBox(width: 6),
        AppText(
          text: label,
          textStyle: AppTextTheme.grey11.copyWith(
            fontWeight: FontWeight.w600,
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
  final double totalPrice;

  const _BookingDetailsCard({
    required this.date,
    required this.timeRange,
    required this.orderId,
    required this.totalPrice,
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
            "#$orderId",
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
                textStyle: AppTextTheme.black15.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              AppText(
                text: "₹${totalPrice.toStringAsFixed(0)}",
                textStyle: AppTextTheme.black18.copyWith(
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
