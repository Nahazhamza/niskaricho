// Educational vector illustrations for Salah postures & Wudu steps.
// Features a worshiper wearing a white prayer cap (Taqiyah) and white thobe (jubba)
// performing each position on a prayer mat, with clear anatomical details and
// realistic side-profile postures (e.g. horizontal back for Ruku' with hands on knees).

import 'dart:math' as math;
import 'package:material_ui/material_ui.dart';

import '../models/learn_namaz_model.dart';
import '../theme/app_theme.dart';

// ---------------------------------------------------------------------------
// SALAH POSTURE ILLUSTRATION
// ---------------------------------------------------------------------------
class SalahPostureIllustration extends StatelessWidget {
  const SalahPostureIllustration({
    super.key,
    required this.position,
    this.size = 200,
    this.primaryColor = AppColors.emerald,
    this.accentColor = AppColors.cyan,
  });

  final SalahPosition position;
  final double size;
  final Color primaryColor;
  final Color accentColor;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        colors: [
          const Color(0xFF0F3D32).withValues(alpha: 0.6),
          const Color(0xFF061A16).withValues(alpha: 0.8),
          const Color(0xFF030D0C),
        ],
        stops: const [0.0, 0.7, 1.0],
      ),
      border: Border.all(color: primaryColor.withValues(alpha: 0.4), width: 1.8),
      boxShadow: [
        BoxShadow(
          color: primaryColor.withValues(alpha: 0.2),
          blurRadius: 28,
          spreadRadius: 2,
        ),
      ],
    ),
    child: ClipOval(
      child: CustomPaint(
        size: Size.square(size),
        painter: _RealisticSalahPainter(position: position),
      ),
    ),
  );
}

class _RealisticSalahPainter extends CustomPainter {
  _RealisticSalahPainter({required this.position});

  final SalahPosition position;

  static const skinColor = Color(0xFFF0BA9D);
  static const hairColor = Color(0xFF1E293B);
  static const thobeColor = Color(0xFFF8FAFC);
  static const thobeShadow = Color(0xFFCBD5E1);
  static const capColor = Color(0xFFFFFFFF);
  static const matGreen = Color(0xFF0D5C46);
  static const matAccent = Color(0xFF168063);
  static const matFringe = Color(0xFFD4A84B);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final groundY = h * 0.84;

    _drawPrayerMat(canvas, w, h, groundY);

