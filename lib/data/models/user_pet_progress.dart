class UserPetProgress {
  final int xp;
  final int level;
  final int duplicateCount;

  UserPetProgress({this.xp = 0, this.level = 1, this.duplicateCount = 0});

  factory UserPetProgress.fromMap(Map<String, dynamic> map) {
    return UserPetProgress(
      xp: map['xp'] ?? 0,
      level: map['level'] ?? 1,
      duplicateCount: map['duplicateCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {'xp': xp, 'level': level, 'duplicateCount': duplicateCount};
}