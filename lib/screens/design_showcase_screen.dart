import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/enhanced_ui_components.dart';

class DesignShowcaseScreen extends StatefulWidget {
  const DesignShowcaseScreen({super.key});

  @override
  State<DesignShowcaseScreen> createState() => _DesignShowcaseScreenState();
}

class _DesignShowcaseScreenState extends State<DesignShowcaseScreen> {
  final ScrollController _scrollController = ScrollController();
  String selectedCategory = 'All';
  bool isLoading = false;

  final List<String> categories = [
    'All', 'Burgers', 'Pizza', 'Asian', 'Desserts', 'Drinks'
  ];

  final List<Map<String, dynamic>> demoProducts = [
    {
      'name': 'Classic Burger',
      'price': 12.99,
      'rating': 4.5,
      'description': 'Juicy beef patty with fresh lettuce, tomato, and special sauce',
      'image': null,
      'category': 'Burgers',
    },
    {
      'name': 'Margherita Pizza',
      'price': 16.99,
      'rating': 4.8,
      'description': 'Classic pizza with tomato sauce, fresh mozzarella, and basil',
      'image': null,
      'category': 'Pizza',
    },
    {
      'name': 'Pad Thai',
      'price': 14.99,
      'rating': 4.7,
      'description': 'Traditional Thai stir-fried noodles with shrimp and peanuts',
      'image': null,
      'category': 'Asian',
    },
    {
      'name': 'Chocolate Lava Cake',
      'price': 8.99,
      'rating': 4.9,
      'description': 'Warm chocolate cake with molten center and vanilla ice cream',
      'image': null,
      'category': 'Desserts',
    },
    {
      'name': 'Fresh Orange Juice',
      'price': 4.99,
      'rating': 4.6,
      'description': 'Freshly squeezed orange juice with pulp',
      'image': null,
      'category': 'Drinks',
    },
  ];

  @override
  void initState() {
    super.initState();
    _simulateLoading();
  }

