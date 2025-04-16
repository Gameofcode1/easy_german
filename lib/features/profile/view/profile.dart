
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';
import '../../../config/tracker/app_usage_tracker.dart';
import '../../storiesScreen/model/stories_services.dart';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _floatAnimation;
  final StoryService _storyService = StoryService();
  final AppUsageTracker _appUsageTracker = AppUsageTracker();

  // Stats variables
  int _totalVocabularyLearned = 0;
  int _totalStoriesRead = 0;
  int _totalLearningTimeMinutes = 0;
  String _formattedLearningTime = "0 mins";
  int _learningStreakDays = 0;
  String _dailyAverageTime = "0 mins";

  // Learning stats will be updated once we load the data
  List<Map<String, dynamic>> _learningStats = [];

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

    // Load learning stats when screen initializes
    _loadLearningStats();
  }

  // Load all the learning stats from SharedPreferences
  Future<void> _loadLearningStats() async {
    // Get the current active session time from the tracker
    // This ensures we get the most up-to-date time data
    await _appUsageTracker.saveCurrentSession();

    // Now load all the stats
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Get stories read count
    _totalStoriesRead = await _storyService.getTotalStoriesRead();

    // Get vocabulary stats
    _totalVocabularyLearned = prefs.getInt('total_words_completed') ?? 0;

    // Get learning time data
    _totalLearningTimeMinutes = await _appUsageTracker.getTotalLearningTimeMinutes();
    _formattedLearningTime = _appUsageTracker.formatLearningTime(_totalLearningTimeMinutes);

    // Get streak data
    _learningStreakDays = prefs.getInt('learning_streak_days') ?? 0;

    // Calculate daily average (if we have data for more than 1 day)
    final int daysUsed = prefs.getInt('days_app_used') ?? 1;
    final int averageMinutesPerDay = daysUsed > 0 ? (_totalLearningTimeMinutes ~/ daysUsed) : 0;
    _dailyAverageTime = _appUsageTracker.formatLearningTime(averageMinutesPerDay);

    // Get vocabulary details
    int nounsLearned = prefs.getInt('vocab_nouns_learned') ?? (_totalVocabularyLearned ~/ 3);
    int verbsLearned = prefs.getInt('vocab_verbs_learned') ?? (_totalVocabularyLearned ~/ 3);
    int adjectivesLearned = prefs.getInt('vocab_adjectives_learned') ?? (_totalVocabularyLearned ~/ 3);

    // Get story level details
    int beginnerStoriesRead = prefs.getInt('beginner_stories_read') ?? (_totalStoriesRead ~/ 3);
    int intermediateStoriesRead = prefs.getInt('intermediate_stories_read') ?? (_totalStoriesRead ~/ 3);
    int advancedStoriesRead = prefs.getInt('advanced_stories_read') ?? (_totalStoriesRead ~/ 3);

    // Now update the _learningStats array with real data
    setState(() {
      _learningStats = [
        {
          'title': 'Vocabulary',
          'value': '$_totalVocabularyLearned words',
          'icon': Icons.language,
          'color': const Color(0xFF4CAF50),
          'details': [
            {'label': 'Nouns', 'value': '$nounsLearned'},
            {'label': 'Verbs', 'value': '$verbsLearned'},
            {'label': 'Adjectives', 'value': '$adjectivesLearned'},
          ]
        },
        {
          'title': 'Stories',
          'value': '$_totalStoriesRead stories',
          'icon': Icons.auto_stories,
          'color': const Color(0xFF2196F3),
          'details': [
            {'label': 'Beginner', 'value': '$beginnerStoriesRead'},
            {'label': 'Intermediate', 'value': '$intermediateStoriesRead'},
            {'label': 'Advanced', 'value': '$advancedStoriesRead'},
          ]
        }
      ];
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(),
          _buildSectionTitle('Learning Journey'),
          _buildLearningStatisticsSection(),
          _buildSectionTitle('About Us'),
          _buildAboutAppSection(),
          _buildSectionTitle('Connect'),
          _buildContactSection(),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  // App bar with user's learning summary
  Widget _buildAppBar() {
    return SliverAppBar(
      iconTheme:const IconThemeData(color: Colors.white),
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
            // Background gradient
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

            // Animated background circles
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

            // Profile Title
            Positioned(
              left: 20,
              bottom: 40,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'My Learning Profile',
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.insights,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'My Learning Curve and about the App',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
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
    );
  }

  // Enhanced section title with more polish
  Widget _buildSectionTitle(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 30, 20, 16),
        child: Row(
          children: [
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF3F51B5),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3F51B5).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    _getIconForTitle(title),
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
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
            // Add a subtle line to extend the section header
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 12.0),
                child: Container(
                  height: 1.5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF3F51B5).withOpacity(0.5),
                        const Color(0xFF3F51B5).withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Get icon for section title
  IconData _getIconForTitle(String title) {
    switch (title) {
      case 'Learning Journey':
        return Icons.trending_up;
      case 'About Us':
        return Icons.info_outline;
      case 'Connect':
        return Icons.connect_without_contact;
      default:
        return Icons.label_outline;
    }
  }

  // Learning statistics with improved responsiveness
// Enhanced Learning Statistics Section
  Widget _buildLearningStatisticsSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Learning Progress Overview Cards
            Row(
              children: [
                _buildStatCard(
                  'Total Words',
                  _totalVocabularyLearned.toString(),
                  Icons.library_books,
                  Colors.blue,
                ),
                const SizedBox(width: 16),
                _buildStatCard(
                  'Stories Read',
                  _totalStoriesRead.toString(),
                  Icons.auto_stories,
                  Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 16),


          ],
        ),
      ),
    );
  }

