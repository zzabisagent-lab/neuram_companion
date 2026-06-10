import 'dart:math';
import 'sim_clock.dart';
import 'regime.dart';

/// R1 양육: 규칙적 긍정. 각성 중 30틱마다 소리A + 보상.
class NurturingRegime extends WeeklyRegime {
  @override
  String get name => 'R1_nurturing';

  @override
  Interaction? at(SimClock t, Random rng) {
    if (!t.awake) return null;
    if (t.tick % 30 == 0) return Interaction(soundA, {rewardComp: 1.0});
    return null;
  }
}

/// R2 방임: 희소·긴 idle. 하루 1회(tickInDay==300) 약자극, 보상 확률 40%.
class NeglectRegime extends WeeklyRegime {
  @override
  String get name => 'R2_neglect';

  @override
  Interaction? at(SimClock t, Random rng) {
    if (!t.awake) return null;
    if (t.tickInDay == 300) {
      return Interaction(
        {0: 0.7, 1: 0.6},
        rng.nextDouble() < 0.4 ? {rewardComp: 1.0} : <int, double>{},
      );
    }
    return null;
  }
}

/// R3 엄격: 부정 valence 빈발. 종일 1차 혐오 CS(loudA, 40틱) +
/// 오전 한정(tickInDay<300) 일시 2차 CS(loudB/흔듦) → 2차 CS 미사용 가지치기.
class HarshRegime extends WeeklyRegime {
  @override
  String get name => 'R3_harsh';

  @override
  Interaction? at(SimClock t, Random rng) {
    if (!t.awake) return null;
    if (t.tick % 40 == 0) return Interaction(loudA, {punishComp: 1.0});
    if (t.tickInDay < 300) {
      final p = t.tickInDay % 40;
      if (p == 13) return Interaction(loudB, {punishComp: 1.0});
      if (p == 26) return Interaction(shake, {punishComp: 1.0});
    }
    return null;
  }
}

/// R4 변동강화: 부분 강화. 30틱마다 소리A, 보상 확률 50%.
class IntermittentRegime extends WeeklyRegime {
  @override
  String get name => 'R4_intermittent';

  @override
  Interaction? at(SimClock t, Random rng) {
    if (!t.awake) return null;
    if (t.tick % 30 == 0) {
      return Interaction(
        soundA,
        rng.nextDouble() < 0.5 ? {rewardComp: 1.0} : <int, double>{},
      );
    }
    return null;
  }
}

/// R5 전환: 소거→재학습. 전반(weekFraction<0.5) A+보상 →
/// 후반 보상이 B로 이전 + A 역조건화(-0.3).
class ShiftRegime extends WeeklyRegime {
  @override
  String get name => 'R5_shift';

  @override
  Interaction? at(SimClock t, Random rng) {
    if (!t.awake) return null;
    if (t.weekFraction < 0.5) {
      if (t.tick % 30 == 0) return Interaction(soundA, {rewardComp: 1.0});
    } else {
      if (t.tick % 30 == 0) return Interaction(soundB, {rewardComp: 1.0});
      if (t.tick % 30 == 15) return Interaction(soundA, {rewardComp: -0.3});
    }
    return null;
  }
}

List<WeeklyRegime> defaultRegimes() => [
      NurturingRegime(),
      NeglectRegime(),
      HarshRegime(),
      IntermittentRegime(),
      ShiftRegime(),
    ];
