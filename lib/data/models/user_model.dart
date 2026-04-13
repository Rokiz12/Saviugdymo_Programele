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
  final Map<String, UserPetProgress> ownedPets;
  final String petMood;

  UserModel({
    required this.id,
    this.email,
    this.xp = 0,
    this.level = 1,
    this.coins = 0,
    required this.createdAt,
    this.equippedPetId = '',
    DateTime? lastDailyReward,
    this.ownedPets = const {},
    this.petMood = 'happy',
  }) : lastDailyReward = lastDailyReward ?? DateTime(2000, 1, 1);

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
      ownedPets: (map['ownedPets'] as Map<String, dynamic>? ?? {}).map(
            (petId, data) => MapEntry(
          petId,
          UserPetProgress.fromMap(Map<String, dynamic>.from(data as Map)),
        ),
      ),
      petMood: map['petMood'] ?? 'happy',
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
      'ownedPets': ownedPets.map((petId, progress) => MapEntry(petId, progress.toMap())),
      'petMood': petMood,
    };
  }
}

