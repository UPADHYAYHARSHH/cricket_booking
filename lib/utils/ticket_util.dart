import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:file_picker/file_picker.dart';
import 'package:printing/printing.dart';
import 'package:turfpro/utils/toast_util.dart';
import 'package:turfpro/utils/file_save_helper.dart';

// ─────────────────────────────────────────────────────
//  PDF Colour palette  (mirrors user's requested design)
// ─────────────────────────────────────────────────────
const _kGreen = PdfColor.fromInt(0xFF2D6A4F);
const _kLightGreen = PdfColor.fromInt(0xFF95D5B2);
const _kDark = PdfColor.fromInt(0xFF1A1A2E);
const _kGrey = PdfColor.fromInt(0xFF6B7280);
const _kBorder = PdfColor.fromInt(0xFFE5E7EB);
const _kBg = PdfColor.fromInt(0xFFF9FAFB);
const _kWhite = PdfColors.white;

class TicketUtil {
  /// Entry point for downloading a ticket.
  /// [onLoadingStarted] and [onLoadingFinished] used to manage loading state in UI.
  static Future<void> downloadTicket(
    BuildContext context, {
    required String groundName,
    required String groundAddress,
    required String groundImageUrl,
    required DateTime date,
    required String timeRange,
    required String orderId,
    required double totalPrice,
    VoidCallback? onLoadingStarted,
    VoidCallback? onLoadingFinished,
  }) async {
    try {
      if (onLoadingStarted != null) onLoadingStarted();

      final pdfBytes = await _buildTicketPdf(
        groundName: groundName,
        groundAddress: groundAddress,
        groundImageUrl: groundImageUrl,
        date: date,
        timeRange: timeRange,
        orderId: orderId,
        totalPrice: totalPrice,
      );

      final fileName = 'cricbook_ticket_${DateTime.now().millisecondsSinceEpoch}.pdf';

      if (kIsWeb) {
        // WEB Download
        await Printing.sharePdf(bytes: pdfBytes, filename: fileName);
        if (context.mounted) {
          ToastUtil.show(context, message: "Ticket download started", type: ToastType.success);
        }
      } else {
        // NATIVE Save
        String? outputFile = await FilePicker.saveFile(
          dialogTitle: 'Save Ticket',
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: ['pdf'],
          bytes: pdfBytes,
        );

        if (outputFile != null) {
          if (!outputFile.toLowerCase().endsWith('.pdf')) {
            outputFile += '.pdf';
          }

          final isMobile = defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS;

          if (!isMobile) {
            await FileSaveHelper.saveFile(outputFile, pdfBytes);
          }

          if (context.mounted) {
            ToastUtil.show(context, message: "Ticket saved successfully", type: ToastType.success);
          }
        }
      }
    } catch (e) {
      debugPrint("Error generating ticket: $e");
      if (context.mounted) {
        ToastUtil.show(context, message: "Error saving ticket: $e", type: ToastType.error);
      }
    } finally {
      if (onLoadingFinished != null) onLoadingFinished();
    }
  }

