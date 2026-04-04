// lib/user_booking/presentation/widgets/pitch_painter.dart

import 'package:flutter/material.dart';

class PitchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Vertical stripes (grass effect)
    for (double x = 0; x < size.width; x += size.width / 6) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Center circle
    final centerPaint = Paint()
      ..color = Colors.white.withOpacity(0.10)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 38, centerPaint);

    // Center line
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      centerPaint,
    );

    // Penalty box
    final boxPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.2, 0, size.width * 0.6, size.height * 0.3),
      boxPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.2, size.height * 0.7, size.width * 0.6,
          size.height * 0.3),
      boxPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
