import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/shop_item_model.dart';

class ShopRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _shop =>
      _firestore.collection('shop_items');

  /// add shop item (admin use)
  Future<void> addItem(ShopItemModel item) async {
    await _shop.doc(item.id).set(item.toMap());
  }

  /// get all shop items
  Future<List<ShopItemModel>> getItems() async {
    final snapshot = await _shop.get();

    return snapshot.docs
        .map((doc) => ShopItemModel.fromMap(
              doc.id,
              doc.data() as Map<String, dynamic>,
            ))
        .toList();
  }
}