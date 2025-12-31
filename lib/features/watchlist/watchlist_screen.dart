import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import '../../core/constants/spacing.dart';
import '../../core/constants/text_styles.dart';
import '../../core/models/watchlist_item.dart';
import '../../core/services/movie_service.dart';
import 'bloc/watchlist_bloc.dart';
import 'bloc/watchlist_event.dart';
import 'bloc/watchlist_state.dart';
import '../../core/widgets/empty_state.dart';
import 'movie_detail_screen.dart';
import '../../core/services/notification_service.dart';
import '../auth/bloc/auth_bloc.dart';

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  static void showAddItemModal(BuildContext context) {
    final titleController = TextEditingController();
    final genreController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.add_circle_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text('Add to Watchlist', style: AppTextStyles.h2),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: genreController,
              decoration: const InputDecoration(labelText: 'Genre'),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: () {
                if (titleController.text.isNotEmpty) {
                  final squadId = context.read<AuthBloc>().state.squadId;
                  if (squadId == null) return;

                  context.read<WatchlistBloc>().add(
                    WatchlistAddItem(
                      title: titleController.text,
                      genre: genreController.text.isEmpty
                          ? 'Unknown'
                          : genreController.text,
                      squadId: squadId,
                    ),
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Add Movie/Series'),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final squadId = context.read<AuthBloc>().state.squadId;
    if (squadId != null) {
      context.read<WatchlistBloc>().add(WatchlistLoadItems(squadId));
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildList(
    BuildContext context,
    List<WatchlistItem> items,
    Set<String> likedItems,
    ThemeData theme,
  ) {
    if (items.isEmpty) {
      return EmptyState(
        icon: Icons.movie_outlined,
        title: 'No matches yet!',
        description: 'Add movies and get votes from your squad.',
        onActionPressed: () => WatchlistScreen.showAddItemModal(context),
        actionLabel: 'Add Movie',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isLiked = likedItems.contains(item.id);

        return Dismissible(
          key: Key(item.id),
          direction: DismissDirection.endToStart,
          background: Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            decoration: BoxDecoration(
              color: Colors.red.shade400,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: const Icon(Icons.delete_outline, color: Colors.white),
          ),
          onDismissed: (direction) {
            context.read<WatchlistBloc>().add(WatchlistRemoveItem(item.id));
            NotificationService().showTopNotification(
              context,
              title: 'Item Removed',
              body: '${item.title} removed from watchlist',
              icon: Icons.delete_outline,
            );
          },
          child: TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 200 + (index * 30)),
            tween: Tween(begin: 0.0, end: 1.0),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: Opacity(opacity: value, child: child),
              );
            },
            child: Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              clipBehavior: Clip.antiAlias,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MovieDetailScreen(item: item),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      // Movie Poster
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 50,
                          height: 75,
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: item.imageUrl.isNotEmpty
                              ? Image.network(
                                  MovieService.getPosterUrl(item.imageUrl),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Icon(
                                        Iconsax.video,
                                        size: 24,
                                        color: theme.colorScheme.onSurface
                                            .withValues(alpha: 0.4),
                                      ),
                                )
                              : Icon(
                                  Iconsax.video,
                                  size: 24,
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.4,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      // Movie Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: AppTextStyles.bodyLarge.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Row(
                              children: [
                                Icon(
                                  Iconsax.tag,
                                  size: 14,
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  item.genre,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.7),
                                  ),
                                ),
                                if (item.rating > 0) ...[
                                  const SizedBox(width: AppSpacing.sm),
                                  Icon(
                                    Icons.star,
                                    size: 14,
                                    color: Colors.amber,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    item.rating.toStringAsFixed(1),
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.7),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Votes and Like Button
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  item.votes.toString(),
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  isLiked ? Iconsax.heart5 : Iconsax.heart,
                                  color: isLiked
                                      ? Colors.red
                                      : theme.colorScheme.onSurfaceVariant,
                                  size: 22,
                                ),
                              ],
                            ),
                            onPressed: () {
                              context.read<WatchlistBloc>().add(
                                WatchlistToggleLike(item),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<WatchlistBloc, WatchlistState>(
      builder: (context, state) {
        // Matched = Items with at least 2 votes
        final matchedItems = state.items.where((i) => i.votes >= 2).toList();

        return Column(
          children: [
            // Enhanced Header
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Iconsax.video,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Watchlist', style: AppTextStyles.h2),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Find your next watch',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.7,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Tab Bar
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: theme.colorScheme.primary,
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor: theme.colorScheme.onSurface.withValues(
                  alpha: 0.6,
                ),
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Matched'),
                        const SizedBox(width: AppSpacing.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${matchedItems.length}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Total List'),
                        const SizedBox(width: AppSpacing.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${state.items.length}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildList(context, matchedItems, state.likedItems, theme),
                  _buildList(context, state.items, state.likedItems, theme),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
