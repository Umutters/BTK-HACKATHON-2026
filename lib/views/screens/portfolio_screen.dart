import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

class PortfolioScreen extends StatelessWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('Portfolio', style: AppTextStyles.appBarTitle),
      ),
      body: Center(
        child: Text('Portfolio — Coming Soon', style: AppTextStyles.bodyLarge),
      ),
    );
  }
}
