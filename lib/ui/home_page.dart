import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../engine/dart_engine.dart';
import '../engine/neuram_engine.dart';
import '../io/sensors.dart';
import '../io/outputs.dart';
import 'face_painter.dart';

/// 메인 화면: 센서 구독 + GestureDetector + ~20fps 표현 틱 + 상태 표시
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

  double _blinkPhase = 0.0;
  double _jitter = 0.0;
  final _rng = math.Random();

  // 깜빡임 타이머
  double _blinkTimer = 0.0;
  double _nextBlink = 3.0; // 초

  bool _engineReady = false;

  @override
  void initState() {
    super.initState();
    _outputs = OutputManager();
    _sensors = SensorManager();
    _init();

    // ~20fps 틱 (Ticker = vsync 기반)
    _ticker = createTicker(_onTick)..start();
  }

  Future<void> _init() async {
    await widget.engine.load();
    await _outputs.init();
    await _sensors.start();
    _sensorSub = _sensors.stream.listen(_onSensor);
    if (mounted) setState(() => _engineReady = true);
  }

  void _onSensor(SensorInput s) {
    widget.engine.onSensor(s);
  }

  Duration _lastTick = Duration.zero;
  void _onTick(Duration elapsed) {
    if (!_engineReady) return;
    final dt = (elapsed - _lastTick).inMilliseconds / 1000.0;
    _lastTick = elapsed;

    // 깜빡임 위상 진행
    _blinkTimer += dt;
    if (_blinkTimer >= _nextBlink) {
      _blinkTimer = 0;
      _nextBlink = 2.0 + _rng.nextDouble() * 4.0; // 2~6초마다
      _blinkPhase = 0.0; // 깜빡임 시작
    }
    if (_blinkPhase < 1.0) {
      _blinkPhase = (_blinkPhase + dt * 5).clamp(0.0, 1.0);
    }

    // 미세 흔들림: arousal에 비례
    _jitter = math.sin(elapsed.inMilliseconds * 0.008) * _state.arousal;

    final newState = widget.engine.tick();

    // 출력
    _outputs.playVocalize(newState.vocalize);
    _outputs.setPurr(newState.purr);

    setState(() => _state = newState);
  }

  void _onTap(TapUpDetails d) {
    widget.engine.onSensor(const SensorInput(touchSharp: 0.8));
  }

  void _onLongPressStart(LongPressStartDetails _) {
    widget.engine.onSensor(const SensorInput(touchSoft: 0.9));
  }

  void _onLongPressMoveUpdate(LongPressMoveUpdateDetails _) {
    widget.engine.onSensor(const SensorInput(touchSoft: 0.7));
  }

  void _onPanUpdate(DragUpdateDetails _) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A14),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: GestureDetector(
                onTapUp: _onTap,
                onLongPressStart: _onLongPressStart,
                onLongPressMoveUpdate: _onLongPressMoveUpdate,
                onPanUpdate: _onPanUpdate,
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: CustomPaint(
                        painter: FacePainter(
                          valence: _state.valence,
                          arousal: _state.arousal,
                          social: _state.social,
                          blinkPhase: _blinkPhase,
                          jitter: _jitter,
                        ),
                        size: Size.infinite,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            _buildStatusBar(),
            _buildControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _statusChip('기분', _state.valence, isSymmetric: true),
          _statusChip('각성', _state.arousal),
          _statusChip('허기', 1 - _state.energy),
          _statusChip('외로움', _state.social),
        ],
      ),
    );
  }

  Widget _statusChip(String label, double value, {bool isSymmetric = false}) {
    final display = isSymmetric
        ? '${value >= 0 ? '+' : ''}${(value * 100).round()}%'
        : '${(value * 100).round()}%';
    final color = isSymmetric
        ? (value > 0 ? Colors.green : Colors.red)
        : Color.lerp(Colors.green, Colors.red, value)!;
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
        const SizedBox(height: 2),
        Text(display, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () { widget.engine.feed(); },
              icon: const Icon(Icons.restaurant, size: 18),
              label: const Text('먹이주기'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2A4A2A),
                foregroundColor: Colors.greenAccent,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                widget.engine.onSensor(const SensorInput(touchSoft: 0.85));
              },
              icon: const Icon(Icons.pets, size: 18),
              label: const Text('쓰다듬기'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2A2A4A),
                foregroundColor: Colors.lightBlueAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