    switch (position) {
      case SalahPosition.niyyah:
      case SalahPosition.qiyam:
        _drawQiyam(canvas, w, h, groundY);
        break;
      case SalahPosition.takbir:
        _drawTakbir(canvas, w, h, groundY);
        break;
      case SalahPosition.ruku:
        _drawRuku(canvas, w, h, groundY);
        break;
      case SalahPosition.itidal:
        _drawItidal(canvas, w, h, groundY);
        break;
      case SalahPosition.sujood1:
      case SalahPosition.sujood2:
        _drawSujood(canvas, w, h, groundY);
        break;
      case SalahPosition.jalsah:
        _drawJalsah(canvas, w, h, groundY);
        break;
      case SalahPosition.tashahhudFirst:
      case SalahPosition.tashahhudFinal:
        _drawTashahhud(canvas, w, h, groundY);
        break;
      case SalahPosition.salawat:
      case SalahPosition.dua:
        _drawDua(canvas, w, h, groundY);
        break;
      case SalahPosition.tasleem:
        _drawTasleem(canvas, w, h, groundY);
        break;
    }
  }

  void _drawPrayerMat(Canvas canvas, double w, double h, double groundY) {
    final matLeft = w * 0.08;
    final matRight = w * 0.92;
    final matTop = groundY - 4;
    final matBottom = groundY + 8;

    // Mat base
    final matRect = RRect.fromRectAndRadius(
      Rect.fromLTRB(matLeft, matTop, matRight, matBottom),
      const Radius.circular(3),
    );
    canvas.drawRRect(matRect, Paint()..color = matGreen);

    // Inner arch / mihrab strip on the mat
    final innerPaint = Paint()
      ..color = matAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawLine(Offset(matLeft + 6, matTop + 4), Offset(matRight - 6, matTop + 4), innerPaint);

    // Fringe on sides
    final fringePaint = Paint()
      ..color = matFringe
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 6; i++) {
      final y = matTop + (i * 2);
      canvas.drawLine(Offset(matLeft - 3, y), Offset(matLeft, y), fringePaint);
      canvas.drawLine(Offset(matRight, y), Offset(matRight + 3, y), fringePaint);
    }
  }

  void _drawHeadWithCap(Canvas canvas, Offset center, double radius, {double tiltAngle = 0}) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(tiltAngle);

    // Face / skin
    final facePaint = Paint()..color = skinColor;
    canvas.drawCircle(Offset.zero, radius, facePaint);

    // Hair at the back/bottom
    final hairPaint = Paint()..color = hairColor;
    final hairPath = Path()
      ..moveTo(radius * 0.3, radius * 0.2)
      ..quadraticBezierTo(radius * 0.9, radius * 0.5, radius * 0.6, radius * 0.9)
      ..lineTo(radius * 0.1, radius * 0.9)
      ..close();
    canvas.drawPath(hairPath, hairPaint);

    // Prayer cap (Taqiyah/Kufi) covering the top & front of head
    final capPaint = Paint()..color = capColor;
    final capShadowPaint = Paint()
      ..color = thobeShadow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final capPath = Path()
      ..moveTo(-radius * 0.85, 0)
      ..quadraticBezierTo(-radius * 0.9, -radius * 1.1, 0, -radius * 1.1)
      ..quadraticBezierTo(radius * 0.9, -radius * 1.1, radius * 0.85, 0)
      ..quadraticBezierTo(0, -radius * 0.2, -radius * 0.85, 0);

    canvas.drawPath(capPath, capPaint);
    canvas.drawPath(capPath, capShadowPaint);

    // Cap dome highlight
    final domeRim = Path()
      ..moveTo(-radius * 0.8, -radius * 0.1)
      ..quadraticBezierTo(0, -radius * 0.35, radius * 0.8, -radius * 0.1);
    canvas.drawPath(domeRim, Paint()..color = const Color(0xFFE2E8F0)..style = PaintingStyle.stroke..strokeWidth = 1.5);

    // Modest eye looking down
    final eyePaint = Paint()
      ..color = hairColor
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(-radius * 0.35, radius * 0.1), Offset(-radius * 0.15, radius * 0.2), eyePaint);

    canvas.restore();
  }

  void _drawQiyam(Canvas canvas, double w, double h, double groundY) {
    final cx = w * 0.52;

    // Feet
    final footPaint = Paint()..color = skinColor;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - 18, groundY - 6, 26, 7), const Radius.circular(3)), footPaint);

    // Lower thobe / legs
    final thobePaint = Paint()..color = thobeColor;
    final shadowPaint = Paint()..color = thobeShadow;

    final skirtPath = Path()
      ..moveTo(cx - 20, groundY - 6)
      ..lineTo(cx - 14, h * 0.46)
      ..lineTo(cx + 12, h * 0.46)
      ..lineTo(cx + 18, groundY - 6)
      ..close();
    canvas.drawPath(skirtPath, thobePaint);
    canvas.drawPath(
      Path()
        ..moveTo(cx + 12, h * 0.46)
        ..lineTo(cx + 18, groundY - 6)
        ..lineTo(cx + 10, groundY - 6)
        ..close(),
      shadowPaint,
    );

    // Torso (white thobe)
    final torsoPath = Path()
      ..moveTo(cx - 15, h * 0.46)
      ..lineTo(cx - 13, h * 0.26)
      ..lineTo(cx + 13, h * 0.26)
      ..lineTo(cx + 14, h * 0.46)
      ..close();
    canvas.drawPath(torsoPath, thobePaint);

    // Folded arms on chest (right hand grasping left forearm/wrist)
    final sleevePaint = Paint()..color = thobeColor;
    final armOutline = Paint()
      ..color = thobeShadow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final leftArm = Path()
      ..moveTo(cx + 12, h * 0.28)
      ..quadraticBezierTo(cx + 16, h * 0.36, cx - 2, h * 0.38)
      ..lineTo(cx - 10, h * 0.36);
    canvas.drawPath(leftArm, sleevePaint);
    canvas.drawPath(leftArm, armOutline);

    final rightArm = Path()
      ..moveTo(cx - 12, h * 0.28)
      ..quadraticBezierTo(cx - 16, h * 0.36, cx + 4, h * 0.37)
      ..lineTo(cx + 8, h * 0.35);
    canvas.drawPath(rightArm, sleevePaint);
    canvas.drawPath(rightArm, armOutline);

    // Hands clasped over lower chest
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - 6, h * 0.35, 14, 7), const Radius.circular(3)), footPaint);

    // Head with Taqiyah looking down
    _drawHeadWithCap(canvas, Offset(cx - 2, h * 0.18), w * 0.08, tiltAngle: -0.15);
  }

  void _drawTakbir(Canvas canvas, double w, double h, double groundY) {
    final cx = w * 0.5;

    // Feet
    final footPaint = Paint()..color = skinColor;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - 14, groundY - 6, 28, 7), const Radius.circular(3)), footPaint);

    // Thobe
    final thobePaint = Paint()..color = thobeColor;
    final shadowPaint = Paint()..color = thobeShadow;

    final body = Path()
      ..moveTo(cx - 18, groundY - 6)
      ..lineTo(cx - 13, h * 0.28)
      ..lineTo(cx + 13, h * 0.28)
      ..lineTo(cx + 18, groundY - 6)
      ..close();
    canvas.drawPath(body, thobePaint);
    canvas.drawPath(Path()..moveTo(cx + 13, h * 0.28)..lineTo(cx + 18, groundY - 6)..lineTo(cx + 11, groundY - 6)..close(), shadowPaint);

    // Raised arms up to ear/shoulder level
    final armStroke = Paint()
      ..color = thobeColor
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final armBorder = Paint()
      ..color = thobeShadow
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Left raised arm
    final leftArm = Path()..moveTo(cx - 11, h * 0.30)..lineTo(cx - 24, h * 0.24)..lineTo(cx - 22, h * 0.14);
    canvas.drawPath(leftArm, armStroke);
    canvas.drawPath(leftArm, armBorder);

    // Right raised arm
    final rightArm = Path()..moveTo(cx + 11, h * 0.30)..lineTo(cx + 24, h * 0.24)..lineTo(cx + 22, h * 0.14);
    canvas.drawPath(rightArm, armStroke);
    canvas.drawPath(rightArm, armBorder);

    // Open palms facing Qibla
    canvas.drawCircle(Offset(cx - 22, h * 0.13), 5.5, footPaint);
    canvas.drawCircle(Offset(cx + 22, h * 0.13), 5.5, footPaint);

    // Head
    _drawHeadWithCap(canvas, Offset(cx, h * 0.19), w * 0.08);
  }

  void _drawRuku(Canvas canvas, double w, double h, double groundY) {
    // Exactly matches the user's uploaded reference: side view with straight horizontal back
    final hip = Offset(w * 0.68, h * 0.44);
    final shoulder = Offset(w * 0.36, h * 0.44);
    final knee = Offset(w * 0.65, h * 0.64);
    final foot = Offset(w * 0.66, groundY - 6);

    final skinPaint = Paint()..color = skinColor;
    final thobePaint = Paint()..color = thobeColor;
    final shadowPaint = Paint()..color = thobeShadow;

    // Feet flat on mat
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(foot.dx - 14, groundY - 6, 22, 6), const Radius.circular(3)), skinPaint);

    // Straight legs with thobe drape
    final legPath = Path()
      ..moveTo(hip.dx + 4, hip.dy)
      ..lineTo(knee.dx + 6, knee.dy)
      ..lineTo(foot.dx + 6, groundY - 6)
      ..lineTo(foot.dx - 8, groundY - 6)
      ..lineTo(knee.dx - 6, knee.dy)
      ..lineTo(hip.dx - 8, hip.dy)
      ..close();
    canvas.drawPath(legPath, thobePaint);
    canvas.drawPath(Path()..moveTo(knee.dx + 6, knee.dy)..lineTo(foot.dx + 6, groundY - 6)..lineTo(foot.dx + 1, groundY - 6)..lineTo(knee.dx + 1, knee.dy)..close(), shadowPaint);

    // Horizontal straight back (Thobe torso)
    final backPath = Path()
      ..moveTo(hip.dx + 5, hip.dy)
      ..lineTo(shoulder.dx - 2, shoulder.dy)
      ..lineTo(shoulder.dx + 2, shoulder.dy + 16)
      ..lineTo(hip.dx - 6, hip.dy + 12)
      ..close();
    canvas.drawPath(backPath, thobePaint);

    // Alignment guide ray along the 90° straight back
    final alignRay = Paint()
      ..color = AppColors.gold.withValues(alpha: 0.6)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(shoulder.dx - 12, shoulder.dy - 3), Offset(hip.dx + 12, hip.dy - 3), alignRay);

    // Arm stretching down to knee
    final armPath = Path()
      ..moveTo(shoulder.dx + 4, shoulder.dy + 8)
      ..lineTo(knee.dx - 8, knee.dy - 4);
    final armStroke = Paint()
      ..color = thobeColor
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(armPath, armStroke);
    canvas.drawPath(armPath, Paint()..color = thobeShadow..strokeWidth = 1.5..style = PaintingStyle.stroke);

    // Hand firmly grasping knee with spread fingers (detailed)
    final handCenter = Offset(knee.dx - 8, knee.dy - 2);
    canvas.drawCircle(handCenter, 6, skinPaint);
    // Finger grasp
    final fingerPaint = Paint()
      ..color = skinColor
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(handCenter, handCenter + const Offset(4, 4), fingerPaint);
    canvas.drawLine(handCenter, handCenter + const Offset(1, 5), fingerPaint);

    // Head aligned with back (in line with horizontal spine, wearing white cap)
    _drawHeadWithCap(canvas, Offset(shoulder.dx - 12, shoulder.dy + 4), w * 0.075, tiltAngle: -0.4);
  }

  void _drawItidal(Canvas canvas, double w, double h, double groundY) {
    // Standing completely upright with hands resting calmly by sides
    final cx = w * 0.5;
    final footPaint = Paint()..color = skinColor;
    final thobePaint = Paint()..color = thobeColor;
    final shadowPaint = Paint()..color = thobeShadow;

    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - 16, groundY - 6, 26, 7), const Radius.circular(3)), footPaint);

    final body = Path()
      ..moveTo(cx - 16, groundY - 6)
      ..lineTo(cx - 12, h * 0.26)
      ..lineTo(cx + 12, h * 0.26)
      ..lineTo(cx + 16, groundY - 6)
      ..close();
    canvas.drawPath(body, thobePaint);
    canvas.drawPath(Path()..moveTo(cx + 12, h * 0.26)..lineTo(cx + 16, groundY - 6)..lineTo(cx + 10, groundY - 6)..close(), shadowPaint);

    // Relaxed straight arms at sides
    final armPaint = Paint()
      ..color = thobeColor
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(cx - 12, h * 0.28), Offset(cx - 15, h * 0.48), armPaint);
    canvas.drawLine(Offset(cx + 12, h * 0.28), Offset(cx + 15, h * 0.48), armPaint);

    canvas.drawCircle(Offset(cx - 15, h * 0.50), 4, footPaint);
    canvas.drawCircle(Offset(cx + 15, h * 0.50), 4, footPaint);

    // Head upright
    _drawHeadWithCap(canvas, Offset(cx, h * 0.18), w * 0.08);
  }

  void _drawSujood(Canvas canvas, double w, double h, double groundY) {
    // Prostrating: forehead, palms, knees, toes touching mat; elbows elevated
    final skinPaint = Paint()..color = skinColor;
    final thobePaint = Paint()..color = thobeColor;
    final shadowPaint = Paint()..color = thobeShadow;

    final kneeX = w * 0.65;
    final toeX = w * 0.82;
    final headX = w * 0.25;
    final palmX = w * 0.35;

    // Toes tucked touching ground
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(toeX - 4, groundY - 6, 10, 6), const Radius.circular(2)), skinPaint);

    // Knees touching ground
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(kneeX - 6, groundY - 8, 14, 8), const Radius.circular(4)), thobePaint);

    // Curved arched back with thobe
    final body = Path()
      ..moveTo(toeX, groundY - 4)
      ..lineTo(kneeX, groundY - 4)
      ..quadraticBezierTo(w * 0.58, h * 0.42, w * 0.42, h * 0.54)
      ..lineTo(headX + 16, groundY - 4)
      ..lineTo(toeX, groundY - 4)
      ..close();
    canvas.drawPath(body, thobePaint);
    canvas.drawPath(
      Path()
        ..moveTo(kneeX, groundY - 4)
        ..quadraticBezierTo(w * 0.58, h * 0.42, w * 0.50, h * 0.46)
        ..lineTo(kneeX + 4, groundY - 4)
        ..close(),
      shadowPaint,
    );

    // Arm with ELEVATED ELBOW (not flat on floor)
    final elbow = Offset(w * 0.40, h * 0.60);
    final armPath = Path()
      ..moveTo(w * 0.42, h * 0.54)
      ..lineTo(elbow.dx, elbow.dy)
      ..lineTo(palmX, groundY - 3);
    final armStroke = Paint()
      ..color = thobeColor
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(armPath, armStroke);
    canvas.drawPath(armPath, Paint()..color = thobeShadow..strokeWidth = 1.5..style = PaintingStyle.stroke);

    // Palm flat beside head
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(palmX - 6, groundY - 4, 12, 4), const Radius.circular(2)), skinPaint);

    // Head with cap prostrating on the mat
    _drawHeadWithCap(canvas, Offset(headX, groundY - 12), w * 0.075, tiltAngle: 1.25);

    // Forehead contact point
    canvas.drawCircle(Offset(headX - 6, groundY - 2), 3, Paint()..color = AppColors.gold);
  }

  void _drawJalsah(Canvas canvas, double w, double h, double groundY) {
    // Sitting upright on feet (Iftirash)
    final cx = w * 0.5;
    final skinPaint = Paint()..color = skinColor;
    final thobePaint = Paint()..color = thobeColor;
    final shadowPaint = Paint()..color = thobeShadow;

    // Legs folded on ground
    final lap = Path()
      ..moveTo(cx - 24, groundY - 4)
      ..lineTo(cx - 18, h * 0.58)
      ..lineTo(cx + 20, h * 0.58)
      ..lineTo(cx + 26, groundY - 4)
      ..close();
    canvas.drawPath(lap, thobePaint);

    // Torso sitting upright
    final torso = Path()
      ..moveTo(cx - 15, h * 0.58)
      ..lineTo(cx - 12, h * 0.35)
      ..lineTo(cx + 12, h * 0.35)
      ..lineTo(cx + 15, h * 0.58)
      ..close();
    canvas.drawPath(torso, thobePaint);
    canvas.drawPath(Path()..moveTo(cx + 12, h * 0.35)..lineTo(cx + 15, h * 0.58)..lineTo(cx + 8, h * 0.58)..close(), shadowPaint);

    // Arms resting on thighs
    final armPaint = Paint()
      ..color = thobeColor
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(cx - 11, h * 0.37), Offset(cx - 16, h * 0.56), armPaint);
    canvas.drawLine(Offset(cx + 11, h * 0.37), Offset(cx + 16, h * 0.56), armPaint);

    // Flat hands on knees
    canvas.drawCircle(Offset(cx - 16, h * 0.57), 5, skinPaint);
    canvas.drawCircle(Offset(cx + 16, h * 0.57), 5, skinPaint);

    // Head
    _drawHeadWithCap(canvas, Offset(cx, h * 0.25), w * 0.08, tiltAngle: -0.1);
  }

  void _drawTashahhud(Canvas canvas, double w, double h, double groundY) {
    // Sitting in Tashahhud with RIGHT INDEX FINGER RAISED
    _drawJalsah(canvas, w, h, groundY);

    final cx = w * 0.5;
    final skinPaint = Paint()..color = skinColor;

    // Overwrite right hand with a raised index finger
    final handPos = Offset(cx - 16, h * 0.56);
    canvas.drawCircle(handPos, 5, skinPaint);

    // Raised index finger pointing forward/up
    final fingerPaint = Paint()
      ..color = skinColor
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    final fingerTip = handPos + const Offset(-6, -10);
    canvas.drawLine(handPos, fingerTip, fingerPaint);

    // Subtle golden glow around the raised finger
    canvas.drawCircle(
      fingerTip,
      4,
      Paint()
        ..color = AppColors.gold.withValues(alpha: 0.7)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawCircle(fingerTip, 2, Paint()..color = AppColors.gold);
  }

  void _drawDua(Canvas canvas, double w, double h, double groundY) {
    _drawJalsah(canvas, w, h, groundY);
    final cx = w * 0.5;
    final skinPaint = Paint()..color = skinColor;

    // Cupped hands raised in supplication
    canvas.drawCircle(Offset(cx - 4, h * 0.47), 5, skinPaint);
    canvas.drawCircle(Offset(cx + 4, h * 0.47), 5, skinPaint);
  }

  void _drawTasleem(Canvas canvas, double w, double h, double groundY) {
    // Sitting on mat, head turned to the right shoulder
    final cx = w * 0.5;
    final thobePaint = Paint()..color = thobeColor;
    final footPaint = Paint()..color = skinColor;

    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - 24, groundY - 4, 48, 6), const Radius.circular(3)), footPaint);

    final body = Path()
      ..moveTo(cx - 22, groundY - 4)
      ..lineTo(cx - 14, h * 0.35)
      ..lineTo(cx + 14, h * 0.35)
      ..lineTo(cx + 22, groundY - 4)
      ..close();
    canvas.drawPath(body, thobePaint);

    // Head turned to the right
    _drawHeadWithCap(canvas, Offset(cx + 6, h * 0.25), w * 0.08, tiltAngle: 0.3);

    // Golden peace greeting ray to the right
    final rayPaint = Paint()
      ..color = AppColors.gold.withValues(alpha: 0.8)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(cx + 16, h * 0.25), Offset(cx + 36, h * 0.22), rayPaint);
    canvas.drawCircle(Offset(cx + 36, h * 0.22), 3, Paint()..color = AppColors.gold);
  }

  @override
  bool shouldRepaint(_RealisticSalahPainter old) => old.position != position;
}

