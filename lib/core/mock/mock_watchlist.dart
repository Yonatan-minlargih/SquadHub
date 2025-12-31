import '../models/watchlist_item.dart';

final List<WatchlistItem> mockWatchlist = [
  WatchlistItem(
    id: '1',
    title: 'Inception',
    genre: 'Sci-Fi',
    rating: 8.8,
    imageUrl: '',
    votedBy: ['1', '2', '3', '4', '5'],
    squadId: 'mock-squad-1',
  ),
  WatchlistItem(
    id: '2',
    title: 'The Dark Knight',
    genre: 'Action',
    rating: 9.0,
    imageUrl: '',
    votedBy: ['1', '2', '3', '4'],
    squadId: 'mock-squad-1',
  ),
  WatchlistItem(
    id: '3',
    title: 'Interstellar',
    genre: 'Sci-Fi',
    rating: 8.6,
    imageUrl: '',
    votedBy: ['1', '2', '3'],
    squadId: 'mock-squad-1',
  ),
];
