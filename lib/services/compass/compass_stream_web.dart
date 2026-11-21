import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:web/web.dart' as web;

/// Reads HTML5 deviceorientation and deviceorientationabsolute events in Web browsers.
Stream<double?> getPlatformCompassHeadingStream() {
  late StreamController<double?> controller;
  JSFunction? listener;

  controller = StreamController<double?>.broadcast(
    onListen: () {
      listener = ((web.DeviceOrientationEvent event) {
        final jsObj = event as JSObject;
        // iOS Safari provides webkitCompassHeading directly (degrees from True North).
        if (jsObj.hasProperty('webkitCompassHeading'.toJS).toDart) {
          final prop = jsObj['webkitCompassHeading'];
          if (prop != null && prop.isA<JSNumber>()) {
            final heading = (prop as JSNumber).toDartDouble;
            if (!controller.isClosed) controller.add(heading);
            return;
          }
        }
        final alpha = event.alpha;
        if (alpha != null) {
          // In standard Android deviceorientation, alpha=0 is North, alpha=90 is West.
          // Compass heading clockwise from North: (360 - alpha) % 360
          final heading = (360.0 - alpha) % 360.0;
          if (!controller.isClosed) controller.add(heading);
        }
      }).toJS;

      web.window.addEventListener('deviceorientationabsolute', listener);
      web.window.addEventListener('deviceorientation', listener);
    },
    onCancel: () {
      if (listener != null) {
        web.window.removeEventListener('deviceorientationabsolute', listener);
        web.window.removeEventListener('deviceorientation', listener);
      }
    },
  );

  return controller.stream;
}

/// On iOS Safari Web, request permission for device orientation sensors.
Future<bool> requestWebCompassPermission() async {
  try {
    final devOrientationClass = (web.window as JSObject)['DeviceOrientationEvent'] as JSObject?;
    if (devOrientationClass != null && devOrientationClass.hasProperty('requestPermission'.toJS).toDart) {
      final promise = devOrientationClass.callMethod('requestPermission'.toJS) as JSPromise;
      final result = await promise.toDart;
      return (result as JSString).toDart == 'granted';
    }
  } catch (_) {}
  return true;
}
