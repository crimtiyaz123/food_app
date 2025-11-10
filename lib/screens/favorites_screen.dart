import 'package:flutter/material.dart';
import '../models/restaurant.dart';
import '../services/restaurant_service.dart';
import 'restaurant_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final RestaurantService _restaurantService = RestaurantService();
  List<Restaurant> _favorites = [];
  bool _isLoading = true;
  String _userId = 'current_user_id'; // TODO: Get from auth

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);
    try {
      final favorites = await _restaurantService.getFavoriteRestaurants(_userId);
      setState(() {
        _favorites = favorites;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading favorites: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Favorites'),
        backgroundColor: Colors.green,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _favorites.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No favorite restaurants yet',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Start exploring and add some favorites!',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _favorites.length,
                  itemBuilder: (context, index) {
                    final restaurant = _favorites[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RestaurantDetailScreen(
                                restaurant: restaurant,
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              // Restaurant Image
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  image: restaurant.imageUrl.isNotEmpty
                                      ? DecorationImage(
                                          image: NetworkImage(restaurant.imageUrl),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: restaurant.imageUrl.isEmpty
                                    ? const Icon(Icons.restaurant, size: 40)
                                    : null,
                              ),
                              const SizedBox(width: 16),

                              // Restaurant Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      restaurant.name,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      restaurant.cuisines.join(', '),
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.star, color: Colors.amber, size: 16),
                                        Text('${restaurant.rating} (${restaurant.reviewCount})'),
                                        const SizedBox(width: 16),
                                        const Icon(Icons.access_time, size: 16),
                                        Text('${restaurant.deliveryTime} min'),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Favorite Icon
                              IconButton(
                                icon: const Icon(Icons.favorite, color: Colors.red),
                                onPressed: () async {
                                  try {
                                    await _restaurantService.removeFromFavorites(_userId, restaurant.id);
                                    setState(() => _favorites.removeAt(index));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('${restaurant.name} removed from favorites')),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error removing favorite: $e')),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}