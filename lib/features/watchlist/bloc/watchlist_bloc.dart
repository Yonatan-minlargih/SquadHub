import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models/watchlist_item.dart';
import '../../../core/services/movie_service.dart';
import 'watchlist_event.dart';
import 'watchlist_state.dart';

class WatchlistBloc extends Bloc<WatchlistEvent, WatchlistState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final MovieService _movieService = MovieService();
  StreamSubscription? _itemsSubscription;

  WatchlistBloc() : super(const WatchlistState(items: [], likedItems: {})) {
    on<WatchlistLoadItems>(_onLoadItems);
    on<WatchlistToggleLike>(_onToggleLike);
    on<WatchlistAddItem>(_onAddItem);
    on<WatchlistFetchMovieData>(_onFetchMovieData);
    on<WatchlistUpdate>(_onUpdateItems);
    on<WatchlistRemoveItem>(_onRemoveItem);
  }

  Future<void> _onLoadItems(
    WatchlistLoadItems event,
    Emitter<WatchlistState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    await _itemsSubscription?.cancel();

    _itemsSubscription = _firestore
        .collection('watchlist')
        .where('squadId', isEqualTo: event.squadId)
        .snapshots()
        .listen((snapshot) {
          final items = snapshot.docs
              .map((doc) => WatchlistItem.fromFirestore(doc.id, doc.data()))
              .toList();

          // Sort by votes descending
          items.sort((a, b) => b.votes.compareTo(a.votes));

          add(WatchlistUpdate(items));
        });
  }

  void _onUpdateItems(WatchlistUpdate event, Emitter<WatchlistState> emit) {
    final currentUser = _auth.currentUser;
    final likedItems = <String>{};

    if (currentUser != null) {
      for (final item in event.items) {
        if (item.votedBy.contains(currentUser.uid)) {
          likedItems.add(item.id);
        }
      }
    }

    emit(
      state.copyWith(
        items: event.items,
        likedItems: likedItems,
        isLoading: false,
      ),
    );
  }

  Future<void> _onToggleLike(
    WatchlistToggleLike event,
    Emitter<WatchlistState> emit,
  ) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final updatedVotedBy = List<String>.from(event.item.votedBy);
    if (updatedVotedBy.contains(user.uid)) {
      updatedVotedBy.remove(user.uid);
    } else {
      updatedVotedBy.add(user.uid);
    }

    try {
      await _firestore.collection('watchlist').doc(event.item.id).update({
        'votedBy': updatedVotedBy,
      });
    } catch (e) {
      // Handle error if document doesn't exist
    }
  }

  Future<void> _onAddItem(
    WatchlistAddItem event,
    Emitter<WatchlistState> emit,
  ) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Check if item already exists in the same squad
    final existingQuery = await _firestore
        .collection('watchlist')
        .where('squadId', isEqualTo: event.squadId)
        .where('title', isEqualTo: event.title)
        .get();

    if (existingQuery.docs.isNotEmpty) {
      // Movie already exists, just add vote if already there
      final doc = existingQuery.docs.first;
      final item = WatchlistItem.fromFirestore(doc.id, doc.data());
      if (!item.votedBy.contains(user.uid)) {
        add(WatchlistToggleLike(item));
      }
      return;
    }

    // New item
    final newItem = WatchlistItem(
      id: '', // Will be assigned by Firestore
      title: event.title,
      genre: event.genre.isEmpty ? 'Unknown' : event.genre,
      rating: 0.0,
      imageUrl: '',
      votedBy: const [],
      squadId: event.squadId,
    );

    emit(state.copyWith(isLoading: true));

    try {
      // Create document
      final docRef = await _firestore
          .collection('watchlist')
          .add(newItem.toFirestore());

      // Fetch movie data from TMDB
      final results = await _movieService.searchMovie(event.title);
      if (results != null) {
        final isTv = results['media_type'] == 'tv';
        await docRef.update({
          'overview': results['overview'],
          'releaseDate': isTv
              ? results['first_air_date']
              : results['release_date'],
          'rating': (results['vote_average'] as num?)?.toDouble() ?? 0.0,
          'imageUrl': results['poster_path'] ?? '',
          'backdropUrl': results['backdrop_path'] ?? '',
        });
      }
    } catch (e) {
      emit(state.copyWith(isLoading: false));
    }
  }

  Future<void> _onFetchMovieData(
    WatchlistFetchMovieData event,
    Emitter<WatchlistState> emit,
  ) async {
    final results = await _movieService.searchMovie(event.item.title);
    if (results != null) {
      try {
        final isTv = results['media_type'] == 'tv';
        await _firestore.collection('watchlist').doc(event.item.id).update({
          'overview': results['overview'],
          'releaseDate': isTv
              ? results['first_air_date']
              : results['release_date'],
          'rating': (results['vote_average'] as num?)?.toDouble() ?? 0.0,
          'imageUrl': results['poster_path'] ?? '',
          'backdropUrl': results['backdrop_path'] ?? '',
        });
      } catch (e) {
        // Handle error
      }
    }
  }

  Future<void> _onRemoveItem(
    WatchlistRemoveItem event,
    Emitter<WatchlistState> emit,
  ) async {
    try {
      await _firestore.collection('watchlist').doc(event.itemId).delete();
    } catch (e) {
      debugPrint('Error removing watchlist item: $e');
    }
  }

  @override
  Future<void> close() {
    _itemsSubscription?.cancel();
    return super.close();
  }
}
