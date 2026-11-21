import 'package:flutter_compass/flutter_compass.dart';

/// Reads native magnetometer/sensor compass heading on Android and iOS.
Stream<double?> getPlatformCompassHeadingStream() {
  return FlutterCompass.events?.map((e) => e.heading) ?? const Stream.empty();
}

Future<bool> requestWebCompassPermission() async => true;
