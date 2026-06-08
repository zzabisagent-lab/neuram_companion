import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../engine/dart_engine.dart';
import '../engine/neuram_engine.dart';
import '../io/sensors.dart';
import '../io/outputs.dart';
import 'face_painter.dart';

/// 메인 화면: 센서 구독 + GestureDetector + ~60fps Ticker + 상태 표시
class HomePage extends StatefulWidget {
  final DartNeuramEngine engine;
  const HomePage({super.key, required this.engine});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late final SensorManager _sensors;
  late final OutputManager _outputs;
  late final Ticker _ticker;
  StreamSubscription? _sensorSub;

  CreatureState _state = const CreatureState(
      valence: 0, arousal: 0, social: 0.2, energy: 0.9);

  // ── 애니메이션 상태 ───────────────────────────────────────────
  double _blinkPhase = 0.0;
  double _blinkTimer = 0.0;
  double _nextBlink = 3.0;

  double _breathPhase = 0.0; // 0..2π 호흡 위상

  Offset _gazeDir = Offset.zero; // 시선 방향 (-1..1)
  Size _faceAreaSize = const Size(300, 300); // LayoutBuilder로 갱신

  bool _engineReady = false;

  @override
  void initState() {
    super.initState();
    _outputs = OutputManager();
    _sensors = SensorManager();
    _init();
    _ticker = createTicker(_onTick)..start();
  }

  Future<void> _init() async {
    await widget.engine.load();
    await _outputs.init();
    await _sensors.start();
    _sensorSub = _sensors.stream.listen(_onSensor);
    if (mounted) setState(() => _engineReady = true);
  }

  void _onSensor(SensorInput s) => widget.engine.onSensor(s);

  Duration _lastTick = Duration.zero;

  void _onTick(Duration elapsed) {
    if (!_engineReady) return;
    final dt = (elapsed - _lastTick).inMilliseconds / 1000.0;
    _lastTick = elapsed;

    // 호흡: ~11초 주기 (τ = 0.57 rad/s)
    _breathPhase = (_breathPhase + dt * 0.57) % (2 * math.pi);

    // 깜빡임: 2~6초마다 한 번
    _blinkTimer += dt;
    if (_blinkTimer >= _nextBlink) {
      _blinkTimer = 0;
      _nextBlink = 2.0 + math.Random().nextDouble() * 4.0;
      _blinkPhase = 0.0;
    }
    if (_blinkPhase < 1.0) {
      _blinkPhase = (_blinkPhase + dt * 5.5).clamp(0.0, 1.0);
    }

    // 시선: 터치 없으면 서서히 정면으로
    _gazeDir = Offset(_gazeDir.dx * 0.93, _gazeDir.dy * 0.93);

    final newState = widget.engine.tick();
    _outputs.playVocalize(newState.vocalize);
    _outputs.setPurr(newState.purr);

    setState(() => _state = newState);
  }

  // ── 시선 방향 갱신 ────────────────────────────────────────────

  void _updateGaze(Offset localPos) {
    final c = Offset(_faceAreaSize.width / 2, _faceAreaSize.height / 2);
    final r = math.min(c.dx, c.dy);
    if (r <= 0) return;
    _gazeDir = Offset(
      ((localPos.dx - c.dx) / r).clamp(-1.0, 1.0),
      ((localPos.dy - c.dy) / r).clamp(-1.0, 1.0),
    );
  }

  // ── 제스처 핸들러 ────────────────────────────────────────────

  void _onTapUp(TapUpDetails d) {
    _updateGaze(d.localPosition);
    widget.engine.onSensor(const SensorInput(touchSharp: 0.8));
  }

  void _onLongPressStart(LongPressStartDetails d) {
    _updateGaze(d.localPosition);
    widget.engine.onSensor(const SensorInput(touchSoft: 0.9));
  }

  void _onLongPressMoveUpdate(LongPressMoveUpdateDetails d) {
    _updateGaze(d.localPosition);
    widget.engine.onSensor(const SensorInput(touchSoft: 0.7));
  }

  void _onPanUpdate(DragUpdateDetails d) {
    _updateGaze(d.localPosition);
    widget.engine.onSensor(const SensorInput(touchSoft: 0.5));
  }

  @override
  void dispose() {
    _ticker.dispose();
    _sensorSub?.cancel();
    _sensors.dispose();
    _outputs.dispose();
    super.dispose();
  }

  // ── 빌드 ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080810),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _buildFaceArea()),
            _buildStatusBar(),
            _buildControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildFaceArea() {
    return LayoutBuilder(
      builder: (context, constraints) {
        _faceAreaSize = constraints.biggest;
        return GestureDetector(
          onTapUp: _onTapUp,
          onLongPressStart: _onLongPressStart,
          onLongPressMoveUpdate: _onLongPressMoveUpdate,
          onPanUpdate: _onPanUpdate,
          child: Center(
            child: AspectRatio(
              aspectRatio: 1,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: CustomPaint(
                  painter: FacePainter(
                    valence: _state.valence,
                    arousal: _state.arousal,
                    social: _state.social,
                    energy: _state.energy,
                    blinkPhase: _blinkPhase,
                    breathPhase: _breathPhase,
                    gazeDir: _gazeDir,
                  ),
                  size: Size.infinite,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── 상태 바 ──────────────────────────────────────────────────

  Widget _buildStatusBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _statusChip('기분', _state.valence, symmetric: true,
              color: _moodColor(_state.valence)),
          _statusChip('각성', _state.arousal,
              color: Color.lerp(const Color(0xFF4488FF), const Color(0xFFFF6622),
                  _state.arousal)!),
          _statusChip('허기', 1 - _state.energy,
              color: Color.lerp(Colors.green, const Color(0xFFFF8844),
                  1 - _state.energy)!),
          _statusChip('외로움', _state.social,
              color: Color.lerp(Colors.tealAccent, const Color(0xFFCC88FF),
                  _state.social)!),
        ],
      ),
    );
  }

  Color _moodColor(double v) =>
      Color.lerp(const Color(0xFFFF5555), const Color(0xFF55DD88), (v + 1) / 2)!;

  Widget _statusChip(String label, double value,
      {bool symmetric = false, required Color color}) {
    final display = symmetric
        ? '${value >= 0 ? '+' : ''}${(value * 100).round()}%'
        : '${(value * 100).round()}%';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white38, fontSize: 10)),
        const SizedBox(height: 2),
        Text(display,
            style: TextStyle(
                color: color, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // ── 버튼 ────────────────────────────────────────────────────

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 2, 20, 14),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => widget.engine.feed(),
              icon: const Icon(Icons.restaurant, size: 17),
              label: const Text('먹이주기'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A1E),
                foregroundColor: const Color(0xFF88EE88),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () =>
                  widget.engine.onSensor(const SensorInput(touchSoft: 0.85)),
              icon: const Icon(Icons.pets, size: 17),
              label: const Text('쓰다듬기'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E1E3A),
                foregroundColor: const Color(0xFF88BBFF),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
