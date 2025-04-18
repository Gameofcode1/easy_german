import 'package:shared_preferences/shared_preferences.dart';

class AppUsageTracker {
  static const String _keyUsageTime = 'app_usage_time';
  static const String _keyLastSession = 'last_session_date';
  static const String _keySessionCount = 'session_count';

  int _startTime = 0;
  bool _isTracking = false;

  // Start tracking app usage time
  void startTracking() {
    if (!_isTracking) {
      _startTime = DateTime.now().millisecondsSinceEpoch;
      _isTracking = true;
      _incrementSessionCount();
    }
  }

  // Stop tracking and save elapsed time
  Future<void> stopTracking() async {
    if (_isTracking) {
      final int now = DateTime.now().millisecondsSinceEpoch;
      final int sessionTime = now - _startTime;

      // Only save if the session time is significant (more than 1 second)
      if (sessionTime > 1000) {
        final prefs = await SharedPreferences.getInstance();
        final int totalTime = prefs.getInt(_keyUsageTime) ?? 0;
        await prefs.setInt(_keyUsageTime, totalTime + sessionTime);
      }

      _isTracking = false;
    }
  }

  // Resume tracking if app was closed without proper stop
  Future<void> resumeTrackingIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final int lastDate = prefs.getInt(_keyLastSession) ?? 0;

    // Save today's date as the last session
    final int today = DateTime.now().year * 10000 +
        DateTime.now().month * 100 +
        DateTime.now().day;
    await prefs.setInt(_keyLastSession, today);
  }

  // Get total usage time in milliseconds
  Future<int> getTotalUsageTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyUsageTime) ?? 0;
  }

  // Get session count (number of app opens)
  Future<int> getSessionCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keySessionCount) ?? 0;
  }

  // Increment session count when app is opened
  Future<void> _incrementSessionCount() async {
    final prefs = await SharedPreferences.getInstance();
    final int count = prefs.getInt(_keySessionCount) ?? 0;
    await prefs.setInt(_keySessionCount, count + 1);
  }

  // Check if this is a new day compared to the last session
  Future<bool> isNewDay() async {
    final prefs = await SharedPreferences.getInstance();
    final int lastDate = prefs.getInt(_keyLastSession) ?? 0;

    final int today = DateTime.now().year * 10000 +
        DateTime.now().month * 100 +
        DateTime.now().day;

    return lastDate != today;
  }
}