import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:German_Spark/features/storiesScreen/model/stories_model.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

import '../viewModel/quiz_viewmodel.dart';

class StoryDetailScreen extends StatefulWidget {
  final String title;
  final List<StoryItem> storyItems;
  final String level;
  final String duration;
  final String description;
  final List<QuestionModel> questions;

  const StoryDetailScreen({
    super.key,
    required this.title,
    required this.storyItems,
    required this.level,
    required this.duration,
    required this.description,
    required this.questions,
  });

  @override
  _StoryDetailScreenState createState() => _StoryDetailScreenState();
}

enum TtsState { playing, stopped, paused, continued }

class CharacterVoiceSettings {
  final String characterName;
  String voiceLocale;
  double speechRate;

  CharacterVoiceSettings({
    required this.characterName,
    required this.voiceLocale,
    this.speechRate = 0.3,
  });
}

class _StoryDetailScreenState extends State<StoryDetailScreen>
    with SingleTickerProviderStateMixin {
  // TTS engine
  late FlutterTts _flutterTts;
  bool _isPlaying = false;
  bool _isPaused = false;
  double _speechRate = 0.5; // Slower initial rate
  double _pauseDuration = 1.0; // Pause duration in seconds
  String _selectedVoice = 'de-DE'; // Default voice

  // Voice options (will be populated when TTS is initialized)
  List<Map<String, String>> _voices = [];

  // Character-specific voices
  Map<String, CharacterVoiceSettings> _characterVoices = {};

  // For voice settings tab control
  late TabController _tabController;
  int _currentTabIndex = 0;

  // Auto-play setting
  bool _autoPlayOnLoad = true;

  // Enhanced TTS state tracking
  TtsState _ttsState = TtsState.stopped;
  bool get isPlaying => _ttsState == TtsState.playing;
  bool get isStopped => _ttsState == TtsState.stopped;
  bool get isPaused => _ttsState == TtsState.paused;

  // UI state
  bool _showTranslation = true;
  int _fontSize = 18;

  // For animated character indicator
  Map<String, Color> _characterColors = {};
  final List<Color> _predefinedColors = [
    Colors.red.shade300,
    Colors.green.shade300,
    Colors.blue.shade300,
    Colors.orange.shade300,
    Colors.purple.shade300,
    Colors.teal.shade300,
  ];

  // Scroll controller
  final ScrollController _scrollController = ScrollController();

  // For tracking
  int _currentItemIndex = 0;
  Timer? _autoScrollTimer;
  Timer? _pauseTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);

    _initTts();
    _loadPreferences();
    _assignCharacterColors();

    // Use a small delay to ensure TTS is initialized before playback
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_autoPlayOnLoad && mounted) {
        _speak();
      }
    });
  }

  void _assignCharacterColors() {
    // Find all characters in the story
    Set<String> characters = {};
    for (var item in widget.storyItems) {
      characters.add(_detectCharacter(item.germanText));
    }

    // Assign a color to each character
    int colorIndex = 0;
    for (var character in characters) {
      // The Narrator gets a neutral color
      if (character == "Narrator") {
        _characterColors[character] = Colors.grey.shade400;
      } else {
        _characterColors[character] =
            _predefinedColors[colorIndex % _predefinedColors.length];
        colorIndex++;
      }
    }
  }

  void _handleTabChange() {
    setState(() {
      _currentTabIndex = _tabController.index;
    });
  }

  // Detect which character is speaking in the text
  String _detectCharacter(String text) {
    // Character detection patterns
    final colonPattern = RegExp(r'^([^:]+):\s');
    final quotesPattern = RegExp(r'^["„]([^""]*)[""]:\s');

    // Check for character name patterns
    var colonMatch = colonPattern.firstMatch(text);
    var quotesMatch = quotesPattern.firstMatch(text);

    if (colonMatch != null && colonMatch.group(1) != null) {
      return colonMatch.group(1)!.trim();
    } else if (quotesMatch != null && quotesMatch.group(1) != null) {
      return quotesMatch.group(1)!.trim();
    }

    // Default character for narrative text
    return "Narrator";
  }

  // Helper method to strip character prefix from speech text
  String _stripCharacterPrefix(String text) {
    final colonPattern = RegExp(r'^([^:]+):\s');
    final quotesPattern = RegExp(r'^["„]([^""]*)[""]:\s');

    if (colonPattern.hasMatch(text)) {
      return text.replaceFirst(colonPattern, '');
    } else if (quotesPattern.hasMatch(text)) {
      return text.replaceFirst(quotesPattern, '');
    }

    return text;
  }

  // Helper method to get a short voice name to display on the UI
  String _getVoiceNameForLocale(String locale) {
    final voice = _voices.firstWhere(
      (v) => v['locale'] == locale,
      orElse: () => {'name': 'Unknown Voice'},
    );

    final name = voice['name'] ?? 'Unknown';

    // Extract a short name from the full voice name
    if (name.contains('Male')) return 'Male';
    if (name.contains('Female')) return 'Female';
    if (name.contains('Austrian')) return 'Austrian';
    if (name.contains('Swiss')) return 'Swiss';

    // Extract just the gender if available
    final genderMatch =
        RegExp(r'\((Male|Female|Männlich|Weiblich)\)').firstMatch(name);
    if (genderMatch != null) return genderMatch.group(1)!;

    // Default to a shortened version
    return name.split(' ').first;
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _fontSize = prefs.getInt('fontSize') ?? 18;
      _showTranslation = prefs.getBool('showTranslation') ?? true;
      _autoPlayOnLoad = prefs.getBool('autoPlayOnLoad') ?? true;
      _speechRate = prefs.getDouble('speechRate') ?? 0.3;
      _pauseDuration = prefs.getDouble('pauseDuration') ?? 1.0;
      _selectedVoice = prefs.getString('selectedVoice') ?? 'de-DE';

      // Load saved character voices
      final characterVoicesJson = prefs.getString('characterVoices');
      if (characterVoicesJson != null) {
        try {
          final Map<String, dynamic> decodedMap =
              jsonDecode(characterVoicesJson);
          decodedMap.forEach((character, voiceData) {
            if (voiceData is Map<String, dynamic> &&
                voiceData.containsKey('voiceLocale')) {
              _characterVoices[character] = CharacterVoiceSettings(
                characterName: character,
                voiceLocale: voiceData['voiceLocale'],
                speechRate: voiceData['speechRate'] ?? _speechRate,
              );
            }
          });
        } catch (e) {
          print("Error loading character voices: $e");
        }
      }
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('fontSize', _fontSize);
    await prefs.setBool('showTranslation', _showTranslation);
    await prefs.setBool('autoPlayOnLoad', _autoPlayOnLoad);
    await prefs.setDouble('speechRate', _speechRate);
    await prefs.setDouble('pauseDuration', _pauseDuration);
    await prefs.setString('selectedVoice', _selectedVoice);

    // Save character voices
    Map<String, dynamic> characterVoicesMap = {};
    _characterVoices.forEach((character, settings) {
      characterVoicesMap[character] = {
        'voiceLocale': settings.voiceLocale,
        'speechRate': settings.speechRate,
      };
    });
    await prefs.setString('characterVoices', jsonEncode(characterVoicesMap));
  }

  Future<void> _initTts() async {
    _flutterTts = FlutterTts();

    if (!kIsWeb) {
      if (Platform.isIOS) {
        var voices = await _flutterTts.getVoices;
        print('Available voices: $voices');

        // Get available German voices for iOS
        _loadVoices(voices);

        // iOS-specific settings
        await _flutterTts.setSharedInstance(true);
        try {
          await _flutterTts.setIosAudioCategory(
              IosTextToSpeechAudioCategory.playback,
              [
                IosTextToSpeechAudioCategoryOptions.allowBluetooth,
                IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
                IosTextToSpeechAudioCategoryOptions.mixWithOthers,
              ],
              IosTextToSpeechAudioMode.defaultMode);
        } catch (e) {
          print("iOS Audio Category Error: $e");
        }
      } else if (Platform.isAndroid) {
        var voices = await _flutterTts.getVoices;
        print('Available voices: $voices');

        // Get available German voices for Android
        _loadVoices(voices);
      }
    }

    // Configure TTS for German language
    await _flutterTts.setLanguage(_selectedVoice);
    await _flutterTts.setSpeechRate(_speechRate);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    // Set up callbacks
    _flutterTts.setStartHandler(() {
      print("TTS STARTED");
      setState(() {
        _ttsState = TtsState.playing;
        _isPlaying = true;
        _isPaused = false;
      });
    });

    _flutterTts.setCompletionHandler(() {
      print("TTS COMPLETED");

      // Cancel any existing pause timer
      _pauseTimer?.cancel();

      // Add pause between items
      _pauseTimer =
          Timer(Duration(milliseconds: (_pauseDuration * 1000).round()), () {
        if (_currentItemIndex < widget.storyItems.length - 1) {
          setState(() {
            _currentItemIndex++;
          });

          // Speak the next item after the pause
          _speakCurrentItem();
        } else {
          // End of list reached
          setState(() {
            _ttsState = TtsState.stopped;
            _isPlaying = false;
            _isPaused = false;
            _currentItemIndex = 0;
          });
          _stopAutoScroll();
        }
      });
    });

    _flutterTts.setErrorHandler((msg) {
      print("TTS ERROR: $msg");
      _handleSpeechFailure();
    });

    // These may not work on iOS but harmless to set
    _flutterTts.setPauseHandler(() {
      print("TTS PAUSED");
      setState(() {
        _ttsState = TtsState.paused;
        _isPlaying = false;
        _isPaused = true;
      });
    });

    _flutterTts.setContinueHandler(() {
      print("TTS CONTINUED");
      setState(() {
        _ttsState = TtsState.continued;
        _isPlaying = true;
        _isPaused = false;
      });
    });
  }

  void _loadVoices(dynamic voices) {
    // Clear previous voices list
    _voices.clear();

    // Default option
    _voices.add({'name': 'Default German', 'locale': 'de-DE'});

    try {
      if (voices is List) {
        for (var voice in voices) {
          if (voice is Map) {
            // Filter for German voices
            String? locale = voice['locale'] as String?;
            String? name = voice['name'] as String?;
            String? gender = voice['gender'] as String?;

            if (locale != null && name != null && locale.startsWith('de')) {
              String displayName = '$name (${gender ?? 'Unknown'})';

              _voices.add({'name': displayName, 'locale': locale});
            }
          }
        }
      }
    } catch (e) {
      print("Error parsing voices: $e");
    }

    // If no German voices found, add some fallback options
    if (_voices.length <= 1) {
      _voices.addAll([
        {'name': 'German Male', 'locale': 'de-DE-x-de-male'},
        {'name': 'German Female', 'locale': 'de-DE-x-de-female'},
        {'name': 'Austrian German', 'locale': 'de-AT'},
        {'name': 'Swiss German', 'locale': 'de-CH'}
      ]);
    }

    // Ensure we have voices assigned to all characters
    _setupCharacterVoices();

    setState(() {});
  }

  void _setupCharacterVoices() {
    // Find all characters in the story
    Set<String> characters = {};
    for (var item in widget.storyItems) {
      characters.add(_detectCharacter(item.germanText));
    }

    // Create voice settings for each character if they don't exist
    for (var character in characters) {
      if (!_characterVoices.containsKey(character)) {
        // For narrator, use a more neutral voice
        if (character == "Narrator") {
          final defaultVoice = _voices.firstWhere(
            (v) => v['name']?.contains('Male') ?? false,
            orElse: () => {'locale': 'de-DE', 'name': 'Default German'},
          );

          _characterVoices[character] = CharacterVoiceSettings(
            characterName: character,
            voiceLocale: defaultVoice['locale']!,
            speechRate: _speechRate * 0.9, // Slightly slower for narrator
          );
        } else {
          // Alternate between male and female voices for characters
          // based on character name length as a simple heuristic
          final isMale = character.length % 2 == 0;
          final defaultVoice = _voices.firstWhere(
            (v) => v['name']?.contains(isMale ? 'Male' : 'Female') ?? false,
            orElse: () => {'locale': 'de-DE', 'name': 'Default German'},
          );

          _characterVoices[character] = CharacterVoiceSettings(
            characterName: character,
            voiceLocale: defaultVoice['locale']!,
            speechRate: _speechRate,
          );
        }
      }
    }
  }

  void _stopAutoScroll() {
    if (_autoScrollTimer != null && _autoScrollTimer!.isActive) {
      _autoScrollTimer!.cancel();
      _autoScrollTimer = null;
    }
  }

  // Only scroll when current item is at bottom of screen
  void _startAutoScroll() {
    // Cancel any existing timer
    _stopAutoScroll();

    // Start a periodic timer to check if we need to scroll
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _scrollToCurrentItemIfNeeded();
    });
  }

  void _scrollToCurrentItemIfNeeded() {
    if (!_scrollController.hasClients || _currentItemIndex <= 0) return;

    // Get the current position
    final double viewportHeight = _scrollController.position.viewportDimension;
    final double maxScroll = _scrollController.position.maxScrollExtent;
    final double currentScroll = _scrollController.offset;

    // Calculate item height (approximate)
    final double itemHeight = (maxScroll / widget.storyItems.length) * 1.2;

    // Calculate where the current item should be
    final double targetPosition = _currentItemIndex * itemHeight;

    // Only scroll if item is near bottom of screen or out of view
    if (targetPosition > currentScroll + viewportHeight * 0.7) {
      _scrollController.animateTo(
        targetPosition - viewportHeight * 0.5, // Center the item
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
    }
  }

  // Improved _speakCurrentItem with character voice support
  Future<void> _speakCurrentItem() async {
    if (_currentItemIndex >= 0 &&
        _currentItemIndex < widget.storyItems.length) {
      try {
        await _flutterTts.stop();

        final textToSpeak = widget.storyItems[_currentItemIndex].germanText;
        final textToShow = _stripCharacterPrefix(textToSpeak);
        print("Speaking: $textToSpeak");

        {
          // Use the global voice setting
          await _flutterTts.setLanguage(_selectedVoice);
          await _flutterTts.setSpeechRate(_speechRate);
        }
        // Update state and speak
        setState(() {
          _ttsState = TtsState.playing;
          _isPlaying = true;
          _isPaused = false;
        });

        var result = await _flutterTts.speak(textToShow);
        print("Speak result: $result");

        // Platform-specific result handling
        if (kIsWeb) {
          print("Web TTS initiated");
        } else if (Platform.isIOS) {
          if (result == 1) {
            print("iOS speech started successfully");
          } else {
            print("iOS speech failed with result: $result");
            _handleSpeechFailure();
          }
        } else if (Platform.isAndroid) {
          if (result == 1) {
            print("Android speech started successfully");
          } else {
            print("Android speech failed with result: $result");
            _handleSpeechFailure();
          }
        }

        // Scroll if needed
        _scrollToCurrentItemIfNeeded();
      } catch (e) {
        print("Error in _speakCurrentItem: $e");
        _handleSpeechFailure();
      }
    }
  }

  void _handleSpeechFailure() {
    // If speaking fails, try to recover or notify the user
    setState(() {
      _ttsState = TtsState.stopped;
      _isPlaying = false;
      _isPaused = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Speech failed. Try adjusting the speed or restarting.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  // Toggle auto-play on load setting
  void _toggleAutoPlayOnLoad() {
    setState(() {
      _autoPlayOnLoad = !_autoPlayOnLoad;
    });
    _savePreferences();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF3F51B5),
        content: Text(_autoPlayOnLoad
            ? 'Auto-play on open enabled'
            : 'Auto-play on open disabled',style:const TextStyle(color: Colors.white),),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Enhanced dispose method to ensure proper cleanup
  @override
  void dispose() {
    _flutterTts.stop();
    _stopAutoScroll();
    _pauseTimer?.cancel();
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // Updated speak method with better state management
  Future<void> _speak() async {
    print("Current TTS state: $_ttsState");

    if (isPlaying) {
      print("Stopping playback");
      await _flutterTts.stop();
      setState(() {
        _ttsState = TtsState.paused;
        _isPlaying = false;
        _isPaused = true;
      });
      _stopAutoScroll();
    } else {
      if (isPaused || isStopped) {
        print("Starting/resuming playback");
        await _speakCurrentItem();
        _startAutoScroll();
      }
    }
  }

  // Navigation methods with consistent state handling
  Future<void> _nextItem() async {
    if (_currentItemIndex < widget.storyItems.length - 1) {
      // Save the current playing state
      final wasPlaying = isPlaying;

      // Always stop current speech
      await _flutterTts.stop();

      // Update index
      setState(() {
        _currentItemIndex++;
        if (!wasPlaying) {
          _ttsState = TtsState.stopped;
          _isPlaying = false;
          _isPaused = false;
        }
      });

      // Resume speech if it was playing
      if (wasPlaying) {
        await _speakCurrentItem();
      } else {
        _scrollToCurrentItemIfNeeded();
      }
    }
  }

  Future<void> _previousItem() async {
    if (_currentItemIndex > 0) {
      // Save the current playing state
      final wasPlaying = isPlaying;

      // Always stop current speech
      await _flutterTts.stop();

      // Update index
      setState(() {
        _currentItemIndex--;
        if (!wasPlaying) {
          _ttsState = TtsState.stopped;
          _isPlaying = false;
          _isPaused = false;
        }
      });

      // Resume speech if it was playing
      if (wasPlaying) {
        await _speakCurrentItem();
      } else {
        _scrollToCurrentItemIfNeeded();
      }
    }
  }

  // Clean stop method
  Future<void> _stop() async {
    await _flutterTts.stop();
    setState(() {
      _ttsState = TtsState.stopped;
      _isPlaying = false;
      _isPaused = false;
      _currentItemIndex = 0;
    });
    _stopAutoScroll();
  }

  // Voice settings methods
  Future<void> _setRate(double rate) async {
    await _flutterTts.setSpeechRate(rate);
    setState(() {
      _speechRate = rate;
    });
    _savePreferences();
  }

  Future<void> _setPauseDuration(double duration) async {
    setState(() {
      _pauseDuration = duration;
    });
    _savePreferences();
  }

  Future<void> _setVoice(String voice) async {
    await _flutterTts.stop();
    await _flutterTts.setLanguage(voice);
    setState(() {
      _selectedVoice = voice;
    });
    _savePreferences();

    if (_isPlaying) {
      await _speakCurrentItem();
    }
  }

  // Character voice methods
  Future<void> _setCharacterVoice(String character, String voice) async {
    if (_characterVoices.containsKey(character)) {
      setState(() {
        _characterVoices[character]!.voiceLocale = voice;
      });
      _savePreferences();

      // If we're currently playing this character, update the voice immediately
      if (isPlaying &&
          _currentItemIndex < widget.storyItems.length &&
          _detectCharacter(widget.storyItems[_currentItemIndex].germanText) ==
              character) {
        await _flutterTts.stop();
        await _speakCurrentItem();
      }
    }
  }

  Future<void> _setCharacterSpeechRate(String character, double rate) async {
    if (_characterVoices.containsKey(character)) {
      setState(() {
        _characterVoices[character]!.speechRate = rate;
      });
      _savePreferences();

      // Update speech rate if currently playing this character
      if (isPlaying &&
          _currentItemIndex < widget.storyItems.length &&
          _detectCharacter(widget.storyItems[_currentItemIndex].germanText) ==
              character) {
        await _flutterTts.setSpeechRate(rate);
      }
    }
  }

  // Enhanced voice settings dialog with tabs for main voice and character voices
  void _showVoiceSettingsDialog() {
    // Make sure character voices are set up
    _setupCharacterVoices();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header with gradient
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF3F51B5), Color(0xFF5C6BC0)],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Handle bar
                      Center(
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),

                      // Title
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.settings_voice,
                            color: Colors.white,
                            size: 28,
                          ),
                          SizedBox(width: 12),
                          Text(
                            "Voice Settings",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Main content
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    children: [
                      // Speech rate section
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8EAF6),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.speed,
                                    color: Color(0xFF3F51B5),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                const Expanded(
                                  child: Text(
                                    "Speaking Speed",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF3F51B5),
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF3F51B5),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    "${(_speechRate * 100).round()}%",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                const Icon(
                                  Icons.safety_check,
                                  color: Colors.grey,
                                  size: 20,
                                ),
                                Expanded(
                                  child: SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      trackHeight: 6,
                                      thumbShape: const RoundSliderThumbShape(
                                          enabledThumbRadius: 10),
                                      overlayShape:
                                          const RoundSliderOverlayShape(
                                              overlayRadius: 20),
                                    ),
                                    child: Slider(
                                      value: _speechRate,
                                      min: 0.1,
                                      max: 0.7,
                                      divisions: 6,
                                      activeColor: const Color(0xFF3F51B5),
                                      inactiveColor: Colors.grey[300],
                                      label:
                                          "Speed: ${(_speechRate * 100).round()}%",
                                      onChanged: (newValue) {
                                        setModalState(() {
                                          _speechRate = newValue;
                                        });
                                        _setRate(newValue);
                                      },
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.add,
                                  color: Colors.grey,
                                  size: 20,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Pause duration section
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8EAF6),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.timer,
                                    color: Color(0xFF3F51B5),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                const Expanded(
                                  child: Text(
                                    "Pause Between Sentences",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF3F51B5),
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF3F51B5),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    "${_pauseDuration.toStringAsFixed(1)}s",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                const Text(
                                  "Short",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                                Expanded(
                                  child: SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      trackHeight: 6,
                                      thumbShape: const RoundSliderThumbShape(
                                          enabledThumbRadius: 10),
                                      overlayShape:
                                          const RoundSliderOverlayShape(
                                              overlayRadius: 20),
                                    ),
                                    child: Slider(
                                      value: _pauseDuration,
                                      min: 0.5,
                                      max: 3.0,
                                      divisions: 5,
                                      activeColor: const Color(0xFF3F51B5),
                                      inactiveColor: Colors.grey[300],
                                      label:
                                          "${_pauseDuration.toStringAsFixed(1)}s",
                                      onChanged: (newValue) {
                                        setModalState(() {
                                          _pauseDuration = newValue;
                                        });
                                        _setPauseDuration(newValue);
                                      },
                                    ),
                                  ),
                                ),
                                const Text(
                                  "Long",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Test voice button
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFE8EAF6), Color(0xFFC5CAE9)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: const Color(0xFF3F51B5),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () async {
                            try {
                              await _flutterTts.stop();
                              await _flutterTts
                                  .speak("Hallo! Das ist ein Test.");
                            } catch (e) {
                              print("Error testing voice: $e");
                            }
                          },
                          icon: const Icon(
                            Icons.play_circle_outline,
                            size: 28,
                          ),
                          label: const Text(
                            "Test Voice",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Apply button
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF3F51B5), Color(0xFF5C6BC0)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3F51B5).withOpacity(0.4),
                          blurRadius: 8,
                          spreadRadius: 0,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        "Apply Settings",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _toggleTranslation() {
    setState(() {
      _showTranslation = !_showTranslation;
    });
    _savePreferences();
  }

  void _changeFontSize(int change) {
    final newSize = _fontSize + change;
    if (newSize >= 14 && newSize <= 28) {
      setState(() {
        _fontSize = newSize;
      });
      _savePreferences();
    }
  }

  // Build method for the playback controls with enhanced debugging
  Widget _buildPlaybackControls() {
    IconData playPauseIcon = Icons.play_arrow;

    if (isPlaying) {
      playPauseIcon = Icons.pause;
    } else if (isPaused) {
      playPauseIcon = Icons.play_arrow;
    } else {
      playPauseIcon = Icons.play_arrow;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.skip_previous),
                onPressed: _previousItem,
              ),
              IconButton(
                icon: Icon(playPauseIcon, size: 32),
                onPressed: _speak,
              ),
              IconButton(
                icon: const Icon(Icons.skip_next),
                onPressed: _nextItem,
              ),
              Expanded(
                child: SliderTheme(
                  data: const SliderThemeData(
                    trackHeight: 4,
                    thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8),
                  ),
                  child: Slider(
                    value: _currentItemIndex.toDouble(),
                    min: 0,
                    max: (widget.storyItems.length - 1).toDouble(),
                    divisions: widget.storyItems.length - 1,
                    onChanged: (value) {
                      final wasPlaying = isPlaying;
                      _flutterTts.stop();

                      setState(() {
                        _currentItemIndex = value.round();
                        if (!wasPlaying) {
                          _ttsState = TtsState.stopped;
                          _isPlaying = false;
                          _isPaused = false;
                        }
                      });

                      if (wasPlaying) {
                        _speakCurrentItem();
                      } else {
                        _scrollToCurrentItemIfNeeded();
                      }
                    },
                  ),
                ),
              ),
              Text(
                '${_currentItemIndex + 1} / ${widget.storyItems.length}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Build a single story item with character indicator
  Widget _buildStoryItem(int index) {
    final storyItem = widget.storyItems[index];
    final String character = _detectCharacter(storyItem.germanText);
    final String displayText = _stripCharacterPrefix(storyItem.germanText);
    final Color characterColor =
        _characterColors[character] ?? Colors.grey.shade400;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF3F51B5), const Color(0xFF5C6BC0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3F51B5).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative elements
          Positioned(
            top: -15,
            right: -15,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -10,
            left: -10,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Main content
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  // Handle card tap if needed
                },
                splashColor: Colors.white.withOpacity(0.1),
                highlightColor: Colors.white.withOpacity(0.05),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Character indicator - only show if character voices are enabled

                      // German text
                      Text(
                        storyItem.germanText,
                        style: TextStyle(
                          fontSize: _fontSize.toDouble(),
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: const [
                            Shadow(
                              color: Colors.black26,
                              blurRadius: 2,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),

                      // English translation (if enabled)
                      if (_showTranslation) ...[
                        const SizedBox(height: 10),
                        Text(
                          storyItem.englishText,
                          style: TextStyle(
                            fontSize: _fontSize.toDouble() - 2,
                            fontStyle: FontStyle.italic,
                            color: Colors.white.withOpacity(0.85),
                          ),
                        ),
                      ],

                      // Current playing indicator
                      if (index == _currentItemIndex && _isPlaying) ...[
                        const SizedBox(height: 12),
                        Container(
                          height: 2,
                          width: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Active indicator on the left side
          if (index == _currentItemIndex)
            Positioned(
              left: 0,
              top: 12,
              bottom: 12,
              child: Container(
                width: 4,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      const BorderRadius.horizontal(right: Radius.circular(2)),
                ),
              ),
            ),

          // Character voice quick access button (if character voices enabled)
        ],
      ),
    );
  }

  // Quick voice change popup for a character
  void _showCharacterVoiceQuickChange(BuildContext context, String character) {
    if (!_characterVoices.containsKey(character)) return;

    final settings = _characterVoices[character]!;
    final characterColor = _characterColors[character] ?? Colors.grey.shade400;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.person, color: characterColor),
                const SizedBox(width: 8),
                Text(
                  "$character's Voice",
                  style: const TextStyle(fontSize: 18),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Voice selection dropdown
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: "Voice Type",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  value: settings.voiceLocale,
                  items: _voices.map((voice) {
                    return DropdownMenuItem<String>(
                      value: voice['locale'],
                      child: Text(voice['name']!),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        settings.voiceLocale = value;
                      });
                      _setCharacterVoice(character, value);
                    }
                  },
                ),

                const SizedBox(height: 16),

                // Speech rate slider
                Text(
                  "Speaking Speed: ${(settings.speechRate * 100).round()}%",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Slider(
                  value: settings.speechRate,
                  min: 0.1,
                  max: 0.7,
                  divisions: 6,
                  activeColor: characterColor,
                  label: "${(settings.speechRate * 100).round()}%",
                  onChanged: (value) {
                    setState(() {
                      settings.speechRate = value;
                    });
                    _setCharacterSpeechRate(character, value);
                  },
                ),

                // Test button
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await _flutterTts.stop();
                      await _flutterTts.setLanguage(settings.voiceLocale);
                      await _flutterTts.setSpeechRate(settings.speechRate);
                      await _flutterTts.speak("Hallo! Ich bin $character.");
                    },
                    icon: const Icon(Icons.play_circle_outline),
                    label: const Text("Test Voice"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: characterColor.withOpacity(0.2),
                      foregroundColor: characterColor,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close"),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF3F51B5),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Auto-play toggle
          IconButton(
            icon: Icon(
              _autoPlayOnLoad ? Icons.play_circle : Icons.play_circle_outline,
              color: Colors.white,
            ),
            onPressed: _toggleAutoPlayOnLoad,
            tooltip: "Toggle auto-play on open",
          ),
          // Translation toggle
          IconButton(
            icon: Icon(
              _showTranslation ? Icons.translate : Icons.translate_outlined,
              color: Colors.white,
            ),
            onPressed: _toggleTranslation,
            tooltip: "Toggle translation",
          ),
          // Character voices toggle
        ],
      ),
      body: Stack(children: [
        Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Story info card
                    const Padding(
                      padding: EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 1),
                        ],
                      ),
                    ),

                    // Story content
                    ...List.generate(widget.storyItems.length, (index) {
                      return _buildStoryItem(index);
                    }),
                    const SizedBox(
                      height: 60,
                    )
                  ],
                ),
              ),
            ),

            // Playback controls
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Use the new playback controls widget
                  _buildPlaybackControls(),

                  // Bottom controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Text size controls
                      IconButton(
                        icon: const Icon(Icons.text_decrease),
                        onPressed: () => _changeFontSize(-2),
                        tooltip: "Decrease text size",
                      ),
                      IconButton(
                        icon: const Icon(Icons.text_increase),
                        onPressed: () => _changeFontSize(2),
                        tooltip: "Increase text size",
                      ),

                      // Voice settings button
                      IconButton(
                        icon: const Icon(Icons.settings_voice),
                        onPressed: _showVoiceSettingsDialog,
                        tooltip: "Voice settings",
                      ),

                      // Character voices button

                      // Translation toggle
                      IconButton(
                        icon: const Icon(Icons.translate),
                        onPressed: _toggleTranslation,
                        tooltip: "Toggle translation",
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),

        // Quiz floating action button
        Positioned(
          right: 10,
          bottom: 120, // Position above the playback controls
          child: TweenAnimationBuilder(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 800),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: child,
              );
            },
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF5C6BC0), // Lighter indigo
                    Color(0xFF3F51B5), // Your UI's primary indigo
                    Color(0xFF303F9F), // Slightly darker indigo
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3F51B5).withOpacity(0.4),
                    blurRadius: 8,
                    spreadRadius: 1,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: FloatingActionButton(
                heroTag: "quiz_button",
                backgroundColor: Colors.transparent,
                elevation:
                    0, // Remove default elevation since we're using custom shadow
                onPressed: _showQuiz,
                tooltip: "Test your knowledge",
                child: const Icon(
                  Icons.quiz,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  void _showQuiz() {
    if (widget.questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No questions available for this story'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Stop any ongoing TTS
    if (_isPlaying) {
      _flutterTts.stop();
      setState(() {
        _ttsState = TtsState.stopped;
        _isPlaying = false;
        _isPaused = false;
      });
    }

    // Show quiz in bottom sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ChangeNotifierProvider(
          create: (_) => QuizViewModel(questions: widget.questions),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Consumer<QuizViewModel>(
              builder: (context, quizVM, _) {
                return quizVM.isCompleted
                    ? _buildQuizResults(quizVM)
                    : _buildQuizQuestion(quizVM);
              },
            ),
          ),
        );
      },
    );
  }

