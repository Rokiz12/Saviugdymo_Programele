import 'package:cloud_firestore/cloud_firestore.dart';

class DiaryEntryModel {
  final String id;
  final String content;
  final DateTime createdAt;
  final int? moodRating; // optional for future stats

  DiaryEntryModel({
    required this.id,
    required this.content,
    required this.createdAt,
    this.moodRating,
  });

  factory DiaryEntryModel.fromMap(String id, Map<String, dynamic> map) {
    return DiaryEntryModel(
      id: id,
      content: map['content'] ?? "",
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      moodRating: map['moodRating'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'content': content,
      'createdAt': createdAt,
      'moodRating': moodRating,
    };
  }
}