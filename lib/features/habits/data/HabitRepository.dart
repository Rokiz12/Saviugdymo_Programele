import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';


abstract class DayLogRepository {
  Future<List<Habit>> getHabits({required String userId});
  Future<Habit> addHabit({required String userId, required Habit habit});
  Future<Habit> updateHabit({required String userId, required Habit habit});
  Future<void> deleteHabit({
    required String userId,
    required String habitId,
    bool cascadeDeleteValues = true,
  });

  Future<List<Goal>> getGoals({required String userId});
  Future<Goal> addGoal({required String userId, required Goal goal});
  Future<Goal> updateGoal({required String userId, required Goal goal});
  Future<void> deleteGoal({required String userId, required String goalId});

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



class FirebaseDayLogRepository implements DayLogRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _habits(String uid) =>
      _db.collection('users').doc(uid).collection('habits');

  CollectionReference<Map<String, dynamic>> _goals(String uid) =>
      _db.collection('users').doc(uid).collection('goals');

  CollectionReference<Map<String, dynamic>> _dayLogs(String uid) =>
      _db.collection('users').doc(uid).collection('dayLogs');



  //  HABITS


  @override
  Future<List<Habit>> getHabits({required String userId}) async {
    final snap = await _habits(userId).get();
    return snap.docs.map((d) => Habit.fromJson(d.data())).toList();
  }

  @override
  Future<Habit> addHabit({required String userId, required Habit habit}) async {
    await _habits(userId).doc(habit.id).set(habit.toJson());
    return habit;
  }

  @override
  Future<Habit> updateHabit({required String userId, required Habit habit}) async {
    await _habits(userId).doc(habit.id).set(habit.toJson());
    return habit;
  }

  @override
  Future<void> deleteHabit({
    required String userId,
    required String habitId,
    bool cascadeDeleteValues = true,
  }) async {
    await _habits(userId).doc(habitId).delete();

    if (!cascadeDeleteValues) return;

    final logs = await _dayLogs(userId).get();

    for (final doc in logs.docs) {
      final entries = (doc.data()['entries'] as Map<String, dynamic>?);

      if (entries != null && entries.containsKey(habitId)) {
        entries.remove(habitId);
        await doc.reference.update({'entries': entries});
      }
    }
  }


  //  GOALS


  @override
  Future<List<Goal>> getGoals({required String userId}) async {
    final snap = await _goals(userId).get();
    return snap.docs.map((d) => Goal.fromJson(d.data())).toList();
  }

  @override
  Future<Goal> addGoal({required String userId, required Goal goal}) async {
    await _goals(userId).doc(goal.id).set(goal.toJson());
    return goal;
  }

  @override
  Future<Goal> updateGoal({required String userId, required Goal goal}) async {
    await _goals(userId).doc(goal.id).set(goal.toJson());
    return goal;
  }

  @override
  Future<void> deleteGoal({required String userId, required String goalId}) async {
    await _goals(userId).doc(goalId).delete();
  }


  //  DAY LOGS


  @override
  Future<List<DayLog>> getLogsForRange({
    required String userId,
    required DateTime startInclusive,
    required DateTime endInclusive,
  }) async {
    final start = _fmtDate(startInclusive);
    final end = _fmtDate(endInclusive);

    final snap = await _dayLogs(userId)
        .where('date', isGreaterThanOrEqualTo: start)
        .where('date', isLessThanOrEqualTo: end)
        .orderBy('date')
        .get();

    return snap.docs.map((d) => DayLog.fromJson(d.data())).toList();
  }

  @override
  Future<void> upsertDayLog({required String userId, required DayLog log}) async {
    final key = _fmtDate(log.dateUtc);
    await _dayLogs(userId).doc(key).set(log.toJson());
  }


  //  HELPERS


  String _fmtDate(DateTime d) {
    final utc = DateTime.utc(d.year, d.month, d.day);
    return "${utc.year.toString().padLeft(4, '0')}-"
        "${utc.month.toString().padLeft(2, '0')}-"
        "${utc.day.toString().padLeft(2, '0')}";
  }
}