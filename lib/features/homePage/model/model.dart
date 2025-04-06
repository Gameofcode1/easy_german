// models/story_model.dart
class Story {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String content;
  final String level;
  final String duration;
  bool favorite;

  Story({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.content,
    required this.level,
    required this.duration,
    required this.favorite,
  });
}

// models/podcast_model.dart
class Podcast {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String audioUrl;
  final String duration;
  bool favorite;

  Podcast({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.audioUrl,
    required this.duration,
    required this.favorite,
  });
}

// models/vocabulary_model.dart
class VocabularyWord {
  final String id;
  final String german;
  final String english;
  final String example;
  final String category;
  bool favorite;

  VocabularyWord({
    required this.id,
    required this.german,
    required this.english,
    required this.example,
    required this.category,
    required this.favorite,
  });
}

// models/wishlist_item.dart
class WishlistItem {
  final String id;
  final String title;
  final String level;
  final String type;  // 'story', 'podcast', or 'vocabulary'

  WishlistItem({
    required this.id,
    required this.title,
    required this.level,
    required this.type,
  });
}