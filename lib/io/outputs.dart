import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';

/// 소리·진동 출력 (graded, §6).
/// 소리 프리셋: content / plaintive / alarm (단순 주파수 기반, 에셋 없이)
class OutputManager {
  final _player = AudioPlayer();
  String? _lastVoc;
  double _lastPurr = 0.0;
  bool _vibrating = false;

  // 소리 프리셋 파일(assets/sounds/ 에 있을 경우), 없으면 무음
  static const _sounds = {
    'content': 'sounds/content.mp3',
    'plaintive': 'sounds/plaintive.mp3',
    'alarm': 'sounds/alarm.mp3',
  };

  Future<void> init() async {
    await _player.setVolume(0.7);
  }

  /// vocalize: null=무음, 문자열=소리 종류
  Future<void> playVocalize(String? voc) async {
    if (voc == _lastVoc) return; // 같은 소리는 반복 안 함
    _lastVoc = voc;
    if (voc == null) {
      await _player.stop();
      return;
    }
    final path = _sounds[voc];
    if (path == null) return;
    try {
      await _player.play(AssetSource(path));
    } catch (_) {
      // 에셋 없으면 무시 — 후속에서 추가
    }
  }

  /// purr: 0=무진동, 1=강한 그르렁(반복 진동)
  Future<void> setPurr(double purr) async {
    if ((purr - _lastPurr).abs() < 0.05) return;
    _lastPurr = purr;

    final hasVib = (await Vibration.hasVibrator()) == true;
    if (!hasVib) return;

    if (purr < 0.1) {
      if (_vibrating) {
        await Vibration.cancel();
        _vibrating = false;
      }
      return;
    }

    // purr 강도에 따라 진동 패턴 결정
    _vibrating = true;
    final duration = (purr * 200).round().clamp(50, 200);
    final amplitude = (purr * 128).round().clamp(32, 128);
    await Vibration.vibrate(
      pattern: [0, duration, duration ~/ 2, duration],
      intensities: [0, amplitude, 0, amplitude ~/ 2],
      repeat: 0,
    );
  }

  void dispose() {
    Vibration.cancel();
    _player.dispose();
  }
}
