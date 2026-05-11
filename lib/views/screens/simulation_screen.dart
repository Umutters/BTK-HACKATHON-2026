import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_text_styles.dart';
import '../../viewmodels/simulation_viewmodel.dart';

class SimulationScreen extends StatelessWidget {
  const SimulationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SimulationViewModel>(
      builder: (context, vm, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: _SimAppBar(),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.pagePaddingH,
                vertical: AppDimensions.pagePaddingV,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 8),
                  _TargetProjectionHeader(vm: vm),
                  const SizedBox(height: 20),
                  _ProjectionChartCard(vm: vm),
                  const SizedBox(height: 16),
                  _AiInsightCard(vm: vm),
                  const SizedBox(height: 28),
                  _TimelineSlider(vm: vm),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── AppBar ──────────────────────────────────────────────────────────────────

class _SimAppBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: Padding(
        padding: const EdgeInsets.only(left: AppDimensions.spaceL),
        child: GestureDetector(
          onTap: () {},
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceVariant,
              border: Border.all(color: AppColors.glass12),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: AppColors.onSurfaceVariant,
              size: 20,
            ),
          ),
        ),
      ),
      title: Text(
        'FortuneFlow AI',
        style: AppTextStyles.titleLarge.copyWith(
          color: AppColors.cyberBlue,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: AppDimensions.spaceL),
          child: Icon(
            Icons.bolt_rounded,
            color: AppColors.cyberBlue,
            size: AppDimensions.iconL,
          ),
        ),
      ],
    );
  }
}

// ─── Target Projection Header ────────────────────────────────────────────────

class _TargetProjectionHeader extends StatelessWidget {
  final SimulationViewModel vm;
  const _TargetProjectionHeader({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'TARGET PROJECTION',
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.onSurfaceVariant,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          vm.formattedTarget,
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 52,
            fontWeight: FontWeight.w800,
            color: AppColors.onSurface,
            height: 1.0,
          ),
        ),
      ],
    );
  }
}

// ─── Projection Chart Card ────────────────────────────────────────────────────

