
// Category Section Model
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';

class CategorySection {
  final String title;
  final List<CategoryItem> items;

  CategorySection({
    required this.title,
    required this.items,
  });
}

// Category Item Model
class CategoryItem {
  final IconData icon;
  final Color iconColor;
  final String title;
  final int count;
  double progress;
  final String category;
  final String level;
  final bool isNotStarted;

  CategoryItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.count,
    required this.progress,
    required this.category,
    required this.level,
    this.isNotStarted = false,
  });
}

// Flashcard Example Model
class FlashcardExample {
  final String prefix;
  final String highlight;
  final String suffix;
  final String type;

  FlashcardExample({
    required this.prefix,
    required this.highlight,
    required this.suffix,
    required this.type,
  });
}

// Flashcard Data Model
class FlashcardData {
  final String id;
  final String german;
  final String english;
  final String partOfSpeech;
  final List<FlashcardExample> examples;
  bool isLearned;
  bool isBookmarked;

  FlashcardData({
    required this.id,
    required this.german,
    required this.english,
    required this.partOfSpeech,
    required this.examples,
    this.isLearned = false,
    this.isBookmarked = false,
  });
}

// Providers

// Vocabulary Provider for category management
class VocabularyProvider extends ChangeNotifier {
  // Category data
  Map<String, List<CategorySection>> levelData = {
    'A1': [
      CategorySection(
        title: 'Basics',
        items: [
          CategoryItem(
            icon: Icons.waving_hand,
            iconColor: Colors.purple,
            title: 'Greetings and Introduction',
            count: 6,
            progress: 1.0,
            category: 'greetings',
            level: 'A1',
          ),
          CategoryItem(
            icon: Icons.family_restroom,
            iconColor: Colors.teal,
            title: 'Family',
            count: 12,
            progress: 0.7,
            category: 'family',
            level: 'A1',
          ),
          CategoryItem(
            icon: Icons.home,
            iconColor: Colors.brown,
            title: 'Home',
            count: 10,
            progress: 0.4,
            category: 'home',
            level: 'A1',
          ),
        ],
      ),
      CategorySection(
        title: 'Food & Drink',
        items: [
          CategoryItem(
            icon: Icons.local_drink,
            iconColor: Colors.blue,
            title: 'Drinks',
            count: 7,
            progress: 0.3,
            category: 'drinks',
            level: 'A1',
          ),
          CategoryItem(
            icon: Icons.apple,
            iconColor: Colors.red,
            title: 'Fruits',
            count: 5,
            progress: 0.5,
            category: 'fruits',
            level: 'A1',
          ),
        ],
      ),
    ],
    'A2': [
      CategorySection(
        title: 'Daily Life',
        items: [
          CategoryItem(
            icon: Icons.shopping_cart,
            iconColor: Colors.orange,
            title: 'Shopping',
            count: 15,
            progress: 0.2,
            category: 'shopping',
            level: 'A2',
          ),
          CategoryItem(
            icon: Icons.directions_walk,
            iconColor: Colors.green,
            title: 'Activities',
            count: 20,
            progress: 0.5,
            category: 'activities',
            level: 'A2',
          ),
        ],
      ),
      CategorySection(
        title: 'Health & Body',
        items: [
          CategoryItem(
            icon: Icons.medical_services,
            iconColor: Colors.red,
            title: 'Health',
            count: 18,
            progress: 0.3,
            category: 'health',
            level: 'A2',
          ),
          CategoryItem(
            icon: Icons.accessibility_new,
            iconColor: Colors.indigo,
            title: 'Body Parts',
            count: 14,
            progress: 0.6,
            category: 'body_parts',
            level: 'A2',
          ),
        ],
      ),
    ],
    'B1': [
      CategorySection(
        title: 'Work & Education',
        items: [
          CategoryItem(
            icon: Icons.work,
            iconColor: Colors.blueGrey,
            title: 'Professions',
            count: 25,
            progress: 0.1,
            category: 'professions',
            level: 'B1',
          ),
          CategoryItem(
            icon: Icons.school,
            iconColor: Colors.blue,
            title: 'Education',
            count: 22,
            progress: 0.2,
            category: 'education',
            level: 'B1',
          ),
        ],
      ),
      CategorySection(
        title: 'Abstract Concepts',
        items: [
          CategoryItem(
            icon: Icons.psychology,
            iconColor: Colors.purple,
            title: 'Emotions',
            count: 30,
            progress: 0.0,
            category: 'emotions',
            level: 'B1',
            isNotStarted: true,
          ),
          CategoryItem(
            icon: Icons.lightbulb,
            iconColor: Colors.amber,
            title: 'Ideas & Opinions',
            count: 35,
            progress: 0.0,
            category: 'ideas',
            level: 'B1',
            isNotStarted: true,
          ),
        ],
      ),
    ],
  };

