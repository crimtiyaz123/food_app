import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/food_category.dart';
import '../models/product.dart';
import '../models/cart_model.dart';
import '../services/food_category_service.dart';
import '../theme/app_theme.dart';
import 'product_screen.dart';

class ModernMenuScreen extends StatefulWidget {
  final Map<String, List<Product>> stock;

  const ModernMenuScreen({super.key, required this.stock});

  @override
  State<ModernMenuScreen> createState() => _ModernMenuScreenState();
}

class _ModernMenuScreenState extends State<ModernMenuScreen> {
  String selectedCategory = "All";

  @override
  Widget build(BuildContext context) {
    // All categories keys
    final categories = ["All", ...widget.stock.keys];

    // Products to display based on filter
    List<Product> productsToShow = [];
    if (selectedCategory == "All") {
      widget.stock.values.forEach((list) => productsToShow.addAll(list));
    } else {
      productsToShow = widget.stock[selectedCategory] ?? [];
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu'),
        backgroundColor: AppColors.primaryRed,
        foregroundColor: AppColors.lightTextWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
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
        child: Column(
          children: [
            // Enhanced Header with Gradient
            Container(
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
                boxShadow: [
                  BoxShadow(
                    color: Colors.black,
                    blurRadius: 15,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.medium),
                  Text(
                    'Discover Delicious',
                    style: AppTextStyles.displaySmall,
                  ),
                  const SizedBox(height: AppSpacing.small),
                  Text(
                    'Food from your favorite restaurants',
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.medium),
                ],
              ),
            ),

            // Bold Category Filter Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.large),
                  Text(
                    'Categories',
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
                        final isSelected = category == selectedCategory;
                        return GestureDetector(
                          onTap: () => setState(() => selectedCategory = category),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: AppSpacing.medium),
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
                              category,
                              style: isSelected 
                                  ? AppTextStyles.buttonText 
                                  : AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Products Grid with Enhanced Cards
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                    crossAxisSpacing: AppSpacing.large,
                    mainAxisSpacing: AppSpacing.large,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: productsToShow.length,
                  itemBuilder: (context, index) {
                    final product = productsToShow[index];
                    return AnimatedContainer(
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
                              // Enhanced Product Image with Overlay
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
                                        if (product.imageUrl != null)
                                          Image.network(
                                            product.imageUrl!,
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            height: double.infinity,
                                          )
                                        else
                                          Container(
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
                                        
                                        // Price Badge
                                        Positioned(
                                          top: AppSpacing.medium,
                                          right: AppSpacing.medium,
                                          child: Container(
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
                                              '\$${product.price.toStringAsFixed(2)}',
                                              style: AppTextStyles.priceSmall.copyWith(
                                                color: AppColors.lightTextWhite,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ),
                                        
                                        // Rating Badge
                                        if (product.rating != null)
                                          Positioned(
                                            bottom: AppSpacing.medium,
                                            left: AppSpacing.medium,
                                            child: Container(
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
                                                    product.rating!.toStringAsFixed(1),
                                                    style: AppTextStyles.bodySmall.copyWith(
                                                      color: AppColors.lightTextWhite,
                                                      fontWeight: FontWeight.w600,
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
                              
                              // Product Details with Enhanced Typography
                              Expanded(
                                flex: 2,
                                child: Padding(
                                  padding: const EdgeInsets.all(AppSpacing.large),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Product Name
                                      Text(
                                        product.name,
                                        style: AppTextStyles.titleSmall,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: AppSpacing.small),
                                      
                                      // Description
                                      if (product.description != null) ...[
                                        Text(
                                          product.description!,
                                          style: AppTextStyles.bodySmall,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: AppSpacing.large),
                                      ],
                                      
                                      // Spacer for products without description
                                      if (product.description == null)
                                        const Spacer(),
                                      
                                      // Add to Cart Button
                                      SizedBox(
                                        width: double.infinity,
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
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: AppSpacing.medium,
                                            ),
                                          ),
                                          child: Container(
                                            width: double.infinity,
                                            height: 40,
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
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}