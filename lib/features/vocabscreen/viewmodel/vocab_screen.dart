
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../view/vocab_screen.dart';


class FlashcardProvider extends ChangeNotifier {
  int currentIndex = 0;
  bool isFlipped = false;
  bool isPlaying = false;
  List<FlashcardData> flashcards = [];
  String currentCategory = '';
  String currentLevel = '';
  String currentTitle = '';
  int wordsViewed = 0;
  int wordsCompleted = 0;
  bool initialized = false;

  // Instance of shared preferences
  SharedPreferences? _prefs;

  final FlutterTts flutterTts = FlutterTts();

  FlashcardProvider() {
    _initSharedPreferences();
  }



  // Initialize shared preferences
  Future<void> _initSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    // Load total stats
    wordsViewed = _prefs?.getInt('total_words_viewed') ?? 0;
    wordsCompleted = _prefs?.getInt('total_words_completed') ?? 0;
    notifyListeners();
  }

  Future<void> initTts() async {
    if (!initialized) {
      await flutterTts.setLanguage('de-DE');
      await flutterTts.setSpeechRate(0.5);
      await flutterTts.setVolume(1.0);

      flutterTts.setCompletionHandler(() {
        isPlaying = false;
        notifyListeners();
      });

      initialized = true;
    }
  }



  void loadFlashcards(String category, String level, String title, List<FlashcardData> cards, BuildContext context) async {
    currentCategory = category;
    currentLevel = level;
    currentTitle = title;

    // Load flashcard status from storage
    for (var card in cards) {
      String cardKey = '${level}_${category}_${card.id}';
      card.isLearned = _prefs?.getBool('${cardKey}_learned') ?? false;
      card.isBookmarked = _prefs?.getBool('${cardKey}_bookmarked') ?? false;
    }

    flashcards = cards;
    currentIndex = 0;
    isFlipped = false;

    // Mark category as started in VocabularyProvider
    try {
      final vocabProvider = Provider.of<VocabularyProvider>(
          context,
          listen: false
      );
      vocabProvider.markCategoryAsStarted(level, category);
    } catch (e) {
      print('Error marking category as started: $e');
    }

    // Update progress for this category
    _updateCategoryProgress(context);

    initTts();
    notifyListeners();
  }

  // Calculate and save progress for the current category
  // Update the _updateCategoryProgress method in FlashcardProvider

  void _updateCategoryProgress(BuildContext context) {
    if (flashcards.isEmpty) return;

    int learnedCount = flashcards.where((card) => card.isLearned).length;
    double progress = learnedCount / flashcards.length;

    // Save progress to shared preferences
    _prefs?.setDouble('${currentLevel}_${currentCategory}_progress', progress);

    // Mark as started
    _prefs?.setBool('${currentLevel}_${currentCategory}_started', true);

    // Update UI through vocabulary provider
    try {
      final vocabProvider = Provider.of<VocabularyProvider>(
          context,
          listen: false
      );
      vocabProvider.updateCategoryProgress(currentLevel, currentCategory, progress);
    } catch (e) {
      print('Error updating category progress: $e');
    }
  }

  Future<void> playPronunciation() async {
    if (isPlaying) {
      await flutterTts.stop();
      isPlaying = false;
      notifyListeners();
      return;
    }

    if (currentIndex < flashcards.length) {
      isPlaying = true;

      // Record view and save to shared preferences
      wordsViewed++;
      _prefs?.setInt('total_words_viewed', wordsViewed);

      // Also mark this specific word as viewed
      String cardKey = '${currentLevel}_${currentCategory}_${flashcards[currentIndex].id}';
      _prefs?.setBool('${cardKey}_viewed', true);

      notifyListeners();

      try {
        await flutterTts.speak(flashcards[currentIndex].german);
      } catch (e) {
        print('Error playing TTS: $e');
        isPlaying = false;
        notifyListeners();
      }
    }
  }

  // Other methods remain the same...

  void markAsLearned(context) {
    if (currentIndex < flashcards.length) {
      flashcards[currentIndex].isLearned = true;
      wordsCompleted++;

      // Save to shared preferences
      String cardKey = '${currentLevel}_${currentCategory}_${flashcards[currentIndex].id}';
      _prefs?.setBool('${cardKey}_learned', true);
      _prefs?.setInt('total_words_completed', wordsCompleted);

      // Update category progress
      _updateCategoryProgress(context);

      notifyListeners();
    }
  }

  void toggleBookmark() {
    if (currentIndex < flashcards.length) {
      flashcards[currentIndex].isBookmarked = !flashcards[currentIndex].isBookmarked;

      // Save to shared preferences
      String cardKey = '${currentLevel}_${currentCategory}_${flashcards[currentIndex].id}';
      _prefs?.setBool('${cardKey}_bookmarked', flashcards[currentIndex].isBookmarked);

      notifyListeners();
    }
  }




  Future<void> playExample() async {
    if (isPlaying) {
      await flutterTts.stop();
      isPlaying = false;
      notifyListeners();
      return;
    }

    if (currentIndex < flashcards.length && flashcards[currentIndex].examples.isNotEmpty) {
      isPlaying = true;
      notifyListeners();

      try {
        final example = flashcards[currentIndex].examples[0];
        final fullText = example.prefix + example.highlight + example.suffix;
        await flutterTts.speak(fullText);
      } catch (e) {
        print('Error playing TTS: $e');
        isPlaying = false;
        notifyListeners();
      }
    }
  }

  void flipCard() {
    isFlipped = !isFlipped;
    notifyListeners();
  }

  void nextCard() {
    if (currentIndex < flashcards.length - 1) {
      currentIndex++;
    } else {
      currentIndex = 0; // Loop back to first card
    }

    isFlipped = false;
    notifyListeners();
  }

  void previousCard() {
    if (currentIndex > 0) {
      currentIndex--;
    } else {
      currentIndex = flashcards.length - 1; // Loop to last card
    }

    isFlipped = false;
    notifyListeners();
  }


  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }
}