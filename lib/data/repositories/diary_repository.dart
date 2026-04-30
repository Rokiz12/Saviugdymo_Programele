import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/diary_entry_model.dart';

class DiaryRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _diaryRef(String userId) {
    return _firestore.collection('users').doc(userId).collection('diary');
  }

  // sukurimas
  Future<void> addEntry(String userId, DiaryEntryModel entry) async {
    await _diaryRef(userId).doc(entry.id).set(entry.toFirestore());
  }

  // skaitymas
  Future<List<DiaryEntryModel>> getEntries(String userId) async {
    final snapshot = await _diaryRef(userId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => DiaryEntryModel.fromFirestore(doc))
        .toList();
  }

  // skaitymas su atsinaujinimu
  Stream<List<DiaryEntryModel>> streamEntries(String userId) {
    return _diaryRef(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => DiaryEntryModel.fromFirestore(doc))
          .toList();
    });
  }

  // skaitymas pagal datų diapazoną
  Future<List<DiaryEntryModel>> getEntriesForDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final snapshot = await _diaryRef(userId)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => DiaryEntryModel.fromFirestore(doc))
        .toList();
  }

  // trinimas
  Future<void> deleteEntry(String userId, String entryId) async {
    await _diaryRef(userId).doc(entryId).delete();
  }
}