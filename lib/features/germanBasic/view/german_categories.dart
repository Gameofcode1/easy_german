import 'package:flutter/material.dart';
import '../viewmodel/german_basic.dart';

class GermanCategoryDetailScreen extends StatefulWidget {
  final String title;
  final Color color;
  final IconData icon;
  final List<Map<String, dynamic>> items;
  final GermanBasicsModel model; // Add model parameter for TTS

  const GermanCategoryDetailScreen({
    Key? key,
    required this.title,
    required this.color,
    required this.icon,
    required this.items,
    required this.model,
  }) : super(key: key);

  @override
  State<GermanCategoryDetailScreen> createState() =>
      _GermanCategoryDetailScreenState();
}

class _GermanCategoryDetailScreenState
    extends State<GermanCategoryDetailScreen> {
  late ScrollController _scrollController;
  bool _isAppBarExpanded = true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()
      ..addListener(() {
        setState(() {
          _isAppBarExpanded = _scrollController.hasClients &&
              _scrollController.offset < (200 - kToolbarHeight);
        });
      });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    // Stop any playing speech when leaving the screen
    widget.model.stopSpeaking();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(),
          _buildContent(),
        ],
      ),
    );
  }

  // Method to speak all items in sequence
  void _speakAllItems() {
    if (widget.items.isEmpty) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Playing all ${widget.title} items'),
        duration: const Duration(seconds: 2),
      ),
    );

    // Speak the first item
    final item = widget.items[0];
    widget.model.speak(
      item['german'],
      context: context,
      showFeedback: false,
    );

    // TODO: In a real implementation, you would use callbacks to
    // speak each item in sequence after the previous finishes
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      stretch: true,
      backgroundColor: widget.color,
      leading: Padding(
        padding: const EdgeInsets.only(left: 8.0),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: _isAppBarExpanded
            ? null
            : Text(
                widget.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Background gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    widget.color.withOpacity(0.8),
                    widget.color,
                  ],
                ),
              ),
            ),

            // Pattern
            Positioned(
              right: -50,
              bottom: -50,
              child: Icon(
                widget.icon,
                size: 200,
                color: Colors.white.withOpacity(0.2),
              ),
            ),

            // Content
            Positioned(
              left: 20,
              bottom: 40,
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
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
                        child: Text(
                          widget.items.isEmpty
                              ? 'Coming soon'
                              : '${widget.items.length} items to learn',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  // Sound icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: widget.model.isSpeaking
                          ? const Icon(Icons.volume_off, color: Colors.white)
                          : const Icon(Icons.volume_up, color: Colors.white),
                      onPressed: () {
                        if (widget.model.isSpeaking) {
                          widget.model.stopSpeaking();
                        } else {
                          // Speak the category title using TTS
                          widget.model.speak(
                            widget.title,
                            context: context,
                          );
                        }
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
  }

  Widget _buildContent() {
    if (widget.items.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.construction_rounded,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Coming Soon',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'We\'re working on this content',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final item = widget.items[index];
            return _buildItemCard(
              german: item['german'],
              english: item['english'],
              example: item['example'],
              index: index,
            );
          },
          childCount: widget.items.length,
        ),
      ),
    );
  }

  Widget _buildItemCard({
    required String german,
    required String english,
    required String example,
    required int index,
  }) {
    // Create a different shade for each card
    final Color cardColor = Color.lerp(
      Colors.white,
      widget.color.withOpacity(0.1),
      (index % 3) * 0.2,
    )!;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 3),
            blurRadius: 6,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              // Show detailed view of item
              _showDetailedView(german, english, example);
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Number indicator
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: widget.color,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              german,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: widget.color,
                              ),
                            ),
                            IconButton(
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                              icon: widget.model.isSpeaking
                                  ? Icon(
                                      Icons.volume_off,
                                      color: widget.color,
                                      size: 20,
                                    )
                                  : Icon(
                                      Icons.volume_up,
                                      color: widget.color,
                                      size: 20,
                                    ),
                              onPressed: () {
                                if (widget.model.isSpeaking) {
                                  widget.model.stopSpeaking();
                                } else {
                                  // Use TTS to speak the German word
                                  widget.model.speak(
                                    german,
                                    context: context,
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          english,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Example: $example',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                              icon: Icon(
                                Icons.volume_up,
                                color: Colors.grey[400],
                                size: 16,
                              ),
                              onPressed: () {
                                // Extract just the German part of the example
                                final germanExample =
                                    example.split('(')[0].trim();
                                widget.model.speak(
                                  germanExample,
                                  context: context,
                                );
                              },
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
      ),
    );
  }

  void _showDetailedView(String german, String english, String example) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            // Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey[200]!,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.icon,
                      color: widget.color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: widget.color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Detailed View',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              german,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              english,
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: widget.color.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(
                              widget.model.isSpeaking
                                  ? Icons.volume_off
                                  : Icons.volume_up,
                              color: widget.color,
                              size: 30,
                            ),
                            onPressed: () {
                              if (widget.model.isSpeaking) {
                                widget.model.stopSpeaking();
                              } else {
                                // Use TTS to speak the German word
                                widget.model.speak(
                                  german,
                                  context: context,
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),

                    // Example section
                    Text(
                      'Example',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: widget.color,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: widget.color.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: widget.color.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.format_quote,
                            color: widget.color,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  example,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                GestureDetector(
                                  onTap: () {
                                    // Extract just the German part of the example
                                    final germanExample =
                                        example.split('(')[0].trim();
                                    widget.model.speak(
                                      germanExample,
                                      context: context,
                                    );
                                  },
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.play_circle_outline,
                                        color: widget.color,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Play Example',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: widget.color,
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
                    const SizedBox(height: 30),

                    // Additional examples
                    Text(
                      'More Examples',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: widget.color,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            offset: const Offset(0, 2),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildExampleItem(
                            example: _generateAdditionalExample(german, 1),
                            onTap: () {
                              widget.model.speak(
                                _generateAdditionalExample(german, 1)
                                    .split('(')[0]
                                    .trim(),
                                context: context,
                              );
                            },
                          ),
                          const Divider(),
                          _buildExampleItem(
                            example: _generateAdditionalExample(german, 2),
                            onTap: () {
                              widget.model.speak(
                                _generateAdditionalExample(german, 2)
                                    .split('(')[0]
                                    .trim(),
                                context: context,
                              );
                            },
                          ),
                          const Divider(),
                          _buildExampleItem(
                            example: _generateAdditionalExample(german, 3),
                            onTap: () {
                              widget.model.speak(
                                _generateAdditionalExample(german, 3)
                                    .split('(')[0]
                                    .trim(),
                                context: context,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Practice button
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPronunciationItem({
    required String text,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: widget.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: widget.color,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[300],
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExampleItem({
    required String example,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                example,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.volume_up,
              color: widget.color,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to generate additional examples
  String _generateAdditionalExample(String germanWord, int index) {
    // This is a simple example generator
    // In a real app, these would come from a database or API

    if (widget.title == 'Numbers') {
      switch (index) {
        case 1:
          return 'Ich brauche $germanWord Äpfel. (I need $germanWord apples.)';
        case 2:
          return 'Es gibt $germanWord Katzen im Garten. (There are $germanWord cats in the garden.)';
        case 3:
          return 'Wir haben $germanWord Stunden Zeit. (We have $germanWord hours of time.)';
      }
    } else if (widget.title == 'Colors') {
      switch (index) {
        case 1:
          return 'Mein Lieblingshemd ist $germanWord. (My favorite shirt is $germanWord.)';
        case 2:
          return 'Die Wand ist $germanWord gestrichen. (The wall is painted $germanWord.)';
        case 3:
          return 'Ich mag die $germanWord Blumen. (I like the $germanWord flowers.)';
      }
    } else if (widget.title == 'Months') {
      switch (index) {
        case 1:
          return 'Im $germanWord fahre ich in den Urlaub. (In $germanWord I go on vacation.)';
        case 2:
          return 'Der $germanWord hat 30 Tage. ($germanWord has 30 days.)';
        case 3:
          return 'Im $germanWord ist das Wetter schön. (The weather is nice in $germanWord.)';
      }
    }

    // Generic examples for other categories
    switch (index) {
      case 1:
        return 'Ich lerne das Wort "$germanWord". (I am learning the word "$germanWord".)';
      case 2:
        return '"$germanWord" ist ein wichtiges Wort. ("$germanWord" is an important word.)';
      case 3:
        return 'Kannst du "$germanWord" sagen? (Can you say "$germanWord"?)';
      default:
        return 'Beispiel mit $germanWord. (Example with $germanWord.)';
    }
  }
}
