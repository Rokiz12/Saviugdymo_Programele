import 'package:cloud_firestore/cloud_firestore.dart';

class DiaryEntryModel {
  // modelis
  final String id;
  final DateTime createdAt;
  final String mood;
  final String highlight;
  final String better;
  final String gratitude;
  final String diaryText;
  final String preview;
  final String? imageUrl;
  final String? category;
  final String? moodImage;


  // konstruktorius
  DiaryEntryModel({
    required this.id,
    required this.createdAt,
    required this.mood,
    required this.highlight,
    required this.better,
    required this.gratitude,
    required this.diaryText,
    required this.preview,
    this.imageUrl,
    this.category,
    this.moodImage,

  });

  // Iš Firestore į Modelį
  factory DiaryEntryModel.fromFirestore(
      DocumentSnapshot doc,
      ) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return DiaryEntryModel(
      id: doc.id,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      mood: data['mood'] ?? '',
      highlight: data['highlight'] ?? '',
      better: data['better'] ?? '',
      gratitude: data['gratitude'] ?? '',
      diaryText: data['diaryText'] ?? '',
      preview: data['preview'] ?? '',
      imageUrl: data['imageUrl'],
      category: data['category'],
      moodImage: data['moodImage'],
    );
  }

  // Iš Modelio į Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'createdAt': Timestamp.fromDate(createdAt),
      'mood': mood,
      'highlight': highlight,
      'better': better,
      'gratitude': gratitude,
      'diaryText': diaryText,
      'preview': preview,
      'imageUrl': imageUrl,
      'category': category,
      'moodImage': moodImage,

    };
  }

  // metodas preview generavimui
  static String generatePreview(String highlight, String diaryText) {
    if (highlight.isNotEmpty) {
      return highlight.length > 50
          ? highlight.substring(0, 47) + '...'
          : highlight;
    } else if (diaryText.isNotEmpty) {
      return diaryText.length > 50
          ? diaryText.substring(0, 47) + '...'
          : diaryText;
    } else {
      return "Tuščias įrašas";
    }
  }
}