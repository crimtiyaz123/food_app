import 'package:flutter/material.dart';
import '../models/ar_experience.dart';
import '../services/ar_experience_service.dart';
import '../theme/app_theme.dart';

class ARMenuScreen extends StatefulWidget {
  final String restaurantId;
  final String? selectedCategoryId;

  const ARMenuScreen({
    super.key,
    required this.restaurantId,
    this.selectedCategoryId,
  });

  @override
  State<ARMenuScreen> createState() => _ARMenuScreenState();
}

class _ARMenuScreenState extends State<ARMenuScreen> with TickerProviderStateMixin {
  final ARExperienceService _arService = ARExperienceService();
  
  List<ARMenuItem> _arMenuItems = [];
  List<ARMenuItem> _personalizedRecommendations = [];
  bool _isLoading = true;
  String _selectedTab = 'AR Menu';
  String? _userId; // Would be retrieved from authentication
  TabController? _tabController;
  TabBar? _tabBar;

  @override
  void initState() {
    super.initState();
    _initializeAR();
  }

  void _initializeAR() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load AR menu items
      final arItems = await _arService.getARMenuItems(
        restaurantId: widget.restaurantId,
        categoryId: widget.selectedCategoryId,
      );

      setState(() {
        _arMenuItems = arItems;
        _isLoading = false;
      });

