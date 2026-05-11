import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

class AiOracleScreen extends StatelessWidget {
  const AiOracleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('AI Oracle', style: AppTextStyles.appBarTitle),
      ),
      body: Center(
        child: Text('AI Oracle — Coming Soon', style: AppTextStyles.bodyLarge),
      ),
    );
  }
}
