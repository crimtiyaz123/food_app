import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/dynamic_pricing.dart';
import '../services/dynamic_pricing_service.dart';
import '../theme/app_theme.dart';

class DynamicPricingScreen extends StatefulWidget {
  final String restaurantId;

  const DynamicPricingScreen({
    super.key,
    required this.restaurantId,
  });

  @override
  State<DynamicPricingScreen> createState() => _DynamicPricingScreenState();
}

class _DynamicPricingScreenState extends State<DynamicPricingScreen> {
  final DynamicPricingService _pricingService = DynamicPricingService();
  
  List<DynamicMenuItem> _menuItems = [];
  List<PricingRecommendation> _recommendations = [];
  bool _isLoading = true;
  String _selectedTab = 'Menu Items';
  Map<String, dynamic> _analytics = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load menu items and analytics in parallel
      final results = await Future.wait([
        _pricingService.getDynamicMenuItems(restaurantId: widget.restaurantId),
        _pricingService.getPricingAnalytics(restaurantId: widget.restaurantId),
      ]);

      setState(() {
        _menuItems = results[0] as List<DynamicMenuItem>;
        _analytics = results[1] as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading dynamic pricing data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dynamic Pricing & Menu'),
        backgroundColor: AppColors.primaryRed,
        foregroundColor: AppColors.lightTextWhite,
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: _showAnalyticsDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.secondaryBlack, AppColors.backgroundGray],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _isLoading
            ? _buildLoadingView()
            : _buildMainView(),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: AppColors.primaryRed,
          ),
          const SizedBox(height: 20),
          Text(
            'Loading dynamic pricing data...',
            style: AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildMainView() {
    return Column(
      children: [
        // Tab Navigation
        _buildTabNavigation(),
        
        // Tab Content
        Expanded(
          child: _selectedTab == 'Menu Items'
              ? _buildMenuItemsTab()
              : _selectedTab == 'Recommendations'
                  ? _buildRecommendationsTab()
                  : _buildAnalyticsTab(),
        ),
      ],
    );
  }

  Widget _buildTabNavigation() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Row(
        children: [
          _buildTabButton('Menu Items', 0),
          const SizedBox(width: AppSpacing.medium),
          _buildTabButton('Recommendations', 1),
          const SizedBox(width: AppSpacing.medium),
          _buildTabButton('Analytics', 2),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, int index) {
    final isSelected = _getSelectedTabIndex() == index;
    return Expanded(
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            _selectedTab = title;
          });
          
          if (title == 'Recommendations') {
            _loadRecommendations();
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? AppColors.primaryRed : AppColors.cardBackground,
          foregroundColor: isSelected ? AppColors.lightTextWhite : AppColors.textSecondary,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Text(
          title,
          style: AppTextStyles.bodySmall,
        ),
      ),
    );
  }

  int _getSelectedTabIndex() {
    switch (_selectedTab) {
      case 'Menu Items':
        return 0;
      case 'Recommendations':
        return 1;
      case 'Analytics':
        return 2;
      default:
        return 0;
    }
  }

