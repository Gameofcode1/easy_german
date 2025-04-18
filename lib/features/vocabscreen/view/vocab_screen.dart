import 'package:flutter/material.dart';
import 'package:German_Spark/features/vocabscreen/viewmodel/vocab_screen.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/vocabulary_model.dart';


class VocabularyData {
  final Map<String, LevelData> levels;

  VocabularyData({required this.levels});

  factory VocabularyData.fromJson(Map<String, dynamic> json) {
    Map<String, LevelData> levels = {};
    json['vocabulary']['levels'].forEach((key, value) {
      levels[key] = LevelData.fromJson(value);
    });
    return VocabularyData(levels: levels);
  }
}

class LevelData {
  final String name;
  final String description;
  final List<SectionData> sections;

  LevelData({
    required this.name,
    required this.description,
    required this.sections,
  });

  factory LevelData.fromJson(Map<String, dynamic> json) {
    List<SectionData> sections = [];
    for (var section in json['sections']) {
      sections.add(SectionData.fromJson(section));
    }
    return LevelData(
      name: json['name'],
      description: json['description'],
      sections: sections,
    );
  }
}

class SectionData {
  final String title;
  final List<ItemData> items;

  SectionData({
    required this.title,
    required this.items,
  });

  factory SectionData.fromJson(Map<String, dynamic> json) {
    List<ItemData> items = [];
    for (var item in json['items']) {
      items.add(ItemData.fromJson(item));
    }
    return SectionData(
      title: json['title'],
      items: items,
    );
  }
}

class ItemData {
  final String icon;
  final String iconColor;
  final String title;
  final int count;
  final double progress;
  final String category;
  final String level;
  final bool isNotStarted;
  final List<FlashcardData> flashcards;

  ItemData({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.count,
    required this.progress,
    required this.category,
    required this.level,
    required this.isNotStarted,
    required this.flashcards,
  });

  factory ItemData.fromJson(Map<String, dynamic> json) {
    List<FlashcardData> flashcards = [];
    for (var card in json['flashcards']) {
      flashcards.add(FlashcardData.fromJson(card));
    }
    return ItemData(
      icon: json['icon'],
      iconColor: json['iconColor'],
      title: json['title'],
      count: json['count'],
      progress: json['progress'].toDouble(),
      category: json['category'],
      level: json['level'],
      isNotStarted: json['isNotStarted'] ?? false,
      flashcards: flashcards,
    );
  }
}

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

  factory FlashcardData.fromJson(Map<String, dynamic> json) {
    List<FlashcardExample> examples = [];
    for (var example in json['examples']) {
      examples.add(FlashcardExample.fromJson(example));
    }
    return FlashcardData(
      id: json['id'],
      german: json['german'],
      english: json['english'],
      partOfSpeech: json['partOfSpeech'],
      examples: examples,
      isLearned: json['isLearned'] ?? false,
      isBookmarked: json['isBookmarked'] ?? false,
    );
  }
}

class FlashcardExample {
  final String prefix;
  final String highlight;
  final String suffix;
  final String type;
  final String? translation;

  FlashcardExample({
    required this.prefix,
    required this.highlight,
    required this.suffix,
    required this.type,
    this.translation,
  });

  factory FlashcardExample.fromJson(Map<String, dynamic> json) {
    return FlashcardExample(
      prefix: json['prefix'],
      highlight: json['highlight'],
      suffix: json['suffix'],
      type: json['type'],
      translation: json['translation'],
    );
  }
}

// ===== PROVIDERS =====

class VocabularyProvider extends ChangeNotifier {
  Map<String, List<CategorySection>> levelData = {};
  bool isLoading = true;
  Map<String, dynamic>? _jsonCache;
  SharedPreferences? _prefs;

  VocabularyProvider() {
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    _loadVocabularyData();
  }

  int getLearnedCardCount(String level, String category) {
    if (_prefs == null) return 0;

    int count = 0;
    // Get all keys that match the pattern for this category
    Set<String> allKeys = _prefs!.getKeys();

    // Filter keys that match our pattern for learned cards
    String pattern = '${level}_${category}_';
    for (String key in allKeys) {
      if (key.startsWith(pattern) && key.endsWith('_learned')) {
        bool isLearned = _prefs!.getBool(key) ?? false;
        if (isLearned) {
          count++;
        }
      }
    }

    return count;
  }

// Modify the updateCategoryProgress method to also update the learned count for display
  void updateCategoryProgress(String level, String category, double progress) {
    // Mark category as started
    _prefs?.setBool('${level}_${category}_started', true);

    // Save progress
    _prefs?.setDouble('${level}_${category}_progress', progress);

    // Update in-memory data
    for (var section in levelData[level] ?? []) {
      for (var item in section.items) {
        if (item.category == category) {
          item.progress = progress;
          item.isNotStarted = false;

          // Update the learned count
          item.learnedCount = getLearnedCardCount(level, category);

          notifyListeners();
          return;
        }
      }
    }
  }


