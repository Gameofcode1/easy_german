import 'dart:math';

import 'package:flutter/material.dart';
import 'package:German_Spark/features/poadcast/view/pod_detail.dart';
import 'package:German_Spark/features/poadcast/view/podcast_list_screen.dart';
import 'dart:ui';
import '../model/podcast_model.dart';
import '../service/podcast_service.dart';

class PodcastCategoryScreen extends StatefulWidget {
  const PodcastCategoryScreen({super.key});

  @override
  _PodcastCategoryScreenState createState() => _PodcastCategoryScreenState();
}

class _PodcastCategoryScreenState extends State<PodcastCategoryScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    _floatAnimation = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _animationController.forward();
    _animationController.repeat(reverse: true);
  }

  final PodcastService _podcastService = PodcastService();

  Future<Podcast?> _getRandomBeginnerPodcast() async {
    try {
      // Load podcast data if not already loaded
      await _podcastService.loadPodcastData();

      // Get beginner level podcasts
      List<Podcast> beginnerPodcasts = _podcastService.getPodcastsByCategory('Beginner');

      // If no beginner podcasts, return null
      if (beginnerPodcasts.isEmpty) return null;

      // Use current timestamp as seed for consistent randomness
      final seed = DateTime.now().millisecondsSinceEpoch;
      final random = Random(seed);

      // Return a random beginner podcast
      return beginnerPodcasts[random.nextInt(beginnerPodcasts.length)];
    } catch (e) {
      print('Error fetching random beginner podcast: $e');
      return null;
    }
  }


  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.grey[50],
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildAppBar(),
            _buildFeaturedPodcast(),
            _buildSectionTitle('Podcast Levels'),
            _buildVerticalLevelCategories(),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to now playing screen
        },
        backgroundColor: const Color(0xFF3F51B5),
        elevation: 8,
        child: const Icon(Icons.headphones, color: Colors.white),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: const Color(0xFF3F51B5),
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
            // Background pattern
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

            // Animated background patterns
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
                    ],
                  );
                }
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
                    'AudioCast',
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
                      'Discover Amazing Podcasts',
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

  Widget _buildSectionTitle(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 30, 20, 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                    title.contains('Level') ? Icons.equalizer : Icons.headset,
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

  Widget _buildFeaturedPodcast() {
    return SliverToBoxAdapter(
      child: FutureBuilder<Podcast?>(
        future: _getRandomBeginnerPodcast(),
        builder: (context, snapshot) {
          // If no podcast found or still loading
          if (!snapshot.hasData) {
            return const SizedBox.shrink(); // Or a loading indicator
          }

          final podcast = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: GestureDetector(
              onTap: (){
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        PodcastDetailScreen(podcast: podcast),
                  ),
                );
              },
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        podcast.color.withOpacity(0.8),
                        podcast.color,
                      ],
                    ),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Featured tag
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.star,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'FEATURED BEGINNER PODCAST',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Podcast info
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  podcast.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 22,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  podcast.description,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 14,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),

                            // Bottom section with stats
                            // Bottom section with stats
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Creator and stats
                                Expanded(
                                  child: Row(
                                    children: [
                                      const Icon(Icons.person, color: Colors.white, size: 16),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          podcast.author,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Play button with some left margin
                                Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.play_arrow,
                                      color: podcast.color,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ],
                            )
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
      ),
    );
  }

  Widget _buildVerticalLevelCategories() {
    final levels = [
      {
        'title': 'Beginner',
        'subtitle': 'Easy listening for new language learners',
        'description': 'Perfect for those just starting out. Simple vocabulary and slower speech to help you build confidence.',
        'color': const Color(0xFF4CAF50),
        'icon': Icons.school,
        'podcasts': 15,
      },
      {
        'title': 'Intermediate',
        'subtitle': 'For those with some language experience',
        'description': 'Step up your skills with more complex topics and natural conversation speed. Expand your vocabulary and comprehension.',
        'color': const Color(0xFF2196F3),
        'icon': Icons.trending_up,
        'podcasts': 12,
      },
      {
        'title': 'Advanced',
        'subtitle': 'Complex topics for fluent speakers',
        'description': 'Challenging content for experienced listeners. Diverse topics with idiomatic expressions and specialized vocabulary.',
        'color': const Color(0xFF9C27B0),
        'icon': Icons.star,
        'podcasts': 8,
      },
      {
        'title': 'Native',
        'subtitle': 'Full-speed authentic podcasts',
        'description': 'Original content created for native speakers. Immerse yourself in the language as it is naturally spoken.',
        'color': const Color(0xFFFF9800),
        'icon': Icons.verified,
        'podcasts': 20,
      },
      {
        'title': 'Special Topics',
        'subtitle': 'Focused on specific vocabulary themes',
        'description': 'Content organized by themes like business, travel, culture, and more. Build specialized vocabulary for your interests.',
        'color': const Color(0xFFF44336),
        'icon': Icons.topic,
        'podcasts': 10,
      },
    ];

    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          final level = levels[index];
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: _buildVerticalLevelCard(
              title: level['title'] as String,
              subtitle: level['subtitle'] as String,
              description: level['description'] as String,
              color: level['color'] as Color,
              icon: level['icon'] as IconData,
              podcasts: level['podcasts'] as int,
            ),
          );
        },
        childCount: levels.length,
      ),
    );
  }

  Widget _buildVerticalLevelCard({
    required String title,
    required String subtitle,
    required String description,
    required Color color,
    required IconData icon,
    required int podcasts,
  }) {
    return Card(
      elevation: 6,
      shadowColor: color.withOpacity(0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        height: 130,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.9),
              color,
            ],
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PodcastListScreen(
                    title: '$title Level Podcasts',
                    level: title,
                  ),
                ),
              );
            },
            child: Stack(
              children: [
                // Background pattern
                Positioned(
                  right: -40,
                  bottom: -25,
                  child: Icon(
                    icon,
                    size: 120,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Left side - Icon
                      AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, _floatAnimation.value / 2),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withOpacity(0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(
                                icon,
                                color: color,
                                size: 26,
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(width: 16),

                      // Middle - Text content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withOpacity(0.9),
                              ),
                              maxLines: 2,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 10),

                      // Right side - Podcast count & arrow
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '$podcasts',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Icon(
                                  Icons.headset,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.arrow_forward,
                              color: color,
                              size: 14,
                            ),
                          ),
                        ],
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
  }
}