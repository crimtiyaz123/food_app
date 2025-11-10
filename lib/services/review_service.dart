import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/review.dart';

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add a review
  Future<void> addReview(Review review) async {
    await _firestore.collection('reviews').add(review.toJson());
  }

  // Get reviews for a restaurant
  Future<List<Review>> getRestaurantReviews(String restaurantId) async {
    final snapshot = await _firestore
        .collection('reviews')
        .where('restaurantId', isEqualTo: restaurantId)
        .orderBy('date', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => Review.fromJson(doc.id, doc.data()))
        .toList();
  }

  // Get user's reviews
  Future<List<Review>> getUserReviews(String userId) async {
    final snapshot = await _firestore
        .collection('reviews')
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => Review.fromJson(doc.id, doc.data()))
        .toList();
  }

  // Update review
  Future<void> updateReview(String reviewId, Map<String, dynamic> data) async {
    await _firestore.collection('reviews').doc(reviewId).update(data);
  }

  // Delete review
  Future<void> deleteReview(String reviewId) async {
    await _firestore.collection('reviews').doc(reviewId).delete();
  }

  // Get average rating for restaurant
  Future<double> getAverageRating(String restaurantId) async {
    final reviews = await getRestaurantReviews(restaurantId);
    if (reviews.isEmpty) return 0.0;
    final total = reviews.fold<double>(0, (sum, review) => sum + review.rating);
    return total / reviews.length;
  }
}