class UserPetProgress {
  final int xp;
  final int level;
  final int duplicateCount;
  final List<String> unlockedSkins;
  final String equippedSkinKey;

  UserPetProgress({this.xp = 0, this.level = 1, this.duplicateCount = 0, this.unlockedSkins = const [],
    this.equippedSkinKey = '',});

  factory UserPetProgress.fromMap(Map<String, dynamic> map) {
    return UserPetProgress(
      xp: map['xp'] ?? 0,
      level: map['level'] ?? 1,
      duplicateCount: map['duplicateCount'] ?? 0,
      unlockedSkins: List<String>.from(map['unlockedSkins'] ?? []),
      equippedSkinKey: map['equippedSkinKey'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {'xp': xp, 'level': level, 'duplicateCount': duplicateCount, 'unlockedSkins': unlockedSkins,
    'equippedSkinKey': equippedSkinKey,};
}