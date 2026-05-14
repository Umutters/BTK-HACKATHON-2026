import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// FortuneFlow logosunu çizen widget.
/// [size] genişlik ve yüksekliği belirler (kare).
class FortuneFlowLogo extends StatelessWidget {
  final double size;

  const FortuneFlowLogo({super.key, this.size = 96});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _LogoPainter()),
    );
  }
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // ── 1. Dış halka gradient ──────────────────────────────────────────────
    final ringGradient = SweepGradient(
      colors: const [
        AppColors.cyberBlue,
        AppColors.neonLime,
        AppColors.cyberBlue,
      ],
      stops: const [0.0, 0.55, 1.0],
      startAngle: -math.pi / 2,
      endAngle: 3 * math.pi / 2,
    );

    final ringPaint = Paint()
      ..shader = ringGradient.createShader(
        Rect.fromCircle(center: center, radius: radius),
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.075
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius * 0.88, ringPaint);

    // ── 2. İç arka plan ───────────────────────────────────────────────────
    final bgGradient = RadialGradient(
      colors: [
        AppColors.cyberBlue.withValues(alpha: 0.18),
        AppColors.background.withValues(alpha: 0.85),
      ],
      stops: const [0.0, 1.0],
    );

    final bgPaint = Paint()
      ..shader = bgGradient.createShader(
        Rect.fromCircle(center: center, radius: radius * 0.80),
      )
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius * 0.78, bgPaint);

    // ── 3. Akan çizgi (flow simgesi) ──────────────────────────────────────
    // Ortada iki kıvrımlı dikey çizgi — akış/dalga efekti
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.055
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final lineGradient = LinearGradient(
      colors: const [AppColors.cyberBlue, AppColors.neonLime],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );

    final lineRect = Rect.fromCircle(center: center, radius: radius * 0.48);
    linePaint.shader = lineGradient.createShader(lineRect);

    // Sol dalga
    final leftPath = Path();
    final cx = center.dx;
    final cy = center.dy;
    final w = size.width * 0.18; // dalga genişliği
    final h = size.height * 0.44; // yükseklik

    leftPath.moveTo(cx - w, cy - h / 2);
    leftPath.cubicTo(
      cx - w * 2.6,
      cy - h / 6, //
      cx + w * 0.6,
      cy + h / 6, //
      cx - w,
      cy + h / 2,
    );

    // Sağ dalga (ayna)
    final rightPath = Path();
    rightPath.moveTo(cx + w, cy - h / 2);
    rightPath.cubicTo(
      cx + w * 2.6,
      cy - h / 6,
      cx - w * 0.6,
      cy + h / 6,
      cx + w,
      cy + h / 2,
    );

    canvas.drawPath(leftPath, linePaint);
    canvas.drawPath(rightPath, linePaint);

    // ── 4. Merkez nokta parıltısı ──────────────────────────────────────────
    final dotPaint = Paint()
      ..color = AppColors.neonLime.withValues(alpha: 0.9)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(center, size.width * 0.045, dotPaint);

    final dotCorePaint = Paint()..color = Colors.white;
    canvas.drawCircle(center, size.width * 0.028, dotCorePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
