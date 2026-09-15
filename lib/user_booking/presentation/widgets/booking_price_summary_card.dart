import 'package:flutter/material.dart';
import 'package:turfpro/common/constants/colors.dart';
import 'package:turfpro/user_booking/domain/models/booking_summary_data.dart';

class BookingPriceSummaryCard extends StatelessWidget {
  final BookingSummaryData summaryData;
  final String? title;
  final String? totalLabel;
  final bool showSavingsPill;

  const BookingPriceSummaryCard({
    super.key,
    required this.summaryData,
    this.title = "Booking summary",
    this.totalLabel,
    this.showSavingsPill = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null && title!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              title!,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ),

        // Rounded Card Container
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0xFFE5E7EB),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Slot Price
              _buildSummaryInvoiceRow(
                label: "Slot Price",
                value: "₹${summaryData.slotPrice.toStringAsFixed(0)}",
                colorScheme: colorScheme,
              ),
              const SizedBox(height: 12),

              // 2. GST with info icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        "GST",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => showGstInfoDialog(context),
                        child: Icon(
                          Icons.info_outline_rounded,
                          size: 15,
                          color: colorScheme.onSurface.withValues(alpha: 0.45),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    "₹${summaryData.gstAmount.toStringAsFixed(0)}",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 3. Platform Fee (strikethrough + Free when isPlatformFeeFree)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Platform Fee",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  if (summaryData.isPlatformFeeFree)
                    Row(
                      children: [
                        Text(
                          "₹${summaryData.platformFee.toStringAsFixed(0)}",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface.withValues(alpha: 0.4),
                            decoration: TextDecoration.lineThrough,
                            decorationColor:
                                colorScheme.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          "Free",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF22C55E),
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      "₹${summaryData.platformFee.toStringAsFixed(0)}",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                ],
              ),

              // 4. Loyalty Points Rewards (if applied)
              if (summaryData.pointsDiscount > 0) ...[
                const SizedBox(height: 12),
                _buildSummaryInvoiceRow(
                  label: "TurfPro Rewards",
                  value: "-₹${summaryData.pointsDiscount.toStringAsFixed(0)}",
                  valueColor: AppColors.primaryDarkGreen,
                  colorScheme: colorScheme,
                ),
              ],

              // 5. Wallet Balance (if applied)
              if (summaryData.walletDiscount > 0) ...[
                const SizedBox(height: 12),
                _buildSummaryInvoiceRow(
                  label: "TurfPro Wallet",
                  value: "-₹${summaryData.walletDiscount.toStringAsFixed(0)}",
                  valueColor: Colors.blue,
                  colorScheme: colorScheme,
                ),
              ],

              const SizedBox(height: 14),

              // Dashed Horizontal Line Divider
              CustomPaint(
                painter: DashedLinePainter(
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
                    totalLabel ?? "Total Amount to Pay",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    "₹${summaryData.grandTotal.toStringAsFixed(0)}",
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDarkGreen,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Total Savings Pill (if any rewards/convenience discounts applied)
        if (showSavingsPill && summaryData.totalSavings > 0) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.primaryDarkGreen.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  size: 14,
                  color: AppColors.primaryDarkGreen,
                ),
                const SizedBox(width: 6),
                Text(
                  "You saved ₹${summaryData.totalSavings.toStringAsFixed(0)} on this booking!",
                  style: const TextStyle(
                    color: AppColors.primaryDarkGreen,
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  static Widget _buildSummaryInvoiceRow({
    required String label,
    required String value,
    Color? valueColor,
    required ColorScheme colorScheme,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: valueColor ?? colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  static void showGstInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.info_outline_rounded,
                color: AppColors.primaryDarkGreen, size: 20),
            SizedBox(width: 8),
            Text(
              "Goods & Services Tax (GST)",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          "GST is calculated according to statutory regulations for sports facility and venue bookings. If tax exemption applies, GST is ₹0.",
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              "Got it",
              style: TextStyle(
                color: AppColors.primaryDarkGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── DASHED LINE PAINTER ──────────────────────────────────────────
class DashedLinePainter extends CustomPainter {
  final Color color;
  DashedLinePainter({required this.color});

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
