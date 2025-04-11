// lib/services/podcast_service.dart

import 'package:flutter/services.dart' show rootBundle;
import '../model/podcast_model.dart';

class PodcastService {
  // Singleton pattern
  static final PodcastService _instance = PodcastService._internal();
  PodcastData? _podcastData;

  factory PodcastService() {
    return _instance;
  }

  PodcastService._internal();

  // Load podcast data from the asset file
  Future<PodcastData> loadPodcastData() async {
    if (_podcastData != null) {
      return _podcastData!;
    }

    try {
      // Load from assets/podcast.json
      final String jsonString = await rootBundle.loadString('assets/json/podcast.json');

      _podcastData = PodcastData.parseJson(jsonString);
      return _podcastData!;
    } catch (e) {
      print('Error loading podcast data: $e');
      rethrow;
    }
  }

  // Method to directly parse data from a string
  Future<PodcastData> parsePodcastData(String jsonString) async {
    try {
      _podcastData = PodcastData.parseJson(jsonString);
      return _podcastData!;
    } catch (e) {
      print('Error parsing podcast data: $e');
      rethrow;
    }
  }

  // Get all categories
  List<PodcastCategory> getCategories() {
    return _podcastData?.categories ?? [];
  }

  // Get podcasts by category name
  List<Podcast> getPodcastsByCategory(String categoryName) {
    final category = _podcastData?.categories
        .firstWhere((c) => c.categoryName == categoryName,
        orElse: () => PodcastCategory(
            categoryName: '',
            categoryDescription: '',
            podcasts: []));

    return category?.podcasts ?? [];
  }

  // Get a podcast by title
  Podcast? getPodcastByTitle(String title) {
    for (final category in _podcastData?.categories ?? []) {
      for (final podcast in category.podcasts) {
        if (podcast.title == title) {
          return podcast;
        }
      }
    }
    return null;
  }
}