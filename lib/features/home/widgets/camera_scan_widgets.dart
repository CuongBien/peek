import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class FocusBracketsPainter extends CustomPainter {
  final bool isSuspicious;
  final double pulseValue;

  FocusBracketsPainter({required this.isSuspicious, required this.pulseValue});

  @override
  void paint(Canvas canvas, Size size) {
    final color = isSuspicious ? AppColors.accentRed : AppColors.accentCyan;
    final paint = Paint()
      ..color = color.withOpacity(0.5 + (0.5 * pulseValue))
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const double bracketLength = 25.0;
    const double padding = 30.0;

    // Top Left
    final pathTL = Path()
      ..moveTo(padding + bracketLength, padding)
      ..lineTo(padding, padding)
      ..lineTo(padding, padding + bracketLength);
    canvas.drawPath(pathTL, paint);

    // Top Right
    final pathTR = Path()
      ..moveTo(size.width - padding - bracketLength, padding)
      ..lineTo(size.width - padding, padding)
      ..lineTo(size.width - padding, padding + bracketLength);
    canvas.drawPath(pathTR, paint);

    // Bottom Left
    final pathBL = Path()
      ..moveTo(padding + bracketLength, size.height - padding)
      ..lineTo(padding, size.height - padding)
      ..lineTo(padding, size.height - padding - bracketLength);
    canvas.drawPath(pathBL, paint);

    // Bottom Right
    final pathBR = Path()
      ..moveTo(size.width - padding - bracketLength, size.height - padding)
      ..lineTo(size.width - padding, size.height - padding)
      ..lineTo(size.width - padding, size.height - padding - bracketLength);
    canvas.drawPath(pathBR, paint);

    // Center crosshair with pulsing size
    final crossPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..strokeWidth = 1.0;
    
    double crossSize = 15.0 + (pulseValue * 5.0);
    double midX = size.width / 2;
    double midY = size.height / 2;
    canvas.drawLine(Offset(midX - crossSize, midY), Offset(midX + crossSize, midY), crossPaint);
    canvas.drawLine(Offset(midX, midY - crossSize), Offset(midX, midY + crossSize), crossPaint);
    canvas.drawCircle(Offset(midX, midY), 4 * (1.0 + pulseValue), Paint()..color = color..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant FocusBracketsPainter oldDelegate) {
    return oldDelegate.isSuspicious != isSuspicious || oldDelegate.pulseValue != pulseValue;
  }
}

class WaveGraphPainter extends CustomPainter {
  final List<double> history;
  final bool isSuspicious;

  WaveGraphPainter({required this.history, required this.isSuspicious});

  @override
  void paint(Canvas canvas, Size size) {
    if (history.isEmpty) return;

    final color = isSuspicious ? AppColors.accentRed : AppColors.accentCyan;

    // Draw background grid lines for the graph
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 1.0;

    int horizontalGridLines = 4;
    for (int i = 0; i <= horizontalGridLines; i++) {
      double y = size.height * (i / horizontalGridLines);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    int verticalGridLines = 8;
    for (int i = 0; i <= verticalGridLines; i++) {
      double x = size.width * (i / verticalGridLines);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    // Min/Max analysis
    double maxVal = history.reduce(max);
    double minVal = history.reduce(min);
    double range = maxVal - minVal;
    if (range < 10) range = 10; // Avoid flatlines or zero division

    // Add extra padding to the top and bottom of the graph
    double graphMax = maxVal + range * 0.15;
    double graphMin = minVal - range * 0.15;
    if (graphMin < 0) graphMin = 0;
    double finalRange = graphMax - graphMin;

    final path = Path();
    final fillPath = Path();

    double stepX = size.width / (history.length - 1);
    
    // Starting coordinates
    double startX = 0;
    double startY = size.height - ((history[0] - graphMin) / finalRange) * size.height;
    path.moveTo(startX, startY);
    fillPath.moveTo(0, size.height);
    fillPath.lineTo(startX, startY);

    // Build wave coordinates using Bezier curves for smoother rendering
    for (int i = 1; i < history.length; i++) {
      double x = i * stepX;
      double y = size.height - ((history[i] - graphMin) / finalRange) * size.height;

      // Draw bezier curves
      double prevX = (i - 1) * stepX;
      double prevY = size.height - ((history[i - 1] - graphMin) / finalRange) * size.height;
      double controlX = prevX + stepX / 2;
      
      path.cubicTo(controlX, prevY, controlX, y, x, y);
      fillPath.cubicTo(controlX, prevY, controlX, y, x, y);
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    // Fill under graph with translucent gradient
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withOpacity(0.2),
          color.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
    
    canvas.drawPath(fillPath, fillPaint);

    // Draw graph stroke line
    final strokePaint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant WaveGraphPainter oldDelegate) {
    return oldDelegate.history != history || oldDelegate.isSuspicious != isSuspicious;
  }
}
