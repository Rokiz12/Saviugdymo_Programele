import 'package:cloud_firestore/cloud_firestore.dart';

class DiaryQuestionModel {
  final String id;
  final String question;
  final int maxLines;
  final String category; // e.g., "highlight", "reflect", "gratitude", etc.

  DiaryQuestionModel({
    required this.id,
    required this.question,
    this.maxLines = 2,
    this.category = 'general',
  });

  // Iš Firestore į Modelį
  factory DiaryQuestionModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return DiaryQuestionModel(
      id: doc.id,
      question: data['question'] ?? '',
      maxLines: data['maxLines'] ?? 2,
      category: data['category'] ?? 'general',
    );
  }

  // Iš Modelio į Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'question': question,
      'maxLines': maxLines,
      'category': category,
    };
  }
}

