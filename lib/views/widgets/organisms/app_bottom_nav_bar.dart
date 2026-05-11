import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';

/// Floating glass bottom nav bar with Cyber Blue top-border glow
class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const _items = [
    _NavItemData(icon: Icons.grid_view_rounded, label: 'ANA SAYFA'),
    _NavItemData(icon: Icons.auto_awesome_rounded, label: 'AI SOHBET'),
    _NavItemData(icon: Icons.show_chart_rounded, label: 'SİMÜLASYON'),
  ];

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AppDimensions.blurNav,
          sigmaY: AppDimensions.blurNav,
        ),
        child: Container(
          height: AppDimensions.bottomNavHeight,
          decoration: const BoxDecoration(
            color: AppColors.glass08,
            border: Border(
              top: BorderSide(color: AppColors.cyberBlue, width: 1),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              _items.length,
              (i) => _NavItem(
                data: _items[i],
                index: i,
                currentIndex: currentIndex,
                onTap: onTap,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final String label;
  const _NavItemData({required this.icon, required this.label});
}

class _NavItem extends StatelessWidget {
  final _NavItemData data;
  final int index;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.data,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = index == currentIndex;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 90,
        height: AppDimensions.bottomNavHeight,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              data.icon,
              color: isSelected ? AppColors.neonLime : AppColors.cyberBlue,
              size: AppDimensions.navIconSize,
            ),
            const SizedBox(height: 3),
            if (isSelected) ...[
              Text(
                data.label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.neonLime,
                  fontSize: 9,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 3),
              Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.neonLime,
                  boxShadow: [
                    BoxShadow(color: AppColors.neonLime50, blurRadius: 6),
                  ],
                ),
              ),
            ] else
              Text(
                data.label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.outline,
                  fontSize: 9,
                  letterSpacing: 0.8,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
