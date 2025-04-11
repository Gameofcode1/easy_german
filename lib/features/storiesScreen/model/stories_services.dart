import 'dart:convert';
import 'package:flutter/services.dart';
import '../../../core/constants/app_images.dart';
import '../model/stories_model.dart';

class StoryService {
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
              'image': story['image'] ?? cat,
              'level': story['level'],
              'duration': story['duration'],
              'favorite': story['favorite'] ?? false,
            },
            storyItems,
            questions,
          ));
        }
      }

      return allStories;
    } catch (e) {
      print('Error loading stories from JSON: $e');
      return [];
    }
  }

  // Get stories by category name
  Future<List<StoryModel>> getStoriesByCategory(String categoryName) async {
    if (categoryName.isEmpty) {
      return getStories();
    }
    return getStories(category: categoryName);
  }

  // Get stories by level
  Future<List<StoryModel>> getStoriesByLevel(String level) async {
    if (level.isEmpty) {
      return getStories();
    }
    return getStories(level: level);
  }

  // Get all categories from the JSON file
  Future<List<Map<String, String>>> getCategories() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/json/beginner.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);

      List<Map<String, String>> categories = [];

      for (var category in jsonData['categories']) {
        categories.add({
          'name': category['categoryName'],
          'description': category['categoryDescription']
        });
      }

      return categories;
    } catch (e) {
      print('Error loading categories: $e');
      return [];
    }
  }
}