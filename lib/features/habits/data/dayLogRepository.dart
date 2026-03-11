// lib/features/habits/data/day_log_repository.dart
import '../models/models.dart';

abstract class DayLogRepository {
  // Habits
  Future<List<Habit>> getHabits({required String userId});
  Future<Habit> addHabit({required String userId, required Habit habit});
  Future<Habit> updateHabit({required String userId, required Habit habit});
  Future<void> deleteHabit({required String userId, required String habitId, bool cascadeDeleteValues = true});

  // Day logs
  Future<List<DayLog>> getLogsForRange({
    required String userId,
    required DateTime startInclusive,
    required DateTime endInclusive,
  });

  Future<void> upsertDayLog({
    required String userId,
    required DayLog log,
  });
}

class InMemoryDayLogRepository implements DayLogRepository {
  // userId -> habits
  final Map<String, List<Habit>> _habitsByUser = {};
  // userId -> date(YYYY-MM-DD) -> DayLog
  final Map<String, Map<String, DayLog>> _logsByUser = {};

  InMemoryDayLogRepository() {
    _seed();
  }

  // ---------------- Habits ----------------
  @override
  Future<List<Habit>> getHabits({required String userId}) async {
    return List.unmodifiable(_habitsByUser[userId] ?? const []);
  }

  @override
  Future<Habit> addHabit({required String userId, required Habit habit}) async {
    _habitsByUser.putIfAbsent(userId, () => []);
    _habitsByUser[userId]!.add(habit);
    return habit;
  }

  @override
  Future<Habit> updateHabit({required String userId, required Habit habit}) async {
    final list = _habitsByUser[userId] ?? [];
    final i = list.indexWhere((h) => h.id == habit.id);
    if (i >= 0) {
      list[i] = habit;
      return habit;
    }
    // If not found, treat as add
    list.add(habit);
    return habit;
  }

  @override
  Future<void> deleteHabit({
    required String userId,
    required String habitId,
    bool cascadeDeleteValues = true,
  }) async {
    final list = _habitsByUser[userId];
    if (list != null) {
      list.removeWhere((h) => h.id == habitId);
    }
    if (cascadeDeleteValues) {
      final byDate = _logsByUser[userId];
      if (byDate != null) {
        for (final entry in byDate.entries) {
          final log = entry.value;
          if (log.entries.containsKey(habitId)) {
            final next = Map<String, RatingValue>.from(log.entries)..remove(habitId);
            byDate[entry.key] = DayLog(dateUtc: log.dateUtc, entries: next);
          }
        }
      }
    }
  }

  @override
  Future<List<DayLog>> getLogsForRange({
    required String userId,
    required DateTime startInclusive,
    required DateTime endInclusive,
  }) async {
    final byDate = _logsByUser[userId] ?? const {};
    final start = _yyyymmdd(startInclusive.toUtc());
    final end = _yyyymmdd(endInclusive.toUtc());

    final result = <DayLog>[];
    for (final e in byDate.entries) {
      if (e.key.compareTo(start) >= 0 && e.key.compareTo(end) <= 0) {
        result.add(e.value);
      }
    }
    result.sort((a, b) => a.yyyymmdd.compareTo(b.yyyymmdd));
    return result;
  }

  @override
  Future<void> upsertDayLog({
    required String userId,
    required DayLog log,
  }) async {
    final key = _yyyymmdd(log.dateUtc.toUtc());
    _logsByUser.putIfAbsent(userId, () => {});
    _logsByUser[userId]![key] = log;
  }

  // ---------------- Helpers + Seed ----------------
  static String _yyyymmdd(DateTime d) =>
      "${d.year.toString().padLeft(4,'0')}-"
          "${d.month.toString().padLeft(2,'0')}-"
          "${d.day.toString().padLeft(2,'0')}";

  static DateTime _utc(int y, int m, int d) => DateTime.utc(y, m, d);

  void _seed() {
    const uid = 'demo_user';
    _habitsByUser[uid] = [
      const Habit(id: 'sport', name: 'Sportas', kind: RatingKind.checkbox),
      const Habit(id: 'read',  name: 'Skaitymas (min)', kind: RatingKind.number, min: 0, max: 200),
      const Habit(id: 'med',   name: 'Meditacija', kind: RatingKind.enumerator, options: ['Bad','OK','Great']),
      const Habit(id: 'mood',  name: 'Nuotaika', kind: RatingKind.scale, min: 1, max: 5),
    ];

    final now = DateTime.now().toUtc();
    final y = now.year, m = now.month;

    final logs = <String, DayLog>{};
    DayLog d(int day, Map<String, RatingValue> entries) {
      final log = DayLog(dateUtc: _utc(y, m, day), entries: entries);
      logs[_yyyymmdd(log.dateUtc)] = log;
      return log;
    }

    d(1, {'sport': const BoolValue(true),  'read': const NumberValue(25), 'med': const EnumValue('Great'), 'mood': const NumberValue(4)});
    d(2, {'sport': const BoolValue(false), 'read': const NumberValue(10), 'med': const EnumValue('OK'),    'mood': const NumberValue(3)});
    d(3, {'sport': const BoolValue(true),  'read': const NumberValue(40), 'med': const EnumValue('OK'),    'mood': const NumberValue(5)});
    d(6, {'sport': const BoolValue(true),  'read': const NumberValue(15), 'med': const EnumValue('Bad'),   'mood': const NumberValue(2)});

    _logsByUser[uid] = logs;
  }
}