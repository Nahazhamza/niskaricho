import '../l10n/tr.dart';

import 'package:intl/intl.dart' show DateFormat;
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Time-zone helpers so every member's times are shown in *their* local time
/// (a Dubai member's Asr in Dubai time, a Kochi member's in IST), whatever
/// zone this phone or browser is in.
class Zones {
  static bool _ready = false;
  static void _init() {
    if (_ready) return;
    tzdata.initializeTimeZones();
    _ready = true;
  }

  /// Wall-clock time in [zone] for an instant. Falls back to device time.
  static DateTime wall(DateTime instant, String? zone) {
    if (zone == null || zone.isEmpty) return instant.toLocal();
    _init();
    try {
      final t = tz.TZDateTime.from(instant.toUtc(), tz.getLocation(zone));
      return DateTime(t.year, t.month, t.day, t.hour, t.minute, t.second);
    } catch (_) {
      return instant.toLocal();
    }
  }

  /// Local calendar date in [zone] right now.
  static DateTime today(String? zone, [DateTime? now]) {
    final w = wall(now ?? DateTime.now().toUtc(), zone);
    return DateTime(w.year, w.month, w.day);
  }

  /// "UTC+4", "UTC+5:30".
  static String offsetLabel(String? zone, [DateTime? at]) {
    final instant = (at ?? DateTime.now()).toUtc();
    final w = wall(instant, zone);
    final mins = DateTime.utc(
      w.year,
      w.month,
      w.day,
      w.hour,
      w.minute,
    ).difference(DateTime.utc(instant.year, instant.month, instant.day, instant.hour, instant.minute)).inMinutes;
    final sign = mins < 0 ? '-' : '+';
    final h = mins.abs() ~/ 60, m = mins.abs() % 60;
    return 'UTC$sign$h${m == 0 ? '' : ':${m.toString().padLeft(2, '0')}'}';
  }

  /// "3:31 PM" in [zone], rounded to the nearest minute like printed
  /// timetables (15:08:35 shows as 3:09 PM).
  static String hm(DateTime instant, String? zone) =>
      DateFormat.jm().format(wall(instant.add(const Duration(seconds: 30)), zone));
}

/// Human names for the server's `calc_method` values.
/// Method names in the app's language.
Map<String, String> get calcMethodLabels => {for (final e in calcMethodNames.entries) e.key: tr(e.value)};

/// English names (keys for tr).
const calcMethodNames = <String, String>{
  'karachi': 'Karachi (India, Kerala, Pakistan)',
  'dubai': 'UAE (Dubai, Awqaf)',
  'umm_al_qura': 'Umm al-Qura (Saudi Arabia)',
  'qatar': 'Qatar / Bahrain',
  'kuwait': 'Kuwait',
  'muslim_world_league': 'Muslim World League (UK, Europe)',
  'north_america': 'North America (ISNA)',
  'singapore': 'Singapore / Malaysia (JAKIM)',
  'indonesian': 'Indonesia (Kemenag)',
  'turkey': 'Turkey (Diyanet)',
  'egyptian': 'Egyptian',
  'morocco': 'Morocco',
  'jordan': 'Jordan',
};

/// The usual method where the phone is, from its time zone (works offline).
/// Mirrors `_method_for_timezone` in schema.sql; keep the two in sync.
String methodForTimezone(String? tz) {
  final z = tz ?? '';
  const karachi = {
    'Asia/Kolkata', 'Asia/Calcutta', 'Asia/Karachi', 'Asia/Dhaka', 'Asia/Kathmandu', //
    'Asia/Colombo', 'Asia/Kabul', 'Indian/Maldives',
  };
  if (karachi.contains(z)) return 'karachi';
  if (z == 'Asia/Dubai' || z == 'Asia/Muscat') return 'dubai';
  if (z == 'Asia/Riyadh' || z == 'Asia/Aden') return 'umm_al_qura';
  if (z == 'Asia/Qatar' || z == 'Asia/Bahrain') return 'qatar';
  if (z == 'Asia/Kuwait') return 'kuwait';
  if (const {'Asia/Singapore', 'Asia/Kuala_Lumpur', 'Asia/Kuching', 'Asia/Brunei'}.contains(z)) return 'singapore';
  if (const {'Asia/Jakarta', 'Asia/Pontianak', 'Asia/Makassar', 'Asia/Jayapura'}.contains(z)) return 'indonesian';
  if (z == 'Europe/Istanbul') return 'turkey';
  if (z == 'Africa/Casablanca' || z == 'Africa/El_Aaiun') return 'morocco';
  if (z == 'Asia/Amman') return 'jordan';
  if (const {'Africa/Cairo', 'Africa/Khartoum', 'Asia/Damascus', 'Asia/Beirut'}.contains(z)) return 'egyptian';
  if (z.startsWith('America/') || z.startsWith('US/') || z.startsWith('Canada/')) return 'north_america';
  return 'muslim_world_league';
}

/// True when the phone's time-zone setting is far from what its GPS
/// longitude suggests (e.g. a phone set to IST while in London). Prayer
/// times still come from GPS + the server clock; this only affects dates
/// and how times are displayed, so the app shows a gentle warning.
bool timezoneLooksWrong(String? tz, double longitude, [DateTime? at]) {
  final label = Zones.offsetLabel(tz, at); // UTC+5:30
  final m = RegExp(r'UTC([+-])(\d+)(?::(\d+))?').firstMatch(label);
  if (m == null) return false;
  final hours = (m.group(1) == '-' ? -1 : 1) * (int.parse(m.group(2)!) + int.parse(m.group(3) ?? '0') / 60);
  return (hours - longitude / 15).abs() > 3.5;
}
