// models/pet_model.dart  (represents a pet in the global /pets collection)
class PetModel {
  final String id;
  final String name;
  final String lore;
  final String rarity;
  final Map<String, String> images; // image_url

  PetModel({
    required this.id,
    required this.name,
    required this.lore,
    required this.rarity,
    required this.images,
  });

  factory PetModel.fromMap(String id, Map<String, dynamic> map) {
    return PetModel(
      id: id,
      name: map['name'] ?? '',
      lore: map['lore'] ?? '',
      rarity: map['rarity'] ?? 'common',
      images: Map<String, String>.from(map['images'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'lore': lore,
      'rarity': rarity,
      'images': images,
    };
  }
}