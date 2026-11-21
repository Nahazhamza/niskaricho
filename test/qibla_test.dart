import 'package:flutter_test/flutter_test.dart';
import 'package:niskaricho/services/qibla_service.dart';

void main() {
  group('QiblaService', () {
    test('Kozhikode Qibla bearing and distance', () {
      // Kozhikode: 11.2588° N, 75.7804° E
      final bearing = QiblaService.calculateBearing(11.2588, 75.7804);
      expect(bearing, closeTo(291.12, 0.1));

      final dist = QiblaService.calculateDistanceKm(11.2588, 75.7804);
      expect(dist, greaterThan(3800));
      expect(dist, lessThan(4200));

      expect(QiblaService.cardinalDirection(bearing), equals('WNW'));
    });

    test('Dubai Qibla bearing and distance', () {
      // Dubai: 25.2048° N, 55.2708° E
      final bearing = QiblaService.calculateBearing(25.2048, 55.2708);
      expect(bearing, closeTo(258.23, 0.1));

      final dist = QiblaService.calculateDistanceKm(25.2048, 55.2708);
      expect(dist, greaterThan(1500));
      expect(dist, lessThan(1900));

      expect(QiblaService.cardinalDirection(bearing), equals('WSW'));
    });

    test('Cardinal directions', () {
      expect(QiblaService.cardinalDirection(0), equals('N'));
      expect(QiblaService.cardinalDirection(360), equals('N'));
      expect(QiblaService.cardinalDirection(90), equals('E'));
      expect(QiblaService.cardinalDirection(180), equals('S'));
      expect(QiblaService.cardinalDirection(270), equals('W'));
      expect(QiblaService.cardinalDirection(45), equals('NE'));
      expect(QiblaService.cardinalDirection(225), equals('SW'));
    });

    test('Turn offset and alignment detection', () {
      const qibla = 292.0;

      // Facing directly at Qibla
      expect(QiblaService.isFacingQibla(292.0, qibla), isTrue);
      expect(QiblaService.turnOffset(292.0, qibla), closeTo(0.0, 0.001));

      // Within 3 degrees
      expect(QiblaService.isFacingQibla(294.0, qibla), isTrue);
      expect(QiblaService.turnOffset(294.0, qibla), closeTo(-2.0, 0.001)); // turn left 2°

      expect(QiblaService.isFacingQibla(290.0, qibla), isTrue);
      expect(QiblaService.turnOffset(290.0, qibla), closeTo(2.0, 0.001)); // turn right 2°

      // Outside tolerance
      expect(QiblaService.isFacingQibla(280.0, qibla), isFalse);
      expect(QiblaService.turnOffset(280.0, qibla), closeTo(12.0, 0.001));

      // Wrapping across 0°/360° North boundary
      const northQibla = 5.0;
      expect(QiblaService.turnOffset(358.0, northQibla), closeTo(7.0, 0.001)); // turn right 7°
      expect(QiblaService.isFacingQibla(359.0, northQibla, toleranceDegrees: 7.0), isTrue);
    });
  });
}
