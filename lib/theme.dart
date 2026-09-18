import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'responsive.dart';

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

  static const surfaceWhite = Color(0xFFF8F9FA);
  static const outlineGray = Color(0xFFE0E0E0);
}

/// سایزهای پایه‌ی فونت (قبل از اعمال fontScale)
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

/// تم ریسپانسیو — باید داخل builder مربوط به MaterialApp صدا زده شود
/// تا با هر تغییر اندازه صفحه/پنجره، فونت‌ها و پدینگ‌ها بازمحاسبه شوند.
ThemeData buildAppTheme(BuildContext context) {
  final fs = context.fontScale;
  final ui = context.uiScale;

  // هِلپر: ساخت TextStyle با گوگل‌فونت + مقیاس فونت
  TextStyle vz(double base, FontWeight weight) =>
      GoogleFonts.vazirmatn(fontSize: base * fs, fontWeight: weight);

  final textTheme = TextTheme(
    displayLarge: vz(FontSizes.displayLarge, FontWeight.w400),
    displayMedium: vz(FontSizes.displayMedium, FontWeight.w400),
    displaySmall: vz(FontSizes.displaySmall, FontWeight.w400),
    headlineLarge: vz(FontSizes.headlineLarge, FontWeight.w700),
    headlineMedium: vz(FontSizes.headlineMedium, FontWeight.w700),
    headlineSmall: vz(FontSizes.headlineSmall, FontWeight.w600),
    titleLarge: vz(FontSizes.titleLarge, FontWeight.w700),
    titleMedium: vz(FontSizes.titleMedium, FontWeight.w600),
    titleSmall: vz(FontSizes.titleSmall, FontWeight.w600),
    labelLarge: vz(FontSizes.labelLarge, FontWeight.w500),
    labelMedium: vz(FontSizes.labelMedium, FontWeight.w500),
    labelSmall: vz(FontSizes.labelSmall, FontWeight.w500),
    bodyLarge: vz(FontSizes.bodyLarge, FontWeight.w400),
    bodyMedium: vz(FontSizes.bodyMedium, FontWeight.w400),
    bodySmall: vz(FontSizes.bodySmall, FontWeight.w400),
  );

  final radiusSm = AppRadius.sm * ui;
  final radiusMd = AppRadius.md * ui;
  final radiusLg = AppRadius.lg * ui;

  final buttonPadding = EdgeInsets.symmetric(
    horizontal: AppSpacing.lg * ui,
    vertical: AppSpacing.md * ui,
  );

  final inputPadding = EdgeInsets.symmetric(
    horizontal: AppSpacing.md * ui,
    vertical: AppSpacing.md * ui,
  );

  return ThemeData(
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
    visualDensity: VisualDensity.adaptivePlatformDensity,

    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.primaryBlack,
      foregroundColor: AppColors.primaryWhite,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: textTheme.titleLarge?.copyWith(
        color: AppColors.primaryWhite,
      ),
      toolbarHeight: 56 * ui.clamp(0.95, 1.15),
    ),

    cardTheme: CardThemeData(
      color: AppColors.primaryWhite,
      elevation: 4,
      shadowColor: AppColors.primaryBlack.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusLg),
        side: const BorderSide(color: AppColors.outlineGray, width: 0.5),
      ),
      margin: EdgeInsets.zero,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.deepTeal,
        foregroundColor: AppColors.primaryWhite,
        elevation: 0,
        padding: buttonPadding,
        textStyle: textTheme.labelLarge,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.deepTeal,
        side: const BorderSide(color: AppColors.deepTeal),
        padding: buttonPadding,
        textStyle: textTheme.labelLarge,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.deepTeal,
        textStyle: textTheme.labelLarge,
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.primaryWhite,
      contentPadding: inputPadding,
      hintStyle: textTheme.bodyMedium?.copyWith(
        color: AppColors.primaryBlack.withValues(alpha: 0.4),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: AppColors.outlineGray),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: AppColors.outlineGray),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: AppColors.deepTeal, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: AppColors.error),
      ),
    ),

    iconTheme: IconThemeData(size: 24 * ui),
    dividerTheme: DividerThemeData(
      color: AppColors.outlineGray,
      thickness: 1 * ui,
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusLg),
      ),
    ),

    textTheme: textTheme,
  );
}
