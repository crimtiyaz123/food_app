import 'package:flutter/material.dart';
import '../models/restaurant.dart';
import '../models/product.dart';
import '../services/restaurant_service.dart';
import '../services/ai_recommendation_service.dart';
import '../services/location_service.dart';
import '../widgets/enhanced_ui_components.dart';
import 'restaurant_detail_screen.dart';

class RestaurantDiscoveryScreen extends StatefulWidget {
  const RestaurantDiscoveryScreen({super.key});

  @override
  State<RestaurantDiscoveryScreen> createState() => _RestaurantDiscoveryScreenState();
}

class _RestaurantDiscoveryScreenState extends State<RestaurantDiscoveryScreen> 
    with TickerProviderStateMixin {
  final RestaurantService _restaurantService = RestaurantService();
  final AIRecommendationService _aiRecommendationService = AIRecommendationService();
  final LocationService _locationService = LocationService();
  
  late AnimationController _filterController;
  late Animation<double> _filterAnimation;
  late AnimationController _searchAnimController;
  late Animation<Offset> _searchAnimation;
  
  // Search and Filter States
  final TextEditingController _searchTextController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  
  List<Restaurant> _allRestaurants = [];
  List<Restaurant> _filteredRestaurants = [];
  List<String> _searchSuggestions = [];
  List<String> _cuisineSuggestions = [];
  
  // Filter States
  bool _isLoading = true;
  bool _showFilters = false;
  String _selectedLocation = 'Current Location';
  Map<String, dynamic>? _currentPosition;
  
  // Advanced Filters
  String _selectedCuisine = '';
  RangeValues _priceRange = const RangeValues(0, 100);
  RangeValues _ratingRange = const RangeValues(0, 5);
  RangeValues _deliveryTimeRange = const RangeValues(10, 90);
  double _deliveryFee = 10.0;
  
  List<String> _selectedDietary = [];
  List<String> _selectedFeatures = [];
  List<String> _selectedTags = [];
  String _sortBy = 'relevance';
  
  // Available filter options
  final List<String> _cuisines = [
    'American', 'Italian', 'Asian', 'Mexican', 'Indian', 'Mediterranean',
    'French', 'Japanese', 'Thai', 'Chinese', 'Korean', 'Vietnamese',
    'Greek', 'Spanish', 'Lebanese', 'Turkish', 'Ethiopian', 'Brazilian'
  ];
  
  final List<String> _dietaryOptions = [
    'Vegetarian', 'Vegan', 'Gluten-Free', 'Dairy-Free', 'Nut-Free', 'Halal', 'Kosher'
  ];
  
  final List<String> _featureOptions = [
    'Free Delivery', 'Fast Delivery', 'Cashback Offers', 'Loyalty Points',
    'Contactless Delivery', 'Group Ordering', 'Scheduled Delivery', 'Eco-Friendly'
  ];
  
  final List<String> _tagOptions = [
    'Trending', 'Popular', 'New', 'Recommended', 'Budget-Friendly', 'Premium',
    'Healthy', 'Organic', 'Spicy', 'Mild', 'Family-Friendly', 'Pet-Friendly'
  ];
  
  final List<Map<String, dynamic>> _sortOptions = [
    {'value': 'relevance', 'label': 'Relevance'},
    {'value': 'rating', 'label': 'Rating'},
    {'value': 'delivery_time', 'label': 'Delivery Time'},
    {'value': 'delivery_fee', 'label': 'Delivery Fee'},
    {'value': 'distance', 'label': 'Distance'},
    {'value': 'price_low_high', 'label': 'Price: Low to High'},
    {'value': 'price_high_low', 'label': 'Price: High to Low'},
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadRestaurants();
    _getCurrentLocation();
  }

  void _initializeAnimations() {
    _filterController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _filterAnimation = CurvedAnimation(
      parent: _filterController,
      curve: Curves.easeInOut,
    );
    
    _searchAnimController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _searchAnimation = Tween<Offset>(
      begin: const Offset(0, -0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _searchAnimController, curve: Curves.easeOut));
    
    _searchAnimController.forward();
  }

  @override
  void dispose() {
    _filterController.dispose();
    _searchAnimController.dispose();
    _searchTextController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      // For now, use mock location data
      // In production, you would use proper geolocation services
      setState(() {
        _currentPosition = {
          'latitude': 40.7128,
          'longitude': -74.0060,
          'address': 'New York, NY'
        };
      });
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  Future<void> _loadRestaurants() async {
    try {
      setState(() => _isLoading = true);
      
      // Load restaurants from service
      final restaurants = await _restaurantService.fetchRestaurants();
      setState(() {
        _allRestaurants = restaurants;
        _filteredRestaurants = restaurants;
        _isLoading = false;
      });
      
      // Generate search suggestions
      _generateSearchSuggestions();
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load restaurants: $e');
    }
  }

  void _generateSearchSuggestions() {
    final Set<String> suggestions = {};
    
    // Add restaurant names
    for (final restaurant in _allRestaurants) {
      suggestions.add(restaurant.name);
      suggestions.addAll(restaurant.cuisines);
    }
    
    // Add cuisine types
    suggestions.addAll(_cuisines);
    
    setState(() {
      _searchSuggestions = suggestions.toList()..sort();
      _cuisineSuggestions = _cuisines;
    });
  }

  void _filterRestaurants() {
    setState(() {
      _filteredRestaurants = _allRestaurants.where((restaurant) {
        // Text search
        final matchesSearch = _searchTextController.text.isEmpty ||
            restaurant.name.toLowerCase().contains(_searchTextController.text.toLowerCase()) ||
            restaurant.description.toLowerCase().contains(_searchTextController.text.toLowerCase()) ||
            restaurant.cuisines.any((cuisine) => 
                cuisine.toLowerCase().contains(_searchTextController.text.toLowerCase()));
        
        // Cuisine filter
        final matchesCuisine = _selectedCuisine.isEmpty ||
            restaurant.cuisines.contains(_selectedCuisine);
        
        // Rating filter
        final matchesRating = restaurant.rating >= _ratingRange.start &&
            restaurant.rating <= _ratingRange.end;
        
        // Delivery time filter
        final matchesDeliveryTime = restaurant.deliveryTime >= _deliveryTimeRange.start &&
            restaurant.deliveryTime <= _deliveryTimeRange.end;
        
        // Delivery fee filter
        final matchesDeliveryFee = restaurant.deliveryFee <= _deliveryFee;
        
        // Open status (always show open restaurants)
        final matchesOpenStatus = restaurant.isOpen;
        
        return matchesSearch && matchesCuisine && matchesRating && 
            matchesDeliveryTime && matchesDeliveryFee && matchesOpenStatus;
      }).toList();
      
      // Apply sorting
      _sortRestaurants();
    });
  }

  void _sortRestaurants() {
    switch (_sortBy) {
      case 'rating':
        _filteredRestaurants.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'delivery_time':
        _filteredRestaurants.sort((a, b) => a.deliveryTime.compareTo(b.deliveryTime));
        break;
      case 'delivery_fee':
        _filteredRestaurants.sort((a, b) => a.deliveryFee.compareTo(b.deliveryFee));
        break;
      case 'price_low_high':
        _filteredRestaurants.sort((a, b) => a.minOrder.compareTo(b.minOrder));
        break;
      case 'price_high_low':
        _filteredRestaurants.sort((a, b) => b.minOrder.compareTo(a.minOrder));
        break;
      case 'distance':
        // Would need to calculate distance from current location
        break;
      default: // relevance
        // Keep original order or apply relevance scoring
        break;
    }
  }

  void _toggleFilter() {
    setState(() {
      _showFilters = !_showFilters;
      if (_showFilters) {
        _filterController.forward();
      } else {
        _filterController.reverse();
      }
    });
  }

  void _resetFilters() {
    setState(() {
      _selectedCuisine = '';
      _priceRange = const RangeValues(0, 100);
      _ratingRange = const RangeValues(0, 5);
      _deliveryTimeRange = const RangeValues(10, 90);
      _deliveryFee = 10.0;
      _selectedDietary.clear();
      _selectedFeatures.clear();
      _selectedTags.clear();
      _sortBy = 'relevance';
    });
    _filterRestaurants();
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SlideTransition(
        position: _searchAnimation,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A1A1A), Color(0xFF2D2D2D)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildSearchBar(),
                _buildFilterRow(),
                if (_showFilters) _buildFilterPanel(),
                _buildResultsHeader(),
                Expanded(
                  child: _isLoading 
                      ? _buildLoadingView()
                      : _buildResultsList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          ),
          const Expanded(
            child: Text(
              'Discover Restaurants',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: _toggleFilter,
            icon: Icon(
              _showFilters ? Icons.filter_list_off : Icons.filter_list,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        controller: _searchTextController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search restaurants, cuisines, dishes...',
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: const Icon(Icons.search, color: Colors.orange),
          suffixIcon: _searchTextController.text.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchTextController.clear();
                    _filterRestaurants();
                  },
                  icon: const Icon(Icons.clear, color: Colors.grey),
                )
              : null,
          filled: true,
          fillColor: Colors.grey[800],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
        onChanged: (value) {
          _filterRestaurants();
        },
      ),
    );
  }

  Widget _buildFilterRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Cuisine', _selectedCuisine.isNotEmpty ? _selectedCuisine : 'All'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Rating', '${_ratingRange.start.toInt()}+'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Delivery', '${_deliveryTimeRange.start.toInt()}-${_deliveryTimeRange.end.toInt()}min'),
                  const SizedBox(width: 8),
                  if (_deliveryFee > 0)
                    _buildFilterChip('Delivery Fee', '<\$${_deliveryFee.toStringAsFixed(0)}'),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _sortBy,
              icon: const Icon(Icons.arrow_drop_down, color: Colors.orange),
              style: const TextStyle(color: Colors.white),
              dropdownColor: Colors.grey[800],
              items: _sortOptions.map((option) =>
                DropdownMenuItem<String>(
                  value: option['value'] as String,
                  child: Text(option['label'] as String, style: const TextStyle(color: Colors.white)),
                )).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _sortBy = value);
                  _sortRestaurants();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.withOpacity(0.5)),
      ),
      child: Text(
        value,
        style: const TextStyle(color: Colors.orange, fontSize: 12),
      ),
    );
  }

  Widget _buildFilterPanel() {
    return SizeTransition(
      sizeFactor: _filterAnimation,
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filters',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: _resetFilters,
                  child: const Text('Reset', style: TextStyle(color: Colors.orange)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Cuisine Filter
            _buildCuisineFilter(),
            const SizedBox(height: 20),
            
            // Rating Range
            _buildRangeFilter(
              'Minimum Rating',
              _ratingRange,
              (RangeValues values) {
                setState(() => _ratingRange = values);
                _filterRestaurants();
              },
              min: 0,
              max: 5,
              divisions: 10,
            ),
            const SizedBox(height: 20),
            
            // Delivery Time Range
            _buildRangeFilter(
              'Delivery Time',
              _deliveryTimeRange,
              (RangeValues values) {
                setState(() => _deliveryTimeRange = values);
                _filterRestaurants();
              },
              min: 10,
              max: 90,
              divisions: 16,
            ),
            const SizedBox(height: 20),
            
            // Delivery Fee
            _buildSliderFilter(
              'Max Delivery Fee',
              _deliveryFee,
              (double value) {
                setState(() => _deliveryFee = value);
                _filterRestaurants();
              },
              max: 10,
              divisions: 10,
            ),
            const SizedBox(height: 20),
            
            // Dietary Preferences
            _buildMultiSelectFilter('Dietary Preferences', _dietaryOptions, _selectedDietary),
            const SizedBox(height: 20),
            
            // Features
            _buildMultiSelectFilter('Features', _featureOptions, _selectedFeatures),
            const SizedBox(height: 20),
            
            // Tags
            _buildMultiSelectFilter('Tags', _tagOptions, _selectedTags),
          ],
        ),
      ),
    );
  }

  Widget _buildCuisineFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cuisine',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildCuisineChip('All', _selectedCuisine.isEmpty),
            ..._cuisines.map((cuisine) => 
              _buildCuisineChip(cuisine, _selectedCuisine == cuisine)),
          ],
        ),
      ],
    );
  }

  Widget _buildCuisineChip(String cuisine, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (cuisine == 'All') {
            _selectedCuisine = '';
          } else {
            _selectedCuisine = cuisine;
          }
        });
        _filterRestaurants();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange : Colors.grey[700],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          cuisine,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[300],
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildRangeFilter(
    String label,
    RangeValues currentRange,
    Function(RangeValues) onChanged, {
    double min = 0,
    double max = 100,
    int divisions = 10,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        RangeSlider(
          values: currentRange,
          min: min,
          max: max,
          divisions: divisions,
          activeColor: Colors.orange,
          inactiveColor: Colors.grey[600],
          labels: RangeLabels(
            currentRange.start.toStringAsFixed(1),
            currentRange.end.toStringAsFixed(1),
          ),
          onChanged: onChanged,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${currentRange.start.toStringAsFixed(1)}',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
            Text(
              '${currentRange.end.toStringAsFixed(1)}',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSliderFilter(
    String label,
    double currentValue,
    Function(double) onChanged, {
    double max = 100,
    int divisions = 10,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Slider(
          value: currentValue,
          min: 0,
          max: max,
          divisions: divisions,
          activeColor: Colors.orange,
          inactiveColor: Colors.grey[600],
          label: currentValue.toStringAsFixed(1),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildMultiSelectFilter(String label, List<String> options, List<String> selected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selected.contains(option);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    selected.remove(option);
                  } else {
                    selected.add(option);
                  }
                });
                _filterRestaurants();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.orange : Colors.grey[700],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  option,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[300],
                    fontSize: 12,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildResultsHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${_filteredRestaurants.length} restaurants found',
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
          if (_searchTextController.text.isNotEmpty)
            Text(
              'Search: "${_searchTextController.text}"',
              style: const TextStyle(color: Colors.orange, fontSize: 12),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.orange),
          SizedBox(height: 20),
          Text(
            'Finding delicious restaurants...',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    if (_filteredRestaurants.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _filteredRestaurants.length,
      itemBuilder: (context, index) {
        final restaurant = _filteredRestaurants[index];
        return _buildRestaurantCard(restaurant);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 20),
          const Text(
            'No restaurants found',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            'Try adjusting your filters',
            style: TextStyle(color: Colors.grey[400]),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              _resetFilters();
              _searchTextController.clear();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear All Filters'),
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantCard(Restaurant restaurant) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.grey[800],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () => _navigateToRestaurantDetail(restaurant),
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Restaurant Header
              Row(
                children: [
                  // Restaurant Image
                  Hero(
                    tag: 'restaurant_${restaurant.id}',
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        image: restaurant.imageUrl.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(restaurant.imageUrl),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: restaurant.imageUrl.isEmpty
                          ? Container(
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.restaurant, size: 30, color: Colors.orange),
                            )
                          : null,
                    ),
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
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          restaurant.cuisines.join(', '),
                          style: TextStyle(color: Colors.grey[400], fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildInfoChip(
                              icon: Icons.star,
                              value: restaurant.rating.toString(),
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 8),
                            _buildInfoChip(
                              icon: Icons.access_time,
                              value: '${restaurant.deliveryTime}min',
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 8),
                            _buildInfoChip(
                              icon: Icons.delivery_dining,
                              value: restaurant.deliveryFee > 0 ? '\$${restaurant.deliveryFee.toStringAsFixed(2)}' : 'Free',
                              color: Colors.green,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Status
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: restaurant.isOpen ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      restaurant.isOpen ? 'Open' : 'Closed',
                      style: TextStyle(
                        color: restaurant.isOpen ? Colors.green : Colors.red,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Restaurant Description
              if (restaurant.description.isNotEmpty)
                Text(
                  restaurant.description,
                  style: TextStyle(color: Colors.grey[300], fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              
              const SizedBox(height: 8),
              
              // Bottom Info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Min order: \$${restaurant.minOrder.toStringAsFixed(2)}',
                    style: TextStyle(color: Colors.grey[400], fontSize: 10),
                  ),
                  Row(
                    children: [
                      if (restaurant.deliveryFee == 0)
                        _buildFeatureBadge('Free Delivery', Colors.green),
                      if (restaurant.rating >= 4.5)
                        _buildFeatureBadge('Top Rated', Colors.amber),
                      if (restaurant.deliveryTime <= 25)
                        _buildFeatureBadge('Fast Delivery', Colors.blue),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String value, required Color color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 2),
        Text(
          value,
          style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildFeatureBadge(String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(left: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w500),
      ),
    );
  }

  void _navigateToRestaurantDetail(Restaurant restaurant) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RestaurantDetailScreen(
          restaurant: restaurant,
        ),
      ),
    );
  }
}