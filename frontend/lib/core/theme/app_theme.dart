import 'package:flutter/material.dart';

/// Theme tokens. Source of truth for colors / spacing / shape is
/// `docs/design-system.md`. Change them there first, then mirror here.
class AppTheme {
  AppTheme._();

  // Brand seed — bright coral-orange. Sampled from docs/design mockups.
  static const Color brandSeed = Color(0xFFFF6F3C);
  // Warm-tinted surfaces override M3's seeded (cool) defaults.
  static const Color _lightSurface = Color(0xFFFFFAF6);
  static const Color _darkSurface = Color(0xFF1A1410);

  // --- Design tokens sampled from materials/screen/Auth mockups ---
  // Neutral warm fill behind inputs (NOT coral-tinted — the mockups use this
  // flat cream, not Primary Container). The faint hairline around them.
  static const Color authInputFill = Color(0xFFF7F3EF);
  static const Color authInputBorder = Color(0xFFE8E0D8);
  // Cards (role options, Google button) sit on the surface as pure white.
  static const Color cardSurface = Color(0xFFFFFFFF);
  // Very light coral wash behind icons / the key glyph / a selected role card.
  static const Color softCoralTint = Color(0xFFFFF0EB);
  // Muted warm gray — input prefix icons and placeholder text in the mockups.
  static const Color authHint = Color(0xFF9B8E82);
  static const Color _lightOnSurface = Color(0xFF1A1410);
  static const Color _lightOnSurfaceVariant = Color(0xFF6B5E52);
  // Soft blue informational banner (e.g. the "Average rate …" note in the
  // tutor onboarding hourly-rate mockup). Not coral — coral is the CTA only.
  static const Color infoBannerBg = Color(0xFFEAF2FE);
  static const Color infoBannerFg = Color(0xFF2563C9);
  // Success green for completed/confirmed states (e.g. an uploaded credential).
  static const Color success = Color(0xFF2E9E5B);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: brandSeed,
      brightness: Brightness.light,
    ).copyWith(
      // M3's tonal palette muddies the seed to a brown (#8F4C35) for `primary`.
      // The mockups use the seed coral itself for every accent, so pin it.
      primary: brandSeed,
      onPrimary: const Color(0xFFFFFFFF),
      primaryContainer: softCoralTint,
      onPrimaryContainer: brandSeed,
      surface: _lightSurface,
      onSurface: _lightOnSurface,
      onSurfaceVariant: _lightOnSurfaceVariant,
      outlineVariant: authInputBorder,
      // Inputs read their fill from surfaceContainerHigh; pin it to the flat
      // cream the mockups use instead of M3's coral-seeded default.
      surfaceContainerHigh: authInputFill,
    );
    return _base(scheme);
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: brandSeed,
      brightness: Brightness.dark,
    ).copyWith(surface: _darkSurface);
    return _base(scheme);
  }

  static ThemeData _base(ColorScheme scheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          // Mockups: white pill, dark label, faint hairline border (the
          // "Continue with Google" / "I Already Have an Account" buttons).
          backgroundColor: scheme.surface,
          foregroundColor: scheme.onSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          side: BorderSide(color: scheme.outlineVariant, width: 1.5),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: scheme.primary,
          selectedForegroundColor: scheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHigh,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
        labelStyle: TextStyle(color: scheme.onSurfaceVariant),
        hintStyle: const TextStyle(color: authHint),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
