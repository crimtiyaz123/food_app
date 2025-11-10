# FoodFirst - Bold Modern Design System Guide

## Overview
This design system implements a bold, modern food delivery app UI with high contrast, layered effects, and vibrant colors inspired by platforms like Zomato. The system emphasizes rich visual hierarchy, smooth animations, and professional typography.

## 🎨 Bold Color Palette

### Primary Colors
- **Primary Red**: `#D62828` - Main brand color for CTAs and primary actions
- **Secondary Black**: `#1B1B1E` - Background and dark surfaces  
- **Accent Orange**: `#F77F00` - Highlights and secondary CTAs
- **Background Gray**: `#2A2A2E` - Card backgrounds and elevated surfaces
- **Light Text White**: `#F1F1F1` - Primary text color

### Supporting Colors
- **Card Background**: `#333338` - Card and component backgrounds
- **Surface Gray**: `#1E1E1E` - Input fields and form elements
- **Text Secondary**: `#B0B0B0` - Secondary text and captions
- **Success Green**: `#28A745` - Success states and ratings
- **Warning Yellow**: `#FFC107` - Warning messages
- **Error Red**: `#DC3545` - Error states

### Gradient Combinations
- **Primary Gradient**: Red to Orange (primary actions)
- **Dark Gradient**: Black to Gray (backgrounds)

## 📝 Typography System

### Display Styles (Large Headers)
```dart
AppTextStyles.displayLarge    // 32px, Bold (700)
AppTextStyles.displayMedium   // 28px, SemiBold (600) 
AppTextStyles.displaySmall    // 24px, SemiBold (600)
```

### Title Styles (Section Headers)
```dart
AppTextStyles.titleLarge      // 22px, SemiBold (600)
AppTextStyles.titleMedium     // 18px, Medium (500)
AppTextStyles.titleSmall      // 16px, Medium (500)
```

### Body Styles (Content Text)
```dart
AppTextStyles.bodyLarge       // 16px, Regular (400)
AppTextStyles.bodyMedium      // 14px, Regular (400)
AppTextStyles.bodySmall       // 12px, Regular (400)
```

### Special Styles
```dart
AppTextStyles.priceText       // 18px, Bold, Orange color
AppTextStyles.ratingText      // 12px, SemiBold, Green color
AppTextStyles.buttonText      // 16px, SemiBold, White
```

### Font Families
- **Headings**: Poppins (Google Fonts)
- **Titles**: Montserrat (Google Fonts)  
- **Body Text**: Lato (Google Fonts)

## 📐 Spacing System

### Screen Margins
- `AppSpacing.screenPadding = 20.0` - General screen padding
- `AppSpacing.screenMargin = 16.0` - Component margins

### Component Spacing
- `AppSpacing.small = 4.0` - Tight spacing
- `AppSpacing.medium = 8.0` - Standard spacing
- `AppSpacing.large = 16.0` - Loose spacing
- `AppSpacing.extraLarge = 24.0` - Section spacing
- `AppSpacing.huge = 32.0` - Major spacing
- `AppSpacing.massive = 48.0` - Hero section spacing

### Card Spacing
- `AppSpacing.cardPadding = 16.0` - Internal card padding
- `AppSpacing.cardMargin = 12.0` - Card margins
- `AppSpacing.cardBorderRadius = 16.0` - Card corner radius

### Button Spacing
- `AppSpacing.buttonPadding = 16.0` - Button internal padding
- `AppSpacing.buttonHeight = 56.0` - Standard button height
- `AppSpacing.buttonSmallHeight = 40.0` - Small button height

## 🎭 UI Components

### 1. BoldFoodProductCard
Displays food products with rich imagery, price badges, and ratings.

```dart
BoldFoodProductCard(
  name: 'Classic Burger',
  price: 12.99,
  rating: 4.5,
  description: 'Juicy beef patty with fresh vegetables',
  imageUrl: 'https://example.com/burger.jpg',
  onAddToCart: () => addToCart(),
  onTap: () => navigateToProduct(),
)
```

