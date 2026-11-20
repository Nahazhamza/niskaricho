import 'dart:math' as math;

import '../l10n/tr.dart';

import 'package:material_ui/material_ui.dart';

/// A prayer mat (musalla) with a mihrab arch, drawn in code so it stays
/// sharp at any size and needs no icon font. Used for "Pray Now".
/// Deliberately no human figure.
class MusallaIcon extends StatelessWidget {
  const MusallaIcon({super.key, this.size = 18, this.color = Colors.white});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Semantics(
    label: tr('Prayer mat'),
    child: CustomPaint(size: Size(size * 0.72, size), painter: _MusallaPainter(color)),
  );
}

class _MusallaPainter extends CustomPainter {
  _MusallaPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.2, w * 0.11)
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    // Mat outline.
    final mat = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.08, h * 0.04, w * 0.84, h * 0.82),
      Radius.circular(w * 0.1),
    );
    canvas.drawRRect(mat, stroke);
    // Pointed mihrab arch.
    final l = w * 0.27, r = w * 0.73, base = h * 0.72, spring = h * 0.42, top = h * 0.18;
    final arch = Path()
      ..moveTo(l, base)
      ..lineTo(l, spring)
      ..quadraticBezierTo(l, h * 0.26, w / 2, top)
      ..quadraticBezierTo(r, h * 0.26, r, spring)
      ..lineTo(r, base);
    canvas.drawPath(arch, stroke);
    // Fringe.
    final fringe = Paint()
      ..color = color
      ..strokeWidth = math.max(1, w * 0.07)
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 4; i++) {
      final x = w * (0.2 + i * 0.2);
      canvas.drawLine(Offset(x, h * 0.88), Offset(x, h * 0.98), fringe);
    }
  }

  @override
  bool shouldRepaint(_MusallaPainter old) => old.color != color;
}

/// A crescent and star, for headers and empty states.
class CrescentIcon extends StatelessWidget {
  const CrescentIcon({super.key, this.size = 18, this.color = Colors.white});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => CustomPaint(size: Size.square(size), painter: _CrescentPainter(color));
}

class _CrescentPainter extends CustomPainter {
  _CrescentPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size s) {
    final r = s.width * 0.42;
    final c = Offset(s.width * 0.45, s.height / 2);
    final moon = Path.combine(
      PathOperation.difference,
      Path()..addOval(Rect.fromCircle(center: c, radius: r)),
      Path()..addOval(Rect.fromCircle(center: c.translate(r * 0.45, -r * 0.12), radius: r * 0.85)),
    );
    final p = Paint()..color = color;
    canvas.drawPath(moon, p);
    // Five-point star.
    final sc = Offset(s.width * 0.8, s.height * 0.42), sr = s.width * 0.13;
    final star = Path();
    for (var i = 0; i < 10; i++) {
      final a = -math.pi / 2 + i * math.pi / 5;
      final rr = i.isEven ? sr : sr * 0.45;
      final pt = sc + Offset(math.cos(a) * rr, math.sin(a) * rr);
      i == 0 ? star.moveTo(pt.dx, pt.dy) : star.lineTo(pt.dx, pt.dy);
    }
    canvas.drawPath(star..close(), p);
  }

  @override
  bool shouldRepaint(_CrescentPainter old) => old.color != color;
}
