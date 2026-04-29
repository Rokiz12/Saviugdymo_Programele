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

  /// increase userxp
  Future<({int oldLevel, int newLevel})> addUserXp(String userId, int xpToAdd) async {
    int oldLevel = 0;
    int newLevel = 0;

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(_users.doc(userId));
      final data = snap.data() as Map<String, dynamic>;

      oldLevel = data['level'] as int;
      final newXp = (data['xp'] as int) + xpToAdd;
      newLevel = (newXp / 100).floor() + 1;

      tx.update(_users.doc(userId), {
        'xp': newXp,
        'level': newLevel,
      });
    });

    return (oldLevel: oldLevel, newLevel: newLevel);
  }

  /// increase pet xp
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

  /// change pet mood
  Future<void> updatePetMood(String userId, String mood) async {
    await _users.doc(userId).update({'petMood': mood});
  }

  Future<bool> tryGiveDiaryXp(String userId, int xpToAdd) async {
    final userRef = _users.doc(userId);

    return await _firestore.runTransaction((tx) async {
      final snap = await tx.get(userRef);
      final data = snap.data() as Map<String, dynamic>;

      final now = DateTime.now();

      DateTime lastDiaryXp;

      if (data['lastDiaryXp'] != null) {
        lastDiaryXp = (data['lastDiaryXp'] as Timestamp).toDate();
      } else {
        lastDiaryXp = DateTime(2000, 1, 1);
      }

      bool isSameDay(DateTime a, DateTime b) {
        return a.year == b.year &&
            a.month == b.month &&
            a.day == b.day;
      }

      if (isSameDay(lastDiaryXp, now)) {
        return false;
      }

      final newXp = (data['xp'] as int) + xpToAdd;
      final newLevel = (newXp / 100).floor() + 1;

      tx.update(userRef, {
        'xp': newXp,
        'level': newLevel,
        'lastDiaryXp': now,
      });

      return true;
    });
  }

}