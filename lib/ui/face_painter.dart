import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 디크리(Dcrea) 고양이형 얼굴 CustomPainter.
///
/// 모든 표정·색상·움직임은 NeuRAM 상태의 순수 함수 — 임의 연출 없음(설계 원칙 §7).
///
/// 상태 → 외형 매핑 요약:
///   valence(-1..1)  : 기분 나쁨↔좋음 → 입 곡률, 홍채 색(청회↔황금), 얼굴 색온도
///   arousal(0..1)   : 졸림↔흥분  → 눈 크기, 동공 폭, 눈꺼풀 처짐
///   social(0..1)    : 충족↔외로움 → 수염 처짐, 귀 안 핑크, 볼 홍조
///   energy(0..1)    : 허기↔포만  → 얼굴 색 창백↔따뜻함
///   blinkPhase      : 깜빡임 위상
///   breathPhase     : 호흡 위상 (0..2π) → 얼굴 미세 스케일·위치 변화
///   gazeDir(-1..1)  : 시선 방향 (터치 위치 추적)
class FacePainter extends CustomPainter {
  final double valence;
  final double arousal;
  final double social;
  final double energy;
  final double blinkPhase;
  final double breathPhase;
  final Offset gazeDir;

  const FacePainter({
    required this.valence,
    required this.arousal,
    required this.social,
    required this.energy,
    this.blinkPhase = 0.0,
    this.breathPhase = 0.0,
    this.gazeDir = Offset.zero,
  });

  // ── 색상 팔레트 (상태 기반) ────────────────────────────────────

  /// 얼굴 피부: wellbeing에 따라 창백 베이지 → 따뜻한 크림
  Color get _faceColor {
    final w = ((valence + 1) / 2 * 0.55 + energy * 0.30 + (1 - social) * 0.15)
        .clamp(0.0, 1.0);
    return Color.lerp(const Color(0xFFBCAA94), const Color(0xFFFFF2D8), w)!;
  }

  /// 귀 외곽: 에너지/기분에 따라 탁한 황토 → 따뜻한 복숭아
  Color get _earColor {
    final t = ((valence + 1) / 2 * 0.6 + energy * 0.4).clamp(0.0, 1.0);
    return Color.lerp(const Color(0xFFC09070), const Color(0xFFE8A87C), t)!;
  }

  /// 홍채: 슬픔/외로움 → 청회색, 행복/포만 → 황금 호박색
  Color get _irisColor {
    final t = ((valence + 1) / 2 * 0.7 + (1 - social) * 0.3).clamp(0.0, 1.0);
    return Color.lerp(const Color(0xFF607090), const Color(0xFFD4830A), t)!;
  }

  // ── paint 진입점 ──────────────────────────────────────────────

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = math.min(cx, cy) * 0.82;

    // 호흡: 얼굴 크기·위치 미세 변동
    final breathScale = 1.0 + math.sin(breathPhase) * 0.009;
    final faceR = r * breathScale;
    // 얼굴을 약간 아래로 내려 귀 공간 확보
    final fcy = cy + r * 0.042 - math.sin(breathPhase) * r * 0.006;

