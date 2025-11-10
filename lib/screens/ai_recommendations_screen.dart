import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../models/cart_model.dart';
import '../services/ai_recommendation_service.dart';
import '../theme/app_theme.dart';
import 'product_screen.dart';

class AIRecommendationsScreen extends StatefulWidget {
  final String userId;

  const AIRecommendationsScreen({super.key, required this.userId});

  @override
  State<AIRecommendationsScreen> createState() => _AIRecommendationsScreenState();
}

class _AIRecommendationsScreenState extends State<AIRecommendationsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final AIRecommendationService _recommendationService = AIRecommendationService();

  // Different types of recommendations
  List<Product> _personalizedRecommendations = [];
  List<Product> _trendingProducts = [];
  List<Product> _contextualRecommendations = [];
  List<Product> _similarProducts = [];

  bool _isLoading = true;
  String _selectedContext = 'lunch';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadRecommendations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRecommendations() async {
    setState(() => _isLoading = true);

    try {
      // Load all types of recommendations
      final results = await Future.wait([
        _recommendationService.getPersonalizedRecommendations(
          userId: widget.userId,
          limit: 15,
        ),
        _recommendationService.getTrendingProducts(limit: 15),
        _recommendationService.getContextualRecommendations(
          userId: widget.userId,
          timeOfDay: _selectedContext,
          limit: 10,
        ),
      ]);

      setState(() {
        _personalizedRecommendations = results[0];
        _trendingProducts = results[1];
        _contextualRecommendations = results[2];
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading recommendations: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadSimilarProducts(Product product) async {
    final similar = await _recommendationService.getSimilarProducts(
      productId: product.id!,
      limit: 6,
    );
    setState(() {
      _similarProducts = similar;
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
        child: Column(
          children: [
            // Enhanced Header with AI Badge
            _buildHeader(),
            
            // Context Selector
            _buildContextSelector(),
            
            // Tab Bar for different recommendation types
            _buildTabBar(),
            
            // Tab Views
            Expanded(
              child: _isLoading 
                ? _buildLoadingView()
                : _buildTabViews(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.large),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.backgroundGray, AppColors.secondaryBlack],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.large),
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: AppColors.primaryRed,
                size: 32,
              ),
              const SizedBox(width: AppSpacing.medium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI-Powered Recommendations',
                      style: AppTextStyles.displaySmall,
                    ),
                    Text(
                      'Curated just for you using advanced AI',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.large),
        ],
      ),
    );
  }

  Widget _buildContextSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Context',
            style: AppTextStyles.titleMedium,
          ),
          const SizedBox(height: AppSpacing.medium),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildContextChip('Breakfast', 'breakfast', Icons.wb_sunny),
                const SizedBox(width: AppSpacing.medium),
                _buildContextChip('Lunch', 'lunch', Icons.wb_twilight),
                const SizedBox(width: AppSpacing.medium),
                _buildContextChip('Dinner', 'dinner', Icons.nightlife),
                const SizedBox(width: AppSpacing.medium),
                _buildContextChip('Late Night', 'late_night', Icons.bedtime),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContextChip(String label, String value, IconData icon) {
    final isSelected = _selectedContext == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedContext = value;
        });
        _loadRecommendations();
      },
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
              )
            : null,
          color: isSelected ? null : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: isSelected 
            ? null 
            : Border.all(
                color: AppColors.dividerGray,
                width: 1,
              ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected 
                ? AppColors.lightTextWhite 
                : AppColors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.small),
            Text(
              label,
              style: isSelected 
                ? AppTextStyles.buttonTextSmall
                : AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.dividerGray,
            width: 1,
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primaryRed,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primaryRed,
        indicatorWeight: 3,
        tabs: const [
          Tab(
            icon: Icon(Icons.person),
            text: 'For You',
          ),
          Tab(
            icon: Icon(Icons.trending_up),
            text: 'Trending',
          ),
          Tab(
            icon: Icon(Icons.access_time),
            text: 'Context',
          ),
          Tab(
            icon: Icon(Icons.more_horiz),
            text: 'Similar',
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppColors.primaryRed,
          ),
          const SizedBox(height: AppSpacing.large),
          Text(
            'AI is analyzing your preferences...',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabViews() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildRecommendationList(
          _personalizedRecommendations,
          'Personalized for You',
          Icons.person,
          'Based on your order history and preferences',
        ),
        _buildRecommendationList(
          _trendingProducts,
          'Trending Now',
          Icons.trending_up,
          'Most popular items this week',
        ),
        _buildRecommendationList(
          _contextualRecommendations,
          'Perfect for $_selectedContext',
          Icons.access_time,
          'Curated based on current time and conditions',
        ),
        _buildSimilarProductsList(),
      ],
    );
  }

  Widget _buildRecommendationList(
    List<Product> products,
    String title,
    IconData icon,
    String subtitle,
  ) {
    if (products.isEmpty) {
      return _buildEmptyState(title, subtitle);
    }

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primaryRed, size: 20),
              const SizedBox(width: AppSpacing.medium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.titleMedium),
                    Text(subtitle, style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    )),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.large),
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                crossAxisSpacing: AppSpacing.large,
                mainAxisSpacing: AppSpacing.large,
                childAspectRatio: 0.75,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                return _buildProductCard(products[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimilarProductsList() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.more_horiz, color: AppColors.primaryRed, size: 20),
              const SizedBox(width: AppSpacing.medium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Similar Products', style: AppTextStyles.titleMedium),
                    Text('Based on the selected product', style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    )),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.large),
          if (_similarProducts.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  'Select a product to see similar items',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                  crossAxisSpacing: AppSpacing.large,
                  mainAxisSpacing: AppSpacing.large,
                  childAspectRatio: 0.75,
                ),
                itemCount: _similarProducts.length,
                itemBuilder: (context, index) {
                  return _buildProductCard(_similarProducts[index]);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    return GestureDetector(
      onTap: () async {
        // Track user interaction for AI learning
        await _recommendationService.updateUserPreferencesFromActivity(
          userId: widget.userId,
          productId: product.id ?? '',
          activity: UserActivity.viewed,
        );

        // Load similar products
        await _loadSimilarProducts(product);

        // Navigate to product detail
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Container(), // Placeholder for product detail
            ),
          );
        }
      },
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardBorderRadius),
        ),
        child: Container(
          decoration: AppDecorations.elevatedCardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppSpacing.cardBorderRadius),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppSpacing.cardBorderRadius),
                    ),
                    child: product.imageUrl != null
                      ? Image.network(
                          product.imageUrl!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        )
                      : Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.cardBackground, AppColors.surfaceGray],
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.restaurant,
                              size: AppSpacing.iconSizeExtraLarge,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                  ),
                ),
              ),
              
              // Product Details
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.medium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: AppTextStyles.titleSmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.small),
                      Text(
                        '\$${product.price.toStringAsFixed(2)}',
                        style: AppTextStyles.priceSmall,
                      ),
                      if (product.rating != null) ...[
                        const SizedBox(height: AppSpacing.small),
                        Row(
                          children: [
                            Icon(
                              Icons.star,
                              size: 12,
                              color: AppColors.successGreen,
                            ),
                            const SizedBox(width: AppSpacing.small),
                            Text(
                              product.rating!.toStringAsFixed(1),
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                        ),
                      ],
                      const Spacer(),
                      // Add to Cart Button and AI Badge Row
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                context.read<CartModel>().addItem(product);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: AppColors.successGreen,
                                    content: Text(
                                      '${product.name} added to cart!',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.lightTextWhite,
                                      ),
                                    ),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 4),
                              ),
                              child: Container(
                                height: 24,
                                decoration: AppDecorations.primaryButtonDecoration.copyWith(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_shopping_cart,
                                      size: 12,
                                      color: AppColors.lightTextWhite,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      'Add',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.lightTextWhite,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          // AI Recommendation Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.small,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.primaryRed, AppColors.accentOrange],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'AI Pick',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.lightTextWhite,
                                fontSize: 8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lightbulb_outline,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: AppSpacing.large),
          Text(
            title,
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.medium),
          Text(
            subtitle,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.large),
          ElevatedButton(
            onPressed: _loadRecommendations,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryRed,
            ),
            child: Text(
              'Refresh Recommendations',
              style: AppTextStyles.buttonTextSmall,
            ),
          ),
        ],
      ),
    );
  }
}