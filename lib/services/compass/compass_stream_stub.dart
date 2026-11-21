/// Stub compass stream for platforms without sensor support.
Stream<double?> getPlatformCompassHeadingStream() => const Stream.empty();

Future<bool> requestWebCompassPermission() async => true;
