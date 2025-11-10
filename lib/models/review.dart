class Review {
  final String id;
  final String userId;
  final String restaurantId;
  final String orderId;
  final double rating;
  final String comment;
  final DateTime date;
  final String userName;

  Review({
    required this.id,
    required this.userId,
    required this.restaurantId,
    required this.orderId,
    required this.rating,
    required this.comment,
    required this.date,
    required this.userName,
  });

  factory Review.fromJson(String id, Map<String, dynamic> json) {
    return Review(
      id: id,
      userId: json['userId'] ?? '',
      restaurantId: json['restaurantId'] ?? '',
      orderId: json['orderId'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      comment: json['comment'] ?? '',
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      userName: json['userName'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'restaurantId': restaurantId,
      'orderId': orderId,
      'rating': rating,
      'comment': comment,
      'date': date.toIso8601String(),
      'userName': userName,
    };
  }
}