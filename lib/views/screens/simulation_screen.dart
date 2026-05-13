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
                  const SizedBox(height: 16),
                  _TransactionBreakdownCard(vm: vm),
                  const SizedBox(height: 16),
                  _ProjectionTableCard(vm: vm),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spaceXL),
      decoration: BoxDecoration(
        color: AppColors.glass08,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: AppColors.glass12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.cyberBlue10,
                  border: Border.all(color: AppColors.cyberBlue15),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.cyberBlue,
                  size: 16,
                ),
              ),
              const SizedBox(width: AppDimensions.spaceS),
              Text(
                'AI ORACLE',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.cyberBlueDim,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceM),
          Text(
            vm.aiInsight,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.onSurface,
              fontFamily: 'Outfit',
              height: 1.6,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceL),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: vm.isGeneratingAi
                  ? null
                  : () =>
                        context.read<SimulationViewModel>().generateAiInsight(),
              icon: vm.isGeneratingAi
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome_rounded, size: 16),
              label: Text(
                vm.isGeneratingAi ? 'Uretiliyor...' : 'AI Yorumu Guncelle',
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.cyberBlue),
                foregroundColor: AppColors.cyberBlue,
                padding: const EdgeInsets.symmetric(vertical: 12),
                textStyle: AppTextStyles.labelMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionBreakdownCard extends StatelessWidget {
  final SimulationViewModel vm;
  const _TransactionBreakdownCard({required this.vm});

  @override
  Widget build(BuildContext context) {
    final rows = vm.transactionImpacts.take(5).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spaceL),
      decoration: BoxDecoration(
        color: AppColors.glass08,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: AppColors.glass12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TRANSACTION ETKI TABLOSU',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.cyberBlueDim,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceM),
          if (rows.isEmpty)
            Text(
              'Tablo icin yeterli transaction verisi yok.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          if (rows.isNotEmpty)
            ...rows.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: AppDimensions.spaceM),
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Text(
                        r.category,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.onSurface,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        _formatTl(r.monthlyImpact),
                        textAlign: TextAlign.right,
                        style: AppTextStyles.labelMedium.copyWith(
                          color: r.monthlyImpact >= 0
                              ? AppColors.neonLime
                              : AppColors.cyberMagenta,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${r.sharePercent.toStringAsFixed(0)}%',
                        textAlign: TextAlign.right,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProjectionTableCard extends StatelessWidget {
  final SimulationViewModel vm;
  const _ProjectionTableCard({required this.vm});

  @override
  Widget build(BuildContext context) {
    final rows = vm.projectionRows;
    final sampledRows = rows
        .where((r) => (r.year - vm.startYear) % 2 == 0)
        .toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spaceL),
      decoration: BoxDecoration(
        color: AppColors.glass08,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: AppColors.glass12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HEDEF TAHMIN TABLOSU',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.cyberBlueDim,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceM),
          Row(
            children: [
              Expanded(
                child: Text(
                  'YIL',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'PORTFOY',
                  textAlign: TextAlign.right,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'HEDEF ACIGI',
                  textAlign: TextAlign.right,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceS),
          ...sampledRows
              .take(6)
              .map(
                (row) => Padding(
                  padding: const EdgeInsets.only(bottom: AppDimensions.spaceS),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${row.year}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.onSurface,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '${row.projectedMillions.toStringAsFixed(2)}M',
                          textAlign: TextAlign.right,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.neonLime,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '${row.goalGapMillions.toStringAsFixed(2)}M',
                          textAlign: TextAlign.right,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: row.goalGapMillions > 0
                                ? AppColors.cyberMagenta
                                : AppColors.neonLime,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

String _formatTl(double value) {
  final sign = value >= 0 ? '+' : '-';
  final absValue = value.abs();
  return '$sign${absValue.toStringAsFixed(0)} TL';
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
