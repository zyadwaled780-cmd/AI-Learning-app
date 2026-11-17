import 'package:material_ui/material_ui.dart';

import 'app_tokens.dart';

abstract final class AppTheme {
  static ThemeData light() {
    final colorScheme = const ColorScheme.light(
      primary: AppTokens.lightPrimary,
      onPrimary: AppTokens.lightOnPrimary,
      primaryContainer: AppTokens.lightPrimaryContainer,
      onPrimaryContainer: Color(0xFF042F2E),
      secondary: AppTokens.lightSecondary,
      onSecondary: Colors.white,
      secondaryContainer: AppTokens.lightSecondaryContainer,
      onSecondaryContainer: Color(0xFF1E1B4B),
      surface: AppTokens.lightSurface,
      onSurface: AppTokens.lightInk,
      surfaceContainerHighest: AppTokens.lightSurfaceMuted,
      onSurfaceVariant: AppTokens.lightInkMuted,
      outline: AppTokens.lightBorder,
      outlineVariant: AppTokens.lightBorder,
      error: AppTokens.lightDanger,
      onError: Colors.white,
    );

    return _buildTheme(
      colorScheme: colorScheme,
      scaffoldBackground: AppTokens.lightBackground,
      cardBackground: AppTokens.lightSurface,
      borderColor: AppTokens.lightBorder,
      inkColor: AppTokens.lightInk,
      mutedInkColor: AppTokens.lightInkMuted,
    );
  }

  static ThemeData dark() {
    final colorScheme = const ColorScheme.dark(
      primary: AppTokens.darkPrimary,
      onPrimary: AppTokens.darkOnPrimary,
      primaryContainer: AppTokens.darkPrimaryContainer,
      onPrimaryContainer: Color(0xFFCCFBF1),
      secondary: AppTokens.darkSecondary,
      onSecondary: Color(0xFF0F172A),
      secondaryContainer: AppTokens.darkSecondaryContainer,
      onSecondaryContainer: Color(0xFFDBEAFE),
      surface: AppTokens.darkSurface,
      onSurface: AppTokens.darkInk,
      surfaceContainerHighest: AppTokens.darkSurfaceMuted,
      onSurfaceVariant: AppTokens.darkInkMuted,
      outline: AppTokens.darkBorder,
      outlineVariant: AppTokens.darkBorder,
      error: AppTokens.darkDanger,
      onError: Color(0xFF450A0A),
    );

    return _buildTheme(
      colorScheme: colorScheme,
      scaffoldBackground: AppTokens.darkBackground,
      cardBackground: AppTokens.darkSurface,
      borderColor: AppTokens.darkBorder,
      inkColor: AppTokens.darkInk,
      mutedInkColor: AppTokens.darkInkMuted,
    );
  }

  static ThemeData _buildTheme({
    required ColorScheme colorScheme,
    required Color scaffoldBackground,
    required Color cardBackground,
    required Color borderColor,
    required Color inkColor,
    required Color mutedInkColor,
  }) {
    final baseText = Typography.englishLike2021.apply(
      bodyColor: inkColor,
      displayColor: inkColor,
    );

    final textTheme = baseText.copyWith(
      headlineMedium: baseText.headlineMedium?.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        height: 1.22,
      ),
      headlineSmall: baseText.headlineSmall?.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        height: 1.28,
      ),
      titleLarge: baseText.titleLarge?.copyWith(
        fontSize: 19,
        fontWeight: FontWeight.w600,
        height: 1.32,
      ),
      titleMedium: baseText.titleMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.35,
      ),
      titleSmall: baseText.titleSmall?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.35,
      ),
      bodyLarge: baseText.bodyLarge?.copyWith(
        fontSize: 16,
        height: 1.58,
        color: inkColor,
      ),
      bodyMedium: baseText.bodyMedium?.copyWith(
        fontSize: 14.5,
        height: 1.52,
        color: inkColor,
      ),
      bodySmall: baseText.bodySmall?.copyWith(
        fontSize: 13,
        height: 1.45,
        color: mutedInkColor,
      ),
      labelLarge: baseText.labelLarge?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      labelMedium: baseText.labelMedium?.copyWith(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBackground,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: cardBackground,
        foregroundColor: inkColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: Border(bottom: BorderSide(color: borderColor, width: 1)),
      ),
      cardTheme: CardThemeData(
        color: cardBackground,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          side: BorderSide(color: borderColor, width: 1),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusSm),
        ),
        side: BorderSide(color: borderColor),
        labelStyle: textTheme.labelMedium,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusSm),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusSm),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusSm),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.8),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: borderColor,
        thickness: 1,
        space: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cardBackground,
        indicatorColor: colorScheme.primaryContainer,
        labelTextStyle: WidgetStateProperty.all(textTheme.labelMedium),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: cardBackground,
        indicatorColor: colorScheme.primaryContainer,
        selectedIconTheme: IconThemeData(color: colorScheme.primary),
        selectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: mutedInkColor,
        ),
      ),
    );
  }
}
