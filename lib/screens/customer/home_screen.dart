import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

import '../../models/restaurant.dart';
import '../../widgets/enhanced_ui_components.dart';

// ===================== ENHANCED HOME SCREEN =====================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  
  // Search and Filter States
  final TextEditingController _searchController = TextEditingController();
  String _selectedLocation = 'Downtown Restaurant District';
  final List<String> _selectedFilters = [];
  int _selectedBottomNavIndex = 0;

  // Mock data for demonstration
  final List<String> _locations = [
    'Downtown Restaurant District',
    'University Area',
    'Old Town',
    'Business District',
    'Waterfront',
  ];

  final List<String> _categories = [
    '🍕 Pizza', '🍔 Burgers', '🍜 Asian', '🍗 Chicken',
    '🍰 Desserts', '🥗 Healthy', '☕ Coffee', '🌮 Mexican',
    '🍕 Italian', '🍞 Bakery', '🍿 Snacks', '🥤 Drinks'
  ];

  final List<Map<String, dynamic>> _quickActions = [
    {'icon': Icons.local_offer, 'title': 'Offers', 'color': AppColors.primaryRed},
    {'icon': Icons.star, 'title': 'Top 10', 'color': AppColors.accentOrange},
    {'icon': Icons.train, 'title': 'Food on Train', 'color': AppColors.successGreen},
    {'icon': Icons.celebration, 'title': 'Plan a Party', 'color': AppColors.warningYellow},
  ];

  final List<String> _filterChips = [
    'Price', 'Cuisine', 'Rating', 'Delivery Time', 'Free Delivery', 'New', 'Popular'
  ];

  final List<Restaurant> _featuredRestaurants = [
    Restaurant(
      id: '1',
      name: 'Bella Italia',
      description: 'Authentic Italian cuisine with fresh ingredients',
      imageUrl: 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=400',
      address: '123 Main St, Downtown',
      phone: '+1 234 567 8900',
      rating: 4.8,
      reviewCount: 245,
      cuisines: ['Italian', 'Pizza', 'Pasta'],
      isOpen: true,
      deliveryFee: 2.99,
      deliveryTime: 25,
      minOrder: 15.00,
    ),
    Restaurant(
      id: '2',
      name: 'Burger Junction',
      description: 'Gourmet burgers made with premium beef',
      imageUrl: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=400',
      address: '456 Oak Ave, University',
      phone: '+1 234 567 8901',
      rating: 4.6,
      reviewCount: 189,
      cuisines: ['American', 'Burgers', 'Fast Food'],
      isOpen: true,
      deliveryFee: 0.00,
      deliveryTime: 20,
      minOrder: 10.00,
    ),
    Restaurant(
      id: '3',
      name: 'Spice Garden',
      description: 'Authentic Asian flavors and aromatic spices',
      imageUrl: 'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=400',
      address: '789 Curry Lane, Old Town',
      phone: '+1 234 567 8902',
      rating: 4.7,
      reviewCount: 312,
      cuisines: ['Asian', 'Indian', 'Chinese'],
      isOpen: true,
      deliveryFee: 3.99,
      deliveryTime: 35,
      minOrder: 20.00,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _toggleFilter(String filter) {
    setState(() {
      if (_selectedFilters.contains(filter)) {
        _selectedFilters.remove(filter);
      } else {
        _selectedFilters.add(filter);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.secondaryBlack, AppColors.backgroundGray],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // PageHeader Section
                  _buildPageHeader(),
                  
                  // Offer Banner
                  _buildOfferBanner(),
                  
                  // Quick Actions Grid
                  _buildQuickActionsGrid(),
                  
                  // Food Categories
                  _buildFoodCategories(),
                  
                  // Filter Chips
                  _buildFilterChips(),
                  
                  // Featured Restaurants
                  _buildFeaturedRestaurants(),
                  
                  const SizedBox(height: 100), // Bottom navigation space
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildPageHeader() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        children: [
          // Location and Profile Row
          Row(
            children: [
              // Location Selector
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.location_on, color: AppColors.accentOrange, size: 20),
                    const SizedBox(width: AppSpacing.small),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedLocation,
                          isExpanded: true,
                          icon: Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
                          items: _locations.map((location) => 
                            DropdownMenuItem(
                              value: location,
                              child: Text(
                                location,
                                style: AppTextStyles.bodyMedium,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ).toList(),
                          onChanged: (newLocation) {
                            setState(() {
                              _selectedLocation = newLocation!;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Profile Button
              GestureDetector(
                onTap: () {
                  // Navigate to profile
                },
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.small),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.person,
                    color: AppColors.lightTextWhite,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.large),
          
          // Search Bar
          BoldSearchBar(
            controller: _searchController,
            hintText: 'Search for restaurants, dishes...',
            onChanged: (query) {
              // Handle search
            },
          ),
          
          const SizedBox(height: AppSpacing.medium),
          
          // Search Filters
          Row(
            children: [
              _buildSearchFilterChip(Icons.sort, 'Sort'),
              const SizedBox(width: AppSpacing.medium),
              _buildSearchFilterChip(Icons.filter_list, 'Filter'),
              const SizedBox(width: AppSpacing.medium),
              _buildSearchFilterChip(Icons.location_on, 'Near me'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchFilterChip(IconData icon, String label) {
    return GestureDetector(
      onTap: () {
        // Handle filter tap
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.medium, vertical: AppSpacing.small),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.dividerGray),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: AppSpacing.small),
            Text(
              label,
              style: AppTextStyles.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfferBanner() {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.screenPadding),
      padding: const EdgeInsets.all(AppSpacing.extraLarge),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryRed, AppColors.accentOrange],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryRed.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🍔 50% OFF',
                      style: AppTextStyles.displayMedium.copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.small),
                    Text(
                      'on your first order',
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.medium),
                    Text(
                      'Valid till midnight today',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(AppSpacing.medium),
                decoration: BoxDecoration(
                  color: AppColors.lightTextWhite.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.delivery_dining,
                  size: 40,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.extraLarge),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                // Handle order now
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.lightTextWhite,
                foregroundColor: AppColors.primaryRed,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: Text(
                'Order Now',
                style: AppTextStyles.buttonText.copyWith(
                  color: AppColors.primaryRed,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid() {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: AppTextStyles.titleMedium,
          ),
          const SizedBox(height: AppSpacing.large),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppSpacing.large,
              mainAxisSpacing: AppSpacing.large,
              childAspectRatio: 1.5,
            ),
            itemCount: _quickActions.length,
            itemBuilder: (context, index) {
              final action = _quickActions[index];
              return GestureDetector(
                onTap: () {
                  // Handle action tap
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: action['color'].withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: action['color'].withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        action['icon'],
                        size: 32,
                        color: action['color'],
                      ),
                      const SizedBox(height: AppSpacing.medium),
                      Text(
                        action['title'],
                        style: AppTextStyles.titleSmall.copyWith(
                          color: action['color'],
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFoodCategories() {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Popular Categories',
            style: AppTextStyles.titleMedium,
          ),
          const SizedBox(height: AppSpacing.large),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(
                _categories.length,
                (index) => GestureDetector(
                  onTap: () {
                    // Handle category selection
                  },
                  child: Container(
                    margin: EdgeInsets.only(
                      right: index < _categories.length - 1 ? AppSpacing.large : 0,
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: AppColors.cardBackground,
                            borderRadius: BorderRadius.circular(35),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              _categories[index].split(' ')[0],
                              style: const TextStyle(fontSize: 32),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.medium),
                        Text(
                          _categories[index].split(' ')[1],
                          style: AppTextStyles.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filters',
            style: AppTextStyles.titleMedium,
          ),
          const SizedBox(height: AppSpacing.large),
          Wrap(
            spacing: AppSpacing.medium,
            runSpacing: AppSpacing.medium,
            children: _filterChips.map((filter) {
              final isSelected = _selectedFilters.contains(filter);
              return GestureDetector(
                onTap: () => _toggleFilter(filter),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.large,
                    vertical: AppSpacing.medium,
                  ),
                  decoration: BoxDecoration(
                    gradient: isSelected 
                        ? const LinearGradient(
                            colors: [AppColors.primaryRed, AppColors.accentOrange],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isSelected ? null : AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(AppSpacing.buttonHeight / 2),
                    border: isSelected 
                        ? null 
                        : Border.all(
                            color: AppColors.dividerGray,
                            width: 1,
                          ),
                  ),
                  child: Text(
                    filter,
                    style: isSelected 
                        ? AppTextStyles.buttonText 
                        : AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedRestaurants() {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Featured Restaurants',
                style: AppTextStyles.titleMedium,
              ),
              TextButton(
                onPressed: () {
                  // View all restaurants
                },
                child: Text(
                  'View All',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.accentOrange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.large),
          ..._featuredRestaurants.map((restaurant) => 
            BoldRestaurantCard(
              name: restaurant.name,
              cuisine: restaurant.cuisines.join(', '),
              rating: restaurant.rating,
              deliveryTime: restaurant.deliveryTime,
              deliveryFee: restaurant.deliveryFee,
              imageUrl: restaurant.imageUrl,
              onTap: () {
                // Navigate to restaurant detail
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedBottomNavIndex,
        selectedItemColor: AppColors.primaryRed,
        unselectedItemColor: AppColors.textSecondary,
        backgroundColor: AppColors.backgroundGray,
        elevation: 0,
        onTap: (index) {
          setState(() {
            _selectedBottomNavIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.delivery_dining, size: 24),
            activeIcon: Icon(Icons.delivery_dining, size: 28),
            label: 'Delivery',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant, size: 24),
            activeIcon: Icon(Icons.restaurant, size: 28),
            label: 'Dining',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag, size: 24),
            activeIcon: Icon(Icons.shopping_bag, size: 28),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite, size: 24),
            activeIcon: Icon(Icons.favorite, size: 28),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person, size: 24),
            activeIcon: Icon(Icons.person, size: 28),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
