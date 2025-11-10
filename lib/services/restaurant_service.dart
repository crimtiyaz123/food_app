import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/restaurant.dart';
import '../models/product.dart';

class RestaurantService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch all restaurants
  Future<List<Restaurant>> fetchRestaurants() async {
    final snapshot = await _firestore.collection('restaurants').get();
    return snapshot.docs
        .map((doc) => Restaurant.fromJson(doc.id, doc.data() as Map<String, dynamic>))
        .toList();
  }

  // Fetch restaurants by cuisine
  Future<List<Restaurant>> fetchRestaurantsByCuisine(String cuisine) async {
    final snapshot = await _firestore
        .collection('restaurants')
        .where('cuisines', arrayContains: cuisine)
        .get();
    return snapshot.docs
        .map((doc) => Restaurant.fromJson(doc.id, doc.data() as Map<String, dynamic>))
        .toList();
  }

  // Search restaurants by name or cuisine
  Future<List<Restaurant>> searchRestaurants(String query) async {
    final snapshot = await _firestore.collection('restaurants').get();
    final allRestaurants = snapshot.docs
        .map((doc) => Restaurant.fromJson(doc.id, doc.data() as Map<String, dynamic>))
        .toList();

    return allRestaurants.where((restaurant) {
      final nameMatch = restaurant.name.toLowerCase().contains(query.toLowerCase());
      final cuisineMatch = restaurant.cuisines.any(
        (cuisine) => cuisine.toLowerCase().contains(query.toLowerCase())
      );
      return nameMatch || cuisineMatch;
    }).toList();
  }

  // Fetch menu for a specific restaurant
  Future<List<Product>> fetchRestaurantMenu(String restaurantId) async {
    final snapshot = await _firestore
        .collection('restaurants')
        .doc(restaurantId)
        .collection('menu')
        .get();
    return snapshot.docs
        .map((doc) => Product.fromJson(doc.id, doc.data() as Map<String, dynamic>))
        .toList();
  }

  // Add restaurant to favorites
  Future<void> addToFavorites(String userId, String restaurantId) async {
    await _firestore.collection('favorites').add({
      'userId': userId,
      'restaurantId': restaurantId,
      'dateAdded': Timestamp.now(),
    });
  }

  // Remove from favorites
  Future<void> removeFromFavorites(String userId, String restaurantId) async {
    final snapshot = await _firestore
        .collection('favorites')
        .where('userId', isEqualTo: userId)
        .where('restaurantId', isEqualTo: restaurantId)
        .get();

    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  // Create a new restaurant
  Future<void> createRestaurant(Restaurant restaurant) async {
    await _firestore.collection('restaurants').add(restaurant.toJson());
  }

  // Get user's favorite restaurants
  Future<List<String>> getFavoriteRestaurantIds(String userId) async {
    final snapshot = await _firestore
        .collection('favorites')
        .where('userId', isEqualTo: userId)
        .get();
    return snapshot.docs.map((doc) => doc['restaurantId'] as String).toList();
  }

  // Get user's favorite restaurants with details
  Future<List<Restaurant>> getFavoriteRestaurants(String userId) async {
    final favoriteIds = await getFavoriteRestaurantIds(userId);
    if (favoriteIds.isEmpty) return [];

    final snapshot = await _firestore
        .collection('restaurants')
        .where(FieldPath.documentId, whereIn: favoriteIds)
        .get();

    return snapshot.docs
        .map((doc) => Restaurant.fromJson(doc.id, doc.data() as Map<String, dynamic>))
        .toList();
  }
}