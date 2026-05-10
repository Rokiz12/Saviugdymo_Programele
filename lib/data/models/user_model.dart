import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_pet_progress.dart';
// models/user_model.dart
class UserModel {
  final String id;
  final String? email;
  final int xp;
  final int level;
  final int coins;
  final DateTime createdAt;
  final String equippedPetId;
  final DateTime lastDailyReward;
  final DateTime lastDiaryXp;
  final DateTime? lastRewardNotificationSent;
  final List<String> fcmTokens;
  final Map<String, UserPetProgress> ownedPets;
  final String petMood;
  final int streak;
  final bool premium;

  UserModel({
    required this.id,
    this.email,
    this.xp = 0,
    this.level = 1,
    this.coins = 0,
    required this.createdAt,
    this.equippedPetId = '',
    DateTime? lastDailyReward,
    DateTime? lastDiaryXp,
    this.lastRewardNotificationSent,
    this.fcmTokens = const [],
    this.ownedPets = const {},
    this.petMood = 'happy',
    this.streak = 0,
    this.premium = false,
  }) : lastDailyReward = lastDailyReward ?? DateTime(2000, 1, 1),
       lastDiaryXp = lastDiaryXp ?? DateTime(2000, 1, 1);

  factory UserModel.fromMap(String id, Map<String, dynamic> map) {
    return UserModel(
      id: id,
      email: map['email'],
      xp: map['xp'] ?? 0,
      level: map['level'] ?? 1,
      coins: map['coins'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      equippedPetId: map['equippedPetId'] ?? '',
      lastDailyReward: map['lastDailyReward'] != null
          ? (map['lastDailyReward'] as Timestamp).toDate()
          : null,
      lastDiaryXp: map['lastDiaryXp'] != null
          ? (map['lastDiaryXp'] as Timestamp).toDate()
          : null,
      lastRewardNotificationSent: map['lastRewardNotificationSent'] != null
          ? (map['lastRewardNotificationSent'] as Timestamp).toDate()
          : null,
      fcmTokens: List<String>.from(map['fcmTokens'] ?? []),
      ownedPets: (map['ownedPets'] as Map<String, dynamic>? ?? {}).map(
            (petId, data) => MapEntry(
          petId,
          UserPetProgress.fromMap(Map<String, dynamic>.from(data as Map)),
        ),
      ),
      petMood: map['petMood'] ?? 'happy',
      streak: map['streak'] ?? 0,
      premium: map['premium'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'xp': xp,
      'level': level,
      'coins': coins,
      'createdAt': createdAt,
      'equippedPetId': equippedPetId,
      'lastDailyReward': lastDailyReward,
      'lastDiaryXp':lastDiaryXp,
      'lastRewardNotificationSent': lastRewardNotificationSent,
      'fcmTokens': fcmTokens,
      'ownedPets': ownedPets.map((petId, progress) => MapEntry(petId, progress.toMap())),
      'petMood': petMood,
      'streak': streak,
      'premium': premium,
    };
  }
}

