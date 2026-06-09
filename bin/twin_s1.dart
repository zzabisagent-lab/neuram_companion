import 'package:neuram_companion/engine/halfmb/config.dart';
import 'package:neuram_companion/engine/halfmb/topology.dart';
import 'package:neuram_companion/engine/halfmb/engine.dart';
import 'package:neuram_companion/engine/halfmb/persistence.dart';

// PN 채널(예시): 0,1=소리밴드A / 2,3=소리밴드B / 4=터치 / 5=흔듦
Map<int, double> patternA() => {0: 1.0, 1: 0.8, 4: 0.1};
Map<int, double> patternB() => {2: 0.9, 3: 1.0, 5: 0.1};
const rewardComp = 0;

double probe(Connectome cx, Map<int, double> Function() pat) {
  final out = cx.step(pat(), const {}, learn: false); // 평가(무학습)
  var s = 0.0; var n = 0;
  for (final m in cx.mbon) {
    if (cx.neurons[m].compartment == rewardComp) { s += out[m]!; n++; }
  }
  return n > 0 ? s / n : 0;
}

void main() {
  final c = HalfMBConfig.s1;
  final cx = buildHalfMB(c);

  print('pre  A=${probe(cx, patternA).toStringAsFixed(3)}  B=${probe(cx, patternB).toStringAsFixed(3)}');

  // 조건화: A는 보상과 짝(CS+/US), B는 단독(CS−). 교차 제시 + 간헐 휴지.
  for (var trial = 0; trial < 500; trial++) {
    if (trial.isEven) {
      cx.step(patternA(), const {rewardComp: 1.0});
    } else {
      cx.step(patternB(), const {});
    }
    if (trial % 25 == 0) cx.step(const {}, const {}); // 휴지(가지치기 관찰)
  }

  print('post A=${probe(cx, patternA).toStringAsFixed(3)}  B=${probe(cx, patternB).toStringAsFixed(3)}');
  print('active=${cx.pool.activeCount}  formed=${cx.formed}  pruned=${cx.pruned}');

  // 영속 검증: 저장→재빌드→로드→재프로브 일치 확인
  saveConnectome(cx, 'connectome_s1.json');
  final cx2 = buildHalfMB(c);
  loadConnectome(cx2, 'connectome_s1.json');
  print('reload A=${probe(cx2, patternA).toStringAsFixed(3)}  B=${probe(cx2, patternB).toStringAsFixed(3)}');
}
