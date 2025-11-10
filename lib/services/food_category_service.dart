import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/food_category.dart';

class FoodCategoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch all food categories from Firestore
  Future<List<FoodCategory>> fetchCategories() async {
    final snapshot = await _firestore.collection('foodCategories').get();
    var items = snapshot.docs
        .map((doc) => FoodCategory.fromJson(doc.id, doc.data() as Map<String, dynamic>))
        .toList();
    return items;
  }
}
