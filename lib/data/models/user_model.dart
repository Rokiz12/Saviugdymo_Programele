import 'package:cloud_firestore/cloud_firestore.dart';

// models/user_model.dart
class UserModel {
  final String id;
  final String? email;
  final int xp;
  final int level;
  final int coins;
  final DateTime createdAt;
  final String equippedPetId;
  final List<String> ownedPetIds;
  final String petMood;

  UserModel({
    required this.id,
    this.email,
    this.xp = 0,
    this.level = 1,
    this.coins = 0,
    required this.createdAt,
    this.equippedPetId = '',
    this.ownedPetIds = const [],
    this.petMood = 'happy',
  });

  factory UserModel.fromMap(String id, Map<String, dynamic> map) {
    return UserModel(
      id: id,
      email: map['email'],
      xp: map['xp'] ?? 0,
      level: map['level'] ?? 1,
      coins: map['coins'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      equippedPetId: map['equippedPetId'] ?? '',
      ownedPetIds: List<String>.from(map['ownedPetIds'] ?? []),
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
      'ownedPetIds': ownedPetIds,
      'petMood': petMood,
    };
  }
}

