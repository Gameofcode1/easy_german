// Correct implementation matching FlashcardProvider
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math';

enum GameMode {
  learnNew,    // For unlearned verbs
  reviewLearned, // For learned verbs
  mixedChallenge // For all verbs
}

class GameCard {
  final int id;
  final String text;
  final bool isGerman;

  GameCard({required this.id, required this.text, required this.isGerman});
}

class WordPair {
  final int id;
  final String german;
  final String english;
  final bool isLearned;
  final String originalId; // Original ID from the JSON file
  final String category;   // Category of the word
  final String level;      // Level of the word (A1, A2, etc.)

  WordPair({
    required this.id,
    required this.german,
    required this.english,
    required this.originalId,
    required this.category,
    required this.level,
    this.isLearned = false,
  });
}

class LanguageMatchingGameProvider extends ChangeNotifier {
  // Text-to-speech engine
  final FlutterTts flutterTts = FlutterTts();

  // Game state
  int score = 0;
  int elapsedTimeInSeconds = 0;
  Stopwatch stopwatch = Stopwatch();
  Timer? timer;
  bool gameActive = false;
  bool isGamePaused = false;
  GameMode gameMode = GameMode.mixedChallenge; // Default mode

  // Animation controllers
  late AnimationController _scoreAnimationController;
  late AnimationController _matchAnimationController;
  late AnimationController _shakeAnimationController;

  // Cards state
  GameCard? selectedGermanCard;
  GameCard? selectedEnglishCard;
  List<int> matchedPairs = [];

  // German and English cards
  List<GameCard> germanCards = [];
  List<GameCard> englishCards = [];

  // Define primary color
  final Color primaryColor = const Color(0xFF3F51B5);

  // Word pairs for the game (will be populated based on game mode)
  List<WordPair> wordPairs = [];

  // Callback for game completion
  Function(String time, int score)? gameCompleteCallback;

  // SharedPreferences instance
  SharedPreferences? _prefs;

  // Set the game mode
  void setGameMode(GameMode mode) {
    gameMode = mode;
    notifyListeners();
  }

  // Initialize the provider
  Future<void> initialize() async {
    // Initialize SharedPreferences
    _prefs = await SharedPreferences.getInstance();

    // Load words from JSON
    await _loadWordsFromJson();

    // Initialize the game
    initGame();
    setupTts();
  }

  // Load words from JSON with correct SharedPreferences integration

  // Simplified implementation - READ ONLY from SharedPreferences
// Properly await async operations before filtering

