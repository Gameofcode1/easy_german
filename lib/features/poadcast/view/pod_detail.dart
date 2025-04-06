import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../model/poascast_vm.dart';

class PodcastDetailScreen extends StatefulWidget {
  final Map<String, dynamic> podcast;

  const PodcastDetailScreen({
    Key? key,
    required this.podcast,
  }) : super(key: key);

  @override
  _PodcastDetailScreenState createState() => _PodcastDetailScreenState();
}

class _PodcastDetailScreenState extends State<PodcastDetailScreen>
    with TickerProviderStateMixin {
  late PodcastPlayerViewModel viewModel;
  bool isInitialized = false;

  @override
  void initState() {
    super.initState();

    // Initialize the ViewModel
    viewModel = PodcastPlayerViewModel(podcast: widget.podcast);

    // Initialize animations - ensure this happens first
    viewModel.initAnimationControllers(this);

    // Initialize TTS after animations are set up - use post frame callback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      viewModel.initTts();
      setState(() {
        isInitialized = true;
      });
    });
  }

  @override
  void dispose() {
    viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Color(0xFF3F51B5);

    // Provide the ViewModel to the widget tree
    return ChangeNotifierProvider.value(
      value: viewModel,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        body: SafeArea(
          child: Column(
            children: [
              _buildAppBar(primaryColor),
              Expanded(
                child: isInitialized
                    ? SingleChildScrollView(
                  physics: BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      _buildPodcastInfo(primaryColor),
                      _buildAnimatedCharacters(primaryColor),
                      _buildSubtitles(primaryColor),
                      _buildProgressBar(primaryColor),
                      _buildControlButtons(primaryColor),
                      SizedBox(height: 20),
                      _buildEpisodeInfo(primaryColor),
                    ],
                  ),
                )
                    : Center(
                  child: CircularProgressIndicator(
                    color: primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(Color primaryColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios, color: primaryColor),
            onPressed: () => Navigator.pop(context),
          ),
          Spacer(),
          IconButton(
            icon: Icon(Icons.share, color: primaryColor),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.playlist_add, color: primaryColor),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildPodcastInfo(Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Podcast image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              widget.podcast['image'] as String,
              width: 120,
              height: 120,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 120,
                  height: 120,
                  color: primaryColor.withOpacity(0.2),
                  child: Center(
                    child: Icon(
                      Icons.headset,
                      color: primaryColor,
                      size: 50,
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(width: 20),

          // Podcast details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.podcast['title'] as String,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  widget.podcast['author'] as String,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 18),
                    SizedBox(width: 4),
                    Text(
                      '${widget.podcast['rating']}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(width: 16),
                    Icon(Icons.headset, color: Colors.grey[600], size: 18),
                    SizedBox(width: 4),
                    Text(
                      '${widget.podcast['episodes']} episodes',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedCharacters(Color primaryColor) {
    return Consumer<PodcastPlayerViewModel>(
      builder: (context, model, child) {
        return Container(
          height: 220,
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: primaryColor.withOpacity(0.1),
              width: 2,
            ),
          ),
          margin: EdgeInsets.symmetric(horizontal: 20),
          child: Stack(
            children: [
              // Background audio wave - only if controllers are initialized
              if (model.areControllersInitialized)
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: model.waveController,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: AudioWavePainter(
                          waveOffset: model.waveAnimation.value,
                          color: primaryColor.withOpacity(0.1),
                        ),
                      );
                    },
                  ),
                ),

              // Character 1 (Left)
              if (model.areControllersInitialized)
                Positioned(
                  left: 20,
                  bottom: 20,
                  child: AnimatedBuilder(
                    animation: model.characterAnimController1,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: model.currentSpeaker == 1 ? model.speakingAnimation1.value : 1.0,
                        alignment: Alignment.bottomCenter,
                        child: Column(
                          children: [
                            // Character face
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.8),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryColor.withOpacity(0.3),
                                    blurRadius: 10,
                                    offset: Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: _buildFaceFeatures(
                                  eyeColor: Colors.white,
                                  mouthColor: Colors.white,
                                  isActive: model.currentSpeaker == 1 && model.isPlaying,
                                ),
                              ),
                            ),
                            SizedBox(height: 8),
                            // Character name
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 5,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                'Anna',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

              // Character 2 (Right)
              if (model.areControllersInitialized)
                Positioned(
                  right: 20,
                  bottom: 20,
                  child: AnimatedBuilder(
                    animation: model.characterAnimController2,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: model.currentSpeaker == 2 ? model.speakingAnimation2.value : 1.0,
                        alignment: Alignment.bottomCenter,
                        child: Column(
                          children: [
                            // Character face
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: Color(0xFF3F51B5).withOpacity(0.8), // Different color for second character
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xFF3F51B5).withOpacity(0.3),
                                    blurRadius: 10,
                                    offset: Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: _buildFaceFeatures(
                                  eyeColor: Colors.white,
                                  mouthColor: Colors.white,
                                  isActive: model.currentSpeaker == 2 && model.isPlaying,
                                ),
                              ),
                            ),
                            SizedBox(height: 8),
                            // Character name
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 5,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                'Max',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF3F51B5),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

              // Speech bubble
              Positioned(
                top: 30,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 250,
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 5,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      model.currentGermanText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: model.currentSpeaker == 1 ? primaryColor : Color(0xFF3F51B5),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFaceFeatures({required Color eyeColor, required Color mouthColor, required bool isActive}) {
    return Stack(
      children: [
        // Eyes
        Positioned(
          top: 35,
          left: 25,
          child: Container(
            width: 10,
            height: isActive ? 5 : 10,
            decoration: BoxDecoration(
              color: eyeColor,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ),
        Positioned(
          top: 35,
          right: 25,
          child: Container(
            width: 10,
            height: isActive ? 5 : 10,
            decoration: BoxDecoration(
              color: eyeColor,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ),

        // Mouth
        Positioned(
          bottom: 30,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              width: isActive ? 30 : 20,
              height: isActive ? 15 : 8,
              decoration: BoxDecoration(
                color: mouthColor,
                borderRadius: BorderRadius.circular(isActive ? 10 : 4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubtitles(Color primaryColor) {
    return Consumer<PodcastPlayerViewModel>(
      builder: (context, model, child) {
        return Container(
          margin: EdgeInsets.fromLTRB(20, 16, 20, 0),
          padding: EdgeInsets.all(16),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'English:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 8),
              Text(
                model.currentEnglishText,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressBar(Color primaryColor) {
    return Consumer<PodcastPlayerViewModel>(
      builder: (context, model, child) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Column(
            children: [
              // Progress indicator without slider functionality
              Container(
                height: 4,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    double maxWidth = constraints.maxWidth;
                    double progressWidth = (model.currentPosition / model.totalDuration) * maxWidth;
                    return Container(
                      width: progressWidth,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      model.formatTime(model.currentPosition),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      model.formatTime(model.totalDuration.toDouble()),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildControlButtons(Color primaryColor) {
    return Consumer<PodcastPlayerViewModel>(
      builder: (context, model, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(Icons.replay_10, color: primaryColor, size: 32),
              onPressed: () => model.skipBackward(),
            ),
            SizedBox(width: 12),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primaryColor,
                    primaryColor.withOpacity(0.8),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.3),
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(
                  model.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 32,
                ),
                onPressed: () => model.togglePlayPause(),
              ),
            ),
            SizedBox(width: 12),
            IconButton(
              icon: Icon(Icons.forward_10, color: primaryColor, size: 32),
              onPressed: () => model.skipForward(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEpisodeInfo(Color primaryColor) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      padding: EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Episode: Deutsche Gespräche für Anfänger',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'This episode features common German conversations to help beginners practice their listening and speaking skills with natural dialogue.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              _buildInfoChip(Icons.calendar_today, 'April 1, 2025', primaryColor),
              SizedBox(width: 12),
              _buildInfoChip(Icons.access_time, widget.podcast['duration'], primaryColor),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              _buildActionButton('Download', Icons.download, primaryColor),
              SizedBox(width: 12),
              _buildActionButton('Share', Icons.share, primaryColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String text, IconData icon, Color color) {
    return Expanded(
      child: ElevatedButton.icon(
        onPressed: () {},
        icon: Icon(icon, size: 18),
        label: Text(text),
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: color,
          padding: EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}

class AudioWavePainter extends CustomPainter {
  final double waveOffset;
  final Color color;

  AudioWavePainter({
    required this.waveOffset,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();

    // Draw first wave
    path.moveTo(0, size.height * 0.5);

    for (double i = 0; i <= size.width; i++) {
      path.lineTo(
          i,
          size.height * 0.5 +
              sin((i / size.width * 4 * pi) + waveOffset) * 20 +
              sin((i / size.width * 8 * pi) + waveOffset * 2) * 10
      );
    }

    canvas.drawPath(path, paint);

    // Draw second wave
    final path2 = Path();
    path2.moveTo(0, size.height * 0.3);

    for (double i = 0; i <= size.width; i++) {
      path2.lineTo(
          i,
          size.height * 0.3 +
              sin((i / size.width * 3 * pi) + waveOffset * 0.8) * 10 +
              sin((i / size.width * 6 * pi) + waveOffset * 1.5) * 5
      );
    }

    canvas.drawPath(path2, paint);

    // Draw third wave
    final path3 = Path();
    path3.moveTo(0, size.height * 0.7);

    for (double i = 0; i <= size.width; i++) {
      path3.lineTo(
          i,
          size.height * 0.7 +
              sin((i / size.width * 2.5 * pi) + waveOffset * 1.2) * 15 +
              sin((i / size.width * 5 * pi) + waveOffset * 0.7) * 7
      );
    }

    canvas.drawPath(path3, paint);
  }

  @override
  bool shouldRepaint(covariant AudioWavePainter oldDelegate) {
    return oldDelegate.waveOffset != waveOffset || oldDelegate.color != color;
  }
}