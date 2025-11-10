import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ===================== BOLD COLOR PALETTE (ZOMATO-INSPIRED) =====================
class AppColors {
  // Primary Colors
  static const Color primaryRed = Color(0xFFD62828);
  static const Color secondaryBlack = Color(0xFF1B1B1E);
  static const Color accentOrange = Color(0xFFF77F00);
  static const Color backgroundGray = Color(0xFF2A2A2E);
  static const Color lightTextWhite = Color(0xFFF1F1F1);
  
  // Additional Colors
  static const Color cardBackground = Color(0xFF333338);
  static const Color surfaceGray = Color(0xFF1E1E1E);
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color dividerGray = Color(0xFF404040);
  static const Color successGreen = Color(0xFF28A745);
  static const Color warningYellow = Color(0xFFFFC107);
  static const Color errorRed = Color(0xFFDC3545);
  static const Color transparentOverlay = Color(0x80000000);
  
  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryRed, accentOrange],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient darkGradient = LinearGradient(
    colors: [secondaryBlack, backgroundGray],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

// ===================== MODERN TYPOGRAPHY SYSTEM =====================
class AppTextStyles {
  // Headings
  static TextStyle get displayLarge => GoogleFonts.poppins(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.lightTextWhite,
    height: 1.2,
  );
  
  static TextStyle get displayMedium => GoogleFonts.poppins(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    color: AppColors.lightTextWhite,
    height: 1.3,
  );
  
  static TextStyle get displaySmall => GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.lightTextWhite,
    height: 1.3,
  );
  
  // Title Styles
  static TextStyle get titleLarge => GoogleFonts.montserrat(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.lightTextWhite,
    height: 1.4,
  );
  
  static TextStyle get titleMedium => GoogleFonts.montserrat(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: AppColors.lightTextWhite,
    height: 1.4,
  );
  
  static TextStyle get titleSmall => GoogleFonts.montserrat(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.lightTextWhite,
    height: 1.4,
  );
  
  // Body Styles
  static TextStyle get bodyLarge => GoogleFonts.lato(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.lightTextWhite,
    height: 1.5,
  );
  
  static TextStyle get bodyMedium => GoogleFonts.lato(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );
  
  static TextStyle get bodySmall => GoogleFonts.lato(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.4,
  );
  
  // Label Styles
  static TextStyle get labelLarge => GoogleFonts.montserrat(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.lightTextWhite,
    height: 1.3,
  );
  
  static TextStyle get labelMedium => GoogleFonts.montserrat(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.lightTextWhite,
    height: 1.3,
  );
  
  // Button Styles
  static TextStyle get buttonText => GoogleFonts.montserrat(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.lightTextWhite,
    height: 1.2,
    letterSpacing: 0.5,
  );
  
  static TextStyle get buttonTextSmall => GoogleFonts.montserrat(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.lightTextWhite,
    height: 1.2,
    letterSpacing: 0.5,
  );
  
  // Price and Special Styles
  static TextStyle get priceText => GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.accentOrange,
    height: 1.2,
  );
  
  static TextStyle get priceSmall => GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.accentOrange,
    height: 1.2,
  );
  
  static TextStyle get ratingText => GoogleFonts.montserrat(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.successGreen,
    height: 1.2,
  );
}

// ===================== CONSISTENT SPACING SYSTEM =====================
class AppSpacing {
  // Screen Margins
  static const double screenPadding = 20.0;
  static const double screenMargin = 16.0;
  
  // Component Spacing
  static const double small = 4.0;
  static const double medium = 8.0;
  static const double large = 16.0;
  static const double extraLarge = 24.0;
  static const double huge = 32.0;
  static const double massive = 48.0;
  
  // Card Spacing
  static const double cardPadding = 16.0;
  static const double cardMargin = 12.0;
  static const double cardBorderRadius = 16.0;
  
  // Button Spacing
  static const double buttonPadding = 16.0;
  static const double buttonMargin = 8.0;
  static const double buttonHeight = 56.0;
  static const double buttonSmallHeight = 40.0;
  
  // List Spacing
  static const double listItemPadding = 16.0;
  static const double listItemSpacing = 12.0;
  
  // Icon Spacing
  static const double iconSizeSmall = 16.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;
  static const double iconSizeExtraLarge = 48.0;
}

