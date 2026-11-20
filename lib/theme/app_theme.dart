import 'package:material_ui/material_ui.dart';

import '../models/prayer_model.dart';

/// Night-mosque palette: deep emerald, warm gold, soft cream.
class AppColors {
  static const night = Color(0xFF0B1F1A);
  static const surface = Color(0xFF12302A);
  static const surfaceHigh = Color(0xFF1A3F37);
  static const emerald = Color(0xFF14B8A6);
  static const gold = Color(0xFFD4A84B);
  static const cream = Color(0xFFF5EFE0);
  static const muted = Color(0xFF9DB5AE);
  static const cyan = Color(0xFF22D3EE);
  static const violet = Color(0xFF8B5CF6);

  static const onTime = Color(0xFF22C55E);
  static const qada = Color(0xFFEAB308);
  static const missed = Color(0xFFEF4444);
  static const pending = Color(0xFF60A5FA);

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
    seedColor: AppColors.emerald,
    brightness: Brightness.dark,
    primary: AppColors.gold,
    secondary: AppColors.emerald,
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
      foregroundColor: AppColors.cream,
      elevation: 0,
      centerTitle: true,
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.night,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceHigh,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xFF07161A).withValues(alpha: 0.85),
      indicatorColor: AppColors.gold.withValues(alpha: 0.18),
      surfaceTintColor: Colors.transparent,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: FadeForwardsPageTransitionsBuilder(),
      },
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(color: AppColors.cream, fontWeight: FontWeight.w800),
      headlineMedium: TextStyle(color: AppColors.cream, fontWeight: FontWeight.w700),
      titleLarge: TextStyle(color: AppColors.cream, fontWeight: FontWeight.w700),
      titleMedium: TextStyle(color: AppColors.cream, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(color: AppColors.cream),
      bodyMedium: TextStyle(color: AppColors.cream),
      bodySmall: TextStyle(color: AppColors.muted),
    ),
  );
}
