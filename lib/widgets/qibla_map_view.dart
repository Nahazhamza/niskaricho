import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n/tr.dart';
import '../services/qibla_service.dart';
import '../theme/app_theme.dart';

/// Overhead map view showing the user's location and the great-circle Qibla
/// trajectory line to Makkah (inspired by Google's desktop Qibla Finder).
class QiblaMapView extends StatefulWidget {
  const QiblaMapView({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.bearing,
    required this.distanceKm,
  });

  final double latitude;
  final double longitude;
  final double bearing;
  final double distanceKm;

  @override
  State<QiblaMapView> createState() => _QiblaMapViewState();
}

class _QiblaMapViewState extends State<QiblaMapView> {
  final _tileManager = _TileManager();

  // Zoom level: 16 is neighborhood / street & building level.
  double _zoom = 16.0;
  double _baseZoom = 16.0;
  Offset _panOffset = Offset.zero;
  bool _satellite = false;

  @override
  void dispose() {
    _tileManager.dispose();
    super.dispose();
  }

  void _onScaleStart(ScaleStartDetails details) {
    _baseZoom = _zoom;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      // Panning translation (1 finger or 2 fingers)
      _panOffset += details.focalPointDelta;

      // Two-finger pinch-to-zoom
      if (details.scale != 1.0) {
        final zoomDelta = math.log(details.scale) / math.ln2;
        _zoom = (_baseZoom + zoomDelta).clamp(3.0, 18.0);
      }
    });
  }

  void _zoomIn() {
    if (_zoom < 18.0) setState(() => _zoom = (_zoom + 1.0).clamp(3.0, 18.0));
  }

  void _zoomOut() {
    if (_zoom > 4.0) setState(() => _zoom = (_zoom - 1.0).clamp(3.0, 18.0));
  }

  void _resetCenter() {
    setState(() => _panOffset = Offset.zero);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cardinal = QiblaService.cardinalDirection(widget.bearing);

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final center = Offset(size.width / 2, size.height / 2) + _panOffset;

        return Stack(
          children: [
            // Interactive pannable & pinch-to-zoom map area
            Listener(
              onPointerSignal: (event) {
                if (event is PointerScrollEvent) {
                  setState(() {
                    if (event.scrollDelta.dy < 0) {
                      _zoom = (_zoom + 0.5).clamp(3.0, 18.0);
                    } else if (event.scrollDelta.dy > 0) {
                      _zoom = (_zoom - 0.5).clamp(3.0, 18.0);
                    }
                  });
                }
              },
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onScaleStart: _onScaleStart,
                onScaleUpdate: _onScaleUpdate,
                child: ClipRect(
                  child: CustomPaint(
                    size: size,
                    painter: _TileMapPainter(
                      tileManager: _tileManager,
                      lat: widget.latitude,
                      lng: widget.longitude,
                      zoom: _zoom.floor(),
                      centerOffset: _panOffset,
                      satellite: _satellite,
                    ),
                    foregroundPainter: _QiblaRayPainter(
                      center: center,
                      bearing: widget.bearing,
                      size: size,
                    ),
                  ),
                ),
              ),
            ),

            // Top info banner with high-contrast background
            Positioned(
              top: 12,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D221D).withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.6), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.6),
                      blurRadius: 18,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.25),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Text('🕋', style: TextStyle(fontSize: 26)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr('{deg}° from North', {'deg': widget.bearing.toStringAsFixed(1)}),
                            style: t.titleMedium?.copyWith(
                              color: AppColors.cream,
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$cardinal · ${tr('{km} km to Makkah', {'km': widget.distanceKm.round()})}',
                            style: t.bodySmall?.copyWith(
                              color: AppColors.gold,
                              fontWeight: FontWeight.w600,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Toggle Street vs Satellite
                    InkWell(
                      onTap: () => setState(() => _satellite = !_satellite),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _satellite ? AppColors.gold : Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _satellite ? Icons.satellite_alt : Icons.map,
                              size: 15,
                              color: _satellite ? Colors.black : AppColors.cream,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _satellite ? tr('Satellite') : tr('Street'),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _satellite ? Colors.black : AppColors.cream,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Floating map controls (Zoom in, Zoom out, Center, Satellite toggle)
            Positioned(
              right: 16,
              bottom: 90,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FloatingActionButton.small(
                    heroTag: 'map_zoom_in',
                    backgroundColor: const Color(0xFF0D221D),
                    foregroundColor: AppColors.cream,
                    tooltip: tr('Zoom in'),
                    onPressed: _zoomIn,
                    child: const Icon(Icons.add),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton.small(
                    heroTag: 'map_zoom_out',
                    backgroundColor: const Color(0xFF0D221D),
                    foregroundColor: AppColors.cream,
                    tooltip: tr('Zoom out'),
                    onPressed: _zoomOut,
                    child: const Icon(Icons.remove),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton.small(
                    heroTag: 'map_center',
                    backgroundColor: const Color(0xFF0D221D),
                    foregroundColor: AppColors.gold,
                    tooltip: tr('Center on my location'),
                    onPressed: _resetCenter,
                    child: const Icon(Icons.my_location),
                  ),
                ],
              ),
            ),

            // Bottom guidance tip with solid contrast
            Positioned(
              left: 16,
              right: 80,
              bottom: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D221D).withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.cyan.withValues(alpha: 0.5)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 18, color: AppColors.cyan),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tr('Zoom in to align with your building, street or window.'),
                        style: t.bodySmall?.copyWith(fontSize: 11.5, color: AppColors.cream, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Manages tile network fetching and caching with change notifications.
class _TileManager extends ChangeNotifier {
  final Map<String, ImageInfo> _cache = {};
  final Set<String> _loading = {};

  ImageInfo? getTile(int z, int x, int y, bool satellite) {
    final key = '$z/$y/$x-$satellite';
    final cached = _cache[key];
    if (cached != null) return cached;

    if (!_loading.contains(key)) {
      _loading.add(key);
      // Esri World Street Map or Satellite Imagery: 100% free, no API key, no watermark.
      final service = satellite ? 'World_Imagery' : 'World_Street_Map';
      final url = 'https://server.arcgisonline.com/ArcGIS/rest/services/$service/MapServer/tile/$z/$y/$x';

      final stream = NetworkImage(url).resolve(ImageConfiguration.empty);
      stream.addListener(
        ImageStreamListener(
          (info, _) {
            _cache[key] = info;
            _loading.remove(key);
            notifyListeners();
          },
          onError: (e, st) {
            _loading.remove(key);
          },
        ),
      );
    }
    return null;
  }
}

/// Draws map tiles for the visible viewport.
class _TileMapPainter extends CustomPainter {
  _TileMapPainter({
    required this.tileManager,
    required this.lat,
    required this.lng,
    required this.zoom,
    required this.centerOffset,
    required this.satellite,
  }) : super(repaint: tileManager);

  final _TileManager tileManager;
  final double lat;
  final double lng;
  final int zoom;
  final Offset centerOffset;
  final bool satellite;

  @override
  void paint(Canvas canvas, Size size) {
    // Fill dark background
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = satellite ? const Color(0xFF0A0F0D) : const Color(0xFF0F201C),
    );

    // Mercator pixel math
    final n = 1 << zoom;
    final latRad = lat * math.pi / 180.0;
    final userPixelX = (lng + 180.0) / 360.0 * n * 256.0;
    final userPixelY = (1.0 - math.log(math.tan(latRad) + 1.0 / math.cos(latRad)) / math.pi) / 2.0 * n * 256.0;

    final centerScreenX = size.width / 2 + centerOffset.dx;
    final centerScreenY = size.height / 2 + centerOffset.dy;

    final viewLeft = userPixelX - centerScreenX;
    final viewTop = userPixelY - centerScreenY;
    final viewRight = viewLeft + size.width;
    final viewBottom = viewTop + size.height;

    final minTileX = (viewLeft / 256.0).floor().clamp(0, n - 1);
    final maxTileX = (viewRight / 256.0).floor().clamp(0, n - 1);
    final minTileY = (viewTop / 256.0).floor().clamp(0, n - 1);
    final maxTileY = (viewBottom / 256.0).floor().clamp(0, n - 1);

    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke;

    for (var tx = minTileX; tx <= maxTileX; tx++) {
      for (var ty = minTileY; ty <= maxTileY; ty++) {
        final screenX = tx * 256.0 - viewLeft;
        final screenY = ty * 256.0 - viewTop;
        final rect = Rect.fromLTWH(screenX, screenY, 256.0, 256.0);

        final tile = tileManager.getTile(zoom, tx, ty, satellite);
        if (tile != null) {
          canvas.drawImageRect(
            tile.image,
            Rect.fromLTWH(0, 0, tile.image.width.toDouble(), tile.image.height.toDouble()),
            rect,
            Paint(),
          );
        } else {
          canvas.drawRect(rect, gridPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_TileMapPainter old) =>
      old.lat != lat ||
      old.lng != lng ||
      old.zoom != zoom ||
      old.centerOffset != centerOffset ||
      old.satellite != satellite;
}

/// Draws the user's location pin and the golden Qibla trajectory ray pointing to Makkah.
class _QiblaRayPainter extends CustomPainter {
  _QiblaRayPainter({
    required this.center,
    required this.bearing,
    required this.size,
  });

  final Offset center;
  final double bearing;
  final Size size;

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final rad = bearing * math.pi / 180.0;
    // Length of the beam extending past the edges of the screen
    final beamLength = math.max(size.width, size.height) * 2.5;
    final endPoint = center + Offset(math.sin(rad) * beamLength, -math.cos(rad) * beamLength);

    // Outer glow for the laser beam
    canvas.drawLine(
      center,
      endPoint,
      Paint()
        ..color = AppColors.gold.withValues(alpha: 0.4)
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Inner sharp golden line
    canvas.drawLine(
      center,
      endPoint,
      Paint()
        ..color = AppColors.gold
        ..strokeWidth = 4.0
        ..strokeCap = StrokeCap.round,
    );

    // Direction arrow chevrons along the beam
    for (var d = 70.0; d < 500.0; d += 90.0) {
      final p = center + Offset(math.sin(rad) * d, -math.cos(rad) * d);
      final arrowBack1 = p + Offset(math.sin(rad + 2.5) * 14, -math.cos(rad + 2.5) * 14);
      final arrowBack2 = p + Offset(math.sin(rad - 2.5) * 14, -math.cos(rad - 2.5) * 14);

      canvas.drawLine(p, arrowBack1, Paint()..color = Colors.white..strokeWidth = 3.0);
      canvas.drawLine(p, arrowBack2, Paint()..color = Colors.white..strokeWidth = 3.0);
    }

    // User location pin (pulsing circle with crisp high-contrast border)
    canvas.drawCircle(
      center,
      22,
      Paint()..color = AppColors.cyan.withValues(alpha: 0.3),
    );
    canvas.drawCircle(
      center,
      12,
      Paint()..color = AppColors.cyan,
    );
    canvas.drawCircle(
      center,
      6,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      center,
      12,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(_QiblaRayPainter old) => old.center != center || old.bearing != bearing;
}
