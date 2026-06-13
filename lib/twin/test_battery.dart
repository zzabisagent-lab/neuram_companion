import '../engine/halfmb/engine.dart';
import 'regime.dart';

/// 고정 프로브 자극 (learn:false 평가용).
const Map<int, double> probeAInput = {0: 1.0, 1: 0.8};
const Map<int, double> probeBInput = {2: 0.9, 3: 1.0};
const Map<int, double> probeNovelInput = {4: 1.0, 5: 1.0};

class BatteryResult {
  final double probeA;       // 프로브 A의 보상구획 MBON 평균
  final double probeB;       // 프로브 B의 보상구획 MBON 평균
  final double probeNovel;   // 프로브 novel의 보상구획 MBON 평균
  final double approachIndex; // 세 프로브 보상구획 평균
  final double avoidIndex;    // 세 프로브 처벌구획 평균
  final double meanWeight;    // 활성 시냅스 가중치 평균
  final double kcSparsity;    // 세 프로브 평균 (act>0 KC 수)/nKC
  final double probeApunish, probeBpunish, probeNovelpunish; // 각 프로브의 처벌구획 평균
  final double netA, netB, netNovel, netIndex;               // 순 접근 = 보상 − 처벌
  BatteryResult({
    required this.probeA,
    required this.probeB,
    required this.probeNovel,
    required this.approachIndex,
    required this.avoidIndex,
    required this.meanWeight,
    required this.kcSparsity,
    required this.probeApunish,
    required this.probeBpunish,
    required this.probeNovelpunish,
    required this.netA,
    required this.netB,
    required this.netNovel,
    required this.netIndex,
  });
}

class _ProbeOut {
  final double rewardMean;
  final double punishMean;
  final int kcActive;
  _ProbeOut(this.rewardMean, this.punishMean, this.kcActive);
}

_ProbeOut _probe(Connectome cx, Map<int, double> input) {
  final out = cx.step(input, const <int, double>{}, learn: false);
  double rSum = 0, pSum = 0;
  int rN = 0, pN = 0;
  for (final m in cx.mbon) {
    final comp = cx.neurons[m].compartment;
    if (comp == rewardComp) {
      rSum += out[m]!;
      rN++;
    } else if (comp == punishComp) {
      pSum += out[m]!;
      pN++;
    }
  }
  int kcActive = 0;
  for (final k in cx.kc) {
    if (cx.neurons[k].act > 0) kcActive++;
  }
  return _ProbeOut(rN > 0 ? rSum / rN : 0, pN > 0 ? pSum / pN : 0, kcActive);
}

double _meanActiveWeight(Connectome cx) {
  double sum = 0;
  int n = 0;
  for (final s in cx.pool.raw) {
    if (s.active) {
      sum += s.weight;
      n++;
    }
  }
  return n > 0 ? sum / n : 0;
}

BatteryResult runBattery(Connectome cx) {
  final a = _probe(cx, probeAInput);
  final b = _probe(cx, probeBInput);
  final n = _probe(cx, probeNovelInput);
  final approach = (a.rewardMean + b.rewardMean + n.rewardMean) / 3;
  final avoid = (a.punishMean + b.punishMean + n.punishMean) / 3;
  return BatteryResult(
    probeA: a.rewardMean, probeB: b.rewardMean, probeNovel: n.rewardMean,
    probeApunish: a.punishMean, probeBpunish: b.punishMean, probeNovelpunish: n.punishMean,
    approachIndex: approach, avoidIndex: avoid,
    netA: a.rewardMean - a.punishMean,
    netB: b.rewardMean - b.punishMean,
    netNovel: n.rewardMean - n.punishMean,
    netIndex: approach - avoid,
    meanWeight: _meanActiveWeight(cx),
    kcSparsity: (a.kcActive + b.kcActive + n.kcActive) / 3 / cx.c.nKC,
  );
}