  Future<void> _loadWordsFromJson() async {
    try {
      // Load SharedPreferences first
      if (_prefs == null) {
        _prefs = await SharedPreferences.getInstance();
      }

      // Load JSON from assets folder
      final String jsonString = await rootBundle.loadString('assets/json/vocabulary.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString); // No await needed

      print('JSON loaded successfully');

      // Navigate to the vocabulary levels data
      if (jsonData == null || !jsonData.containsKey('vocabulary') ||
          !jsonData['vocabulary'].containsKey('levels')) {
        print('Invalid JSON structure');
        _addFallbackWordPairs();
        return;
      }

      final Map<String, dynamic> levels = jsonData['vocabulary']['levels'];
      if (levels == null || levels.isEmpty) {
        print('No levels found in JSON');
        _addFallbackWordPairs();
        return;
      }

      List<WordPair> allWords = [];
      int idCounter = 1;

      // Iterate through levels (A1, A2, B1)
      levels.forEach((levelKey, levelValue) {
        if (levelValue == null || !levelValue.containsKey('sections')) {
          print('Skipping invalid level: $levelKey');
          return;
        }

        List<dynamic> sections = levelValue['sections'];
        if (sections == null) {
          print('No sections in level: $levelKey');
          return;
        }

        // Iterate through sections in each level
        for (var section in sections) {
          if (section == null || !section.containsKey('items')) {
            print('Skipping invalid section');
            continue;
          }

          List<dynamic> items = section['items'];
          if (items == null) {
            print('No items in section');
            continue;
          }

          // Iterate through category items in each section
          for (var item in items) {
            if (item == null || !item.containsKey('category') ||
                !item.containsKey('level') || !item.containsKey('flashcards')) {
              print('Skipping invalid item');
              continue;
            }

            String category = item['category'];
            String level = item['level'];
            List<dynamic> flashcards = item['flashcards'];

            if (flashcards == null) {
              print('No flashcards in item');
              continue;
            }

            // Iterate through flashcards in this category
            for (var card in flashcards) {
              if (card == null || !card.containsKey('id') ||
                  !card.containsKey('german') || !card.containsKey('english')) {
                print('Skipping invalid flashcard');
                continue;
              }

              String cardId = card['id'];

              // Check if word is learned in SharedPreferences
              String cardKey = '${level}_${category}_${cardId}';
              bool isLearned = _prefs?.getBool('${cardKey}_learned') ?? false;

              try {
                // Add word with its learned status from SharedPreferences
                allWords.add(WordPair(
                  id: idCounter++,
                  german: card['german'],
                  english: card['english'],
                  isLearned: isLearned,
                  level: "",
                  category: "",
                  originalId: ""
                  // These fields should be optional in WordPair constructor
                ));
              } catch (e) {
                print('Error adding word: $e');
              }
            }
          }
        }
      });

      print('Loaded ${allWords.length} total words');

      // Now filter words based on game mode
      List<WordPair> filteredWords = [];

      // Apply filtering based on game mode
      try {
        switch (gameMode) {
          case GameMode.learnNew:
            filteredWords = allWords.where((word) => !word.isLearned).toList();
            print('Found ${filteredWords.length} unlearned words');
            break;
          case GameMode.reviewLearned:
            filteredWords = allWords.where((word) => word.isLearned).toList();
            print('Found ${filteredWords.length} learned words');
            break;
          case GameMode.mixedChallenge:
            filteredWords = allWords;
            print('Using all ${filteredWords.length} words (mixed mode)');
            break;
        }
      } catch (e) {
        print('Error filtering words: $e');
        filteredWords = allWords; // Fallback to all words
      }

      if (filteredWords.isNotEmpty) {
        // Shuffle and limit to 10 if needed
        try {
          filteredWords.shuffle();
          if (filteredWords.length > 10) {
            filteredWords = filteredWords.sublist(0, 10);
          }

          wordPairs = filteredWords;
          print('Selected ${wordPairs.length} words for game');
        } catch (e) {
          print('Error shuffling or selecting words: $e');
          _addFallbackWordPairs();
        }
      } else {
        // No words found, use fallback
        print('No matching words found, using fallback words');
        _addFallbackWordPairs();
      }

    } catch (e) {
      print('Error loading words from JSON: $e');
      _addFallbackWordPairs();
    }
  }

  // Filter words based on game mode - separated for clarity
  List<WordPair> _filterWordsByGameMode(List<WordPair> allWords) {
    switch (gameMode) {
      case GameMode.learnNew:
      // Only unlearned words
        List<WordPair> unlearned = allWords.where((word) => !word.isLearned).toList();
        print('Found ${unlearned.length} unlearned words');
        return unlearned;

      case GameMode.reviewLearned:
      // Only learned words
        List<WordPair> learned = allWords.where((word) => word.isLearned).toList();
        print('Found ${learned.length} learned words');
        return learned;

      case GameMode.mixedChallenge:
      // All words
        return allWords;
    }
  }

  // Add fallback word pairs
  void _addFallbackWordPairs() {
    wordPairs = [
      WordPair(
        id: 1,
        german: 'sein',
        english: 'to be',
        isLearned: false,
        originalId: 'verb_1',
        category: 'verbs',
        level: 'A1',
      ),
      WordPair(
        id: 2,
        german: 'haben',
        english: 'to have',
        isLearned: false,
        originalId: 'verb_2',
        category: 'verbs',
        level: 'A1',
      ),
      WordPair(
        id: 3,
        german: 'werden',
        english: 'to become',
        isLearned: false,
        originalId: 'verb_3',
        category: 'verbs',
        level: 'A1',
      ),
      WordPair(
        id: 4,
        german: 'können',
        english: 'can',
        isLearned: false,
        originalId: 'verb_4',
        category: 'verbs',
        level: 'A1',
      ),
      WordPair(
        id: 5,
        german: 'müssen',
        english: 'must',
        isLearned: false,
        originalId: 'verb_5',
        category: 'verbs',
        level: 'A1',
      ),
      WordPair(
        id: 6,
        german: 'sagen',
        english: 'to say',
        isLearned: false,
        originalId: 'verb_6',
        category: 'verbs',
        level: 'A1',
      ),
      WordPair(
        id: 7,
        german: 'machen',
        english: 'to make/do',
        isLearned: false,
        originalId: 'verb_7',
        category: 'verbs',
        level: 'A1',
      ),
      WordPair(
        id: 8,
        german: 'geben',
        english: 'to give',
        isLearned: false,
        originalId: 'verb_8',
        category: 'verbs',
        level: 'A1',
      ),
      WordPair(
        id: 9,
        german: 'kommen',
        english: 'to come',
        isLearned: false,
        originalId: 'verb_9',
        category: 'verbs',
        level: 'A1',
      ),
      WordPair(
        id: 10,
        german: 'sollen',
        english: 'should',
        isLearned: false,
        originalId: 'verb_10',
        category: 'verbs',
        level: 'A1',
      ),
    ];
  }

  // Set animation controllers from the view
  void setAnimationControllers(
      AnimationController scoreController,
      AnimationController matchController,
      AnimationController shakeController,
      ) {
    _scoreAnimationController = scoreController;
    _matchAnimationController = matchController;
    _shakeAnimationController = shakeController;
  }

  // Initialize the game
  void initGame() {
    try {
      // Create German cards
      germanCards = wordPairs.map((pair) =>
          GameCard(id: pair.id, text: pair.german, isGerman: true)
      ).toList();

      // Create English cards
      englishCards = wordPairs.map((pair) =>
          GameCard(id: pair.id, text: pair.english, isGerman: false)
      ).toList();

      // Shuffle both card sets
      germanCards.shuffle();
      englishCards.shuffle();

      // Reset game state
      selectedGermanCard = null;
      selectedEnglishCard = null;
      matchedPairs = [];
      score = 0;
      elapsedTimeInSeconds = 0;
      stopwatch.reset();

      if (timer != null) {
        timer!.cancel();
        timer = null;
      }

      gameActive = true;
      isGamePaused = false;

      startTimer();
      notifyListeners();
    } catch (e) {
      print('Error initializing game: $e');
      if (wordPairs.isEmpty) {
        _addFallbackWordPairs();
        initGame();
      }
    }
  }

  // Set up text-to-speech
  Future<void> setupTts() async {
    await flutterTts.setLanguage("de-DE");
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);
  }

