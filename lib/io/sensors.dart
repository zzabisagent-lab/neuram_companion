import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:path_provider/path_provider.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import '../engine/neuram_engine.dart';

/// 마이크·가속도 센서 → SensorInput 스트림.
/// 터치 입력은 UI(GestureDetector)에서 직접 onSensor() 호출.
class SensorManager {
  final _controller = StreamController<SensorInput>.broadcast();
  Stream<SensorInput> get stream => _controller.stream;

  final _audioRecorder = AudioRecorder();
  StreamSubscription? _ampSub;
  StreamSubscription? _accelSub;
  String? _tmpRecordPath;

  double _lastAmpDb = -60.0;
  double _accelVar = 0.0;
  final _accelWindow = <double>[];
  static const _accelWinSize = 10;

  // send-on-delta 임계
  static const _ampDeltaThreshold = 3.0; // dB
  static const _shakeDeltaThreshold = 0.05;

  Future<void> start() async {
    final status = await Permission.microphone.request();
    if (status.isGranted) {
      await _startMic();
    }
    _startAccel();
  }

  Future<void> _startMic() async {
    try {
      if (!await _audioRecorder.hasPermission()) return;
      // 임시 파일 경로 — getAmplitude()를 사용하기 위해 recording을 시작해야 함
      final tmp = await getTemporaryDirectory();
      _tmpRecordPath = '${tmp.path}/neuram_amp_tmp.m4a';
      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          sampleRate: 16000,
          numChannels: 1,
          bitRate: 32000,
        ),
        path: _tmpRecordPath!,
      );
      // 진폭 폴링: 100ms마다
      _ampSub = Stream.periodic(const Duration(milliseconds: 100))
          .listen((_) async {
        try {
          final amp = await _audioRecorder.getAmplitude();
          final db = amp.current.clamp(-60.0, 0.0);
          final delta = (db - _lastAmpDb).abs();
          if (delta > _ampDeltaThreshold) {
            _lastAmpDb = db;
            _emit();
          }
        } catch (_) {}
      });
    } catch (_) {}
  }

  void _startAccel() {
    _accelSub = accelerometerEventStream(
            samplingPeriod: SensorInterval.normalInterval)
        .listen((e) {
      final mag = math.sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
      _accelWindow.add(mag);
      if (_accelWindow.length > _accelWinSize) _accelWindow.removeAt(0);

      final mean = _accelWindow.reduce((a, b) => a + b) / _accelWindow.length;
      final variance = _accelWindow
              .map((v) => (v - mean) * (v - mean))
              .reduce((a, b) => a + b) /
          _accelWindow.length;
      final newVar = math.sqrt(variance) / 9.8;

      if ((newVar - _accelVar).abs() > _shakeDeltaThreshold) {
        _accelVar = newVar;
        _emit();
      }
    });
  }

  double get _soundLevel =>
      ((_lastAmpDb + 60) / 60).clamp(0.0, 1.0);

  double get _soundSharp {
    final level = _soundLevel;
    return level > 0.5 ? ((level - 0.5) * 2).clamp(0.0, 1.0) : 0.0;
  }

  void _emit() {
    if (_controller.isClosed) return;
    _controller.add(SensorInput(
      soundLevel: _soundLevel,
      soundSharp: _soundSharp,
      shake: _accelVar.clamp(0.0, 1.0),
    ));
  }

  void dispose() {
    _ampSub?.cancel();
    _accelSub?.cancel();
    _audioRecorder.stop().then((_) {
      // 임시 녹음 파일 삭제
      if (_tmpRecordPath != null) {
        try { File(_tmpRecordPath!).deleteSync(); } catch (_) {}
      }
    });
    _audioRecorder.dispose();
    _controller.close();
  }
}
