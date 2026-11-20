// Visual effects: animated night sky, glass panels, glowing rings, the sun's
// arc through the five prayers, confetti celebrations and tactile buttons.

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../models/prayer_model.dart';
import '../theme/app_theme.dart';
import '../theme/look.dart';

// ---------------------------------------------------------------------------
// Animated cosmic background: slow aurora blobs + twinkling stars.
// ---------------------------------------------------------------------------
class CosmicBackground extends StatefulWidget {
  const CosmicBackground({super.key, required this.child});
  final Widget child;

  @override
  State<CosmicBackground> createState() => _CosmicBackgroundState();
}

class _CosmicBackgroundState extends State<CosmicBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 40));
  final _stars = List.generate(90, (i) {
    final r = math.Random(i * 7919);
    return (x: r.nextDouble(), y: r.nextDouble(), s: r.nextDouble() * 1.6 + 0.4, p: r.nextDouble());
  });

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final look = LookScope.of(context);
    // Lite / reduced motion / Masjid style: paint once, no ticking.
    if (look.still) {
      if (_c.isAnimating) _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
    return Stack(
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: look.style == AppStyle.masjid
                ? const CustomPaint(painter: _GeometricPainter())
                : look.still
                ? CustomPaint(painter: _SkyPainter(0.12, _stars))
                : AnimatedBuilder(
                    animation: _c,
                    builder: (_, _) => CustomPaint(painter: _SkyPainter(_c.value, _stars)),
                  ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _SkyPainter extends CustomPainter {
  _SkyPainter(this.t, this.stars);
  final double t;
  final List<({double x, double y, double s, double p})> stars;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF030A12), Color(0xFF07211C), Color(0xFF0B1F1A)],
        ).createShader(rect),
    );
    final a = t * 2 * math.pi;
    void blob(Color c, double cx, double cy, double r) => canvas.drawCircle(
      Offset(cx * size.width, cy * size.height),
      r * size.shortestSide,
      Paint()
        ..color = c
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 90),
    );
    blob(AppColors.emerald.withValues(alpha: 0.22), 0.2 + 0.1 * math.sin(a), 0.15 + 0.05 * math.cos(a), 0.55);
    blob(AppColors.violet.withValues(alpha: 0.16), 0.9 + 0.08 * math.cos(a * 2), 0.45 + 0.1 * math.sin(a), 0.5);
    blob(AppColors.gold.withValues(alpha: 0.08), 0.5 + 0.2 * math.sin(a * 1.5), 0.95, 0.6);

    for (final s in stars) {
      final tw = 0.35 + 0.65 * (0.5 + 0.5 * math.sin(a * 6 + s.p * 20));
      canvas.drawCircle(
        Offset(s.x * size.width, s.y * size.height * 0.7),
        s.s,
        Paint()..color = Colors.white.withValues(alpha: 0.5 * tw),
      );
    }
  }

  @override
  bool shouldRepaint(_SkyPainter old) => old.t != t;
}

/// Masjid style: deep teal-navy with a faint gold lattice of eight-point
/// stars (khatam), the pattern found in mosque tiles and musalla borders.
class _GeometricPainter extends CustomPainter {
  const _GeometricPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0A1A2A), Color(0xFF0C2530), Color(0xFF0B2420)],
        ).createShader(rect),
    );
    final line = Paint()
      ..color = AppColors.gold.withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    const cell = 64.0;
    for (var y = -cell / 2; y < size.height + cell; y += cell) {
      for (var x = -cell / 2; x < size.width + cell; x += cell) {
        final c = Offset(x, y);
        // Two overlapping squares = an eight-point star.
        for (final rot in [0.0, math.pi / 4]) {
          final p = Path();
          for (var i = 0; i < 4; i++) {
            final a = rot + i * math.pi / 2 + math.pi / 4;
            final pt = c + Offset(math.cos(a), math.sin(a)) * (cell * 0.36);
            i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
          }
          canvas.drawPath(p..close(), line);
        }
        // Small connecting cross between stars.
        canvas.drawCircle(c + const Offset(cell / 2, cell / 2), 3, line);
      }
    }
    // A soft glow behind the top, like a lit dome.
    canvas.drawCircle(
      Offset(size.width / 2, -size.width * 0.25),
      size.width * 0.8,
      Paint()
        ..shader = RadialGradient(
          colors: [AppColors.emerald.withValues(alpha: 0.18), Colors.transparent],
        ).createShader(Rect.fromCircle(center: Offset(size.width / 2, -size.width * 0.25), radius: size.width * 0.8)),
    );
  }

  @override
  bool shouldRepaint(_GeometricPainter old) => false;
}