// Quiz question UI
  Widget _buildQuizQuestion(QuizViewModel quizVM) {
    final currentQuestion = quizVM.questions[quizVM.currentQuestionIndex];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 20),
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          // Quiz header
          Row(
            children: [
              const Icon(Icons.quiz, color: Color(0xFF3F51B5), size: 24),
              const SizedBox(width: 12),
              const Text(
                'Story Quiz',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3F51B5),
                ),
              ),
              const Spacer(),
              Text(
                'Question ${quizVM.currentQuestionIndex + 1}/${quizVM.questions.length}',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),

          // Progress indicator
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: (quizVM.currentQuestionIndex + 1) / quizVM.questions.length,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3F51B5)),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),

          const SizedBox(height: 24),

          // Question text
          Text(
            currentQuestion.question,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 24),

          // Answer options
          Expanded(
            child: ListView.builder(
              itemCount: currentQuestion.options.length,
              itemBuilder: (context, index) {
                // Colors based on state
                Color bgColor = Colors.white;
                Color borderColor = Colors.grey[300]!;

                if (quizVM.showResult) {
                  if (index == currentQuestion.correctAnswer) {
                    // Correct answer
                    bgColor = Colors.green[50]!;
                    borderColor = Colors.green;
                  } else if (quizVM.selectedOption == index) {
                    // Wrong answer selected
                    bgColor = Colors.red[50]!;
                    borderColor = Colors.red;
                  }
                } else if (quizVM.selectedOption == index) {
                  // Selected but not submitted
                  bgColor = const Color(0xFFE3F2FD);
                  borderColor = const Color(0xFF3F51B5);
                }

                return GestureDetector(
                  onTap: quizVM.showResult
                      ? null
                      : () => quizVM.selectOption(index),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor, width: 2),
                    ),
                    child: Row(
                      children: [
                        // Option selector
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: quizVM.selectedOption == index
                                ? const Color(0xFF3F51B5)
                                : Colors.grey[200],
                          ),
                          child: quizVM.selectedOption == index
                              ? const Icon(Icons.check,
                                  color: Colors.white, size: 16)
                              : null,
                        ),
                        const SizedBox(width: 12),

                        // Option text
                        Expanded(
                          child: Text(
                            currentQuestion.options[index],
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: quizVM.selectedOption == index
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),

                        // Result indicators
                        if (quizVM.showResult &&
                            index == currentQuestion.correctAnswer)
                          const Icon(Icons.check_circle, color: Colors.green),
                        if (quizVM.showResult &&
                            quizVM.selectedOption == index &&
                            index != currentQuestion.correctAnswer)
                          const Icon(Icons.cancel, color: Colors.red),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Next button
          if (quizVM.showResult)
            Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: ElevatedButton(
                onPressed: quizVM.nextQuestion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3F51B5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  quizVM.currentQuestionIndex < quizVM.questions.length - 1
                      ? 'Next Question'
                      : 'See Results',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

// Quiz results UI
  Widget _buildQuizResults(QuizViewModel quizVM) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Score display
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: quizVM.isPassed ? Colors.green[50] : Colors.red[50],
              border: Border.all(
                color: quizVM.isPassed ? Colors.green : Colors.red,
                width: 8,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${quizVM.score}/${quizVM.questions.length}',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color:
                          quizVM.isPassed ? Colors.green[700] : Colors.red[700],
                    ),
                  ),
                  Text(
                    '${quizVM.percentageScore.round()}%',
                    style: TextStyle(
                      fontSize: 18,
                      color:
                          quizVM.isPassed ? Colors.green[700] : Colors.red[700],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Result message
          Text(
            quizVM.isPassed ? 'Great job!' : 'Keep practicing!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: quizVM.isPassed ? Colors.green[700] : Colors.red[700],
            ),
          ),

          const SizedBox(height: 16),

          // Detail message
          Text(
            quizVM.isPassed
                ? 'You have successfully completed the quiz.'
                : 'You need more practice with this story.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),

          const SizedBox(height: 48),

          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  foregroundColor: Colors.black87,
                ),
                child: const Text('Back to Story'),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () {
                  quizVM.restartQuiz();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3F51B5),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getLevelColor(String level) {
    switch (level) {
      case 'Beginner':
        return Colors.green;
      case 'Intermediate':
        return Colors.orange;
      case 'Advanced':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }
}
