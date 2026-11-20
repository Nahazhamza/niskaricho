import 'package:adhan_dart/adhan_dart.dart' as adhan;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:geolocator/geolocator.dart';

import '../models/prayer_model.dart';

/// Where the user prays from. Sent to the server once (rate-limited there),
/// so both sides compute the same windows.
class UserLocation {
  const UserLocation({required this.latitude, required this.longitude, required this.timezone});
  final double latitude;
  final double longitude;
  final String timezone; // IANA, e.g. Asia/Kolkata
}

/// Offline, GPS-based prayer time engine built on `adhan_dart`.
///
/// Used for: scheduling Adhan / expiry notifications, and showing times when
/// the device is offline. The *authoritative* windows for logging come from
/// the server (`SupabaseService.fetchMyWindows`); both use the same
/// astronomy and parameters, so they agree to within about a minute.
class PrayerCalculatorService {
  PrayerCalculatorService({this.method = 'karachi', this.madhab = 'shafi', this.offsets = const [0, 0, 0, 0, 0]});

  /// Mosque offsets in minutes for Fajr, Dhuhr, Asr, Maghrib, Isha (-10..10).
  /// Each moves that prayer's start and the previous window's end, exactly
  /// like `prayer_windows_for` on the server.
  List<int> offsets;

  /// Server enum `calc_method`; Karachi (18°/18°) is common in Kerala / India.
  String method;

  /// Server enum `asr_madhab`; Shafi'i is the majority in Kerala.
  String madhab;

  adhan.CalculationParameters get _params {
    final p = switch (method) {
      'muslim_world_league' => adhan.CalculationMethodParameters.muslimWorldLeague(),
      'egyptian' => adhan.CalculationMethodParameters.egyptian(),
      'north_america' => adhan.CalculationMethodParameters.northAmerica(),
      'kuwait' => adhan.CalculationMethodParameters.kuwait(),
      'umm_al_qura' => adhan.CalculationMethodParameters.ummAlQura(),
      'qatar' => adhan.CalculationMethodParameters.qatar(),
      'singapore' => adhan.CalculationMethodParameters.singapore(),
      'indonesian' => adhan.CalculationMethodParameters.indonesian(),
      'turkey' => adhan.CalculationMethodParameters.turkiye(),
      'morocco' => adhan.CalculationMethodParameters.morocco(),
      'jordan' => adhan.CalculationMethodParameters.jordan(),
      // UAE (Dubai/Awqaf). The official UAE timetable has no +3 on Asr, so
      // drop that one preset offset (server does the same).
      'dubai' => adhan.CalculationMethodParameters.dubai()..methodAdjustments[adhan.Prayer.asr] = 0,
      _ => adhan.CalculationMethodParameters.karachi(),
    };
    p.madhab = madhab == 'hanafi' ? adhan.Madhab.hanafi : adhan.Madhab.shafi;
    return p;
  }

  /// Reads GPS + device timezone. Asks for permission if needed.
  Future<UserLocation> currentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw StateError('Location services are turned off.');
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
      throw StateError('Location permission is needed to calculate prayer times.');
    }
    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
    );
    final tz = await FlutterTimezone.getLocalTimezone();
    return UserLocation(latitude: pos.latitude, longitude: pos.longitude, timezone: tz.identifier);
  }

  /// Windows for one local calendar day, same rules as the server:
  /// Fajr→Sunrise, Dhuhr→Asr, Asr→Maghrib, Maghrib→Isha, Isha→next Fajr.
  List<PrayerWindow> windowsFor(UserLocation loc, DateTime localDay) {
    final coords = adhan.Coordinates(loc.latitude, loc.longitude);
    final day = DateTime(localDay.year, localDay.month, localDay.day);
    final t = adhan.PrayerTimes(coordinates: coords, date: day, calculationParameters: _params, precision: true);
    // Note: adhan presets already add +1 min to Dhuhr; the server does the same.
    DateTime o(DateTime x, int i) => x.toUtc().add(Duration(minutes: offsets.length == 5 ? offsets[i] : 0));
    final fajr = o(t.fajr, 0), dhuhr = o(t.dhuhr, 1), asr = o(t.asr, 2), maghrib = o(t.maghrib, 3), isha = o(t.isha, 4);
    return [
      PrayerWindow(prayer: PrayerName.fajr, start: fajr, end: t.sunrise.toUtc()),
      PrayerWindow(prayer: PrayerName.dhuhr, start: dhuhr, end: asr),
      PrayerWindow(prayer: PrayerName.asr, start: asr, end: maghrib),
      PrayerWindow(prayer: PrayerName.maghrib, start: maghrib, end: isha),
      PrayerWindow(prayer: PrayerName.isha, start: isha, end: o(t.fajrAfter, 0)),
    ];
  }

  /// The window that is open at [now] (Isha after midnight belongs to yesterday).
  PrayerWindow? currentWindow(List<PrayerWindow> today, List<PrayerWindow> yesterday, DateTime now) {
    for (final w in [...yesterday.where((w) => w.prayer == PrayerName.isha), ...today]) {
      if (w.isOpenAt(now)) return w;
    }
    return null;
  }

  /// The next window to open after [now].
  PrayerWindow? nextWindow(List<PrayerWindow> today, List<PrayerWindow> tomorrow, DateTime now) {
    for (final w in [...today, ...tomorrow]) {
      if (w.start.isAfter(now)) return w;
    }
    return null;
  }
}
