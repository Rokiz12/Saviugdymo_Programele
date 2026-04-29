import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import '../models/diary_question_model.dart';

class DiaryQuestionRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _questionsRef {
    return _firestore.collection('diaryQuestions');
  }

  // Gauti visus klausimus
  Future<List<DiaryQuestionModel>> getAllQuestions() async {
    final snapshot = await _questionsRef.get();
    return snapshot.docs
        .map((doc) => DiaryQuestionModel.fromFirestore(doc))
        .toList();
  }

  // Gauti N atsitiktinių klausimų
  Future<List<DiaryQuestionModel>> getRandomQuestions(int count) async {
    final allQuestions = await getAllQuestions();

    if (allQuestions.isEmpty) {
      return [];
    }

    final random = Random();
    final selectedQuestions = <DiaryQuestionModel>[];
    final availableIndices = List<int>.generate(allQuestions.length, (i) => i);

    for (int i = 0; i < count && availableIndices.isNotEmpty; i++) {
      final randomIndex = random.nextInt(availableIndices.length);
      selectedQuestions.add(allQuestions[availableIndices[randomIndex]]);
      availableIndices.removeAt(randomIndex);
    }

    return selectedQuestions;
  }

  // Pridėti naują klausimą (tik admin funkcija)
  Future<void> addQuestion(DiaryQuestionModel question) async {
    await _questionsRef.add(question.toFirestore());
  }

  // Gauti klausimus pagal kategoriją
  Future<List<DiaryQuestionModel>> getQuestionsByCategory(String category) async {
    final snapshot = await _questionsRef
        .where('category', isEqualTo: category)
        .get();

    return snapshot.docs
        .map((doc) => DiaryQuestionModel.fromFirestore(doc))
        .toList();
  }

  // Gauti N atsitiktinių klausimų iš konkrečios kategorijos
  Future<List<DiaryQuestionModel>> getRandomQuestionsByCategory(
      String category, int count) async {
    final categoryQuestions = await getQuestionsByCategory(category);

    if (categoryQuestions.isEmpty) {
      return [];
    }

    final random = Random();
    final selectedQuestions = <DiaryQuestionModel>[];
    final availableIndices = List<int>.generate(categoryQuestions.length, (i) => i);

    for (int i = 0; i < count && availableIndices.isNotEmpty; i++) {
      final randomIndex = random.nextInt(availableIndices.length);
      selectedQuestions.add(categoryQuestions[availableIndices[randomIndex]]);
      availableIndices.removeAt(randomIndex);
    }

    return selectedQuestions;
  }

  // Gauti po vieną atsitiktinį klausimą iš kiekvienos kategorijos
  Future<List<DiaryQuestionModel>> getOneRandomFromEachCategory(
      List<String> categories) async {
    final List<DiaryQuestionModel> result = [];

    for (final category in categories) {
      final questionsInCategory = await getRandomQuestionsByCategory(category, 1);
      if (questionsInCategory.isNotEmpty) {
        result.add(questionsInCategory.first);
      }
    }

    return result;
  }
}
