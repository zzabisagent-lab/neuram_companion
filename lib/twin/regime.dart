import 'dart:math';
import 'sim_clock.dart';

/// 구획 인덱스 (MBON compartment = i % nCompartments).
const int rewardComp = 0;
const int punishComp = 1;

/// 한 틱에 주어지는 자극(inputs) + 교사신호(valence: 구획→값).
/// "부정 valence"는 음수가 아니라 처벌 구획(punishComp)의 양수 교사로 표현한다.
/// (엔진 형성 규칙이 v > formThreshold 양수에서만 시냅스를 생성하기 때문)
class Interaction {
  final Map<int, double> inputs;
  final Map<int, double> valence;
  Interaction(this.inputs, this.valence);
}

/// 주간 레짐: 시뮬 시각에 줄 자극을 결정. null이면 idle.
abstract class WeeklyRegime {
  String get name;
  Interaction? at(SimClock clock, Random rng);
}

// ── 공용 자극 헬퍼 (PN 채널: 0,1=소리A / 2,3=소리B / 4=터치 / 5=흔듦) ──
const Map<int, double> soundA = {0: 1.0, 1: 0.8};
const Map<int, double> soundB = {2: 0.9, 3: 1.0};
const Map<int, double> loudA = {0: 1.0, 1: 1.0};
const Map<int, double> loudB = {2: 1.0, 3: 1.0};
const Map<int, double> shake = {5: 1.0};
