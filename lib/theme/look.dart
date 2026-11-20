import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The two designs you can switch between in Journey → Appearance.
enum AppStyle {
  /// Animated night sky with frosted glass cards (the original look).
  nightSky('Night sky', 'Animated stars and glass cards'),

  /// Calm masjid style: Islamic geometric pattern, solid panels with a gold
  /// hairline, no blur and no moving background.
  masjid('Masjid', 'Geometric pattern, calm and still');

  const AppStyle(this.label, this.blurb);
  final String label;
  final String blurb;
}

/// App-wide look settings, saved on the device.
class Look {
  static final style = ValueNotifier<AppStyle>(AppStyle.nightSky);

  /// Lite mode for older phones: no blur, no looping animations, fewer glows.
  static final lite = ValueNotifier<bool>(false);

  /// Hijri date adjustment for your community's moon sighting (-2..+2 days).
  static final hijriAdjust = ValueNotifier<int>(0);

  static Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      style.value = AppStyle.values.asNameMap()[p.getString('look.style')] ?? AppStyle.nightSky;
      lite.value = p.getBool('look.lite') ?? false;
      hijriAdjust.value = p.getInt('look.hijriAdjust') ?? 0;
    } catch (_) {}
  }

  static Future<void> save() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString('look.style', style.value.name);
      await p.setBool('look.lite', lite.value);
      await p.setInt('look.hijriAdjust', hijriAdjust.value);
    } catch (_) {}
  }
}

/// Makes the current look available to widgets, so only those that use it
/// rebuild when it changes (switching design never resets the app).
class LookScope extends InheritedWidget {
  const LookScope({super.key, required this.style, required this.lite, required super.child});
  final AppStyle style;

  /// Lite mode is on, or the phone asks for reduced motion.
  final bool lite;

  static LookScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LookScope>() ??
      const LookScope(style: AppStyle.nightSky, lite: false, child: SizedBox());

  bool get still => lite || style == AppStyle.masjid;

  @override
  bool updateShouldNotify(LookScope old) => old.style != style || old.lite != lite;
}