  Future<void> _loadVocabularyData() async {
    try {
      isLoading = true;
      notifyListeners();

      await preloadJson();

      // Process each level (A1, A2, B1, etc.)
      _jsonCache!['vocabulary']['levels'].forEach((levelKey, levelValue) {
        List<dynamic> sectionsJson = levelValue['sections'];
        List<CategorySection> sections = [];

        // Process each section
        for (var sectionJson in sectionsJson) {
          String sectionTitle = sectionJson['title'];
          List<dynamic> itemsJson = sectionJson['items'];
          List<CategoryItem> items = [];

          // Process each category item
          for (var itemJson in itemsJson) {
            String category = itemJson['category'];
            String level = itemJson['level'];

            // Get actual count of flashcards in this category from JSON
            int actualCount = 0;
            try {
              actualCount = itemJson['flashcards']?.length ?? 0;
            } catch (e) {
              print('Error getting flashcard count: $e');
              actualCount = itemJson['count']; // Fall back to the static count
            }

            // Load progress from SharedPreferences if available
            double progress = _prefs?.getDouble('${level}_${category}_progress') ??
                itemJson['progress'].toDouble();

            bool isNotStarted = !(_prefs?.getBool('${level}_${category}_started') ?? false);
            if (progress > 0) {
              isNotStarted = false;
            }

            // Calculate learned count from SharedPreferences
            int learnedCount = 0;
            if (_prefs != null && !isNotStarted) {
              // Get all keys that match the pattern for this category
              Set<String> allKeys = _prefs!.getKeys();

              // Filter keys that match our pattern for learned cards
              String pattern = '${level}_${category}_';
              for (String key in allKeys) {
                if (key.startsWith(pattern) && key.endsWith('_learned')) {
                  bool isLearned = _prefs!.getBool(key) ?? false;
                  if (isLearned) {
                    learnedCount++;
                  }
                }
              }
            }

            items.add(CategoryItem(
              icon: _getIconData(itemJson['icon']),
              iconColor: _getColor(itemJson['iconColor']),
              title: itemJson['title'],
              count: actualCount, // Use the actual count instead of the static one
              learnedCount: learnedCount, // Add the learned count
              progress: progress,
              category: category,
              level: level,
              isNotStarted: isNotStarted,
            ));
          }

          sections.add(CategorySection(
            title: sectionTitle,
            items: items,
          ));
        }

        levelData[levelKey] = sections;
      });

      isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error loading vocabulary data: $e');
      isLoading = false;
      notifyListeners();
    }
  }

  // Add a method to mark categories as started
  void markCategoryAsStarted(String level, String category) {
    _prefs?.setBool('${level}_${category}_started', true);

    // Update in-memory data
    for (var section in levelData[level] ?? []) {
      for (var item in section.items) {
        if (item.category == category) {
          item.isNotStarted = false;
          notifyListeners();
          return;
        }
      }
    }
  }

  // Update the updateCategoryProgress method

  Future<void> preloadJson() async {
    if (_jsonCache != null) return;

    try {
      // Load JSON from assets folder
      final String jsonString = await rootBundle.loadString('assets/json/vocabulary.json');
      _jsonCache = json.decode(jsonString);
    } catch (e) {
      print('Error preloading JSON: $e');
      throw Exception('Failed to load JSON data');
    }
  }

  List<FlashcardData> getFlashcardsForCategory(String category, String level) {
    try {
      if (_jsonCache == null) {
        throw Exception('JSON data is not loaded yet');
      }

      // Find the corresponding flashcards in the JSON data
      Map<String, dynamic> levelsJson = _jsonCache!['vocabulary']['levels'];
      List<dynamic> sectionsJson = levelsJson[level]['sections'];

      for (var section in sectionsJson) {
        for (var item in section['items']) {
          if (item['category'] == category) {
            List<dynamic> flashcardsJson = item['flashcards'];
            List<FlashcardData> flashcards = [];

            for (var cardJson in flashcardsJson) {
              List<FlashcardExample> examples = [];

              for (var exampleJson in cardJson['examples']) {
                examples.add(FlashcardExample.fromJson(exampleJson));
              }

              flashcards.add(FlashcardData(
                id: cardJson['id'],
                german: cardJson['german'],
                english: cardJson['english'],
                partOfSpeech: cardJson['partOfSpeech'],
                examples: examples,
                isLearned: cardJson['isLearned'] ?? false,
                isBookmarked: cardJson['isBookmarked'] ?? false,
              ));
            }

            return flashcards;
          }
        }
      }

      // If category not found in JSON, return the fallback data
      return _getFallbackFlashcards(category);
    } catch (e) {
      print('Error getting flashcards: $e');
      return _getFallbackFlashcards(category);
    }
  }

