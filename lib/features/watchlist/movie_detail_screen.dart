import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../core/constants/spacing.dart';
import '../../core/constants/text_styles.dart';
import '../../core/models/watchlist_item.dart';
import '../../core/services/movie_service.dart';

class MovieDetailScreen extends StatelessWidget {
  final WatchlistItem item;

  const MovieDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background:
                  item.backdropUrl != null && item.backdropUrl!.isNotEmpty
                  ? Image.network(
                      MovieService.getBackdropUrl(item.backdropUrl),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(color: Colors.grey),
                    )
                  : Container(color: Colors.grey),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    item.title,
                    style: AppTextStyles.h1.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Metadata Row (Rating, Year, Genre)
                  Row(
                    children: [
                      Icon(Iconsax.star1, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '${item.rating.toStringAsFixed(1)}/10',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      if (item.releaseDate != null) ...[
                        Text(
                          item.releaseDate!.split('-').first,
                          style: AppTextStyles.bodyMedium,
                        ),
                        const SizedBox(width: AppSpacing.md),
                      ],
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.genre,
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Overview Section
                  Text('Overview', style: AppTextStyles.h3),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    item.overview ?? 'No description available.',
                    style: AppTextStyles.bodyLarge.copyWith(height: 1.5),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
