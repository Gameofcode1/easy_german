import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'stories_model.dart';

class StoryService {
  // Keys for SharedPreferences
  static const String _keyTotalStoriesRead = 'total_stories_read';
  static const String _keyStoryReadPrefix = 'story_read_';
  static const String _keyStoryFavoritePrefix = 'story_favorite_';

  // Method to mark a story as read
  Future<void> markStoryAsRead(String storyId) async {
    final prefs = await SharedPreferences.getInstance();

    // Check if already read to avoid double counting
    bool alreadyRead = prefs.getBool('$_keyStoryReadPrefix$storyId') ?? false;

    // Mark as read
    await prefs.setBool('$_keyStoryReadPrefix$storyId', true);

    // Only increment counter if not already read
    if (!alreadyRead) {
      int totalRead = prefs.getInt(_keyTotalStoriesRead) ?? 0;
      await prefs.setInt(_keyTotalStoriesRead, totalRead + 1);
    }
  }

  // Method to check if a story has been read
  Future<bool> isStoryRead(String storyId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_keyStoryReadPrefix$storyId') ?? false;
  }

  // Method to toggle favorite status of a story
  Future<bool> toggleFavorite(String storyId) async {
    final prefs = await SharedPreferences.getInstance();
    bool isFavorite = prefs.getBool('$_keyStoryFavoritePrefix$storyId') ?? false;
    bool newStatus = !isFavorite;

    await prefs.setBool('$_keyStoryFavoritePrefix$storyId', newStatus);
    return newStatus;
  }

  // Method to check if a story is favorited
  Future<bool> isStoryFavorite(String storyId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_keyStoryFavoritePrefix$storyId') ?? false;
  }

  // Method to get total stories read count
  Future<int> getTotalStoriesRead() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyTotalStoriesRead) ?? 0;
  }

  // Method to get all favorite story IDs
  Future<List<String>> getFavoriteStoryIds() async {
    final prefs = await SharedPreferences.getInstance();
    final allKeys = prefs.getKeys();

    // Filter keys that match our pattern for favorite stories
    final favoriteKeys = allKeys.where((key) =>
    key.startsWith(_keyStoryFavoritePrefix) &&
        (prefs.getBool(key) ?? false)
    ).toList();

    // Extract story IDs from keys
    return favoriteKeys.map((key) =>
        key.replaceFirst(_keyStoryFavoritePrefix, '')
    ).toList();
  }

  // Get stories from assets and apply filters
  Future<List<StoryModel>> getStories({String? level, String? category}) async {
    try {
      // Load the JSON directly from assets
      final String jsonString = await rootBundle.loadString('assets/json/stories.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);

      List<StoryModel> allStories = [];

      // Parse the JSON and extract the stories
      for (var categoryData in jsonData['categories']) {
        // Skip this category if it doesn't match the category filter (when filter is specified)
        if (category != null &&
            category.isNotEmpty &&
            !categoryData['categoryName'].contains(category)) {
          continue;
        }

        for (var story in categoryData['stories']) {
          // Skip this story if it doesn't match the level filter (when filter is specified)
          if (level != null &&
              level.isNotEmpty &&
              story['level'] != level) {
            continue;
          }

          // Convert storyItems JSON to StoryItem objects
          List<StoryItem> storyItems = [];
          for (var item in story['storyItems']) {
            storyItems.add(StoryItem(
                germanText: item['germanText'],
                englishText: item['englishText']
            ));
          }

          // Parse questions if available
          List<QuestionModel> questions = [];
          if (story.containsKey('questions')) {
            for (var questionData in story['questions']) {
              questions.add(QuestionModel.fromJson(questionData));
            }
          }

          // Create a StoryModel and add to our list
          allStories.add(StoryModel.fromJson(
            {
              'title': story['title'],
              'description': story['description'],
              'image': story['image'] ?? '', // Use empty string as default
              'level': story['level'],
              'duration': story['duration'],
              'favorite': story['favorite'] ?? false,
            },
            storyItems,
            questions,
          ));
        }
      }

      // Load status (read/favorite) for each story
      return loadStoriesWithStatus(allStories);
    } catch (e) {
      print('Error loading stories from JSON: $e');
      return [];
    }
  }

  // Load read status and favorites for a list of stories
  Future<List<StoryModel>> loadStoriesWithStatus(List<StoryModel> stories) async {
    final prefs = await SharedPreferences.getInstance();

    List<StoryModel> updatedStories = [];

    for (var story in stories) {
      bool isRead = prefs.getBool('$_keyStoryReadPrefix${story.id}') ?? false;
      bool isFavorite = prefs.getBool('$_keyStoryFavoritePrefix${story.id}') ?? false;

      // Create a copy with updated status
      updatedStories.add(story.copyWith(
          isRead: isRead,
          favorite: isFavorite
      ));
    }

    return updatedStories;
  }

  // Get only favorite stories
  Future<List<StoryModel>> getFavoriteStories() async {
    // First get all stories
    List<StoryModel> allStories = await getStories();

    // Get favorite IDs
    List<String> favoriteIds = await getFavoriteStoryIds();

    // Filter to only include favorites
    return allStories.where((story) => favoriteIds.contains(story.id)).toList();
  }
}