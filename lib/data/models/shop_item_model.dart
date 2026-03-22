class ShopItemModel {
  final String id;
  final String name;
  final int price;
  final String type;
  final String image;

  ShopItemModel({
    required this.id,
    required this.name,
    required this.price,
    required this.type,
    required this.image,
  });

  factory ShopItemModel.fromMap(String id, Map<String, dynamic> map) {
    return ShopItemModel(
      id: id,
      name: map['name'],
      price: map['price'] ?? 0,
      type: map['type'] ?? "unknown",
      image: map['image'] ?? "",
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'type': type,
      'image': image,
    };
  }
}