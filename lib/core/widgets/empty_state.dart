import 'package:flutter/material.dart';
import '../constants/spacing.dart';
import '../constants/text_styles.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback? onActionPressed;
  final String? actionLabel;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryActionPressed;
  final Widget? extra;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.onActionPressed,
    this.actionLabel,
    this.secondaryActionLabel,
    this.onSecondaryActionPressed,
    this.extra,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 600),
              tween: Tween(begin: 0.0, end: 1.0),
              curve: Curves.easeOutBack,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: 0.5 + (0.5 * value),
                  child: Opacity(
                    opacity: value.clamp(0.0, 1.0),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withValues(
                          alpha: 0.1,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        size: 80,
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              title,
              style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              description,
              style: AppTextStyles.bodyMedium.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            if (extra != null) ...[
              const SizedBox(height: AppSpacing.lg),
              extra!,
            ],
            if (onActionPressed != null && actionLabel != null) ...[
              const SizedBox(height: AppSpacing.xl),
              FilledButton.icon(
                onPressed: onActionPressed,
                icon: const Icon(Icons.add),
                label: Text(actionLabel!),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(200, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              if (onSecondaryActionPressed != null &&
                  secondaryActionLabel != null) ...[
                const SizedBox(height: AppSpacing.md),
                OutlinedButton(
                  onPressed: onSecondaryActionPressed,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(200, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(secondaryActionLabel!),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
