import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../../services/app_ratingservice.dart';
import '../../germanBasic/view/german_basic_screen.dart';
import 'stories_list.dart';

class StoriesCategoryScreen extends StatefulWidget {
  const StoriesCategoryScreen({super.key});

  @override
  State<StoriesCategoryScreen> createState() => _StoriesCategoryScreenState();
}

class _StoriesCategoryScreenState extends State<StoriesCategoryScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _floatAnimation;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();

    // Initialize the animation controller with a more conservative duration
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    // Create the animation
    _floatAnimation = Tween<double>(begin: 0, end: 6).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    // Add status listener for more controlled animation
    _animationController.addStatusListener((status) {
      if (_disposed) return; // Safety check

      if (status == AnimationStatus.completed) {
        _animationController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _animationController.forward();
      }
    });

    // Initial forward animation
    _animationController.forward();
  }

  @override
  void dispose() {
    // Set flag first
    _disposed = true;

    // Clean up the animation controller
    _animationController.stop();
    _animationController.removeStatusListener((_) {});
    _animationController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Remove SafeArea to allow the app bar to extend to the top of the screen
      body: Container(
        color: Colors.grey[50],
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildAppBar(),
            _buildNewToGermanSection(),
            _buildSectionTitle('Story Levels'),
            _buildLevelCategories(),
            _buildSectionTitle('Story Categories'),
            _buildStoryCategories(),
            // Create a debug button that forces rating to show

            const SliverToBoxAdapter(
              key: ValueKey('bottom_padding'),
              child: SizedBox(height: 80),
            ),
          ],
        ),
      ),
    );
  }

  // Methods with AnimatedBuilder updated to safely handle disposal
  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: const Color(0xFF3F51B5),
      // Extend to top of the screen
      stretch: true,
      // Remove top padding to fully cover status bar area
      toolbarHeight: 0,
      collapsedHeight: kToolbarHeight,
      // Make sure to cover status bar
      primary: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Background
            Container(
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF5C6BC0),
                    Color(0xFF3F51B5),
                  ],
                ),
              ),
            ),

            // Animated patterns - careful with this
            StatefulBuilder(
              builder: (context, setState) {
                if (_disposed) return Container(); // Safety check

                return AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    if (_disposed) return Container(); // Double safety

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
                      ],
                    );
                  },
                );
              },
            ),

            // Content
            Positioned(
              left: 20,
              bottom: 40,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'German Spark',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'Learn German through fun stories',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewToGermanSection() {
    return SliverList(
      delegate: SliverChildListDelegate([
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 30, 20, 16),
          key: const ValueKey('new_to_german_header'),
          child: Row(
            children: [
              Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                decoration: BoxDecoration(
                  color: const Color(0xFF3F51B5),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3F51B5).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.school,
                      color: Colors.white,
                      size: 16,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'New to German?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // The card itself - using stateful builder for safer animation
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          key: const ValueKey('basics_card_container'),
          child: _buildBasicsCard(),
        ),

        const SizedBox(height: 10),
      ]),
    );
  }

  Widget _buildBasicsCard() {
    return StatefulBuilder(
      builder: (context, setState) {
        if (_disposed) return Container(height: 140);

        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            if (_disposed) return Container(height: 140);

            return Transform.translate(
              offset: Offset(0, _floatAnimation.value / 2),
              child: Container(
                height: 140,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF3F51B5),
                      Color(0xFF9C27B0),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0xFF3F51B5),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      if (_disposed) return;

                      // Use microtask for safer navigation
                      SchedulerBinding.instance.addPostFrameCallback((_) {
                        // You could uncomment this when you have the screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const GermanBasicsScreen(),
                          ),
                        );
                      });
                    },
                    child: Stack(
                      children: [
                        // Background pattern
                        Positioned(
                          right: -20,
                          bottom: -20,
                          child: Icon(
                            Icons.school,
                            size: 100,
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),

                        // Content
                        Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Row(
                            children: [
                              // Left side content
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'German Basics',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Learn alphabets, numbers, colors, and more!',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white.withOpacity(0.9),
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),

                              // Vertical divider
                              Container(
                                height: 70,
                                width: 1,
                                color: Colors.white.withOpacity(0.3),
                                margin: const EdgeInsets.symmetric(horizontal: 15),
                              ),

                              // Right side - animated icon
                              Expanded(
                                flex: 1,
                                child: Container(
                                  height: 60,
                                  width: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return SliverToBoxAdapter(
      key: ValueKey('section_title_$title'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 30, 20, 16),
        child: Row(
          children: [
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              decoration: BoxDecoration(
                color: const Color(0xFF3F51B5),
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
                    title.contains('Level') ? Icons.equalizer :
                    title.contains('New to German') ? Icons.school :
                    Icons.explore,
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
          ],
        ),
      ),
    );
  }

  Widget _buildLevelCategories() {
    final levels = [
      {
        'title': 'Beginner',
        'subtitle': 'Simple stories with basic vocabulary',
        'color': const Color(0xFF4CAF50),
        'icon': Icons.emoji_events_outlined,
        'stories': 12,
      },
      {
        'title': 'Intermediate',
        'subtitle': 'More complex stories with advanced grammar',
        'color': const Color(0xFFFF9800),
        'icon': Icons.trending_up,
        'stories': 8,
      },
      {
        'title': 'Advanced',
        'subtitle': 'Challenging stories for fluent speakers',
        'color': const Color(0xFFF44336),
        'icon': Icons.psychology,
        'stories': 6,
      },
    ];

    return SliverToBoxAdapter(
      key: const ValueKey('level_categories'),
      child: SizedBox(
        height: 200,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: levels.length,
          itemBuilder: (context, index) {
            final level = levels[index];
            return _buildLevelCard(
              key: ValueKey('level_card_${level['title']}'),
              title: level['title'] as String,
              subtitle: level['subtitle'] as String,
              color: level['color'] as Color,
              icon: level['icon'] as IconData,
              stories: level['stories'] as int,
            );
          },
        ),
      ),
    );
  }

  Widget _buildLevelCard({
    Key? key,
    required String title,
    required String subtitle,
    required Color color,
    required IconData icon,
    required int stories,
  }) {
    return Container(
      key: key,
      width: 220,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.9),
            color,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            if (_disposed) return;

            // Use safer navigation with post-frame callback
            SchedulerBinding.instance.addPostFrameCallback((_) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StoriesListScreen(
                    title: '$title Stories',
                    level: title,
                  ),
                ),
              );
            });
          },
          child: Stack(
            children: [
              // Background pattern
              Positioned(
                right: -20,
                bottom: -20,
                child: Icon(
                  icon,
                  size: 100,
                  color: Colors.white.withOpacity(0.2),
                ),
              ),

              // Floating icon with safer animation
              Positioned(
                right: 16,
                top: 16,
                child: StatefulBuilder(
                  builder: (context, setState) {
                    if (_disposed) return Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        color: color,
                        size: 20,
                      ),
                    );

                    return AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        if (_disposed) return Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            icon,
                            color: color,
                            size: 20,
                          ),
                        );

                        return Transform.translate(
                          offset: Offset(0, _floatAnimation.value / 2),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              icon,
                              color: color,
                              size: 20,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40), // Space for the floating icon
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$stories stories',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white,
                            size: 12,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoryCategories() {
    final categories = [
      {
        'title': 'Everyday',
        'icon': Icons.home,
        'color': const Color(0xFF3F51B5),
        'image': 'assets/images/everyday.jpg',
      },
      {
        'title': 'Travel',
        'icon': Icons.flight,
        'color': const Color(0xFF4CAF50),
        'image': 'assets/images/travel.jpg',
      },
      {
        'title': 'Food',
        'icon': Icons.restaurant,
        'color': const Color(0xFFFF9800),
        'image': 'assets/images/food.jpg',
      },
      {
        'title': 'Culture',
        'icon': Icons.museum,
        'color': const Color(0xFF9C27B0),
        'image': 'assets/images/culture.jpg',
      },
      {
        'title': 'Work',
        'icon': Icons.business,
        'color': const Color(0xFF2196F3),
        'image': 'assets/images/work.jpg',
      },
      {
        'title': 'Fairy',
        'icon': Icons.auto_stories,
        'color': const Color(0xFFE91E63),
        'image': 'assets/images/fairy_tales.jpg',
      },
    ];

    return SliverPadding(
      key: const ValueKey('story_categories'),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.1,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        delegate: SliverChildBuilderDelegate(
              (context, index) {
            final category = categories[index];
            return _buildCategoryCard(
              key: ValueKey('category_card_${category['title']}'),
              title: category['title'] as String,
              icon: category['icon'] as IconData,
              color: category['color'] as Color,
              image: category['image'] as String,
            );
          },
          childCount: categories.length,
        ),
      ),
    );
  }

  Widget _buildCategoryCard({
    Key? key,
    required String title,
    required IconData icon,
    required Color color,
    required String image,
  }) {
    return Material(
      key: key,
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (_disposed) return;

          // Use safer navigation
          SchedulerBinding.instance.addPostFrameCallback((_) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StoriesListScreen(
                  title: '$title Stories',
                  category: title,
                ),
              ),
            );
          });
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Image background
                Image.asset(
                  image,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: color.withOpacity(0.2),
                      child: Center(
                        child: Icon(
                          icon,
                          color: color,
                          size: 40,
                        ),
                      ),
                    );
                  },
                ),

                // Gradient overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        color.withOpacity(0.8),
                      ],
                    ),
                  ),
                ),

                // Title at bottom
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        Icon(
                          icon,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
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