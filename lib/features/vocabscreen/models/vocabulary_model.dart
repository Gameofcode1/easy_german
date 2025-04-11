import 'dart:convert';
import 'package:flutter/material.dart';


class VocabularyModel {
  final String level;
  final List<CategorySection> categories;

  VocabularyModel({
    required this.level,
    required this.categories,
  });

  factory VocabularyModel.fromJson(Map<String, dynamic> json, IconData Function(String) getIconData) {
    return VocabularyModel(
      level: json['level'],
      categories: (json['categories'] as List)
          .map((category) => CategorySection.fromJson(category, getIconData))
          .toList(),
    );
  }
}

class CategorySection {
  final String title;
  final List<CategoryItem> items;

  CategorySection({
    required this.title,
    required this.items,
  });

  factory CategorySection.fromJson(Map<String, dynamic> json, IconData Function(String) getIconData) {
    return CategorySection(
      title: json['title'],
      items: (json['items'] as List)
          .map((item) => CategoryItem.fromJson(item, getIconData))
          .toList(),
    );
  }
}

class CategoryItem {
  final IconData icon;
  final Color iconColor;
  final String title;
  final int count;  // Total count of cards
  int learnedCount; // Count of learned cards
  double progress;
  final String category;
  final String level;
  bool isNotStarted;

  CategoryItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.count,
    this.learnedCount = 0,
    required this.progress,
    required this.category,
    required this.level,
    this.isNotStarted = false,
  });

  factory CategoryItem.fromJson(Map<String, dynamic> json, IconData Function(String) getIconData) {
    return CategoryItem(
      icon: getIconData(json['icon']),
      iconColor: Color(int.parse(json['iconColor'].substring(1), radix: 16) + 0xFF000000),
      title: json['title'],
      count: json['count'],
      learnedCount: 0, // Initialize to 0, will be updated from SharedPreferences
      progress: json['progress'].toDouble(),
      category: json['category'],
      level: json['level'],
      isNotStarted: json['isNotStarted'] ?? false,
    );
  }
}

class VocabularyWord {
  final String id;
  final String german;
  final String english;
  final String partOfSpeech;
  final List<WordExample> examples;

  VocabularyWord({
    required this.id,
    required this.german,
    required this.english,
    required this.partOfSpeech,
    required this.examples,
  });

  factory VocabularyWord.fromJson(Map<String, dynamic> json) {
    return VocabularyWord(
      id: json['id'],
      german: json['german'],
      english: json['english'],
      partOfSpeech: json['partOfSpeech'],
      examples: (json['examples'] as List)
          .map((example) => WordExample.fromJson(example))
          .toList(),
    );
  }
}

class WordExample {
  final String prefix;
  final String highlight;
  final String suffix;
  final String type;
  final String translation;

  WordExample({
    required this.prefix,
    required this.highlight,
    required this.suffix,
    required this.type,
    required this.translation,
  });

  factory WordExample.fromJson(Map<String, dynamic> json) {
    return WordExample(
      prefix: json['prefix'],
      highlight: json['highlight'],
      suffix: json['suffix'],
      type: json['type'],
      translation: json['translation'],
    );
  }
} 