import 'package:flutter/material.dart';

/// Unified Design Tokens for Haneen Kids (Stage P0 / Sprint 2).
/// Provides a single source of truth for colors, spacing, radii, and touch targets
/// across both Light and Dark themes.
class AppDesignTokens {
  // Core Brand & Semantic Palette
  static const Color primaryPurple = Color(0xFF6C63FF);
  static const Color secondaryGreen = Color(0xFF16C79A);
  static const Color rewardGold = Color(0xFFFFB84C);
  static const Color gentlePink = Color(0xFFFF7892);
  static const Color infoBlue = Color(0xFF53B9F5);

  // Dark Surfaces
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkHighContrastBg = Color(0xFF050811);
  static const Color darkHighContrastSurface = Color(0xFF111827);

  // Light Surfaces
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE2E8F0);

  // Spacing & Geometry
  static const double spaceXs = 6.0;
  static const double spaceSm = 12.0;
  static const double spaceMd = 16.0;
  static const double spaceLg = 24.0;

  static const double radiusMd = 16.0;
  static const double radiusLg = 20.0;
  static const double radiusPill = 999.0;

  // Accessibility: Minimum touch target size (>= 48dp)
  static const double minTouchTarget = 48.0;
}

class AppTheme {
  static ThemeData buildTheme({
    required bool highContrast,
    bool isDarkMode = true,
  }) {
    final Color bgColor = isDarkMode
        ? (highContrast
            ? AppDesignTokens.darkHighContrastBg
            : AppDesignTokens.darkBackground)
        : AppDesignTokens.lightBackground;

    final Color surfaceColor = isDarkMode
        ? (highContrast
            ? AppDesignTokens.darkHighContrastSurface
            : AppDesignTokens.darkSurface)
        : AppDesignTokens.lightSurface;

    final Color primaryColor =
        highContrast ? const Color(0xFF818CF8) : AppDesignTokens.primaryPurple;

    final Color secondaryColor =
        highContrast ? const Color(0xFF2DD4BF) : AppDesignTokens.secondaryGreen;

    final Brightness brightness =
        isDarkMode ? Brightness.dark : Brightness.light;

    final ColorScheme colorScheme = isDarkMode
        ? ColorScheme.dark(
            primary: primaryColor,
            secondary: secondaryColor,
            tertiary: AppDesignTokens.rewardGold,
            surface: surfaceColor,
            onPrimary: Colors.white,
            onSecondary: const Color(0xFF0F172A),
            onSurface: Colors.white,
          )
        : ColorScheme.light(
            primary: primaryColor,
            secondary: secondaryColor,
            tertiary: AppDesignTokens.rewardGold,
            surface: surfaceColor,
            onPrimary: Colors.white,
            onSecondary: Colors.white,
            onSurface: const Color(0xFF0F172A),
          );

    final ThemeData base = isDarkMode ? ThemeData.dark() : ThemeData.light();

    return base.copyWith(
      brightness: brightness,
      scaffoldBackgroundColor: bgColor,
      colorScheme: colorScheme,
      textTheme: base.textTheme.apply(
        bodyColor: colorScheme.onSurface,
        displayColor: colorScheme.onSurface,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bgColor,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: SoftPageTransitionsBuilder(),
          TargetPlatform.iOS: SoftPageTransitionsBuilder(),
        },
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceColor,
        indicatorColor: primaryColor.withOpacity(isDarkMode ? 0.28 : 0.16),
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final bool selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 11.5,
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            color: selected
                ? primaryColor
                : colorScheme.onSurface.withOpacity(0.72),
          );
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(88, AppDesignTokens.minTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDesignTokens.radiusLg),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            height: 1.35,
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusLg + 4),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(64, AppDesignTokens.minTouchTarget),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(88, AppDesignTokens.minTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDesignTokens.radiusLg),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: highContrast ? 0 : (isDarkMode ? 2 : 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusLg),
          side: BorderSide(
            color: highContrast
                ? colorScheme.onSurface.withOpacity(0.55)
                : (isDarkMode ? Colors.white12 : AppDesignTokens.lightBorder),
            width: highContrast ? 1.5 : 1.0,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
          borderSide: BorderSide(
            color: isDarkMode
                ? const Color(0xFF334155)
                : AppDesignTokens.lightBorder,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
          borderSide: BorderSide(
            color: isDarkMode
                ? const Color(0xFF334155)
                : AppDesignTokens.lightBorder,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
      ),
    );
  }
}

/// Smooth page transition: fade, small slide up and a gentle scale-in.
class SoftPageTransitionsBuilder extends PageTransitionsBuilder {
  const SoftPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final CurvedAnimation curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(curved),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.97, end: 1.0).animate(curved),
          child: child,
        ),
      ),
    );
  }
}
