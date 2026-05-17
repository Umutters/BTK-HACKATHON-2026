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
            child: RefreshIndicator.adaptive(
              color: AppColors.cyberBlue,
              backgroundColor: AppColors.surface,
              onRefresh: () => context.read<SimulationViewModel>().refresh(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
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
                    _SavingsAverageCard(vm: vm),
                    const SizedBox(height: 16),
                    _ProjectionChartCard(vm: vm),
                    const SizedBox(height: 16),
                    _AiInsightCard(vm: vm),
                    const SizedBox(height: 16),
                    _TransactionBreakdownCard(vm: vm),
                    const SizedBox(height: 16),
                    _ProjectionTableCard(vm: vm),
                    const SizedBox(height: 28),
                    _WhatIfSlidersPanel(vm: vm),
                    const SizedBox(height: 24),
                  ],
                ),
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
        'FortuneFlow Yapay Zeka',
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

// ─── Hedef projeksiyonu başlığı ──────────────────────────────────────────────

class _TargetProjectionHeader extends StatelessWidget {
  final SimulationViewModel vm;
  const _TargetProjectionHeader({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '5 YILLIK FİNANS ROTASI',
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

class _SavingsAverageCard extends StatelessWidget {
  final SimulationViewModel vm;
  const _SavingsAverageCard({required this.vm});

  @override
  Widget build(BuildContext context) {
    final daily30 = vm.avgDailyTransferred30;
    final daily7 = vm.avgDailyTransferred7;
    final monthly = daily30 * 30;

    String trendArrow = '→';
    String trendText = 'Sabit';
    if (daily7 > daily30 * 1.05) {
      trendArrow = '↑';
      trendText = 'Artis';
    } else if (daily7 < daily30 * 0.95) {
      trendArrow = '↓';
      trendText = 'Azalis';
    }
    final trendDiff = daily30 > 0
        ? (((daily7 - daily30) / daily30) * 100).abs()
        : 0.0;

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
            ' 30 GÜNLÜK TASARRUF ORTALAMASI',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.onSurfaceVariant,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceS),
          Row(
            children: [
              Expanded(
                child: _MetricBox(
                  label: 'Günlük ort. aktarım',
                  value: '${daily30.toStringAsFixed(1)} ${vm.currencySymbol}',
                ),
              ),
              const SizedBox(width: AppDimensions.spaceM),
              Expanded(
                child: _MetricBox(
                  label: 'Aylık tasarruf',
                  value:
                      '${monthly.toStringAsFixed(0)} ${vm.currencySymbol}/ay',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceS),
          Row(
            children: [
              Expanded(
                child: _MetricBox(
                  label: '7 GUN TREND',
                  value:
                      '$trendArrow $trendText (%${trendDiff.toStringAsFixed(1)})',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricBox extends StatelessWidget {
  final String label;
  final String value;

  const _MetricBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceM),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.glass12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.onSurfaceVariant,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceXS),
          Text(
            value,
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.neonLime,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
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
              painter: _DualChartPainter(
                currentPoints: vm.currentPoints,
                optimizedPoints: vm.optimizedPoints,
                goalMillions: vm.goalMillions,
              ),
              child: const SizedBox.expand(),
            ),
          ),
          const SizedBox(height: 8),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendDot(color: AppColors.cyberBlue, label: 'Mevcut Rota'),
              const SizedBox(width: 16),
              _LegendDot(color: AppColors.neonLime, label: 'Optimize Rota'),
              const SizedBox(width: 16),
              _LegendDot(color: AppColors.cyberMagenta, label: 'Hedef'),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${vm.startYear}',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.cyberBlueDim,
                  fontSize: 11,
                ),
              ),
              Text(
                '${vm.endYear}',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.cyberBlueDim,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Dual Chart CustomPainter ─────────────────────────────────────────────────

class _DualChartPainter extends CustomPainter {
  final List<ProjectionPoint> currentPoints;
  final List<ProjectionPoint> optimizedPoints;
  final double goalMillions;

  const _DualChartPainter({
    required this.currentPoints,
    required this.optimizedPoints,
    required this.goalMillions,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (currentPoints.length < 2) return;

    final allAmounts = [
      ...currentPoints.map((p) => p.amountMillions),
      if (optimizedPoints.isNotEmpty)
        ...optimizedPoints.map((p) => p.amountMillions),
      goalMillions,
    ];

    const minAmount = 0.0;
    final maxAmount = allAmounts.reduce(max) * 1.08;
    final amountRange = (maxAmount - minAmount).clamp(0.001, double.infinity);

    final minYear = currentPoints.first.year.toDouble();
    final maxYear = currentPoints.last.year.toDouble();
    final yearRange = (maxYear - minYear).clamp(1.0, double.infinity);

    const padL = 4.0, padR = 4.0, padT = 16.0, padB = 4.0;
    final w = size.width - padL - padR;
    final h = size.height - padT - padB;

    double xPos(double year) => padL + ((year - minYear) / yearRange) * w;
    double yPos(double amount) =>
        padT + h * (1 - (amount - minAmount) / amountRange);

    // ── Goal horizontal dashed line (cyberMagenta) ─────────────────────
    final goalY = yPos(goalMillions);
    if (goalY >= padT && goalY <= size.height - padB) {
      final goalPaint = Paint()
        ..color = AppColors.cyberMagenta.withAlpha(160)
        ..strokeWidth = 1.5;
      _drawDashedH(canvas, padL, size.width - padR, goalY, goalPaint);
    }

    // ── Current path (cyberBlue) ───────────────────────────────────────
    _drawCurve(
      canvas,
      currentPoints,
      xPos,
      yPos,
      color: AppColors.cyberBlue,
      strokeWidth: 2.0,
    );

    // ── Optimized path (neonLime) ──────────────────────────────────────
    if (optimizedPoints.length >= 2) {
      _drawCurve(
        canvas,
        optimizedPoints,
        xPos,
        yPos,
        color: AppColors.neonLime,
        strokeWidth: 2.5,
      );
    }

    // ── Endpoint dots ─────────────────────────────────────────────────
    if (currentPoints.isNotEmpty) {
      final ep = Offset(
        xPos(currentPoints.last.year.toDouble()),
        yPos(currentPoints.last.amountMillions),
      );
      canvas.drawCircle(
        ep,
        5,
        Paint()..color = AppColors.cyberBlue.withAlpha(200),
      );
    }
    if (optimizedPoints.isNotEmpty) {
      final ep = Offset(
        xPos(optimizedPoints.last.year.toDouble()),
        yPos(optimizedPoints.last.amountMillions),
      );
      canvas.drawCircle(
        ep,
        12,
        Paint()
          ..color = AppColors.neonLime.withAlpha(50)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      canvas.drawCircle(ep, 6, Paint()..color = AppColors.neonLime);
      canvas.drawCircle(ep, 3, Paint()..color = AppColors.background);
    }
  }

  void _drawCurve(
    Canvas canvas,
    List<ProjectionPoint> points,
    double Function(double) xPos,
    double Function(double) yPos, {
    required Color color,
    required double strokeWidth,
  }) {
    final path = _buildPath(points, xPos, yPos);

    // Glow pass
    for (int i = 2; i >= 1; i--) {
      canvas.drawPath(
        path,
        Paint()
          ..color = color.withAlpha((18 + i * 22).round())
          ..strokeWidth = strokeWidth + i * 4
          ..style = PaintingStyle.stroke
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
    }
    // Main line
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  Path _buildPath(
    List<ProjectionPoint> points,
    double Function(double) xPos,
    double Function(double) yPos,
  ) {
    final offsets = points
        .map((p) => Offset(xPos(p.year.toDouble()), yPos(p.amountMillions)))
        .toList();
    final path = Path()..moveTo(offsets.first.dx, offsets.first.dy);
    for (int j = 1; j < offsets.length; j++) {
      final prev = offsets[j - 1];
      final curr = offsets[j];
      final cpx = (prev.dx + curr.dx) / 2;
      path.cubicTo(cpx, prev.dy, cpx, curr.dy, curr.dx, curr.dy);
    }
    return path;
  }

  void _drawDashedH(
    Canvas canvas,
    double x1,
    double x2,
    double y,
    Paint paint,
  ) {
    const dashLen = 6.0, gapLen = 4.0;
    double x = x1;
    while (x < x2) {
      canvas.drawLine(
        Offset(x, y),
        Offset((x + dashLen).clamp(x1, x2), y),
        paint,
      );
      x += dashLen + gapLen;
    }
  }

  @override
  bool shouldRepaint(_DualChartPainter old) {
    if (old.goalMillions != goalMillions) return true;
    if (old.currentPoints.length != currentPoints.length) return true;
    if (old.optimizedPoints.length != optimizedPoints.length) return true;
    // Slider değişince nokta sayısı aynı kalır ama değerler değişir — son noktayı karşılaştır
    if (currentPoints.isNotEmpty &&
        old.currentPoints.isNotEmpty &&
        old.currentPoints.last.amountMillions !=
            currentPoints.last.amountMillions) {
      return true;
    }
    if (optimizedPoints.isNotEmpty &&
        old.optimizedPoints.isNotEmpty &&
        old.optimizedPoints.last.amountMillions !=
            optimizedPoints.last.amountMillions) {
      return true;
    }
    return false;
  }
}

// ─── Legend Dot ───────────────────────────────────────────────────────────────

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.onSurfaceVariant,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

// ─── AI Insight Card ──────────────────────────────────────────────────────────

class _AiInsightCard extends StatefulWidget {
  final SimulationViewModel vm;
  const _AiInsightCard({required this.vm});

  @override
  State<_AiInsightCard> createState() => _AiInsightCardState();
}

class _AiInsightCardState extends State<_AiInsightCard> {
  bool _expanded = false;
  static const int _collapsedMaxLines = 3;

  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;
    final text = vm.aiInsight;
    final isGenerating = vm.isGeneratingAi;
    final hasText = text.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spaceXL),
      decoration: BoxDecoration(
        color: AppColors.glass08,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(
          color: isGenerating
              ? AppColors.cyberBlue.withAlpha(60)
              : AppColors.glass12,
        ),
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
                child: isGenerating
                    ? const Padding(
                        padding: EdgeInsets.all(8),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.cyberBlue,
                        ),
                      )
                    : const Icon(
                        Icons.auto_awesome_rounded,
                        color: AppColors.cyberBlue,
                        size: 16,
                      ),
              ),
              const SizedBox(width: AppDimensions.spaceS),
              Text(
                isGenerating
                    ? 'YAPAY ZEKA ANALİZ EDİYOR...'
                    : 'YAPAY ZEKA ANALİZİ',
                style: AppTextStyles.labelSmall.copyWith(
                  color: isGenerating
                      ? AppColors.cyberBlue
                      : AppColors.cyberBlueDim,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceM),
          if (isGenerating && !hasText)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ShimmerLine(width: double.infinity),
                const SizedBox(height: 8),
                _ShimmerLine(width: 260),
                const SizedBox(height: 8),
                _ShimmerLine(width: 200),
              ],
            )
          else if (hasText)
            LayoutBuilder(
              builder: (context, constraints) {
                final textStyle = AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.onSurface,
                  fontFamily: 'Outfit',
                  fontSize: 13,
                  height: 1.6,
                );
                final textPainter = TextPainter(
                  text: TextSpan(text: text, style: textStyle),
                  maxLines: _collapsedMaxLines,
                  textDirection: TextDirection.ltr,
                )..layout(maxWidth: constraints.maxWidth);
                final isOverflowing = textPainter.didExceedMaxLines;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text,
                      style: textStyle,
                      maxLines: _expanded ? null : _collapsedMaxLines,
                      overflow: _expanded
                          ? TextOverflow.visible
                          : TextOverflow.fade,
                    ),
                    if (isOverflowing) ...[
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () => setState(() => _expanded = !_expanded),
                        child: Text(
                          _expanded ? 'Gizle' : 'Devamını gör',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.cyberBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            )
          else
            Text(
              'Yapay zeka analizi başlatılamadı.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          const SizedBox(height: AppDimensions.spaceL),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isGenerating
                  ? null
                  : () {
                      setState(() => _expanded = false);
                      context.read<SimulationViewModel>().generateAiInsight();
                    },
              icon: isGenerating
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded, size: 16),
              label: Text(
                isGenerating ? 'Analiz Ediliyor...' : 'Yeniden Analiz Et',
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: isGenerating
                      ? AppColors.cyberBlue.withAlpha(80)
                      : AppColors.cyberBlue,
                ),
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

// ─── Shimmer placeholder line ─────────────────────────────────────────────────

class _ShimmerLine extends StatefulWidget {
  final double width;
  const _ShimmerLine({required this.width});

  @override
  State<_ShimmerLine> createState() => _ShimmerLineState();
}

class _ShimmerLineState extends State<_ShimmerLine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = Tween<double>(
      begin: 0.15,
      end: 0.35,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, _) => Container(
        height: 12,
        width: widget.width,
        decoration: BoxDecoration(
          color: AppColors.cyberBlue.withValues(
            alpha: (_anim.value * 255).toDouble(),
          ),
          borderRadius: BorderRadius.circular(6),
        ),
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

// ─── What-If Sliders Panel ────────────────────────────────────────────────────

class _WhatIfSlidersPanel extends StatelessWidget {
  final SimulationViewModel vm;
  const _WhatIfSlidersPanel({required this.vm});

  @override
  Widget build(BuildContext context) {
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
            'WHAT-IF ANALİZİ',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.cyberBlueDim,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceM),
          _SliderRow(
            label: 'Günlük Ek Tasarruf',
            value: vm.extraDailySavings,
            min: 0,
            max: 500,
            displayValue: '${vm.extraDailySavings.round()} TL',
            onChanged: (v) =>
                context.read<SimulationViewModel>().setExtraDailySavings(v),
          ),
          const SizedBox(height: AppDimensions.spaceM),
          _SliderRow(
            label: 'Yıllık Bileşik Getiri',
            value: vm.annualReturnRateSlider * 100,
            min: 5,
            max: 25,
            displayValue: '%${(vm.annualReturnRateSlider * 100).round()}',
            onChanged: (v) => context
                .read<SimulationViewModel>()
                .setAnnualReturnRate(v / 100),
          ),
          const SizedBox(height: AppDimensions.spaceM),
          _SliderRow(
            label: 'Emeklilik Hedefi',
            value: vm.goalMillions.clamp(0.5, 20.0),
            min: 0.5,
            max: 20,
            displayValue: '${vm.goalMillions.toStringAsFixed(1)}M TL',
            onChanged: (v) =>
                context.read<SimulationViewModel>().setRetirementGoal(v),
          ),
        ],
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final String displayValue;
  final ValueChanged<double> onChanged;

  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.displayValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            Text(
              displayValue,
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.neonLime,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: AppColors.neonLime,
            inactiveTrackColor: AppColors.surfaceContainerHighest,
            thumbColor: AppColors.neonLime,
            overlayColor: AppColors.neonLime20,
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