class _ProjectionChartCard extends StatelessWidget {
  final SimulationViewModel vm;
  const _ProjectionChartCard({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 220,
      padding: const EdgeInsets.all(AppDimensions.spaceL),
      decoration: BoxDecoration(
        color: AppColors.glass08,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: AppColors.glass12),
      ),
      child: Column(
        children: [
          Expanded(
            child: CustomPaint(
              painter: _ChartPainter(points: vm.visiblePoints),
              child: const SizedBox.expand(),
            ),
          ),
          const SizedBox(height: 8),
          // Mid-year label
          Text(
            '${vm.startYear + ((vm.selectedYear - vm.startYear) / 2).round()}',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.cyberBlueDim,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Chart CustomPainter ──────────────────────────────────────────────────────

class _ChartPainter extends CustomPainter {
  final List<ProjectionPoint> points;

  const _ChartPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final minAmount = points.map((p) => p.amountMillions).reduce(min);
    final maxAmount = points.map((p) => p.amountMillions).reduce(max);
    final amountRange = (maxAmount - minAmount).clamp(0.001, double.infinity);

    final minYear = points.first.year.toDouble();
    final maxYear = points.last.year.toDouble();
    final yearRange = (maxYear - minYear).clamp(1.0, double.infinity);

    final padding = const EdgeInsets.only(
      left: 4,
      right: 4,
      top: 12,
      bottom: 4,
    );

    Offset toCanvas(ProjectionPoint p) {
      final x =
          padding.left +
          ((p.year - minYear) / yearRange) *
              (size.width - padding.left - padding.right);
      final y =
          padding.top +
          (size.height - padding.top - padding.bottom) -
          ((p.amountMillions - minAmount) / amountRange) *
              (size.height - padding.top - padding.bottom);
      return Offset(x, y);
    }

    final offsets = points.map(toCanvas).toList();

    // ── Glow passes ───────────────────────────────────────────────────────
    for (int i = 3; i >= 1; i--) {
      final glowPaint = Paint()
        ..color = AppColors.cyberBlue.withAlpha((25 + i * 18).round())
        ..strokeWidth = 1.5 + i * 3.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

      final path = Path()..moveTo(offsets.first.dx, offsets.first.dy);
      for (int j = 1; j < offsets.length; j++) {
        // Smooth bezier
        final prev = offsets[j - 1];
        final curr = offsets[j];
        final cpx = (prev.dx + curr.dx) / 2;
        path.cubicTo(cpx, prev.dy, cpx, curr.dy, curr.dx, curr.dy);
      }
      canvas.drawPath(path, glowPaint);
    }

    // ── Main line ─────────────────────────────────────────────────────────
    final linePaint = Paint()
      ..color = AppColors.cyberBlue
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final mainPath = Path()..moveTo(offsets.first.dx, offsets.first.dy);
    for (int j = 1; j < offsets.length; j++) {
      final prev = offsets[j - 1];
      final curr = offsets[j];
      final cpx = (prev.dx + curr.dx) / 2;
      mainPath.cubicTo(cpx, prev.dy, cpx, curr.dy, curr.dx, curr.dy);
    }
    canvas.drawPath(mainPath, linePaint);

    // ── Vertical dashed line at midpoint ──────────────────────────────────
    final midIndex = offsets.length ~/ 2;
    if (midIndex > 0 && midIndex < offsets.length) {
      final midOffset = offsets[midIndex];
      final dashPaint = Paint()
        ..color = AppColors.cyberBlue.withAlpha(80)
        ..strokeWidth = 1;
      _drawDashedVertical(canvas, midOffset.dx, 0, size.height, dashPaint);

      // Hollow circle at midpoint
      canvas.drawCircle(midOffset, 7, Paint()..color = AppColors.background);
      canvas.drawCircle(
        midOffset,
        7,
        Paint()
          ..color = AppColors.cyberBlue
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    // ── Endpoint filled circle with glow ──────────────────────────────────
    final endOffset = offsets.last;
    canvas.drawCircle(
      endOffset,
      14,
      Paint()
        ..color = AppColors.cyberBlue.withAlpha(60)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawCircle(endOffset, 8, Paint()..color = AppColors.cyberBlue);
    // Inner dark dot
    canvas.drawCircle(endOffset, 3.5, Paint()..color = AppColors.background);
  }

  void _drawDashedVertical(
    Canvas canvas,
    double x,
    double top,
    double bottom,
    Paint paint,
  ) {
    const dashLen = 5.0;
    const gapLen = 4.0;
    double y = top;
    while (y < bottom) {
      canvas.drawLine(
        Offset(x, y),
        Offset(x, (y + dashLen).clamp(top, bottom)),
        paint,
      );
      y += dashLen + gapLen;
    }
  }

  @override
  bool shouldRepaint(_ChartPainter old) =>
      old.points.length != points.length ||
      (old.points.isNotEmpty &&
          points.isNotEmpty &&
          old.points.last.year != points.last.year);
}

// ─── AI Insight Card ──────────────────────────────────────────────────────────

class _AiInsightCard extends StatelessWidget {
  final SimulationViewModel vm;
  const _AiInsightCard({required this.vm});

  @override
  Widget build(BuildContext context) {
    final insight = vm.aiInsight;
    final goalYearStr = vm.aiGoalYear.toString();

    // Split insight around the goal year to highlight it
    final idx = insight.indexOf(goalYearStr);
    final before = idx >= 0 ? insight.substring(0, idx) : insight;
    final after = idx >= 0 ? insight.substring(idx + goalYearStr.length) : '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spaceXL),
      decoration: BoxDecoration(
        color: AppColors.glass08,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: AppColors.glass12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sparkle icon container
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.cyberBlue10,
              border: Border.all(color: AppColors.cyberBlue15),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.cyberBlue,
              size: 20,
            ),
          ),
          const SizedBox(width: AppDimensions.spaceL),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.onSurface,
                  fontFamily: 'Outfit',
                  height: 1.5,
                ),
                children: [
                  TextSpan(text: '"$before'),
                  if (idx >= 0)
                    TextSpan(
                      text: goalYearStr,
                      style: const TextStyle(
                        color: AppColors.neonLime,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  if (idx >= 0) TextSpan(text: '$after"'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Timeline Slider ──────────────────────────────────────────────────────────

class _TimelineSlider extends StatelessWidget {
  final SimulationViewModel vm;
  const _TimelineSlider({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${vm.startYear}',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            Text(
              '${vm.endYear}',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: AppColors.neonLime,
            inactiveTrackColor: AppColors.surfaceContainerHighest,
            thumbColor: AppColors.neonLime,
            overlayColor: AppColors.neonLime20,
            trackHeight: 8,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 22),
          ),
          child: Slider(
            value: vm.sliderValue,
            min: 0.0,
            max: 1.0,
            onChanged: (v) =>
                context.read<SimulationViewModel>().setSliderValue(v),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'ADJUST TIMELINE',
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.cyberBlueDim,
            letterSpacing: 2.0,
          ),
        ),
      ],
    );
  }
}
