import 'dart:math';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';

class PodcastPlayerViewModel extends ChangeNotifier {
  // Properties from the original state
  final Map<String, dynamic> podcast;
  bool isPlaying = false;
  int currentIndex = 0;
  double currentPosition = 0.0;
  Timer? progressTimer;
  FlutterTts flutterTts = FlutterTts();
  bool isTtsInitialized = false;
  bool isTtsSpeaking = false;

  // Animation controllers - mark them as nullable and with late
  late AnimationController waveController;
  late AnimationController characterAnimController1;
  late AnimationController characterAnimController2;

  // Animation values - will be initialized with controllers
  late Animation<double> _waveAnimation;
  late Animation<double> _speakingAnimation1;
  late Animation<double> _speakingAnimation2;

  // Make sure controllers are initialized flag
  bool _areControllersInitialized = false;

  // Getters for animations
  Animation<double> get waveAnimation => _waveAnimation;
  Animation<double> get speakingAnimation1 => _speakingAnimation1;
  Animation<double> get speakingAnimation2 => _speakingAnimation2;

  // Check if controllers are initialized
  bool get areControllersInitialized => _areControllersInitialized;

  // Current dialogue content
  String currentGermanText = '';
  String currentEnglishText = '';
  int currentSpeaker = 1;

  // Total duration in seconds
  late int totalDuration;

  // Mock conversation data - German dialogue with English subtitles
  final List<Map<String, dynamic>> conversation = [
    {
      'speaker': 1,
      'german': 'Hallo! Wie geht es dir heute?',
      'english': 'Hello! How are you today?',
      'duration': 3,
    },
    {
      'speaker': 2,
      'german': 'Mir geht es gut, danke! Was hast du heute gemacht?',
      'english': 'I\'m doing well, thank you! What did you do today?',
      'duration': 4,
    },
    {
      'speaker': 1,
      'german': 'Ich war im Park und habe ein interessantes Buch gelesen.',
      'english': 'I was at the park and read an interesting book.',
      'duration': 4,
    },
    {
      'speaker': 2,
      'german': 'Oh, welches Buch hast du gelesen?',
      'english': 'Oh, which book did you read?',
      'duration': 3,
    },
    {
      'speaker': 1,
      'german': 'Es war "Die Verwandlung" von Franz Kafka. Ein Klassiker der deutschen Literatur.',
      'english': 'It was "The Metamorphosis" by Franz Kafka. A classic of German literature.',
      'duration': 5,
    },
    {
      'speaker': 2,
      'german': 'Das klingt interessant! Ich liebe Kafka\'s Werke.',
      'english': 'That sounds interesting! I love Kafka\'s works.',
      'duration': 4,
    },
    {
      'speaker': 1,
      'german': 'Ja, seine Geschichten sind surreal und tiefgründig. Hast du eine Lieblingsgeschichte von ihm?',
      'english': 'Yes, his stories are surreal and profound. Do you have a favorite story by him?',
      'duration': 5,
    },
    {
      'speaker': 2,
      'german': 'Ich mag "Der Prozess" sehr. Die Atmosphäre ist bedrückend, aber fesselnd.',
      'english': 'I really like "The Trial". The atmosphere is oppressive but captivating.',
      'duration': 4,
    },
    {
      'speaker': 1,
      'german': 'Eine gute Wahl! Vielleicht können wir nächstes Mal zusammen in der Bibliothek lesen?',
      'english': 'A good choice! Perhaps next time we can read together at the library?',
      'duration': 4,
    },
    {
      'speaker': 2,
      'german': 'Das wäre wunderbar! Ich freue mich darauf.',
      'english': 'That would be wonderful! I\'m looking forward to it.',
      'duration': 3,
    },
  ];

  PodcastPlayerViewModel({required this.podcast}) {
    // Calculate total duration
    totalDuration = conversation.fold(0, (sum, item) => sum + (item['duration'] as int));

    // Set initial dialogue
    updateCurrentDialogue();
  }

