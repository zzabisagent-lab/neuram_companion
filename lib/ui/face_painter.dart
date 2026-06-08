import 'dart:math' as math;
import 'package:flutter/material.dart';

/// valence(-1..1)·arousal(0..1)·social(0..1) → 얼굴 렌더링 (§6).
/// 눈 두 개 + 입. 상태에 따라:
///   valence → 입 곡률(찡그림↔미소), 눈 곡선
///   arousal → 눈 크기·깜빡임·미세 흔들림
///   social  → 처진 눈·작은 움직임
class FacePainter extends CustomPainter {
  final double valence;
  final double arousal;
  final double social;
  final double blinkPhase; // 0..1 깜빡임 위상
  final double jitter;     // 미세 흔들림 오프셋

  const FacePainter({
    required this.valence,
    required this.arousal,
    required this.social,
    this.blinkPhase = 0.0,
    this.jitter = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = math.min(cx, cy) * 0.85;

    // 얼굴 배경
    final bgPaint = Paint()
      ..color = _faceColor()
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), r, bgPaint);

    // 얼굴 외곽선
    final outlinePaint = Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset(cx, cy), r, outlinePaint);

    final eyePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // 눈 크기: arousal↑→크게, 깜빡임 시 납작
    final baseEyeH = r * 0.18;
    final eyeH = _eyeHeight(baseEyeH);
    final eyeW = r * 0.22;
    final eyeY = cy - r * 0.15 + jitter * r * 0.04;

    // 외로움(social↑) → 눈이 처짐(Y축 아래)
    final droopOffset = social * r * 0.08;

    // 왼쪽 눈
    _drawEye(canvas, eyePaint, cx - r * 0.28, eyeY + droopOffset, eyeW, eyeH, valence);
    // 오른쪽 눈
    _drawEye(canvas, eyePaint, cx + r * 0.28, eyeY + droopOffset, eyeW, eyeH, valence);

    // 입
    _drawMouth(canvas, cx, cy + r * 0.28, r * 0.45, valence, arousal);
  }

  double _eyeHeight(double base) {
    // 깜빡임: blinkPhase 0.9..1.0 구간에서 납작
    if (blinkPhase > 0.9) {
      final t = (blinkPhase - 0.9) / 0.1;
      final blink = math.sin(t * math.pi); // 0→1→0
      return base * (1 - blink * 0.9);
    }
    // arousal↑ → 눈 크게
    return base * (0.7 + arousal * 0.6);
  }

  void _drawEye(Canvas canvas, Paint paint, double x, double y,
      double w, double h, double val) {
    // valence↑ → 눈 곡선(위 아치), valence↓ → 찡그린 눈(아래 아치)
    final rect = Rect.fromCenter(center: Offset(x, y), width: w, height: h);
    if (h < 2) {
      // 깜빡임: 선으로
      canvas.drawLine(
        Offset(x - w / 2, y),
        Offset(x + w / 2, y),
        paint..strokeWidth = 2,
      );
    } else {
      canvas.drawOval(rect, paint);
      // 눈 광채 (위치 고정)
      final shinePaint = Paint()..color = Colors.white70;
      canvas.drawCircle(Offset(x - w * 0.15, y - h * 0.2), h * 0.18, shinePaint);
    }
  }

  void _drawMouth(Canvas canvas, double cx, double mouthY,
      double width, double val, double aro) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    // val: -1=찡그림(아치↓), +1=미소(아치↑)
    final curvature = val * width * 0.35;
    final path = Path();
    path.moveTo(cx - width / 2, mouthY);
    path.quadraticBezierTo(cx, mouthY - curvature, cx + width / 2, mouthY);
    canvas.drawPath(path, paint);

    // 각성 높으면 입을 약간 벌림(타원)
    if (aro > 0.6) {
      final openH = (aro - 0.6) * 0.5 * width * 0.3;
      if (openH > 2) {
        final mouthRect = Rect.fromCenter(
            center: Offset(cx, mouthY + openH / 2),
            width: width * 0.4,
            height: openH);
        canvas.drawOval(mouthRect,
            Paint()..color = Colors.black54..style = PaintingStyle.fill);
      }
    }
  }

  Color _faceColor() {
    // valence: -1=어두운 파랑, 0=회색, +1=따뜻한 주황
    final t = (valence + 1) / 2; // 0..1
    final r = (50 + t * 180).round();
    final g = (50 + t * 120).round();
    final b = (200 - t * 100).round();
    final brightness = (0.3 + (1 - arousal) * 0.4).clamp(0.0, 1.0);
    return Color.fromARGB(
      255,
      (r * brightness).round().clamp(0, 255),
      (g * brightness).round().clamp(0, 255),
      (b * brightness).round().clamp(0, 255),
    );
  }

  @override
  bool shouldRepaint(FacePainter old) =>
      old.valence != valence ||
      old.arousal != arousal ||
      old.social != social ||
      old.blinkPhase != blinkPhase ||
      old.jitter != jitter;
}
