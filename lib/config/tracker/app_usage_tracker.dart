import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

/// A service that tracks active app usage time and saves it to SharedPreferences
class AppUsageTracker {
  // Keys for SharedPreferences
  static const String _keyTotalTimeMinutes = 'total_learning_time_minutes';
  static const String _keyLastSessionStart = 'last_session_start';
  static const String _keyIsSessionActive = 'is_session_active';

  // Timer to periodically save the time
  Timer? _saveTimer;
  DateTime? _sessionStartTime;
  bool _isActive = false;

  // Singleton pattern
  static final AppUsageTracker _instance = AppUsageTracker._internal();
  factory AppUsageTracker() => _instance;

  AppUsageTracker._internal();

  /// Start tracking app usage time
  void startTracking() async {
    if (_isActive) return; // Don't start if already tracking

    _isActive = true;
    _sessionStartTime = DateTime.now();

    // Save the session start time to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt(_keyLastSessionStart, _sessionStartTime!.millisecondsSinceEpoch);
    prefs.setBool(_keyIsSessionActive, true);

    // Start a timer to save time periodically (every 30 seconds)
    _saveTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _saveCurrentSession();
    });

    print("Started tracking app usage time");
  }

  /// Stop tracking app usage time and save the final time
  void stopTracking() async {
    if (!_isActive) return; // Don't stop if not tracking

    // Cancel the timer
    _saveTimer?.cancel();

    // Save the final session time
    await _saveCurrentSession();

    // Reset the session
    _isActive = false;
    _sessionStartTime = null;

    // Update SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool(_keyIsSessionActive, false);

    print("Stopped tracking app usage time");
  }

  /// Save the current session time to SharedPreferences
  Future<void> _saveCurrentSession() async {
    if (_sessionStartTime == null) return;

    final now = DateTime.now();
    final sessionDurationMinutes = now.difference(_sessionStartTime!).inMinutes;

    if (sessionDurationMinutes <= 0) return; // Don't save if no meaningful time has passed

    // Get the current total time
    final prefs = await SharedPreferences.getInstance();
    final totalMinutes = prefs.getInt(_keyTotalTimeMinutes) ?? 0;

    // Add the session time and save
    final newTotalMinutes = totalMinutes + sessionDurationMinutes;
    await prefs.setInt(_keyTotalTimeMinutes, newTotalMinutes);

    // Update the session start time to now
    _sessionStartTime = now;
    await prefs.setInt(_keyLastSessionStart, now.millisecondsSinceEpoch);

    // Update daily stats
    await _updateDailyStats();

    print("Saved session time: $sessionDurationMinutes minutes. New total: $newTotalMinutes minutes");
  }

  /// Force save the current session to SharedPreferences
  Future<void> saveCurrentSession() async {
    if (!_isActive || _sessionStartTime == null) return;

    final now = DateTime.now();
    final sessionDurationMinutes = now.difference(_sessionStartTime!).inMinutes;

    if (sessionDurationMinutes <= 0) return;

    // Get the current total time
    final prefs = await SharedPreferences.getInstance();
    final totalMinutes = prefs.getInt(_keyTotalTimeMinutes) ?? 0;

    // Add the session time and save
    final newTotalMinutes = totalMinutes + sessionDurationMinutes;
    await prefs.setInt(_keyTotalTimeMinutes, newTotalMinutes);

    // Update the session start time to now
    _sessionStartTime = now;
    await prefs.setInt(_keyLastSessionStart, now.millisecondsSinceEpoch);

    // Update daily stats - check if it's a new day
    await _updateDailyStats();

    print("Manually saved session time: $sessionDurationMinutes minutes. New total: $newTotalMinutes minutes");
  }

  /// Resume tracking if the app was in an active session
  Future<void> resumeTrackingIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final wasActive = prefs.getBool(_keyIsSessionActive) ?? false;

    if (wasActive) {
      // Start a new session
      startTracking();
    }
  }

  /// Get the total learning time in minutes
  Future<int> getTotalLearningTimeMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyTotalTimeMinutes) ?? 0;
  }

  /// Format learning time as a human-readable string
  String formatLearningTime(int minutes) {
    if (minutes < 60) {
      return '$minutes mins';
    } else {
      int hours = minutes ~/ 60;
      int remainingMinutes = minutes % 60;
      if (remainingMinutes == 0) {
        return '$hours hrs';
      } else {
        return '$hours hrs $remainingMinutes mins';
      }
    }
  }

  /// Update daily stats for streak tracking
  Future<void> _updateDailyStats() async {
    final prefs = await SharedPreferences.getInstance();

    // Get the current date
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Get the last date the app was used
    final lastUsedTimestamp = prefs.getInt('last_used_date');
    DateTime? lastUsedDate;

    if (lastUsedTimestamp != null) {
      final lastUsed = DateTime.fromMillisecondsSinceEpoch(lastUsedTimestamp);
      lastUsedDate = DateTime(lastUsed.year, lastUsed.month, lastUsed.day);
    }

    // Save today as the last used date
    await prefs.setInt('last_used_date', today.millisecondsSinceEpoch);

    // If it's the first time using the app or a different day, increment days used
    if (lastUsedDate == null || !_isSameDay(lastUsedDate, today)) {
      final daysUsed = prefs.getInt('days_app_used') ?? 0;
      await prefs.setInt('days_app_used', daysUsed + 1);

      // Update streak count
      if (lastUsedDate != null) {
        final yesterday = DateTime(now.year, now.month, now.day - 1);

        if (_isSameDay(lastUsedDate, yesterday)) {
          // Used yesterday, increase streak
          final streak = prefs.getInt('learning_streak_days') ?? 0;
          await prefs.setInt('learning_streak_days', streak + 1);
        } else if (!_isSameDay(lastUsedDate, today)) {
          // Not used yesterday or today yet, reset streak
          await prefs.setInt('learning_streak_days', 1);
        }
      } else {
        // First time using the app, start streak at 1
        await prefs.setInt('learning_streak_days', 1);
      }
    }
  }

  /// Check if two dates are the same day
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}