  // Initialize animation controllers
  void initAnimationControllers(TickerProvider vsync) {
    try {
      // Create animation controllers
      waveController = AnimationController(
        vsync: vsync,
        duration: Duration(milliseconds: 1500),
      );

      characterAnimController1 = AnimationController(
        vsync: vsync,
        duration: Duration(milliseconds: 800),
      );

      characterAnimController2 = AnimationController(
        vsync: vsync,
        duration: Duration(milliseconds: 800),
      );

      // Create animations
      _waveAnimation = Tween<double>(begin: 0, end: 2 * pi).animate(waveController);

      _speakingAnimation1 = Tween<double>(begin: 1.0, end: 1.1).animate(
          CurvedAnimation(parent: characterAnimController1, curve: Curves.easeInOut)
      );

      _speakingAnimation2 = Tween<double>(begin: 1.0, end: 1.1).animate(
          CurvedAnimation(parent: characterAnimController2, curve: Curves.easeInOut)
      );

      // Start wave animation regardless of play state
      waveController.repeat();

      // Mark controllers as initialized
      _areControllersInitialized = true;

      // Notify listeners after controllers are initialized
      notifyListeners();
    } catch (e) {
      print("Error initializing animation controllers: $e");
    }
  }

  // Initialize TTS
  Future<void> initTts() async {
    try {
      // Set the language to German
      await flutterTts.setLanguage("de-DE");

      // Set volume and speech rate
      await flutterTts.setVolume(1.0);
      await flutterTts.setSpeechRate(0.5); // Slightly slower for learning

      // Set pitch slightly lower for more natural sound
      await flutterTts.setPitch(0.9);

      // Listen for TTS state changes
      flutterTts.setStartHandler(() {
        isTtsSpeaking = true;
        notifyListeners();
      });

      // Set completed callback to know when speech is done
      flutterTts.setCompletionHandler(() {
        isTtsSpeaking = false;
        notifyListeners();
      });

      // Handle errors
      flutterTts.setErrorHandler((error) {
        print("TTS Error: $error");
        isTtsSpeaking = false;
        notifyListeners();
      });

      isTtsInitialized = true;
      notifyListeners();
    } catch (e) {
      print("Error initializing TTS: $e");
    }
  }