  // Start game timer
  void startTimer() {
    stopwatch.start();
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      elapsedTimeInSeconds = stopwatch.elapsed.inSeconds;
      notifyListeners();
    });
  }

  // Formatted time as mm:ss
  String get formattedTime {
    final minutes = elapsedTimeInSeconds ~/ 60;
    final seconds = elapsedTimeInSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // Get the game mode name
  String get gameModeName {
    switch (gameMode) {
      case GameMode.learnNew:
        return "Learn New Words";
      case GameMode.reviewLearned:
        return "Review Learned Words";
      case GameMode.mixedChallenge:
        return "Mixed Challenge";
    }
  }

  // Handle card selection
  void handleCardTap(GameCard card) {
    if (!gameActive || isGamePaused) return;
    if (matchedPairs.contains(card.id)) return;

    // Don't allow selecting the same card type twice
    if (card.isGerman && selectedGermanCard != null) return;
    if (!card.isGerman && selectedEnglishCard != null) return;

    // Haptic feedback on tap
    HapticFeedback.selectionClick();

    // Speak the word
    speakWord(card.text, card.isGerman ? "de-DE" : "en-US");

    if (card.isGerman) {
      selectedGermanCard = card;
    } else {
      selectedEnglishCard = card;
    }

    // Check for a match if both cards are selected
    if (selectedGermanCard != null && selectedEnglishCard != null) {
      if (selectedGermanCard!.id == selectedEnglishCard!.id) {
        // Match found - success feedback
        HapticFeedback.mediumImpact();
        _scoreAnimationController.reset();
        _scoreAnimationController.forward();
        _matchAnimationController.reset();
        _matchAnimationController.forward();

        // Match found
        matchedPairs.add(selectedGermanCard!.id);
        score += 10;

        // Mark word as learned in SharedPreferences
        // Find the corresponding word pair
        WordPair? matchedPair = wordPairs.firstWhere(
              (pair) => pair.id == selectedGermanCard!.id,
          orElse: () => wordPairs[0], // Fallback
        );

        // Reset selected cards
        selectedGermanCard = null;
        selectedEnglishCard = null;

        // Check if all pairs are matched
        if (matchedPairs.length == wordPairs.length) {
          gameActive = false;
          stopwatch.stop();
          if (timer != null) {
            timer!.cancel();
          }
          HapticFeedback.heavyImpact();

          // Delay a bit to show the match animation before showing dialog
          Future.delayed(const Duration(milliseconds: 500), () {
            showGameCompleteDialog();
          });
        }
      } else {
        // No match - error feedback
        HapticFeedback.vibrate();
        _shakeAnimationController.reset();
        _shakeAnimationController.forward();

        // No match, reset after a delay
        Future.delayed(const Duration(milliseconds: 1000), () {
          selectedGermanCard = null;
          selectedEnglishCard = null;
          notifyListeners();
        });
      }
    }

    notifyListeners();
  }

  // Speak a word using TTS
  Future<void> speakWord(String word, String language) async {
    await flutterTts.setLanguage(language);
    await flutterTts.speak(word);
  }

  // Show game complete dialog
  void showGameCompleteDialog() {
    isGamePaused = true;
    notifyListeners();

    // Call the callback if set
    if (gameCompleteCallback != null) {
      gameCompleteCallback!(formattedTime, score);
    }
  }

  // Set callback for game completion dialog
  void setGameCompleteCallback(Function(String time, int score) callback) {
    gameCompleteCallback = callback;
  }

  // Pause game
  void togglePause() {
    isGamePaused = !isGamePaused;

    if (isGamePaused) {
      stopwatch.stop();
    } else {
      stopwatch.start();
    }

    notifyListeners();
  }

  // Play again after game is complete
  void playAgain() {
    initGame();
  }

  // Get counts for the game screen
  Future<Map<String, int>> getWordCounts() async {
    if (_prefs == null) {
      _prefs = await SharedPreferences.getInstance();
    }

    int totalWords = 0;
    Set<String> uniqueLearnedWords = Set<String>();

    try {
      // Load JSON to count total words
      final String jsonString = await rootBundle.loadString('assets/json/vocabulary.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      final Map<String, dynamic> levels = jsonData['vocabulary']['levels'];

      // Count total words and check which ones are learned
      levels.forEach((levelKey, levelValue) {
        List<dynamic> sections = levelValue['sections'];

        for (var section in sections) {
          List<dynamic> items = section['items'];

          for (var item in items) {
            String category = item['category'];
            String level = item['level'];
            List<dynamic> flashcards = item['flashcards'];

            for (var card in flashcards) {
              String cardId = card['id'];
              String uniqueWordKey = '${level}_${category}_${cardId}';

              // Count total unique words (avoid duplicates)
              if (!totalWords.toString().contains(uniqueWordKey)) {
                totalWords++;
              }

              // Check if learned in SharedPreferences using exact format
              String learnedKey = '${uniqueWordKey}_learned';
              bool isLearned = _prefs?.getBool(learnedKey) ?? false;

              if (isLearned) {
                // Use a unique identifier to prevent double-counting
                uniqueLearnedWords.add(uniqueWordKey);
              }
            }
          }
        }
      });
    } catch (e) {
      print('Error getting word counts: $e');
    }

    return {
      'total': totalWords,
      'learned': uniqueLearnedWords.length,
      'unlearned': totalWords - uniqueLearnedWords.length,
    };
  }
  @override
  void dispose() {
    flutterTts.stop();
    if (timer != null) {
      timer!.cancel();
    }
    super.dispose();
  }
}