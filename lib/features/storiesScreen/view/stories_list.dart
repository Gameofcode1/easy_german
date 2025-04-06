import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:job_finder/features/storiesScreen/view/stories_player.dart';
import 'dart:ui';

import '../../../core/constants/app_images.dart';

class StoriesListScreen extends StatefulWidget {
  final String title;
  final String? level;
  final String? category;

  StoriesListScreen({
    required this.title,
    this.level,
    this.category,
  });

  @override
  _StoriesListScreenState createState() => _StoriesListScreenState();
}

class _StoriesListScreenState extends State<StoriesListScreen>
    with SingleTickerProviderStateMixin {
  late List<Map<String, dynamic>> _stories;
  bool _isLoading = true;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _floatAnimation;

  // Scroll controller to detect scroll for app bar effects
  final ScrollController _scrollController = ScrollController();
  double _appBarOpacity = 0.0;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 3000), // Match the animation duration
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    // Add floating animation like in StoriesCategoryScreen
    _floatAnimation = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    // Add scroll listener for app bar effects
    _scrollController.addListener(() {
      setState(() {
        // Change opacity based on scroll position
        _appBarOpacity = (_scrollController.offset / 100).clamp(0.0, 1.0);
      });
    });

    _loadStories();

    // Match the animation behavior from StoriesCategoryScreen
    _animationController.forward();
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadStories() async {
    // Simulate loading delay
    await Future.delayed(Duration(milliseconds: 800));

    // Filter stories based on level or category
    if (widget.level != null) {
      _stories = _getStoriesByLevel(widget.level!);
    } else if (widget.category != null) {
      _stories = _getStoriesByCategory(widget.category!);
    } else {
      _stories = _getAllStories();
    }

    setState(() {
      _isLoading = false;
    });
  }

  // Rest of the data methods remain the same
  List<Map<String, dynamic>> _getAllStories() {
    final beginner = _getStoriesByLevel('Beginner');
    final intermediate = _getStoriesByLevel('Intermediate');
    final advanced = _getStoriesByLevel('Advanced');

    return [...beginner, ...intermediate, ...advanced];
  }

  List<Map<String, dynamic>> _getStoriesByLevel(String level) {
    // In a real app, you would fetch this from your database or provider
    switch (level) {
      case 'Beginner':
        return [
          {
            'id': 'b1',
            'title': 'Mein erstes Haustier',
            'description': 'A simple story about getting a first pet.',
            'image': cat,
            'level': 'Beginner',
            'duration': '5 min',
            'favorite': false,
            'content': 'Ich habe ein Haustier. Es ist ein Hund. Mein Hund heißt Max. Max ist sehr freundlich und verspielt. Er hat braunes Fell und große Augen. Jeden Tag gehe ich mit Max spazieren. Wir gehen in den Park. Max spielt gerne mit dem Ball. Er rennt schnell und bringt mir den Ball zurück. Ich liebe mein Haustier sehr.',
          },
          {
            'id': 'b2',
            'title': 'Im Restaurant',
            'description': 'Learn restaurant vocabulary through a simple dialogue.',
            'image': cat,
            'level': 'Beginner',
            'duration': '4 min',
            'favorite': false,
            'content': 'Kellner: Guten Tag! Möchten Sie bestellen?\nPeter: Ja, ich hätte gerne eine Suppe.\nKellner: Welche Suppe möchten Sie? Wir haben Tomatensuppe und Hühnersuppe.\nPeter: Die Tomatensuppe, bitte.\nKellner: Und als Hauptgericht?\nPeter: Ein Schnitzel mit Pommes, bitte.\nKellner: Möchten Sie etwas trinken?\nPeter: Ja, ein Glas Wasser und ein Bier, bitte.\nKellner: Kommt sofort!',
          },
          {
            'id': 'b3',
            'title': 'Meine Familie',
            'description': 'A beginner story about family members.',
            'image': cat,
            'level': 'Beginner',
            'duration': '3 min',
            'favorite': false,
            'content': 'Meine Familie ist klein. Ich habe eine Mutter, einen Vater und eine Schwester. Meine Mutter heißt Anna. Sie ist Lehrerin. Mein Vater heißt Thomas. Er ist Arzt. Meine Schwester heißt Lisa. Sie ist Studentin. Wir wohnen zusammen in einem Haus. Am Wochenende machen wir oft Ausflüge. Wir gehen wandern oder besuchen Museen. Ich liebe meine Familie.',
          },
          {
            'id': 'b4',
            'title': 'Ein Tag in der Stadt',
            'description': 'Follow Max as he explores the city.',
            'image': cat,
            'level': 'Beginner',
            'duration': '6 min',
            'favorite': false,
            'content': 'Heute besuche ich die Stadt. Ich fahre mit dem Bus ins Zentrum. Zuerst gehe ich in ein Café und trinke einen Kaffee. Dann besuche ich ein Museum. Das Museum ist sehr interessant. Nach dem Museum gehe ich einkaufen. Ich kaufe ein Buch und ein T-Shirt. Zum Mittagessen gehe ich in ein Restaurant. Ich esse eine Pizza. Sie schmeckt sehr gut. Am Nachmittag gehe ich in den Park. Im Park gibt es viele Bäume und Blumen. Ich sitze auf einer Bank und lese mein neues Buch. Der Tag in der Stadt ist schön.',
          },
        ];
      case 'Intermediate':
        return [
          {
            'id': 'i1',
            'title': 'Eine Reise nach Berlin',
            'description': 'Join Lisa on her first trip to Berlin.',
            'image': cat,
            'level': 'Intermediate',
            'duration': '8 min',
            'favorite': false,
            'content': 'Letzten Sommer bin ich nach Berlin gefahren. Es war meine erste Reise nach Deutschland. Berlin ist eine sehr große und interessante Stadt. Ich habe viele berühmte Sehenswürdigkeiten besucht: das Brandenburger Tor, den Reichstag und den Berliner Dom. Ich bin auch zur Berliner Mauer gegangen. Das war sehr beeindruckend. Die Menschen in Berlin waren sehr freundlich und hilfsbereit. Das Essen war auch sehr lecker. Ich habe viel Currywurst gegessen. Meine Reise nach Berlin war wunderschön.',
          },
          {
            'id': 'i2',
            'title': 'Der geheimnisvolle Brief',
            'description': 'A mysterious letter arrives for Markus.',
            'image': cat,
            'level': 'Intermediate',
            'duration': '10 min',
            'favorite': false,
            'content': 'Es war ein ganz normaler Montag, als Markus einen seltsamen Brief in seinem Briefkasten fand. Der Brief hatte keinen Absender. Markus öffnete den Umschlag vorsichtig. Darin war ein alter Schlüssel und eine kurze Nachricht: "Kommen Sie um Mitternacht zum alten Bahnhof." Markus war verwirrt. Wer hatte ihm diesen Brief geschickt? Und warum? Er beschloss, zum Bahnhof zu gehen. Um Mitternacht stand er vor dem verlassenen Gebäude. Plötzlich hörte er Schritte hinter sich...',
          },
          {
            'id': 'i3',
            'title': 'Das Vorstellungsgespräch',
            'description': 'Anna prepares for an important job interview.',
            'image': cat,
            'level': 'Intermediate',
            'duration': '7 min',
            'favorite': false,
            'content': 'Anna war nervös. Morgen hatte sie ein wichtiges Vorstellungsgespräch bei einer großen Firma. Sie hatte sich gut vorbereitet. Ihr Lebenslauf war perfekt und sie hatte viele Informationen über die Firma gesammelt. Am nächsten Morgen stand Anna früh auf. Sie zog ihr bestes Kleid an und ging zum Bürogebäude. Das Gespräch begann pünktlich um 10 Uhr. Die Personalchefin stellte viele Fragen. Anna antwortete ruhig und selbstbewusst. Nach 30 Minuten war das Gespräch vorbei. Zwei Tage später erhielt Anna einen Anruf: Sie hatte den Job bekommen!',
          },
        ];
      case 'Advanced':
        return [
          {
            'id': 'a1',
            'title': 'Die Entscheidung',
            'description': 'A complex tale about making difficult life choices.',
            'image': cat,
            'level': 'Advanced',
            'duration': '15 min',
            'favorite': false,
            'content': 'Die Entscheidung, die Thomas treffen musste, war alles andere als einfach. Sie würde sein gesamtes Leben verändern. Seit fünf Jahren arbeitete er bei einer renommierten Anwaltskanzlei in München. Nun hatte er ein Jobangebot von einer internationalen Firma in Berlin erhalten. Das Gehalt war besser, die Arbeit interessanter. Aber ein Umzug würde bedeuten, seine Freunde und seine Familie zurückzulassen. Thomas verbrachte Tage damit, über die Vor- und Nachteile nachzudenken. Schließlich traf er eine Entscheidung, die ihn überraschte...',
          },
          {
            'id': 'a2',
            'title': 'Der verlorene Schlüssel',
            'description': 'A mystery story with complex vocabulary.',
            'image': cat,
            'level': 'Advanced',
            'duration': '12 min',
            'favorite': false,
            'content': 'Die alte Villa am Stadtrand hatte seit Jahrzehnten leer gestanden. Niemand traute sich hinein, bis eines Tages ein junger Historiker namens Felix beschloss, das Geheimnis des Hauses zu lüften. Die Legende besagte, dass der letzte Besitzer einen wertvollen Schatz versteckt hatte, bevor er unter mysteriösen Umständen verschwand. Der Schlüssel zu diesem Schatz sei irgendwo im Haus verborgen. Felix betrat die Villa mit einer Mischung aus Neugierde und Angst. Staub bedeckte die antiken Möbel, Spinnweben hingen von der Decke. Als er das Arbeitszimmer erreichte, entdeckte er ein altes Buch auf dem Schreibtisch...',
          },
          {
            'id': 'a3',
            'title': 'Zwischen den Welten',
            'description': 'A philosophical journey between reality and dreams.',
            'image': cat,
            'level': 'Advanced',
            'duration': '20 min',
            'favorite': false,
            'content': 'Professor Weber hatte sein ganzes Leben der Erforschung des menschlichen Bewusstseins gewidmet. Seine neueste Theorie besagte, dass die Grenze zwischen Traum und Realität fließender sei als allgemein angenommen. Um diese Theorie zu beweisen, entwickelte er eine Maschine, die es ermöglichte, kontrolliert in den Traumzustand einzutreten und diesen bewusst zu steuern. Nach jahrelanger Arbeit war die Maschine endlich fertig. Weber entschloss sich, der erste Proband zu sein. Doch als er die Maschine aktivierte, geschah etwas Unerwartetes. Die Grenzen zwischen seinen Träumen und der Wirklichkeit begannen zu verschwimmen...',
          },
        ];
      default:
        return [];
    }
  }

  List<Map<String, dynamic>> _getStoriesByCategory(String category) {
    // In a real app, you would fetch this from your database or provider
    switch (category) {
      case 'Everyday Life':
        return [
          {
            'id': 'c1',
            'title': 'Ein Tag im Leben',
            'description': 'Follow Marie through her daily routine.',
            'image': cat,
            'level': 'Beginner',
            'duration': '5 min',
            'favorite': false,
            'content': 'Marie steht jeden Tag um 7 Uhr auf. Zuerst nimmt sie eine Dusche. Dann frühstückt sie. Zum Frühstück isst sie Müsli mit Obst und trinkt einen Kaffee. Um 8:30 Uhr geht sie aus dem Haus. Sie fährt mit dem Fahrrad zur Arbeit. Marie arbeitet in einer Bücherei. Sie liebt Bücher und hilft gerne den Kunden. Um 13 Uhr macht sie Mittagspause. Nach der Arbeit geht sie oft ins Fitnessstudio. Abends kocht sie gerne. Nach dem Abendessen schaut sie Netflix oder liest ein Buch. Sie geht normalerweise um 23 Uhr ins Bett.',
          },
          {
            'id': 'c2',
            'title': 'Meine Wohnung',
            'description': 'Learn vocabulary about apartments and furniture.',
            'image': cat,
            'level': 'Beginner',
            'duration': '4 min',
            'favorite': false,
            'content': 'Meine Wohnung liegt im zweiten Stock eines alten Gebäudes. Sie ist nicht sehr groß, aber gemütlich. Es gibt ein Wohnzimmer, ein Schlafzimmer, eine Küche und ein Badezimmer. Im Wohnzimmer steht ein Sofa, ein Couchtisch und ein Bücherregal. Es gibt auch einen Fernseher. Mein Schlafzimmer ist klein. Dort stehen nur ein Bett und ein Kleiderschrank. Die Küche ist modern mit einem neuen Herd und einem Kühlschrank. Das Badezimmer hat eine Dusche, aber keine Badewanne. Meine Wohnung hat auch einen kleinen Balkon. Dort habe ich viele Pflanzen.',
          },
        ];
      case 'Travel':
        return [
          {
            'id': 'c3',
            'title': 'Eine Reise nach Berlin',
            'description': 'Join Lisa on her first trip to Berlin.',
            'image': 'cat',
            'level': 'Intermediate',
            'duration': '8 min',
            'favorite': false,
            'content': 'Letzten Sommer bin ich nach Berlin gefahren. Es war meine erste Reise nach Deutschland. Berlin ist eine sehr große und interessante Stadt. Ich habe viele berühmte Sehenswürdigkeiten besucht: das Brandenburger Tor, den Reichstag und den Berliner Dom. Ich bin auch zur Berliner Mauer gegangen. Das war sehr beeindruckend. Die Menschen in Berlin waren sehr freundlich und hilfsbereit. Das Essen war auch sehr lecker. Ich habe viel Currywurst gegessen. Meine Reise nach Berlin war wunderschön.',
          },
          {
            'id': 'c4',
            'title': 'Am Bahnhof',
            'description': 'Learn useful phrases for train travel.',
            'image': cat,
            'level': 'Beginner',
            'duration': '6 min',
            'favorite': false,
            'content': 'Ich bin am Bahnhof. Mein Zug fährt in 30 Minuten ab. Ich gehe zum Ticketschalter, um eine Fahrkarte zu kaufen. "Eine Fahrkarte nach München, bitte." "Einfach oder hin und zurück?" "Hin und zurück, bitte." "Das macht 56 Euro." Ich bezahle und nehme mein Ticket. Dann schaue ich auf die Anzeigetafel. Mein Zug fährt von Gleis 7 ab. Ich habe noch Zeit, also kaufe ich mir einen Kaffee und eine Zeitung. Dann gehe ich zu Gleis 7 und warte auf meinen Zug. Der Zug kommt pünktlich an.',
          },
        ];
      case 'Food & Dining':
        return [
          {
            'id': 'f1',
            'title': 'Im Restaurant',
            'description': 'Learn restaurant vocabulary through a simple dialogue.',
            'image': cat,
            'level': 'Beginner',
            'duration': '4 min',
            'favorite': false,
            'content': 'Kellner: Guten Tag! Möchten Sie bestellen?\nPeter: Ja, ich hätte gerne eine Suppe.\nKellner: Welche Suppe möchten Sie? Wir haben Tomatensuppe und Hühnersuppe.\nPeter: Die Tomatensuppe, bitte.\nKellner: Und als Hauptgericht?\nPeter: Ein Schnitzel mit Pommes, bitte.\nKellner: Möchten Sie etwas trinken?\nPeter: Ja, ein Glas Wasser und ein Bier, bitte.\nKellner: Kommt sofort!',
          },
        ];
      default:
        return [];
    }
  }

  Color _getLevelColor(String level) {
    // Using the same colors as in StoriesCategoryScreen
    switch (level) {
      case 'Beginner':
        return Color(0xFF4CAF50);
      case 'Intermediate':
        return Color(0xFFFF9800);
      case 'Advanced':
        return Color(0xFFF44336);
      default:
        return Color(0xFF2196F3);
    }
  }

  void _toggleFavorite(int index) {
    setState(() {
      _stories[index]['favorite'] = !_stories[index]['favorite'];
    });

    // Add a haptic feedback
    HapticFeedback.lightImpact();

    // Show a snackbar for feedback - keeping this from your improved design
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _stories[index]['favorite']
              ? 'Added to favorites'
              : 'Removed from favorites',
          style: TextStyle(color: Colors.white),
        ),
        duration: Duration(seconds: 1),
        backgroundColor: Color(0xFF424242),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      body: _isLoading
          ? _buildLoadingState()
          : Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            physics: BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(),
              _buildSectionTitle('Continue Learning'),
              if (_stories.isNotEmpty) _buildFeaturedStory(_stories[0]),
              _buildSectionTitle('All Stories'),
              _buildStoryList(),
              SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
          // Floating search button - keeping your implementation but matching color

        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Custom loading animation
          Container(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3F51B5)), // Indigo color
              strokeWidth: 3,
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Loading Stories...',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF757575),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    // Following the design pattern of StoriesCategoryScreen with rounded bottom corners
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: _appBarOpacity > 0.5
          ? Color(0xFF3F51B5) // Indigo color
          : Colors.transparent,
      elevation: _appBarOpacity > 0.5 ? 4 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      stretch: true,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: EdgeInsets.only(left: 20, bottom: 16),
        title: AnimatedOpacity(
          opacity: _appBarOpacity < 0.5 ? 1.0 : 0.0,
          duration: Duration(milliseconds: 300),
          child: Text(
            widget.title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 24,
              shadows: [
                Shadow(
                  offset: Offset(0, 1),
                  blurRadius: 3,
                  color: Colors.black.withOpacity(0.3),
                ),
              ],
            ),
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Background gradient - using indigo colors from StoriesCategoryScreen
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
            // Animated decorative shapes like in StoriesCategoryScreen
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
                      // Tiny circles for a starry effect
                      ...List.generate(12, (index) {
                        return Positioned(
                          left: 50.0 + (index * 25) % 300,
                          top: 20.0 + (index * 30) % 150,
                          child: Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                          ),
                        );
                      }),
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
            // Header content

          ],
        ),
      ),
      actions: [
        // Profile icon - keeping this from your design
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: CircleAvatar(
            backgroundColor: Colors.white.withOpacity(0.2),
            radius: 18,
            child: Icon(
              Icons.person,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
        SizedBox(width: 8),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    // Using the section title design from StoriesCategoryScreen
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 30, 20, 16),
        child: Row(
          children: [
            Container(
              height: 32,
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Color(0xFF3F51B5), // Indigo color
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF3F51B5).withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    title.contains('All') ? Icons.explore : Icons.play_circle_outline,
                    color: Colors.white,
                    size: 16,
                  ),
                  SizedBox(width: 6),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // If it's the "All Stories" section, add a filter button
            if (title == 'All Stories')
              Spacer(),
            if (title == 'All Stories')
              TextButton.icon(
                onPressed: () {
                  // Implement filter functionality
                },
                icon: Icon(
                  Icons.filter_list,
                  size: 18,
                  color: Color(0xFF3F51B5),
                ),
                label: Text(
                  'Filter',
                  style: TextStyle(
                    color: Color(0xFF3F51B5),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedStory(Map<String, dynamic> story) {
    // Enhanced featured story with animated elements like in StoriesCategoryScreen
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: GestureDetector(
          onTap: () {
            // Replace your navigation code in both _buildFeaturedStory and _buildStoryCard methods
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) {
                  // Create dummy story items similar to the screenshot
                  final List<StoryItem> storyItems = [
                    StoryItem(
                        germanText: "Anna und Tim lieben die Natur.",
                        englishText: "Anna and Tim love nature."
                    ),
                    StoryItem(
                        germanText: "An einem sonnigen Samstagmorgen beschließen sie zu wandern.",
                        englishText: "On a sunny Saturday morning, they decide to go hiking."
                    ),
                    StoryItem(
                        germanText: "Sie packen Wasserflaschen, Sandwiches und Rucksäcke.",
                        englishText: "They pack water bottles, sandwiches, and backpacks."
                    ),
                    StoryItem(
                        germanText: "Dann gehen sie in den Wald.",
                        englishText: "Then they head into the forest."
                    ),
                    StoryItem(
                        germanText: "Der Wald ist ruhig.",
                        englishText: "The forest is quiet."
                    ),
                    // Add more story items based on the actual content
                    StoryItem(
                        germanText: "Sie hören Vögel singen.",
                        englishText: "They hear birds singing."
                    ),
                    StoryItem(
                        germanText: "Die frische Luft tut ihnen gut.",
                        englishText: "The fresh air feels good to them."
                    ),
                  ];

                  return StoryDetailScreen(
                    title: story['title'],
                    storyItems: storyItems,
                    level: story['level'],
                    duration: story['duration'],
                    description: story['description'],
                  );
                },
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
                transitionDuration: Duration(milliseconds: 300),
              ),
            );
          },
          child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _floatAnimation.value / 3), // Subtle floating effect
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Background image
                          Image.asset(
                            story['image'],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[300],
                                child: Icon(
                                  Icons.image_not_supported,
                                  size: 50,
                                  color: Colors.grey[500],
                                ),
                              );
                            },
                          ),
                          // Glass effect overlay
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: ClipRRect(
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                child: Container(
                                  padding: EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.3),
                                    borderRadius: BorderRadius.only(
                                      bottomLeft: Radius.circular(24),
                                      bottomRight: Radius.circular(24),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          'FEATURED',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        story['title'],
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Container(
                                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: _getLevelColor(story['level']),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              story['level'],
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 12),
                                          Icon(
                                            Icons.access_time,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            story['duration'],
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
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
                          // Play button overlay - with animation like in StoriesCategoryScreen
                          Positioned(
                            top: 0,
                            right: 0,
                            bottom: 0,
                            child: Center(
                              child: Container(
                                margin: EdgeInsets.only(right: 20),
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.play_arrow,
                                  color: Color(0xFF3F51B5), // Indigo color
                                  size: 30,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
          ),
        ),
      ),
    );
  }

  Widget _buildStoryList() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          // Skip the first item as it's used as featured
          if (index == 0) return SizedBox.shrink();

          final story = _stories[index];
          return  _buildStoryCard(story, index);
        },
        childCount: _stories.length,
      ),
    );
  }

  Widget _buildStoryCard(Map<String, dynamic> story, int index) {
    // Enhanced card design matching the StoriesCategoryScreen style
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Card(
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Replace your navigation code in both _buildFeaturedStory and _buildStoryCard methods
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) {
                  // Create dummy story items similar to the screenshot
                  final List<StoryItem> storyItems = [
                    StoryItem(
                        germanText: "Anna und Tim lieben die Natur.",
                        englishText: "Anna and Tim love nature."
                    ),
                    StoryItem(
                        germanText: "An einem sonnigen Samstagmorgen beschließen sie zu wandern.",
                        englishText: "On a sunny Saturday morning, they decide to go hiking."
                    ),
                    StoryItem(
                        germanText: "Sie packen Wasserflaschen, Sandwiches und Rucksäcke.",
                        englishText: "They pack water bottles, sandwiches, and backpacks."
                    ),
                    StoryItem(
                        germanText: "Dann gehen sie in den Wald.",
                        englishText: "Then they head into the forest."
                    ),
                    StoryItem(
                        germanText: "Der Wald ist ruhig.",
                        englishText: "The forest is quiet."
                    ),
                    // Add more story items based on the actual content
                    StoryItem(
                        germanText: "Sie hören Vögel singen.",
                        englishText: "They hear birds singing."
                    ),
                    StoryItem(
                        germanText: "Die frische Luft tut ihnen gut.",
                        englishText: "The fresh air feels good to them."
                    ),
                  ];

                  return StoryDetailScreen(
                    title: story['title'],
                    storyItems: storyItems,
                    level: story['level'],
                    duration: story['duration'],
                    description: story['description'],
                  );
                },
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
                transitionDuration: Duration(milliseconds: 300),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail image with animated play button
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 80,
                    height: 80,
                    child: Stack(
                      children: [
                        Image.asset(
                          story['image'],
                          fit: BoxFit.cover,
                          width: 80,
                          height: 80,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300],
                              child: Icon(
                                Icons.image_not_supported,
                                size: 30,
                                color: Colors.grey[500],
                              ),
                            );
                          },
                        ),
                        // Small play button with animation
                        Positioned.fill(
                          child: Container(
                            color: Colors.black.withOpacity(0.2),
                            child: Center(
                              child: Container(
                                width: 30 + (_floatAnimation.value / 8),
                                height: 30 + (_floatAnimation.value / 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.8),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.play_arrow,
                                  color: Color(0xFF3F51B5), // Indigo color
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 16),
                // Story details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        story['title'],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF212121),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        story['description'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF757575),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          // Level pill
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getLevelColor(story['level']).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              story['level'],
                              style: TextStyle(
                                color: _getLevelColor(story['level']),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(
                            Icons.access_time,
                            color: Color(0xFF757575),
                            size: 12,
                          ),
                          SizedBox(width: 4),
                          Text(
                            story['duration'],
                            style: TextStyle(
                              color: Color(0xFF757575),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Favorite button with animation
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => _toggleFavorite(index),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: story['favorite']
                                ? 1.0 + (_floatAnimation.value / 100)
                                : 1.0,
                            child: AnimatedContainer(
                              duration: Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                              child: Icon(
                                story['favorite'] ? Icons.favorite : Icons.favorite_border,
                                color: story['favorite'] ? Colors.red : Color(0xFFBDBDBD),
                                size: 22,
                              ),
                            ),
                          );
                        }
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