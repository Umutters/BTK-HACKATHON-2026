import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_text_styles.dart';
import '../../data/models/recurring_rule_model.dart';
import '../../viewmodels/recurring_rules_viewmodel.dart';
import '../widgets/organisms/recurring_rule_form_sheet.dart';

class RecurringRulesScreen extends StatefulWidget {
  const RecurringRulesScreen({super.key});

  @override
  State<RecurringRulesScreen> createState() => _RecurringRulesScreenState();
}

class _RecurringRulesScreenState extends State<RecurringRulesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecurringRulesViewModel>().loadRules();
    });
  }

  Future<void> _openForm({RecurringRuleModel? existing}) async {
    HapticFeedback.mediumImpact();
    final result = await showModalBottomSheet<RecurringRuleModel>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (_) => RecurringRuleFormSheet(existing: existing),
    );

    if (result == null || !mounted) return;

    final vm = context.read<RecurringRulesViewModel>();
    if (existing == null) {
      await vm.addRule(result);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${result.category} düzenli işlemi eklendi.'),
          backgroundColor: AppColors.surfaceContainerHigh,
        ),
      );
    } else {
      await vm.updateRule(result);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${result.category} güncellendi.'),
          backgroundColor: AppColors.surfaceContainerHigh,
        ),
      );
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    RecurringRuleModel rule,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLow,
        title: Text(
          'Düzenli İşlemi Sil',
          style: AppTextStyles.titleLarge.copyWith(color: AppColors.onSurface),
        ),
        content: Text(
          '"${rule.category}" kuralı silinecek. Emin misiniz?',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'İptal',
              style: TextStyle(color: AppColors.onSurfaceVariant),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Sil',
              style: const TextStyle(
                color: AppColors.cyberMagenta,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<RecurringRulesViewModel>().deleteRule(rule.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.onSurface,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Düzenli İşlemler', style: AppTextStyles.appBarTitle),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppDimensions.spaceL),
            child: IconButton(
              icon: const Icon(
                Icons.add_circle_outline_rounded,
                color: AppColors.cyberBlue,
              ),
              onPressed: () => _openForm(),
              tooltip: 'Yeni Kural Ekle',
            ),
          ),
        ],
      ),
      body: Consumer<RecurringRulesViewModel>(
        builder: (context, vm, _) {
          if (vm.state == RecurringRulesState.loading) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.cyberBlue,
                strokeWidth: 2,
              ),
            );
          }

          if (vm.state == RecurringRulesState.error) {
            return Center(
              child: Text(
                vm.errorMessage ?? 'Bir hata oluştu',
                style: AppTextStyles.bodyLarge,
              ),
            );
          }

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppDimensions.pagePaddingH,
                    AppDimensions.spaceL,
                    AppDimensions.pagePaddingH,
                    0,
                  ),
                  child: _SummaryCards(
                    monthlyIncome: vm.totalMonthlyIncome,
                    monthlyExpense: vm.totalMonthlyExpense,
                  ),
                ),
              ),
              if (vm.rules.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyState(onAdd: () => _openForm()),
                )
              else ...[
                if (vm.incomeRules.isNotEmpty) ...[
                  _SectionHeader(
                    label: 'GELİR (${vm.incomeRules.length})',
                    color: AppColors.neonLime,
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => _RuleCard(
                        rule: vm.incomeRules[i],
                        onEdit: () => _openForm(existing: vm.incomeRules[i]),
                        onDelete: () =>
                            _confirmDelete(context, vm.incomeRules[i]),
                        onToggle: () => vm.toggleActive(vm.incomeRules[i].id),
                      ),
                      childCount: vm.incomeRules.length,
                    ),
                  ),
                ],
                if (vm.expenseRules.isNotEmpty) ...[
                  _SectionHeader(
                    label: 'GİDER (${vm.expenseRules.length})',
                    color: AppColors.cyberMagenta,
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => _RuleCard(
                        rule: vm.expenseRules[i],
                        onEdit: () => _openForm(existing: vm.expenseRules[i]),
                        onDelete: () =>
                            _confirmDelete(context, vm.expenseRules[i]),
                        onToggle: () => vm.toggleActive(vm.expenseRules[i].id),
                      ),
                      childCount: vm.expenseRules.length,
                    ),
                  ),
                ],
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppDimensions.space3XL),
                ),
              ],
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        backgroundColor: AppColors.cyberBlue,
        foregroundColor: Colors.black,
        tooltip: 'Düzenli İşlem Ekle',
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

// ─── Özet kartlar ─────────────────────────────────────────────────────────────

class _SummaryCards extends StatelessWidget {
  final double monthlyIncome;
  final double monthlyExpense;

  const _SummaryCards({
    required this.monthlyIncome,
    required this.monthlyExpense,
  });

