class AvatarModel {
  final String selectedSkin;
  final String? equippedItem;
  final String mood;

  AvatarModel({
    this.selectedSkin = "default",
    this.equippedItem,
    this.mood = "happy",
  });

  factory AvatarModel.fromMap(Map<String, dynamic> map) {
    return AvatarModel(
      selectedSkin: map['selectedSkin'] ?? "default",
      equippedItem: map['equippedItem'],
      mood: map['mood'] ?? "happy",
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'selectedSkin': selectedSkin,
      'equippedItem': equippedItem,
      'mood': mood,
    };
  }
}