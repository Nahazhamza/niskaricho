import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n/tr.dart';
import '../services/compass/compass_stream.dart';
import '../services/prayer_calculator_service.dart';
import '../services/qibla_service.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/fx.dart';
import '../widgets/qibla_map_view.dart';

/// Full interactive Qibla Finder with real-time compass rotation,
/// Kaaba alignment feedback, haptics, distance to Makkah, and manual mode.
class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  final _db = SupabaseService.instance;
  final _calc = PrayerCalculatorService();

  double? _latitude;
  double? _longitude;
  String? _placeLabel;
  double? _qiblaBearing;
  double? _distanceKm;

  double _heading = 0.0;
  bool _hasSensor = false;
  bool _loadingLocation = true;
  String? _locationError;

  StreamSubscription<double?>? _compassSub;
  bool _wasFacingQibla = false;

  // Manual rotation angle when sensors are unavailable.
  double _manualAngle = 0.0;
  int _viewMode = 0; // 0: Compass, 1: Map

  @override
  void initState() {
    super.initState();
    _initLocation();
    _initCompass();
  }

  @override
  void dispose() {
    _compassSub?.cancel();
    super.dispose();
  }

  Future<void> _initLocation() async {
    setState(() {
      _loadingLocation = true;
      _locationError = null;
    });

    try {
      // 1. Try saved user location from profile / demo
      double? lat = _db.myLocation?.latitude;
      double? lng = _db.myLocation?.longitude;
      String? place = _db.myPlaceLabel;

      if (lat == null || lng == null) {
        final prof = await _db.myProfile();
        if (prof['latitude'] != null && prof['longitude'] != null) {
          lat = (prof['latitude'] as num).toDouble();
          lng = (prof['longitude'] as num).toDouble();
          place = prof['place'] as String? ?? place;
        }
      }

      // 2. If still null, query device GPS
      if (lat == null || lng == null) {
        final loc = await _calc.currentLocation();
        lat = loc.latitude;
        lng = loc.longitude;
      }

      final bearing = QiblaService.calculateBearing(lat, lng);
      final dist = QiblaService.calculateDistanceKm(lat, lng);

      if (mounted) {
        setState(() {
          _latitude = lat;
          _longitude = lng;
          _placeLabel = place;
          _qiblaBearing = bearing;
          _distanceKm = dist;
          _loadingLocation = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationError = '$e';
          _loadingLocation = false;
        });
      }
    }
  }

  void _initCompass() {
    try {
      _compassSub = getPlatformCompassHeadingStream().listen(
        (heading) {
          if (!mounted) return;
          if (heading != null) {
            final normalized = (heading % 360.0 + 360.0) % 360.0;
            final qBearing = _qiblaBearing;
            final isFacing = qBearing != null && QiblaService.isFacingQibla(normalized, qBearing);

            if (isFacing && !_wasFacingQibla) {
              HapticFeedback.heavyImpact();
            }
            _wasFacingQibla = isFacing;

            setState(() {
              _heading = normalized;
              _hasSensor = true;
            });
          }
        },
        onError: (_) {
          if (mounted) setState(() => _hasSensor = false);
        },
      );
    } catch (_) {
      _hasSensor = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final bearing = _qiblaBearing;
    final effectiveHeading = _hasSensor ? _heading : _manualAngle;
    final isFacing = bearing != null && QiblaService.isFacingQibla(effectiveHeading, bearing);
    final offset = bearing != null ? QiblaService.turnOffset(effectiveHeading, bearing) : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('🕋 Qibla Finder')),
        actions: [
          IconButton(
            icon: Icon(_viewMode == 0 ? Icons.map_outlined : Icons.explore_outlined),
            tooltip: _viewMode == 0 ? tr('Map') : tr('Compass'),
            onPressed: () => setState(() => _viewMode = _viewMode == 0 ? 1 : 0),
          ),
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: tr('Get location'),
            onPressed: _initLocation,
          ),
        ],
      ),
      body: SafeArea(
        child: _loadingLocation
            ? const Center(child: CircularProgressIndicator())
            : _latitude == null || bearing == null
                ? _buildLocationPrompt(t)
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: SegmentedButton<int>(
                          segments: [
                            ButtonSegment<int>(value: 0, icon: const Icon(Icons.explore), label: Text(tr('Compass'))),
                            ButtonSegment<int>(value: 1, icon: const Icon(Icons.map), label: Text(tr('Map'))),
                          ],
                          selected: {_viewMode},
                          onSelectionChanged: (s) => setState(() => _viewMode = s.first),
                        ),
                      ),
                      Expanded(
                        child: _viewMode == 1
                            ? QiblaMapView(
                                latitude: _latitude!,
                                longitude: _longitude!,
                                bearing: bearing,
                                distanceKm: _distanceKm ?? 0,
                              )
                            : Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    child: _buildInfoCard(t, bearing),
                                  ),
                                  const Spacer(),
                                  _buildCompassView(bearing, effectiveHeading, isFacing),
                                  const Spacer(),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    child: _buildGuidanceBanner(t, isFacing, offset),
                                  ),
                                  const SizedBox(height: 12),
                                ],
                              ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildLocationPrompt(TextTheme t) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_off_outlined, size: 54, color: AppColors.gold),
            const SizedBox(height: 16),
            Text(tr('Location needed to find Qibla'), style: t.titleMedium, textAlign: TextAlign.center),
            if (_locationError != null) ...[
              const SizedBox(height: 8),
              Text(_locationError!, style: t.bodySmall?.copyWith(color: AppColors.muted), textAlign: TextAlign.center),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _initLocation,
              icon: const Icon(Icons.location_on),
              label: Text(tr('Get location')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(TextTheme t, double bearing) {
    final dist = _distanceKm?.round() ?? 0;
    final cardinal = QiblaService.cardinalDirection(bearing);
    final label = _placeLabel ?? '${_latitude!.toStringAsFixed(2)}°, ${_longitude!.toStringAsFixed(2)}°';

    return GlassCard(
      glow: AppColors.gold,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.place_outlined, size: 15, color: AppColors.gold),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        label,
                        style: t.bodySmall?.copyWith(color: AppColors.gold, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  tr('{deg}° from North', {'deg': bearing.toStringAsFixed(1)}),
                  style: t.titleMedium?.copyWith(color: AppColors.cream, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  cardinal,
                  style: const TextStyle(color: AppColors.cyan, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  tr('{km} km to Makkah', {'km': dist}),
                  style: t.bodySmall?.copyWith(fontSize: 10.5, color: AppColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompassView(double qiblaBearing, double heading, bool isFacing) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () async {
            await requestWebCompassPermission();
          },
          onPanUpdate: _hasSensor
              ? null
              : (details) {
                  setState(() {
                    _manualAngle = (_manualAngle + details.delta.dx * 0.5) % 360.0;
                    if (_manualAngle < 0) _manualAngle += 360.0;
                  });
                },
          child: Center(
            child: SizedBox(
              width: 290,
              height: 290,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Compass Dial rotating with heading
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: heading),
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    builder: (_, currentH, _) {
                      return CustomPaint(
                        size: const Size(290, 290),
                        painter: _QiblaCompassPainter(
                          heading: currentH,
                          qiblaBearing: qiblaBearing,
                          isFacing: isFacing,
                        ),
                      );
                    },
                  ),
                  // Top phone alignment pointer (fixed at 12 o'clock)
                  Positioned(
                    top: 2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: isFacing ? AppColors.onTime : AppColors.gold,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (isFacing ? AppColors.onTime : AppColors.gold).withValues(alpha: 0.8),
                            blurRadius: isFacing ? 12 : 6,
                            spreadRadius: isFacing ? 2 : 0,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Center badge with live heading
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF0A1A1F),
                      border: Border.all(
                        color: isFacing ? AppColors.onTime : AppColors.gold.withValues(alpha: 0.5),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isFacing ? AppColors.onTime : AppColors.gold).withValues(alpha: 0.3),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${heading.round()}°',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isFacing ? AppColors.onTime : AppColors.cream,
                            ),
                          ),
                          Text(
                            QiblaService.cardinalDirection(heading),
                            style: const TextStyle(fontSize: 10, color: AppColors.cyan, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (!_hasSensor) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filledTonal(
                icon: const Icon(Icons.rotate_left, size: 20),
                onPressed: () => setState(() {
                  _manualAngle = (_manualAngle - 15) % 360.0;
                  if (_manualAngle < 0) _manualAngle += 360.0;
                }),
              ),
              const SizedBox(width: 8),
              FilledButton.tonal(
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                onPressed: () => setState(() => _manualAngle = 0),
                child: Text(tr('Reset North'), style: const TextStyle(fontSize: 12)),
              ),
              const SizedBox(width: 8),
              FilledButton.tonal(
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                onPressed: () => setState(() => _manualAngle = qiblaBearing),
                child: Text(tr('Align with Qibla'), style: const TextStyle(fontSize: 12)),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                icon: const Icon(Icons.rotate_right, size: 20),
                onPressed: () => setState(() => _manualAngle = (_manualAngle + 15) % 360.0),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildGuidanceBanner(TextTheme t, bool isFacing, double offset) {
    if (isFacing) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppColors.onTime.withValues(alpha: 0.15),
          border: Border.all(color: AppColors.onTime, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.onTime.withValues(alpha: 0.3),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🕋', style: TextStyle(fontSize: 26)),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('Facing the Qibla'),
                    style: t.titleMedium?.copyWith(color: AppColors.onTime, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    tr('You are facing the Qibla'),
                    style: t.bodySmall?.copyWith(color: AppColors.cream),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final turnDeg = offset.abs().round();
    final isRight = offset > 0;
    final guidanceText = isRight
        ? tr('Turn {deg}° right', {'deg': turnDeg})
        : tr('Turn {deg}° left', {'deg': turnDeg});

    return GlassCard(
      glow: AppColors.gold,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isRight ? Icons.rotate_right : Icons.rotate_left,
                color: AppColors.gold,
                size: 26,
              ),
              const SizedBox(width: 8),
              Text(
                guidanceText,
                style: t.titleMedium?.copyWith(color: AppColors.gold, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _hasSensor
                ? tr('Keep phone flat for best accuracy.')
                : tr('Computers lack compass sensors. Use controls or open on phone.'),
            style: t.bodySmall?.copyWith(color: AppColors.muted, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _QiblaCompassPainter extends CustomPainter {
  _QiblaCompassPainter({
    required this.heading,
    required this.qiblaBearing,
    required this.isFacing,
  });

  final double heading;
  final double qiblaBearing;
  final bool isFacing;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 8;

    // Background circle
    canvas.drawCircle(c, r, Paint()..color = const Color(0xFF08171B));
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = isFacing ? AppColors.onTime : AppColors.gold.withValues(alpha: 0.4),
    );

    // Inner subtle ring
    canvas.drawCircle(
      c,
      r * 0.75,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: 0.06),
    );

    // Draw rotated compass dial
    canvas.save();
    canvas.translate(c.dx, c.dy);
    // Rotate dial opposite to device heading so North aligns with true North
    canvas.rotate(-heading * math.pi / 180.0);

    // Compass dial degree ticks
    for (var i = 0; i < 72; i++) {
      final deg = i * 5;
      final rad = deg * math.pi / 180.0;
      final isMajor = deg % 90 == 0;
      final isMedium = deg % 30 == 0;
      final tickLen = isMajor ? 14.0 : (isMedium ? 10.0 : 5.0);
      final tickColor = isMajor
          ? (deg == 0 ? AppColors.cyan : AppColors.cream)
          : (isMedium ? AppColors.gold.withValues(alpha: 0.7) : Colors.white.withValues(alpha: 0.25));

      final startOffset = Offset(math.sin(rad) * (r - tickLen), -math.cos(rad) * (r - tickLen));
      final endOffset = Offset(math.sin(rad) * r, -math.cos(rad) * r);

      canvas.drawLine(
        startOffset,
        endOffset,
        Paint()
          ..color = tickColor
          ..strokeWidth = isMajor ? 2.5 : (isMedium ? 1.5 : 1.0),
      );
    }

    // Cardinal labels: N, E, S, W
    const cardinals = [
      (0, 'N', AppColors.cyan),
      (90, 'E', AppColors.cream),
      (180, 'S', AppColors.cream),
      (270, 'W', AppColors.cream),
    ];
    for (final (deg, text, color) in cardinals) {
      final rad = deg * math.pi / 180.0;
      final pos = Offset(math.sin(rad) * (r - 26), -math.cos(rad) * (r - 26));

      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
    }

    // Draw Kaaba Pointer on the rotating dial
    final kaabaRad = qiblaBearing * math.pi / 180.0;
    final kaabaPos = Offset(math.sin(kaabaRad) * (r - 16), -math.cos(kaabaRad) * (r - 16));

    // Needle from center towards Kaaba
    final needleTip = Offset(math.sin(kaabaRad) * (r - 36), -math.cos(kaabaRad) * (r - 36));

    // Glowing needle
    canvas.drawLine(
      Offset.zero,
      needleTip,
      Paint()
        ..color = (isFacing ? AppColors.onTime : AppColors.gold).withValues(alpha: 0.3)
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawLine(
      Offset.zero,
      needleTip,
      Paint()
        ..color = isFacing ? AppColors.onTime : AppColors.gold
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round,
    );

    // Kaaba icon beacon circle
    canvas.drawCircle(
      kaabaPos,
      13,
      Paint()
        ..color = isFacing ? AppColors.onTime : AppColors.gold
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      kaabaPos,
      15,
      Paint()
        ..color = (isFacing ? AppColors.onTime : AppColors.gold).withValues(alpha: 0.4)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );

    // Kaaba emoji / indicator
    final kaabaTp = TextPainter(
      text: const TextSpan(
        text: '🕋',
        style: TextStyle(fontSize: 14),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    kaabaTp.paint(canvas, kaabaPos - Offset(kaabaTp.width / 2, kaabaTp.height / 2));

    canvas.restore();
  }

  @override
  bool shouldRepaint(_QiblaCompassPainter old) =>
      old.heading != heading || old.qiblaBearing != qiblaBearing || old.isFacing != isFacing;
}