// Progress Row Widget
  Widget _buildProgressRow(
      String title,
      int value,
      IconData icon,
      Color color
      ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey[800],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                height: 6,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: FractionallySizedBox(
                  widthFactor: _calculateProgressFactor(value),
                  alignment: Alignment.centerLeft,
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '$value',
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

// Insight Row Widget
  Widget _buildInsightRow(
      String title,
      String value,
      IconData icon,
      Color color
      ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: Colors.grey[800],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

// Helper method to calculate progress factor
  double _calculateProgressFactor(int value) {
    // Adjust the scaling as needed
    return value > 100 ? 1.0 : value / 100.0;
  }

// Calculate progress rate

// Detailed Learning Breakdown Widget


// Learning Breakdown Row
  Widget _buildLearningBreakdownRow(
      String title,
      int value,
      IconData icon,
      Color color
      ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey[800],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                height: 6,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: FractionallySizedBox(
                  widthFactor: value / (value + 50), // Adjust scaling as needed
                  alignment: Alignment.centerLeft,
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '$value',
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

// Detailed Stat Row
  Widget _buildDetailStatRow(
      String title,
      int value,
      IconData icon,
      Color color
      ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: Colors.grey[800],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          '$value',
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

// Existing stat card method (keep the one from the current implementation)
  Widget _buildStatCard(
      String title,
      String value,
      IconData icon,
      Color color
      ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Improved learning stat card with staggered animation
  Widget _buildLearningStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required List<Map<String, String>> details,
    required int index,
  }) {
    return Hero(
      tag: 'stat_card_$index',
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.8), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              // Show detailed stats if needed
            },
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          icon,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  // About App Section with card animation
  Widget _buildAboutAppSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Card(
          elevation: 6,
          shadowColor: Colors.black26,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3F51B5).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.school,
                        color: Color(0xFF3F51B5),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'About Deutsch Lernen',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3F51B5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'We make German language learning engaging and fun through interactive stories, comprehensive grammar lessons, and personalized learning paths.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                // Adding features section
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildFeatureChip('Interactive Stories'),
                    _buildFeatureChip('Grammar Lessons'),
                    _buildFeatureChip('Vocabulary Builder'),
                    _buildFeatureChip('Audio Pronunciation'),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Version 1.2.0',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 14,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3F51B5).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.copyright,
                            size: 14,
                            color: Color(0xFF3F51B5),
                          ),
                          SizedBox(width: 4),
                          Text(
                            '2024 Language App',
                            style: TextStyle(
                              color: Color(0xFF3F51B5),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Feature chip widget
  Widget _buildFeatureChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF3F51B5).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF3F51B5).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF3F51B5),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // Improved contact section
  Widget _buildContactSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Card(
          color: Colors.white,
          elevation: 6,
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.connect_without_contact,
                      color: Color(0xFF3F51B5),
                      size: 24,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Get in Touch',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3F51B5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'We value your feedback and are always happy to help with any questions!',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                _buildContactButton(
                  icon: Icons.email,
                  label: 'Email Support',
                  description: 'support@deutschlernen.com',
                  onTap: () async {
                    final Uri emailLaunchUri = Uri(
                      scheme: 'mailto',
                      path: 'support@deutschlernen.com',
                      query: _encodeQueryParameters(<String, String>{
                        'subject': 'App Support Request',
                      }),
                    );
                    if (await canLaunchUrl(emailLaunchUri)) {
                      await launchUrl(emailLaunchUri);
                    }
                  },
                ),
                const SizedBox(height: 12),
                _buildContactButton(
                  icon: Icons.web,
                  label: 'Visit Website',
                  description: 'www.deutschlernen.com',
                  onTap: () async {
                    final Uri websiteUri = Uri.parse(
                        'https://www.deutschlernen.com');
                    if (await canLaunchUrl(websiteUri)) {
                      await launchUrl(websiteUri);
                    }
                  },
                ),
                const SizedBox(height: 12),
                _buildContactButton(
                  icon: Icons.feedback,
                  label: 'Send Feedback',
                  description: 'Help us improve',
                  onTap: () async {
                    final Uri feedbackUri = Uri.parse(
                        'https://www.deutschlernen.com/feedback');
                    if (await canLaunchUrl(feedbackUri)) {
                      await launchUrl(feedbackUri);
                    }
                  },
                ),
                const SizedBox(height: 16),
                // Social media links
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSocialButton(Icons.facebook, Colors.blue.shade700),
                    const SizedBox(width: 16),
                    _buildSocialButton(Icons.language, Colors.green.shade600),
                    const SizedBox(width: 16),
                    _buildSocialButton(
                        Icons.ondemand_video, Colors.red.shade600),
                    const SizedBox(width: 16),
                    _buildSocialButton(Icons.discord, Colors.indigo.shade400),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Social media button
  Widget _buildSocialButton(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Icon(
        icon,
        color: color,
        size: 22,
      ),
    );
  }

  // Enhanced contact button with more information
  Widget _buildContactButton({
    required IconData icon,
    required String label,
    required String description,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF3F51B5).withOpacity(0.075),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF3F51B5).withOpacity(0.1),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF3F51B5).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF3F51B5),
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFF3F51B5),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.black87.withOpacity(0.7),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Color(0xFF3F51B5),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to encode query parameters for email
  String? _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((MapEntry<String, String> e) =>
    '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

}