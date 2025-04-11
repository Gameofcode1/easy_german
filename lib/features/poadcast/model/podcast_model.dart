// lib/model/podcast_model.dart

import 'dart:convert';
import 'package:flutter/material.dart';

// Root model for the entire podcast data structure
class PodcastData {
  final List<PodcastCategory> categories;

  PodcastData({
    required this.categories,
  });

  factory PodcastData.fromJson(Map<String, dynamic> json) {
    return PodcastData(
      categories: (json['categories'] as List)
          .map((categoryJson) => PodcastCategory.fromJson(categoryJson))
          .toList(),
    );
  }

  static PodcastData parseJson(String jsonString) {
    final Map<String, dynamic> json = jsonDecode(jsonString);
    return PodcastData.fromJson(json);
  }
}

// Category model (like True Crime, Popular, Learning German)
class PodcastCategory {
  final String categoryName;
  final String categoryDescription;
  final List<Podcast> podcasts;

  PodcastCategory({
    required this.categoryName,
    required this.categoryDescription,
    required this.podcasts,
  });

  factory PodcastCategory.fromJson(Map<String, dynamic> json) {
    return PodcastCategory(
      categoryName: json['categoryName'],
      categoryDescription: json['categoryDescription'],
      podcasts: (json['podcasts'] as List)
          .map((podcastJson) => Podcast.fromJson(podcastJson))
          .toList(),
    );
  }
}

// Individual podcast model
class Podcast {
  final String title;
  final String author;
  final String description;
  final String image;
  final String duration;
  final double rating;
  final int episodes;
  final Color color;
  final List<PodcastEpisode> conversations;

  Podcast({
    required this.title,
    required this.author,
    required this.description,
    required this.image,
    required this.duration,
    required this.rating,
    required this.episodes,
    required this.color,
    required this.conversations,
  });

  factory Podcast.fromJson(Map<String, dynamic> json) {
    // Parse color from string (format: 0xFFXXXXXX)
    Color color;
    try {
      if (json['color'] is String) {
        color = Color(int.parse(json['color']));
      } else if (json['color'] is Color) {
        color = json['color'] as Color;
      } else {
        color = const Color(0xFF3F51B5); // Default color
      }
    } catch (e) {
      color = const Color(0xFF3F51B5); // Default color if parsing fails
    }

    return Podcast(
      title: json['title'],
      author: json['author'],
      description: json['description'],
      image: json['image'],
      duration: json['duration'],
      rating: json['rating'] is int ? (json['rating'] as int).toDouble() : json['rating'],
      episodes: json['episodes'],
      color: color,
      conversations: json.containsKey('conversations')
          ? (json['conversations'] as List)
          .map((convoJson) => PodcastEpisode.fromJson(convoJson))
          .toList()
          : [],
    );
  }

  // Convert to a regular Map for compatibility with existing code
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'author': author,
      'description': description,
      'image': image,
      'duration': duration,
      'rating': rating,
      'episodes': episodes,
      'color': color,
      'conversations': conversations.map((e) => e.toMap()).toList(),
    };
  }
}

// Episode model
class PodcastEpisode {
  final String episodeTitle;
  final String episodeDescription;
  final String releaseDate;
  final List<DialogueEntry> dialogue;

  PodcastEpisode({
    required this.episodeTitle,
    required this.episodeDescription,
    required this.releaseDate,
    required this.dialogue,
  });

  factory PodcastEpisode.fromJson(Map<String, dynamic> json) {
    return PodcastEpisode(
      episodeTitle: json['episodeTitle'],
      episodeDescription: json['episodeDescription'],
      releaseDate: json['releaseDate'],
      dialogue: (json['dialogue'] as List)
          .map((dialogueJson) => DialogueEntry.fromJson(dialogueJson))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'episodeTitle': episodeTitle,
      'episodeDescription': episodeDescription,
      'releaseDate': releaseDate,
      'dialogue': dialogue.map((d) => d.toMap()).toList(),
    };
  }
}

// Individual dialogue entry model
class DialogueEntry {
  final int speaker;
  final String german;
  final String english;
  final int duration;

  DialogueEntry({
    required this.speaker,
    required this.german,
    required this.english,
    required this.duration,
  });

  factory DialogueEntry.fromJson(Map<String, dynamic> json) {
    return DialogueEntry(
      speaker: json['speaker'],
      german: json['german'],
      english: json['english'],
      duration: json['duration'],
    );
  }

  // Convert to Map for compatibility
  Map<String, dynamic> toMap() {
    return {
      'speaker': speaker,
      'german': german,
      'english': english,
      'duration': duration,
    };
  }
}