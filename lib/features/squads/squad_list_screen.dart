import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/spacing.dart';
import '../../core/constants/text_styles.dart';
import '../../core/mock/mock_squad.dart';
import '../../routes/app_routes.dart';

class SquadListScreen extends StatelessWidget {
  const SquadListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text('Squads', style: AppTextStyles.h2),
        leading: IconButton(
          icon: const Icon(Iconsax.menu, color: AppColors.textPrimary),
          onPressed: () {},
        ),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.user, color: AppColors.textPrimary),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: mockSquads.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) {
          final squad = mockSquads[index];
          return GestureDetector(
            onTap: () => Navigator.pushNamed(context, AppRoutes.squadHub),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(squad.name, style: AppTextStyles.h3),
                      Row(
                        children: [
                          const Icon(
                            Iconsax.people,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${squad.memberCount} Members',
                            style: AppTextStyles.bodyMedium,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Recent Activity:',
                    style: AppTextStyles.bodyMedium.copyWith(fontSize: 12),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Icon(
                        squad.activityIcon,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        squad.recentActivity,
                        style: AppTextStyles.bodyLarge,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () {},
        child: const Icon(Iconsax.add, color: Colors.white),
      ),
    );
  }
}
