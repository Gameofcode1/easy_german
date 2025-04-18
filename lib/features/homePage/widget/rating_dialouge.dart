import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:in_app_review/in_app_review.dart';

class AppRatingService {
  static const String _keyRated = 'app_rated';
  static const String _keyLastPrompted = 'last_rating_prompt';
  static const String _keyAppOpenCount = 'app_open_count';
  static const int _minSessionsBeforeRating = 3; // Show after 3 sessions

  // Check if we should show the rating dialog
  static Future<bool> shouldShowRatingDialog() async {
    final prefs = await SharedPreferences.getInstance();

    // If user has already rated, don't show again
    if (prefs.getBool(_keyRated) ?? false) {
      return false;
    }

    // Count app opens
    int openCount = prefs.getInt(_keyAppOpenCount) ?? 0;
    await prefs.setInt(_keyAppOpenCount, openCount + 1);

    // Check last prompted time
    int lastPrompted = prefs.getInt(_keyLastPrompted) ?? 0;
    int currentTime = DateTime.now().millisecondsSinceEpoch;

    // Show dialog if:
    // 1. App has been opened at least the minimum number of times
    // 2. It's been at least 3 days since the last prompt (if declined previously)
    if (openCount >= _minSessionsBeforeRating &&
        (lastPrompted == 0 || currentTime - lastPrompted > const Duration(days: 3).inMilliseconds)) {
      await prefs.setInt(_keyLastPrompted, currentTime);
      return true;
    }

    return false;
  }

  // Mark as rated to prevent future prompts
  static Future<void> markAsRated() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyRated, true);
  }
}


class EnhancedRatingDialog extends StatefulWidget {
  final Function? onRated;
  final Function? onLater;
  final Function? onNever;

  const EnhancedRatingDialog({
    Key? key,
    this.onRated,
    this.onLater,
    this.onNever,
  }) : super(key: key);

