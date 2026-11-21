import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:web/web.dart' as web;

/// Reads HTML5 deviceorientation and deviceorientationabsolute events in Web browsers.
Stream<double?> getPlatformCompassHeadingStream() {
  late StreamController<double?> controller;
  JSFunction? cleanupFn;

  controller = StreamController<double?>.broadcast(
    onListen: () {
      try {
        final win = web.window as JSObject;
        if (win.hasProperty('__startCompass'.toJS).toDart) {
          final jsCallback = ((JSNumber heading) {
            if (!controller.isClosed) {
              controller.add(heading.toDartDouble);
            }
          }).toJS;
          final cleanup = win.callMethod('__startCompass'.toJS, jsCallback);
          if (cleanup.isA<JSFunction>()) {
            cleanupFn = cleanup as JSFunction;
          }
          return;
        }
      } catch (_) {}

      // Fallback direct event listeners if bridge is unavailable
      void onEvent(web.DeviceOrientationEvent event) {
        final jsObj = event as JSObject;
        final prop = jsObj['webkitCompassHeading'];
        if (prop != null && prop.isA<JSNumber>()) {
          final heading = (prop as JSNumber).toDartDouble;
          if (!controller.isClosed) controller.add(heading);
          return;
        }
        final alpha = event.alpha;
        if (alpha != null) {
          final heading = (360.0 - alpha) % 360.0;
          if (!controller.isClosed) controller.add(heading);
        }
      }

      final listener = onEvent.toJS;
      web.window.addEventListener('deviceorientationabsolute', listener);
      web.window.addEventListener('deviceorientation', listener);
    },
    onCancel: () {
      try {
        cleanupFn?.callAsFunction();
      } catch (_) {}
    },
  );

  return controller.stream;
}

/// On iOS Safari Web, request permission for device orientation sensors.
Future<bool> requestWebCompassPermission() async {
  try {
    final win = web.window as JSObject;
    if (win.hasProperty('__requestCompassPermission'.toJS).toDart) {
      final promise = win.callMethod('__requestCompassPermission'.toJS) as JSPromise;
      final result = await promise.toDart;
      return (result as JSBoolean).toDart;
    }
  } catch (_) {}
  return true;
}
