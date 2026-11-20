import 'package:flutter_test/flutter_test.dart';
import 'package:niskaricho/models/prayer_model.dart';
import 'package:niskaricho/services/prayer_calculator_service.dart';

/// The client (adhan_dart) and the server (compute_prayer_times in schema.sql)
/// must agree, otherwise the UI would unlock a prayer the server rejects.
/// Expected values below were produced by the SQL function.
void main() {
  final calc = PrayerCalculatorService(); // karachi + shafi, like the server default
  const kozhikode = UserLocation(latitude: 11.2588, longitude: 75.7804, timezone: 'Asia/Kolkata');

  test('client windows match server windows within 1 minute (Kozhikode, 20 Nov 2026)', () {
    final w = {for (final x in calc.windowsFor(kozhikode, DateTime(2026, 11, 20))) x.prayer: x};
    final server = <PrayerName, (DateTime, DateTime)>{
      PrayerName.fajr: (DateTime.utc(2026, 11, 19, 23, 41, 15), DateTime.utc(2026, 11, 20, 0, 55, 3)),
      PrayerName.dhuhr: (DateTime.utc(2026, 11, 20, 6, 43, 26), DateTime.utc(2026, 11, 20, 10, 1, 41)),
      PrayerName.asr: (DateTime.utc(2026, 11, 20, 10, 1, 41), DateTime.utc(2026, 11, 20, 12, 29, 42)),
      PrayerName.maghrib: (DateTime.utc(2026, 11, 20, 12, 29, 42), DateTime.utc(2026, 11, 20, 13, 43, 33)),
      PrayerName.isha: (DateTime.utc(2026, 11, 20, 13, 43, 33), DateTime.utc(2026, 11, 20, 23, 41, 35)),
    };
    for (final e in server.entries) {
      final c = w[e.key]!;
      expect(c.start.difference(e.value.$1).inSeconds.abs(), lessThan(60), reason: '${e.key} start ${c.start}');
      expect(c.end.difference(e.value.$2).inSeconds.abs(), lessThan(60), reason: '${e.key} end ${c.end}');
    }
  });

  test('windows are contiguous and ordered', () {
    final w = calc.windowsFor(kozhikode, DateTime(2026, 11, 20));
    for (var i = 0; i < w.length; i++) {
      expect(w[i].start.isBefore(w[i].end), isTrue);
    }
    expect(w[1].end, w[2].start); // Dhuhr ends when Asr begins
    expect(w[3].end, w[4].start); // Maghrib ends when Isha begins
  });

  test('cannot be open before it starts', () {
    final asr = calc.windowsFor(kozhikode, DateTime(2026, 11, 20))[2];
    expect(asr.isOpenAt(asr.start.subtract(const Duration(seconds: 1))), isFalse);
    expect(asr.isOpenAt(asr.start), isTrue);
    expect(asr.isOpenAt(asr.end), isFalse);
  });

  // Family members in other places: each one is checked against the server
  // (compute_prayer_times) with that member's own method. Dubai also matches
  // the official UAE timetable for 20 Nov 2026: 5:18 6:35 12:07 3:09 5:33 6:50.
  void expectAgrees(String name, PrayerCalculatorService c, UserLocation loc, List<DateTime> server) {
    final w = c.windowsFor(loc, DateTime(2026, 11, 20));
    final client = [w[0].start, w[0].end, w[1].start, w[2].start, w[3].start, w[4].start];
    for (var i = 0; i < server.length; i++) {
      expect(
        client[i].difference(server[i]).inSeconds.abs(),
        lessThan(60),
        reason: '$name #$i ${client[i]} vs ${server[i]}',
      );
    }
  }

  test('Dubai (UAE method) matches server and official timetable', () {
    expectAgrees(
      'Dubai',
      PrayerCalculatorService(method: 'dubai'),
      const UserLocation(latitude: 25.2048, longitude: 55.2708, timezone: 'Asia/Dubai'),
      [
        DateTime.utc(2026, 11, 20, 1, 18, 37),
        DateTime.utc(2026, 11, 20, 2, 36, 11),
        DateTime.utc(2026, 11, 20, 8, 7, 29),
        DateTime.utc(2026, 11, 20, 11, 8, 35),
        DateTime.utc(2026, 11, 20, 13, 32, 33),
        DateTime.utc(2026, 11, 20, 14, 50, 8),
      ],
    );
  });

  test('Kochi and Thiruvananthapuram match server', () {
    expectAgrees('Kochi', calc, const UserLocation(latitude: 9.9312, longitude: 76.2673, timezone: 'Asia/Kolkata'), [
      DateTime.utc(2026, 11, 19, 23, 37, 36),
      DateTime.utc(2026, 11, 20, 0, 51, 9),
      DateTime.utc(2026, 11, 20, 6, 41, 29),
      DateTime.utc(2026, 11, 20, 10, 0, 38),
      DateTime.utc(2026, 11, 20, 12, 29, 43),
      DateTime.utc(2026, 11, 20, 13, 43, 18),
    ]);
    expectAgrees('Tvm', calc, const UserLocation(latitude: 8.5241, longitude: 76.9366, timezone: 'Asia/Kolkata'), [
      DateTime.utc(2026, 11, 19, 23, 33, 6),
      DateTime.utc(2026, 11, 20, 0, 46, 26),
      DateTime.utc(2026, 11, 20, 6, 38, 48),
      DateTime.utc(2026, 11, 20, 9, 58, 48),
      DateTime.utc(2026, 11, 20, 12, 29, 6),
      DateTime.utc(2026, 11, 20, 13, 42, 28),
    ]);
  });

  // Region methods and the high-latitude rule, checked against the server.
  // (fajr, sunrise, dhuhr, asr, maghrib, isha) in UTC from compute_prayer_times.
  void world(String name, String method, double lat, double lng, DateTime day, List<List<int>> hms) {
    final c = PrayerCalculatorService(method: method);
    final w = c.windowsFor(UserLocation(latitude: lat, longitude: lng, timezone: 'UTC'), day);
    final client = [w[0].start, w[0].end, w[1].start, w[2].start, w[3].start, w[4].start];
    for (var i = 0; i < 6; i++) {
      final e = hms[i];
      final server = DateTime.utc(e[0], e[1], e[2], e[3], e[4], e[5]);
      expect(client[i].difference(server).inSeconds.abs(), lessThan(90), reason: '$name #$i ${client[i]} vs $server');
    }
  }

  test('Riyadh (Umm al-Qura), Doha (Qatar), Istanbul (Turkey) match server', () {
    world('Riyadh', 'umm_al_qura', 24.7136, 46.6753, DateTime(2026, 11, 20), [
      [2026, 11, 20, 1, 51, 7],
      [2026, 11, 20, 3, 12, 44],
      [2026, 11, 20, 8, 38, 52],
      [2026, 11, 20, 11, 43, 41],
      [2026, 11, 20, 14, 4, 46],
      [2026, 11, 20, 15, 34, 46],
    ]);
    world('Doha', 'qatar', 25.2854, 51.531, DateTime(2026, 11, 20), [
      [2026, 11, 20, 1, 34, 35],
      [2026, 11, 20, 2, 54, 17],
      [2026, 11, 20, 8, 19, 26],
      [2026, 11, 20, 11, 23, 26],
      [2026, 11, 20, 13, 44, 22],
      [2026, 11, 20, 15, 14, 22],
    ]);
    world('Istanbul', 'turkey', 41.0082, 28.9784, DateTime(2026, 11, 20), [
      [2026, 11, 20, 3, 21, 5],
      [2026, 11, 20, 4, 50, 9],
      [2026, 11, 20, 9, 54, 40],
      [2026, 11, 20, 12, 25, 47],
      [2026, 11, 20, 14, 48, 44],
      [2026, 11, 20, 16, 12, 26],
    ]);
  });

  test('New York (ISNA) and London in June (no true night) match server', () {
    world('New York', 'north_america', 40.7128, -74.006, DateTime(2026, 11, 20), [
      [2026, 11, 20, 10, 29, 11],
      [2026, 11, 20, 11, 48, 40],
      [2026, 11, 20, 16, 42, 40],
      [2026, 11, 20, 19, 14, 21],
      [2026, 11, 20, 21, 34, 14],
      [2026, 11, 20, 22, 53, 44],
    ]);
    world('London June', 'muslim_world_league', 51.5074, -0.1278, DateTime(2026, 6, 21), [
      [2026, 6, 21, 0, 2, 20],
      [2026, 6, 21, 3, 43, 7],
      [2026, 6, 21, 12, 3, 20],
      [2026, 6, 21, 16, 25, 9],
      [2026, 6, 21, 20, 21, 32],
      [2026, 6, 22, 0, 2, 20],
    ]);
  });

  test('mosque offsets move starts and the previous window end', () {
    final base = PrayerCalculatorService().windowsFor(kozhikode, DateTime(2026, 11, 20));
    final off = PrayerCalculatorService(offsets: [2, 0, 3, 0, 5]).windowsFor(kozhikode, DateTime(2026, 11, 20));
    expect(off[0].start.difference(base[0].start).inMinutes, 2);
    expect(off[1].end.difference(base[1].end).inMinutes, 3); // Dhuhr ends at shifted Asr
    expect(off[4].start.difference(base[4].start).inMinutes, 5);
    expect(off[0].end, base[0].end); // sunrise never moves
  });
}
