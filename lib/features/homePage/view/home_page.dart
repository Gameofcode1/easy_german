import 'package:flutter/material.dart';
import '../../exceriseSections/view/excerice_sections.dart';
import '../../poadcast/view/pordCast.dart';
import '../../profile/view/profile.dart';
import '../../storiesScreen/view/stories_screen.dart';
import '../../vocabscreen/view/vocab_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
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
        children: [
          StoriesCategoryScreen(),
          PodcastCategoryScreen(),
          const VocabularyCategoryScreen(),
          const ExerciseScreen(),
          const ProfileScreen(),
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
                icon: Icon(Icons.play_lesson, size: 30),
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

  void _showWishlistModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Wishlist',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.favorite_border,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Your wishlist is empty',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}