// ---------------------------------------------------------------------------
// WUDU STEP ILLUSTRATION
// ---------------------------------------------------------------------------
class WuduStepIllustration extends StatelessWidget {
  const WuduStepIllustration({
    super.key,
    required this.stepNumber,
    this.size = 200,
    this.primaryColor = AppColors.cyan,
  });

  final int stepNumber;
  final double size;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        colors: [
          const Color(0xFF0C333D).withValues(alpha: 0.7),
          const Color(0xFF041820).withValues(alpha: 0.85),
          const Color(0xFF020C10),
        ],
        stops: const [0.0, 0.7, 1.0],
      ),
      border: Border.all(color: primaryColor.withValues(alpha: 0.45), width: 1.8),
      boxShadow: [
        BoxShadow(
          color: primaryColor.withValues(alpha: 0.2),
          blurRadius: 28,
          spreadRadius: 2,
        ),
      ],
    ),
    child: ClipOval(
      child: CustomPaint(
        size: Size.square(size),
        painter: _RealisticWuduPainter(stepNumber: stepNumber, waterColor: primaryColor),
      ),
    ),
  );
}

class _RealisticWuduPainter extends CustomPainter {
  _RealisticWuduPainter({required this.stepNumber, required this.waterColor});

  final int stepNumber;
  final Color waterColor;

