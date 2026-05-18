import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_text_styles.dart';
import '../../viewmodels/data_management_viewmodel.dart';

class DataManagementScreen extends StatefulWidget {
  const DataManagementScreen({super.key});

  @override
  State<DataManagementScreen> createState() => _DataManagementScreenState();
}

class _DataManagementScreenState extends State<DataManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DataManagementViewModel>().loadDataInfo();
    });
  }

  Future<void> _showClearDataDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLow,
        title: Text(
          'Yerel Verileri Temizle',
          style: AppTextStyles.titleLarge.copyWith(color: AppColors.onSurface),
        ),
        content: Text(
          'Tüm yerel kayıtlar silinecek. Bu işlem geri alınamaz. Devam etmek istiyor musunuz?',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'İptal',
              style: TextStyle(color: AppColors.onSurfaceVariant),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Temizle',
              style: TextStyle(color: AppColors.cyberMagenta),
            ),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      if (!mounted) return;
      final vm = context.read<DataManagementViewModel>();
      await vm.clearLocalData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Yerel veriler temizlendi'),
          backgroundColor: AppColors.surfaceContainerHigh,
        ),
      );
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
        title: Text('Veri Yönetimi', style: AppTextStyles.appBarTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<DataManagementViewModel>(
        builder: (context, vm, _) {
          return ListView(
            padding: const EdgeInsets.all(AppDimensions.pagePaddingH),
            children: [
              // Introduction
              Padding(
                padding: const EdgeInsets.only(bottom: AppDimensions.spaceXL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Veri Yönetimi',
                      style: AppTextStyles.titleLarge.copyWith(
                        color: AppColors.neonLime,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spaceM),
                    Text(
                      'Yerel verilerinizi yönetme ve yedekleme',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              // Data info card
              Container(
                padding: const EdgeInsets.all(AppDimensions.spaceL),
                decoration: BoxDecoration(
                  color: AppColors.glass08,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
                  border: Border.all(color: AppColors.glass12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.cyberBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.storage_rounded,
                            color: AppColors.cyberBlue,
                          ),
                        ),
                        const SizedBox(width: AppDimensions.spaceL),
                        Text(
                          'Depolama Bilgisi',
                          style: AppTextStyles.titleMedium.copyWith(
                            color: AppColors.onSurface,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spaceL),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kullanılan Depolama',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${(vm.localDataSizeKb / 1024).toStringAsFixed(2)} MB',
                              style: AppTextStyles.titleMedium.copyWith(
                                color: AppColors.cyberBlue,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Son Yedek',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              vm.lastBackupDate == null
                                  ? 'Hiç'
                                  : _formatDate(vm.lastBackupDate!),
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.neonLime,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.spaceXL),

              // Auto backup toggle
              _DataManagementCard(
                title: 'Otomatik Yedekleme',
                subtitle: 'Verileri otomatik olarak yedekle',
                icon: Icons.backup_rounded,
                value: vm.autoBackup,
                onChanged: vm.toggleAutoBackup,
                accentColor: AppColors.neonLime,
              ),
              const SizedBox(height: AppDimensions.spaceL),

              // Backup frequency (if auto backup is enabled)
              if (vm.autoBackup) ...[
                Container(
                  padding: const EdgeInsets.all(AppDimensions.spaceL),
                  decoration: BoxDecoration(
                    color: AppColors.glass08,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
                    border: Border.all(color: AppColors.glass12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.neonLime.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.schedule_rounded,
                              color: AppColors.neonLime,
                            ),
                          ),
                          const SizedBox(width: AppDimensions.spaceL),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Yedekleme Sıklığı',
                                  style: AppTextStyles.titleMedium.copyWith(
                                    color: AppColors.onSurface,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${vm.autoBackupFrequency} günde bir',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.spaceL),
                      Slider(
                        value: vm.autoBackupFrequency.toDouble(),
                        min: 1,
                        max: 30,
                        divisions: 29,
                        label: '${vm.autoBackupFrequency}',
                        activeColor: AppColors.neonLime,
                        onChanged: (value) =>
                            vm.setAutoBackupFrequency(value.toInt()),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceXL),
              ],

              // Action buttons
              Column(
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Yedekleme oluşturuluyor...'),
                          backgroundColor: AppColors.surfaceContainerHigh,
                        ),
                      );
                      await context
                          .read<DataManagementViewModel>()
                          .createBackup();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Yedekleme başarılı!'),
                            backgroundColor: AppColors.neonLime,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.cyberBlue,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppDimensions.spaceL,
                      ),
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusL,
                        ),
                      ),
                    ),
                    child: Text(
                      'Şimdi Yedekle',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spaceM),
                  ElevatedButton(
                    onPressed: () async {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Yedekleme geri yükleniyorç..'),
                          backgroundColor: AppColors.surfaceContainerHigh,
                        ),
                      );
                      await context
                          .read<DataManagementViewModel>()
                          .restoreBackup();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Yedekleme geri yüklendi!'),
                            backgroundColor: AppColors.neonLime,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.cyberMagenta,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppDimensions.spaceL,
                      ),
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusL,
                        ),
                      ),
                    ),
                    child: Text(
                      'Yedeklemeyi Geri Yükle',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spaceM),
                  ElevatedButton(
                    onPressed: _showClearDataDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.cyberMagenta.withValues(
                        alpha: 0.2,
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: AppDimensions.spaceL,
                      ),
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusL,
                        ),
                        side: const BorderSide(color: AppColors.cyberMagenta),
                      ),
                    ),
                    child: Text(
                      'Yerel Verileri Temizle',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.cyberMagenta,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Bugün';
    } else if (diff.inDays == 1) {
      return 'Dün';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} gün önce';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class _DataManagementCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color accentColor;

  const _DataManagementCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceL),
      decoration: BoxDecoration(
        color: AppColors.glass08,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        border: Border.all(color: AppColors.glass12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accentColor),
          ),
          const SizedBox(width: AppDimensions.spaceL),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.spaceL),
          Switch(value: value, onChanged: onChanged, activeColor: accentColor),
        ],
      ),
    );
  }
}