  Widget _buildMenuItemsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      itemCount: _menuItems.length,
      itemBuilder: (context, index) {
        final item = _menuItems[index];
        return _buildMenuItemCard(item);
      },
    );
  }

  Widget _buildMenuItemCard(DynamicMenuItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.medium),
      padding: const EdgeInsets.all(AppSpacing.large),
      decoration: AppDecorations.elevatedCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: AppTextStyles.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.small),
                    Text(
                      item.description,
                      style: AppTextStyles.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.medium,
                  vertical: AppSpacing.small,
                ),
                decoration: BoxDecoration(
                  color: item.isOnPromotion() 
                      ? AppColors.successGreen 
                      : AppColors.primaryRed,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '\$${item.currentPrice.toStringAsFixed(2)}',
                  style: AppTextStyles.buttonTextSmall,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.medium),

          // Price Information
          _buildPriceInfo(item),

          const SizedBox(height: AppSpacing.medium),

          // Status Information
          _buildStatusInfo(item),

          const SizedBox(height: AppSpacing.medium),

          // Action Buttons
          _buildActionButtons(item),
        ],
      ),
    );
  }

  Widget _buildPriceInfo(DynamicMenuItem item) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Base Price: \$${item.basePrice.toStringAsFixed(2)}',
                style: AppTextStyles.bodySmall,
              ),
              if (item.originalPrice != null) ...[
                Text(
                  'Original: \$${item.originalPrice!.toStringAsFixed(2)}',
                  style: AppTextStyles.bodySmall.copyWith(
                    decoration: TextDecoration.lineThrough,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (item.isOnPromotion()) ...[
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.small,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: AppColors.accentOrange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${item.getDiscountPercentage()!.toStringAsFixed(0)}% OFF',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.accentOrange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatusInfo(DynamicMenuItem item) {
    return Row(
      children: [
        _buildStatusBadge(
          'Stock: ${item.stockLevel}',
          item.stockLevel > 10 ? AppColors.successGreen : 
          item.stockLevel > 0 ? AppColors.accentOrange : AppColors.primaryRed,
        ),
        const SizedBox(width: AppSpacing.medium),
        _buildStatusBadge(
          'Demand: ${(item.demandScore * 100).toStringAsFixed(0)}%',
          item.demandScore > 0.7 ? AppColors.successGreen : 
          item.demandScore > 0.4 ? AppColors.accentOrange : AppColors.textSecondary,
        ),
        const SizedBox(width: AppSpacing.medium),
        _buildStatusBadge(
          'Popularity: ${item.popularityScore}',
          item.popularityScore > 80 ? AppColors.successGreen : 
          item.popularityScore > 50 ? AppColors.accentOrange : AppColors.textSecondary,
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.small,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: AppTextStyles.bodySmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildActionButtons(DynamicMenuItem item) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showPriceUpdateDialog(item),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryRed,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            icon: const Icon(Icons.attach_money, size: 16),
            label: const Text('Update Price'),
          ),
        ),
        const SizedBox(width: AppSpacing.medium),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showCustomizationDialog(item),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentOrange,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            icon: const Icon(Icons.tune, size: 16),
            label: const Text('Customize'),
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationsTab() {
    if (_recommendations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lightbulb_outline,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 20),
            Text(
              'No recommendations available',
              style: AppTextStyles.titleMedium,
            ),
            const SizedBox(height: 10),
            Text(
              'AI is analyzing your menu and market data',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadRecommendations,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRed,
              ),
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh Recommendations'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      itemCount: _recommendations.length,
      itemBuilder: (context, index) {
        final recommendation = _recommendations[index];
        return _buildRecommendationCard(recommendation);
      },
    );
  }

  Widget _buildRecommendationCard(PricingRecommendation recommendation) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.medium),
      padding: const EdgeInsets.all(AppSpacing.large),
      decoration: AppDecorations.elevatedCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Text(
                  'Price Recommendation',
                  style: AppTextStyles.titleMedium,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.medium,
                  vertical: AppSpacing.small,
                ),
                decoration: BoxDecoration(
                  color: _getConfidenceColor(recommendation.confidenceScore),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(recommendation.confidenceScore * 100).toStringAsFixed(0)}%',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.lightTextWhite,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.medium),

          // Price Change
          Row(
            children: [
              Text(
                'Current: ',
                style: AppTextStyles.bodyMedium,
              ),
              Text(
                '\$${(recommendation.metadata['currentPrice'] as double).toStringAsFixed(2)}',
                style: AppTextStyles.bodyMedium.copyWith(
                  decoration: TextDecoration.lineThrough,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: AppSpacing.medium),
              Text(
                'Recommended: ',
                style: AppTextStyles.bodyMedium,
              ),
              Text(
                '\$${recommendation.recommendedPrice.toStringAsFixed(2)}',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.successGreen,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.medium),

          // Rationale
          Text(
            recommendation.rationale,
            style: AppTextStyles.bodySmall,
          ),

          const SizedBox(height: AppSpacing.medium),

          // Factors
          if (recommendation.factors.isNotEmpty) ...[
            Text(
              'Factors:',
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.small),
            ...recommendation.factors.map((factor) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.small),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 16,
                      color: AppColors.successGreen,
                    ),
                    const SizedBox(width: AppSpacing.small),
                    Expanded(
                      child: Text(
                        factor,
                        style: AppTextStyles.bodySmall,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],

          const SizedBox(height: AppSpacing.large),

          // Action Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _applyRecommendation(recommendation),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.successGreen,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.check),
              label: const Text('Apply Recommendation'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overview Cards
          _buildAnalyticsCards(),
          
          const SizedBox(height: AppSpacing.large),

          // Price Range Chart
          _buildPriceRangeChart(),
          
          const SizedBox(height: AppSpacing.large),

          // Stock Level Distribution
          _buildStockLevelDistribution(),
          
          const SizedBox(height: AppSpacing.large),

          // Popularity Distribution
          _buildPopularityDistribution(),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildAnalyticsCard(
                'Total Items',
                '${_analytics['totalItems'] ?? 0}',
                Icons.restaurant,
                AppColors.primaryRed,
              ),
            ),
            const SizedBox(width: AppSpacing.medium),
            Expanded(
              child: _buildAnalyticsCard(
                'Average Price',
                '\$${(_analytics['averagePrice'] ?? 0.0).toStringAsFixed(2)}',
                Icons.attach_money,
                AppColors.accentOrange,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.medium),
        Row(
          children: [
            Expanded(
              child: _buildAnalyticsCard(
                'On Promotion',
                '${_analytics['itemsOnPromotion'] ?? 0}',
                Icons.local_offer,
                AppColors.successGreen,
              ),
            ),
            const SizedBox(width: AppSpacing.medium),
            Expanded(
              child: _buildAnalyticsCard(
                'Avg Demand',
                '${((_analytics['demandScoreAverage'] ?? 0.0) * 100).toStringAsFixed(0)}%',
                Icons.trending_up,
                AppColors.accentOrange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnalyticsCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.large),
      decoration: AppDecorations.elevatedCardDecoration,
      child: Column(
        children: [
          Icon(
            icon,
            size: 32,
            color: color,
          ),
          const SizedBox(height: AppSpacing.medium),
          Text(
            value,
            style: AppTextStyles.titleLarge,
          ),
          const SizedBox(height: AppSpacing.small),
          Text(
            title,
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRangeChart() {
    final priceRange = _analytics['priceRange'] as Map<String, dynamic>? ?? {};
    final min = priceRange['min'] as double? ?? 0.0;
    final max = priceRange['max'] as double? ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.large),
      decoration: AppDecorations.elevatedCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Price Range',
            style: AppTextStyles.titleMedium,
          ),
          const SizedBox(height: AppSpacing.medium),
          Text(
            'Min: \$${min.toStringAsFixed(2)}',
            style: AppTextStyles.bodyMedium,
          ),
          Text(
            'Max: \$${max.toStringAsFixed(2)}',
            style: AppTextStyles.bodyMedium,
          ),
          Text(
            'Range: \$${(max - min).toStringAsFixed(2)}',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockLevelDistribution() {
    final stockLevels = _analytics['stockLevels'] as Map<String, int>? ?? {};

    return Container(
      padding: const EdgeInsets.all(AppSpacing.large),
      decoration: AppDecorations.elevatedCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Stock Level Distribution',
            style: AppTextStyles.titleMedium,
          ),
          const SizedBox(height: AppSpacing.medium),
          ...stockLevels.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.small),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(entry.key),
                  Text('${entry.value} items'),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildPopularityDistribution() {
    final popularity = _analytics['popularityDistribution'] as Map<String, int>? ?? {};

    return Container(
      padding: const EdgeInsets.all(AppSpacing.large),
      decoration: AppDecorations.elevatedCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Popularity Distribution',
            style: AppTextStyles.titleMedium,
          ),
          const SizedBox(height: AppSpacing.medium),
          ...popularity.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.small),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(entry.key),
                  Text('${entry.value} items'),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // Dialog Methods
  void _showPriceUpdateDialog(DynamicMenuItem item) {
    final priceController = TextEditingController(text: item.currentPrice.toString());
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Price'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'New Price',
                prefixText: '\$',
              ),
            ),
            const SizedBox(height: AppSpacing.medium),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for Change',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newPrice = double.tryParse(priceController.text);
              if (newPrice != null && newPrice > 0) {
                await _pricingService.updateMenuItemPrice(
                  menuItemId: item.id,
                  newPrice: newPrice,
                  reason: reasonController.text.isEmpty 
                      ? 'Manual price update' 
                      : reasonController.text,
                );
                
                Navigator.pop(context);
                _loadData();
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showCustomizationDialog(DynamicMenuItem item) {
    // Implementation for menu customization dialog
    // This would show a dialog for managing customizations
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Menu Customization'),
        content: const Text('Customization management will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAnalyticsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pricing Analytics'),
        content: const Text('Detailed analytics view will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Helper Methods
  void _loadRecommendations() async {
    setState(() {
      _recommendations = [];
    });

    try {
      final recommendations = await _pricingService.generatePricingRecommendations(
        restaurantId: widget.restaurantId,
      );
      
      setState(() {
        _recommendations = recommendations;
      });
    } catch (e) {
      debugPrint('Error loading recommendations: $e');
    }
  }

  Future<void> _applyRecommendation(PricingRecommendation recommendation) async {
    final success = await _pricingService.updateMenuItemPrice(
      menuItemId: recommendation.menuItemId,
      newPrice: recommendation.recommendedPrice,
      reason: 'AI Recommendation: ${recommendation.rationale}',
    );

    if (success) {
      setState(() {
        _recommendations.remove(recommendation);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.successGreen,
          content: Text(
            'Price updated successfully to \$${recommendation.recommendedPrice.toStringAsFixed(2)}',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.primaryRed,
          content: const Text('Failed to update price'),
        ),
      );
    }
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return AppColors.successGreen;
    if (confidence >= 0.6) return AppColors.accentOrange;
    return AppColors.textSecondary;
  }
}