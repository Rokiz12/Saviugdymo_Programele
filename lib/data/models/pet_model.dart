// models/pet_model.dart  (represents a pet in the global /pets collection)
class PetModel {
  final String id;
  final String name;
  final String rarity;
  final Map<String, String> images; // image_url
  final Map<String, String> lore;

  PetModel({
    required this.id,
    required this.name,
    required this.rarity,
    required this.images,
    required this.lore,
  });

  factory PetModel.fromMap(String id, Map<String, dynamic> map) {
    return PetModel(
      id: id,
      name: map['name'] ?? '',
      rarity: map['rarity'] ?? 'Common',
      images: Map<String, String>.from(map['images'] ?? {}),
      lore: Map<String, String>.from(map['lore'] ?? {})
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'rarity': rarity,
      'images': images,
      'lore': lore
    };
  }
}