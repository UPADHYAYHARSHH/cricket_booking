import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../common/constants/colors.dart';
import '../../../constants/widgets/app_sizedBox.dart';
import '../../../constants/widgets/app_text.dart';

class SplitShareScreen extends StatefulWidget {
  const SplitShareScreen({super.key});

  @override
  State<SplitShareScreen> createState() => _SplitShareScreenState();
}

class _SplitShareScreenState extends State<SplitShareScreen> {
  final GlobalKey _cardKey = GlobalKey();

  Future<void> _shareCard(String name, double amount, String upiId) async {
    try {
      RenderRepaintBoundary boundary =
          _cardKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      var byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      var pngBytes = byteData!.buffer.asUint8List();

      final directory = await getTemporaryDirectory();
      final imagePath = await File('${directory.path}/split_card.png').create();
      await imagePath.writeAsBytes(pngBytes);

      final upiLink = "upi://pay?pa=$upiId&pn=CricBook&am=$amount&cu=INR&tn=CricBook%20Split";
      
      await Share.shareXFiles(
        [XFile(imagePath.path)],
        text: "Hey $name, you owe ₹${amount.toStringAsFixed(0)} for our Box Cricket booking. Pay me here: $upiLink",
      );
    } catch (e) {
      debugPrint("Error sharing card: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Expecting Map with member and splitRequest
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args == null) return const Scaffold(body: Center(child: Text("Missing arguments")));

    final String name = args['name'] ?? "Teammate";
    final double amount = args['amount'] ?? 0.0;
    final String venue = args['venue'] ?? "PowerPlay Arena";
    final String date = args['date'] ?? "";
    final String time = args['time'] ?? "";
    final String upiId = args['upiId'] ?? "";
    final String? qrUrl = args['qrUrl'];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Share Payment Card"),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            RepaintBoundary(
              key: _cardKey,
              child: _buildStyledCard(name, amount, venue, date, time, qrUrl),
            ),
            const AppSizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () => _shareCard(name, amount, upiId),
                icon: const HugeIcon(icon: HugeIcons.strokeRoundedWhatsapp, color: Colors.white, size: 20),
                label: const Text("Share to WhatsApp", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366), // WhatsApp Green
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const AppSizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Back to Overview"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStyledCard(String name, double amount, String venue, String date, String time, String? qrUrl) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with Branding
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: const BoxDecoration(
              color: AppColors.primaryDarkGreen,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: const Center(
              child: AppText(
                text: "CricBook Split",
                textStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: 1.2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const AppText(
                  text: "PAYMENT REQUEST",
                  textStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 2),
                ),
                const AppSizedBox(height: 16),
                AppText(
                  text: name,
                  textStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
                ),
                const AppSizedBox(height: 4),
                const AppText(
                  text: "owes you",
                  textStyle: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const AppSizedBox(height: 12),
                AppText(
                  text: "₹${amount.toStringAsFixed(0)}",
                  textStyle: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: AppColors.primaryDarkGreen),
                ),
                const AppSizedBox(height: 24),
                const Divider(),
                const AppSizedBox(height: 16),
                _cardDetail(HugeIcons.strokeRoundedCricketBat, venue),
                const AppSizedBox(height: 8),
                _cardDetail(HugeIcons.strokeRoundedCalendar01, "$date • $time"),
                const AppSizedBox(height: 24),
                if (qrUrl != null) ...[
                  const AppText(
                    text: "Scan to Pay",
                    textStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  const AppSizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Image.network(
                      qrUrl,
                      height: 160,
                      width: 160,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.qr_code_scanner, size: 80, color: Colors.grey),
                    ),
                  ),
                ] else
                   const HugeIcon(icon: HugeIcons.strokeRoundedBitcoinEllipse, size: 24, color: AppColors.primaryDarkGreen),
                const AppSizedBox(height: 24),
                const AppText(
                  text: "Generated via CricBook",
                  textStyle: TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardDetail(dynamic icon, String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        HugeIcon(icon: icon, size: 16, color: Colors.grey),
        const AppSizedBox(width: 8),
        Flexible(
          child: AppText(
            text: text,
            textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
            maxLines: 1,
          ),
        ),
      ],
    );
  }
}