  static Future<void> show(BuildContext context) async {
    // For testing, you can force it to true
    bool shouldShow = await AppRatingService.shouldShowRatingDialog();

    if (shouldShow && context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => EnhancedRatingDialog(
          onRated: () async {
            // Mark as rated to prevent future prompts
            AppRatingService.markAsRated();
            Navigator.of(context).pop();

            // Show thank you dialog
            await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: const Text('Thank You!'),
                content: const Text('Your feedback helps us improve the app for everyone.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          },
          onLater: () {
            Navigator.of(context).pop();
          },
          onNever: () {
            AppRatingService.markAsRated(); // Also mark as rated so we don't show again
            Navigator.of(context).pop();
          },
        ),
      );
    }
  }

  @override
  State<EnhancedRatingDialog> createState() => _EnhancedRatingDialogState();
}

class _EnhancedRatingDialogState extends State<EnhancedRatingDialog> with SingleTickerProviderStateMixin {
  int _rating = 0;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Show App Store review for high ratings
  Future<void> _handleHighRating() async {
    final InAppReview inAppReview = InAppReview.instance;

    if (await inAppReview.isAvailable()) {
      inAppReview.requestReview();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 10,
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/rating_icon.png', // Make sure to add this asset
                height: 60,
                width: 60,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.star,
                  size: 60,
                  color: Color(0xFF3F51B5),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Enjoying our app?',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Your feedback helps us improve.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: Duration(milliseconds: 100 + (index * 100)),
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: child,
                      );
                    },
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _rating = index + 1;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: Icon(
                          index < _rating ? Icons.star : Icons.star_border,
                          color: index < _rating
                              ? const Color(0xFFFF9800)
                              : Colors.grey.shade400,
                          size: 40,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              if (_rating > 0) ...[
                if (_rating >= 4) ...[
                  // High rating (4-5 stars)
                  Text(
                    'Thanks for your positive feedback!',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      // First close this dialog
                      if (widget.onRated != null) {
                        widget.onRated!();
                      }

                      // Then show app store review
                      await _handleHighRating();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text('Submit & Rate on Store'),
                  ),
                ] else ...[
                  // Low rating (1-3 stars)
                  Text(
                    'Thanks for your feedback!',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'How can we improve your experience?',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Close this dialog
                      Navigator.of(context).pop();

                      // Navigate to feedback screen with the rating
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FeedbackScreen(rating: _rating),
                        ),
                      );

                      // Still call the onRated callback
                      if (widget.onRated != null) {
                        widget.onRated!();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text('Send Feedback'),
                  ),
                ],
              ],
              if (_rating == 0) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () {
                        if (widget.onNever != null) {
                          widget.onNever!();
                        }
                      },
                      child: const Text('Don\'t ask again'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (widget.onLater != null) {
                          widget.onLater!();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3F51B5),
                      ),
                      child: const Text('Remind later'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
// Keep the existing AppRatingService from the previous file



class FeedbackScreen extends StatelessWidget {
  final int rating;

  const FeedbackScreen({
    Key? key,
    required this.rating,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FeedbackViewModel(initialRating: rating),
      child: const _FeedbackScreenContent(),
    );
  }
}

class _FeedbackScreenContent extends StatefulWidget {
  const _FeedbackScreenContent({Key? key}) : super(key: key);

  @override
  State<_FeedbackScreenContent> createState() => _FeedbackScreenContentState();
}

class _FeedbackScreenContentState extends State<_FeedbackScreenContent> {
  final TextEditingController _feedbackController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _feedbackController.addListener(_onFeedbackChanged);
  }

  @override
  void dispose() {
    _feedbackController.removeListener(_onFeedbackChanged);
    _feedbackController.dispose();
    super.dispose();
  }

  void _onFeedbackChanged() {
    final viewModel = Provider.of<FeedbackViewModel>(context, listen: false);
    viewModel.updateFeedbackText(_feedbackController.text);
  }

  Future<void> _submitFeedback() async {
    final viewModel = Provider.of<FeedbackViewModel>(context, listen: false);
    final success = await viewModel.submitFeedback();

    if (success && mounted) {
      _showThankYouDialog();
    }
  }

  void _showThankYouDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Thank You!'),
        content: const Text('Your feedback is valuable to us and helps us improve the app.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Return to previous screen
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<FeedbackViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Feedback'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rating summary
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.star,
                    color: Color(0xFFFF9800),
                    size: 40,
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Rating',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: List.generate(5, (index) {
                          return Icon(
                            index < viewModel.rating ? Icons.star : Icons.star_border,
                            color: index < viewModel.rating
                                ? const Color(0xFFFF9800)
                                : Colors.grey.shade400,
                            size: 20,
                          );
                        }),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Feedback categories
            Text(
              'What areas need improvement?',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: viewModel.feedbackCategories.map((category) {
                final bool isSelected = viewModel.selectedCategories.contains(category);
                return FilterChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (_) => viewModel.toggleCategory(category),
                  selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  checkmarkColor: Theme.of(context).colorScheme.primary,
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Feedback text field
            Text(
              'Tell us more (optional)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _feedbackController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Share your thoughts with us...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Submit button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: viewModel.isSubmitting || !viewModel.canSubmit
                    ? null
                    : _submitFeedback,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: viewModel.isSubmitting
                    ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : const Text('Submit Feedback'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class FeedbackViewModel extends ChangeNotifier {
  bool _isSubmitting = false;
  List<String> _selectedCategories = [];
  String _feedbackText = '';
  int _rating = 0;

  // Getters
  bool get isSubmitting => _isSubmitting;
  List<String> get selectedCategories => _selectedCategories;
  String get feedbackText => _feedbackText;
  int get rating => _rating;

  // Check if we can submit the feedback
  bool get canSubmit => _selectedCategories.isNotEmpty || _feedbackText.isNotEmpty;

  // List of default feedback categories
  final List<String> feedbackCategories = [
    'User Interface',
    'Features',
    'Performance',
    'Content',
    'Difficulty Level',
    'Technical Issues',
    'Other'
  ];

  // Constructor
  FeedbackViewModel({required int initialRating}) {
    _rating = initialRating;
  }

  // Add or remove a category
  void toggleCategory(String category) {
    if (_selectedCategories.contains(category)) {
      _selectedCategories.remove(category);
    } else {
      _selectedCategories.add(category);
    }
    notifyListeners();
  }

  // Update feedback text
  void updateFeedbackText(String text) {
    _feedbackText = text;
    notifyListeners();
  }

  // Submit feedback
  Future<bool> submitFeedback() async {
    _isSubmitting = true;
    notifyListeners();

    try {
      // Simulate a network delay
      await Future.delayed(const Duration(milliseconds: 800));

      final prefs = await SharedPreferences.getInstance();

      // Create feedback data object
      final Map<String, dynamic> feedbackData = {
        'rating': _rating,
        'categories': _selectedCategories,
        'feedback': _feedbackText,
        'timestamp': DateTime.now().toIso8601String(),
      };

      // In a real app, you would send this to your backend
      // For now, just store locally
      final List<String> savedFeedback = prefs.getStringList('user_feedback') ?? [];
      savedFeedback.add(feedbackData.toString());
      await prefs.setStringList('user_feedback', savedFeedback);

      // Mark app as rated in preferences
      await prefs.setBool('app_rated', true);

      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }
}
