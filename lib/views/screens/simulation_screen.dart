import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
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
                    _FinanceSnapshotCard(vm: vm),
                    const SizedBox(height: 16),
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
          'FİNANSAL FOTOĞRAF',
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.onSurfaceVariant,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 6),
        Text(vm.goalName, style: AppTextStyles.titleLarge),
        const SizedBox(height: 4),
        Text(
          '${vm.routeYears} yıllık ufuk • ${vm.startYear} - ${vm.endYear}${vm.targetAge != null ? ' • yaklaşık ${vm.targetAge} yaş' : ''}',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.onSurfaceVariant,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _FinanceSnapshotCard extends StatelessWidget {
  final SimulationViewModel vm;
  const _FinanceSnapshotCard({required this.vm});

  @override
  Widget build(BuildContext context) {
    final monthlyNet = vm.monthlyNetCashflow;
    final runway = vm.emergencyRunwayMonths;
    final savingsRate = vm.savingsRatePercent;
    final safeBudget = vm.safeMonthlyBudget;

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
            'NAKİT AKIŞI ZEMİNİ',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.cyberBlueDim,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Bilgi için metrik kutusuna basılı tut',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceM),
          Row(
            children: [
              Expanded(
                child: _MetricBox(
                  label: 'Aylık net akış',
                  value:
                      '${monthlyNet.toStringAsFixed(0)} ${vm.currencySymbol}/ay',
                  infoTitle: 'Aylık net akış',
                  infoText:
                      'Formül: Aylık gelir - aylık gider. Tasarruf transferi bu değerden ayrıca düşülmez.',
                ),
              ),
              const SizedBox(width: AppDimensions.spaceM),
              Expanded(
                child: _MetricBox(
                  label: 'Tasarruf oranı',
                  value: '%${savingsRate.toStringAsFixed(1)}',
                  infoTitle: 'Tasarruf oranı',
                  infoText:
                      'Formül: (Aylık tasarruf transferi / aylık gelir) x 100. Gelir yoksa 0 kabul edilir.',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceS),
          Row(
            children: [
              Expanded(
                child: _MetricBox(
                  label: 'Acil fon dayanıklılığı',
                  value: '${runway.toStringAsFixed(1)} ay',
                  infoTitle: 'Acil fon dayanıklılığı',
                  infoText:
                      'Formül: Tasarruf havuzu / aylık zorunlu gider tabanı. Havuzun kaç ay yeteceğini gösterir.',
                ),
              ),
              const SizedBox(width: AppDimensions.spaceM),
              Expanded(
                child: _MetricBox(
                  label: 'Güvenli aylık bütçe',
                  value:
                      '${safeBudget.toStringAsFixed(0)} ${vm.currencySymbol}/ay',
                  infoTitle: 'Güvenli aylık bütçe',
                  infoText:
                      'Formül: max(0, aylık gelir - aylık gider). Negatifse 0 gösterilir.',
                ),
              ),
            ],
          ),
        ],
      ),
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
            '30 GÜNLÜK GERÇEK TASARRUF ORTALAMASI',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.onSurfaceVariant,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Bilgi için metrik kutusuna basılı tut',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceS),
          Row(
            children: [
              Expanded(
                child: _MetricBox(
                  label: 'Günlük ort. aktarım',
                  value: '${daily30.toStringAsFixed(1)} ${vm.currencySymbol}',
                  infoTitle: 'Günlük ortalama aktarım',
                  infoText:
                      'Son 30 günlük aktarım verisinden uç değerler kırpılarak hesaplanan ortalamadır.',
                ),
              ),
              const SizedBox(width: AppDimensions.spaceM),
              Expanded(
                child: _MetricBox(
                  label: 'Aylık aktarım',
                  value:
                      '${monthly.toStringAsFixed(0)} ${vm.currencySymbol}/ay',
                  infoTitle: 'Aylık aktarım',
                  infoText:
                      'Formül: Günlük ortalama aktarım x 30. Tahmini aylık birikim etkisini gösterir.',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceS),
          Row(
            children: [
              Expanded(
                child: _MetricBox(
                  label: '7 günlük trend',
                  value:
                      '$trendArrow $trendText (%${trendDiff.toStringAsFixed(1)})',
                  infoTitle: '7 günlük trend',
                  infoText:
                      'Son 7 gün ortalaması ile 30 gün ortalaması kıyaslanır. Fark yüzde olarak gösterilir.',
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
  final String? infoTitle;
  final String? infoText;

  const _MetricBox({
    required this.label,
    required this.value,
    this.infoTitle,
    this.infoText,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: (infoText == null || infoText!.trim().isEmpty)
          ? null
          : () => _showMetricInfo(context, infoTitle ?? label, infoText!),
      child: Container(
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
      ),
    );
  }
}

void _showMetricInfo(BuildContext context, String title, String text) {
  showDialog<void>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        backgroundColor: AppColors.surfaceContainerLow,
        title: Text(
          title,
          style: AppTextStyles.titleLarge.copyWith(color: AppColors.onSurface),
        ),
        content: Text(
          text,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.onSurfaceVariant,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Tamam',
              style: TextStyle(color: AppColors.cyberBlue),
            ),
          ),
        ],
      );
    },
  );
}

// ─── Projection Chart Card ────────────────────────────────────────────────────

class _ProjectionChartCard extends StatelessWidget {
  final SimulationViewModel vm;
  const _ProjectionChartCard({required this.vm});

  @override
  Widget build(BuildContext context) {
    final viewportWidth =
        MediaQuery.sizeOf(context).width -
        (AppDimensions.pagePaddingH * 2) -
        (AppDimensions.spaceL * 2);
    final currentSpots = vm.currentSeries
        .map((p) => FlSpot(p.monthIndex.toDouble(), p.amountMillions))
        .toList();
    final optimizedSpots = vm.optimizedSeries
        .map((p) => FlSpot(p.monthIndex.toDouble(), p.amountMillions))
        .toList();
    final allValues = [
      ...currentSpots.map((s) => s.y),
      ...optimizedSpots.map((s) => s.y),
      vm.goalMillions,
    ];
    final maxY = max(0.1, allValues.reduce(max) * 1.12);
    final maxX = max(12, vm.routeYears * 12).toDouble();
    final chartWidth = max(viewportWidth, (maxX / 72.0) * viewportWidth);

    final crisisLines = vm.crisisMarkers.map((marker) {
      return VerticalLine(
        x: marker.monthIndex.toDouble(),
        color: AppColors.cyberMagenta.withAlpha(180),
        strokeWidth: 1.2,
        dashArray: [6, 6],
      );
    }).toList();

    return Container(
      width: double.infinity,
      height: 320,
      padding: const EdgeInsets.all(AppDimensions.spaceL),
      decoration: BoxDecoration(
        color: AppColors.glass08,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: AppColors.glass12),
      ),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: SizedBox(
                width: chartWidth,
                child: LineChart(
                  LineChartData(
                    minX: 0,
                    maxX: maxX,
                    minY: 0,
                    maxY: maxY,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: maxY / 4,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: AppColors.glass12,
                        strokeWidth: 1,
                        dashArray: [4, 6],
                      ),
                    ),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 44,
                          interval: maxY / 4,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              '${value.toStringAsFixed(1)}M',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.onSurfaceVariant,
                                fontSize: 9,
                              ),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28,
                          interval: 12,
                          getTitlesWidget: (value, meta) {
                            final yearStep = vm.routeYears <= 12 ? 2 : 5;
                            final monthStep = yearStep * 12;

                            final isStart = value == 0;
                            final isEnd = value == maxX;
                            final isStepped =
                                value.toInt() > 0 &&
                                value.toInt() % monthStep == 0;

                            if (!isStart && !isEnd && !isStepped) {
                              return const SizedBox.shrink();
                            }

                            final year = vm.startYear + (value ~/ 12).toInt();
                            return Text(
                              '$year',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.cyberBlueDim,
                                fontSize: 10,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    extraLinesData: ExtraLinesData(
                      horizontalLines: [
                        HorizontalLine(
                          y: vm.goalMillions,
                          color: AppColors.cyberMagenta.withAlpha(180),
                          strokeWidth: 1.5,
                          dashArray: [8, 6],
                        ),
                      ],
                      verticalLines: crisisLines,
                    ),
                    lineTouchData: LineTouchData(
                      enabled: true,
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (_) => AppColors.surfaceContainerLow,
                        getTooltipItems: (spots) {
                          return spots.map((spot) {
                            final isOptimized = spot.barIndex == 1;
                            final color = isOptimized
                                ? AppColors.neonLime
                                : AppColors.cyberBlue;
                            return LineTooltipItem(
                              '${isOptimized ? 'Optimize' : 'Mevcut'}\n${spot.y.toStringAsFixed(2)}M ${vm.currencySymbol}',
                              AppTextStyles.labelSmall.copyWith(
                                color: color,
                                fontWeight: FontWeight.w700,
                              ),
                            );
                          }).toList();
                        },
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: currentSpots,
                        isCurved: true,
                        barWidth: 2.5,
                        color: AppColors.cyberBlue,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: AppColors.cyberBlue.withAlpha(24),
                        ),
                      ),
                      LineChartBarData(
                        spots: optimizedSpots,
                        isCurved: true,
                        barWidth: 3.0,
                        color: AppColors.neonLime,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: AppColors.neonLime.withAlpha(20),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 14,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: const [
              _LegendDot(color: AppColors.cyberBlue, label: 'Mevcut Rota'),
              _LegendDot(color: AppColors.neonLime, label: 'Optimize Rota'),
              _LegendDot(color: AppColors.cyberMagenta, label: 'Hedef'),
              _LegendDot(
                color: AppColors.cyberMagenta,
                label: 'Kriz Kırılması',
              ),
            ],
          ),
        ],
      ),
    );
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
    final scenarioReason = vm.aiScenarioReason;
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
          if (scenarioReason.trim().isNotEmpty) ...[
            const SizedBox(height: AppDimensions.spaceM),
            Text(
              'AI Senaryo Notu: $scenarioReason',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.neonLime,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: AppDimensions.spaceL),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isGenerating
                  ? null
                  : () {
                      setState(() => _expanded = false);
                      context
                          .read<SimulationViewModel>()
                          .applyAiScenarioSuggestion();
                    },
              icon: isGenerating
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_graph_rounded, size: 16),
              label: Text(
                isGenerating
                    ? 'AI Senaryosu Hesaplanıyor...'
                    : 'AI Senaryosunu Uygula',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.neonLime,
                foregroundColor: AppColors.background,
                disabledBackgroundColor: AppColors.surfaceContainerHigh,
                padding: const EdgeInsets.symmetric(vertical: 12),
                textStyle: AppTextStyles.labelMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.spaceS),
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
            'AYLIK KALEM ETKISI',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.cyberBlueDim,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceM),
          if (rows.isEmpty)
            Text(
              'Kalem etkisini göstermek için yeterli işlem verisi yok.',
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
        .where((r) => r.year > vm.startYear && (r.year - vm.startYear) % 2 == 0)
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
            'İleriye Dönük Hedef TABLOSU',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.cyberBlueDim,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceS),
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
                  'PORTFÖY',
                  textAlign: TextAlign.right,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'HEDEF AÇIĞI',
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
            'SENARYO TESTİ',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.cyberBlueDim,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceM),
          _SliderRow(
            label: 'Bitiş Yılı',
            value: vm.endYear.toDouble(),
            min: (vm.startYear + 1).toDouble(),
            max: (vm.startYear + 60).toDouble(),
            displayValue:
                '${vm.endYear}${vm.targetAge != null ? ' • ${vm.targetAge} yaş' : ''}',
            onChanged: (v) => context
                .read<SimulationViewModel>()
                .setProjectionHorizonYears(v - vm.startYear),
          ),
          const SizedBox(height: AppDimensions.spaceM),
          _SliderRow(
            label: 'Günlük Ek Tasarruf',
            value: vm.extraDailySavings,
            min: 0,
            max: vm.maxExtraDailySavings,
            displayValue:
                '${vm.extraDailySavings.round()} TL / max ${vm.maxExtraDailySavings.round()} TL',
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