  // Update progress for a category
  void updateCategoryProgress(String level, String category, double progress) {
    for (var section in levelData[level] ?? []) {
      for (var item in section.items) {
        if (item.category == category) {
          item.progress = progress;
          notifyListeners();
          return;
        }
      }
    }
  }

  // Get flashcards based on category and level
  List<FlashcardData> getFlashcardsForCategory(String category, String level) {
    // This would ideally come from a database or API
    // Here we're creating sample data
    switch (category) {
      case 'greetings':
        return [
          FlashcardData(
            id: 'greeting_1',
            german: 'Hallo',
            english: 'Hello',
            partOfSpeech: 'INT',
            examples: [
              FlashcardExample(
                prefix: 'Ich sage ',
                highlight: 'Hallo',
                suffix: ' zu meinem Freund.',
                type: 'INT',
              ),
              FlashcardExample(
                prefix: '',
                highlight: 'Hallo',
                suffix: ', wie geht es dir?',
                type: 'INT',
              ),
            ],
          ),
          FlashcardData(
            id: 'greeting_2',
            german: 'Guten Tag',
            english: 'Good day',
            partOfSpeech: 'INT',
            examples: [
              FlashcardExample(
                prefix: '',
                highlight: 'Guten Tag',
                suffix: ', Herr Schmidt!',
                type: 'INT',
              ),
              FlashcardExample(
                prefix: 'Man sagt ',
                highlight: 'Guten Tag',
                suffix: ' am Nachmittag.',
                type: 'INT',
              ),
            ],
          ),
          FlashcardData(
            id: 'greeting_3',
            german: 'Auf Wiedersehen',
            english: 'Goodbye',
            partOfSpeech: 'INT',
            examples: [
              FlashcardExample(
                prefix: '',
                highlight: 'Auf Wiedersehen',
                suffix: '! Bis morgen!',
                type: 'INT',
              ),
              FlashcardExample(
                prefix: 'Ich muss jetzt gehen. ',
                highlight: 'Auf Wiedersehen',
                suffix: '!',
                type: 'INT',
              ),
            ],
          ),
        ];
      case 'family':
        return [
          FlashcardData(
            id: 'family_1',
            german: 'die Familie',
            english: 'the family',
            partOfSpeech: 'NOU',
            examples: [
              FlashcardExample(
                prefix: 'Meine ',
                highlight: 'Familie',
                suffix: ' ist sehr groß.',
                type: 'NOU',
              ),
              FlashcardExample(
                prefix: 'Wie groß ist deine ',
                highlight: 'Familie',
                suffix: '?',
                type: 'NOU',
              ),
            ],
          ),
          FlashcardData(
            id: 'family_2',
            german: 'die Mutter',
            english: 'the mother',
            partOfSpeech: 'NOU',
            examples: [
              FlashcardExample(
                prefix: 'Meine ',
                highlight: 'Mutter',
                suffix: ' kocht sehr gut.',
                type: 'NOU',
              ),
              FlashcardExample(
                prefix: 'Die ',
                highlight: 'Mutter',
                suffix: ' von meinem Freund ist Ärztin.',
                type: 'NOU',
              ),
            ],
          ),
        ];
      default:
        return [
          FlashcardData(
            id: 'default_1',
            german: 'einzeln',
            english: 'single',
            partOfSpeech: 'ADJ',
            examples: [
              FlashcardExample(
                prefix: 'er wurde mit einer ',
                highlight: 'einzelnen',
                suffix: ' Kugel getötet.',
                type: 'ADJ',
              ),
              FlashcardExample(
                prefix: 'die ',
                highlight: 'einzelnen',
                suffix: ' Zimmer waren komplett ausgebucht.',
                type: 'ADJ',
              ),
            ],
          ),
          FlashcardData(
            id: 'default_2',
            german: 'das Einzelzimmer',
            english: 'single room',
            partOfSpeech: 'NOU',
            examples: [
              FlashcardExample(
                prefix: 'ich hätte gern ein ',
                highlight: 'Einzelzimmer',
                suffix: ' mit Dusche, bitte.',
                type: 'NOU',
              ),
            ],
          ),
        ];
    }
  }