  String _fmt(double v) {
    final raw = v.toStringAsFixed(0);
    return raw.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final net = monthlyIncome - monthlyExpense;
    return Row(
      children: [
        Expanded(
          child: _SummaryTile(
            label: 'Aylık Gelir',
            amount: _fmt(monthlyIncome),
            color: AppColors.neonLime,
            icon: Icons.arrow_downward_rounded,
          ),
        ),
        const SizedBox(width: AppDimensions.spaceM),
        Expanded(
          child: _SummaryTile(
            label: 'Aylık Gider',
            amount: _fmt(monthlyExpense),
            color: AppColors.cyberMagenta,
            icon: Icons.arrow_upward_rounded,
          ),
        ),
        const SizedBox(width: AppDimensions.spaceM),
        Expanded(
          child: _SummaryTile(
            label: 'Net',
            amount: '${net >= 0 ? '+' : ''}${_fmt(net)}',
            color: net >= 0 ? AppColors.cyberBlue : AppColors.cyberMagenta,
            icon: net >= 0
                ? Icons.trending_up_rounded
                : Icons.trending_down_rounded,
          ),
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String amount;
  final Color color;
  final IconData icon;

  const _SummaryTile({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceM),
      decoration: BoxDecoration(
        color: AppColors.glass08,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: AppColors.glass12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: AppDimensions.iconS),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              amount,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.onSurfaceVariant,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bölüm başlığı ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final Color color;

  const _SectionHeader({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppDimensions.pagePaddingH,
          AppDimensions.spaceXL,
          AppDimensions.pagePaddingH,
          AppDimensions.spaceS,
        ),
        child: Text(
          label,
          style: AppTextStyles.labelCaps.copyWith(
            color: color,
            letterSpacing: 1.4,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}

// ─── Kural kartı ──────────────────────────────────────────────────────────────

class _RuleCard extends StatelessWidget {
  final RecurringRuleModel rule;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggle;

  const _RuleCard({
    required this.rule,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  static const _freqLabels = {
    'daily': 'Her gün',
    'weekly': 'Her hafta',
    'monthly': 'Her ay',
    'yearly': 'Her yıl',
  };

  String _freqDetail() {
    switch (rule.frequency) {
      case 'weekly':
        const days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
        final idx = (rule.dayOfWeek ?? 1) - 1;
        return '${_freqLabels['weekly']} (${days[idx.clamp(0, 6)]})';
      case 'monthly':
        return 'Her ayın ${rule.dayOfMonth ?? rule.startDate.day}. günü';
      case 'yearly':
        return 'Her yıl ${rule.startDate.month}. ayın ${rule.dayOfMonth ?? rule.startDate.day}. günü';
      default:
        return _freqLabels[rule.frequency] ?? rule.frequency;
    }
  }

  String _fmt(double v) {
    final raw = v.toStringAsFixed(0);
    return raw.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = rule.isIncome
        ? AppColors.neonLime
        : AppColors.cyberMagenta;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.pagePaddingH,
        0,
        AppDimensions.pagePaddingH,
        AppDimensions.spaceM,
      ),
      child: Dismissible(
        key: Key(rule.id),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) async {
          onDelete();
          return false; // ViewModel halleder
        },
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: AppDimensions.spaceXL),
          decoration: BoxDecoration(
            color: AppColors.cyberMagenta.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          ),
          child: const Icon(
            Icons.delete_outline_rounded,
            color: AppColors.cyberMagenta,
          ),
        ),
        child: GestureDetector(
          onTap: onEdit,
          child: Container(
            padding: const EdgeInsets.all(AppDimensions.spaceL),
            decoration: BoxDecoration(
              color: rule.isActive ? AppColors.glass08 : AppColors.glass05,
              borderRadius: BorderRadius.circular(AppDimensions.radiusL),
              border: Border.all(
                color: rule.isActive
                    ? accentColor.withValues(alpha: 0.2)
                    : AppColors.glass12,
              ),
            ),
            child: Row(
              children: [
                // İkon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  ),
                  child: Icon(
                    rule.isIncome
                        ? Icons.arrow_downward_rounded
                        : Icons.arrow_upward_rounded,
                    color: rule.isActive
                        ? accentColor
                        : AppColors.onSurfaceVariant,
                    size: AppDimensions.iconS,
                  ),
                ),
                const SizedBox(width: AppDimensions.spaceM),
                // Bilgi
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rule.category,
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: rule.isActive
                              ? AppColors.onSurface
                              : AppColors.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _freqDetail(),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                // Tutar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${rule.isIncome ? '+' : '-'}${_fmt(rule.amount)} TL',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: rule.isActive
                            ? accentColor
                            : AppColors.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Aktif toggle
                    GestureDetector(
                      onTap: onToggle,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: rule.isActive
                              ? accentColor.withValues(alpha: 0.12)
                              : AppColors.glass08,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: rule.isActive
                                ? accentColor.withValues(alpha: 0.3)
                                : AppColors.glass12,
                          ),
                        ),
                        child: Text(
                          rule.isActive ? 'Aktif' : 'Pasif',
                          style: TextStyle(
                            fontFamily: 'SpaceGrotesk',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: rule.isActive
                                ? accentColor
                                : AppColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Boş durum ────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.pagePaddingH),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.cyberBlue10,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.repeat_rounded,
                color: AppColors.cyberBlue,
                size: 36,
              ),
            ),
            const SizedBox(height: AppDimensions.spaceXL),
            Text(
              'Henüz düzenli işlem yok',
              style: AppTextStyles.titleLarge.copyWith(
                color: AppColors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.spaceM),
            Text(
              'Maaş, kira, abonelik gibi tekrar eden\ngelir ve giderlerinizi tanımlayın.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.spaceXXL),
            ElevatedButton.icon(
              onPressed: onAdd,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cyberBlue,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                ),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'İlk Kuralı Ekle',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