  // Start progress timer for tracking playback
  void startProgressTimer() {
    progressTimer?.cancel();
    progressTimer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      if (isPlaying) {
        currentPosition += 0.1;

        // Check if we need to move to the next dialogue
        double positionInCurrentDialogue = getCurrentPositionInDialogue();
        int currentDuration = conversation[currentIndex]['duration'] as int;

        if (positionInCurrentDialogue >= currentDuration && currentIndex < conversation.length - 1) {
          // Only auto-advance if TTS has finished speaking
          if (!isTtsSpeaking) {
            skipForward();
          }
        } else if (currentPosition >= totalDuration.toDouble()) {
          // Reached the end
          currentPosition = 0.0;
          currentIndex = 0;
          pausePlayback();
          updateCurrentDialogue();
        }

        notifyListeners();
      }
    });
  }

  // Helper function to get position within current dialogue
  double getCurrentPositionInDialogue() {
    double previousDuration = 0;
    for (int i = 0; i < currentIndex; i++) {
      previousDuration += conversation[i]['duration'] as int;
    }
    return currentPosition - previousDuration;
  }

  // Update the current dialogue text and speaker
  void updateCurrentDialogue() {
    if (currentIndex < conversation.length) {
      final dialogue = conversation[currentIndex];
      currentGermanText = dialogue['german'];
      currentEnglishText = dialogue['english'];
      currentSpeaker = dialogue['speaker'];

      // Start speaking if playing and TTS is initialized
      if (isPlaying && isTtsInitialized) {
        speakCurrentText();
      }

      // Start the appropriate character animation
      startSpeaking(currentSpeaker);

      notifyListeners();
    }
  }

  // Speak the current German text
  Future<void> speakCurrentText() async {
    if (isTtsInitialized) {
      try {
        // Stop any ongoing speech first
        await flutterTts.stop();

        // Small delay to ensure previous speech is fully stopped
        await Future.delayed(Duration(milliseconds: 100));

        // Start new speech
        await flutterTts.speak(currentGermanText);
      } catch (e) {
        print("Error speaking text: $e");
      }
    }
  }

  // Toggle play/pause
  void togglePlayPause() {
    if (isPlaying) {
      pausePlayback();
    } else {
      startPlayback();
    }
  }

  // Pause playback
  void pausePlayback() {
    isPlaying = false;

    // Stop speaking
    if (isTtsInitialized) {
      flutterTts.stop();
      isTtsSpeaking = false;
    }

    // Stop character animations but keep wave animation
    if (_areControllersInitialized) {
      characterAnimController1.stop();
      characterAnimController2.stop();
    }

    // Cancel progress timer
    progressTimer?.cancel();

    notifyListeners();
  }

  // Start playback
  void startPlayback() {
    isPlaying = true;

    // Start speaking current text
    speakCurrentText();

    // Start character animation
    startSpeaking(currentSpeaker);

    // Start progress timer
    startProgressTimer();

    notifyListeners();
  }

  // Skip to the next dialogue
  Future<void> skipForward() async {
    // Only proceed if there's a change in dialogue
    if (currentIndex < conversation.length - 1) {
      // Stop current speech
      if (isTtsInitialized) {
        await flutterTts.stop();
        isTtsSpeaking = false;
      }

      // Move to next dialogue
      currentIndex++;

      // Update position
      double position = 0;
      for (int i = 0; i < currentIndex; i++) {
        position += conversation[i]['duration'] as int;
      }
      currentPosition = position;

      // Update dialogue and start speaking if playing
      updateCurrentDialogue();

      notifyListeners();
    }
  }

  // Skip to the previous dialogue
  Future<void> skipBackward() async {
    // Only proceed if there's a change in dialogue
    if (currentIndex > 0) {
      // Stop current speech
      if (isTtsInitialized) {
        await flutterTts.stop();
        isTtsSpeaking = false;
      }

      // Move to previous dialogue
      currentIndex--;

      // Update position
      double position = 0;
      for (int i = 0; i < currentIndex; i++) {
        position += conversation[i]['duration'] as int;
      }
      currentPosition = position;

      // Update dialogue and start speaking if playing
      updateCurrentDialogue();

      notifyListeners();
    }
  }

  // Set playback position
  void setPosition(double value) {
    try {
      // Stop current speech
      if (isTtsInitialized) {
        flutterTts.stop();
        isTtsSpeaking = false;
      }

      currentPosition = value;

      // Find the current dialogue based on position
      double accumulatedTime = 0;
      for (int i = 0; i < conversation.length; i++) {
        double dialogueDuration = conversation[i]['duration'] as double;
        if (value < accumulatedTime + dialogueDuration) {
          currentIndex = i;
          break;
        }
        accumulatedTime += dialogueDuration;
      }

      // Update dialogue and start speaking if playing
      updateCurrentDialogue();

      notifyListeners();
    } catch (e) {
      print("Error setting position: $e");
    }
  }

  // Start speaking animation for appropriate character
  void startSpeaking(int speaker) {
    if (!_areControllersInitialized) {
      return;
    }

    try {
      // Reset both controllers
      characterAnimController1.stop();
      characterAnimController2.stop();
      characterAnimController1.reset();
      characterAnimController2.reset();

      // Only animate if currently playing
      if (isPlaying) {
        // Activate the appropriate controller
        if (speaker == 1) {
          characterAnimController1.repeat(reverse: true);
        } else {
          characterAnimController2.repeat(reverse: true);
        }
      }
    } catch (e) {
      print("Error starting speaking animation: $e");
    }
  }

  // Helper for formatted time display
  String formatTime(double seconds) {
    int mins = (seconds / 60).floor();
    int secs = (seconds % 60).floor();
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  // Clean up resources
  @override
  void dispose() {
    // Stop TTS
    flutterTts.stop();

    // Cancel timers
    progressTimer?.cancel();

    // Dispose controllers if they've been initialized
    if (_areControllersInitialized) {
      waveController.dispose();
      characterAnimController1.dispose();
      characterAnimController2.dispose();
    }

    super.dispose();
  }
}