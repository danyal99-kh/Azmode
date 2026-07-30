import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

class AppRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
}

extension TextStyleContext on BuildContext {
  TextTheme get textStyles => Theme.of(this).textTheme;
}

extension TextStyleExtensions on TextStyle {
  TextStyle get bold => copyWith(fontWeight: FontWeight.bold);
  TextStyle get semiBold => copyWith(fontWeight: FontWeight.w600);
  TextStyle get medium => copyWith(fontWeight: FontWeight.w500);
  TextStyle get normal => copyWith(fontWeight: FontWeight.w400);
  TextStyle get light => copyWith(fontWeight: FontWeight.w300);
  TextStyle withColor(Color color) => copyWith(color: color);
  TextStyle withSize(double size) => copyWith(fontSize: size);
}

class AppColors {
  static const primaryWhite = Color(0xFFFFFFFF);
  static const primaryBlack = Color(0xFF121212);
  static const darkGray = Color(0xFF2B2B2B);
  static const deepTeal = Color(0xFF005F5F);

  static const error = Color(0xFFD32F2F);
  static const success = Color(0xFF388E3C);
  static const warning = Color(0xFFF57C00);

  static const surfaceWhite = Color(
    0xFFF8F9FA,
  ); // slightly off-white for backgrounds
  static const outlineGray = Color(0xFFE0E0E0);
}

class FontSizes {
  static const double displayLarge = 57.0;
  static const double displayMedium = 45.0;
  static const double displaySmall = 36.0;
  static const double headlineLarge = 32.0;
  static const double headlineMedium = 28.0;
  static const double headlineSmall = 24.0;
  static const double titleLarge = 22.0;
  static const double titleMedium = 16.0;
  static const double titleSmall = 14.0;
  static const double labelLarge = 14.0;
  static const double labelMedium = 12.0;
  static const double labelSmall = 11.0;
  static const double bodyLarge = 16.0;
  static const double bodyMedium = 14.0;
  static const double bodySmall = 12.0;
}

ThemeData get appTheme => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.light(
    primary: AppColors.deepTeal,
    onPrimary: AppColors.primaryWhite,
    secondary: AppColors.darkGray,
    onSecondary: AppColors.primaryWhite,
    surface: AppColors.primaryWhite,
    onSurface: AppColors.primaryBlack,
    error: AppColors.error,
    onError: AppColors.primaryWhite,
  ),
  scaffoldBackgroundColor: AppColors.surfaceWhite,
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.primaryBlack,
    foregroundColor: AppColors.primaryWhite,
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: true,
  ),
  cardTheme: CardThemeData(
    color: AppColors.primaryWhite,
    elevation: 4,
    shadowColor: AppColors.primaryBlack.withValues(alpha: 0.05),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      side: const BorderSide(color: AppColors.outlineGray, width: 0.5),
    ),
    margin: EdgeInsets.zero,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.deepTeal,
      foregroundColor: AppColors.primaryWhite,
      elevation: 0,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.deepTeal,
      side: const BorderSide(color: AppColors.deepTeal),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(foregroundColor: AppColors.deepTeal),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.primaryWhite,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.md,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: const BorderSide(color: AppColors.outlineGray),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: const BorderSide(color: AppColors.outlineGray),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: const BorderSide(color: AppColors.deepTeal, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: const BorderSide(color: AppColors.error),
    ),
  ),
  textTheme: _buildTextTheme(),
);

TextTheme _buildTextTheme() {
  return TextTheme(
    displayLarge: GoogleFonts.vazirmatn(
      fontSize: FontSizes.displayLarge,
      fontWeight: FontWeight.w400,
    ),
    displayMedium: GoogleFonts.vazirmatn(
      fontSize: FontSizes.displayMedium,
      fontWeight: FontWeight.w400,
    ),
    displaySmall: GoogleFonts.vazirmatn(
      fontSize: FontSizes.displaySmall,
      fontWeight: FontWeight.w400,
    ),
    headlineLarge: GoogleFonts.vazirmatn(
      fontSize: FontSizes.headlineLarge,
      fontWeight: FontWeight.w700,
    ),
    headlineMedium: GoogleFonts.vazirmatn(
      fontSize: FontSizes.headlineMedium,
      fontWeight: FontWeight.w700,
    ),
    headlineSmall: GoogleFonts.vazirmatn(
      fontSize: FontSizes.headlineSmall,
      fontWeight: FontWeight.w600,
    ),
    titleLarge: GoogleFonts.vazirmatn(
      fontSize: FontSizes.titleLarge,
      fontWeight: FontWeight.w700,
    ),
    titleMedium: GoogleFonts.vazirmatn(
      fontSize: FontSizes.titleMedium,
      fontWeight: FontWeight.w600,
    ),
    titleSmall: GoogleFonts.vazirmatn(
      fontSize: FontSizes.titleSmall,
      fontWeight: FontWeight.w600,
    ),
    labelLarge: GoogleFonts.vazirmatn(
      fontSize: FontSizes.labelLarge,
      fontWeight: FontWeight.w500,
    ),
    labelMedium: GoogleFonts.vazirmatn(
      fontSize: FontSizes.labelMedium,
      fontWeight: FontWeight.w500,
    ),
    labelSmall: GoogleFonts.vazirmatn(
      fontSize: FontSizes.labelSmall,
      fontWeight: FontWeight.w500,
    ),
    bodyLarge: GoogleFonts.vazirmatn(
      fontSize: FontSizes.bodyLarge,
      fontWeight: FontWeight.w400,
    ),
    bodyMedium: GoogleFonts.vazirmatn(
      fontSize: FontSizes.bodyMedium,
      fontWeight: FontWeight.w400,
    ),
    bodySmall: GoogleFonts.vazirmatn(
      fontSize: FontSizes.bodySmall,
      fontWeight: FontWeight.w400,
    ),
  );
}
