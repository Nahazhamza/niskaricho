import 'package:material_ui/material_ui.dart';

import '../models/prayer_model.dart';

/// Forest Green, Sand / Beige & Electric Purple palette.
/// Calm, spiritual, organic luxury with high-voltage modern accents.
class AppColors {
  // Deep Forest Green foundation
  static const forestDeep = Color(0xFF051710);
  static const night = Color(0xFF082218);
  static const surface = Color(0xFF0F3124);
  static const surfaceHigh = Color(0xFF164433);
  static const forestGreen = Color(0xFF1E5B44);
  static const emerald = Color(0xFF2CB67D); // natural vibrant forest emerald

  // Warm Sand & Beige
  static const sand = Color(0xFFE2D4C3);
  static const sandLight = Color(0xFFF7F2EB);
  static const sandDark = Color(0xFFC7B39B);
  static const cream = Color(0xFFF6F0E6);
  static const gold = Color(0xFFE6B450); // warm desert sand-gold
  static const muted = Color(0xFFAFA597); // warm sand muted

  // Electric Purple accents
  static const electricPurple = Color(0xFF9D4EDD);
  static const purpleGlow = Color(0xFFC77DFF);
  static const violet = Color(0xFF9D4EDD);
  static const cyan = Color(0xFFB388FF); // electric lavender-purple

  // Status indicators
  static const onTime = Color(0xFF2ECC71);
  static const qada = Color(0xFFE5A93C);
  static const missed = Color(0xFFF05454);
  static const pending = Color(0xFF8E9AAF);

  static Color forStatus(PrayerStatus s) => switch (s) {
    PrayerStatus.onTime => onTime,
    PrayerStatus.qada => qada,
    PrayerStatus.missed => missed,
    PrayerStatus.inProgress => gold,
    PrayerStatus.pending => pending,
    PrayerStatus.upcoming => muted,
    PrayerStatus.excused || PrayerStatus.private => const Color(0xFFE9D5FF),
  };
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.forestGreen,
    brightness: Brightness.dark,
    primary: AppColors.sand,
    secondary: AppColors.forestGreen,
    tertiary: AppColors.electricPurple,
    surface: AppColors.surface,
  );
  return ThemeData(
    useMaterial3: true,
    fontFamilyFallback: const ['NotoSansMalayalam', 'NotoNaskhArabic', 'NotoColorEmoji'],
    colorScheme: scheme,
    // The animated CosmicBackground shows through every screen.
    scaffoldBackgroundColor: Colors.transparent,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      foregroundColor: AppColors.sandLight,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: AppColors.sandLight,
        fontWeight: FontWeight.w700,
        fontSize: 19,
        letterSpacing: 0.3,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.sand.withValues(alpha: 0.12)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.sand,
        foregroundColor: AppColors.forestDeep,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.sand,
        side: BorderSide(color: AppColors.sand.withValues(alpha: 0.4)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceHigh,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.sand.withValues(alpha: 0.15)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.sand.withValues(alpha: 0.15)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.electricPurple, width: 1.5),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.forestDeep.withValues(alpha: 0.94),
      indicatorColor: AppColors.electricPurple.withValues(alpha: 0.30),
      surfaceTintColor: Colors.transparent,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: AppColors.sandLight);
        }
        return const IconThemeData(color: AppColors.muted);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(color: AppColors.sandLight, fontWeight: FontWeight.bold, fontSize: 12);
        }
        return const TextStyle(color: AppColors.muted, fontSize: 11);
      }),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: FadeForwardsPageTransitionsBuilder(),
      },
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(color: AppColors.sandLight, fontWeight: FontWeight.w800, letterSpacing: -0.3, height: 1.3),
      headlineMedium: TextStyle(color: AppColors.sandLight, fontWeight: FontWeight.w700, height: 1.3),
      titleLarge: TextStyle(color: AppColors.sandLight, fontWeight: FontWeight.w700, height: 1.3),
      titleMedium: TextStyle(color: AppColors.sand, fontWeight: FontWeight.w600, height: 1.35),
      bodyLarge: TextStyle(color: AppColors.sandLight, height: 1.45),
      bodyMedium: TextStyle(color: AppColors.sand, height: 1.45),
      bodySmall: TextStyle(color: AppColors.muted, height: 1.4),
    ),
  );
}
