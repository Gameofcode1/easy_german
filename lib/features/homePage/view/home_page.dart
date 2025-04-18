import 'package:German_Spark/features/homePage/widget/rating_dialouge.dart';
import 'package:German_Spark/services/app_ratingservice.dart';
import 'package:flutter/material.dart';
import '../../poadcast/view/pordCast.dart';
import '../../profile/view/profile.dart';
import '../../storiesScreen/model/stories_model.dart';
import '../../storiesScreen/model/stories_services.dart';
import '../../storiesScreen/view/stories_player.dart';
import '../../storiesScreen/view/stories_screen.dart';
import '../../vocabscreen/view/vocab_screen.dart';
import '../../gamescreen/view/game_screen.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;
  final StoryService _storyService = StoryService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        EnhancedRatingDialog.show(context);
      }
    });
    _tabController.addListener(() {
      setState(() {
        _currentIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(), // Disable swipe to change tabs
        children:const [
             StoriesCategoryScreen(),
             PodcastCategoryScreen(),
             VocabularyCategoryScreen(),
             GameScreen(),
             ProfileScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        // Wrap the TabBar in a SizedBox to increase its height
        child: SizedBox(
          height: 55, // Increased height from default ~50 to 70
          child: TabBar(
            controller: _tabController,
            indicator: const BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Color(0xFF3F51B5),
                  width: 3.0,
                ),
              ),
            ),
            labelColor: const Color(0xFF3F51B5),
            unselectedLabelColor: Colors.grey,
            labelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            tabs: const [
              Tab(
                icon: Icon(Icons.auto_stories, size: 30),
                child: Padding(
                  padding: EdgeInsets.only(bottom: 2),
                ),
              ),
              Tab(
                icon: Icon(Icons.headset, size: 30),
                child: Padding(
                  padding: EdgeInsets.only(bottom: 2),
                ),
              ),
              Tab(
                icon: Icon(Icons.translate, size: 30),
                child: Padding(
                  padding: EdgeInsets.only(bottom: 2),
                ),
              ),
              Tab(
                icon: Icon(Icons.gamepad, size: 30),
                child: Padding(
                  padding: EdgeInsets.only(bottom: 2),
                ),
              ),
              Tab(
                icon: Icon(Icons.person, size: 30),
                child: Padding(
                  padding: EdgeInsets.only(bottom: 2),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _currentIndex == 0 || _currentIndex == 1 || _currentIndex == 2
          ? FloatingActionButton(
        backgroundColor: const Color(0xFF3F51B5),
        child: const Icon(Icons.favorite, color: Colors.white),
        onPressed: () {
          // Show wishlist dialog or navigate to wishlist page
          _showWishlistModal(context);
        },
      )
          : null,
    );
  }

  void _showWishlistModal(BuildContext context) async {
    // Get favorite stories from StoryService
    List<StoryModel> favoriteStories = await _storyService.getFavoriteStories();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85, // Taller for better content display
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              spreadRadius: 0,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Title with heart icon
                  Row(
                    children: [
                      const Icon(
                        Icons.favorite,
                        color: Colors.red,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Favorites',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),

                  // Total count badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3F51B5).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${favoriteStories.length} items',
                      style: const TextStyle(
                        color: Color(0xFF3F51B5),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Divider with gradient
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.grey.withOpacity(0.0),
                    Colors.grey.withOpacity(0.3),
                    Colors.grey.withOpacity(0.0),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),

            // Content - either favorites list or empty state
            Expanded(
              child: favoriteStories.isEmpty
                  ? _buildEmptyWishlist()
                  : _buildFavoritesList(favoriteStories),
            ),
          ],
        ),
      ),
    );
  }

// Widget for empty wishlist state
  Widget _buildEmptyWishlist() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.favorite_border,
              size: 80,
              color: Colors.red.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Your favorites list is empty',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Add stories to favorites by tapping the heart icon',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

// Widget for favorites list
  Widget _buildFavoritesList(List<StoryModel> favorites) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: favorites.length,
      itemBuilder: (context, index) {
        final story = favorites[index];

        // Create a unique but consistent color for each story based on its ID
        final int colorSeed = story.id.hashCode;
        final primaryColor = Color(0xFF000000 | (colorSeed & 0xFFFFFF)).withOpacity(1.0);

        // Generate a complementary gradient
        final gradientColors = [
          HSLColor.fromColor(primaryColor).withSaturation(0.8).withLightness(0.4).toColor(),
          HSLColor.fromColor(primaryColor).withSaturation(0.7).withLightness(0.6).toColor()
        ];

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Material(
            borderRadius: BorderRadius.circular(18),
            elevation: 0,
            color: Colors.white,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                // Close the modal
                Navigator.pop(context);

                // Navigate to the story detail screen
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
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left gradient column with thumbnail
                    Container(
                      width: 100,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: gradientColors,
                        ),
                      ),
                      child: Stack(
                        children: [
                          // Decorative shapes
                          Positioned(
                            top: -15,
                            right: -15,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: -10,
                            left: -10,
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),

                          // Center icon
                          Center(
                            child: Icon(
                              Icons.auto_stories,
                              color: Colors.white,
                              size: 36,
                            ),
                          ),

                          // Read badge
                          if (story.isRead)
                            Positioned(
                              top: 8,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.all(4),
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
                                child: const Icon(
                                  Icons.check,
                                  color: Color(0xFF4CAF50),
                                  size: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Story details
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              story.title,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: story.isRead
                                    ? const Color(0xFF3F51B5)
                                    : const Color(0xFF212121),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              story.description,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF757575),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 12),

                            // Level, duration and read status
                            Row(
                              children: [
                                // Level pill
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getLevelColor(story.level).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _getLevelColor(story.level).withOpacity(0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    story.level,
                                    style: TextStyle(
                                      color: _getLevelColor(story.level),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Icon(
                                  Icons.access_time,
                                  color: Color(0xFF757575),
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  story.duration,
                                  style: const TextStyle(
                                    color: Color(0xFF757575),
                                    fontSize: 12,
                                  ),
                                ),

                                // Add "Read" badge if the story has been read

                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Remove from favorites button - with improved styling
                    Padding(
                      padding: const EdgeInsets.only(top: 12, right: 8),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () async {
                            // Toggle favorite status
                            await _storyService.toggleFavorite(story.id);

                            // Close and reopen modal to refresh list
                            Navigator.pop(context);
                            _showWishlistModal(context);
                          },
                          child: Ink(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.red.withOpacity(0.1),
                            ),
                            child: const Icon(
                              Icons.favorite,
                              color: Colors.red,
                              size: 24,
                            ),
                          ),
                        ),
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
  }
  // Helper method to get color for level
  Color _getLevelColor(String level) {
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
}