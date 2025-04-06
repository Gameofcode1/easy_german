import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class StoryItem {
  final String germanText;
  final String englishText;

  StoryItem({required this.germanText, required this.englishText});
}

class StoryDetailScreen extends StatefulWidget {
  final String title;
  final List<StoryItem> storyItems;
  final String level;
  final String duration;
  final String description;

  StoryDetailScreen({
    required this.title,
    required this.storyItems,
    required this.level,
    required this.duration,
    required this.description,
  });

  @override
  _StoryDetailScreenState createState() => _StoryDetailScreenState();
}

class _StoryDetailScreenState extends State<StoryDetailScreen> {
  // TTS engine
  late FlutterTts _flutterTts;
  bool _isPlaying = false;
  bool _isPaused = false;
  double _speechRate = 0.5;

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
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _fontSize = prefs.getInt('fontSize') ?? 18;
      _isBookmarked = prefs.getBool('bookmark_${widget.title}') ?? false;
      _showTranslation = prefs.getBool('showTranslation') ?? true;
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('fontSize', _fontSize);
    await prefs.setBool('bookmark_${widget.title}', _isBookmarked);
    await prefs.setBool('showTranslation', _showTranslation);
  }

  Future<void> _initTts() async {
    _flutterTts = FlutterTts();

    // Configure TTS for German language
    await _flutterTts.setLanguage('de-DE');
    await _flutterTts.setSpeechRate(_speechRate);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    // Set up TTS callbacks
    _flutterTts.setStartHandler(() {
      setState(() {
        _isPlaying = true;
        _isPaused = false;
      });
    });

    _flutterTts.setCompletionHandler(() {
      // Move to next item or finish
      if (_currentItemIndex < widget.storyItems.length - 1) {
        setState(() {
          _currentItemIndex++;
        });
        _speakCurrentItem();
      } else {
        setState(() {
          _isPlaying = false;
          _isPaused = false;
          _currentItemIndex = 0;
        });
        _stopAutoScroll();
      }
    });

    _flutterTts.setErrorHandler((msg) {
      setState(() {
        _isPlaying = false;
        _isPaused = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $msg')),
      );
      _stopAutoScroll();
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
    _autoScrollTimer = Timer.periodic(Duration(seconds: 1), (timer) {
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
        duration: Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _speakCurrentItem() async {
    if (_currentItemIndex >= 0 && _currentItemIndex < widget.storyItems.length) {
      // Only speak German text
      final textToSpeak = widget.storyItems[_currentItemIndex].germanText;
      await _flutterTts.speak(textToSpeak);

      // Scroll if needed
      _scrollToCurrentItemIfNeeded();
    }
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _scrollController.dispose();
    _stopAutoScroll();
    super.dispose();
  }

  Future<void> _speak() async {
    if (_isPlaying) {
      if (_isPaused) {
        // Resume - speak current item
        _speakCurrentItem();
        setState(() {
          _isPaused = false;
        });
        _startAutoScroll();
      } else {
        // Pause
        await _flutterTts.stop();
        setState(() {
          _isPaused = true;
        });
        _stopAutoScroll();
      }
    } else {
      // Start from beginning or from current
      _speakCurrentItem();
      _startAutoScroll();
    }
  }

  Future<void> _stop() async {
    await _flutterTts.stop();
    setState(() {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(

        title: Text(widget.title,style: TextStyle(color: Colors.white),),
        backgroundColor: Color(0xFF3F51B5),
        leading: IconButton(
          icon: Icon(Icons.arrow_back,color: Colors.white,),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [

          IconButton(
            icon: Icon(_showTranslation ? Icons.translate : Icons.translate_outlined,color: Colors.white,),
            onPressed: _toggleTranslation,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Story info card
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.description,
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 8),

                      ],
                    ),
                  ),

                  // Story content
                  ...List.generate(widget.storyItems.length, (index) {
                    return Card(
                      margin: EdgeInsets.only(bottom: 16),
                      color:   Color(0xFF3F51B5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: index == _currentItemIndex && _isPlaying
                            ? BorderSide(color: Colors.green, width: 2)
                            : BorderSide.none,
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16),
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
                              ),
                            ),

                            // English translation (if enabled)
                            if (_showTranslation) ...[
                              SizedBox(height: 8),
                              Text(
                                widget.storyItems[index].englishText,
                                style: TextStyle(
                                  fontSize: _fontSize.toDouble() - 2,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          // Playback controls
          Container(
            padding: EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
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
                // Progress bar
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(_isPlaying
                            ? (_isPaused ? Icons.play_arrow : Icons.pause)
                            : Icons.play_arrow,
                          size: 32,
                        ),
                        onPressed: _speak,
                      ),
                      Expanded(
                        child: SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 4,
                            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8),
                          ),
                          child: Slider(
                            value: _currentItemIndex.toDouble(),
                            min: 0,
                            max: (widget.storyItems.length - 1).toDouble(),
                            divisions: widget.storyItems.length - 1,
                            onChanged: (value) {
                              setState(() {
                                _currentItemIndex = value.round();
                              });
                              if (_isPlaying) {
                                _stop();
                                _speak();
                              } else {
                                _scrollToCurrentItemIfNeeded();
                              }
                            },
                          ),
                        ),
                      ),
                      Text(
                        '${_currentItemIndex + 1} / ${widget.storyItems.length}',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),

                // Bottom controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: Icon(Icons.text_decrease),
                      onPressed: () => _changeFontSize(-2),
                    ),
                    IconButton(
                      icon: Icon(Icons.text_increase),
                      onPressed: () => _changeFontSize(2),
                    ),
                    IconButton(
                      icon: Icon(Icons.speed),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (context) => StatefulBuilder(
                            builder: (context, setModalState) {
                              return Container(
                                padding: EdgeInsets.all(16),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('Speech Speed', style: TextStyle(fontWeight: FontWeight.bold)),
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
                                    Text('${(_speechRate * 2).toStringAsFixed(1)}x'),
                                  ],
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.translate),
                      onPressed: _toggleTranslation,
                    ),
                    IconButton(
                      icon: Icon(_isBookmarked ? Icons.bookmark : Icons.bookmark_border),
                      onPressed: _toggleBookmark,
                    ),
                  ],
                ),
              ],
            ),
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
