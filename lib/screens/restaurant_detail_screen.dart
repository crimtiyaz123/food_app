import 'package:flutter/material.dart';
import '../models/restaurant.dart';
import '../models/product.dart';
import '../models/review.dart';
import '../services/restaurant_service.dart';
import '../services/review_service.dart';
import '../models/cart_model.dart';
import 'package:provider/provider.dart';

class RestaurantDetailScreen extends StatefulWidget {
  final Restaurant restaurant;

  const RestaurantDetailScreen({super.key, required this.restaurant});

  @override
  State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen> {
  final RestaurantService _restaurantService = RestaurantService();
  final ReviewService _reviewService = ReviewService();
  List<Product> _menu = [];
  List<Review> _reviews = [];
  bool _isLoadingMenu = true;
  bool _isLoadingReviews = true;
  bool _isFavorite = false;
  String _userId = 'current_user_id'; // TODO: Get from auth

  @override
  void initState() {
    super.initState();
    _loadMenu();
    _loadReviews();
    _checkFavorite();
  }

  Future<void> _loadMenu() async {
    setState(() => _isLoadingMenu = true);
    try {
      final menu = await _restaurantService.fetchRestaurantMenu(widget.restaurant.id);
      setState(() {
        _menu = menu;
        _isLoadingMenu = false;
      });
    } catch (e) {
      setState(() => _isLoadingMenu = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading menu: $e')),
      );
    }
  }

  Future<void> _loadReviews() async {
    setState(() => _isLoadingReviews = true);
    try {
      final reviews = await _reviewService.getRestaurantReviews(widget.restaurant.id);
      setState(() {
        _reviews = reviews;
        _isLoadingReviews = false;
      });
    } catch (e) {
      setState(() => _isLoadingReviews = false);
    }
  }

  Future<void> _checkFavorite() async {
    try {
      final favorites = await _restaurantService.getFavoriteRestaurantIds(_userId);
      setState(() => _isFavorite = favorites.contains(widget.restaurant.id));
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _toggleFavorite() async {
    try {
      if (_isFavorite) {
        await _restaurantService.removeFromFavorites(_userId, widget.restaurant.id);
      } else {
        await _restaurantService.addToFavorites(_userId, widget.restaurant.id);
      }
      setState(() => _isFavorite = !_isFavorite);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating favorites: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Restaurant Header
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  widget.restaurant.imageUrl.isNotEmpty
                      ? Image.network(widget.restaurant.imageUrl, fit: BoxFit.cover)
                      : Container(color: Colors.grey[300]),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                      ),
                    ),
                  ),
                ],
              ),
              title: Text(
                widget.restaurant.name,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: _isFavorite ? Colors.red : Colors.white,
                ),
                onPressed: _toggleFavorite,
              ),
            ],
          ),

          // Restaurant Info
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber),
                      Text('${widget.restaurant.rating} (${widget.restaurant.reviewCount} reviews)'),
                      const SizedBox(width: 16),
                      const Icon(Icons.access_time),
                      Text('${widget.restaurant.deliveryTime} min'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(widget.restaurant.description),
                  const SizedBox(height: 8),
                  Text(
                    'Delivery: \$${widget.restaurant.deliveryFee} • Min order: \$${widget.restaurant.minOrder}',
                    style: const TextStyle(color: Colors.green),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: widget.restaurant.cuisines.map((cuisine) => Chip(label: Text(cuisine))).toList(),
                  ),
                ],
              ),
            ),
          ),

          // Menu Section
          SliverToBoxAdapter(
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Menu',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          _isLoadingMenu
              ? const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final product = _menu[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: ListTile(
                          title: Text(product.name),
                          subtitle: Text(product.description ?? ''),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('\$${product.price.toStringAsFixed(2)}'),
                              const SizedBox(width: 8),
ElevatedButton(
                                onPressed: () {
                                  context.read<CartModel>().addItem(
                                    product,
                                    restaurantId: widget.restaurant.id
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('${product.name} added to cart')),
                                  );
                                },
                                child: const Text('Add'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: _menu.length,
                  ),
                ),

          // Reviews Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Reviews',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      // TODO: Navigate to add review screen
                    },
                    child: const Text('Add Review'),
                  ),
                ],
              ),
            ),
          ),

          _isLoadingReviews
              ? const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final review = _reviews[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.person),
                                  const SizedBox(width: 8),
                                  Text(review.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  const Spacer(),
                                  Row(
                                    children: List.generate(5, (starIndex) {
                                      return Icon(
                                        starIndex < review.rating ? Icons.star : Icons.star_border,
                                        color: Colors.amber,
                                        size: 16,
                                      );
                                    }),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(review.comment),
                              const SizedBox(height: 4),
                              Text(
                                '${review.date.day}/${review.date.month}/${review.date.year}',
                                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: _reviews.length,
                  ),
                ),
        ],
      ),
    );
  }
}