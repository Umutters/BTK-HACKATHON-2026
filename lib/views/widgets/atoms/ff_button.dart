import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';

enum FfButtonVariant { primary, outlined, ghost }

class FfButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final FfButtonVariant variant;
  final double? width;

  const FfButton({
    super.key,
    required this.label,
    this.onTap,
    this.variant = FfButtonVariant.primary,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: switch (variant) {
        FfButtonVariant.primary => _PrimaryButton(label: label, onTap: onTap),
        FfButtonVariant.outlined => _OutlinedButton(label: label, onTap: onTap),
        FfButtonVariant.ghost => _GhostButton(label: label, onTap: onTap),
      },
    );
  }
}

/// Neon Lime pill — primary CTA with lime glow
class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _PrimaryButton({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        boxShadow: const [
          BoxShadow(
            color: AppColors.neonLime30,
            blurRadius: 16,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.neonLime,
          foregroundColor: AppColors.background,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spaceXXL,
            vertical: AppDimensions.spaceL,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
        child: Text(
          label,
          style: AppTextStyles.labelLarge.copyWith(
            color: AppColors.background,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

/// Cyber Blue outlined — secondary action
class _OutlinedButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _OutlinedButton({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.cyberBlue,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spaceL,
          vertical: AppDimensions.spaceM,
        ),
        side: const BorderSide(color: AppColors.cyberBlue, width: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        ),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelLarge.copyWith(color: AppColors.cyberBlue),
      ),
    );
  }
}

/// Ghost — white text, low-opacity hover
class _GhostButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _GhostButton({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.onSurface,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spaceL,
          vertical: AppDimensions.spaceM,
        ),
      ),
      child: Text(label, style: AppTextStyles.labelLarge),
    );
  }
}