// ---------------------------------------------------------------------------
// Frosted glass panel with a soft neon edge.
// ---------------------------------------------------------------------------
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.glow,
    this.radius = 24,
    this.margin = const EdgeInsets.symmetric(vertical: 6),
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color? glow;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final look = LookScope.of(context);
    if (look.still) {
      // No blur: a solid panel is much cheaper on older phones.
      final masjid = look.style == AppStyle.masjid;
      return Padding(
        padding: margin,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(masjid ? 14 : radius),
            color: masjid ? const Color(0xF2112A33) : const Color(0xE6122A26),
            border: Border.all(
              color:
                  glow?.withValues(alpha: 0.7) ??
                  (masjid ? AppColors.gold.withValues(alpha: 0.35) : Colors.white.withValues(alpha: 0.10)),
              width: masjid ? 1.2 : 1,
            ),
          ),
          child: child,
        ),
      );
    }
    return Padding(
      padding: margin,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            if (glow != null) BoxShadow(color: glow!.withValues(alpha: 0.35), blurRadius: 28, spreadRadius: -6),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white.withValues(alpha: 0.09), Colors.white.withValues(alpha: 0.03)],
                ),
                border: Border.all(color: (glow ?? Colors.white).withValues(alpha: glow != null ? 0.45 : 0.10)),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tap feedback: squish + haptic.
// ---------------------------------------------------------------------------
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, this.onTap});
  final Widget child;
  final VoidCallback? onTap;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: widget.onTap == null ? null : (_) => setState(() => _down = true),
    onTapCancel: () => setState(() => _down = false),
    onTapUp: (_) => setState(() => _down = false),
    onTap: widget.onTap == null
        ? null
        : () {
            HapticFeedback.lightImpact();
            widget.onTap!();
          },
    child: AnimatedScale(
      scale: _down ? 0.95 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: widget.child,
    ),
  );
}

// ---------------------------------------------------------------------------
// Entrance animation: fade + rise, staggered by [index].
// ---------------------------------------------------------------------------
class RiseIn extends StatelessWidget {
  const RiseIn({super.key, required this.child, this.index = 0});
  final Widget child;
  final int index;

  @override
  Widget build(BuildContext context) => LookScope.of(context).lite
      ? child
      : TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 450 + index * 70),
          curve: Curves.easeOutCubic,
          builder: (_, v, child) => Opacity(
            opacity: v,
            child: Transform.translate(offset: Offset(0, 24 * (1 - v)), child: child),
          ),
          child: child,
        );
}

// ---------------------------------------------------------------------------
// Five glowing ring segments — one per prayer — around a centre widget.
// ---------------------------------------------------------------------------
class PrayerRings extends StatelessWidget {
  const PrayerRings({super.key, required this.statuses, required this.child, this.size = 120});
  final List<PrayerStatus> statuses; // fajr..isha
  final Widget child;
  final double size;

  @override
  Widget build(BuildContext context) => LookScope.of(context).lite
      ? child
      : TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 1200),
          curve: Curves.easeOutCubic,
          builder: (_, v, c) => CustomPaint(
            size: Size.square(size),
            painter: _RingsPainter(statuses, v),
            child: SizedBox.square(
              dimension: size,
              child: Center(child: c),
            ),
          ),
          child: child,
        );
}

