import 'package:flutter_test/flutter_test.dart';
import 'package:niskaricho/services/hijri.dart';

void main() {
  test('known dates', () {
    final eid = HijriDate.fromDate(DateTime(2026, 3, 20)); // Eid al-Fitr 1447
    expect([eid.year, eid.month, eid.day], [1447, 10, 1]);
    final r = HijriDate.fromDate(DateTime(2026, 2, 18)); // 1 Ramadan 1447
    expect([r.year, r.month, r.day], [1447, 9, 1]);
    expect(HijriDate.fromDate(DateTime(2026, 2, 18), adjust: -1).month, 8); // a day later locally
  });
}