  static Future<Uint8List> _buildTicketPdf({
    required String groundName,
    required String groundAddress,
    required String groundImageUrl,
    required DateTime date,
    required String timeRange,
    required String orderId,
    required double totalPrice,
  }) async {
    final pdf = pw.Document();

    // ── Try to fetch ground image ──────────────────────
    pw.MemoryImage? venueImage;
    try {
      final netImage = await networkImage(groundImageUrl);
      venueImage = netImage as pw.MemoryImage?;
    } catch (_) {}

    // ── Formatted values ──────────────────────────────
    final formattedDate = DateFormat('EEEE, d MMMM yyyy').format(date);
    final formattedPrice = '₹${totalPrice.toStringAsFixed(0)}';
    final shortId = orderId.length > 10 ? orderId.substring(0, 10) : orderId;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(0),
        build: (pw.Context ctx) {
          return pw.Column(
            children: [
              // HEADER
              pw.Container(
                width: double.infinity,
                color: _kGreen,
                padding: const pw.EdgeInsets.fromLTRB(40, 36, 40, 32),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      children: [
                        pw.Container(
                          width: 36,
                          height: 36,
                          decoration: pw.BoxDecoration(
                            color: _kLightGreen,
                            borderRadius: pw.BorderRadius.circular(8),
                          ),
                          alignment: pw.Alignment.center,
                          child: pw.Text(
                            'C',
                            style: pw.TextStyle(
                              color: _kGreen,
                              fontSize: 20,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                        pw.SizedBox(width: 10),
                        pw.Text(
                          'CricBook',
                          style: pw.TextStyle(
                            color: _kWhite,
                            fontSize: 22,
                            fontWeight: pw.FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        pw.Spacer(),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: pw.BoxDecoration(
                            color: _kLightGreen,
                            borderRadius: pw.BorderRadius.circular(20),
                          ),
                          child: pw.Text(
                            'CONFIRMED',
                            style: pw.TextStyle(
                              color: _kGreen,
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 28),
                    pw.Text(
                      'Booking Ticket',
                      style: pw.TextStyle(
                        color: _kWhite.withAlpha(0.7),
                        fontSize: 12,
                        letterSpacing: 2,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      groundName,
                      style: pw.TextStyle(
                        color: _kWhite,
                        fontSize: 28,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      children: [
                        pw.Text('📍  ', style: const pw.TextStyle(fontSize: 11)),
                        pw.Text(
                          groundAddress,
                          style: pw.TextStyle(color: _kLightGreen, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // VENUE IMAGE STRIP
              if (venueImage != null)
                pw.Container(
                  width: double.infinity,
                  height: 140,
                  child: pw.Image(venueImage, fit: pw.BoxFit.cover),
                ),

              // TICKET BODY
              pw.Expanded(
                child: pw.Container(
                  color: _kBg,
                  padding: const pw.EdgeInsets.fromLTRB(40, 32, 40, 0),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'BOOKING DETAILS',
                        style: pw.TextStyle(
                          color: _kGrey,
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 1.8,
                        ),
                      ),
                      pw.SizedBox(height: 16),
                      pw.Container(
                        width: double.infinity,
                        padding: const pw.EdgeInsets.all(24),
                        decoration: pw.BoxDecoration(
                          color: _kWhite,
                          borderRadius: pw.BorderRadius.circular(12),
                          border: pw.Border.all(color: _kBorder, width: 1),
                        ),
                        child: pw.Column(
                          children: [
                            _pdfDetailRow('Date', formattedDate),
                            _pdfDivider(),
                            _pdfDetailRow('Time Slot', timeRange),
                            _pdfDivider(),
                            _pdfDetailRow('Booking ID', '#$orderId'),
                            _pdfDivider(),
                            _pdfDetailRow('Status', 'Payment Successful ✓'),
                          ],
                        ),
                      ),
                      pw.SizedBox(height: 24),
                      pw.Container(
                        width: double.infinity,
                        padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                        decoration: pw.BoxDecoration(
                          color: _kGreen,
                          borderRadius: pw.BorderRadius.circular(12),
                        ),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  'TOTAL PAID',
                                  style: pw.TextStyle(
                                    color: _kLightGreen,
                                    fontSize: 10,
                                    letterSpacing: 1.4,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                                pw.SizedBox(height: 4),
                                pw.Text(
                                  formattedPrice,
                                  style: pw.TextStyle(
                                    color: _kWhite,
                                    fontSize: 30,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.end,
                              children: [
                                pw.Text(
                                  'Razorpay · Secured',
                                  style: pw.TextStyle(color: _kWhite.withAlpha(0.6), fontSize: 9),
                                ),
                                pw.SizedBox(height: 4),
                                pw.Text(
                                  DateFormat('dd MMM yyyy').format(DateTime.now()),
                                  style: pw.TextStyle(color: _kWhite.withAlpha(0.8), fontSize: 10),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      pw.SizedBox(height: 24),
                      pw.Container(
                        width: double.infinity,
                        padding: const pw.EdgeInsets.all(18),
                        decoration: pw.BoxDecoration(
                          color: _kLightGreen.withAlpha(0.15),
                          borderRadius: pw.BorderRadius.circular(10),
                          border: pw.Border.all(color: _kLightGreen.withAlpha(0.4), width: 1),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              '🏏  How to use this ticket',
                              style: pw.TextStyle(color: _kGreen, fontSize: 11, fontWeight: pw.FontWeight.bold),
                            ),
                            pw.SizedBox(height: 8),
                            _pdfBullet('Show this PDF at the venue entrance.'),
                            _pdfBullet('Arrive 10 minutes before your slot starts.'),
                            _pdfBullet('Cancellations must be done 2 hours prior.'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // PERFORATED TEAR-OFF SEPARATOR
              _pdfTearLine(),

              // STUB
              pw.Container(
                color: _kWhite,
                padding: const pw.EdgeInsets.fromLTRB(40, 20, 40, 28),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('BOOKING REF', style: pw.TextStyle(color: _kGrey, fontSize: 8, letterSpacing: 1.5)),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          '#$shortId',
                          style: pw.TextStyle(color: _kDark, fontSize: 15, fontWeight: pw.FontWeight.bold, letterSpacing: 1),
                        ),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.Text(
                          DateFormat('d MMM').format(date).toUpperCase(),
                          style: pw.TextStyle(color: _kGreen, fontSize: 13, fontWeight: pw.FontWeight.bold, letterSpacing: 1),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(timeRange, style: pw.TextStyle(color: _kGrey, fontSize: 10)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('TOTAL', style: pw.TextStyle(color: _kGrey, fontSize: 8, letterSpacing: 1.5)),
                        pw.SizedBox(height: 4),
                        pw.Text(formattedPrice, style: pw.TextStyle(color: _kGreen, fontSize: 15, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),

              // FOOTER
              pw.Container(
                color: _kDark,
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'cricbook.app  ·  support@cricbook.app',
                      style: pw.TextStyle(color: _kWhite.withAlpha(0.4), fontSize: 9),
                    ),
                    pw.Text(
                      'Generated ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
                      style: pw.TextStyle(color: _kWhite.withAlpha(0.4), fontSize: 9),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _pdfDetailRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 10),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(color: _kGrey, fontSize: 11)),
          pw.Text(value, style: pw.TextStyle(color: _kDark, fontSize: 11, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  static pw.Widget _pdfDivider() => pw.Divider(color: _kBorder, thickness: 0.8);

  static pw.Widget _pdfBullet(String text) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('• ', style: pw.TextStyle(color: _kGreen, fontSize: 10)),
            pw.Expanded(child: pw.Text(text, style: pw.TextStyle(color: _kGrey, fontSize: 10))),
          ],
        ),
      );

  static pw.Widget _pdfTearLine() {
    return pw.Container(
      height: 20,
      width: double.infinity,
      color: _kBg,
      child: pw.CustomPaint(
        painter: (canvas, size) {
          const dashWidth = 6.0;
          const gap = 5.0;
          double x = 0;
          while (x < size.x) {
            canvas.drawLine(x, size.y / 2, x + dashWidth, size.y / 2);
            canvas.setStrokeColor(_kBorder);
            canvas.setLineWidth(1.2);
            canvas.strokePath();
            x += dashWidth + gap;
          }
        },
      ),
    );
  }
}
