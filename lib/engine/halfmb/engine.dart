import 'dart:math';
import 'config.dart';
import 'model.dart';

class Connectome {
  final HalfMBConfig c;
  final List<Neuron> neurons;
  final SynapsePool pool;
  final List<int> pn, kc, mbon, dan;
  final int apl;
  final Map<int, List<int>> pnToKc; // 고정 랜덤 확장
  int t = 0, formed = 0, pruned = 0;

  Connectome(this.c, this.neurons, this.pool,
      {required this.pn, required this.kc, required this.mbon,
       required this.dan, required this.apl, required this.pnToKc});

  /// 한 틱. inputs: PN id→활성. valence: 구획→보상(+)/처벌(−). learn=false면 평가(가소성 없음).
  Map<int, double> step(Map<int, double> inputs, Map<int, double> valence, {bool learn = true}) {
    t++;
    for (final p in pn) neurons[p].act = inputs[p] ?? 0.0;

    // KC 사전활성(고정 PN→KC 합) → APL k-WTA(희소화)
    final kcRaw = <int, double>{};
    for (final k in kc) {
      var s = 0.0;
      for (final p in pnToKc[k]!) s += neurons[p].act;
      kcRaw[k] = s / c.kcFanIn;
    }
    final order = kc.toList()..sort((a, b) => kcRaw[b]!.compareTo(kcRaw[a]!));
    final activeKc = <int>{};
    for (var i = 0; i < c.kWTA && i < order.length; i++) {
      if (kcRaw[order[i]]! > 0) activeKc.add(order[i]);
    }
    for (final k in kc) neurons[k].act = activeKc.contains(k) ? kcRaw[k]! : 0.0;

    // DAN = valence
    for (final d in dan) neurons[d].act = valence[neurons[d].compartment] ?? 0.0;

    // KC→MBON 전파(active 시냅스만)
    final out = <int, double>{};
    for (final m in mbon) {
      var s = 0.0;
      for (final si in pool.postSynapses(m)) {
        final syn = pool[si];
        if (!syn.active) continue;
        final a = neurons[syn.pre].act;
        if (a > 0) { s += a * syn.weight; syn.tLastUsed = t; }
      }
      out[m] = 1 / (1 + exp(-4 * (s - 0.5)));
      neurons[m].act = out[m]!;
    }

    if (learn) _plasticity(activeKc, valence);
    return out;
  }

  void _plasticity(Set<int> activeKc, Map<int, double> valence) {
    for (final m in mbon) {
      final v = valence[neurons[m].compartment] ?? 0.0;

      // 강화/약화: 활성 KC로 들어오는 active 시냅스를 valence로 게이팅
      for (final si in pool.postSynapses(m).toList()) {
        final syn = pool[si];
        if (!syn.active) continue;
        if (activeKc.contains(syn.pre) && v != 0) {
          syn.weight = (syn.weight + c.lr * v).clamp(0.0, 1.0);
        }
      }
      // 형성: 보상 + 활성 KC인데 연결 없으면 silent 실현(예산 내)
      if (v > c.formThreshold) {
        for (final k in activeKc) {
          if (_synCount(m) >= c.synapseBudgetPerMBON) break;
          if (!_hasSyn(k, m)) { pool.create(k, m, 0.05, t); formed++; }
        }
      }
      // 사멸: 약하거나 미사용 → 가지치기
      for (final si in pool.postSynapses(m).toList()) {
        final syn = pool[si];
        if (!syn.active) continue;
        if (syn.weight < c.weightFloor || (t - syn.tLastUsed) > c.pruneTau) {
          pool.remove(si); pruned++;
        }
      }
      // 안정화: 항상성 스케일링(입력 총합 상한)
      _normalize(m);
    }
  }

  bool _hasSyn(int pre, int post) {
    for (final si in pool.postSynapses(post)) {
      final s = pool[si];
      if (s.active && s.pre == pre) return true;
    }
    return false;
  }

  int _synCount(int m) {
    var n = 0;
    for (final si in pool.postSynapses(m)) if (pool[si].active) n++;
    return n;
  }

  void _normalize(int m) {
    var sum = 0.0;
    final idxs = <int>[];
    for (final si in pool.postSynapses(m)) {
      final s = pool[si];
      if (s.active) { sum += s.weight; idxs.add(si); }
    }
    if (sum > c.synScaleTarget) {
      final f = c.synScaleTarget / sum;
      for (final si in idxs) pool[si].weight *= f;
    }
  }
}
