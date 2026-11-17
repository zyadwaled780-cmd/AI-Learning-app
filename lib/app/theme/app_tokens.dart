import 'package:material_ui/material_ui.dart';

/// Design tokens for spacing, breakpoints, surface colors, and motion.
abstract final class AppTokens {
  static const double maxReadingWidth = 840;
  static const double maxContentWidth = 1180;
  static const double desktopBreakpoint = 840;

  static const double spaceXs = 4;
  static const double spaceSm = 8;
  static const double spaceMd = 16;
  static const double spaceLg = 24;
  static const double spaceXl = 32;

  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;

  // Light palette — crisp slate & navy with calm teal accent.
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceMuted = Color(0xFFF1F5F9);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightInk = Color(0xFF0F172A);
  static const Color lightInkMuted = Color(0xFF475569);
  static const Color lightPrimary = Color(0xFF0F766E);
  static const Color lightOnPrimary = Color(0xFFFFFFFF);
  static const Color lightPrimaryContainer = Color(0xFFCCFBF1);
  static const Color lightSecondary = Color(0xFF4338CA);
  static const Color lightSecondaryContainer = Color(0xFFE0E7FF);

  // Dark palette — calm navy/slate surfaces with legible teal & restrained indigo.
  static const Color darkBackground = Color(0xFF0B1120);
  static const Color darkSurface = Color(0xFF131C31);
  static const Color darkSurfaceMuted = Color(0xFF1E293B);
  static const Color darkBorder = Color(0xFF334155);
  static const Color darkInk = Color(0xFFF1F5F9);
  static const Color darkInkMuted = Color(0xFF94A3B8);
  static const Color darkPrimary = Color(0xFF2DD4BF);
  static const Color darkOnPrimary = Color(0xFF042F2E);
  static const Color darkPrimaryContainer = Color(0xFF134E4A);
  static const Color darkSecondary = Color(0xFF93C5FD);
  static const Color darkSecondaryContainer = Color(0xFF1E3A5F);

  // Semantic colors.
  static const Color lightSuccess = Color(0xFF15803D);
  static const Color darkSuccess = Color(0xFF4ADE80);
  static const Color lightWarning = Color(0xFFB45309);
  static const Color darkWarning = Color(0xFFFBBF24);
  static const Color lightDanger = Color(0xFFB91C1C);
  static const Color darkDanger = Color(0xFFF87171);

  // Code block surfaces (always dark slate for consistent syntax legibility).
  static const Color codeSurface = Color(0xFF0F172A);
  static const Color codeHeaderSurface = Color(0xFF1E293B);
  static const Color codeText = Color(0xFFE2E8F0);
}

/// Motion helper that honors user reduced-motion preferences.
abstract final class AppMotion {
  static Duration duration(
    BuildContext context, [
    Duration normal = const Duration(milliseconds: 220),
  ]) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return Duration.zero;
    }
    return normal;
  }

  static Curve curve(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return Curves.linear;
    }
    return Curves.easeOutCubic;
  }
}
