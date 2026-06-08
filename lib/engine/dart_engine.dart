import 'dart:math' as math;
import 'model.dart';
import 'neuram_engine.dart';
import 'connectome.dart';
import 'persistence.dart';

int _now() => DateTime.now().millisecondsSinceEpoch;
double _clamp01(double x) => x < 0 ? 0 : (x > 1 ? 1 : x);

class DartNeuramEngine implements NeuramEngine {
  late Map<int, Neuron> n;
  late List<Synapse> syn;
  final Persistence store;

  // 드라이브 Lazy 상태
  double _social = 0.2, _energy = 0.9, _arousal = 0.0, _valence = 0.1;
  int _tSocial = 0, _tEnergy = 0, _tArousal = 0;

  // social: 시간↑→외로움↑(baseline 1.0 수렴)
  // energy: 시간↑→허기↑(baseline 0.0 수렴)
  static const tauSocial = 3600.0;
  static const tauEnergy = 7200.0;
  static const tauArousal = 20.0;

  DartNeuramEngine(this.store);

  @override
  Future<void> load() async {
    final now = _now();
    _tSocial = now; _tEnergy = now; _tArousal = now;

    final loaded = await store.load();
    if (loaded == null) {
      final c = buildReflexConnectome();
      n = c.$1; syn = c.$2;
      await store.save(n, syn, meta: {'born': now});
    } else {
      n = loaded.$1; syn = loaded.$2;
      final meta = await store.loadMeta();
      if (meta != null) {
        _social = (meta['social'] as num?)?.toDouble() ?? 0.2;
        _energy = (meta['energy'] as num?)?.toDouble() ?? 0.9;
        _valence = (meta['valence'] as num?)?.toDouble() ?? 0.1;
        _tSocial = (meta['tSocial'] as num?)?.toInt() ?? now;
        _tEnergy = (meta['tEnergy'] as num?)?.toInt() ?? now;
        // arousal은 재시작 시 리셋(새 세션 각성 = 0)
      }
    }
  }

  void _applyLazyDrives(int now) {
    final dsS = math.exp(-(now - _tSocial) / 1000.0 / tauSocial);
    _social = 1.0 + (_social - 1.0) * dsS; _tSocial = now;
    final dsE = math.exp(-(now - _tEnergy) / 1000.0 / tauEnergy);
    _energy = 0.0 + (_energy - 0.0) * dsE; _tEnergy = now;
    final dsA = math.exp(-(now - _tArousal) / 1000.0 / tauArousal);
    _arousal = _arousal * dsA; _tArousal = now;
  }

  @override
  void onSensor(SensorInput s) {
    final now = _now();
    _applyLazyDrives(now);

    // 습관화 시냅스(S_sound→I_startle) 회복(Lazy)
    final hab = syn.firstWhere(
        (x) => x.preId == Ids.sSound && x.postId == Ids.iStartle);
    final rec = math.exp(-(now - hab.tLastMs) / 1000.0 / hab.depTauSec);
    hab.depression *= rec;
    hab.tLastMs = now;

    n[Ids.sSound]!.value = s.soundLevel;
    n[Ids.sTouch]!.value = s.touchSoft - s.touchSharp;
    n[Ids.sShake]!.value = s.shake;

    // 놀람: 습관화(depression) 적용
    final startleDrive = (s.soundSharp + s.shake) * (1 - hab.depression);
    n[Ids.iStartle]!.value = _clamp01(startleDrive);
    if (startleDrive > 0.15) {
      hab.depression =
          hab.depression + hab.depIncr * (1 - hab.depression);
      hab.tLastMs = now;
    }

    n[Ids.iSoothe]!.value = _clamp01(s.touchSoft);

    _arousal = _clamp01(
        _arousal + 0.6 * n[Ids.iStartle]!.value - 0.5 * n[Ids.iSoothe]!.value);
    _tArousal = now;
    _valence = (_valence
        + 0.4 * n[Ids.iSoothe]!.value
        - 0.3 * n[Ids.iStartle]!.value
        - 0.1 * _social).clamp(-1.0, 1.0);

    if (s.touchSoft > 0.05 || s.soundLevel > 0.05) {
      _social = (_social
          - 0.15 * (s.touchSoft + 0.5 * s.soundLevel)).clamp(0.0, 1.0);
      _tSocial = now;
    }
  }

  /// 명시적 먹이주기 (UI 버튼에서 호출, D-018)
  void feed() {
    _energy = _clamp01(_energy + 0.3);
    _tEnergy = _now();
    _valence = (_valence + 0.15).clamp(-1.0, 1.0);
    _social = (_social - 0.1).clamp(0.0, 1.0);
    _tSocial = _now();
  }

  @override
  CreatureState tick() {
    final now = _now();
    _applyLazyDrives(now);

    final valence = (_valence - 0.4 * _social).clamp(-1.0, 1.0);
    final arousal = _arousal;
    String? voc;
    if (_social > 0.7 && arousal < 0.4) {
      voc = 'plaintive';
    } else if (arousal > 0.75) {
      voc = 'alarm';
    } else if (valence > 0.5 && arousal < 0.3) {
      voc = 'content';
    }
    final purr = n[Ids.iSoothe]!.value *
        (valence > 0 ? 1.0 : 0.0) *
        (1 - arousal);

    return CreatureState(
      valence: valence,
      arousal: arousal,
      social: _social,
      energy: _energy,
      vocalize: voc,
      purr: _clamp01(purr),
    );
  }

  @override
  Future<void> save() => store.save(n, syn, meta: {
        'social': _social,
        'energy': _energy,
        'valence': _valence,
        'tSocial': _tSocial,
        'tEnergy': _tEnergy,
      });

  // 디버그용 게터
  double get arousal => _arousal;
  double get valence => _valence;
  double get social => _social;
  double get energy => _energy;
}