  List<FlashcardData> _getFallbackFlashcards(String category) {
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
                translation: 'I say hello to my friend.',
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
                translation: 'He was killed with a single bullet.',
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

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'waving_hand':
        return Icons.waving_hand;
      case 'family_restroom':
        return Icons.family_restroom;
      case 'home':
        return Icons.home;
      case 'local_drink':
        return Icons.local_drink;
      case 'apple':
        return Icons.apple;
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'directions_walk':
        return Icons.directions_walk;
      case 'medical_services':
        return Icons.medical_services;
      case 'accessibility_new':
        return Icons.accessibility_new;
      case 'work':
        return Icons.work;
      case 'school':
        return Icons.school;
      case 'psychology':
        return Icons.psychology;
      case 'lightbulb':
        return Icons.lightbulb;
      default:
        return Icons.book;
    }
  }

  Color _getColor(String colorHex) {
    if (colorHex.startsWith('#')) {
      return Color(int.parse(colorHex.substring(1), radix: 16) | 0xFF000000);
    }
    return Colors.blue;
  }
}





// ===== UI COMPONENTS =====

class VocabularyCategoryScreen extends StatefulWidget {
  const VocabularyCategoryScreen({Key? key}) : super(key: key);

  @override
  State<VocabularyCategoryScreen> createState() => _VocabularyCategoryScreenState();
}

class _VocabularyCategoryScreenState extends State<VocabularyCategoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<VocabularyProvider>(context, listen: false);
      provider.preloadJson();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VocabularyProvider>(
      builder: (context, vocabularyProvider, child) {
        if (vocabularyProvider.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        return DefaultTabController(
          length: 3,
          child: Scaffold(
            backgroundColor: Colors.grey[50],
            appBar: AppBar(
              title: const Text('German Vocabulary'),
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
            body: const TabBarView(
              children: [
                LevelContentWidget(level: 'A1'),
                LevelContentWidget(level: 'A2'),
                LevelContentWidget(level: 'B1'),
              ],
            ),
          ),
        );
      },
    );
  }
}

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
        )),
      ],
    );
  }
}

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
        ...items.map((item) => CategoryItemWidget(item: item)),
      ],
    );
  }
}



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

    // Consider it not started if learnedCount is 0
    final bool effectivelyNotStarted = item.isNotStarted || item.learnedCount == 0;

    return InkWell(
      onTap: () {
        // Load flashcards and navigate to flashcard screen
        final flashcards = vocabularyProvider.getFlashcardsForCategory(item.category, item.level);
        flashcardProvider.loadFlashcards(item.category, item.level, item.title, flashcards, context);

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
            // Show just the total count number
            Text(
              '${item.count}',  // Just show total count
              style: TextStyle(
                fontSize: 16,
                color: effectivelyNotStarted
                    ? Colors.grey.shade600
                    : item.learnedCount == item.count
                    ? Colors.green
                    : const Color(0xFF3F51B5),
                fontWeight: !effectivelyNotStarted ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 16),
            if (effectivelyNotStarted)
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
                      item.progress == 1.0 ? Colors.green : const Color(0xFF3F51B5),
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



// Update your _buildLearnedButton method in FlashcardScreen

  Widget _buildLearnedButton(FlashcardProvider provider, FlashcardData card) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: card.isLearned ? Colors.green : const Color(0xFF3F51B5),
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () {
          if (!card.isLearned) {
            // Pass context to the markAsLearned method
            provider.markAsLearned(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Marked as learned!',style: TextStyle(color: Colors.white),),
                duration: Duration(seconds: 1),
                backgroundColor: const Color(0xFF3F51B5),
              ),
            );
          }
        },
        child: Text(
          card.isLearned ? 'Learned ✓' : 'Mark as Learned',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }



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

  @override
  void dispose() {
    _flipController.dispose();
    final provider = Provider.of<FlashcardProvider>(context, listen: false);
    provider.removeListener(_onFlipChanged);
    super.dispose();
  }


  // This is the new method to build the learned button

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
                  const Icon(Icons.remove_red_eye, color: Color(0xFF3F51B5), size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${flashcardProvider.wordsViewed}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.check_circle, color: Color(0xFF3F51B5), size: 16),
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
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3F51B5)),
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
                                        gradient: const LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Colors.white,
                                            Color(0xFFF5F7FF),
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
                                                      currentCard.examples[0].translation ?? _getTranslatedExample(currentCard),
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
                                            if (!currentCard.isLearned)
                                              _buildLearnedButton(flashcardProvider, currentCard),
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
    // Here we're using the translation from the JSON if available
    if (card.examples.isEmpty) return '';

    final example = card.examples[0];
    if (example.translation != null) {
      return example.translation!;
    }

    // Fallback translations if not available in JSON
    switch (card.id) {
      case 'greeting_1':
        return "I say hello to my friend.";
      case 'greeting_2':
        return "Good day, Mr. Schmidt!";
      case 'family_1':
        return "My family is very big.";
      case 'family_2':
        return "My mother cooks very well.";
      default:
        return "Translation: ${card.english} ${example.suffix.contains('?') ? '?' : '.'}";
    }
  }
}