    _drawGlow(canvas, cx, fcy, faceR);
    _drawEars(canvas, cx, fcy, faceR);
    _drawFaceCircle(canvas, cx, fcy, faceR);
    _drawCheeks(canvas, cx, fcy, faceR);
    _drawEyes(canvas, cx, fcy, faceR);
    _drawNose(canvas, cx, fcy, faceR);
    _drawMouth(canvas, cx, fcy, faceR);
    _drawWhiskers(canvas, cx, fcy, faceR);
  }

  // ── 배경 글로우 ───────────────────────────────────────────────

  void _drawGlow(Canvas canvas, double cx, double cy, double r) {
    final alpha = (0.07 + arousal * 0.09).clamp(0.0, 0.18);
    final color = Color.lerp(
      const Color(0xFF3050A0),
      const Color(0xFFFF9040),
      (valence + 1) / 2,
    )!.withAlpha((alpha * 255).round());
    canvas.drawCircle(Offset(cx, cy), r * 1.38,
        Paint()
          ..color = color
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 26));
  }

  // ── 귀 ───────────────────────────────────────────────────────

  void _drawEars(Canvas canvas, double cx, double cy, double r) {
    _drawSingleEar(canvas, cx, cy, r, isLeft: true);
    _drawSingleEar(canvas, cx, cy, r, isLeft: false);
  }

  void _drawSingleEar(Canvas canvas, double cx, double cy, double r,
      {required bool isLeft}) {
    final s = isLeft ? -1.0 : 1.0;

    // 귀 꼭짓점(tip)과 밑변 두 점
    final tip = Offset(cx + s * r * 0.52, cy - r * 0.88);
    final bInner = Offset(cx + s * r * 0.18, cy - r * 0.62); // 얼굴 쪽
    final bOuter = Offset(cx + s * r * 0.70, cy - r * 0.42); // 바깥쪽

    // 귀 외곽 삼각형
    final outerPath = Path()
      ..moveTo(bInner.dx, bInner.dy)
      ..lineTo(tip.dx, tip.dy)
      ..lineTo(bOuter.dx, bOuter.dy)
      ..close();

    canvas.drawPath(outerPath, Paint()..color = _earColor);
    canvas.drawPath(
        outerPath,
        Paint()
          ..color = _earColor.withAlpha(150)
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.020
          ..strokeJoin = StrokeJoin.round);

    // 귀 안쪽 핑크 (무게중심 기준 60% 축소)
    final gx = (tip.dx + bInner.dx + bOuter.dx) / 3;
    final gy = (tip.dy + bInner.dy + bOuter.dy) / 3;
    const sc = 0.60;
    double ix(double x) => gx + (x - gx) * sc;
    double iy(double y) => gy + (y - gy) * sc;

    final innerPath = Path()
      ..moveTo(ix(bInner.dx), iy(bInner.dy))
      ..lineTo(ix(tip.dx), iy(tip.dy))
      ..lineTo(ix(bOuter.dx), iy(bOuter.dy))
      ..close();

    // 외로울수록 핑크가 진해짐 (social↑ → 더 선명)
    final pinkAlpha = (0.68 + social * 0.30).clamp(0.0, 1.0);
    canvas.drawPath(
        innerPath,
        Paint()
          ..color = Color.fromRGBO(255, 155, 180, pinkAlpha)
          ..style = PaintingStyle.fill);
  }

  // ── 얼굴 원 ──────────────────────────────────────────────────

  void _drawFaceCircle(Canvas canvas, double cx, double cy, double r) {
    // 드롭 섀도우
    canvas.drawCircle(
        Offset(cx, cy + r * 0.07),
        r * 0.97,
        Paint()
          ..color = Colors.black.withAlpha(55)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));

    // 얼굴 본체
    canvas.drawCircle(Offset(cx, cy), r, Paint()..color = _faceColor);

    // 외곽선
    canvas.drawCircle(
        Offset(cx, cy),
        r,
        Paint()
          ..color = _earColor.withAlpha(115)
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.022);
  }

  // ── 볼 홍조 ──────────────────────────────────────────────────

  void _drawCheeks(Canvas canvas, double cx, double cy, double r) {
    // 기분 좋거나 외로울 때 볼이 빨개짐
    final alpha = (valence * 0.28 + social * 0.24).clamp(0.0, 0.50);
    if (alpha < 0.04) return;
    final paint = Paint()
      ..color = const Color(0xFFFF9EAD).withAlpha((alpha * 255).round())
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.16);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx - r * 0.39, cy + r * 0.10),
            width: r * 0.36,
            height: r * 0.20),
        paint);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx + r * 0.39, cy + r * 0.10),
            width: r * 0.36,
            height: r * 0.20),
        paint);
  }

  // ── 눈 ───────────────────────────────────────────────────────

  void _drawEyes(Canvas canvas, double cx, double cy, double r) {
    final eyeY = cy - r * 0.10;
    final droopY = social * r * 0.06; // 외로울수록 눈이 처짐
    _drawSingleEye(canvas, cx - r * 0.295, eyeY + droopY, r);
    _drawSingleEye(canvas, cx + r * 0.295, eyeY + droopY, r);
  }

  void _drawSingleEye(Canvas canvas, double ex, double ey, double r) {
    final eyeW = r * 0.295;
    final eyeH = _calcEyeH(r);
    final eyeRect =
        Rect.fromCenter(center: Offset(ex, ey), width: eyeW, height: eyeH);

    // 깜빡임 — 가는 선으로 표현
    if (eyeH < r * 0.030) {
      canvas.drawLine(
          Offset(ex - eyeW / 2, ey),
          Offset(ex + eyeW / 2, ey),
          Paint()
            ..color = const Color(0xFF3A2010)
            ..strokeWidth = r * 0.048
            ..strokeCap = StrokeCap.round);
      return;
    }

    // 눈 내부: oval clip 안에서 흰자 → 홍채 → 동공 → 하이라이트 → 졸음 눈꺼풀
    canvas.save();
    canvas.clipPath(Path()..addOval(eyeRect));

    // 흰자 (약간 따뜻한 화이트)
    canvas.drawPaint(Paint()..color = const Color(0xFFF8F0E8));

    // 홍채
    final irisR = eyeH * 0.44;
    final gox = gazeDir.dx * irisR * 0.36; // 시선 오프셋
    final goy = gazeDir.dy * irisR * 0.30;
    canvas.drawCircle(Offset(ex + gox, ey + goy), irisR, Paint()..color = _irisColor);

    // 홍채 내부 링 (깊이감)
    canvas.drawCircle(
        Offset(ex + gox, ey + goy),
        irisR * 0.72,
        Paint()
          ..color = _irisColor.withAlpha(128)
          ..style = PaintingStyle.stroke
          ..strokeWidth = irisR * 0.14);

    // 동공: 고양이 세로 타원 (각성↑ → 더 넓고 둥글게)
    final pupilW = irisR * (0.20 + arousal * 0.54);
    final pupilH = irisR * (0.80 + arousal * 0.18);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(ex + gox, ey + goy),
            width: pupilW,
            height: pupilH),
        Paint()..color = const Color(0xFF120800));

    // 하이라이트 (큰 것 + 작은 것 → 생기 있는 눈)
    canvas.drawCircle(
        Offset(ex - irisR * 0.22 + gox * 0.22, ey - irisR * 0.28 + goy * 0.22),
        irisR * 0.24,
        Paint()..color = Colors.white.withAlpha(235));
    canvas.drawCircle(
        Offset(ex + irisR * 0.18 + gox * 0.22, ey - irisR * 0.14 + goy * 0.22),
        irisR * 0.11,
        Paint()..color = Colors.white.withAlpha(140));

    // 졸음 눈꺼풀: 각성 낮을수록 얼굴색이 눈 위쪽 덮음
    final sleepy =
        ((1 - arousal) * 0.40 + (valence < 0 ? -valence * 0.12 : 0))
            .clamp(0.0, 0.58);
    if (sleepy > 0.04) {
      canvas.drawRect(
          Rect.fromLTWH(
              ex - eyeW, ey - eyeH, eyeW * 2, eyeH * sleepy * 1.65),
          Paint()..color = _faceColor.withAlpha(225));
    }

    canvas.restore();

    // 눈 외곽선
    canvas.drawOval(
        eyeRect,
        Paint()
          ..color = const Color(0xFF3A2010).withAlpha(192)
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.022);

    // 위 눈꺼풀 아치 (고양이 눈 특유의 아이라인 효과)
    _drawUpperLidArch(canvas, ex, ey, eyeW, eyeH, r);
  }

  void _drawUpperLidArch(
      Canvas canvas, double ex, double ey, double w, double h, double r) {
    final path = Path()
      ..moveTo(ex - w * 0.53, ey)
      ..quadraticBezierTo(ex, ey - h * 0.58, ex + w * 0.53, ey);
    canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFF3A2010).withAlpha(140)
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.036
          ..strokeCap = StrokeCap.round);
  }

  double _calcEyeH(double r) {
    final base = r * 0.268;
    // 깜빡임 구간: blinkPhase 0.82..1.0
    if (blinkPhase > 0.82) {
      final t = (blinkPhase - 0.82) / 0.18;
      return base * (1 - math.sin(t * math.pi) * 0.94) *
          (0.52 + arousal * 0.62);
    }
    return base * (0.52 + arousal * 0.62);
  }

  // ── 코 ───────────────────────────────────────────────────────

  void _drawNose(Canvas canvas, double cx, double cy, double r) {
    final ny = cy + r * 0.112;
    final nw = r * 0.106;
    final nh = r * 0.068;

    final noseColor = Color.lerp(
        const Color(0xFFFF7A9A), const Color(0xFFFF4568), arousal * 0.42)!;

    // 역삼각형 코
    final nosePath = Path()
      ..moveTo(cx - nw / 2, ny)
      ..lineTo(cx + nw / 2, ny)
      ..lineTo(cx, ny + nh)
      ..close();
    canvas.drawPath(nosePath, Paint()..color = noseColor);

    // 인중 (코 아래 짧은 세로선)
    canvas.drawLine(
        Offset(cx, ny + nh),
        Offset(cx, ny + nh + r * 0.052),
        Paint()
          ..color = noseColor.withAlpha(115)
          ..strokeWidth = r * 0.022
          ..strokeCap = StrokeCap.round);
  }

  // ── 입 ───────────────────────────────────────────────────────

  void _drawMouth(Canvas canvas, double cx, double cy, double r) {
    final my = cy + r * 0.248;
    final mw = r * 0.338;
    final curvature = valence * mw * 0.265;
    final catDip = mw * 0.072; // W형 가운데 살짝 들어감

    final paint = Paint()
      ..color = const Color(0xFF7A3A2A).withAlpha(210)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.038
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // 고양이 W 입: 좌절반 + 우절반 (각각 quadratic bezier)
    final path = Path()
      ..moveTo(cx - mw / 2, my)
      ..quadraticBezierTo(
          cx - mw * 0.13, my - curvature, cx, my + catDip - curvature * 0.28)
      ..quadraticBezierTo(
          cx + mw * 0.13, my - curvature, cx + mw / 2, my);
    canvas.drawPath(path, paint);

    // 각성 높을 때 입이 살짝 벌어짐
    if (arousal > 0.62) {
      final openH = ((arousal - 0.62) / 0.38) * r * 0.070;
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(cx, my + catDip + openH * 0.45),
              width: mw * 0.30,
              height: openH),
          Paint()
            ..color = const Color(0xFF5A1A0A).withAlpha(190)
            ..style = PaintingStyle.fill);
    }
  }

  // ── 수염 ─────────────────────────────────────────────────────

  void _drawWhiskers(Canvas canvas, double cx, double cy, double r) {
    final baseY = cy + r * 0.155;
    final droop = social * r * 0.110; // 외로울수록 수염 처짐
    final wLen = r * 0.460;

    final lBase = Offset(cx - r * 0.145, baseY);
    final rBase = Offset(cx + r * 0.145, baseY);

    // 왼쪽 수염 끝점 3가닥 (위·중·아래)
    final lTips = [
      Offset(lBase.dx - wLen * 0.97, lBase.dy - r * 0.058),
      Offset(lBase.dx - wLen, lBase.dy + droop * 0.28),
      Offset(lBase.dx - wLen * 0.93, lBase.dy + r * 0.078 + droop),
    ];
    // 오른쪽 (좌우 대칭)
    final rTips = lTips
        .map((t) => Offset(rBase.dx + (lBase.dx - t.dx).abs(), t.dy))
        .toList();

    for (int i = 0; i < 3; i++) {
      final alpha = ((0.72 - i * 0.09) * 255).round();
      final sw = r * (0.019 - i * 0.003);
      final p = Paint()
        ..color = Colors.white.withAlpha(alpha)
        ..strokeWidth = sw
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(lBase, lTips[i], p);
      canvas.drawLine(rBase, rTips[i], p);
    }
  }

  @override
  bool shouldRepaint(FacePainter old) =>
      old.valence != valence ||
      old.arousal != arousal ||
      old.social != social ||
      old.energy != energy ||
      old.blinkPhase != blinkPhase ||
      old.breathPhase != breathPhase ||
      old.gazeDir != gazeDir;
}
