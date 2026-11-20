import 'package:flutter_test/flutter_test.dart';
import 'package:niskaricho/models/prayer_model.dart';

void main() {
  final day = DateTime.utc(2026, 11, 20);
  PrayerWindow w(int h1, int h2) => PrayerWindow(
    prayer: PrayerName.dhuhr,
    start: day.add(Duration(hours: h1)),
    end: day.add(Duration(hours: h2)),
  );
  final now = day.add(const Duration(days: 30));

  test('a window inside the period is excused, one it began after is owed', () {
    final p = ExcusedPeriod(id: 'a', kind: 'haid', startedAt: day.add(const Duration(hours: 9)));
    expect(p.covers(w(10, 12), 'shafi', day.add(const Duration(hours: 13))), isTrue);
    expect(p.covers(w(8, 10), 'shafi', day.add(const Duration(hours: 13))), isFalse); // time to pray existed
  });

  test('haid caps at 15 days (Hanafi 10), nifas at 60 (Hanafi 40)', () {
    expect(ExcusedPeriod.maxFor('haid', 'shafi').inDays, 15);
    expect(ExcusedPeriod.maxFor('haid', 'hanafi').inDays, 10);
    expect(ExcusedPeriod.maxFor('nifas', 'shafi').inDays, 60);
    expect(ExcusedPeriod.maxFor('nifas', 'hanafi').inDays, 40);
    final p = ExcusedPeriod(id: 'a', kind: 'haid', startedAt: day);
    expect(p.covers(w(24 * 12, 24 * 12 + 2), 'shafi', now), isTrue);
    expect(p.covers(w(24 * 12, 24 * 12 + 2), 'hanafi', now), isFalse); // istihada after 10 days
  });

  test('ending the period ends the excuse', () {
    final p = ExcusedPeriod(
      id: 'a',
      kind: 'haid',
      startedAt: day,
      endedAt: day.add(const Duration(days: 5, hours: 11)),
    );
    expect(p.covers(w(24 * 5 + 6, 24 * 5 + 8), 'shafi', now), isTrue);
    expect(p.covers(w(24 * 5 + 10, 24 * 5 + 12), 'shafi', now), isFalse);
  });
}
