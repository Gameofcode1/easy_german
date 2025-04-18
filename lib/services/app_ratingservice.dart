import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Keep the existing AppRatingService from the previous file
class AppRatingService {
  static const String _keyRated = 'app_rated';
  static const String _keyLastPrompted = 'last_rating_prompt';
  static const String _keyAppOpenCount = 'app_open_count';
  static const int _minSessionsBeforeRating = 3; // Show after 3 sessions


  static Future<void> resetAllRatingPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyRated);
    await prefs.remove(_keyLastPrompted);
    // Don't reset app open count, or set it to the threshold
    await prefs.setInt(_keyAppOpenCount, _minSessionsBeforeRating);
    print("All rating preferences reset for testing");
  }

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


class RatingDialog extends StatefulWidget {
  final Function? onRated;
  final Function? onLater;

  const RatingDialog({
    Key? key,
    this.onRated,
    this.onLater,
  }) : super(key: key);

  static Future<void> show(BuildContext context) async {
    if (await AppRatingService.shouldShowRatingDialog()) {
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => RatingDialog(
            onRated: () {
              // Handle when user rates the app
              AppRatingService.markAsRated();
              Navigator.of(context).pop();
              // Here you would typically launch store review
              // using a package like in_app_review or url_launcher
            },
            onLater: () {
              Navigator.of(context).pop();
            },
          ),
        );
      }
    }
  }

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  int _rating = 0;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enjoying our app?',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'We\'d love to hear your feedback!',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: index < _rating ? const Color(0xFFFF9800) : Colors.grey,
                    size: 36,
                  ),
                  onPressed: () {
                    setState(() {
                      _rating = index + 1;
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () {
                    if (widget.onLater != null) {
                      widget.onLater!();
                    }
                  },
                  child: const Text('Later'),
                ),
                ElevatedButton(
                  onPressed: _rating > 0
                      ? () {
                    if (widget.onRated != null) {
                      widget.onRated!();
                    }
                  }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                  ),
                  child: const Text('Submit'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}