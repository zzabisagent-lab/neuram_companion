import 'dart:math';
import '../engine/halfmb/config.dart';
import '../engine/halfmb/engine.dart';
import '../engine/halfmb/topology.dart';
import 'sim_clock.dart';
import 'regime.dart';
import 'metrics.dart';
import 'report.dart';

enum PlanMode { independent, continual }

class SimPlan {
  final PlanMode mode;
  final List<WeeklyRegime> weeks;
  SimPlan(this.mode, this.weeks);
}

/// 트윈 전용 config: HalfMBConfig.s1 필드 그대로 + pruneTau만 600.
/// (HalfMBConfig.s1 자체는 불변. 전 레짐 동일 적용 → 공정 비교.)
HalfMBConfig twinConfig({int pruneTau = 600}) => HalfMBConfig(
      nPN: 6,
      nKC: 64,
      nMBON: 6,
      nCompartments: 2,
      kcFanIn: 4,
      kWTA: 4,
      formThreshold: 0.5,
      lr: 0.06,
      weightFloor: 0.02,
      synScaleTarget: 2.0,
      pruneTau: pruneTau,
      synapseBudgetPerMBON: 48,
      seed: 42,
    );

/// 한 주(7일) 실행. 주 시작 스냅샷 + 일 경계마다 스냅샷.
/// 루프 종료 후 추가 스냅샷 금지(마지막 일 경계에서 이미 캡처 → 중복행 방지).
MetricsLog runWeek(
  WeeklyRegime regime,
  Connectome cx,
  MetricsLog log,
  Random rng, {
  int dayOffset = 0,
}) {
  final clk = SimClock();
  log.snapshot(cx, dayOffset + clk.day); // 주 시작 = day 0
  int lastDay = clk.day;
  while (clk.tick < clk.totalTicks) {
    final it = regime.at(clk, rng);
    cx.step(it?.inputs ?? const <int, double>{},
        it?.valence ?? const <int, double>{});
    clk.tick++;
    if (clk.day != lastDay) {
      lastDay = clk.day;
      log.snapshot(cx, dayOffset + clk.day);
    }
  }
  return log;
}

List<MetricsLog> runPlan(SimPlan plan, HalfMBConfig cfg) {
  final logs = <MetricsLog>[];
  if (plan.mode == PlanMode.independent) {
    // 주마다 새 connectome(같은 seed) + 새 Random(777).
    for (final r in plan.weeks) {
      final cx = buildHalfMB(cfg);
      final rng = Random(777);
      final log = MetricsLog(r.name);
      runWeek(r, cx, log, rng);
      logs.add(log);
    }
  } else {
    // connectome 하나 이월 + Random(777) 이월 + dayOffset=wi*7.
    final cx = buildHalfMB(cfg);
    final rng = Random(777);
    for (var wi = 0; wi < plan.weeks.length; wi++) {
      final r = plan.weeks[wi];
      final log = MetricsLog(r.name);
      runWeek(r, cx, log, rng, dayOffset: wi * 7);
      logs.add(log);
    }
  }
  return logs;
}

Map<String, dynamic> cfgMap(HalfMBConfig c, SimPlan plan) => {
      'mode': plan.mode.name,
      'seed': c.seed,
      'nKC': c.nKC,
      'pruneTau': c.pruneTau,
      'lr': c.lr,
      'kWTA': c.kWTA,
      'formThreshold': c.formThreshold,
      'weightFloor': c.weightFloor,
      'ticksPerHour': 60,
      'awakeHours': 16,
      'sleepHours': 8,
      'days': 7,
      'weeks': plan.weeks.map((w) => w.name).toList(),
    };

void runAndWrite(SimPlan plan, HalfMBConfig cfg) {
  final logs = runPlan(plan, cfg);
  final suffix = plan.mode == PlanMode.continual ? '_continual' : '';
  final cm = cfgMap(cfg, plan);
  for (final log in logs) {
    writeMetricsCsv(log, suffix: suffix);
    writeRegimeReport(log, cm, suffix: suffix);
  }
  writeComparison(logs, cm, suffix: suffix);
}