  Color getLevelColor(String level) {
    switch (level) {
      case 'A1':
        return Colors.green;
      case 'A2':
        return Colors.orange;
      case 'B1':
        return Colors.redAccent;
      default:
        return const Color(0xFF3F51B5);
    }
  }

  String getTypeLabel(String type) {
    switch (type) {
      case 'NOU':
        return 'NOUN';
      case 'VER':
        return 'VERB';
      case 'ADJ':
        return 'ADJECTIVE';
      case 'ADV':
        return 'ADVERB';
      case 'PRE':
        return 'PREPOSITION';
      case 'INT':
        return 'INTERJECTION';
      default:
        return type;
    }
  }
}

// Flashcard Provider for flashcard interactions
class FlashcardProvider extends ChangeNotifier {
  int currentIndex = 0;
  bool isFlipped = false;
  bool isPlaying = false;
  List<FlashcardData> flashcards = [];
  String currentCategory = '';
  String currentLevel = '';
  String currentTitle = '';
  int wordsViewed = 0;
  int wordsCompleted = 0;
  bool initialized = false;

  final FlutterTts flutterTts = FlutterTts();

  // Initialize the TTS engine
  Future<void> initTts() async {
    if (!initialized) {
      await flutterTts.setLanguage('de-DE');
      await flutterTts.setSpeechRate(0.5);
      await flutterTts.setVolume(1.0);

      flutterTts.setCompletionHandler(() {
        isPlaying = false;
        notifyListeners();
      });

      initialized = true;
    }
  }

  // Load the flashcards for a category
  void loadFlashcards(String category, String level, String title, List<FlashcardData> cards) {
    currentCategory = category;
    currentLevel = level;
    currentTitle = title;
    flashcards = cards;
    currentIndex = 0;
    isFlipped = false;
    initTts();
    notifyListeners();
  }

  // Play pronunciation using TTS
  Future<void> playPronunciation() async {
    if (isPlaying) {
      await flutterTts.stop();
      isPlaying = false;
      notifyListeners();
      return;
    }

    if (currentIndex < flashcards.length) {
      isPlaying = true;
      wordsViewed++;
      notifyListeners();

      try {
        await flutterTts.speak(flashcards[currentIndex].german);
      } catch (e) {
        print('Error playing TTS: $e');
        isPlaying = false;
        notifyListeners();
      }
    }
  }

  // Play example using TTS
  Future<void> playExample() async {
    if (isPlaying) {
      await flutterTts.stop();
      isPlaying = false;
      notifyListeners();
      return;
    }

    if (currentIndex < flashcards.length && flashcards[currentIndex].examples.isNotEmpty) {
      isPlaying = true;
      notifyListeners();

      try {
        final example = flashcards[currentIndex].examples[0];
        final fullText = example.prefix + example.highlight + example.suffix;
        await flutterTts.speak(fullText);
      } catch (e) {
        print('Error playing TTS: $e');
        isPlaying = false;
        notifyListeners();
      }
    }
  }

  // Flip the card
  void flipCard() {
    isFlipped = !isFlipped;
    notifyListeners();
  }

  // Move to next card
  void nextCard() {
    if (currentIndex < flashcards.length - 1) {
      currentIndex++;
    } else {
      currentIndex = 0; // Loop back to first card
    }

    isFlipped = false;
    notifyListeners();
  }

  // Move to previous card
  void previousCard() {
    if (currentIndex > 0) {
      currentIndex--;
    } else {
      currentIndex = flashcards.length - 1; // Loop to last card
    }

    isFlipped = false;
    notifyListeners();
  }

  // Mark card as learned
  void markAsLearned() {
    if (currentIndex < flashcards.length) {
      flashcards[currentIndex].isLearned = true;
      wordsCompleted++;
      notifyListeners();
    }
  }

  // Toggle bookmark status
  void toggleBookmark() {
    if (currentIndex < flashcards.length) {
      flashcards[currentIndex].isBookmarked = !flashcards[currentIndex].isBookmarked;
      notifyListeners();
    }
  }