**Features:**
- Gradient price badges
- Rating displays with stars
- Hover animations
- Fallback placeholders for missing images
- Add to cart functionality

### 2. BoldCategoryChip
Interactive category filters with smooth animations.

```dart
BoldCategoryChip(
  label: 'Burgers',
  isSelected: isSelected,
  onTap: () => selectCategory(),
)
```

**Features:**
- Gradient selection states
- Smooth color transitions
- Shadow effects
- Rounded pill design

### 3. BoldRestaurantCard
Showcase restaurants with delivery info and ratings.

```dart
BoldRestaurantCard(
  name: 'Italian Kitchen',
  cuisine: 'Italian',
  rating: 4.8,
  deliveryTime: 25,
  deliveryFee: 2.99,
  imageUrl: 'https://example.com/restaurant.jpg',
  onTap: () => openRestaurant(),
)
```

**Features:**
- Restaurant image thumbnails
- Delivery time and fee display
- Rating badges
- Cuisine type indicators

### 4. BoldSearchBar
Custom search input with consistent styling.

```dart
BoldSearchBar(
  controller: searchController,
  hintText: 'Search for food...',
  onChanged: (value) => updateSearch(value),
  onSubmitted: (value) => performSearch(),
)
```

**Features:**
- Consistent input field styling
- Search icon integration
- Focus state animations

### 5. BoldHeroSection
Large banner sections for important content.

```dart
BoldHeroSection(
  title: 'Discover Delicious Food',
  subtitle: 'Order from your favorite restaurants',
  actions: [/* action buttons */],
)
```

**Features:**
- Large, bold typography
- Background gradient support
- Action button integration
- Responsive design

## 🎨 Decoration System

### Card Decorations
```dart
// Standard card with subtle shadow
AppDecorations.cardDecoration

// Elevated card with stronger shadow  
AppDecorations.elevatedCardDecoration

// Hero banner decoration
AppDecorations.heroBannerDecoration
```

### Button Decorations
```dart
// Primary button with gradient
AppDecorations.primaryButtonDecoration

// Secondary button with border
AppDecorations.secondaryButtonDecoration
```

### Input Field Decoration
```dart
AppDecorations.inputFieldDecoration
```

## 🚀 Animation Guidelines

### Animation Principles
1. **Smooth Transitions**: Use 200-300ms for most animations
2. **Staggered Loading**: Delay child animations by 50-100ms for visual flow
3. **Easing Curves**: Use `Curves.easeOutCubic` for natural feel
4. **Transform Properties**: Prefer transform over layout changes for performance

### Common Animation Patterns
```dart
// Fade in animation
FadeTransition(
  opacity: Tween(begin: 0.0, end: 1.0).animate(
    CurvedAnimation(parent: animationController, curve: Curves.easeIn)
  ),
  child: child,
)

// Slide up animation
SlideTransition(
  position: Tween(begin: Offset(0, 0.3), end: Offset.zero).animate(
    CurvedAnimation(parent: animationController, curve: Curves.easeOutCubic)
  ),
  child: child,
)

// Scale animation
ScaleTransition(
  scale: Tween(begin: 0.8, end: 1.0).animate(
    CurvedAnimation(parent: animationController, curve: Curves.elasticOut)
  ),
  child: child,
)
```

## 📱 Responsive Design

### Breakpoint Strategy
- **Mobile**: < 600px width
- **Tablet**: 600px - 1200px width  
- **Desktop**: > 1200px width

### Grid Systems
- **Product Grid**: 2 columns (mobile), 3 columns (tablet+)
- **Category Grid**: 2 columns (mobile), 4 columns (tablet+)
- **Restaurant Grid**: 1 column (mobile), 2 columns (tablet+)

