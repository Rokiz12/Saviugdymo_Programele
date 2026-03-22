class UserPetProgress {
  final int xp;
  final int level;

  UserPetProgress({this.xp = 0, this.level = 1});

  factory UserPetProgress.fromMap(Map<String, dynamic> map) {
    return UserPetProgress(
      xp: map['xp'] ?? 0,
      level: map['level'] ?? 1,
    );
  }

  Map<String, dynamic> toMap() => {'xp': xp, 'level': level};
}