class _RingsPainter extends CustomPainter {
  _RingsPainter(this.statuses, this.v);
  final List<PrayerStatus> statuses;
  final double v;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 8;
    const gap = 0.12;
    final seg = 2 * math.pi / 5;
    for (var i = 0; i < 5; i++) {
      final s = i < statuses.length ? statuses[i] : PrayerStatus.upcoming;
      final color = AppColors.forStatus(s);
      final start = -math.pi / 2 + i * seg + gap / 2;
      final sweep = (seg - gap) * v;
      final rect = Rect.fromCircle(center: c, radius: r);
      canvas.drawArc(
        rect,
        start,
        seg - gap,
        false,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.07)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 9
          ..strokeCap = StrokeCap.round,
      );
      if (s == PrayerStatus.upcoming) continue;
      final paint = Paint()
        ..color = color.withValues(alpha: s.isDone ? 1 : 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..strokeCap = StrokeCap.round;
      if (s.isDone) {
        canvas.drawArc(
          rect,
          start,
          sweep,
          false,
          Paint()
            ..color = color.withValues(alpha: 0.6)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 14
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
        );
      }
      canvas.drawArc(rect, start, sweep, false, paint);
    }
  }

  @override
  bool shouldRepaint(_RingsPainter old) => old.v != v || old.statuses != statuses;
}

// ---------------------------------------------------------------------------
// The sky arc: the sun travels from Fajr to Isha; each prayer is a node.
// ---------------------------------------------------------------------------
class SkyArc extends StatelessWidget {
  const SkyArc({super.key, required this.windows, required this.now, required this.statuses});
  final List<PrayerWindow> windows; // today's five
  final DateTime now;
  final Map<PrayerName, PrayerStatus> statuses;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 120,
    child: CustomPaint(painter: _SkyArcPainter(windows, now, statuses), size: Size.infinite),
  );
}

class _SkyArcPainter extends CustomPainter {
  _SkyArcPainter(this.windows, this.now, this.statuses);
  final List<PrayerWindow> windows;
  final DateTime now;
  final Map<PrayerName, PrayerStatus> statuses;

  @override
  void paint(Canvas canvas, Size size) {
    if (windows.length < 5) return;
    final t0 = windows.first.start, t1 = windows.last.start.add(const Duration(minutes: 60));
    double frac(DateTime t) => (t.difference(t0).inSeconds / t1.difference(t0).inSeconds).clamp(0.0, 1.0).toDouble();
    Offset at(double f) {
      final x = 18 + f * (size.width - 36);
      final y = size.height - 22 - math.sin(f * math.pi) * (size.height - 44);
      return Offset(x, y);
    }

    // Path of the day
    final path = Path()..moveTo(at(0).dx, at(0).dy);
    for (var f = 0.0; f <= 1.0001; f += 0.01) {
      path.lineTo(at(f).dx, at(f).dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white.withValues(alpha: 0.12),
    );
    // Travelled part, glowing
    final nowF = frac(now);
    final done = Path()..moveTo(at(0).dx, at(0).dy);
    for (var f = 0.0; f <= nowF; f += 0.005) {
      done.lineTo(at(f).dx, at(f).dy);
    }
    canvas.drawPath(
      done,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..shader = const LinearGradient(colors: [AppColors.violet, AppColors.emerald, AppColors.gold])
            .createShader(Offset.zero & size),
    );

    final label = TextPainter(textDirection: TextDirection.ltr);
    for (final w in windows) {
      final p = at(frac(w.start));
      final st = statuses[w.prayer] ?? PrayerStatus.upcoming;
      final c = AppColors.forStatus(st);
      canvas.drawCircle(p, 9, Paint()..color = c.withValues(alpha: 0.25));
      canvas.drawCircle(p, 5, Paint()..color = st == PrayerStatus.upcoming ? Colors.white24 : c);
      label.text = TextSpan(
        text: w.prayer.label,
        style: const TextStyle(fontSize: 10, color: AppColors.muted, fontWeight: FontWeight.w600),
      );
      label.layout();
      label.paint(canvas, p + Offset(-label.width / 2, 10));
    }
    // The sun (or moon after Maghrib)
    final sp = at(nowF);
    final isNight = !now.isBefore(windows[3].start) || now.isBefore(windows[0].end);
    final sunColor = isNight ? const Color(0xFFE2E8F0) : AppColors.gold;
    canvas.drawCircle(
      sp,
      18,
      Paint()
        ..color = sunColor.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    canvas.drawCircle(sp, 8, Paint()..color = sunColor);
  }

  @override
  bool shouldRepaint(_SkyArcPainter old) => old.now != now || old.statuses != statuses;
}

// ---------------------------------------------------------------------------
// Animated progress bar with a shimmering neon fill.
// ---------------------------------------------------------------------------
class NeonBar extends StatelessWidget {
  const NeonBar({super.key, required this.value, this.height = 10, this.colors});
  final double value;
  final double height;
  final List<Color>? colors;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: value.clamp(0, 1)),
    duration: const Duration(milliseconds: 1100),
    curve: Curves.easeOutCubic,
    builder: (_, v, _) => Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(height),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: v == 0 ? 0.001 : v,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(height),
            gradient: LinearGradient(colors: colors ?? const [AppColors.emerald, AppColors.cyan]),
            boxShadow: [
              BoxShadow(color: (colors ?? [AppColors.cyan]).last.withValues(alpha: 0.6), blurRadius: 10),
            ],
          ),
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Celebration overlay: confetti burst + headline. Call [celebrate].
// ---------------------------------------------------------------------------
Future<void> celebrate(
  BuildContext context, {
  required String title,
  String? subtitle,
  String emoji = '🎉',
  bool big = false,
}) async {
  HapticFeedback.heavyImpact();
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => Material(
      type: MaterialType.transparency,
      child: _Celebration(title: title, subtitle: subtitle, emoji: emoji, big: big, onDone: () => entry.remove()),
    ),
  );
  overlay.insert(entry);
}

