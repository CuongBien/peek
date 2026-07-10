import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class RadarPainter extends CustomPainter {
  final double angle; // Sweep rotation angle (0 to 2*pi)
  final double pulseValue; // Pulse scale (0.0 to 1.0)
  final bool isScanning;

  RadarPainter({
    required this.angle,
    required this.pulseValue,
    required this.isScanning,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = min(size.width, size.height) / 2;

    // Paint for background grid lines
    final gridPaint = Paint()
      ..color = AppColors.accentCyan.withOpacity(0.1)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Draw concentric radar rings
    for (int i = 1; i <= 4; i++) {
      double r = maxRadius * (i / 4);
      canvas.drawCircle(center, r, gridPaint);
    }

    // Draw crosshair axes
    canvas.drawLine(Offset(center.dx - maxRadius, center.dy), Offset(center.dx + maxRadius, center.dy), gridPaint);
    canvas.drawLine(Offset(center.dx, center.dy - maxRadius), Offset(center.dx, center.dy + maxRadius), gridPaint);

    // Draw diagonal grid lines
    final diagonalPaint = Paint()
      ..color = AppColors.accentCyan.withOpacity(0.05)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    
    double diagOffset = maxRadius * 0.7071; // sin(45) * r
    canvas.drawLine(Offset(center.dx - diagOffset, center.dy - diagOffset), Offset(center.dx + diagOffset, center.dy + diagOffset), diagonalPaint);
    canvas.drawLine(Offset(center.dx - diagOffset, center.dy + diagOffset), Offset(center.dx + diagOffset, center.dy - diagOffset), diagonalPaint);

    if (isScanning) {
      // Draw pulsing center ring
      final pulsePaint = Paint()
        ..color = AppColors.accentCyan.withOpacity(0.2 * (1.0 - pulseValue))
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(center, maxRadius * pulseValue, pulsePaint);

      // Draw sweeping scanner line with gradient fill
      final sweepPaint = Paint()
        ..shader = SweepGradient(
          center: Alignment.center,
          startAngle: 0.0,
          endAngle: 2 * pi,
          colors: [
            AppColors.accentCyan.withOpacity(0.0),
            AppColors.accentCyan.withOpacity(0.0),
            AppColors.accentCyan.withOpacity(0.4),
          ],
          transform: GradientRotation(angle),
        ).createShader(Rect.fromCircle(center: center, radius: maxRadius))
        ..style = PaintingStyle.fill;

      canvas.drawCircle(center, maxRadius, sweepPaint);

      // Draw scanner leading edge line
      final edgePaint = Paint()
        ..color = AppColors.accentCyan.withOpacity(0.8)
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;
      
      double edgeX = center.dx + maxRadius * cos(angle);
      double edgeY = center.dy + maxRadius * sin(angle);
      canvas.drawLine(center, Offset(edgeX, edgeY), edgePaint);

      // Draw some glowing threat dots inside the radar scan area
      final dotPaint = Paint()
        ..color = AppColors.accentRed.withOpacity(0.8)
        ..style = PaintingStyle.fill;
      final dotShadowPaint = Paint()
        ..color = AppColors.accentRed.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4)
        ..style = PaintingStyle.fill;

      // Suspicious target 1 (glowing)
      Offset target1 = Offset(center.dx + maxRadius * 0.45 * cos(angle - 0.8), center.dy + maxRadius * 0.45 * sin(angle - 0.8));
      canvas.drawCircle(target1, 8, dotShadowPaint);
      canvas.drawCircle(target1, 4, dotPaint);

      // Safe target 2 (cyan)
      final safeDotPaint = Paint()
        ..color = AppColors.accentCyan.withOpacity(0.8)
        ..style = PaintingStyle.fill;
      final safeDotShadow = Paint()
        ..color = AppColors.accentCyan.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      
      Offset target2 = Offset(center.dx + maxRadius * 0.65 * cos(angle - 1.8), center.dy + maxRadius * 0.65 * sin(angle - 1.8));
      canvas.drawCircle(target2, 7, safeDotShadow);
      canvas.drawCircle(target2, 3.5, safeDotPaint);
    } else {
      // Draw static center core
      final corePaint = Paint()
        ..color = AppColors.accentCyan.withOpacity(0.3)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, 12, corePaint);
    }
  }

  @override
  bool shouldRepaint(covariant RadarPainter oldDelegate) {
    return oldDelegate.angle != angle || oldDelegate.pulseValue != pulseValue || oldDelegate.isScanning != isScanning;
  }
}
