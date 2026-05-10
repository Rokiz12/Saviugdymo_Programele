import 'package:health/health.dart';

class StepService {
  static final _health = Health();

  /// Request permissions. Call once on app start (e.g. in _initialize).
  /// Returns true if granted.
  static Future<bool> requestPermissions() async {
    final types = [HealthDataType.STEPS];
    final permissions = [HealthDataAccess.READ];
    try {
      return await _health.requestAuthorization(types, permissions: permissions);
    } catch (_) {
      return false;
    }
  }

  /// Returns total steps for today (UTC midnight → now).
  /// Returns null if permission denied or read fails.
  static Future<int?> getTodaySteps() async {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);

    try {
      final granted = await requestPermissions();
      if (!granted) return null;

      final steps = await _health.getTotalStepsInInterval(midnight, now);
      return steps;
    } catch (_) {
      return null;
    }
  }
}