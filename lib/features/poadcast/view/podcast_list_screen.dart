import 'package:flutter/material.dart';
import 'dart:ui';

import 'package:job_finder/features/poadcast/view/pod_detail.dart';

class PodcastListScreen extends StatefulWidget {
  final String title;
  final String? level;
  final String? category;

  const PodcastListScreen({
    Key? key,
    required this.title,
    this.level,
    this.category,
  }) : super(key: key);

  @override
  _PodcastListScreenState createState() => _PodcastListScreenState();
}

class _PodcastListScreenState extends State<PodcastListScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _podcasts = [];
  bool _isLoading = true;

  late AnimationController _animationController;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 2000),
    );

    _floatAnimation = Tween<double>(begin: 0, end: 6).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _animationController.forward();
    _animationController.repeat(reverse: true);

    _loadPodcasts();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadPodcasts() async {
    // Simulate loading from API
    await Future.delayed(Duration(milliseconds: 1500));

    // Mock data based on category or level
    setState(() {
      _podcasts = _getMockPodcasts();
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> _getMockPodcasts() {
    if (widget.category == 'True Crime') {
      return [
      {
        'title': 'Crime Junkie',
    'author': 'Ashley Flowers',
    'description': 'Weekly true crime podcast dedicated to giving you a fix of all cases that haunt you most.',
    'image': 'https://images.theabcdn.com/i/39267873',
    'duration': '32 min',
    'rating': 4.8,
    'episodes': 245,
    'color': Color(0xFF3F51B5),
  },
    {
    'title': 'My Favorite Murder',
    'author': 'Karen Kilgariff and Georgia Hardstark',
    'description': 'Lifelong fans of true crime discuss their favorite murder cases.',
    'image': 'https://images.theabcdn.com/i/39267873',
    'duration': '45 min',
    'rating': 4.5,
    'episodes': 325,
    'color': Color(0xFF3F51B5),
    },
    {
    'title': 'Serial',
    'author': 'Sarah Koenig',
    'description': 'Investigative journalism that unfolds one story over the course of a season.',
    'image': 'https://images.theabcdn.com/i/39267873',
    'duration': '40 min',
    'rating': 4.9,
    'episodes': 80,
    'color': Color(0xFF3F51B5),
    },
    {
    'title': 'Criminal',
    'author': 'Phoebe Judge',
    'description': 'Stories of people who',
    'image': 'https://images.theabcdn.com/i/39267873',
    'duration': '28 min',
    'rating': 4.7,
    'episodes': 178,
    'color': Color(0xFF3F51B5),
    },
    {
    'title': 'Casefile',
    'author': 'Anonymous Host',
    'description': 'Explores solved and unsolved cases from around the world with a factual storytelling approach.',
    'image': 'https://images.theabcdn.com/i/39267873',
    'duration': '55 min',
    'rating': 4.6,
    'episodes': 210,
    'color': Color(0xFF3F51B5),
    },
    ];
    } else if (widget.level == 'Popular') {
    return [
    {
    'title': 'The Joe Rogan Experience',
    'author': 'Joe Rogan',
    'description': 'Long-form conversations with guests from all walks of life.',
    'image': 'https://images.theabcdn.com/i/39267873',
    'duration': '180 min',
    'rating': 4.7,
    'episodes': 1850,
    'color': Color(0xFF3F51B5),
    },
    {
    'title': 'This American Life',
    'author': 'Ira Glass',
    'description': 'Weekly public radio program that explores a theme through stories and interviews.',
    'image': 'https://images.theabcdn.com/i/39267873',
    'duration': '65 min',
    'rating': 4.9,
    'episodes': 760,
    'color': Color(0xFF3F51B5),
    },
    {
    'title': 'The Daily',
    'author': 'The New York Times',
    'description': 'Daily news podcast that covers one major story per episode.',
    'image': 'https://images.theabcdn.com/i/39267873',
    'duration': '25 min',
    'rating': 4.8,
    'episodes': 1200,
    'color': Color(0xFF3F51B5),
    },
    {
    'title': 'Stuff You Should Know',
    'author': 'Josh Clark and Chuck Bryant',
    'description': 'Explores a variety of topics to explain how things work.',
    'image': 'https://images.theabcdn.com/i/39267873',
    'duration': '50 min',
    'rating': 4.6,
    'episodes': 1500,
    'color': Color(0xFF3F51B5),
    },
    {
    'title': 'Armchair Expert',
    'author': 'Dax Shepard',
    'description': 'Interviews with celebrities, journalists, and academics about their lives.',
    'image': 'https://images.theabcdn.com/i/39267873',
    'duration': '120 min',
    'rating': 4.5,
    'episodes': 310,
    'color': Color(0xFF3F51B5),
    },
    ];
    } else {
    // Default list for other categories
    return [
    {
    'title': 'RadioLab',
    'author': 'Jad Abumrad & Robert Krulwich',
    'description': 'A show about curiosity where sound illuminates ideas.',
    'image': 'https://images.theabcdn.com/i/39267873',
    'duration': '55 min',
    'rating': 4.8,
    'episodes': 350,
    'color': Color(0xFF3F51B5),
    },
    {
    'title': 'Planet Money',
    'author': 'NPR',
    'description': 'The economy explained with entertaining stories about the world around us.',
    'image': 'https://images.theabcdn.com/i/39267873',
    'duration': '25 min',
    'rating': 4.7,
    'episodes': 1100,
    'color': Color(0xFF3F51B5),
    },
    {
    'title': 'How I Built This',
    'author': 'Guy Raz',
    'description': 'Stories of entrepreneurs and the companies they built.',
    'image': 'https://images.theabcdn.com/i/39267873',
    'duration': '45 min',
    'rating': 4.9,
    'episodes': 275,
    'color': Color(0xFF3F51B5),
    },
    {
    'title': '99% Invisible',
    'author': 'Roman Mars',
    'description': 'A show about all the thought that goes into the things we don',
    'image': 'https://images.theabcdn.com/i/39267873',
    'duration': '35 min',
    'rating': 4.8,
    'episodes': 450,
    'color': Color(0xFF3F51B5),
    },
    {
    'title': 'Freakonomics Radio',
    'author': 'Stephen J. Dubner',
    'description': 'Explores the hidden side of everything, with economic theory applied to everyday topics.',
    'image': 'https://images.theabcdn.com/i/39267873',
    'duration': '45 min',
    'rating': 4.6,
    'episodes': 485,
    'color': Color(0xFF3F51B5),
    },
    ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        physics: BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(),
          _isLoading
              ? SliverFillRemaining(
            child: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF3F51B5),
              ),
            ),
          )
              : _buildPodcastList(),
          SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 150,
      pinned: true,
      backgroundColor: Color(0xFF3F51B5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Background gradient
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
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

            // Animated circles
            AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Stack(
                    children: [
                      Positioned(
                        right: -30,
                        top: -10 + _floatAnimation.value,
                        child: Container(
                          width: 100,
                          height: 100,
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
                          width: 80,
                          height: 80,
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
              bottom: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 6),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_isLoading ? '...' : _podcasts.length} podcasts',
                      style: TextStyle(
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
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.search, color: Colors.white),
          onPressed: () {
            // Implement search functionality
          },
        ),
        IconButton(
          icon: Icon(Icons.filter_list, color: Colors.white),
          onPressed: () {
            // Implement filter functionality
          },
        ),
        SizedBox(width: 8),
      ],
    );
  }

  Widget _buildPodcastList() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          final podcast = _podcasts[index];
          return _buildPodcastCard(podcast);
        },
        childCount: _podcasts.length,
      ),
    );
  }

  Widget _buildPodcastCard(Map<String, dynamic> podcast) {
    return Container(
      margin: EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Navigate to podcast detail when implemented
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PodcastDetailScreen(podcast: podcast),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Podcast cover image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    podcast['image'] as String,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 100,
                        height: 100,
                        color: (podcast['color'] as Color).withOpacity(0.2),
                        child: Center(
                          child: Icon(
                            Icons.headset,
                            size: 40,
                            color: podcast['color'] as Color,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(width: 16),

                // Podcast info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: (podcast['color'] as Color).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.graphic_eq,
                                  size: 12,
                                  color: podcast['color'] as Color,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  podcast['duration'] as String,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: podcast['color'] as Color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Spacer(),
                          Row(
                            children: [
                              Icon(
                                Icons.star,
                                size: 16,
                                color: Colors.amber,
                              ),
                              SizedBox(width: 2),
                              Text(
                                '${podcast['rating']}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        podcast['title'] as String,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Text(
                        podcast['author'] as String,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 8),
                      Text(
                        podcast['description'] as String,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[800],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${podcast['episodes']} episodes',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                          Spacer(),
                          Icon(
                            Icons.play_circle_fill_rounded,
                            size: 32,
                            color: podcast['color'] as Color,
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