class _Celebration extends StatefulWidget {
  const _Celebration({required this.title, required this.emoji, required this.onDone, this.subtitle, this.big = false});
  final String title;
  final String? subtitle;
  final String emoji;
  final bool big;
  final VoidCallback onDone;

  @override
  State<_Celebration> createState() => _CelebrationState();
}

class _CelebrationState extends State<_Celebration> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: widget.big ? 3200 : 2400),
  )..forward().whenComplete(widget.onDone);
  late final _parts = List.generate(widget.big ? 140 : 80, (i) {
    final r = math.Random(i);
    return (
      angle: r.nextDouble() * 2 * math.pi,
      speed: 0.35 + r.nextDouble() * 0.75,
      spin: r.nextDouble() * 10,
      color: [AppColors.gold, AppColors.emerald, AppColors.cyan, AppColors.violet, AppColors.cream][i % 5],
      size: 4 + r.nextDouble() * 6,
    );
  });

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;
        final fade = t < 0.75 ? 1.0 : (1 - (t - 0.75) / 0.25);
        final pop = Curves.elasticOut.transform((t * 2.2).clamp(0, 1));
        return Opacity(
          opacity: fade,
          child: Stack(
            children: [
              Positioned.fill(
                child: ColoredBox(color: Colors.black.withValues(alpha: 0.35 * fade)),
              ),
              Positioned.fill(child: CustomPaint(painter: _ConfettiPainter(_parts, t))),
              Center(
                child: Transform.scale(
                  scale: 0.4 + 0.6 * pop,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(widget.emoji, style: TextStyle(fontSize: widget.big ? 84 : 64)),
                      const SizedBox(height: 8),
                      Text(
                        widget.title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: widget.big ? 34 : 28,
                          fontWeight: FontWeight.w900,
                          color: AppColors.cream,
                          decoration: TextDecoration.none,
                          shadows: const [Shadow(color: AppColors.gold, blurRadius: 24)],
                        ),
                      ),
                      if (widget.subtitle != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6, left: 24, right: 24),
                          child: Text(
                            widget.subtitle!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 15,
                              color: AppColors.gold,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.parts, this.t);
  final List<({double angle, double speed, double spin, Color color, double size})> parts;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(size.width / 2, size.height * 0.45);
    final reach = size.longestSide * 0.7;
    for (final p in parts) {
      final d = Curves.easeOutCubic.transform(t) * p.speed * reach;
      final pos = origin + Offset(math.cos(p.angle) * d, math.sin(p.angle) * d) + Offset(0, 260 * t * t); // gravity
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(p.spin * t * 6);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.5),
          const Radius.circular(1.5),
        ),
        Paint()..color = p.color,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}

/// Small glowing pill used for status tags and stats.
class GlowChip extends StatelessWidget {
  const GlowChip(this.text, this.color, {super.key});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: 0.4)),
    ),
    child: Text(
      text,
      style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.w700),
    ),
  );
}