  void _simulateLoading() async {
    setState(() => isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() => isLoading = false);
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
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // App Bar with Bold Design
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              backgroundColor: AppColors.backgroundGray,
              flexibleSpace: FlexibleSpaceBar(
                title: Text('FoodFirst Design', style: AppTextStyles.titleLarge),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.backgroundGray, AppColors.secondaryBlack],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.restaurant,
                      size: 80,
                      color: Colors.white54,
                    ),
                  ),
                ),
              ),
              actions: [
                IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.notifications, color: AppColors.lightTextWhite),
                ),
                IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.search, color: AppColors.lightTextWhite),
                ),
              ],
            ),

            // Hero Section with Rich Typography
            SliverToBoxAdapter(
              child: BoldHeroSection(
                title: 'Bold Modern Design',
                subtitle: 'Experience the future of food delivery with our stunning UI components',
                actions: [
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.extraLarge,
                          vertical: AppSpacing.medium,
                        ),
                        decoration: AppDecorations.primaryButtonDecoration,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.explore,
                              size: 20,
                              color: AppColors.lightTextWhite,
                            ),
                            const SizedBox(width: AppSpacing.medium),
                            Text(
                              'Explore Design',
                              style: AppTextStyles.buttonText,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar Showcase
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Search Components',
                      style: AppTextStyles.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.large),
                    const BoldSearchBar(),
                  ],
                ),
              ),
            ),

            // Category Filter with Animation
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Category Filters',
                      style: AppTextStyles.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.medium),
                    SizedBox(
                      height: 60,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final category = categories[index];
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: AppSpacing.medium),
                            child: BoldCategoryChip(
                              label: category,
                              isSelected: category == selectedCategory,
                              onTap: () => setState(() => selectedCategory = category),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Loading State Showcase
            if (isLoading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.extraLarge),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryRed,
                    ),
                  ),
                ),
              ),

            // Product Grid Showcase
            if (!isLoading)
              SliverPadding(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: AppSpacing.large,
                    mainAxisSpacing: AppSpacing.large,
                    childAspectRatio: 0.75,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final product = demoProducts[index % demoProducts.length];
                      return AnimatedContainer(
                        duration: Duration(milliseconds: 300 + (index * 50)),
                        child: BoldFoodProductCard(
                          name: product['name'],
                          price: product['price'],
                          rating: product['rating'],
                          description: product['description'],
                          imageUrl: product['image'],
                          onAddToCart: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: AppColors.successGreen,
                                content: Text(
                                  '${product['name']} added to cart!',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.lightTextWhite,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                    childCount: 6,
                  ),
                ),
              ),

            // Restaurant Cards Showcase
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Restaurant Showcase',
                      style: AppTextStyles.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.large),
                    ...List.generate(
                      3,
                      (index) => AnimatedContainer(
                        duration: Duration(milliseconds: 400 + (index * 100)),
                        child: BoldRestaurantCard(
                          name: 'Restaurant ${index + 1}',
                          cuisine: ['Italian', 'Asian', 'Mexican'][index],
                          rating: 4.2 + (index * 0.2),
                          deliveryTime: 25 + (index * 5),
                          deliveryFee: index == 0 ? 0.0 : 2.99,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: AppColors.backgroundGray,
                                content: Text(
                                  'Opening Restaurant ${index + 1}',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.lightTextWhite,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Color Palette Showcase
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bold Color Palette',
                      style: AppTextStyles.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.large),
                    Container(
                      decoration: AppDecorations.cardDecoration,
                      padding: const EdgeInsets.all(AppSpacing.extraLarge),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              _buildColorSwatch('Primary Red', AppColors.primaryRed),
                              const SizedBox(width: AppSpacing.large),
                              _buildColorSwatch('Accent Orange', AppColors.accentOrange),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.large),
                          Row(
                            children: [
                              _buildColorSwatch('Dark Gray', AppColors.backgroundGray),
                              const SizedBox(width: AppSpacing.large),
                              _buildColorSwatch('Surface', AppColors.cardBackground),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Typography Showcase
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Typography System',
                      style: AppTextStyles.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.large),
                    Container(
                      decoration: AppDecorations.cardDecoration,
                      padding: const EdgeInsets.all(AppSpacing.extraLarge),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Display Large', style: AppTextStyles.displayLarge),
                          const SizedBox(height: AppSpacing.medium),
                          Text('Display Medium', style: AppTextStyles.displayMedium),
                          const SizedBox(height: AppSpacing.medium),
                          Text('Title Large', style: AppTextStyles.titleLarge),
                          const SizedBox(height: AppSpacing.medium),
                          Text('Body Large', style: AppTextStyles.bodyLarge),
                          const SizedBox(height: AppSpacing.medium),
                          Text('Price: \$12.99', style: AppTextStyles.priceText),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Button Styles Showcase
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Button Styles',
                      style: AppTextStyles.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.large),
                    Container(
                      decoration: AppDecorations.cardDecoration,
                      padding: const EdgeInsets.all(AppSpacing.extraLarge),
                      child: Column(
                        children: [
                          // Primary Button
                          SizedBox(
                            width: double.infinity,
                            height: AppSpacing.buttonHeight,
                            child: ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                elevation: 0,
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppSpacing.buttonHeight / 2),
                                ),
                              ),
                              child: Container(
                                width: double.infinity,
                                height: double.infinity,
                                decoration: AppDecorations.primaryButtonDecoration,
                                child: Center(
                                  child: Text(
                                    'Primary Button',
                                    style: AppTextStyles.buttonText,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.large),
                          
                          // Secondary Button
                          SizedBox(
                            width: double.infinity,
                            height: AppSpacing.buttonHeight,
                            child: OutlinedButton(
                              onPressed: () {},
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.accentOrange,
                                side: const BorderSide(color: AppColors.accentOrange, width: 2),
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppSpacing.buttonHeight / 2),
                                ),
                              ),
                              child: Container(
                                width: double.infinity,
                                height: double.infinity,
                                decoration: AppDecorations.secondaryButtonDecoration,
                                child: Center(
                                  child: Text(
                                    'Secondary Button',
                                    style: AppTextStyles.buttonText.copyWith(
                                      color: AppColors.accentOrange,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Spacing
            const SliverToBoxAdapter(
              child: SizedBox(height: AppSpacing.extraLarge),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorSwatch(String name, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(
            height: 60,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.medium),
          Text(
            name,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}