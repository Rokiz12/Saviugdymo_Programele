import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pet_model.dart';

// repositories/pet_repository.dart
class PetRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _pets => _firestore.collection('pets');

  Future<PetModel?> getPet(String petId) async {
    final doc = await _pets.doc(petId).get();
    if (!doc.exists) return null;
    return PetModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }

  Future<List<PetModel>> getAllPets() async {
    final snapshot = await _pets.get();
    return snapshot.docs
        .map((doc) => PetModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList();
  }

  Future<List<PetModel>> getPetsByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final snapshot = await _pets.where(FieldPath.documentId, whereIn: ids).get();
    return snapshot.docs
        .map((doc) => PetModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList();
  }
}