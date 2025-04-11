import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../core/constants/app_images.dart';
import '../../homePage/view/home_page.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLastPage = false;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;

  final List<OnboardingPage> onboardingPages = [
    OnboardingPage(
      title: "Learn German with Stories",
      description: "Immerse yourself in interactive German stories with text-to-speech to improve your reading and listening skills.",
      imagePath: cat,
      bgColor: const Color(0xFF3F51B5),
      gradientColors: [const Color(0xFF3F51B5), const Color(0xFF5C6BC0)],
      icon: Icons.book,
    ),
    OnboardingPage(
      title: "Build Your Vocabulary",
      description: "Expand your German vocabulary through flashcards, categories, and interactive exercises.",
      imagePath: cat,
      bgColor: const Color(0xFF4CAF50),
      gradientColors: [const Color(0xFF4CAF50), const Color(0xFF81C784)],
      icon: Icons.translate,
    ),
    OnboardingPage(
      title: "Master Daily Phrases",
      description: "Learn and practice essential German phrases for real-life conversations and situations.",
      imagePath: cat,
      bgColor: const Color(0xFFF44336),
      gradientColors: [const Color(0xFFF44336), const Color(0xFFE57373)],
      icon: Icons.chat_bubble,
    ),
    OnboardingPage(
      title: "Play and Learn",
      description: "Reinforce your German skills with fun, interactive games designed to test your knowledge.",
      imagePath: cat,
      bgColor: const Color(0xFFFF9800),
      gradientColors: [const Color(0xFFFF9800), const Color(0xFFFFB74D)],
      icon: Icons.games,
    ),
    OnboardingPage(
      title: "Track Your Progress",
      description: "Monitor your improvement with detailed statistics and personalized learning paths.",
      imagePath: cat,
      bgColor: const Color(0xFF9C27B0),
      gradientColors: [const Color(0xFF9C27B0), const Color(0xFFBA68C8)],
      icon: Icons.insights,
    ),
  ];

  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Use shorter animation duration for smoother transitions
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeOutCubic, // Use a smoother curve
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05), // Reduced slide distance for subtler effect
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: Curves.easeOutCubic, // Match the fade animation curve
      ),
    );

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
      _isLastPage = index == onboardingPages.length - 1;
    });

    // Reset and restart animations for the new page
    _fadeController.reset();
    _slideController.reset();
    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> _completeOnboarding() async {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: AnimatedOpacity(
                  opacity: _isLastPage ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  child: TextButton(
                    onPressed: _isLastPage ? null : _completeOnboarding,
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        color: Color(0xFF3F51B5),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: onboardingPages.length,
                physics: const ClampingScrollPhysics(), // Improved physics for smoother scrolling
                itemBuilder: (context, index) {
                  final page = onboardingPages[index];
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: EnhancedOnboardingPageContent(
                        title: page.title,
                        description: page.description,
                        imagePath: page.imagePath,
                        bgColor: page.bgColor,
                        gradientColors: page.gradientColors,
                        icon: page.icon,
                        isCurrentPage: _currentPage == index,
                      ),
                    ),
                  );
                },
              ),
            ),

            // Navigation and indicator
            Container(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Page indicator
                  SmoothPageIndicator(
                    controller: _pageController,
                    count: onboardingPages.length,
                    effect: CustomizableEffect(
                      spacing: 8.0, // More space between dots
                      activeDotDecoration: DotDecoration(
                        width: 20,
                        height: 8,
                        color: onboardingPages[_currentPage].bgColor,
                        borderRadius: BorderRadius.circular(4),
                        rotationAngle: 0.0,
                        dotBorder: DotBorder(
                          padding: 0,
                          width: 0,
                          color: Colors.transparent,
                        ),
                      ),
                      dotDecoration: DotDecoration(
                        width: 8,
                        height: 8,
                        color: const Color(0xFFD1D1D1),
                        borderRadius: BorderRadius.circular(4),
                        dotBorder: DotBorder(
                          padding: 0,
                          width: 0,
                          color: Colors.transparent,
                        ),
                      ),
                    ),
                  ),

                  // Next/Done button
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 300),
                    tween: Tween<double>(
                      begin: _isLastPage ? 60 : 160,
                      end: _isLastPage ? 160 : 60,
                    ),
                    builder: (context, value, child) {
                      return Container(
                        width: value,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: _isLastPage
                              ? _completeOnboarding
                              : () => _pageController.nextPage(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeOutCubic, // Match other animations
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: onboardingPages[_currentPage].bgColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: EdgeInsets.zero,
                            elevation: 5,
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: _isLastPage
                                ? const Row(
                              key: ValueKey('get_started'),
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Get Started',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward, size: 20),
                              ],
                            )
                                : const Icon(
                              Icons.arrow_forward,
                              size: 24,
                              key: ValueKey('arrow'),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EnhancedOnboardingPageContent extends StatefulWidget {
  final String title;
  final String description;
  final String imagePath;
  final Color bgColor;
  final List<Color> gradientColors;
  final IconData icon;
  final bool isCurrentPage;

  const EnhancedOnboardingPageContent({
    super.key,
    required this.title,
    required this.description,
    required this.imagePath,
    required this.bgColor,
    required this.gradientColors,
    required this.icon,
    required this.isCurrentPage,
  });

  @override
  _EnhancedOnboardingPageContentState createState() => _EnhancedOnboardingPageContentState();
}

class _EnhancedOnboardingPageContentState extends State<EnhancedOnboardingPageContent>
    with SingleTickerProviderStateMixin {

  late AnimationController _animationController;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();

    // Slower animation for smoother floating effect
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    // Reduced float distance for subtler animation
    _floatAnimation = Tween<double>(begin: 0, end: 6).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(EnhancedOnboardingPageContent oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Don't reset animation when page changes - this keeps it smooth
    if (widget.isCurrentPage && !oldWidget.isCurrentPage) {
      // Just ensure the animation is running
      if (!_animationController.isAnimating) {
        _animationController.repeat(reverse: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Illustration area
        AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          height: size.height * 0.4,
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.gradientColors.map((color) => color.withOpacity(0.15)).toList(),
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: widget.bgColor.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background icon
                Positioned(
                  right: 20,
                  bottom: 20,
                  child: Icon(
                    widget.icon,
                    size: 100,
                    color: widget.bgColor.withOpacity(0.1),
                  ),
                ),

                // Main image with floating animation
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _floatAnimation.value),
                      child: child,
                    );
                  },
                  child: Image.asset(
                    widget.imagePath,
                    height: size.height * 0.3,
                    fit: BoxFit.contain,
                  ),
                ),

                // Decorative elements
                Positioned(
                  top: 20,
                  left: 20,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: widget.bgColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                // Animated rotating square with slower animation
                Positioned(
                  bottom: 30,
                  left: 50,
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _animationController.value * math.pi, // Half rotation for smoother effect
                        child: child,
                      );
                    },
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: widget.bgColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 40),

        // Title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            widget.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
              height: 1.2,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Description
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36),
          child: Text(
            widget.description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF666666),
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final String imagePath;
  final Color bgColor;
  final List<Color> gradientColors;
  final IconData icon;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.imagePath,
    required this.bgColor,
    required this.gradientColors,
    required this.icon,
  });
}