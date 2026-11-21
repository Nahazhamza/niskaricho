import 'dart:math' as math;
import 'package:adhan_dart/adhan_dart.dart' as adhan;

/// Geometry, distances, and alignment calculations for Qibla direction towards the Kaaba.
class QiblaService {
  QiblaService._();

  /// Coordinates of the Holy Kaaba in Makkah (Mecca), Saudi Arabia.
  static const double kaabaLat = 21.422487;
  static const double kaabaLng = 39.826206;

  /// Returns the bearing (0..360° clockwise from True North) from [lat], [lng] to the Kaaba.
  static double calculateBearing(double lat, double lng) {
    final bearing = adhan.Qibla.qibla(adhan.Coordinates(lat, lng));
    return (bearing % 360.0 + 360.0) % 360.0;
  }

  /// Great circle distance in kilometers between [lat], [lng] and the Kaaba using Haversine.
  static double calculateDistanceKm(double lat, double lng) {
    const earthRadiusKm = 6371.0;
    final phi1 = lat * math.pi / 180.0;
    final phi2 = kaabaLat * math.pi / 180.0;
    final deltaPhi = (kaabaLat - lat) * math.pi / 180.0;
    final deltaLambda = (kaabaLng - lng) * math.pi / 180.0;

    final a = math.sin(deltaPhi / 2.0) * math.sin(deltaPhi / 2.0) +
        math.cos(phi1) * math.cos(phi2) *
        math.sin(deltaLambda / 2.0) * math.sin(deltaLambda / 2.0);
    final c = 2.0 * math.atan2(math.sqrt(a), math.sqrt(1.0 - a));
    return earthRadiusKm * c;
  }

  /// Converts an angle [0..360) to a 16-point cardinal direction (e.g. 292° -> WNW).
  static String cardinalDirection(double deg) {
    const directions = [
      'N', 'NNE', 'NE', 'ENE',
      'E', 'ESE', 'SE', 'SSE',
      'S', 'SSW', 'SW', 'WSW',
      'W', 'WNW', 'NW', 'NNW', 'N'
    ];
    final normalized = (deg % 360.0 + 360.0) % 360.0;
    final idx = ((normalized + 11.25) / 22.5).floor();
    return directions[idx % 16];
  }

  /// Shortest signed angular offset from [currentHeading] to [qiblaBearing].
  /// Positive: turn clockwise (right).
  /// Negative: turn counter-clockwise (left).
  static double turnOffset(double currentHeading, double qiblaBearing) {
    var diff = (qiblaBearing - currentHeading) % 360.0;
    if (diff > 180.0) diff -= 360.0;
    if (diff < -180.0) diff += 360.0;
    return diff;
  }

  /// True when the device heading is facing within [toleranceDegrees] (default ±4°) of the Qibla.
  static bool isFacingQibla(double currentHeading, double qiblaBearing, {double toleranceDegrees = 4.0}) {
    return turnOffset(currentHeading, qiblaBearing).abs() <= toleranceDegrees;
  }
}
