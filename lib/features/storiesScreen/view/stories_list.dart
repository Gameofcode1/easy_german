import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:German_Spark/features/storiesScreen/view/stories_player.dart';
import 'dart:ui';
import 'dart:math';
import '../../profile/view/profile.dart';
import '../model/stories_model.dart';
import '../model/stories_services.dart';

class StoriesListScreen extends StatefulWidget {
  final String title;
  final String? level;
  final String? category;

  const StoriesListScreen({super.key, 
    required this.title,
    this.level,
    this.category,
  });

  @override
  _StoriesListScreenState createState() => _StoriesListScreenState();
}

class _StoriesListScreenState extends State<StoriesListScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  late List<StoryModel> _stories;
  final StoryService _storyService = StoryService();
  int _totalStoriesRead = 0; // Track total stories read


  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _floatAnimation;

  // Scroll controller to detect scroll for app bar effects
  final ScrollController _scrollController = ScrollController();
  double _appBarOpacity = 0.0;

  // Random for generating consistent gradients
  final Random _random = Random(42); // Fixed seed for consistency

  // List of gradient color pairs
  final List<List<Color>> _gradients = [
    [const Color(0xFF6A11CB), const Color(0xFF2575FC)], // Purple to Blue
    [const Color(0xFF00B09B), const Color(0xFF96C93D)], // Teal to Green
    [const Color(0xFFF83600), const Color(0xFFF9D423)], // Red to Yellow
    [const Color(0xFFA8C0FF), const Color(0xFF3F2B96)], // Light Blue to Deep Purple
    [const Color(0xFFFF5F6D), const Color(0xFFFFC371)], // Red to Light Orange
    [const Color(0xFF4E65FF), const Color(0xFF92EFFD)], // Blue to Cyan
    [const Color(0xFFFF9A9E), const Color(0xFFFAD0C4)], // Pink to Light Pink
    [const Color(0xFF764BA2), const Color(0xFF667EEA)], // Purple to Blue
    [const Color(0xFFCB356B), const Color(0xFFBD3F32)], // Pink to Red
    [const Color(0xFF06BEB6), const Color(0xFF48B1BF)], // Teal to Blue
  ];

  // Icons for different categories
  final Map<String, IconData> _categoryIcons = {
    'Travel': Icons.flight,
    'Food': Icons.restaurant,
    'Culture': Icons.theater_comedy,
    'Work': Icons.work,
    'Fairy Tales': Icons.auto_stories,
    'Everyday Life': Icons.home,
    'Beginner': Icons.emoji_events_outlined,
    'Intermediate': Icons.trending_up,
    'Advanced': Icons.psychology,
  };

  @override
  void initState() {
    super.initState();
    _loadStoriesAndStats();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000), // Match the animation duration
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    // Add floating animation like in StoriesCategoryScreen
    _floatAnimation = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    // Add scroll listener for app bar effects
    _scrollController.addListener(() {
      setState(() {
        // Change opacity based on scroll position
        _appBarOpacity = (_scrollController.offset / 100).clamp(0.0, 1.0);
      });
    });

    _loadStories();

    // Match the animation behavior from StoriesCategoryScreen
    _animationController.forward();
    _animationController.repeat(reverse: true);
  }


  // Update this method to load stories and stats
  Future<void> _loadStoriesAndStats() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate loading delay
    await Future.delayed(const Duration(milliseconds: 800));

    try {
      // Load total read count
      _totalStoriesRead = await _storyService.getTotalStoriesRead();

      // Load stories using the service
      final stories = await _storyService.getStories(
          level: widget.level,
          category: widget.category
      );

      // Load read status and favorites for each story
      for (var story in stories) {
        story.isRead = await _storyService.isStoryRead(story.id);
        story.favorite = await _storyService.isStoryFavorite(story.id);
      }

      setState(() {
        _stories = stories;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading stories: $e');
      setState(() {
        _isLoading = false;
        _stories = [];
      });
    }
  }

  // Update the toggle favorite method to use SharedPreferences
  void _toggleFavorite(int index) async {
    // Toggle in SharedPreferences and get new status
    bool newStatus = await _storyService.toggleFavorite(_stories[index].id);

    setState(() {
      _stories[index].favorite = newStatus;
    });

    // Add a haptic feedback
    HapticFeedback.lightImpact();

    // Show a snackbar for feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _stories[index].favorite
              ? 'Added to favorites'
              : 'Removed from favorites',
          style: const TextStyle(color: Colors.white),
        ),
        duration: const Duration(seconds: 1),
        backgroundColor: const Color(0xFF424242),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // Add this method to navigate to story detail and mark as read
  void _navigateToStoryDetail(StoryModel story) async {
    // Navigate to story detail screen
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return StoryDetailScreen(
            title: story.title,
            storyItems: story.storyItems,
            level: story.level,
            duration: story.duration,
            description: story.description,
            questions: story.questions,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );

    // Mark story as read if not already read
    if (!story.isRead) {
      await _storyService.markStoryAsRead(story.id);
      setState(() {
        story.isRead = true;
        _totalStoriesRead = _totalStoriesRead + 1;
      });
    }
  }


  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadStories() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate loading delay
    await Future.delayed(const Duration(milliseconds: 800));

    try {
      // Load stories using the service
      final stories = await _storyService.getStories(
          level: widget.level,
          category: widget.category
      );

      setState(() {
        _stories = stories;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading stories: $e');
      setState(() {
        _isLoading = false;
        _stories = [];
      });
    }
  }

  Color _getLevelColor(String level) {
    // Using the same colors as in StoriesCategoryScreen
    switch (level) {
      case 'Beginner':
        return const Color(0xFF4CAF50); // Green for beginner level
      case 'Intermediate':
        return const Color(0xFFFF9800); // Orange for intermediate level
      case 'Advanced':
        return const Color(0xFFF44336); // Red for advanced level
      default:
        return const Color(0xFF2196F3); // Blue as fallback color
    }
  }

  // Get a consistent gradient for a story
  List<Color> _getGradientForStory(int index) {
    return _gradients[index % _gradients.length];
  }

  // Get icon for story based on category or level
  IconData _getIconForStory(StoryModel story) {
    if (_categoryIcons.containsKey(story.level)) {
      return _categoryIcons[story.level]!;
    } else if (_categoryIcons.containsKey(widget.category)) {
      return _categoryIcons[widget.category]!;
    } else {
      // Default icon
      final iconsList = [
        Icons.menu_book, Icons.translate, Icons.language,
        Icons.record_voice_over, Icons.forum, Icons.chat
      ];
      return iconsList[story.title.length % iconsList.length];
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),

      body: _isLoading
          ? _buildLoadingState()
          : Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(),
              _buildSectionTitle('Continue Learning'),
              if (_stories.isNotEmpty) _buildFeaturedStory(_stories[0]),
              _buildSectionTitle('All Stories'),
              _buildStoryList(),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Custom loading animation
          SizedBox(
            width: 60,
            height: 60,
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3F51B5)), // Indigo color
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Loading Stories...',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF757575),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: _appBarOpacity > 0.5
          ? const Color(0xFF3F51B5) // Indigo color
          : Colors.transparent,
      elevation: _appBarOpacity > 0.5 ? 4 : 0,
      iconTheme: const IconThemeData(color: Colors.white),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      stretch: true,
      flexibleSpace: ClipRRect(
        // Use ClipRRect to ensure the content respects the rounded corners
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        child: FlexibleSpaceBar(
          titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
          title: AnimatedOpacity(
            opacity: _appBarOpacity < 0.5 ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Text(
              widget.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 24,
                shadows: [
                  Shadow(
                    offset: const Offset(0, 1),
                    blurRadius: 3,
                    color: Colors.black.withOpacity(0.3),
                  ),
                ],
              ),
            ),
          ),
          background: Container(
            // Ensure this container fills entire space
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF5C6BC0),
                  Color(0xFF3F51B5),
                ],
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Animated decorative shapes
                AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Stack(
                        children: [
                          Positioned(
                            right: -30,
                            top: -30 + _floatAnimation.value,
                            child: Container(
                              width: 180,
                              height: 180,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          Positioned(
                            left: -20,
                            bottom: -20 + _floatAnimation.value,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          // Tiny circles for a starry effect

                        ],
                      );
                    }
                ),
                // Darkening overlay for text readability
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.3),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        // Profile icon
        InkWell(
       onTap: (){
         Navigator.push(context, MaterialPageRoute(builder: (context)=>ProfileScreen()));
       },
          child: Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: CircleAvatar(
              backgroundColor: Colors.white.withOpacity(0.2),
              radius: 18,
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 30, 20, 16),
        child: Row(
          children: [
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF3F51B5), // Indigo color
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3F51B5).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    title.contains('All') ? Icons.explore : Icons.play_circle_outline,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // If it's the "All Stories" section, add a filter button
            if (title == 'All Stories')
              const Spacer(),

          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedStory(StoryModel story) {
    final gradientColors = _gradients[0]; // Use first gradient for featured
    final storyIcon = _getIconForStory(story);

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: GestureDetector(
          onTap: () {
            // Navigate to story detail screen
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) {
                  return StoryDetailScreen(
                    title: story.title,
                    storyItems: story.storyItems,
                    level: story.level,
                    duration: story.duration,
                    description: story.description,
                    questions: story.questions,
                  );
                },
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
                transitionDuration: const Duration(milliseconds: 300),
              ),
            );
          },
          child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _floatAnimation.value / 3), // Subtle floating effect
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: gradientColors,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: gradientColors[0].withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Decorative elements
                          Positioned(
                            top: -20,
                            right: -20,
                            child: Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: -30,
                            left: -30,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          // Decorative icon
                          Positioned(
                            right: 30,
                            top: 30,
                            child: Icon(
                              storyIcon,
                              size: 60,
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          // Content
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'FEATURED',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  story.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _getLevelColor(story.level),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        story.level,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Icon(
                                      Icons.access_time,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      story.duration,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.2),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.play_arrow,
                                        color: Color(0xFF3F51B5),
                                        size: 24,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (story.isRead)
                            Positioned(
                              top: 20,
                              left: 20,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4CAF50),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'READ',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          // Content
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'FEATURED',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ),
                                // Rest of existing content...
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
          ),
        ),
      ),
    );
  }

  Widget _buildStoryList() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          // Skip the first item as it's used as featured
          if (index == 0) return const SizedBox.shrink();
          if (index >= _stories.length) return const SizedBox.shrink();

          final story = _stories[index];
          return _buildStoryCard(story, index);
        },
        childCount: _stories.length,
      ),
    );
  }

  // Update the story card to show read status
  Widget _buildStoryCard(StoryModel story, int index) {
    final gradientColors = _getGradientForStory(index);
    final storyIcon = _getIconForStory(story);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Card(
        color: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _navigateToStoryDetail(story),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gradient thumbnail with icon
                Stack(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: gradientColors,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: gradientColors[0].withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Decorative circle
                          Positioned(
                            top: -15,
                            right: -15,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          // Center icon
                          Center(
                            child: Icon(
                              storyIcon,
                              color: Colors.white,
                              size: 36,
                            ),
                          ),
                          // Play button
                          Positioned(
                            right: 4,
                            bottom: 4,
                            child: Container(
                              width: 26,
                              height: 26,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.play_arrow,
                                color: gradientColors[1],
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Add read badge if the story has been read
                    if (story.isRead)
                      Positioned(
                        top: 0,
                        left: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFF4CAF50),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                // Story details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        story.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: story.isRead
                              ? const Color(0xFF3F51B5) // Highlight if read
                              : const Color(0xFF212121),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        story.description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF757575),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          // Level pill
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getLevelColor(story.level).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              story.level,
                              style: TextStyle(
                                color: _getLevelColor(story.level),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.access_time,
                            color: Color(0xFF757575),
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            story.duration,
                            style: const TextStyle(
                              color: Color(0xFF757575),
                              fontSize: 12,
                            ),
                          ),

                          const SizedBox(width: 10,),
                          // Add "Read" badge if the story has been read
                          if (story.isRead) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4CAF50).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: Color(0xFF4CAF50),
                                    size: 10,
                                  ),

                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Favorite button with animation
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => _toggleFavorite(index),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: story.favorite
                              ? 1.0 + (_floatAnimation.value / 100)
                              : 1.0,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                            child: Icon(
                              story.favorite ? Icons.favorite : Icons.favorite_border,
                              color: story.favorite ? Colors.red : const Color(0xFFBDBDBD),
                              size: 22,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


}