  // Clean up resources
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }
}

// UI Screens

// Main Vocabulary Screen with Levels
class VocabularyCategoryScreen extends StatelessWidget {
  const VocabularyCategoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Vocabulary'),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF3F51B5),
          elevation: 0,
          bottom: const TabBar(
            labelColor: Color(0xFF3F51B5),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFF3F51B5),
            tabs: [
              Tab(text: 'A1 - Beginner'),
              Tab(text: 'A2 - Elementary'),
              Tab(text: 'B1 - Intermediate'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // A1 Level Vocabulary
            LevelContentWidget(level: 'A1'),

            // A2 Level Vocabulary
            LevelContentWidget(level: 'A2'),

            // B1 Level Vocabulary
            LevelContentWidget(level: 'B1'),
          ],
        ),
      ),
    );
  }
}

// Level Content Widget
class LevelContentWidget extends StatelessWidget {
  final String level;

  const LevelContentWidget({
    Key? key,
    required this.level,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<VocabularyProvider>(context);
    final sections = provider.levelData[level] ?? [];

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            '$level Level German Vocabulary',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3F51B5),
            ),
          ),
        ),
        ...sections.map((section) => CategorySectionWidget(
          title: section.title,
          items: section.items,
        )).toList(),
      ],
    );
  }
}

// Category Section Widget
class CategorySectionWidget extends StatelessWidget {
  final String title;
  final List<CategoryItem> items;

  const CategorySectionWidget({
    Key? key,
    required this.title,
    required this.items,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        ...items.map((item) => CategoryItemWidget(item: item)).toList(),
      ],
    );
  }
}

// Category Item Widget
class CategoryItemWidget extends StatelessWidget {
  final CategoryItem item;

