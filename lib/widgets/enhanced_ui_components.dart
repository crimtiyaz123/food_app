import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ===================== BOLD FOOD PRODUCT CARD =====================
class BoldFoodProductCard extends StatelessWidget {
  final String name;
  final double price;
  final double? rating;
  final String? description;
  final String? imageUrl;
  final VoidCallback? onAddToCart;
  final VoidCallback? onTap;

  const BoldFoodProductCard({
    super.key,
    required this.name,
    required this.price,
    this.rating,
    this.description,
    this.imageUrl,
    this.onAddToCart,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
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
                // Product Image with Enhanced Overlay
                Expanded(
                  flex: 3,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.transparent, Colors.black54],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppSpacing.cardBorderRadius),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppSpacing.cardBorderRadius),
                      ),
                      child: Stack(
                        children: [
                          if (imageUrl != null)
                            Image.network(
                              imageUrl!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildPlaceholderImage();
                              },
                            )
                          else
                            _buildPlaceholderImage(),
                          
                          // Price Badge
                          Positioned(
                            top: AppSpacing.medium,
                            right: AppSpacing.medium,
                            child: _buildPriceBadge(),
                          ),
                          
                          // Rating Badge
                          if (rating != null) ...[
                            Positioned(
                              bottom: AppSpacing.medium,
                              left: AppSpacing.medium,
                              child: _buildRatingBadge(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Product Details
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.large),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product Name
                        Text(
                          name,
                          style: AppTextStyles.titleSmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSpacing.small),
                        
                        // Description
                        if (description != null) ...[
                          Text(
                            description!,
                            style: AppTextStyles.bodySmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: AppSpacing.large),
                        ] else ...[
                          const Spacer(),
                        ],
                        
                        // Add to Cart Button
                        if (onAddToCart != null)
                          SizedBox(
                            width: double.infinity,
                            height: 40,
                            child: ElevatedButton(
                              onPressed: onAddToCart,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: EdgeInsets.zero,
                              ),
                              child: Container(
                                width: double.infinity,
                                height: double.infinity,
                                decoration: AppDecorations.primaryButtonDecoration,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_shopping_cart,
                                      size: 16,
                                      color: AppColors.lightTextWhite,
                                    ),
                                    const SizedBox(width: AppSpacing.small),
                                    Text(
                                      'Add to Cart',
                                      style: AppTextStyles.buttonTextSmall,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
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
    );
  }

  Widget _buildPriceBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.medium,
        vertical: AppSpacing.small,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.accentOrange, AppColors.primaryRed],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentOrange.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        '\$${price.toStringAsFixed(2)}',
        style: AppTextStyles.priceSmall.copyWith(
          color: AppColors.lightTextWhite,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildRatingBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.medium,
        vertical: AppSpacing.small,
      ),
      decoration: BoxDecoration(
        color: AppColors.successGreen.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star,
            size: 14,
            color: AppColors.lightTextWhite,
          ),
          const SizedBox(width: AppSpacing.small),
          Text(
            rating!.toStringAsFixed(1),
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.lightTextWhite,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ===================== BOLD CATEGORY CHIP =====================
class BoldCategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  const BoldCategoryChip({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
          boxShadow: [
            BoxShadow(
              color: isSelected 
                  ? AppColors.primaryRed.withOpacity(0.3)
                  : Colors.black.withOpacity(0.2),
              blurRadius: isSelected ? 12 : 8,
              offset: const Offset(0, 4),
              spreadRadius: -1,
            ),
          ],
          border: isSelected 
              ? null 
              : Border.all(
                  color: AppColors.dividerGray,
                  width: 1,
                ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: isSelected 
              ? AppTextStyles.buttonText 
              : AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
        ),
      ),
    );
  }
}

// ===================== BOLD RESTAURANT CARD =====================
class BoldRestaurantCard extends StatelessWidget {
  final String name;
  final String cuisine;
  final double rating;
  final int deliveryTime;
  final double deliveryFee;
  final String? imageUrl;
  final VoidCallback? onTap;

  const BoldRestaurantCard({
    super.key,
    required this.name,
    required this.cuisine,
    required this.rating,
    required this.deliveryTime,
    required this.deliveryFee,
    this.imageUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.large),
        decoration: AppDecorations.cardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Restaurant Image
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.cardBackground, AppColors.surfaceGray],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSpacing.cardBorderRadius),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSpacing.cardBorderRadius),
                ),
                child: imageUrl != null
                    ? Image.network(
                        imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Icon(
                              Icons.restaurant,
                              size: 40,
                              color: AppColors.textSecondary,
                            ),
                          );
                        },
                      )
                    : Center(
                        child: Icon(
                          Icons.restaurant,
                          size: 40,
                          color: AppColors.textSecondary,
                        ),
                      ),
              ),
            ),
            
            // Restaurant Details
            Padding(
              padding: const EdgeInsets.all(AppSpacing.large),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and Rating
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: AppTextStyles.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _buildRatingBadge(),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.small),
                  
                  // Cuisine and Delivery Info
                  Row(
                    children: [
                      Icon(
                        Icons.local_dining,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: AppSpacing.small),
                      Text(
                        cuisine,
                        style: AppTextStyles.bodySmall,
                      ),
                      const SizedBox(width: AppSpacing.extraLarge),
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: AppSpacing.small),
                      Text(
                        '${deliveryTime}min',
                        style: AppTextStyles.bodySmall,
                      ),
                      const SizedBox(width: AppSpacing.extraLarge),
                      Icon(
                        Icons.delivery_dining,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: AppSpacing.small),
                      Text(
                        deliveryFee == 0 ? 'Free' : '\$${deliveryFee.toStringAsFixed(2)}',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.medium,
        vertical: AppSpacing.small,
      ),
      decoration: BoxDecoration(
        color: AppColors.successGreen.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star,
            size: 12,
            color: AppColors.lightTextWhite,
          ),
          const SizedBox(width: AppSpacing.small),
          Text(
            rating.toStringAsFixed(1),
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.lightTextWhite,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ===================== BOLD SEARCH BAR =====================
class BoldSearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSubmitted;

  const BoldSearchBar({
    super.key,
    this.controller,
    this.hintText = 'Search for food...',
    this.onChanged,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: AppDecorations.inputFieldDecoration,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        onSubmitted: (value) => onSubmitted?.call(),
        style: AppTextStyles.bodyLarge,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: AppColors.textSecondary,
            size: 24,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.large,
            vertical: AppSpacing.medium,
          ),
        ),
      ),
    );
  }
}

