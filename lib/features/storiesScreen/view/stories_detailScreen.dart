import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:ui';

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

  // Factory method to create from story map with dummy translations
  static StoryDetailScreen fromStoryMap(Map<String, dynamic> story) {
    // Create some dummy story items
    List<StoryItem> storyItems = [
      StoryItem(
          germanText: "Anna und Tim lieben die Natur.",
          englishText: "Anna and Tim love nature."),
      StoryItem(
          germanText:
              "An einem sonnigen Samstagmorgen beschließen sie zu wandern.",
          englishText:
              "On a sunny Saturday morning, they decide to go hiking."),
      StoryItem(
          germanText: "Sie packen Wasserflaschen, Sandwiches und Rucksäcke.",
          englishText: "They pack water bottles, sandwiches, and backpacks."),
      StoryItem(
          germanText: "Dann gehen sie in den Wald.",
          englishText: "Then they head into the forest."),
      StoryItem(
          germanText: "Der Wald ist ruhig.",
          englishText: "The forest is quiet."),
      StoryItem(
          germanText: "Sie hören Vögel singen.",
          englishText: "They hear birds singing."),
      StoryItem(
          germanText: "Die frische Luft tut ihnen gut.",
          englishText: "The fresh air feels good to them."),
      StoryItem(
          germanText: "Sie machen viele Fotos von schönen Blumen.",
          englishText: "They take many photos of beautiful flowers."),
      StoryItem(
          germanText: "Nach zwei Stunden sind sie müde.",
          englishText: "After two hours, they are tired."),
      StoryItem(
          germanText:
              "Sie setzen sich auf eine Bank und essen ihre Sandwiches.",
          englishText: "They sit on a bench and eat their sandwiches."),
      StoryItem(
          germanText: "Sie trinken Wasser und entspannen sich.",
          englishText: "They drink water and relax."),
      StoryItem(
          germanText: "Am Nachmittag gehen sie nach Hause.",
          englishText: "In the afternoon, they go home."),
      StoryItem(
          germanText: "Es war ein schöner Tag in der Natur.",
          englishText: "It was a beautiful day in nature."),
    ];

    return StoryDetailScreen(
      title: story['title'],
      storyItems: storyItems,
      level: story['level'],
      duration: story['duration'],
      description: story['description'],
    );
  }
}

