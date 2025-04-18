import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

class GermanBasicsModel extends ChangeNotifier {
  bool _isLoading = true;
  List<Map<String, dynamic>> _categoriesData = [];
  List<Map<String, dynamic>> _practiceData = [];
  String _errorMessage = '';

  // Text-to-speech instance
  final FlutterTts _flutterTts = FlutterTts();
  bool _isSpeaking = false;

  // Constructor - initialize TTS and load data
  GermanBasicsModel() {
    _initTts();
    loadGermanBasicsData();
  }

  // Initialize text-to-speech
  Future<void> _initTts() async {
    try {
      // Set German language
      await _flutterTts.setLanguage('de-DE');

      // Set speech rate (0.5 is slower, 1.0 is normal)
      await _flutterTts.setSpeechRate(0.5);

      // Set volume
      await _flutterTts.setVolume(1.0);

      // Set pitch
      await _flutterTts.setPitch(1.0);

      // Set completed listener
      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
        notifyListeners();
      });

      debugPrint('Text-to-speech initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize text-to-speech: $e');
      _errorMessage = 'Could not initialize speech. Some features may be limited.';
      notifyListeners();
    }
  }

  // Getters
  bool get isLoading => _isLoading;
  List<Map<String, dynamic>> get categoriesData => _categoriesData;
  List<Map<String, dynamic>> get practiceData => _practiceData;
  String get errorMessage => _errorMessage;
  bool get hasError => _errorMessage.isNotEmpty;
  bool get isSpeaking => _isSpeaking;

  // Load data from JSON file
  Future<void> loadGermanBasicsData() async {
    try {
      _isLoading = true;
      _errorMessage = '';
      notifyListeners();

      // Simulate network delay for better UX feedback
      await Future.delayed(const Duration(milliseconds: 800));

      // Load JSON file from assets
      final String jsonData = await rootBundle.loadString('assets/json/germanbasics.json');
      final Map<String, dynamic> data = json.decode(jsonData);

      _categoriesData = List<Map<String, dynamic>>.from(data['categories']);
      _practiceData = List<Map<String, dynamic>>.from(data['practice']);
      _isLoading = false;

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading JSON data: $e');

      // If there's an error, provide some fallback data
      _categoriesData = _getFallbackCategoriesData();
      _practiceData = _getFallbackPracticeData();
      _errorMessage = 'Could not load data. Using fallback content.';
      _isLoading = false;

      notifyListeners();
    }
  }

  // Play speech for a word or phrase using text-to-speech
  Future<void> speak(String text, {bool showFeedback = true, BuildContext? context}) async {
    // If already speaking, stop current speech
    if (_isSpeaking) {
      await _flutterTts.stop();
      _isSpeaking = false;
    }

    try {
      // Set the language to German
      await _flutterTts.setLanguage('de-DE');

      // Speak the text
      await _flutterTts.speak(text);
      _isSpeaking = true;
      notifyListeners();

      // Show feedback if requested and context is provided
      if (showFeedback && context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Speaking: "$text"'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error speaking text: $e');

      // Show error feedback if requested and context is provided
      if (showFeedback && context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not speak the text. Please try again.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // Speak slowly (for pronunciation practice)
  Future<void> speakSlowly(String text, {BuildContext? context}) async {
    if (_isSpeaking) {
      await _flutterTts.stop();
      _isSpeaking = false;
    }

    try {
      await _flutterTts.setLanguage('de-DE');
      await _flutterTts.setSpeechRate(0.3); // Slower rate
      await _flutterTts.speak(text);
      _isSpeaking = true;
      notifyListeners();

      // Reset speech rate after speaking
      await Future.delayed(const Duration(seconds: 3));
      await _flutterTts.setSpeechRate(0.5); // Back to normal rate

      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Speaking slowly: "$text"'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error speaking text slowly: $e');
    }
  }

  // Stop current speech
  Future<void> stopSpeaking() async {
    if (_isSpeaking) {
      await _flutterTts.stop();
      _isSpeaking = false;
      notifyListeners();
    }
  }

  // Cleanup resources
  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  // Fallback data in case the JSON file can't be loaded
  List<Map<String, dynamic>> _getFallbackCategoriesData() {
    return [
      {
        'title': 'Alphabets',
        'subtitle': 'Learn German alphabet pronunciation',
        'color': '0xFF4CAF50',
        'icon': 'font_download',
        'items': [
          {
            'german': 'A',
            'english': 'A as in father',
            'example': 'Apfel (apple)'
          },
          {
            'german': 'B',
            'english': 'B as in boy',
            'example': 'Buch (book)'
          },
          {
            'german': 'C',
            'english': 'C as in cats',
            'example': 'Computer (computer)'
          }
        ]
      },
      {
        'title': 'Numbers',
        'subtitle': 'Count from 1 to 100 in German',
        'color': '0xFF2196F3',
        'icon': 'format_list_numbered',
        'items': [
          {
            'german': 'eins',
            'english': 'one',
            'example': 'Ich habe ein Buch. (I have one book.)'
          },
          {
            'german': 'zwei',
            'english': 'two',
            'example': 'Ich habe zwei Katzen. (I have two cats.)'
          },
          {
            'german': 'drei',
            'english': 'three',
            'example': 'Drei Männer gehen in eine Bar. (Three men walk into a bar.)'
          }
        ]
      },
      {
        'title': 'Colors',
        'subtitle': 'Learn colors in German',
        'color': '0xFFFF9800',
        'icon': 'palette',
        'items': [
          {
            'german': 'rot',
            'english': 'red',
            'example': 'Das Auto ist rot. (The car is red.)'
          },
          {
            'german': 'blau',
            'english': 'blue',
            'example': 'Der Himmel ist blau. (The sky is blue.)'
          },
          {
            'german': 'grün',
            'english': 'green',
            'example': 'Das Gras ist grün. (The grass is green.)'
          }
        ]
      },
      {
        'title': 'Months',
        'subtitle': 'Names of months in German',
        'color': '0xFF9C27B0',
        'icon': 'calendar_today',
        'items': [
          {
            'german': 'Januar',
            'english': 'January',
            'example': 'Im Januar ist es kalt. (It is cold in January.)'
          },
          {
            'german': 'Februar',
            'english': 'February',
            'example': 'Mein Geburtstag ist im Februar. (My birthday is in February.)'
          },
          {
            'german': 'März',
            'english': 'March',
            'example': 'Im März beginnt der Frühling. (Spring begins in March.)'
          }
        ]
      },
      {
        'title': 'Seasons',
        'subtitle': 'The four seasons in German',
        'color': '0xFF795548',
        'icon': 'eco',
        'items': [
          {
            'german': 'Frühling',
            'english': 'Spring',
            'example': 'Im Frühling blühen die Blumen. (Flowers bloom in spring.)'
          },
          {
            'german': 'Sommer',
            'english': 'Summer',
            'example': 'Im Sommer ist es heiß. (It is hot in summer.)'
          },
          {
            'german': 'Herbst',
            'english': 'Autumn/Fall',
            'example': 'Im Herbst fallen die Blätter. (Leaves fall in autumn.)'
          },
          {
            'german': 'Winter',
            'english': 'Winter',
            'example': 'Im Winter schneit es. (It snows in winter.)'
          }
        ]
      },
      {
        'title': 'Basic Grammar',
        'subtitle': 'Essential German grammar rules',
        'color': '0xFFF44336',
        'icon': 'menu_book',
        'items': [
          {
            'german': 'Der, Die, Das',
            'english': 'The (masc., fem., neut.)',
            'example': 'Der Mann, die Frau, das Kind. (The man, the woman, the child.)'
          },
          {
            'german': 'Ich, Du, Er/Sie/Es',
            'english': 'I, You, He/She/It',
            'example': 'Ich bin, du bist, er/sie/es ist. (I am, you are, he/she/it is.)'
          },
          {
            'german': 'Wir, Ihr, Sie',
            'english': 'We, You (plural), They',
            'example': 'Wir sind, ihr seid, sie sind. (We are, you are, they are.)'
          }
        ]
      },
    ];
  }

  List<Map<String, dynamic>> _getFallbackPracticeData() {
    return [
      {
        'title': 'Flashcards',
        'subtitle': 'Test your vocabulary knowledge',
        'color': '0xFF3F51B5',
        'icon': 'flash_on',
      },
      {
        'title': 'Pronunciation',
        'subtitle': 'Practice your German accent',
        'color': '0xFFE91E63',
        'icon': 'record_voice_over',
      },
      {
        'title': 'Listening',
        'subtitle': 'Audio exercises for comprehension',
        'color': '0xFF009688',
        'icon': 'headset',
      },
      {
        'title': 'Writing',
        'subtitle': 'Practice writing in German',
        'color': '0xFF607D8B',
        'icon': 'create',
      },
    ];
  }

  // Helper function to get the proper IconData from a string
  IconData getIconData(String iconName) {
    switch (iconName) {
      case 'font_download': return Icons.font_download;
      case 'format_list_numbered': return Icons.format_list_numbered;
      case 'palette': return Icons.palette;
      case 'calendar_today': return Icons.calendar_today;
      case 'eco': return Icons.eco;
      case 'menu_book': return Icons.menu_book;
      case 'flash_on': return Icons.flash_on;
      case 'record_voice_over': return Icons.record_voice_over;
      case 'headset': return Icons.headset;
      case 'create': return Icons.create;
      default: return Icons.auto_stories;
    }
  }
}