// ===================== BOLD HERO SECTION =====================
class BoldHeroSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? backgroundImage;
  final List<Widget>? actions;

  const BoldHeroSection({
    super.key,
    required this.title,
    required this.subtitle,
    this.backgroundImage,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.extraLarge),
      decoration: AppDecorations.heroBannerDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.huge),
          Text(
            title,
            style: AppTextStyles.displaySmall,
          ),
          const SizedBox(height: AppSpacing.medium),
          Text(
            subtitle,
            style: AppTextStyles.bodyLarge,
          ),
          if (actions != null) ...[
            const SizedBox(height: AppSpacing.extraLarge),
            ...actions!,
          ] else ...[
            const SizedBox(height: AppSpacing.huge),
          ],
        ],
      ),
    );
  }
}

// ===================== ANIMATED BOTTOM NAV BAR =====================
class AnimatedBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;
  final List<BottomNavigationBarItem> items;

  const AnimatedBottomNavBar({
    super.key,
    required this.currentIndex,
    this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
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
        currentIndex: currentIndex,
        selectedItemColor: AppColors.primaryRed,
        unselectedItemColor: AppColors.textSecondary,
        backgroundColor: AppColors.backgroundGray,
        elevation: 0,
        onTap: onTap,
        items: items,
      ),
    );
  }
}