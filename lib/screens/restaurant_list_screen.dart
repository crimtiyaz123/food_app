import 'package:flutter/material.dart';
import '../models/restaurant.dart';
import '../services/restaurant_service.dart';
import 'restaurant_detail_screen.dart';

class RestaurantListScreen extends StatefulWidget {
  const RestaurantListScreen({super.key});

  @override
  State<RestaurantListScreen> createState() => _RestaurantListScreenState();
}

class _RestaurantListScreenState extends State<RestaurantListScreen> {
  final RestaurantService _restaurantService = RestaurantService();
  List<Restaurant> _restaurants = [];
  List<Restaurant> _filteredRestaurants = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCuisine = 'All';

  @override
  void initState() {
    super.initState();
    _loadRestaurants();
  }

  Future<void> _loadRestaurants() async {
    setState(() => _isLoading = true);
    try {
      final restaurants = await _restaurantService.fetchRestaurants();
      setState(() {
        _restaurants = restaurants;
        _filteredRestaurants = restaurants;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading restaurants: $e')),
      );
    }
  }

  void _filterRestaurants() {
    setState(() {
      _filteredRestaurants = _restaurants.where((restaurant) {
        final matchesSearch = _searchQuery.isEmpty ||
            restaurant.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            restaurant.cuisines.any((cuisine) =>
                cuisine.toLowerCase().contains(_searchQuery.toLowerCase()));

        final matchesCuisine = _selectedCuisine == 'All' ||
            restaurant.cuisines.contains(_selectedCuisine);

        return matchesSearch && matchesCuisine;
      }).toList();
    });
  }

  List<String> _getAllCuisines() {
    final Set<String> cuisines = {};
    for (var restaurant in _restaurants) {
      cuisines.addAll(restaurant.cuisines);
    }
    return ['All', ...cuisines.toList()..sort()];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurants'),
        backgroundColor: Colors.green,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search restaurants or cuisines...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onChanged: (value) {
                      _searchQuery = value;
                      _filterRestaurants();
                    },
                  ),
                ),

                // Cuisine Filter
                SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _getAllCuisines().length,
                    itemBuilder: (context, index) {
                      final cuisine = _getAllCuisines()[index];
                      final isSelected = cuisine == _selectedCuisine;
                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedCuisine = cuisine);
                          _filterRestaurants();
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.green : Colors.grey[300],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Text(
                              cuisine,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Restaurants List
                Expanded(
                  child: _filteredRestaurants.isEmpty
                      ? const Center(child: Text('No restaurants found'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredRestaurants.length,
                          itemBuilder: (context, index) {
                            final restaurant = _filteredRestaurants[index];
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
                                            const SizedBox(height: 4),
                                            Text(
                                              '\$${restaurant.deliveryFee} delivery • Min \$${restaurant.minOrder}',
                                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Status
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: restaurant.isOpen ? Colors.green : Colors.red,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          restaurant.isOpen ? 'Open' : 'Closed',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}