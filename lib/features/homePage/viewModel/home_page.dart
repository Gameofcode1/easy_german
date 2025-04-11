import 'package:flutter/material.dart';
import 'package:job_finder/features/homePage/model/model.dart';

class AppProvider with ChangeNotifier {
  // Stories data
  List<Story> _stories = [];
  List<Story> _beginnerStories = [];
  List<Story> _intermediateStories = [];
  List<Story> _advancedStories = [];

  // Podcasts data
  List<Podcast> _podcasts = [];

  // Vocabulary data
  List<VocabularyWord> _vocabularyWords = [];

  // Wishlist
  final List<WishlistItem> _wishlist = [];

  // Selected level filter for stories
  String _selectedStoryLevel = 'All';

  // Getters
  List<Story> get allStories => _stories;
  List<Story> get beginnerStories => _beginnerStories;
  List<Story> get intermediateStories => _intermediateStories;
  List<Story> get advancedStories => _advancedStories;
  List<Podcast> get podcasts => _podcasts;
  List<VocabularyWord> get vocabularyWords => _vocabularyWords;
  String get selectedStoryLevel => _selectedStoryLevel;

  // Initialize with dummy data (in real app, load from Firebase)
  AppProvider() {
    _initDummyData();
  }

  void _initDummyData() {
    // Initialize beginner stories
    _beginnerStories = [
      Story(
        id: 'b1',
        title: 'Mein erstes Haustier',
        description: 'A simple story about getting a first pet.',
        imageUrl: 'assets/images/stories/pet.jpg',
        content: 'Ich habe ein Haustier. Es ist ein Hund. Mein Hund heißt Max. Max ist sehr freundlich und verspielt...',
        level: 'Beginner',
        duration: '5 min',
        favorite: false,
      ),
      Story(
        id: 'b2',
        title: 'Im Restaurant',
        description: 'Learn restaurant vocabulary through a simple dialogue.',
        imageUrl: 'assets/images/stories/restaurant.jpg',
        content: 'Kellner: Guten Tag! Möchten Sie bestellen?\nPeter: Ja, ich hätte gerne eine Suppe...',
        level: 'Beginner',
        duration: '4 min',
        favorite: false,
      ),
      Story(
        id: 'b3',
        title: 'Meine Familie',
        description: 'A beginner story about family members.',
        imageUrl: 'assets/images/stories/family.jpg',
        content: 'Meine Familie ist klein. Ich habe eine Mutter, einen Vater und eine Schwester...',
        level: 'Beginner',
        duration: '3 min',
        favorite: false,
      ),
    ];

    // Initialize intermediate stories
    _intermediateStories = [
      Story(
        id: 'i1',
        title: 'Eine Reise nach Berlin',
        description: 'Join Lisa on her first trip to Berlin.',
        imageUrl: 'assets/images/stories/berlin.jpg',
        content: 'Letzten Sommer bin ich nach Berlin gefahren. Es war meine erste Reise nach Deutschland...',
        level: 'Intermediate',
        duration: '8 min',
        favorite: false,
      ),
      Story(
        id: 'i2',
        title: 'Der geheimnisvolle Brief',
        description: 'A mysterious letter arrives for Markus.',
        imageUrl: 'assets/images/stories/letter.jpg',
        content: 'Es war ein ganz normaler Montag, als Markus einen seltsamen Brief in seinem Briefkasten fand...',
        level: 'Intermediate',
        duration: '10 min',
        favorite: false,
      ),
      Story(
        id: 'i3',
        title: 'Das Vorstellungsgespräch',
        description: 'Anna prepares for an important job interview.',
        imageUrl: 'assets/images/stories/interview.jpg',
        content: 'Anna war nervös. Morgen hatte sie ein wichtiges Vorstellungsgespräch bei einer großen Firma...',
        level: 'Intermediate',
        duration: '7 min',
        favorite: false,
      ),
    ];

    // Initialize advanced stories
    _advancedStories = [
      Story(
        id: 'a1',
        title: 'Die Entscheidung',
        description: 'A complex tale about making difficult life choices.',
        imageUrl: 'assets/images/stories/decision.jpg',
        content: 'Die Entscheidung, die Thomas treffen musste, war alles andere als einfach. Sie würde sein gesamtes Leben verändern...',
        level: 'Advanced',
        duration: '15 min',
        favorite: false,
      ),
      Story(
        id: 'a2',
        title: 'Der verlorene Schlüssel',
        description: 'A mystery story with complex vocabulary.',
        imageUrl: 'assets/images/stories/key.jpg',
        content: 'Die alte Villa am Stadtrand hatte seit Jahrzehnten leer gestanden. Niemand traute sich hinein, bis eines Tages...',
        level: 'Advanced',
        duration: '12 min',
        favorite: false,
      ),
      Story(
        id: 'a3',
        title: 'Zwischen den Welten',
        description: 'A philosophical journey between reality and dreams.',
        imageUrl: 'assets/images/stories/worlds.jpg',
        content: 'Professor Weber hatte sein ganzes Leben der Erforschung des menschlichen Bewusstseins gewidmet...',
        level: 'Advanced',
        duration: '20 min',
        favorite: false,
      ),
    ];

    // Combine all stories
    _stories = [..._beginnerStories, ..._intermediateStories, ..._advancedStories];

    // Initialize podcasts (simplified for now)
    _podcasts = [
      Podcast(
        id: 'p1',
        title: 'Alltag in Deutschland',
        description: 'Daily life conversations in Germany.',
        imageUrl: 'assets/images/podcasts/daily_life.jpg',
        audioUrl: 'assets/audio/alltag.mp3',
        duration: '15:30',
        favorite: false,
      ),
      Podcast(
        id: 'p2',
        title: 'Deutsche Kultur',
        description: 'Learn about German culture and traditions.',
        imageUrl: 'assets/images/podcasts/culture.jpg',
        audioUrl: 'assets/audio/kultur.mp3',
        duration: '20:45',
        favorite: false,
      ),
    ];

    // Initialize vocabulary (simplified for now)
    _vocabularyWords = [
      VocabularyWord(
        id: 'v1',
        german: 'der Hund',
        english: 'the dog',
        example: 'Mein Hund ist sehr freundlich.',
        category: 'Animals',
        favorite: false,
      ),
      VocabularyWord(
        id: 'v2',
        german: 'essen',
        english: 'to eat',
        example: 'Ich esse gerne Pizza.',
        category: 'Verbs',
        favorite: false,
      ),
    ];
  }

