import 'package:flutter/foundation.dart';
import 'network_service.dart';

class MovieService {
  static const String _apiKey = 'ea186890e93510be422a576c65b9ea28';
  static const String _imageBaseUrl = 'https://image.tmdb.org/t/p/w500';
  static const String _backdropBaseUrl = 'https://image.tmdb.org/t/p/original';

  final _dio = NetworkService().dio;

  Future<Map<String, dynamic>?> searchMovie(String query) async {
    try {
      final response = await _dio.get(
        'https://api.themoviedb.org/3/search/multi',
        queryParameters: {'api_key': _apiKey, 'query': query},
      );
      if (response.statusCode == 200) {
        final results = response.data['results'] as List;
        if (results.isNotEmpty) {
          // Filter out people, only take movie or tv
          final match = results.firstWhere(
            (r) => r['media_type'] == 'movie' || r['media_type'] == 'tv',
            orElse: () => results.first,
          );
          return match as Map<String, dynamic>;
        }
      }
    } catch (e) {
      debugPrint('Error searching TMDB: $e');
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getTrendingMovies() async {
    try {
      final response = await _dio.get(
        'https://api.themoviedb.org/3/trending/movie/day',
        queryParameters: {'api_key': _apiKey},
      );
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data['results']);
      }
    } catch (e) {
      debugPrint('Error getting trending movies: $e');
    }
    return [];
  }

  Future<Map<String, dynamic>?> getMovieDetails(int movieId) async {
    try {
      final response = await _dio.get(
        'https://api.themoviedb.org/3/movie/$movieId',
        queryParameters: {'api_key': _apiKey},
      );
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Error getting movie details: $e');
    }
    return null;
  }

  static String getPosterUrl(String? path) {
    if (path == null) return '';
    return '$_imageBaseUrl$path';
  }

  static String getBackdropUrl(String? path) {
    if (path == null) return '';
    return '$_backdropBaseUrl$path';
  }
}
