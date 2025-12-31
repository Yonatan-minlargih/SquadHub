import 'package:equatable/equatable.dart';
import '../../../core/models/watchlist_item.dart';

class WatchlistState extends Equatable {
  final List<WatchlistItem> items;
  final Set<String> likedItems;
  final bool isLoading;

  const WatchlistState({
    required this.items,
    required this.likedItems,
    this.isLoading = false,
  });

  WatchlistState copyWith({
    List<WatchlistItem>? items,
    Set<String>? likedItems,
    bool? isLoading,
  }) {
    return WatchlistState(
      items: items ?? this.items,
      likedItems: likedItems ?? this.likedItems,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [items, likedItems, isLoading];
}


