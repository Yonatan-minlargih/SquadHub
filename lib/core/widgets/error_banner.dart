import 'package:flutter/material.dart';
import '../constants/spacing.dart';
import '../constants/text_styles.dart';

class ErrorBanner extends StatelessWidget {
  final String? error;
  final bool isSuccess;

  const ErrorBanner({super.key, this.error, this.isSuccess = false});

  @override
  Widget build(BuildContext context) {
    if (error == null) return const SizedBox.shrink();

    final Color primaryColor = isSuccess ? Colors.green : Colors.red;
    final Color bgColor = primaryColor.withValues(alpha: 0.1);
    final Color borderColor = primaryColor.withValues(alpha: 0.3);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor),
        ),
        child: Text(
          error!,
          style: AppTextStyles.bodyMedium.copyWith(color: primaryColor),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
