import 'package:cloud_firestore/cloud_firestore.dart';

class QuoteRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetches all motivational quotes from Firestore.
  /// Expected collection: "quotes"
  /// Expected document fields: { "text": "string" }
  Future<List<String>> getQuotes() async {
    try {
      final snapshot = await _firestore.collection('quotes').get();
      return snapshot.docs
          .map((doc) => doc.data()['text'] as String? ?? '')
          .where((text) => text.isNotEmpty)
          .toList();
    } catch (e) {
      // Return fallback quotes if Firestore fetch fails
      return [
        'Keep going — every step counts!',
        'You showed up today. That\'s already a win.',
        'Small progress is still progress.',
        'Believe in yourself!',
        'You\'re stronger than you think.',
      ];
    }
  }
}