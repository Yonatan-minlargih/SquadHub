import 'dart:math';
import 'notification_service.dart';
import 'movie_service.dart';
import 'package:flutter/foundation.dart';

class MovieNotificationService {
  static final MovieNotificationService _instance =
      MovieNotificationService._internal();
  factory MovieNotificationService() => _instance;
  MovieNotificationService._internal();

  final MovieService _movieService = MovieService();
  final NotificationService _notificationService = NotificationService();

  Future<void> scheduleMovieOfTheDay() async {
    try {
      final trendingMovies = await _movieService.getTrendingMovies();
      if (trendingMovies.isNotEmpty) {
        final randomMovie =
            trendingMovies[Random().nextInt(trendingMovies.length)];
        final title = randomMovie['title'] ?? 'Trending Movie';
        final overview = randomMovie['overview'] ?? 'Check out today\'s pick!';

        await _notificationService.showLocalNotification(
          title: '🎬 Movie of the Day: $title',
          body: overview,
        );
      }
    } catch (e) {
      debugPrint('Error scheduling movie notification: $e');
    }
  }
}
