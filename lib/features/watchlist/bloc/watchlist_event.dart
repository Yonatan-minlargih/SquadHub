import 'package:equatable/equatable.dart';
import '../../../core/models/watchlist_item.dart';

abstract class WatchlistEvent extends Equatable {
  const WatchlistEvent();

  @override
  List<Object?> get props => [];
}

class WatchlistLoadItems extends WatchlistEvent {
  final String squadId;
  const WatchlistLoadItems(this.squadId);

  @override
  List<Object?> get props => [squadId];
}

class WatchlistUpdate extends WatchlistEvent {
  final List<WatchlistItem> items;
  const WatchlistUpdate(this.items);

  @override
  List<Object?> get props => [items];
}

class WatchlistToggleLike extends WatchlistEvent {
  final WatchlistItem item;

  const WatchlistToggleLike(this.item);

  @override
  List<Object?> get props => [item];
}

class WatchlistAddItem extends WatchlistEvent {
  final String title;
  final String genre;
  final String squadId;

  const WatchlistAddItem({
    required this.title,
    required this.genre,
    required this.squadId,
  });

  @override
  List<Object?> get props => [title, genre, squadId];
}

class WatchlistFetchMovieData extends WatchlistEvent {
  final WatchlistItem item;

  const WatchlistFetchMovieData(this.item);

  @override
  List<Object?> get props => [item];
}

class WatchlistRemoveItem extends WatchlistEvent {
  final String itemId;

  const WatchlistRemoveItem(this.itemId);

  @override
  List<Object?> get props => [itemId];
}
