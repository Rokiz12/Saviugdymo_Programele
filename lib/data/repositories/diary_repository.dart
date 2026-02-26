import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/diary_entry_model.dart';

class DiaryRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference _diaryRef(String userId) =>
      _firestore.collection('users').doc(userId).collection('diary');

  /// add diary entry
  Future<void> addEntry(String userId, DiaryEntryModel entry) async {
    await _diaryRef(userId).doc(entry.id).set(entry.toMap());
  }

  /// get all diary entries
  Future<List<DiaryEntryModel>> getEntries(String userId) async {
    final snapshot = await _diaryRef(userId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => DiaryEntryModel.fromMap(
              doc.id,
              doc.data() as Map<String, dynamic>,
            ))
        .toList();
  }
}