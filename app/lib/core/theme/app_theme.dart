import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Defaults to following the OS/browser's own light/dark setting; the user
/// can override it explicitly via [AppTheme.nextThemeMode].
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

class AppTheme {
  AppTheme._();

  static IconData iconFor(ThemeMode mode) => switch (mode) {
        ThemeMode.system => Icons.brightness_auto_outlined,
        ThemeMode.light => Icons.light_mode_outlined,
        ThemeMode.dark => Icons.dark_mode_outlined,
      };

  static String labelFor(ThemeMode mode) => switch (mode) {
        ThemeMode.system => 'Auto',
        ThemeMode.light => 'Day',
        ThemeMode.dark => 'Night',
      };

  static ThemeMode nextThemeMode(ThemeMode mode) => switch (mode) {
        ThemeMode.system => ThemeMode.light,
        ThemeMode.light => ThemeMode.dark,
        ThemeMode.dark => ThemeMode.system,
      };

  static const seedColor = Color(0xFF228B22);
  static const gradientEndColor = Color(0xFF0F5C3A);
  static const lightScaffoldBackground = Color(0xFFF5FAF6);

  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [seedColor, gradientEndColor],
  );

  /// Deep navy/violet, used as the Dashboard's page background in dark mode
  /// only -- light mode keeps [lightScaffoldBackground] untouched.
  static const darkScaffoldBackground = Color(0xFF0B0F1D);
  static const darkPageGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0B0F1D), Color(0xFF121A2E), Color(0xFF17122B)],
  );
  static const darkCardColor = Color(0xFF141B2E);

  /// A soft colored glow behind a card, dark mode only -- approximates the
  /// reference dashboard's neon-accent look without needing real
  /// glassmorphism/blur support.
  static List<BoxShadow> glow(Color color) => [
        BoxShadow(color: color.withValues(alpha: 0.28), blurRadius: 24, spreadRadius: -6),
      ];

  /// One (background tint, accent) pair per dashboard category, cycled by
  /// index. Backgrounds are pastel-light so they read well in both themes'
  /// card surfaces; accents are the saturated version used for icons/text.
  static const categoryPalette = <(Color bg, Color accent)>[
    (Color(0xFFE8EEFF), Color(0xFF3B5BDB)), // Classes - blue
    (Color(0xFFE3F6EC), Color(0xFF12805C)), // Students - teal
    (Color(0xFFEAF7E9), Color(0xFF2F9E44)), // Attendance - green
    (Color(0xFFEEE9FB), Color(0xFF6741D9)), // Scan QR - indigo/violet
    (Color(0xFFF9E9F7), Color(0xFFAE3EC9)), // Register QR Card - purple
    (Color(0xFFFFF4DE), Color(0xFFE8A400)), // Merit - amber
    (Color(0xFFE7F1FF), Color(0xFF1971C2)), // Class Summary - blue
    (Color(0xFFFDE9F1), Color(0xFFD6336C)), // Rewards - pink
    (Color(0xFFE6FBFA), Color(0xFF0C8599)), // Reports - cyan
    (Color(0xFFEEF1F4), Color(0xFF495057)), // Settings - blueGrey
    (Color(0xFFFDF0E7), Color(0xFFD9730D)), // Manual Attendance - orange
    (Color(0xFFE9F3FF), Color(0xFF1864AB)), // Dashboard - deep blue
  ];

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(seedColor: seedColor);
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: lightScaffoldBackground,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: colorScheme.onSurface,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      chipTheme: ChipThemeData(shape: const StadiumBorder(), side: BorderSide.none),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
    );
  }

  static ThemeData dark() {
    final colorScheme = ColorScheme.fromSeed(seedColor: seedColor, brightness: Brightness.dark);
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: darkScaffoldBackground,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: colorScheme.onSurface,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: darkCardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
        ),
      ),
      chipTheme: ChipThemeData(shape: const StadiumBorder(), side: BorderSide.none),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
    );
  }
}