// ===================== ENHANCED UI COMPONENTS WITH LAYERED EFFECTS =====================
class AppDecorations {
  // Card Decoration with Shadow and Gradient
  static BoxDecoration get cardDecoration => BoxDecoration(
    gradient: const LinearGradient(
      colors: [Color(0xFF333338), Color(0xFF2A2A2E)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(AppSpacing.cardBorderRadius),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.3),
        blurRadius: 12,
        offset: const Offset(0, 6),
        spreadRadius: -2,
      ),
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 2,
        offset: const Offset(0, 1),
      ),
    ],
    border: Border.all(
      color: AppColors.dividerGray,
      width: 0.5,
    ),
  );
  
  // Elevated Card with stronger shadow
  static BoxDecoration get elevatedCardDecoration => BoxDecoration(
    gradient: const LinearGradient(
      colors: [Color(0xFF3A3A3F), Color(0xFF2E2E33)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(AppSpacing.cardBorderRadius),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.4),
        blurRadius: 16,
        offset: const Offset(0, 8),
        spreadRadius: -3,
      ),
      BoxShadow(
        color: Colors.black.withOpacity(0.2),
        blurRadius: 4,
        offset: const Offset(0, 2),
      ),
    ],
    border: Border.all(
      color: AppColors.dividerGray.withOpacity(0.3),
      width: 0.8,
    ),
  );
  
  // Button Decoration with Gradient
  static BoxDecoration get primaryButtonDecoration => BoxDecoration(
    gradient: const LinearGradient(
      colors: [AppColors.primaryRed, AppColors.accentOrange],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(AppSpacing.buttonHeight / 2),
    boxShadow: [
      BoxShadow(
        color: AppColors.primaryRed.withOpacity(0.3),
        blurRadius: 12,
        offset: const Offset(0, 6),
        spreadRadius: -2,
      ),
    ],
  );
  
  // Secondary Button Decoration
  static BoxDecoration get secondaryButtonDecoration => BoxDecoration(
    color: AppColors.cardBackground,
    borderRadius: BorderRadius.circular(AppSpacing.buttonHeight / 2),
    border: Border.all(
      color: AppColors.primaryRed,
      width: 2.0,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.2),
        blurRadius: 8,
        offset: const Offset(0, 4),
        spreadRadius: -1,
      ),
    ],
  );
  
  // Input Field Decoration
  static BoxDecoration get inputFieldDecoration => BoxDecoration(
    color: AppColors.surfaceGray,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
      color: AppColors.dividerGray,
      width: 1.0,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 4,
        offset: const Offset(0, 2),
      ),
    ],
  );
  
  // Hero Banner Decoration
  static BoxDecoration get heroBannerDecoration => BoxDecoration(
    gradient: const LinearGradient(
      colors: [AppColors.secondaryBlack, AppColors.backgroundGray],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.5),
        blurRadius: 20,
        offset: const Offset(0, 10),
        spreadRadius: -5,
      ),
    ],
  );
}

// ===================== MAIN THEME DATA =====================
class AppTheme {
  static Color get primaryColor => AppColors.primaryRed;

  static ThemeData get darkThemeData {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.secondaryBlack,
      
      // Color Scheme
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryRed,
        secondary: AppColors.accentOrange,
        surface: AppColors.cardBackground,
        background: AppColors.secondaryBlack,
        onPrimary: AppColors.lightTextWhite,
        onSecondary: AppColors.lightTextWhite,
        onSurface: AppColors.lightTextWhite,
        onBackground: AppColors.lightTextWhite,
        error: AppColors.errorRed,
        onError: AppColors.lightTextWhite,
      ),
      
      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.backgroundGray,
        foregroundColor: AppColors.lightTextWhite,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTextStyles.titleLarge,
        shadowColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
      ),
      
      // Card Theme
      cardTheme: const CardThemeData(
        color: AppColors.cardBackground,
        elevation: 8,
        shadowColor: Color(0x33000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16.0)),
        ),
        margin: EdgeInsets.symmetric(
          vertical: 12.0,
          horizontal: 16.0,
        ),
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.lightTextWhite,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.buttonPadding,
            vertical: AppSpacing.medium,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.buttonHeight / 2),
          ),
          textStyle: AppTextStyles.buttonText,
        ),
      ),
      
      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryRed,
          side: const BorderSide(color: AppColors.primaryRed, width: 2),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.buttonPadding,
            vertical: AppSpacing.medium,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.buttonHeight / 2),
          ),
          textStyle: AppTextStyles.buttonText,
        ),
      ),
      
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accentOrange,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.large,
            vertical: AppSpacing.medium,
          ),
          textStyle: AppTextStyles.buttonTextSmall,
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceGray,
        hintStyle: AppTextStyles.bodyMedium,
        labelStyle: AppTextStyles.bodyMedium,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.dividerGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.dividerGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryRed, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.errorRed),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.large,
          vertical: AppSpacing.medium,
        ),
      ),
      
      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.backgroundGray,
        selectedItemColor: AppColors.primaryRed,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: AppTextStyles.bodySmall,
        unselectedLabelStyle: AppTextStyles.bodySmall,
      ),
      
      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.accentOrange,
        foregroundColor: AppColors.lightTextWhite,
        elevation: 8,
        shape: CircleBorder(),
      ),
      
      // Text Theme
      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayLarge,
        displayMedium: AppTextStyles.displayMedium,
        displaySmall: AppTextStyles.displaySmall,
        titleLarge: AppTextStyles.titleLarge,
        titleMedium: AppTextStyles.titleMedium,
        titleSmall: AppTextStyles.titleSmall,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        bodySmall: AppTextStyles.bodySmall,
        labelLarge: AppTextStyles.labelLarge,
        labelMedium: AppTextStyles.labelMedium,
      ),
    );
  }
}