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

  const StoryDetailScreen(
      {super.key, required this.title,
        required this.storyItems,
        required this.level,
        required this.duration,
        required this.description,
        required this.questions});

  @override
  _StoryDetailScreenState createState() => _StoryDetailScreenState();
}

enum TtsState { playing, stopped, paused, continued }

class _StoryDetailScreenState extends State<StoryDetailScreen> {
  // TTS engine
  late FlutterTts _flutterTts;
  bool _isPlaying = false;
  bool _isPaused = false;
  double _speechRate = 0.5;

  // Auto-play setting
  bool _autoPlayOnLoad = true;

  // Enhanced TTS state tracking
  TtsState _ttsState = TtsState.stopped;
  bool get isPlaying => _ttsState == TtsState.playing;
  bool get isStopped => _ttsState == TtsState.stopped;
  bool get isPaused => _ttsState == TtsState.paused;

  // UI state
  bool _showTranslation = true;
  bool _isBookmarked = false;
  int _fontSize = 18;

  // Scroll controller
  final ScrollController _scrollController = ScrollController();

  // For tracking
  int _currentItemIndex = 0;
  Timer? _autoScrollTimer;

  @override
  void initState() {
    super.initState();
    _initTts();
    _loadPreferences();

    // Use a small delay to ensure TTS is initialized before playback
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_autoPlayOnLoad && mounted) {
        _speak();
      }
    });
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _fontSize = prefs.getInt('fontSize') ?? 18;
      _isBookmarked = prefs.getBool('bookmark_${widget.title}') ?? false;
      _showTranslation = prefs.getBool('showTranslation') ?? true;
      _autoPlayOnLoad = prefs.getBool('autoPlayOnLoad') ?? true;
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('fontSize', _fontSize);
    await prefs.setBool('bookmark_${widget.title}', _isBookmarked);
    await prefs.setBool('showTranslation', _showTranslation);
    await prefs.setBool('autoPlayOnLoad', _autoPlayOnLoad);
  }

  Future<void> _initTts() async {
    _flutterTts = FlutterTts();

    if (!kIsWeb && Platform.isIOS) {
      var voices = await _flutterTts.getVoices;
      print('Available voices: $voices');

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
    }

    // Configure TTS for German language
    await _flutterTts.setLanguage('de-DE');
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
      if (_currentItemIndex < widget.storyItems.length - 1) {
        setState(() {
          _currentItemIndex++;
        });

        // Always speak the next item when one completes
        // This ensures continuous playback regardless of state
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

  // Improved _speakCurrentItem with better error handling
  Future<void> _speakCurrentItem() async {
    if (_currentItemIndex >= 0 && _currentItemIndex < widget.storyItems.length) {
      try {
        // Always stop before speaking again for consistent behavior
        await _flutterTts.stop();

        // Get the text to speak
        final textToSpeak = widget.storyItems[_currentItemIndex].germanText;
        print("Speaking: $textToSpeak");

        // Ensure state is set before speaking
        setState(() {
          _ttsState = TtsState.playing;
          _isPlaying = true;
          _isPaused = false;
        });

        // Speak the text
        var result = await _flutterTts.speak(textToSpeak);
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
          content: Text('Speech failed. Try adjusting the speed or restarting.'),
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
        content: Text(_autoPlayOnLoad
            ? 'Auto-play on open enabled'
            : 'Auto-play on open disabled'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Enhanced dispose method to ensure proper cleanup
  @override
  void dispose() {
    _flutterTts.stop();
    _stopAutoScroll();
    _scrollController.dispose();
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

  Future<void> _setRate(double rate) async {
    await _flutterTts.setSpeechRate(rate);
    setState(() {
      _speechRate = rate;
    });
  }

  void _toggleBookmark() {
    setState(() {
      _isBookmarked = !_isBookmarked;
    });
    _savePreferences();
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
          IconButton(
            icon: Icon(
              _autoPlayOnLoad ? Icons.play_circle : Icons.play_circle_outline,
              color: Colors.white,
            ),
            onPressed: _toggleAutoPlayOnLoad,
            tooltip: "Toggle auto-play on open",
          ),
          IconButton(
            icon: Icon(
              _showTranslation ? Icons.translate : Icons.translate_outlined,
              color: Colors.white,
            ),
            onPressed: _toggleTranslation,
          ),
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
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF3F51B5), Color(0xFF5C6BC0)],
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
                                        // German text
                                        Text(
                                          widget.storyItems[index].germanText,
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
                                            widget.storyItems[index].englishText,
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
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.horizontal(right: Radius.circular(2)),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
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
                      IconButton(
                        icon: const Icon(Icons.text_decrease),
                        onPressed: () => _changeFontSize(-2),
                      ),
                      IconButton(
                        icon: const Icon(Icons.text_increase),
                        onPressed: () => _changeFontSize(2),
                      ),
                      IconButton(
                        icon: const Icon(Icons.speed),
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            builder: (context) => StatefulBuilder(
                              builder: (context, setModalState) {
                                return Container(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('Speech Speed',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      Slider(
                                        value: _speechRate,
                                        min: 0.25,
                                        max: 0.75,
                                        divisions: 4,
                                        onChanged: (value) {
                                          setModalState(() {
                                            _speechRate = value;
                                          });
                                          _setRate(value);
                                        },
                                      ),
                                      Text(
                                          '${(_speechRate * 2).toStringAsFixed(1)}x'),
                                    ],
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.translate),
                        onPressed: _toggleTranslation,
                      ),
                      IconButton(
                        icon: Icon(_isBookmarked
                            ? Icons.bookmark
                            : Icons.bookmark_border),
                        onPressed: _toggleBookmark,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
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
              )),
        ),
      ]),
    );
  }

  // Add this method to show the quiz in a bottom sheet
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
                              ? const Icon(Icons.check, color: Colors.white, size: 16)
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
