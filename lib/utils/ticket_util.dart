import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:file_picker/file_picker.dart';
import 'package:printing/printing.dart';
import 'package:turfpro/utils/toast_util.dart';
import 'package:turfpro/utils/file_save_helper.dart';
import 'package:turfpro/utils/id_util.dart';
import 'package:open_filex/open_filex.dart';

import 'package:url_launcher/url_launcher.dart';

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
  static Future<void> openMap(double lat, double lng) async {
    final String googleUrl =
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    final Uri url = Uri.parse(googleUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Could not launch $googleUrl');
    }
  }

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
    required int displayId,
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
        displayId: displayId,
        totalPrice: totalPrice,
      );

      final fileName =
          'cricbook_ticket_${DateTime.now().millisecondsSinceEpoch}.pdf';

      if (kIsWeb) {
        await Printing.sharePdf(bytes: pdfBytes, filename: fileName);
      } else {
        final isMobile = defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS;

        if (isMobile) {
          // ✅ Save to device storage
          final dir = await getTemporaryDirectory();
          final filePath = '${dir.path}/$fileName';

          final file = File(filePath);
          await file.writeAsBytes(pdfBytes);

          if (context.mounted) {
            ToastUtil.show(context,
                message: "Ticket saved successfully", type: ToastType.success);
          }

          // ✅ Open using OS default app
          final result = await OpenFilex.open(filePath);

          debugPrint("Open result: ${result.message}");
        } else {
          // Desktop flow
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

            await FileSaveHelper.saveFile(outputFile, pdfBytes);

            if (context.mounted) {
              ToastUtil.show(context,
                  message: "Ticket saved successfully",
                  type: ToastType.success);
            }

            await OpenFilex.open(outputFile);
          }
        }
      }
    } catch (e) {
      debugPrint("Error generating ticket: $e");
      if (context.mounted) {
        ToastUtil.show(context,
            message: "Error saving ticket: $e", type: ToastType.error);
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
    required int displayId,
    required double totalPrice,
  }) async {
    final pdf = pw.Document();

    // ── Try to fetch ground image ──────────────────────
    pw.MemoryImage? venueImage;
    try {
      final netImage = await networkImage(groundImageUrl)
          .timeout(const Duration(seconds: 4));
      venueImage = netImage as pw.MemoryImage?;
    } catch (e) {
      debugPrint("Image fetch failed: $e");
    }

    // ── Formatted values ──────────────────────────────
    final formattedDate = DateFormat('EEEE, d MMMM yyyy').format(date);
    final formattedPrice = '₹${totalPrice.toStringAsFixed(0)}';
    final shortId = IdUtil.formatDisplayId(displayId);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(0),
        build: (pw.Context ctx) {
          return pw.Container(
            color: _kBg,
            alignment: pw.Alignment.center,
            child: pw.Container(
              width: 420,
              margin: const pw.EdgeInsets.symmetric(vertical: 40),
              decoration: pw.BoxDecoration(
                color: _kWhite,
                borderRadius: pw.BorderRadius.circular(20),
              ),
              child: pw.Column(
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  // 1. HERO SECTION (Image + Name Overlay)
                  pw.Stack(
                    children: [
                      pw.ClipRect(
                        child: pw.Container(
                          height: 180,
                          width: double.infinity,
                          child: venueImage != null
                              ? pw.Image(venueImage, fit: pw.BoxFit.cover)
                              : pw.Container(color: _kGreen),
                        ),
                      ),
                      pw.Container(
                        height: 180,
                        decoration: pw.BoxDecoration(
                          borderRadius: const pw.BorderRadius.vertical(
                              top: pw.Radius.circular(20)),
                          gradient: pw.LinearGradient(
                            colors: [
                              PdfColors.black.withAlpha(204), // 0.8 opacity
                              PdfColor.fromInt(0x00000000), // transparent
                            ],
                            begin: pw.Alignment.bottomCenter,
                            end: pw.Alignment.topCenter,
                          ),
                        ),
                      ),
                      pw.Positioned(
                        top: 20,
                        left: 20,
                        right: 20,
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: pw.BoxDecoration(
                                color: _kWhite.withAlpha(51), // 0.2 opacity
                                borderRadius: pw.BorderRadius.circular(6),
                              ),
                              child: pw.Text(
                                'CricBook',
                                style: pw.TextStyle(
                                    color: _kWhite,
                                    fontSize: 10,
                                    fontWeight: pw.FontWeight.bold),
                              ),
                            ),
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: pw.BoxDecoration(
                                color: _kLightGreen,
                                borderRadius: pw.BorderRadius.circular(6),
                              ),
                              child: pw.Text(
                                'CONFIRMED',
                                style: pw.TextStyle(
                                    color: _kGreen,
                                    fontSize: 8,
                                    fontWeight: pw.FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                      pw.Positioned(
                        bottom: 20,
                        left: 20,
                        right: 20,
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              groundName,
                              style: pw.TextStyle(
                                color: _kWhite,
                                fontSize: 24,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.SizedBox(height: 4),
                            pw.Row(
                              children: [
                                pw.Text('📍 ',
                                    style: const pw.TextStyle(fontSize: 10)),
                                pw.Flexible(
                                  child: pw.Text(
                                    groundAddress,
                                    style: pw.TextStyle(
                                        color: _kWhite.withAlpha(204), // 0.8 opacity
                                        fontSize: 10),
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

                  // 2. MAIN DETAILS
                  pw.Container(
                    padding: const pw.EdgeInsets.all(24),
                    child: pw.Column(
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            _pdfInfoBlock('DATE', formattedDate, isBold: true),
                            _pdfInfoBlock('TIME', timeRange,
                                isBold: true, alignRight: true),
                          ],
                        ),
                        pw.SizedBox(height: 24),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            _pdfInfoBlock('BOOKING ID', '#$shortId'),
                            _pdfInfoBlock('PRICE PAID', formattedPrice,
                                alignRight: true),
                          ],
                        ),
                        pw.SizedBox(height: 24),
                        pw.Container(
                          width: double.infinity,
                          padding: const pw.EdgeInsets.all(16),
                          decoration: pw.BoxDecoration(
                            color: _kBg,
                            borderRadius: pw.BorderRadius.circular(12),
                            border: pw.Border.all(color: _kBorder, width: 1),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'IMPORTANT INSTRUCTIONS',
                                style: pw.TextStyle(
                                    color: _kGrey,
                                    fontSize: 8,
                                    fontWeight: pw.FontWeight.bold,
                                    letterSpacing: 1),
                              ),
                              pw.SizedBox(height: 10),
                              _pdfBullet(
                                  'Show this QR code at the venue entrance.'),
                              _pdfBullet(
                                  'Slot once booked cannot be rescheduled.'),
                              _pdfBullet(
                                  'Please carry your own sports gear.'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 3. TEAR SECTION
                  _pdfTearLineWithCircles(),

                  // 4. QR STUB
                  pw.Container(
                    padding: const pw.EdgeInsets.fromLTRB(24, 10, 24, 30),
                    child: pw.Column(
                      children: [
                        pw.Center(
                          child: pw.Column(
                            children: [
                              pw.Container(
                                padding: const pw.EdgeInsets.all(10),
                                decoration: pw.BoxDecoration(
                                  border:
                                      pw.Border.all(color: _kBorder, width: 1),
                                  borderRadius: pw.BorderRadius.circular(12),
                                ),
                                child: pw.BarcodeWidget(
                                  barcode: pw.Barcode.qrCode(),
                                  data: orderId,
                                  width: 100,
                                  height: 100,
                                  color: _kDark,
                                ),
                              ),
                              pw.SizedBox(height: 12),
                              pw.Text(
                                'SCAN AT VENUE',
                                style: pw.TextStyle(
                                  color: _kGrey,
                                  fontSize: 9,
                                  fontWeight: pw.FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        pw.SizedBox(height: 20),
                        pw.Divider(color: _kBorder, thickness: 1),
                        pw.SizedBox(height: 15),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              'cricbook.app',
                              style: pw.TextStyle(
                                  color: _kGrey,
                                  fontSize: 9,
                                  fontWeight: pw.FontWeight.bold),
                            ),
                            pw.Text(
                              'ENJOY YOUR MATCH!',
                              style: pw.TextStyle(
                                  color: _kGreen,
                                  fontSize: 9,
                                  fontWeight: pw.FontWeight.bold),
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
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _pdfInfoBlock(String label, String value,
      {bool isBold = false, bool alignRight = false}) {
    return pw.Column(
      crossAxisAlignment:
          alignRight ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
              color: _kGrey,
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              letterSpacing: 1),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          style: pw.TextStyle(
            color: _kDark,
            fontSize: isBold ? 14 : 12,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      ],
    );
  }

  static pw.Widget _pdfBullet(String text) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 6),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              margin: const pw.EdgeInsets.only(top: 3, right: 6),
              width: 3,
              height: 3,
              decoration: const pw.BoxDecoration(
                  color: _kGreen, shape: pw.BoxShape.circle),
            ),
            pw.Expanded(
                child: pw.Text(text,
                    style: pw.TextStyle(color: _kDark, fontSize: 9))),
          ],
        ),
      );

  static pw.Widget _pdfTearLineWithCircles() {
    return pw.Stack(
      alignment: pw.Alignment.center,
      children: [
        // Dotted Line
        pw.Container(
          height: 1,
          width: double.infinity,
          margin: const pw.EdgeInsets.symmetric(horizontal: 20),
          child: pw.CustomPaint(
            painter: (canvas, size) {
              const dashWidth = 4.0;
              const gap = 4.0;
              double x = 0;
              while (x < size.x) {
                canvas.drawLine(x, 0, x + dashWidth, 0);
                canvas.setStrokeColor(_kBorder);
                canvas.setLineWidth(1);
                canvas.strokePath();
                x += dashWidth + gap;
              }
            },
          ),
        ),
        // Left Circle Cut
        pw.Positioned(
          left: -12,
          child: pw.Container(
            width: 24,
            height: 24,
            decoration: const pw.BoxDecoration(
              color: _kBg,
              shape: pw.BoxShape.circle,
            ),
          ),
        ),
        // Right Circle Cut
        pw.Positioned(
          right: -12,
          child: pw.Container(
            width: 24,
            height: 24,
            decoration: const pw.BoxDecoration(
              color: _kBg,
              shape: pw.BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}