class _StoryDetailScreenState extends State<StoryDetailScreen>
    with SingleTickerProviderStateMixin {
  late FlutterTts _flutterTts;
  bool _isPlaying = false;
  bool _isPaused = false;
  int _currentItemIndex = 0;
  final ScrollController _scrollController = ScrollController();

  // For visual effects
  bool _showScrollTopButton = false;
  double _headerHeight = 0;

  // Animation controller
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();

    // Set up animations
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 2000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _floatAnimation = Tween<double>(begin: 0, end: 5).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    // Setup scroll controller listener
    _scrollController.addListener(() {
      setState(() {
        _showScrollTopButton = _scrollController.offset > 300;
        _headerHeight =
            _scrollController.offset > 50 ? 0 : 50 - _scrollController.offset;
      });
    });

    _initTts();
    _animationController.forward();
    _animationController.repeat(reverse: true);

    // Initial scroll to start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentItem();
    });
  }

  Future<void> _initTts() async {
    _flutterTts = FlutterTts();

    // Configure TTS for German language
    await _flutterTts.setLanguage('de-DE');
    await _flutterTts.setSpeechRate(0.5); // Slower rate for language learning
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
      // Move to the next item when current one completes
      if (_currentItemIndex < widget.storyItems.length - 1) {
        setState(() {
          _currentItemIndex++;
        });
        _scrollToCurrentItem();
        _speakCurrentItem();
      } else {
        setState(() {
          _isPlaying = false;
          _isPaused = false;
        });
        // Show completion dialog
        _showCompletionDialog();
      }
    });

    _flutterTts.setErrorHandler((msg) {
      setState(() {
        _isPlaying = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $msg'),
          backgroundColor: Colors.red,
        ),
      );
    });
  }

  void _scrollToCurrentItem() {
    if (!_scrollController.hasClients) return;

    // Create a map of global keys for each item
    // Note: Add this as a class field and initialize in initState:
    // final Map<int, GlobalKey> _itemKeys = {};
    // Then in build method for each item:
    // key: _itemKeys[index] ??= GlobalKey(),

    // Direct approach using item height estimate
    final itemHeight = 170.0; // Approximate height

    // Calculate position to put the current item in the center
    final screenHeight = MediaQuery.of(context).size.height;
    final targetPosition = (_currentItemIndex * itemHeight) - (screenHeight / 2) + (itemHeight / 2);

    // Simple clamping to avoid going beyond scroll limits
    final adjustedPosition = targetPosition.clamp(
        0.0,
        _scrollController.position.maxScrollExtent
    );

    // Scroll with a simple animation
    _scrollController.animateTo(
      adjustedPosition,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Future<void> _speakCurrentItem() async {
    if (_currentItemIndex < widget.storyItems.length) {
      await _flutterTts.speak(widget.storyItems[_currentItemIndex].germanText);
    }
  }

  Future<void> _togglePlayPause() async {
    if (_isPlaying) {
      // Pause/Stop
      await _flutterTts.stop();
      setState(() {
        _isPlaying = false;
      });
    } else {
      // Start playing
      _speakCurrentItem();
    }
  }

  void _goToPrevious() {
    if (_currentItemIndex > 0) {
      // Stop current playback
      if (_isPlaying) {
        _flutterTts.stop();
      }

      setState(() {
        _currentItemIndex--;
        _isPlaying = false;
      });

      _scrollToCurrentItem();
    }
  }

  void _goToNext() {
    if (_currentItemIndex < widget.storyItems.length - 1) {
      // Stop current playback
      if (_isPlaying) {
        _flutterTts.stop();
      }

      setState(() {
        _currentItemIndex++;
        _isPlaying = false;
      });

      _scrollToCurrentItem();
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: Duration(milliseconds: 800),
      curve: Curves.easeOutQuint,
    );
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.celebration, color: Color(0xFF3F51B5)),
              SizedBox(width: 10),
              Text('Congratulations!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'You have completed the story!',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: Color(0xFF3F51B5).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    Icons.emoji_events,
                    size: 60,
                    color: Color(0xFF3F51B5),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('CLOSE'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF3F51B5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _currentItemIndex = 0;
                });
                _scrollToCurrentItem();
              },
              child: Text('START AGAIN'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background pattern
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Color(0xFFF5F7FA),
                image: DecorationImage(
                  image: NetworkImage(
                      'https://www.transparenttextures.com/patterns/clean-gray-paper.png'),
                  repeat: ImageRepeat.repeat,
                  opacity: 0.3,
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // App bar with animated gradient
                AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Container(
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF2C3E50),
                              Color(0xFF3F51B5).withOpacity(
                                  0.9 + _floatAnimation.value / 100),
                            ],
                            stops: [0.3, 0.9],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(16),
                            bottomRight: Radius.circular(16),
                          ),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.arrow_back_ios_new,
                                  color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.title,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.translate, color: Colors.white),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Translation mode is active'),
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: Color(0xFF3F51B5),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.favorite_border,
                                  color: Colors.white),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Added to favorites'),
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: Color(0xFF3F51B5),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    }),

                // Story header with animation (collapsing on scroll)
                AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  height: _headerHeight,
                  curve: Curves.easeOut,
                  child: SingleChildScrollView(
                    physics: NeverScrollableScrollPhysics(),
                    child: Container(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Color(0xFF3F51B5).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.menu_book,
                              color: Color(0xFF3F51B5),
                              size: 24,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'German Story Reader',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF3F51B5),
                                  ),
                                ),
                                Text(
                                  'Learn German with interactive stories',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 8),
                          _buildLevelBadge(widget.level),
                        ],
                      ),
                    ),
                  ),
                ),

                // Story progress
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      RichText(
                        text: TextSpan(children: [
                          TextSpan(
                            text: 'Progress ',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                          TextSpan(
                            text:
                                '${((_currentItemIndex + 1) / widget.storyItems.length * 100).toInt()}%',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3F51B5),
                            ),
                          ),
                        ]),
                      ),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Color(0xFF3F51B5),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF3F51B5).withOpacity(0.3),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          '${_currentItemIndex + 1}/${widget.storyItems.length}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Linear progress indicator with animation
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: SizedBox(
                    height: 8,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Stack(
                        children: [
                          // Background
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 2,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                          // Foreground progress
                          AnimatedBuilder(
                              animation: _animationController,
                              builder: (context, child) {
                                return FractionallySizedBox(
                                  widthFactor: (_currentItemIndex + 1) /
                                      widget.storyItems.length,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                        colors: [
                                          Color(0xFF3F51B5),
                                          Color(0xFF5C6BC0),
                                          Color(0xFF3F51B5),
                                        ],
                                        stops: [
                                          0.0,
                                          0.5 + _floatAnimation.value / 100,
                                          1.0
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }),
                          // Shimmer effect
                          if (_isPlaying)
                            AnimatedBuilder(
                                animation: _animationController,
                                builder: (context, child) {
                                  return Positioned(
                                    left: MediaQuery.of(context).size.width *
                                        (_currentItemIndex /
                                            widget.storyItems.length),
                                    child: Container(
                                      width: 40,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                          colors: [
                                            Colors.white.withOpacity(0.0),
                                            Colors.white.withOpacity(0.5),
                                            Colors.white.withOpacity(0.0),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                        ],
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 8),

                // Story content - scrollable list with enhanced cards
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.fromLTRB(
                          16, 8, 16, 100), // Extra bottom padding
                      itemCount: widget.storyItems.length,
                      itemBuilder: (context, index) {
                        final item = widget.storyItems[index];
                        final isCurrentItem = index == _currentItemIndex;
                        final isBeforeCurrent = index < _currentItemIndex;
                        final isAfterCurrent = index > _currentItemIndex;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _currentItemIndex = index;
                            });
                            if (_isPlaying) {
                              _flutterTts.stop();
                              setState(() {
                                _isPlaying = false;
                              });
                            }
                            _scrollToCurrentItem();
                          },
                          child: AnimatedBuilder(
                              animation: _animationController,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: isCurrentItem
                                      ? Offset(0, _floatAnimation.value / 2)
                                      : Offset.zero,
                                  child: AnimatedContainer(
                                    duration: Duration(milliseconds: 400),
                                    curve: Curves.easeOutQuad,
                                    margin: EdgeInsets.only(
                                      bottom: 12,
                                      top: isCurrentItem ? 8 : 0,
                                      left: isCurrentItem
                                          ? 0
                                          : (isBeforeCurrent ? 8 : 16),
                                      right: isCurrentItem
                                          ? 0
                                          : (isAfterCurrent ? 8 : 16),
                                    ),
                                    decoration: BoxDecoration(
                                      color: isCurrentItem
                                          ? Color(0xFF2C3E50)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: isCurrentItem
                                              ? Color(0xFF3F51B5)
                                                  .withOpacity(0.4)
                                              : Colors.black.withOpacity(0.05),
                                          blurRadius: isCurrentItem ? 12 : 4,
                                          offset: Offset(0, 4),
                                          spreadRadius: isCurrentItem ? 1 : 0,
                                        ),
                                      ],
                                      border: isCurrentItem
                                          ? Border.all(
                                              color: Color(0xFF3F51B5),
                                              width: 2)
                                          : null,
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(18),
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(
                                          sigmaX: isCurrentItem ? 0 : 0,
                                          sigmaY: isCurrentItem ? 0 : 0,
                                        ),
                                        child: Padding(
                                          padding: EdgeInsets.all(16),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // Index indicator for completed items
                                              if (isBeforeCurrent)
                                                Align(
                                                  alignment: Alignment.topRight,
                                                  child: Container(
                                                    width: 24,
                                                    height: 24,
                                                    decoration: BoxDecoration(
                                                      color: Colors.green
                                                          .withOpacity(0.2),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: Center(
                                                      child: Icon(
                                                        Icons.check,
                                                        color: Colors.green,
                                                        size: 14,
                                                      ),
                                                    ),
                                                  ),
                                                ),

                                              // German text with play icon for current item
                                              Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      item.germanText,
                                                      style: TextStyle(
                                                        fontSize: 19,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: isCurrentItem
                                                            ? Colors.white
                                                            : Color(0xFF2C3E50),
                                                        height: 1.4,
                                                      ),
                                                    ),
                                                  ),
                                                  if (isCurrentItem)
                                                    Container(
                                                      margin: EdgeInsets.only(
                                                          left: 8),
                                                      width: 32,
                                                      height: 32,
                                                      decoration: BoxDecoration(
                                                        color: _isPlaying
                                                            ? Colors.red
                                                                .withOpacity(
                                                                    0.8)
                                                            : Color(0xFF3F51B5),
                                                        shape: BoxShape.circle,
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Color(
                                                                    0xFF3F51B5)
                                                                .withOpacity(
                                                                    0.3),
                                                            blurRadius: 8,
                                                            offset:
                                                                Offset(0, 2),
                                                          ),
                                                        ],
                                                      ),
                                                      child: Icon(
                                                        _isPlaying
                                                            ? Icons.volume_up
                                                            : Icons.play_arrow,
                                                        color: Colors.white,
                                                        size: 18,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              SizedBox(height: 12),

                                              // Divider between texts
                                              Container(
                                                height: 1,
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    begin: Alignment.centerLeft,
                                                    end: Alignment.centerRight,
                                                    colors: isCurrentItem
                                                        ? [
                                                            Colors.white
                                                                .withOpacity(
                                                                    0.1),
                                                            Colors.white
                                                                .withOpacity(
                                                                    0.3),
                                                            Colors.white
                                                                .withOpacity(
                                                                    0.1),
                                                          ]
                                                        : [
                                                            Colors.grey
                                                                .withOpacity(
                                                                    0.1),
                                                            Colors.grey
                                                                .withOpacity(
                                                                    0.2),
                                                            Colors.grey
                                                                .withOpacity(
                                                                    0.1),
                                                          ],
                                                  ),
                                                ),
                                                margin: EdgeInsets.symmetric(
                                                    vertical: 8),
                                              ),

                                              // English translation
                                              Text(
                                                item.englishText,
                                                style: TextStyle(
                                                  fontSize: 17,
                                                  fontStyle: FontStyle.italic,
                                                  color: isCurrentItem
                                                      ? Colors.white
                                                          .withOpacity(0.85)
                                                      : Colors.grey[600],
                                                  height: 1.4,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Scroll to top button
          if (_showScrollTopButton)
            Positioned(
              bottom: 140,
              right: 16,
              child: AnimatedOpacity(
                opacity: _showScrollTopButton ? 1.0 : 0.0,
                duration: Duration(milliseconds: 300),
                child: FloatingActionButton.small(
                  backgroundColor: Colors.white,
                  onPressed: _scrollToTop,
                  child: Icon(
                    Icons.arrow_upward,
                    color: Color(0xFF3F51B5),
                  ),
                  elevation: 4,
                ),
              ),
            ),
        ],
      ),

      // Floating play button with pulse animation
      // Floating play button with pulse animation
      floatingActionButton: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (_isPlaying ? Colors.red : Color(0xFF3F51B5))
                      .withOpacity(0.3 + _floatAnimation.value / 100),
                  blurRadius: 12 + _floatAnimation.value,
                  spreadRadius: 2 + _floatAnimation.value / 5,
                ),
              ],
            ),
            child: FloatingActionButton(
              backgroundColor: _isPlaying ? Colors.red : Color(0xFF3F51B5),
              onPressed: _togglePlayPause,
              child: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                size: 32,
              ),
              elevation: 6,
            ),
          );
        },
      ),

      // Bottom navigation bar with previous and next buttons
      bottomNavigationBar: Container(
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, -2),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Previous button
            GestureDetector(
              onTap: _currentItemIndex > 0 ? _goToPrevious : null,
              child: AnimatedContainer(
                duration: Duration(milliseconds: 300),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: _currentItemIndex > 0
                      ? Color(0xFFEFF3FF)
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: _currentItemIndex > 0
                        ? Color(0xFF3F51B5).withOpacity(0.3)
                        : Colors.grey[300]!,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_back_ios,
                      size: 16,
                      color: _currentItemIndex > 0
                          ? Color(0xFF3F51B5)
                          : Colors.grey[400],
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Previous',
                      style: TextStyle(
                        color: _currentItemIndex > 0
                            ? Color(0xFF3F51B5)
                            : Colors.grey[400],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Space for FAB
            SizedBox(width: 20),

            // Next button
            GestureDetector(
              onTap: _currentItemIndex < widget.storyItems.length - 1
                  ? _goToNext
                  : null,
              child: AnimatedContainer(
                duration: Duration(milliseconds: 300),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: _currentItemIndex < widget.storyItems.length - 1
                      ? Color(0xFFEFF3FF)
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: _currentItemIndex < widget.storyItems.length - 1
                        ? Color(0xFF3F51B5).withOpacity(0.3)
                        : Colors.grey[300]!,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Next',
                      style: TextStyle(
                        color: _currentItemIndex < widget.storyItems.length - 1
                            ? Color(0xFF3F51B5)
                            : Colors.grey[400],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: _currentItemIndex < widget.storyItems.length - 1
                          ? Color(0xFF3F51B5)
                          : Colors.grey[400],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  // Level badge with appropriate color
  Widget _buildLevelBadge(String level) {
    Color color;
    IconData icon;

    switch (level.toLowerCase()) {
      case 'beginner':
        color = Colors.green;
        icon = Icons.school;
        break;
      case 'intermediate':
        color = Colors.orange;
        icon = Icons.trending_up;
        break;
      case 'advanced':
        color = Colors.red;
        icon = Icons.workspace_premium;
        break;
      default:
        color = Colors.blue;
        icon = Icons.book;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color,
          ),
          SizedBox(width: 4),
          Text(
            level,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