### Adaptive Components
```dart
// Responsive text sizing
double getResponsiveTextSize(BuildContext context) {
  if (MediaQuery.of(context).size.width > 600) {
    return 18.0;
  }
  return 16.0;
}

// Responsive padding
EdgeInsets getResponsivePadding(BuildContext context) {
  if (MediaQuery.of(context).size.width > 600) {
    return EdgeInsets.all(24.0);
  }
  return EdgeInsets.all(16.0);
}
```

## 🛠️ Implementation Examples

### 1. Complete Product Grid Screen
```dart
class ProductGridScreen extends StatelessWidget {
  final List<Product> products;
  
  const ProductGridScreen({super.key, required this.products});

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
          slivers: [
            SliverAppBar(
              expandedHeight: 120,
              flexibleSpace: FlexibleSpaceBar(
                title: Text('Menu', style: AppTextStyles.titleLarge),
              ),
            ),
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
                    return BoldFoodProductCard(
                      name: products[index].name,
                      price: products[index].price,
                      rating: products[index].rating,
                      description: products[index].description,
                      imageUrl: products[index].imageUrl,
                      onAddToCart: () => addToCart(products[index]),
                    );
                  },
                  childCount: products.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### 2. Category Filter Bar
```dart
class CategoryFilterBar extends StatefulWidget {
  final List<String> categories;
  final ValueChanged<String> onCategorySelected;
  
  const CategoryFilterBar({
    super.key,
    required this.categories,
    required this.onCategorySelected,
  });

  @override
  State<CategoryFilterBar> createState() => _CategoryFilterBarState();
}

class _CategoryFilterBarState extends State<CategoryFilterBar> {
  String selectedCategory = 'All';
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.categories.length,
        itemBuilder: (context, index) {
          final category = widget.categories[index];
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(right: AppSpacing.medium),
            child: BoldCategoryChip(
              label: category,
              isSelected: category == selectedCategory,
              onTap: () {
                setState(() => selectedCategory = category);
                widget.onCategorySelected(category);
              },
            ),
          );
        },
      ),
    );
  }
}
```

## 🎯 Best Practices

### 1. Color Usage
- Use primary red for primary CTAs and important actions
- Use accent orange for secondary actions and highlights
- Maintain high contrast ratios for accessibility
- Use gradients sparingly for emphasis

### 2. Typography
- Use display styles for main headings only
- Maintain consistent line spacing (1.2-1.6)
- Use appropriate font weights for hierarchy
- Test readability on different screen sizes

### 3. Spacing
- Follow the 8pt grid system
- Use consistent margins and padding
- Maintain visual breathing room
- Consider touch targets for mobile (44px minimum)

### 4. Animations
- Keep animations purposeful and fast
- Use spring animations for natural feel
- Respect user preferences for reduced motion
- Test performance on lower-end devices

### 5. Accessibility
- Maintain 4.5:1 contrast ratio minimum
- Use semantic colors for states (red for errors, green for success)
- Provide alternative text for images
- Support dynamic text scaling

## 📋 Design System Checklist

- [ ] All screens use consistent color palette
- [ ] Typography follows hierarchy system
- [ ] Spacing follows 8pt grid
- [ ] Components use consistent decoration patterns
- [ ] Animations are smooth and purposeful
- [ ] Responsive design works on all screen sizes
- [ ] Accessibility standards are met
- [ ] Loading states and error handling are consistent
- [ ] Brand identity is maintained throughout
- [ ] Performance is optimized for all devices

## 🚀 Getting Started

### 1. Import the Design System
```dart
import 'package:food_app/theme/app_theme.dart';
import 'package:food_app/widgets/enhanced_ui_components.dart';
```

### 2. Apply the Theme
```dart
MaterialApp(
  theme: AppTheme.darkThemeData,
  home: YourMainScreen(),
)
```

### 3. Use Components
```dart
BoldFoodProductCard(
  name: 'Product Name',
  price: 12.99,
  onAddToCart: () {},
)
```

### 4. Reference Documentation
- Check `app_theme.dart` for color and style definitions
- Use `enhanced_ui_components.dart` for pre-built components
- Refer to `design_showcase_screen.dart` for complete examples