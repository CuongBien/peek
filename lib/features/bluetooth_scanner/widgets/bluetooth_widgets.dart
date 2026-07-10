import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class ConcentricSignalArcsPainter extends CustomPainter {
  final double animationValue;
  final int maxRssi; // Strongest RSSI value in the room (e.g. -45 dBm)

  ConcentricSignalArcsPainter({
    required this.animationValue,
    required this.maxRssi,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.85); // Anchor at bottom center
    final double baseRadius = min(size.width, size.height) * 0.75;
    
    // Normalize RSSI to gauge strength (typical range: -100 to -40)
    double strength = ((maxRssi + 100) / 60.0).clamp(0.0, 1.0);
    int activeArcs = (strength * 5).round().clamp(1, 5);
    Color meterColor = strength > 0.7 ? AppColors.accentRed : AppColors.accentCyan;

    for (int i = 1; i <= 5; i++) {
      double radius = (baseRadius / 5) * i;
      
      // Calculate opacity based on strength and animation pulse
      double opacity = 0.05;
      if (i <= activeArcs) {
        opacity = 0.15 + 0.35 * (1.0 - (i / 5.0)) + 0.1 * sin(animationValue * 2 * pi);
      }

      final arcPaint = Paint()
        ..color = meterColor.withOpacity(opacity.clamp(0.01, 1.0))
        ..strokeWidth = 4.0 + (i * 1.5)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      // Draw semi-circular upward facing arcs (from 180 to 360 degrees)
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        pi,
        pi,
        false,
        arcPaint,
      );

      // Draw glowing dots on active outer rings
      if (i == activeArcs && strength > 0) {
        final dotPaint = Paint()
          ..color = meterColor
          ..style = PaintingStyle.fill;
        final dotShadow = Paint()
          ..color = meterColor.withOpacity(0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
          
        double angle = pi + (pi * 0.25) + (pi * 0.5 * sin(animationValue * pi));
        Offset dotPos = Offset(center.dx + radius * cos(angle), center.dy + radius * sin(angle));
        canvas.drawCircle(dotPos, 8, dotShadow);
        canvas.drawCircle(dotPos, 4, dotPaint);
      }
    }

    // Draw central node/device indicator
    final corePaint = Paint()
      ..color = meterColor
      ..style = PaintingStyle.fill;
    final coreShadow = Paint()
      ..color = meterColor.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    
    canvas.drawCircle(center, 12, coreShadow);
    canvas.drawCircle(center, 6, corePaint);
  }

  @override
  bool shouldRepaint(covariant ConcentricSignalArcsPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue || oldDelegate.maxRssi != maxRssi;
  }
}

class FluidWavePainter extends CustomPainter {
  final double animationValue;
  final int proximityScore; // Proximity percentage (0 - 100)

  FluidWavePainter({
    required this.animationValue,
    required this.proximityScore,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = min(size.width, size.height) * 0.45;
    
    // Scale speed and size with proximity score
    double speedFactor = 1.0 + (proximityScore / 100.0) * 3.0; // speed multiplier
    double rangeFactor = 0.3 + (proximityScore / 100.0) * 0.7; // size multiplier
    Color waveColor = proximityScore > 75 
        ? AppColors.accentRed 
        : (proximityScore > 45 ? AppColors.warningOrange : AppColors.accentCyan);

    // Draw multiple overlapping wavy layers
    for (int layer = 0; layer < 3; layer++) {
      final path = Path();
      
      // Calculate offset phase for each layer to differentiate them
      double phase = (animationValue * speedFactor * 2 * pi) + (layer * pi / 1.5);
      double layerRadius = maxRadius * rangeFactor * (0.6 + (layer * 0.15));

      int pointsCount = 60;
      for (int i = 0; i <= pointsCount; i++) {
        double angle = (i / pointsCount) * 2 * pi;
        
        // Fluid ripple effect using sine waves relative to angle and time
        double ripple = sin(angle * 6 + phase) * (layerRadius * 0.08);
        double r = layerRadius + ripple;

        double x = center.dx + r * cos(angle);
        double y = center.dy + r * sin(angle);

        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();

      final paint = Paint()
        ..color = waveColor.withOpacity(0.07 - (layer * 0.02))
        ..style = PaintingStyle.fill;
        
      canvas.drawPath(path, paint);

      // Draw line path for the outer layer
      if (layer == 1) {
        final linePaint = Paint()
          ..color = waveColor.withOpacity(0.3)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;
        canvas.drawPath(path, linePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant FluidWavePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue || oldDelegate.proximityScore != proximityScore;
  }
}
