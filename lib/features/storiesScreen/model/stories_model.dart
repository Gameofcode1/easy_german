class StoryItem {
  final String germanText;
  final String englishText;

  StoryItem({required this.germanText, required this.englishText});
}

class StoryModel {
  final String id;
  final String title;
  final String description;
  final String image;
  final String level;
  final String duration;
  bool favorite;
  bool isRead; // Added isRead property
  final List<StoryItem> storyItems;
  final List<QuestionModel> questions;

  StoryModel({
    required this.id,
    required this.title,
    required this.description,
    required this.image,
    required this.level,
    required this.duration,
    this.favorite = false,
    this.isRead = false, // Default to false
    required this.storyItems,
    required this.questions,
  });

  factory StoryModel.fromJson(Map<String, dynamic> json, List<StoryItem> items, List<QuestionModel> questions) {
    return StoryModel(
      id: json['title'].hashCode.toString(),
      title: json['title'],
      description: json['description'],
      image: json['image'],
      level: json['level'],
      duration: json['duration'],
      favorite: json['favorite'] ?? false,
      isRead: json['isRead'] ?? false, // Initialize from JSON if available
      storyItems: items,
      questions: questions,
    );
  }

  // Allows converting model to a Map for UI
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'image': image,
      'level': level,
      'duration': duration,
      'favorite': favorite,
      'isRead': isRead, // Include read status in map
      'storyItems': storyItems,
      'questions': questions.map((q) => q.toMap()).toList(),
    };
  }

  // Create a copy of the story with updated properties
  StoryModel copyWith({
    String? id,
    String? title,
    String? description,
    String? image,
    String? level,
    String? duration,
    bool? favorite,
    bool? isRead,
    List<StoryItem>? storyItems,
    List<QuestionModel>? questions,
  }) {
    return StoryModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      image: image ?? this.image,
      level: level ?? this.level,
      duration: duration ?? this.duration,
      favorite: favorite ?? this.favorite,
      isRead: isRead ?? this.isRead,
      storyItems: storyItems ?? this.storyItems,
      questions: questions ?? this.questions,
    );
  }
}

class QuestionModel {
  final String question;
  final List<String> options;
  final int correctAnswer;

  QuestionModel({
    required this.question,
    required this.options,
    required this.correctAnswer,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      question: json['question'],
      options: List<String>.from(json['options']),
      correctAnswer: json['correctAnswer'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'question': question,
      'options': options,
      'correctAnswer': correctAnswer,
    };
  }
}