  static const skinColor = Color(0xFFF0BA9D);
  static const capColor = Color(0xFFFFFFFF);
  static const hairColor = Color(0xFF1E293B);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final c = Offset(w / 2, h / 2);

    switch (stepNumber) {
      case 1:
        // Niyyah: spiritual intention in heart
        _drawNiyyah(canvas, w, h, c);
        break;
      case 2:
        // Bismillah: water tap and blessing
        _drawBismillah(canvas, w, h, c);
        break;
      case 3:
        // Wash hands to wrists with fingers interlaced
        _drawWashHands(canvas, w, h, c);
        break;
      case 4:
        // Rinse mouth (Madmadah)
        _drawRinseMouth(canvas, w, h, c);
        break;
      case 5:
        // Clean nose (Istinshaq & Istinthar)
        _drawCleanNose(canvas, w, h, c);
        break;
      case 6:
        // Wash face from hairline to chin & ear to ear
        _drawWashFace(canvas, w, h, c);
        break;
      case 7:
        // Wash right arm including elbow
        _drawWashArm(canvas, w, h, c, isRight: true);
        break;
      case 8:
        // Wash left arm including elbow
        _drawWashArm(canvas, w, h, c, isRight: false);
        break;
      case 9:
        // Wipe head (Mash)
        _drawWipeHead(canvas, w, h, c);
        break;
      case 10:
        // Wipe ears (both index fingers and thumbs)
        _drawWipeEars(canvas, w, h, c);
        break;
      case 11:
        // Wash right foot to ankle
        _drawWashFoot(canvas, w, h, c, isRight: true);
        break;
      case 12:
        // Wash left foot to ankle
        _drawWashFoot(canvas, w, h, c, isRight: false);
        break;
      default:
        canvas.drawCircle(c, w * 0.25, Paint()..color = waterColor);
    }
  }

  void _drawWaterDrop(Canvas canvas, Offset pos, double radius) {
    final dropPath = Path()
      ..moveTo(pos.dx, pos.dy - radius * 1.5)
      ..quadraticBezierTo(pos.dx + radius, pos.dy, pos.dx, pos.dy + radius)
      ..quadraticBezierTo(pos.dx - radius, pos.dy, pos.dx, pos.dy - radius * 1.5)
      ..close();
    canvas.drawPath(dropPath, Paint()..color = waterColor);
  }

  void _drawNiyyah(Canvas canvas, double w, double h, Offset c) {
    // Serene chest & heart radiating spiritual intention
    final heartGlow = Paint()
      ..color = AppColors.gold.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    canvas.drawCircle(c, w * 0.28, heartGlow);

    // Glowing heart symbol
    final heartPath = Path()
      ..moveTo(c.dx, c.dy + w * 0.16)
      ..cubicTo(c.dx - w * 0.25, c.dy - 0.05 * w, c.dx - w * 0.18, c.dy - w * 0.22, c.dx, c.dy - w * 0.08)
      ..cubicTo(c.dx + w * 0.18, c.dy - w * 0.22, c.dx + w * 0.25, c.dy - 0.05 * w, c.dx, c.dy + w * 0.16)
      ..close();
    canvas.drawPath(heartPath, Paint()..color = AppColors.gold);
    canvas.drawPath(heartPath, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2);

    // Rays
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      final p1 = c + Offset(math.cos(a) * w * 0.28, math.sin(a) * w * 0.28);
      final p2 = c + Offset(math.cos(a) * w * 0.36, math.sin(a) * w * 0.36);
      canvas.drawLine(p1, p2, Paint()..color = AppColors.gold..strokeWidth = 1.5..strokeCap = StrokeCap.round);
    }
  }

  void _drawBismillah(Canvas canvas, double w, double h, Offset c) {
    // Water tap pouring pure stream
    final tapPaint = Paint()..color = const Color(0xFF94A3B8)..strokeWidth = 7..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(c.dx - 40, h * 0.26), Offset(c.dx, h * 0.26), tapPaint);
    canvas.drawLine(Offset(c.dx, h * 0.26), Offset(c.dx, h * 0.34), tapPaint);

    // Water flow
    final waterFlow = Paint()..color = waterColor..strokeWidth = 8..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(c.dx, h * 0.34), Offset(c.dx, h * 0.62), waterFlow);

    // Cupped hands beneath water
    _drawCuppedHands(canvas, c.dx, h * 0.64);

    _drawWaterDrop(canvas, Offset(c.dx - 18, h * 0.48), 5);
    _drawWaterDrop(canvas, Offset(c.dx + 18, h * 0.52), 6);
  }

  void _drawCuppedHands(Canvas canvas, double cx, double cy) {
    final skinPaint = Paint()..color = skinColor;
    final strokePaint = Paint()..color = const Color(0xFFD69A7E)..style = PaintingStyle.stroke..strokeWidth = 1.5;

    final leftPalm = Path()
      ..moveTo(cx - 30, cy + 18)
      ..lineTo(cx - 24, cy - 6)
      ..lineTo(cx - 4, cy + 6)
      ..lineTo(cx - 10, cy + 24)
      ..close();
    canvas.drawPath(leftPalm, skinPaint);
    canvas.drawPath(leftPalm, strokePaint);

    final rightPalm = Path()
      ..moveTo(cx + 30, cy + 18)
      ..lineTo(cx + 24, cy - 6)
      ..lineTo(cx + 4, cy + 6)
      ..lineTo(cx + 10, cy + 24)
      ..close();
    canvas.drawPath(rightPalm, skinPaint);
    canvas.drawPath(rightPalm, strokePaint);
  }

  void _drawWashHands(Canvas canvas, double w, double h, Offset c) {
    final skinPaint = Paint()..color = skinColor;
    final borderPaint = Paint()..color = const Color(0xFFD69A7E)..style = PaintingStyle.stroke..strokeWidth = 1.8;

    // Left hand meeting right hand with fingers interlacing
    // Wrists
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(c.dx - 60, c.dy + 12, 34, 18), const Radius.circular(5)), skinPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(c.dx + 26, c.dy + 12, 34, 18), const Radius.circular(5)), skinPaint);

    // Wrist water line highlight
    final wristLine = Paint()..color = waterColor..strokeWidth = 2.5..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(c.dx - 54, c.dy + 10), Offset(c.dx - 54, c.dy + 32), wristLine);
    canvas.drawLine(Offset(c.dx + 54, c.dy + 10), Offset(c.dx + 54, c.dy + 32), wristLine);

    // Two palms rubbing together
    final palms = Path()
      ..moveTo(c.dx - 30, c.dy + 20)
      ..lineTo(c.dx - 18, c.dy - 12)
      ..lineTo(c.dx, c.dy - 22)
      ..lineTo(c.dx + 18, c.dy - 12)
      ..lineTo(c.dx + 30, c.dy + 20)
      ..close();
    canvas.drawPath(palms, skinPaint);
    canvas.drawPath(palms, borderPaint);

    // Distinct interlaced fingers
    final fingerPaint = Paint()..color = const Color(0xFFD69A7E)..strokeWidth = 2..strokeCap = StrokeCap.round;
    for (var i = -2; i <= 2; i++) {
      canvas.drawLine(Offset(c.dx + (i * 7), c.dy - 18), Offset(c.dx + (i * 7), c.dy + 6), fingerPaint);
    }

    // Water splashing around fingers and wrists
    _drawWaterDrop(canvas, Offset(c.dx - 14, c.dy - 26), 5);
    _drawWaterDrop(canvas, Offset(c.dx + 14, c.dy - 26), 5);
    _drawWaterDrop(canvas, Offset(c.dx, c.dy + 16), 6);
  }

  void _drawRinseMouth(Canvas canvas, double w, double h, Offset c) {
    // Profile of face with water cup reaching mouth
    final skinPaint = Paint()..color = skinColor;
    final hairPaint = Paint()..color = hairColor;
    final capPaint = Paint()..color = capColor;

    // Face profile
    final face = Path()
      ..moveTo(c.dx + 20, h * 0.18)
      ..lineTo(c.dx + 6, h * 0.36) // nose
      ..lineTo(c.dx + 10, h * 0.45) // upper lip
      ..lineTo(c.dx + 6, h * 0.48) // mouth opening
      ..lineTo(c.dx + 12, h * 0.58) // chin
      ..lineTo(c.dx + 36, h * 0.65) // jaw
      ..lineTo(c.dx + 44, h * 0.22)
      ..close();
    canvas.drawPath(face, skinPaint);

    // Cap on head
    final cap = Path()
      ..moveTo(c.dx + 10, h * 0.22)
      ..quadraticBezierTo(c.dx + 30, h * 0.12, c.dx + 48, h * 0.20)
      ..close();
    canvas.drawPath(cap, capPaint);
    canvas.drawCircle(Offset(c.dx + 36, h * 0.26), 8, hairPaint);

    // Hand bringing water stream into mouth
    final hand = Path()
      ..moveTo(c.dx - 32, h * 0.68)
      ..lineTo(c.dx - 12, h * 0.48)
      ..lineTo(c.dx + 4, h * 0.48);
    canvas.drawPath(hand, Paint()..color = skinColor..strokeWidth = 9..strokeCap = StrokeCap.round..style = PaintingStyle.stroke);

    // Water stream swirling into mouth
    final waterSwirl = Paint()..color = waterColor..strokeWidth = 3.5..strokeCap = StrokeCap.round..style = PaintingStyle.stroke;
    canvas.drawArc(Rect.fromCircle(center: Offset(c.dx + 2, h * 0.48), radius: 10), 0, 4.5, false, waterSwirl);
    _drawWaterDrop(canvas, Offset(c.dx - 6, h * 0.44), 4.5);
  }

  void _drawCleanNose(Canvas canvas, double w, double h, Offset c) {
    // Face profile with water reaching nostrils
    _drawRinseMouth(canvas, w, h, c);

    // Inhaling water droplets into nostril
    final nostril = Offset(c.dx + 6, h * 0.38);
    canvas.drawCircle(nostril, 3.5, Paint()..color = const Color(0xFFD69A7E));

    // Water stream to nose
    final waterStream = Paint()..color = waterColor..strokeWidth = 3..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(c.dx - 8, h * 0.46), nostril, waterStream);
    _drawWaterDrop(canvas, Offset(c.dx - 2, h * 0.42), 4.5);
  }

  void _drawWashFace(Canvas canvas, double w, double h, Offset c) {
    final skinPaint = Paint()..color = skinColor;
    final capPaint = Paint()..color = capColor;
    final borderPaint = Paint()..color = const Color(0xFFD69A7E)..style = PaintingStyle.stroke..strokeWidth = 1.5;

    // Full front face oval
    final faceOval = Rect.fromCenter(center: Offset(c.dx, c.dy + 8), width: w * 0.48, height: h * 0.54);
    canvas.drawOval(faceOval, skinPaint);
    canvas.drawOval(faceOval, borderPaint);

    // White Taqiyah at top of face
    final capRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(c.dx - w * 0.24, c.dy - h * 0.26, w * 0.48, h * 0.18),
      const Radius.circular(16),
    );
    canvas.drawRRect(capRect, capPaint);
    canvas.drawRRect(capRect, borderPaint);

    // Hands cupping sides of face washing downwards
    final handPaint = Paint()..color = skinColor;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(c.dx - w * 0.32, c.dy - 10, 16, 46), const Radius.circular(8)), handPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(c.dx + w * 0.22, c.dy - 10, 16, 46), const Radius.circular(8)), handPaint);

    // Water sheen washing over face
    final waterSheen = Paint()
      ..color = waterColor.withValues(alpha: 0.5)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    for (var i = -2; i <= 2; i++) {
      final x = c.dx + (i * 14);
      canvas.drawLine(Offset(x, c.dy - 16), Offset(x, c.dy + 28), waterSheen);
    }
    _drawWaterDrop(canvas, Offset(c.dx, c.dy + 38), 6);
  }

  void _drawWashArm(Canvas canvas, double w, double h, Offset c, {required bool isRight}) {
    final skinPaint = Paint()..color = skinColor;
    final strokePaint = Paint()..color = const Color(0xFFD69A7E)..style = PaintingStyle.stroke..strokeWidth = 1.8;

    final handX = isRight ? c.dx - 48 : c.dx + 48;
    final elbowX = isRight ? c.dx + 46 : c.dx - 46;
    final elbowY = c.dy - 12;

    // Forearm path up to and including elbow
    final arm = Path()
      ..moveTo(handX, c.dy + 32)
      ..lineTo(handX + (isRight ? 16 : -16), c.dy + 38)
      ..lineTo(elbowX, elbowY + 8)
      ..arcToPoint(Offset(elbowX + (isRight ? 8 : -8), elbowY - 14), radius: const Radius.circular(12))
      ..lineTo(isRight ? c.dx + 24 : c.dx - 24, c.dy - 32)
      ..lineTo(handX, c.dy + 14)
      ..close();
    canvas.drawPath(arm, skinPaint);
    canvas.drawPath(arm, strokePaint);

    // Highlight circle around elbow joint to emphasize the ruling
    final elbowCenter = Offset(elbowX + (isRight ? 4 : -4), elbowY - 4);
    canvas.drawCircle(
      elbowCenter,
      14,
      Paint()
        ..color = AppColors.gold.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawCircle(elbowCenter, 4, Paint()..color = AppColors.gold);

    // Other hand rubbing and washing water along forearm
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(c.dx, c.dy + 4), width: 22, height: 28), const Radius.circular(8)),
      skinPaint,
    );

    // Cascading water streams along arm
    final waterPaint = Paint()..color = waterColor..strokeWidth = 3..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(elbowX, elbowY), Offset(handX + (isRight ? 20 : -20), c.dy + 26), waterPaint);
    _drawWaterDrop(canvas, Offset(elbowX, elbowY + 12), 5);
    _drawWaterDrop(canvas, Offset(c.dx - 10, c.dy + 24), 5.5);
  }

  void _drawWipeHead(Canvas canvas, double w, double h, Offset c) {
    final hairPaint = Paint()..color = hairColor;
    final skinPaint = Paint()..color = skinColor;

    // Head profile
    canvas.drawCircle(c, w * 0.28, hairPaint);
    // Face lower profile
    canvas.drawOval(Rect.fromLTWH(c.dx - w * 0.26, c.dy, w * 0.26, w * 0.28), skinPaint);

    // Both hands passing over hair from forehead to nape of neck
    final handPaint = Paint()
      ..color = skinColor
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final wipeMotion = Path()
      ..moveTo(c.dx - w * 0.24, c.dy - w * 0.18)
      ..quadraticBezierTo(c.dx, c.dy - w * 0.34, c.dx + w * 0.26, c.dy - w * 0.08);
    canvas.drawPath(wipeMotion, handPaint);

    // Water gloss sheen on hair
    final sheen = Paint()
      ..color = waterColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawArc(Rect.fromCircle(center: c, radius: w * 0.29), -math.pi * 0.9, math.pi * 0.8, false, sheen);
    _drawWaterDrop(canvas, Offset(c.dx, c.dy - w * 0.32), 5);
  }

  void _drawWipeEars(Canvas canvas, double w, double h, Offset c) {
    final skinPaint = Paint()..color = skinColor;
    final strokePaint = Paint()..color = const Color(0xFFD69A7E)..style = PaintingStyle.stroke..strokeWidth = 2;

    // Detailed ear
    final ear = Path()
      ..moveTo(c.dx, c.dy + 38)
      ..quadraticBezierTo(c.dx - 28, c.dy + 12, c.dx - 8, c.dy - 34)
      ..quadraticBezierTo(c.dx + 28, c.dy - 38, c.dx + 28, c.dy)
      ..quadraticBezierTo(c.dx + 28, c.dy + 34, c.dx, c.dy + 38)
      ..close();
    canvas.drawPath(ear, skinPaint);
    canvas.drawPath(ear, strokePaint);

    // Ear inner folds
    final innerFolds = Path()
      ..moveTo(c.dx + 6, c.dy - 18)
      ..quadraticBezierTo(c.dx + 16, c.dy, c.dx + 8, c.dy + 16)
      ..lineTo(c.dx, c.dy + 4);
    canvas.drawPath(innerFolds, strokePaint);

    // Index finger wiping inner ear canal
    final indexFinger = Paint()..color = skinColor..strokeWidth = 8..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(c.dx - 32, c.dy), Offset(c.dx + 4, c.dy), indexFinger);

    // Thumb wiping back of ear
    final thumb = Paint()..color = skinColor..strokeWidth = 9..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(c.dx + 38, c.dy + 18), Offset(c.dx + 28, c.dy - 4), thumb);

    _drawWaterDrop(canvas, Offset(c.dx + 4, c.dy - 12), 4.5);
  }

  void _drawWashFoot(Canvas canvas, double w, double h, Offset c, {required bool isRight}) {
    final skinPaint = Paint()..color = skinColor;
    final strokePaint = Paint()..color = const Color(0xFFD69A7E)..style = PaintingStyle.stroke..strokeWidth = 1.8;

    final toeX = isRight ? c.dx + 48 : c.dx - 48;
    final heelX = isRight ? c.dx - 40 : c.dx + 40;
    final ankleX = isRight ? c.dx - 22 : c.dx + 22;
    final ankleY = c.dy - 12;

    // Foot and ankle profile
    final foot = Path()
      ..moveTo(ankleX, c.dy - 42)
      ..lineTo(heelX, c.dy + 16)
      ..quadraticBezierTo(heelX, c.dy + 34, c.dx, c.dy + 34)
      ..lineTo(toeX, c.dy + 34)
      ..quadraticBezierTo(toeX + (isRight ? 12 : -12), c.dy + 26, toeX, c.dy + 18)
      ..lineTo(ankleX + (isRight ? 14 : -14), c.dy - 42)
      ..close();
    canvas.drawPath(foot, skinPaint);
    canvas.drawPath(foot, strokePaint);

    // Distinct toes
    final toeLine = Paint()..color = const Color(0xFFD69A7E)..strokeWidth = 1.5;
    for (var i = 0; i < 4; i++) {
      final x = toeX - (isRight ? (i * 6) : -(i * 6));
      canvas.drawLine(Offset(x, c.dy + 22), Offset(x, c.dy + 34), toeLine);
    }

    // Ankle bone highlight (Ka'b)
    final ankleCircle = Offset(ankleX + (isRight ? -4 : 4), ankleY);
    canvas.drawCircle(
      ankleCircle,
      12,
      Paint()
        ..color = AppColors.gold.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawCircle(ankleCircle, 3.5, Paint()..color = AppColors.gold);

    // Hand washing foot and running fingers between toes
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(toeX - (isRight ? 14 : -14), c.dy + 20), width: 22, height: 16), const Radius.circular(5)),
      skinPaint,
    );

    // Water streaming over ankle and heel
    final waterPaint = Paint()..color = waterColor..strokeWidth = 3..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(ankleX, ankleY - 14), Offset(heelX, c.dy + 32), waterPaint);
    _drawWaterDrop(canvas, Offset(ankleX + 4, ankleY + 8), 5);
    _drawWaterDrop(canvas, Offset(c.dx, c.dy + 36), 5.5);
  }

  @override
  bool shouldRepaint(_RealisticWuduPainter old) =>
      old.stepNumber != stepNumber || old.waterColor != waterColor;
}