      // If user is authenticated, load personalized recommendations
      if (_userId != null) {
        _loadPersonalizedRecommendations();
      }
    } catch (e) {
      debugPrint('Error initializing AR menu: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _loadPersonalizedRecommendations() async {
    if (_userId == null) return;

    try {
      final recommendations = await _arService.getPersonalizedARRecommendations(
        userId: _userId!,
        restaurantId: widget.restaurantId,
        limit: 5,
      );

      setState(() {
        _personalizedRecommendations = recommendations;
      });
    } catch (e) {
      debugPrint('Error loading personalized recommendations: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AR Menu Experience'),
        backgroundColor: AppColors.primaryRed,
        foregroundColor: AppColors.lightTextWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: _showARAnalytics,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _initializeAR,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: _buildTabBar(),
        ),
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

  Widget _buildTabBar() {
    if (_tabController == null) {
      _tabController = TabController(length: 3, vsync: this);
      _tabController!.addListener(() {
        setState(() {
          _selectedTab = _getTabName(_tabController!.index);
        });
      });
    }

    return TabBar(
      controller: _tabController,
      labelColor: AppColors.lightTextWhite,
      unselectedLabelColor: AppColors.textSecondary,
      indicatorColor: AppColors.accentOrange,
      tabs: const [
        Tab(
          icon: Icon(Icons.view_in_ar),
          text: 'AR Menu',
        ),
        Tab(
          icon: Icon(Icons.stars),
          text: 'For You',
        ),
        Tab(
          icon: Icon(Icons.restaurant),
          text: 'Tours',
        ),
      ],
    );
  }

  String _getTabName(int index) {
    switch (index) {
      case 0:
        return 'AR Menu';
      case 1:
        return 'For You';
      case 2:
        return 'Tours';
      default:
        return 'AR Menu';
    }
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
            'Loading AR Menu Experience...',
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'Preparing 3D food visualizations',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMainView() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildARMenuTab(),
        _buildForYouTab(),
        _buildToursTab(),
      ],
    );
  }

  Widget _buildARMenuTab() {
    if (_arMenuItems.isEmpty) {
      return _buildEmptyARView(
        'No AR Items Available',
        'This restaurant doesn\'t have AR experiences yet.',
        'Ask the restaurant to add 3D menu visualizations!',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      itemCount: _arMenuItems.length,
      itemBuilder: (context, index) {
        final item = _arMenuItems[index];
        return _buildARMenuItemCard(item);
      },
    );
  }

  Widget _buildForYouTab() {
    if (_personalizedRecommendations.isEmpty) {
      return _buildEmptyARView(
        'No Personalized Recommendations',
        'Try some AR experiences to get personalized recommendations.',
        'AR experiences help us understand your preferences!',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      itemCount: _personalizedRecommendations.length,
      itemBuilder: (context, index) {
        final item = _personalizedRecommendations[index];
        return _buildARMenuItemCard(item, isPersonalized: true);
      },
    );
  }

  Widget _buildToursTab() {
    return FutureBuilder<List<ARRestaurantTour>>(
      future: _arService.getRestaurantTours(widget.restaurantId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorView('Error loading restaurant tours');
        }

        if (!snapshot.hasData) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                Text('Loading restaurant tours...', style: AppTextStyles.bodyMedium),
              ],
            ),
          );
        }

        final tours = snapshot.data!;
        if (tours.isEmpty) {
          return _buildEmptyARView(
            'No Virtual Tours Available',
            'This restaurant doesn\'t offer virtual tours yet.',
            'Virtual tours would show the restaurant in 3D!',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          itemCount: tours.length,
          itemBuilder: (context, index) {
            final tour = tours[index];
            return _buildRestaurantTourCard(tour);
          },
        );
      },
    );
  }

  Widget _buildARMenuItemCard(ARMenuItem item, {bool isPersonalized = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.large),
      decoration: AppDecorations.elevatedCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with AR indicator
          Container(
            padding: const EdgeInsets.all(AppSpacing.large),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isPersonalized 
                    ? [AppColors.accentOrange, AppColors.primaryRed]
                    : [AppColors.primaryRed, AppColors.accentOrange],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.view_in_ar,
                  color: AppColors.lightTextWhite,
                  size: 24,
                ),
                const SizedBox(width: AppSpacing.medium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.lightTextWhite,
                        ),
                      ),
                      if (isPersonalized) ...[
                        const SizedBox(height: AppSpacing.small),
                        Text(
                          'Recommended for you',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.lightTextWhite.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Text(
                  '\$${item.basePrice.toStringAsFixed(2)}',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.lightTextWhite,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(AppSpacing.large),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.description,
                  style: AppTextStyles.bodyMedium,
                ),

                const SizedBox(height: AppSpacing.medium),

                // AR Features
                _buildARFeaturesRow(item),

                const SizedBox(height: AppSpacing.medium),

                // AR Status
                _buildARStatusRow(item),

                const SizedBox(height: AppSpacing.large),

                // Action Buttons
                _buildActionButtons(item),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildARFeaturesRow(ARMenuItem item) {
    final features = <Widget>[];

    if (item.models3D.isNotEmpty) {
      features.add(_buildFeatureBadge('3D Model', Icons.view_in_ar, AppColors.successGreen));
    }
    if (item.hotspots.isNotEmpty) {
      features.add(_buildFeatureBadge('${item.hotspots.length} Hotspots', Icons.touch_app, AppColors.accentOrange));
    }
    if (item.nutritionOverlay.isNotEmpty) {
      features.add(_buildFeatureBadge('Nutrition', Icons.food_bank, AppColors.primaryRed));
    }
    if (item.allergenHighlights.isNotEmpty) {
      features.add(_buildFeatureBadge('Allergen Info', Icons.warning, AppColors.accentOrange));
    }
    if (item.isOnPromotion) {
      features.add(_buildFeatureBadge('Special Offer', Icons.local_offer, AppColors.successGreen));
    }

    if (features.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.medium),
        decoration: BoxDecoration(
          color: AppColors.backgroundGray,
          borderRadius: BorderRadius.circular(AppSpacing.small),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info,
              color: AppColors.textSecondary,
              size: 16,
            ),
            const SizedBox(width: AppSpacing.small),
            Text(
              'No AR features available',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Wrap(
      spacing: AppSpacing.small,
      runSpacing: AppSpacing.small,
      children: features,
    );
  }

  Widget _buildFeatureBadge(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.medium,
        vertical: AppSpacing.small,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: AppSpacing.small),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildARStatusRow(ARMenuItem item) {
    return Row(
      children: [
        _buildStatusBadge(
          'Usage: ${item.usageCount}',
          AppColors.textSecondary,
        ),
        const SizedBox(width: AppSpacing.medium),
        if (item.averageInteractionTime > 0) ...[
          _buildStatusBadge(
            'Avg Time: ${item.averageInteractionTime.toStringAsFixed(0)}s',
            AppColors.textSecondary,
          ),
          const SizedBox(width: AppSpacing.medium),
        ],
        if (item.analytics['averageSatisfaction'] != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.medium,
              vertical: AppSpacing.small,
            ),
            decoration: BoxDecoration(
              color: AppColors.successGreen.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.star,
                  size: 14,
                  color: AppColors.successGreen,
                ),
                const SizedBox(width: AppSpacing.small),
                Text(
                  '${(item.analytics['averageSatisfaction'] as double).toStringAsFixed(1)}★',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.successGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.medium,
        vertical: AppSpacing.small,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
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

  Widget _buildActionButtons(ARMenuItem item) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: () => _startARExperience(item, 'visualization'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.successGreen,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            icon: const Icon(Icons.view_in_ar, size: 20),
            label: const Text('View in AR'),
          ),
        ),
        const SizedBox(width: AppSpacing.medium),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showNutritionOverlay(item),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentOrange,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            icon: const Icon(Icons.info, size: 18),
            label: const Text('Info'),
          ),
        ),
      ],
    );
  }

  Widget _buildRestaurantTourCard(ARRestaurantTour tour) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.large),
      decoration: AppDecorations.elevatedCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppSpacing.large),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryRed, AppColors.accentOrange],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.restaurant,
                  color: AppColors.lightTextWhite,
                  size: 24,
                ),
                const SizedBox(width: AppSpacing.medium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tour.name,
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.lightTextWhite,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.small),
                      Text(
                        'Duration: ${tour.estimatedDuration.inMinutes} min',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.lightTextWhite.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(AppSpacing.large),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tour.description,
                  style: AppTextStyles.bodyMedium,
                ),

                const SizedBox(height: AppSpacing.medium),

                // Tour stats
                Row(
                  children: [
                    _buildStatusBadge(
                      '${tour.stops.length} Stops',
                      AppColors.primaryRed,
                    ),
                    const SizedBox(width: AppSpacing.medium),
                    _buildStatusBadge(
                      '${tour.supportedLanguages.length} Languages',
                      AppColors.accentOrange,
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.large),

                // Action Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _startVirtualTour(tour),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryRed,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    icon: const Icon(Icons.explore, size: 20),
                    label: const Text('Start Virtual Tour'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyARView(String title, String subtitle, String description) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.view_in_ar,
              size: 80,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppSpacing.large),
            Text(
              title,
              style: AppTextStyles.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.medium),
            Text(
              subtitle,
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.small),
            Text(
              description,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.large),
            ElevatedButton.icon(
              onPressed: _initializeAR,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRed,
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 15,
                ),
              ),
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 60,
              color: AppColors.primaryRed,
            ),
            const SizedBox(height: 20),
            Text(
              'Error Loading AR Content',
              style: AppTextStyles.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _initializeAR,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRed,
              ),
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  // AR Experience Methods
  void _startARExperience(ARMenuItem item, String experienceType) async {
    if (_userId == null) {
      _showLoginPrompt();
      return;
    }

    try {
      // Check device compatibility
      final deviceInfo = await _getDeviceInfo();
      if (!_isDeviceCompatible(item)) {
        _showIncompatibleDeviceDialog();
        return;
      }

      // Start AR session
      final sessionId = await _arService.startARExperience(
        userId: _userId!,
        menuItemId: item.id,
        sessionType: experienceType,
        deviceInfo: deviceInfo,
      );

      // Navigate to AR view (this would integrate with AR framework)
      _navigateToARView(item, sessionId, experienceType);
      
    } catch (e) {
      debugPrint('Error starting AR experience: $e');
      _showErrorSnackBar('Failed to start AR experience: ${e.toString()}');
    }
  }

  void _showNutritionOverlay(ARMenuItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nutrition Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.nutritionOverlay.isNotEmpty) ...[
              ...item.nutritionOverlay.map((nutrition) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.medium),
                  child: Row(
                    children: [
                      Icon(
                        _getNutritionIcon(nutrition.nutrient),
                        color: _getNutritionColor(nutrition.nutrient),
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.medium),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nutrition.nutrient.toUpperCase(),
                              style: AppTextStyles.bodySmall.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${nutrition.value} ${nutrition.unit}',
                              style: AppTextStyles.bodyMedium,
                            ),
                            Text(
                              '${nutrition.dailyValue} of daily value',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ] else ...[
              Text(
                'No nutrition information available',
                style: AppTextStyles.bodyMedium,
              ),
            ],

            if (item.allergenHighlights.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.large),
              Text(
                'Allergen Information',
                style: AppTextStyles.titleSmall,
              ),
              const SizedBox(height: AppSpacing.medium),
              ...item.allergenHighlights.map((allergen) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.small),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning,
                        color: _getAllergenColor(allergen.severity),
                        size: 16,
                      ),
                      const SizedBox(width: AppSpacing.small),
                      Expanded(
                        child: Text(
                          allergen.allergen.toUpperCase(),
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _startVirtualTour(ARRestaurantTour tour) {
    // Implementation for starting virtual restaurant tour
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Virtual Tour'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tour.name,
              style: AppTextStyles.titleMedium,
            ),
            const SizedBox(height: AppSpacing.medium),
            Text(
              tour.description,
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.medium),
            Text(
              'Stops: ${tour.stops.length}',
              style: AppTextStyles.bodySmall,
            ),
            Text(
              'Duration: ${tour.estimatedDuration.inMinutes} minutes',
              style: AppTextStyles.bodySmall,
            ),
            Text(
              'Languages: ${tour.supportedLanguages.join(', ')}',
              style: AppTextStyles.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Start tour implementation
              _navigateToVirtualTour(tour);
            },
            child: const Text('Start Tour'),
          ),
        ],
      ),
    );
  }

  // Helper Methods
  Future<Map<String, dynamic>> _getDeviceInfo() async {
    // This would get actual device information
    return {
      'deviceType': 'mobile',
      'arSupport': true,
      'osVersion': '14.0',
      'deviceModel': 'iPhone',
    };
  }

  bool _isDeviceCompatible(ARMenuItem item) {
    // Check device compatibility for AR features
    // This would check against device requirements
    return true; // Simplified for demo
  }

  void _navigateToARView(ARMenuItem item, String sessionId, String experienceType) {
    // This would navigate to the actual AR view
    // For now, show a demo dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('AR Experience'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.view_in_ar,
              size: 64,
              color: AppColors.primaryRed,
            ),
            const SizedBox(height: 20),
            Text(
              'AR View: ${item.name}',
              style: AppTextStyles.titleMedium,
            ),
            const SizedBox(height: 10),
            Text(
              'Session: $sessionId',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'In a real implementation, this would open the AR camera view with 3D food models.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Simulate ending the session
              _endARSession(sessionId);
            },
            child: const Text('End Experience'),
          ),
        ],
      ),
    );
  }

  void _navigateToVirtualTour(ARRestaurantTour tour) {
    // This would navigate to the actual virtual tour view
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Virtual Tour'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.restaurant,
              size: 64,
              color: AppColors.primaryRed,
            ),
            const SizedBox(height: 20),
            Text(
              tour.name,
              style: AppTextStyles.titleMedium,
            ),
            const SizedBox(height: 10),
            const Text(
              'Starting virtual restaurant tour...\n\nIn a real implementation, this would open an immersive 3D tour of the restaurant.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Exit Tour'),
          ),
        ],
      ),
    );
  }

  void _endARSession(String sessionId) {
    // Simulate ending AR session with analytics
    _arService.endARExperience(
      sessionId: sessionId,
      interactionsCount: 5, // Simulated
      visitedHotspots: [], // Simulated
      satisfactionRating: 4.5, // Simulated
    );
  }

  void _showLoginPrompt() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login Required'),
        content: const Text('Please log in to use AR features and get personalized recommendations.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to login screen
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  void _showIncompatibleDeviceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Device Not Compatible'),
        content: const Text('Your device doesn\'t support AR features. Please use a newer device with AR capabilities.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showARAnalytics() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('AR Analytics'),
        content: const Text('AR analytics dashboard would be shown here, displaying usage statistics, popular features, and performance metrics.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.primaryRed,
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  IconData _getNutritionIcon(String nutrient) {
    switch (nutrient.toLowerCase()) {
      case 'calories':
        return Icons.local_fire_department;
      case 'protein':
        return Icons.fitness_center;
      case 'carbs':
      case 'carbohydrates':
        return Icons.grass;
      case 'fat':
        return Icons.opacity;
      case 'fiber':
        return Icons.eco;
      default:
        return Icons.food_bank;
    }
  }

  Color _getNutritionColor(String nutrient) {
    switch (nutrient.toLowerCase()) {
      case 'calories':
        return AppColors.accentOrange;
      case 'protein':
        return AppColors.successGreen;
      case 'carbs':
      case 'carbohydrates':
        return AppColors.primaryRed;
      case 'fat':
        return AppColors.accentOrange;
      case 'fiber':
        return AppColors.successGreen;
      default:
        return AppColors.textSecondary;
    }
  }

  Color _getAllergenColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
        return AppColors.primaryRed;
      case 'medium':
        return AppColors.accentOrange;
      case 'low':
        return AppColors.textSecondary;
      default:
        return AppColors.textSecondary;
    }
  }
}