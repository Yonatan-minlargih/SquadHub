class WatchlistItem {
  final String id;
  final String title;
  final String genre;
  final double rating;
  final String imageUrl;
  final List<String> votedBy;
  final String squadId;
  final String? overview;
  final String? releaseDate;
  final String? backdropUrl;

  int get votes => votedBy.length;

  WatchlistItem({
    required this.id,
    required this.title,
    required this.genre,
    required this.rating,
    required this.imageUrl,
    this.votedBy = const [],
    this.squadId = '',
    this.overview,
    this.releaseDate,
    this.backdropUrl,
  });

  WatchlistItem copyWith({
    String? id,
    String? title,
    String? genre,
    double? rating,
    String? imageUrl,
    List<String>? votedBy,
    String? squadId,
    String? overview,
    String? releaseDate,
    String? backdropUrl,
  }) {
    return WatchlistItem(
      id: id ?? this.id,
      title: title ?? this.title,
      genre: genre ?? this.genre,
      rating: rating ?? this.rating,
      imageUrl: imageUrl ?? this.imageUrl,
      votedBy: votedBy ?? this.votedBy,
      squadId: squadId ?? this.squadId,
      overview: overview ?? this.overview,
      releaseDate: releaseDate ?? this.releaseDate,
      backdropUrl: backdropUrl ?? this.backdropUrl,
    );
  }

  factory WatchlistItem.fromFirestore(String id, Map<String, dynamic> data) {
    return WatchlistItem(
      id: id,
      title: data['title'] ?? '',
      genre: data['genre'] ?? '',
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      imageUrl: data['imageUrl'] ?? '',
      votedBy: List<String>.from(data['votedBy'] ?? []),
      squadId: data['squadId'] ?? '',
      overview: data['overview'],
      releaseDate: data['releaseDate'],
      backdropUrl: data['backdropUrl'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'genre': genre,
      'rating': rating,
      'imageUrl': imageUrl,
      'votedBy': votedBy,
      'squadId': squadId,
      'overview': overview,
      'releaseDate': releaseDate,
      'backdropUrl': backdropUrl,
    };
  }
}