  // Methods to manage stories
  void setSelectedStoryLevel(String level) {
    _selectedStoryLevel = level;
    notifyListeners();
  }

  List<Story> getFilteredStories() {
    switch (_selectedStoryLevel) {
      case 'Beginner':
        return _beginnerStories;
      case 'Intermediate':
        return _intermediateStories;
      case 'Advanced':
        return _advancedStories;
      default:
        return _stories;
    }
  }

  void toggleStoryFavorite(String storyId) {
    final storyIndex = _stories.indexWhere((story) => story.id == storyId);
    if (storyIndex >= 0) {
      _stories[storyIndex].favorite = !_stories[storyIndex].favorite;

      // If it's favorited, add to wishlist
      if (_stories[storyIndex].favorite) {
        final story = _stories[storyIndex];
        addToWishlist(
          WishlistItem(
            id: story.id,
            title: story.title,
            level: story.level,
            type: 'story',
          ),
        );
      } else {
        // If unfavorited, remove from wishlist
        removeFromWishlist(storyId);
      }

      // Update the story in its respective level list
      _updateStoryInLevelList(storyId);

      notifyListeners();
    }
  }

  void _updateStoryInLevelList(String storyId) {
    final story = _stories.firstWhere((s) => s.id == storyId);

    switch (story.level) {
      case 'Beginner':
        final index = _beginnerStories.indexWhere((s) => s.id == storyId);
        if (index >= 0) {
          _beginnerStories[index] = story;
        }
        break;
      case 'Intermediate':
        final index = _intermediateStories.indexWhere((s) => s.id == storyId);
        if (index >= 0) {
          _intermediateStories[index] = story;
        }
        break;
      case 'Advanced':
        final index = _advancedStories.indexWhere((s) => s.id == storyId);
        if (index >= 0) {
          _advancedStories[index] = story;
        }
        break;
    }
  }

  // Methods to manage podcasts
  void togglePodcastFavorite(String podcastId) {
    final podcastIndex = _podcasts.indexWhere((podcast) => podcast.id == podcastId);
    if (podcastIndex >= 0) {
      _podcasts[podcastIndex].favorite = !_podcasts[podcastIndex].favorite;

      // If it's favorited, add to wishlist
      if (_podcasts[podcastIndex].favorite) {
        final podcast = _podcasts[podcastIndex];
        addToWishlist(
          WishlistItem(
            id: podcast.id,
            title: podcast.title,
            level: '',
            type: 'podcast',
          ),
        );
      } else {
        // If unfavorited, remove from wishlist
        removeFromWishlist(podcastId);
      }

      notifyListeners();
    }
  }

  // Methods to manage vocabulary
  void toggleVocabularyFavorite(String vocabId) {
    final vocabIndex = _vocabularyWords.indexWhere((vocab) => vocab.id == vocabId);
    if (vocabIndex >= 0) {
      _vocabularyWords[vocabIndex].favorite = !_vocabularyWords[vocabIndex].favorite;

      // If it's favorited, add to wishlist
      if (_vocabularyWords[vocabIndex].favorite) {
        final vocab = _vocabularyWords[vocabIndex];
        addToWishlist(
          WishlistItem(
            id: vocab.id,
            title: vocab.german,
            level: vocab.category,
            type: 'vocabulary',
          ),
        );
      } else {
        // If unfavorited, remove from wishlist
        removeFromWishlist(vocabId);
      }

      notifyListeners();
    }
  }

  // Wishlist methods
  List<WishlistItem> getWishlist() {
    return [..._wishlist];
  }

  void addToWishlist(WishlistItem item) {
    if (!_wishlist.any((element) => element.id == item.id)) {
      _wishlist.add(item);
      notifyListeners();
    }
  }

  void removeFromWishlist(String itemId) {
    _wishlist.removeWhere((item) => item.id == itemId);

    // Also update favorite status in respective lists
    final storyIndex = _stories.indexWhere((story) => story.id == itemId);
    if (storyIndex >= 0) {
      _stories[storyIndex].favorite = false;
      _updateStoryInLevelList(itemId);
    }

    final podcastIndex = _podcasts.indexWhere((podcast) => podcast.id == itemId);
    if (podcastIndex >= 0) {
      _podcasts[podcastIndex].favorite = false;
    }

    final vocabIndex = _vocabularyWords.indexWhere((vocab) => vocab.id == itemId);
    if (vocabIndex >= 0) {
      _vocabularyWords[vocabIndex].favorite = false;
    }

    notifyListeners();
  }
}