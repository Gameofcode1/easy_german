// language_matching_game.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;

import '../viremodel/game_viewmodel.dart';

class LanguageMatchingGame extends StatelessWidget {
  const LanguageMatchingGame({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LanguageMatchingGameProvider(),
      child: Builder(
        builder: (context) {
          // Initialize the provider and set up callback
          final provider = Provider.of<LanguageMatchingGameProvider>(context, listen: false);
          provider.setGameCompleteCallback((time, score) {
            _showGameCompleteDialog(context, provider, time, score);
          });

          return const _LanguageMatchingGameView();
        },
      ),
    );
  }

  // Show game complete dialog
  void _showGameCompleteDialog(
      BuildContext context,
      LanguageMatchingGameProvider provider,
      String completionTime,
      int currentScore,
      ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Challenge Complete!',
          style: TextStyle(color: provider.primaryColor, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events, size: 50, color: Colors.amber),
            const SizedBox(height: 20),
            Text(
              'Your score: $currentScore',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Completion time: $completionTime',
              style: TextStyle(
                fontSize: 18,
                color: provider.primaryColor,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                provider.playAgain();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: provider.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text('Play Again', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _LanguageMatchingGameView extends StatefulWidget {
  const _LanguageMatchingGameView({Key? key}) : super(key: key);

  @override
  _LanguageMatchingGameViewState createState() => _LanguageMatchingGameViewState();
}

class _LanguageMatchingGameViewState extends State<_LanguageMatchingGameView> with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _scoreAnimationController;
  late AnimationController _matchAnimationController;
  late AnimationController _shakeAnimationController;

  // Animations
  late Animation<double> _scoreAnimation;
  late Animation<double> _loadingAnimation;
  late AnimationController _loadingAnimationController;




  @override
  void initState() {
    super.initState();


    // Initialize loading animation controller
    _loadingAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _loadingAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _loadingAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // Initialize animations
    _scoreAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _scoreAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(
        parent: _scoreAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _matchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _shakeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Initialize the provider
    final provider = Provider.of<LanguageMatchingGameProvider>(context, listen: false);
    provider.initialize();
    provider.setAnimationControllers(
      _scoreAnimationController,
      _matchAnimationController,
      _shakeAnimationController,
    );
  }

  @override
  void dispose() {
    final provider = Provider.of<LanguageMatchingGameProvider>(context, listen: false);
    provider.dispose();

    _scoreAnimationController.dispose();
    _matchAnimationController.dispose();
    _shakeAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageMatchingGameProvider>(
      builder: (context, provider, child) {
        if (provider.wordPairs.isEmpty) {
          return _buildLoadingScreen(provider);
        }
        // Get only unmatched cards
        final unmatchedGermanCards = provider.germanCards
            .where((card) => !provider.matchedPairs.contains(card.id))
            .toList();
        final unmatchedEnglishCards = provider.englishCards
            .where((card) => !provider.matchedPairs.contains(card.id))
            .toList();

        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            backgroundColor: provider.primaryColor,
            iconTheme:const IconThemeData(color: Colors.white),
            elevation: 0,
            title: const Text(
              'Language Match',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            centerTitle: true,
            actions: [
              // Pause button
              IconButton(
                icon: Icon(provider.isGamePaused ? Icons.play_arrow : Icons.pause, color: Colors.white),
                onPressed: provider.togglePause,
              ),
              // Timer display
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      provider.formattedTime,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: provider.isGamePaused
                ? _buildPausedScreen(provider)
                : Column(
              children: [
                // Progress and score indicator
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Progress bar
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: provider.matchedPairs.length / provider.wordPairs.length,
                            backgroundColor: Colors.grey[200],
                            color: provider.primaryColor,
                            minHeight: 10,
                          ),
                        ),
                      ),

                      const SizedBox(width: 20),

                      // Score display with animation
                      AnimatedBuilder(
                          animation: _scoreAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _scoreAnimation.value,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: provider.primaryColor,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: provider.primaryColor.withOpacity(0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.star, color: Colors.amber, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${provider.score}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                      ),
                    ],
                  ),
                ),

                // Game instruction
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.touch_app, color: provider.primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        'Match German-English word pairs',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: provider.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),

                // Cards remaining counter
                Text(
                  '${unmatchedGermanCards.length} pairs remaining',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),

                const SizedBox(height: 10),

                // Game grid
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        // German words (left side)
                        Expanded(
                          child: _buildCardsList(
                            provider,
                            unmatchedGermanCards,
                            provider.selectedGermanCard?.id,
                            Colors.blue[50]!,
                            provider.primaryColor,
                          ),
                        ),

                        // Divider with animation for matches
                        AnimatedBuilder(
                            animation: _matchAnimationController,
                            builder: (context, child) {
                              return Container(
                                width: 2,
                                margin: const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      provider.primaryColor.withOpacity(0.1),
                                      provider.matchedPairs.isNotEmpty
                                          ? Colors.green.withOpacity(_matchAnimationController.value)
                                          : provider.primaryColor,
                                      provider.primaryColor.withOpacity(0.1),
                                    ],
                                  ),
                                ),
                              );
                            }
                        ),

                        // English words (right side)
                        Expanded(
                          child: _buildCardsList(
                            provider,
                            unmatchedEnglishCards,
                            provider.selectedEnglishCard?.id,
                            Colors.amber[50]!,
                            Colors.amber[800]!,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Matched pairs section
                if (provider.matchedPairs.isNotEmpty)
                  Container(
                    height: 90,
                    margin: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Matched words (${provider.matchedPairs.length})',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: provider.matchedPairs.length,
                            itemBuilder: (context, index) {
                              final pairId = provider.matchedPairs[index];
                              final pair = provider.wordPairs.firstWhere((p) => p.id == pairId);

                              return Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [provider.primaryColor.withOpacity(0.1), Colors.green.withOpacity(0.3)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.green),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      pair.german,
                                      style: TextStyle(
                                        color: provider.primaryColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const Text(' = ', style: TextStyle(color: Colors.grey)),
                                    Text(
                                      pair.english,
                                      style: TextStyle(
                                        color: Colors.amber[800],
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Build paused screen
  Widget _buildPausedScreen(LanguageMatchingGameProvider provider) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Colors.grey[100]!],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pause_circle_filled, size: 80, color: provider.primaryColor),
            const SizedBox(height: 20),
            Text(
              'Game Paused',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: provider.primaryColor,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Current time: ${provider.formattedTime}',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: provider.togglePause,
              style: ElevatedButton.styleFrom(
                backgroundColor: provider.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 4,
              ),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Resume Game', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }

  // Build card list with animations
  Widget _buildCardsList(
      LanguageMatchingGameProvider provider,
      List<GameCard> cards,
      int? selectedId,
      Color baseColor,
      Color textColor
      ) {
    return AnimatedBuilder(
        animation: _shakeAnimationController,
        builder: (context, child) {
          return Transform.translate(
            offset: selectedId != null && cards.any((c) => c.id == selectedId)
                ? Offset(
              _shakeAnimationController.value * math.sin(_shakeAnimationController.value * math.pi * 5) * 5,
              0,
            )
                : Offset.zero,
            child: ListView.builder(
              itemCount: cards.length,
              itemBuilder: (context, index) {
                final card = cards[index];
                final isSelected = selectedId == card.id;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5.0),
                  child: GestureDetector(
                    onTap: () {
                      if (provider.gameActive && !provider.isGamePaused) {
                        provider.handleCardTap(card);
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 60,
                      decoration: BoxDecoration(
                        color: isSelected ? baseColor : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? textColor : Colors.grey[300]!,
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isSelected
                                ? textColor.withOpacity(0.3)
                                : Colors.black.withOpacity(0.05),
                            blurRadius: isSelected ? 10 : 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  card.text,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? textColor : Colors.black87,
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isSelected)
                                Container(
                                  margin: const EdgeInsets.only(left: 4),
                                  child: Icon(
                                    Icons.volume_up,
                                    size: 16,
                                    color: textColor,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        }
    );
  }



  // New loading screen with animated progress indicator
  Widget _buildLoadingScreen(LanguageMatchingGameProvider provider) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation: _loadingAnimation,
        builder: (context, child) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Pulsating loading icon
                Transform.scale(
                  scale: _loadingAnimation.value,
                  child: Icon(
                    Icons.language,
                    size: 100,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 30),
                // Text with dynamic opacity
                Opacity(
                  opacity: _loadingAnimation.value,
                  child: Text(
                    'Loading Language Matching Game',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          blurRadius: 10.0,
                          color: Colors.black.withOpacity(0.3),
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                // Animated progress indicator
                SizedBox(
                  width: 200,
                  child: LinearProgressIndicator(
                    value: _loadingAnimation.value,
                    backgroundColor: Colors.blue[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white.withOpacity(0.8),
                    ),
                    minHeight: 10,
                  ),
                ),
                const SizedBox(height: 20),
                // Hint text
                Text(
                  'Preparing your language challenge...',
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

}

