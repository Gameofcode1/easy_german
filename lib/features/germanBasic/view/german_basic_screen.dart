import 'package:German_Spark/features/germanBasic/viewmodel/german_basic.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'german_categories.dart';

class GermanBasicsScreen extends StatefulWidget {
  const GermanBasicsScreen({Key? key}) : super(key: key);

  @override
  State<GermanBasicsScreen> createState() => _GermanBasicsScreenState();
}

class _GermanBasicsScreenState extends State<GermanBasicsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _floatAnimation;
  bool _disposed = false;


  // Add scroll controller and app bar opacity
  late ScrollController _scrollController;
  double _appBarOpacity = 0.0;


  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController()
      ..addListener(() {
        setState(() {
          // Start showing app bar background after scrolling 20 pixels
          // and be fully opaque at 120 pixels
          _appBarOpacity = (_scrollController.offset - 20) / 100;
          _appBarOpacity = _appBarOpacity.clamp(0.0, 1.0);
        });
      });

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    // Create floating animation
    _floatAnimation = Tween<double>(begin: 0, end: 6).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    // Add status listener for controlled animation
    _animationController.addStatusListener((status) {
      if (_disposed) return; // Safety check

      if (status == AnimationStatus.completed) {
        _animationController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _animationController.forward();
      }
    });

    // Initialize scroll controller for app bar opacity
    _scrollController = ScrollController()
      ..addListener(() {
        if (_disposed) return;

        // Calculate opacity based on scroll position
        setState(() {
          // Start showing app bar background after scrolling 20 pixels
          // and be fully opaque at 120 pixels
          _appBarOpacity = (_scrollController.offset - 20) / 100;
          _appBarOpacity = _appBarOpacity.clamp(0.0, 1.0);
        });
      });

    // Start the animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _disposed = true;
    _animationController.stop();
    _animationController.removeStatusListener((_) {});
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GermanBasicsModel(),
      child: Scaffold(
        body: Consumer<GermanBasicsModel>(
          builder: (context, model, child) {
            if (model.isLoading) {
              return _buildLoadingView();
            }

            // Show error message if there was an error loading data
            if (model.hasError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(model.errorMessage,style: TextStyle(color: Colors.white),),
                  backgroundColor: const Color(0xFF3F51B5),
                  duration: const Duration(seconds: 3),
                  action: SnackBarAction(
                    label: 'Dismiss',
                    onPressed: () {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    },
                  ),
                ),
              );
            }

            return Container(
              color: Colors.grey[50],
              child: CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _buildAppBar(context, model),
                  _buildIntroSection(model),
                  _buildSectionTitle('Essential Categories'),
                  _buildBasicCategories(context, model),

                  const SliverToBoxAdapter(
                    key: ValueKey('bottom_padding'),
                    child: SizedBox(height: 80),
                  ),
                ],
              ),
            );
          },
        ),
        // Floating action button to stop speech if speaking
        floatingActionButton: Consumer<GermanBasicsModel>(
          builder: (context, model, child) {
            if (model.isSpeaking) {
              return FloatingActionButton(
                onPressed: () => model.stopSpeaking(),
                backgroundColor: Colors.red,
                child: const Icon(Icons.stop),
                mini: true,
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Loading German basics...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildAppBar(BuildContext context, GermanBasicsModel model) {
    return SliverAppBar(
      expandedHeight: 200,
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
          centerTitle: false,
          titlePadding: const EdgeInsets.only(left: 18, bottom: 16),
          title: AnimatedOpacity(
            opacity: _appBarOpacity < 0.5 ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: const Text(
              'German Basics',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 24,
                shadows: [
                  Shadow(
                    offset: Offset(0, 1),
                    blurRadius: 3,
                    color: Color(0x4D000000), // Colors.black.withOpacity(0.3)
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
                      if (_disposed) return Container();

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

                // Content subtitle positioned at bottom
                Positioned(
                  left: 20,
                  bottom: 70, // Position it above the title
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'Learn the fundamentals of German',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
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
  }


  Widget _buildIntroSection(GermanBasicsModel model) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                offset: const Offset(0, 4),
                blurRadius: 10,
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
                      color: const Color(0xFF3F51B5).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.lightbulb_outline,
                      color: Color(0xFF3F51B5),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Getting Started with German',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3F51B5),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'German (Deutsch) is a West Germanic language that is the official language of Germany, Austria, Switzerland, and other countries.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'In this section, you\'ll learn essential vocabulary and grammar to build a strong foundation for your German language journey.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_outline, color: Color(0xFF4CAF50), size: 16),
                            SizedBox(width: 6),
                            Text(
                              'Beginner Friendly',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4CAF50),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2196F3).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.timer_outlined, color: Color(0xFF2196F3), size: 16),
                            SizedBox(width: 6),
                            Text(
                              '5-10 minutes',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2196F3),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
                    title.contains('Essential') ? Icons.category : Icons.fitness_center,
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

  Widget _buildBasicCategories(BuildContext context, GermanBasicsModel model) {
    return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
    sliver: SliverGrid(
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    childAspectRatio: 0.85,
    crossAxisSpacing: 16,
    mainAxisSpacing: 16,
    ),
    delegate: SliverChildBuilderDelegate(
    (context, index) {
    final category = model.categoriesData[index];
    final color = Color(int.parse(category['color']));
    final iconData = model.getIconData(category['icon']);

    return _buildCategoryCard(
      context: context,
      model: model,
      key: ValueKey('basics_category_${category['title']}'),
      title: category['title'],
      subtitle: category['subtitle'],
      color: color,
      icon: iconData,
      items: List<Map<String, dynamic>>.from(category['items'] ?? []),
      index: index,
    );
    },
      childCount: model.categoriesData.length,
    ),
    ),
    );
  }

  Widget _buildCategoryCard({
    required BuildContext context,
    required GermanBasicsModel model,
    Key? key,
    required String title,
    required String subtitle,
    required Color color,
    required IconData icon,
    required List<Map<String, dynamic>> items,
    required int index,
  }) {
    return GestureDetector(
      onTap: () {
        if (_disposed) return;

        // Navigate to the detailed category screen with items
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GermanCategoryDetailScreen(
              title: title,
              color: color,
              icon: icon,
              items: items,
              model: model, // Pass the model to use TTS in detail screen
            ),
          ),
        );
      },
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          if (_disposed) return child ?? Container();

          return Transform.translate(
            offset: Offset(0, index % 2 == 0 ? _floatAnimation.value / 3 : -_floatAnimation.value / 3),
            child: child,
          );
        },
        child: Container(
          key: key,
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

              // Content
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            icon,
                            color: color,
                            size: 24,
                          ),
                        ),

                      ],
                    ),
                    const SizedBox(height: 16),
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${items.isEmpty ? "Coming soon" : "${items.length} items"}',
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

  Widget _buildPracticeActivities(BuildContext context, GermanBasicsModel model) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 160,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: model.practiceData.length,
          itemBuilder: (context, index) {
            final practice = model.practiceData[index];
            final color = Color(int.parse(practice['color']));
            final iconData = model.getIconData(practice['icon']);

            return _buildPracticeCard(
              context: context,
              model: model,
              key: ValueKey('practice_${practice['title']}'),
              title: practice['title'],
              subtitle: practice['subtitle'],
              color: color,
              icon: iconData,
              index: index,
            );
          },
        ),
      ),
    );
  }

  Widget _buildPracticeCard({
    required BuildContext context,
    required GermanBasicsModel model,
    Key? key,
    required String title,
    required String subtitle,
    required Color color,
    required IconData icon,
    required int index,
  }) {
    return Container(
      key: key,
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      child: GestureDetector(
        onTap: () {
          // TODO: Navigate to practice activity
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Opening $title practice'),
              duration: const Duration(seconds: 2),
            ),
          );
        },
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            if (_disposed) return child ?? Container();

            return Transform.translate(
              offset: Offset(0, index % 2 == 0 ? _floatAnimation.value / 3 : -_floatAnimation.value / 3),
              child: child,
            );
          },
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withOpacity(0.8),
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

                // Content
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      // Left side - icon
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          icon,
                          color: color,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Right side - content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(
                                        Icons.play_arrow_rounded,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Start',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),

                              ],
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
      ),
    );
  }
}