  const CategoryItemWidget({
    Key? key,
    required this.item,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final vocabularyProvider = Provider.of<VocabularyProvider>(context);
    final flashcardProvider = Provider.of<FlashcardProvider>(context, listen: false);

    return InkWell(
      onTap: () {
        // Load flashcards and navigate to flashcard screen
        final flashcards = vocabularyProvider.getFlashcardsForCategory(item.category, item.level);
        flashcardProvider.loadFlashcards(item.category, item.level, item.title, flashcards);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const FlashcardScreen(),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: item.iconColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(item.icon, color: item.iconColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Level ${item.level}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              item.count.toString(),
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(width: 16),
            if (item.isNotStarted)
              Text(
                'Not Started',
                style: TextStyle(color: Colors.grey.shade600),
              )
            else
              SizedBox(
                width: 100,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: item.progress,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      item.progress == 1.0 ? const Color(0xFF3F51B5) : Colors.orange,
                    ),
                    minHeight: 8,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}


class FlashcardScreen extends StatefulWidget {
  const FlashcardScreen({Key? key}) : super(key: key);

  @override
  _FlashcardScreenState createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> with SingleTickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );

    // Listen to flip card changes
    final provider = Provider.of<FlashcardProvider>(context, listen: false);
    provider.addListener(_onFlipChanged);
  }

  void _onFlipChanged() {
    final provider = Provider.of<FlashcardProvider>(context, listen: false);
    if (provider.isFlipped) {
      _flipController.forward();
    } else {
      _flipController.reverse();
    }
  }

  Widget _buildProgressBar(BuildContext context) {
    final flashcardProvider = Provider.of<FlashcardProvider>(context);
    final totalCards = flashcardProvider.flashcards.length;
    final currentIndex = flashcardProvider.currentIndex;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Card ${currentIndex + 1}/$totalCards',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              Row(
                children: [
                  Icon(Icons.remove_red_eye, color: const Color(0xFF3F51B5), size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${flashcardProvider.wordsViewed}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.check_circle, color: const Color(0xFF3F51B5), size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${flashcardProvider.wordsCompleted}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ((currentIndex + 1) / totalCards),
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF3F51B5)),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSoundWaves() {
    return SizedBox(
      height: 24,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          4,
              (index) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: AnimatedContainer(
              duration: Duration(milliseconds: 300 + (index * 100)),
              width: 3,
              height: 10.0 + (index % 3) * 4,
              decoration: const BoxDecoration(
                color: Color(0xFF3F51B5),
                borderRadius: BorderRadius.all(Radius.circular(2)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    final provider = Provider.of<FlashcardProvider>(context, listen: false);
    provider.removeListener(_onFlipChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<FlashcardProvider, VocabularyProvider>(
      builder: (context, flashcardProvider, vocabProvider, child) {
        final level = flashcardProvider.currentLevel;
        final title = flashcardProvider.currentTitle;
        final levelColor = vocabProvider.getLevelColor(level);

        if (flashcardProvider.flashcards.isEmpty) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final currentCard = flashcardProvider.flashcards[flashcardProvider.currentIndex];
        final hasExamples = currentCard.examples.isNotEmpty;

        return Scaffold(
          backgroundColor: Colors.grey[100],
          appBar: AppBar(
            title: Text(title),
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF3F51B5),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: levelColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Level $level',
                  style: TextStyle(
                    color: levelColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                _buildProgressBar(context),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: GestureDetector(
                      onTap: () => flashcardProvider.flipCard(),
                      onHorizontalDragEnd: (details) {
                        if (details.primaryVelocity! > 0) {
                          flashcardProvider.previousCard();
                        } else if (details.primaryVelocity! < 0) {
                          flashcardProvider.nextCard();
                        }
                      },
                      child: AnimatedBuilder(
                        animation: _flipAnimation,
                        builder: (context, child) {
                          final frontOpacity = 1.0 - _flipAnimation.value;
                          final backOpacity = _flipAnimation.value;

                          return Stack(
                            children: [
                              // Front of card (German word)
                              Opacity(
                                opacity: frontOpacity,
                                child: Transform(
                                  transform: Matrix4.identity()
                                    ..setEntry(3, 2, 0.001)
                                    ..rotateY(3.14159 * _flipAnimation.value),
                                  alignment: Alignment.center,
                                  child: Card(
                                    elevation: 8,
                                    shadowColor: const Color(0xFF3F51B5).withOpacity(0.2),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    child: Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(24),
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Colors.white,
                                            Colors.grey.shade50,
                                          ],
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(24.0),
                                        child: LayoutBuilder(
                                          builder: (context, constraints) {
                                            return SingleChildScrollView(
                                              physics: const NeverScrollableScrollPhysics(),
                                              child: ConstrainedBox(
                                                constraints: BoxConstraints(
                                                  minHeight: constraints.maxHeight,
                                                ),
                                                child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    // Type badge
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 4,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFF3F51B5).withOpacity(0.1),
                                                        borderRadius: BorderRadius.circular(12),
                                                      ),
                                                      child: Text(
                                                        vocabProvider.getTypeLabel(currentCard.partOfSpeech),
                                                        style: const TextStyle(
                                                          color: Color(0xFF3F51B5),
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 30),

                                                    // Sound playing indicator - Shows only when playing
                                                    if (flashcardProvider.isPlaying)
                                                      Padding(
                                                        padding: const EdgeInsets.only(bottom: 20),
                                                        child: _buildSoundWaves(),
                                                      ),

                                                    // German word
                                                    FittedBox(
                                                      fit: BoxFit.scaleDown,
                                                      child: Text(
                                                        currentCard.partOfSpeech == 'NOU' ?
                                                        currentCard.german :
                                                        currentCard.german.toLowerCase(),
                                                        style: const TextStyle(
                                                          fontSize: 40,
                                                          fontWeight: FontWeight.bold,
                                                          color: Colors.black87,
                                                        ),
                                                        textAlign: TextAlign.center,
                                                      ),
                                                    ),

                                                    const SizedBox(height: 30),

                                                    // Hint for card flipping
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        const Icon(
                                                          Icons.touch_app,
                                                          size: 14,
                                                          color: Colors.grey,
                                                        ),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          'Tap to see meaning',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: Colors.grey.shade500,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // Back of card (English translation and example)
                              Opacity(
                                opacity: backOpacity,
                                child: Transform(
                                  transform: Matrix4.identity()
                                    ..setEntry(3, 2, 0.001)
                                    ..rotateY(3.14159 * (1 - _flipAnimation.value)),
                                  alignment: Alignment.center,
                                  child: Card(
                                    elevation: 8,
                                    shadowColor: const Color(0xFF3F51B5).withOpacity(0.2),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    child: Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(24),
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Colors.white,
                                            const Color(0xFFF5F7FF),
                                          ],
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(24.0),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            // Sound playing indicator
                                            if (flashcardProvider.isPlaying)
                                              _buildSoundWaves(),

                                            // English translation
                                            FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Text(
                                                currentCard.english,
                                                style: const TextStyle(
                                                  fontSize: 36,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black87,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                            const SizedBox(height: 30),

                                            // Example section
                                            if (hasExamples) ...[
                                              const Align(
                                                alignment: Alignment.centerLeft,
                                                child: Text(
                                                  'Example:',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF3F51B5),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 10),
                                              Container(
                                                width: double.infinity,
                                                padding: const EdgeInsets.all(16),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: Colors.grey.shade200,
                                                  ),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text.rich(
                                                      TextSpan(
                                                        style: const TextStyle(
                                                          fontSize: 16,
                                                          color: Colors.black87,
                                                        ),
                                                        children: [
                                                          TextSpan(text: currentCard.examples[0].prefix),
                                                          TextSpan(
                                                            text: currentCard.examples[0].highlight,
                                                            style: const TextStyle(
                                                              backgroundColor: Color(0x663F51B5),
                                                              fontWeight: FontWeight.bold,
                                                              color: Color(0xFF3F51B5),
                                                            ),
                                                          ),
                                                          TextSpan(text: currentCard.examples[0].suffix),
                                                        ],
                                                      ),
                                                    ),
                                                    const SizedBox(height: 12),
                                                    const Divider(),
                                                    const SizedBox(height: 6),
                                                    Text(
                                                      _getTranslatedExample(currentCard),
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.grey.shade700,
                                                        fontStyle: FontStyle.italic,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ] else ...[
                                              const Text(
                                                'No examples available',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontStyle: FontStyle.italic,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],

                                            const Spacer(),

                                            // Hint for flipping back
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                const Icon(
                                                  Icons.touch_app,
                                                  size: 14,
                                                  color: Colors.grey,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Tap to return',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey.shade500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),

                // Bottom navigation controls
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNavButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: () => flashcardProvider.previousCard(),
                      ),

                      _buildNavButton(
                        icon: Icons.volume_up_rounded,
                        highlighted: true,
                        isActive: flashcardProvider.isPlaying,
                        onTap: () => flashcardProvider.playPronunciation(),
                      ),

                      _buildNavButton(
                        icon: Icons.flip,
                        onTap: () => flashcardProvider.flipCard(),
                      ),

                      _buildNavButton(
                        icon: Icons.bookmark_border,
                        isActive: currentCard.isBookmarked,
                        onTap: () {
                          flashcardProvider.toggleBookmark();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  currentCard.isBookmarked
                                      ? 'Added to favorites!'
                                      : 'Removed from favorites.'
                              ),
                              duration: const Duration(seconds: 1),
                              backgroundColor: const Color(0xFF3F51B5),
                            ),
                          );
                        },
                      ),

                      _buildNavButton(
                        icon: Icons.arrow_forward_ios_rounded,
                        onTap: () => flashcardProvider.nextCard(),
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

  String _getTranslatedExample(FlashcardData card) {
    // This would ideally come from a database with actual translations
    // Here we're simply creating a simulated translation
    if (card.examples.isEmpty) return '';

    final example = card.examples[0];
    final fullExample = example.prefix + example.highlight + example.suffix;

    switch (card.id) {
      case 'greeting_1':
        return "I say hello to my friend.";
      case 'greeting_2':
        return "Good day, Mr. Schmidt!";
      case 'greeting_3':
        return "Goodbye! See you tomorrow!";
      case 'family_1':
        return "My family is very big.";
      case 'family_2':
        return "My mother cooks very well.";
      default:
      // Generate a simplistic translation for demo purposes
        return "Translation: ${card.english} ${fullExample.contains('?') ? '?' : '.'}";
    }
  }

  Widget _buildNavButton({
    required IconData icon,
    required VoidCallback onTap,
    bool highlighted = false,
    bool isActive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: highlighted
                ? isActive
                ? const Color(0xFF3F51B5)
                : const Color(0xFF3F51B5).withOpacity(0.1)
                : isActive
                ? const Color(0xFF3F51B5).withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: highlighted
                ? isActive
                ? Colors.white
                : const Color(0xFF3F51B5)
                : isActive
                ? const Color(0xFF3F51B5)
                : const Color(0xFF3F51B5),
            size: 24,
          ),
        ),
      ),
    );
  }
}