import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../core/constants/spacing.dart';
import '../../core/constants/text_styles.dart';
import '../../core/models/watchlist_item.dart';
import '../../core/services/movie_service.dart';

class FavoritesScreen extends StatelessWidget {
  final List<WatchlistItem> favoriteItems;

  const FavoritesScreen({super.key, required this.favoriteItems});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Favorites')),
      body: favoriteItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Iconsax.heart, size: 64, color: Colors.grey),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'No favorites yet',
                    style: AppTextStyles.bodyLarge.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: favoriteItems.length,
              itemBuilder: (context, index) {
                final item = favoriteItems[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(8),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        width: 40,
                        height: 60,
                        color: Colors.grey[800],
                        child: item.imageUrl.isNotEmpty
                            ? Image.network(
                                MovieService.getPosterUrl(item.imageUrl),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(
                                      Iconsax.video,
                                      size: 20,
                                      color: Colors.white54,
                                    ),
                              )
                            : const Icon(
                                Iconsax.video,
                                size: 20,
                                color: Colors.white54,
                              ),
                      ),
                    ),
                    title: Text(item.title, style: AppTextStyles.bodyLarge),
                    subtitle: Text(item.genre, style: AppTextStyles.bodyMedium),
                    trailing: const Icon(Iconsax.heart5, color: Colors.red),
                  ),
                );
              },
            ),
    );
  }
}
