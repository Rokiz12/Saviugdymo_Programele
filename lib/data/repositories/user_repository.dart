import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/user_pet_progress.dart';

class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _users => _firestore.collection('users');

  /// create new user
  Future<void> createUser(UserModel user) async {
    await _users.doc(user.id).set(user.toMap());
  }

  /// get user by ID
  Future<UserModel?> getUser(String userId) async {
    final doc = await _users.doc(userId).get();

    if (!doc.exists) return null;

    return UserModel.fromMap(
      doc.id,
      doc.data() as Map<String, dynamic>,
    );
  }

  Future<void> equipPet(String userId, String petId) async {
    await _users.doc(userId).update({'equippedPetId': petId});
  }

  Future<void> addOwnedPet(String userId, String petId) async {
    await _users.doc(userId).update({
      'ownedPets.$petId': {
        'xp': 0,
        'level': 1,
      }
    });
  }

  Future<void> addPetXp(String userId, String petId, int xpToAdd) async {
    final user = await getUser(userId);
    if (user == null) return;

    final current = user.ownedPets[petId] ?? UserPetProgress();
    final newXp = current.xp + xpToAdd;
    final newLevel = (newXp / 100).floor() + 1; // every 100xp = 1 level

    await _users.doc(userId).update({
      'ownedPets.$petId': {
        'xp': newXp,
        'level': newLevel,
      }
    });
  }

  Future<void> updatePetMood(String userId, String mood) async {
    await _users.doc(userId).update({'petMood': mood});
  }

}