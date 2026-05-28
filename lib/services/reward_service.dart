import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/pet_model.dart';
import '../data/models/user_model.dart';
import '../data/models/user_pet_progress.dart';
import 'reward_notifier.dart';


class RewardService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const Map<String, int> _rarityWeights = {
    'Common':    50,
    'Rare':      30,
    'Epic':      15,
    'Legendary':  5,
  };

  // Skin unlock thresholds: duplicateCount -> skinKey
  static const Map<int, String> _skinUnlockThresholds = {
    5:  'skin_1',
    10: 'skin_2',
  };

  Future<List<PetModel>> _getAllPets() async {
    final snap = await _db.collection('pets').get();
    return snap.docs.map((d) => PetModel.fromMap(d.id, d.data())).toList();
  }

  PetModel _pickPetByRarity(List<PetModel> pets) {
    final totalWeight = _rarityWeights.values.fold(0, (a, b) => a + b);
    final roll = Random().nextInt(totalWeight);
    int cumulative = 0;
    String chosenRarity = 'Common';
    for (final entry in _rarityWeights.entries) {
      cumulative += entry.value;
      if (roll < cumulative) {
        chosenRarity = entry.key;
        break;
      }
    }
    final pool = pets.where((p) => p.rarity == chosenRarity).toList();
    final finalPool = pool.isNotEmpty ? pool : pets;
    return finalPool[Random().nextInt(finalPool.length)];
  }

  /// Returns the skin key to unlock if the new duplicateCount hits a threshold,
  /// or null if no skin should be unlocked.
  String? _skinToUnlock({
    required int newDuplicateCount,
    required List<String> alreadyUnlockedSkins,
  }) {
    final skinKey = _skinUnlockThresholds[newDuplicateCount];
    if (skinKey == null) return null;
    if (alreadyUnlockedSkins.contains(skinKey)) return null;
    return skinKey;
  }

  /// Call this on app start. Checks if user already claimed today.
  Future<void> checkDailyReward(UserModel user, RewardNotifier notifier) async {
    final userDoc = _db.collection('users').doc(user.id);

    PetModel? picked;
    bool isDuplicate = false;
    String? unlockedSkin;

    final granted = await _db.runTransaction<bool>((tx) async {
      final snap = await tx.get(userDoc);
      final data = snap.data()!;
      final lastClaim = (data['lastDailyReward'] as Timestamp?)?.toDate();
      final now = DateTime.now();

      final alreadyClaimed = lastClaim != null &&
          lastClaim.year == now.year &&
          lastClaim.month == now.month &&
          lastClaim.day == now.day;

      if (alreadyClaimed) return false;

      bool streakBroken = false;
      if (lastClaim != null) {
        final lastClaimDay = DateTime(lastClaim.year, lastClaim.month, lastClaim.day);
        final today = DateTime(now.year, now.month, now.day);
        final daysDiff = today.difference(lastClaimDay).inDays;
        streakBroken = daysDiff > 1;
      }

      tx.update(userDoc, {
        'lastDailyReward': FieldValue.serverTimestamp(),
        'streak': streakBroken ? 1 : FieldValue.increment(1),
      });

      return true;
    });

    if (!granted) return;

    final pets = await _getAllPets();
    if (pets.isEmpty) return;
    picked = _pickPetByRarity(pets);
    isDuplicate = user.ownedPets.containsKey(picked.id);

    if (!isDuplicate) {
      await userDoc.update({
        'ownedPets.${picked.id}': {
          'xp': 0,
          'level': 1,
          'duplicateCount': 0,
          'equippedSkinKey': '',
          'unlockedSkins': [],
        },
      });
    } else {
      // Read current pet progress to compute new duplicateCount
      final petProgress = user.ownedPets[picked.id]!;
      final newDuplicateCount = petProgress.duplicateCount + 1;
      unlockedSkin = _skinToUnlock(
        newDuplicateCount: newDuplicateCount,
        alreadyUnlockedSkins: petProgress.unlockedSkins,
      );

      await userDoc.update({
        'ownedPets.${picked.id}.duplicateCount': FieldValue.increment(1),
        if (unlockedSkin != null)
          'ownedPets.${picked.id}.unlockedSkins': FieldValue.arrayUnion([unlockedSkin]),
      });
    }

    notifier.enqueue(PendingReward(
      type: RewardType.dailyLogin,
      pet: picked,
      isDuplicate: isDuplicate,
    ));
  }

  /// Call this after any XP award
  Future<void> checkLevelUp({
    required String userId,
    required int oldLevel,
    required int newLevel,
    required RewardNotifier notifier,
  }) async {
    if (newLevel <= oldLevel) return;

    final pets = await _getAllPets();
    if (pets.isEmpty) return;
    final picked = _pickPetByRarity(pets);
    final userRef = _db.collection('users').doc(userId);

    String? unlockedSkin;

    final isDuplicate = await _db.runTransaction<bool>((tx) async {
      final snap = await tx.get(userRef);
      final data = snap.data() as Map<String, dynamic>;
      final ownedPets = data['ownedPets'] as Map<String, dynamic>? ?? {};
      final duplicate = ownedPets.containsKey(picked.id);

      if (!duplicate) {
        tx.update(userRef, {
          'ownedPets.${picked.id}': {
            'xp': 0,
            'level': 1,
            'duplicateCount': 0,
            'equippedSkinKey': '',
            'unlockedSkins': [],
          },
        });
      } else {
        // Parse current pet progress from inside the transaction
        final petProgress = UserPetProgress.fromMap(
          Map<String, dynamic>.from(ownedPets[picked.id] as Map),
        );
        final newDuplicateCount = petProgress.duplicateCount + 1;
        final skinKey = _skinToUnlock(
          newDuplicateCount: newDuplicateCount,
          alreadyUnlockedSkins: petProgress.unlockedSkins,
        );
        // Capture for use outside the transaction
        unlockedSkin = skinKey;

        tx.update(userRef, {
          'ownedPets.${picked.id}.duplicateCount': FieldValue.increment(1),
          if (skinKey != null)
            'ownedPets.${picked.id}.unlockedSkins': FieldValue.arrayUnion([skinKey]),
        });
      }

      return duplicate;
    });

    notifier.enqueue(PendingReward(
      type: RewardType.levelUp,
      pet: picked,
      isDuplicate: isDuplicate,
      newLevel: newLevel,
    ));
  }
}