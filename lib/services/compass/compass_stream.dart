export 'compass_stream_stub.dart'
    if (dart.library.js_interop) 'compass_stream_web.dart'
    if (dart.library.io) 'compass_stream_native.dart';
