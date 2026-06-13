import 'dart:io';
import 'dart:math';
import '../lib/engine/halfmb/topology.dart';
import '../lib/twin/runner.dart';
import '../lib/twin/sim_clock.dart';
import '../lib/twin/regime.dart';
import '../lib/twin/regimes.dart';
import '../lib/twin/test_battery.dart';

const String kOutDir = 'out/valence';

class DayRow {
  final int day;
  final int active;
  final BatteryResult b;
  DayRow(this.day, this.active, this.b);
}

List<DayRow> runRegime(WeeklyRegime regime, double opponentAlpha, int days) {
  final cfg = twinConfig(opponentAlpha: opponentAlpha);
  final cx = buildHalfMB(cfg);
  final rng = Random(777);
  final clk = SimClock(days: days);
  final rows = <DayRow>[DayRow(0, cx.pool.activeCount, runBattery(cx))];
  int lastDay = 0;
  while (clk.tick < clk.totalTicks) {
    final it = regime.at(clk, rng);
    cx.step(it?.inputs ?? const <int, double>{},
        it?.valence ?? const <int, double>{});
    clk.tick++;
    if (clk.day != lastDay) {
      lastDay = clk.day;
      rows.add(DayRow(clk.day, cx.pool.activeCount, runBattery(cx)));
    }
  }
  return rows;
}

void writeCsv(String name, List<DayRow> rows) {
  final sb = StringBuffer();
  sb.writeln('day,active,probeA,probeApunish,netA,probeB,probeBpunish,netB,approachIndex,avoidIndex,netIndex');
  for (final r in rows) {
    final b = r.b;
    sb.writeln([
      r.day, r.active,
      b.probeA.toStringAsFixed(3), b.probeApunish.toStringAsFixed(3), b.netA.toStringAsFixed(3),
      b.probeB.toStringAsFixed(3), b.probeBpunish.toStringAsFixed(3), b.netB.toStringAsFixed(3),
      b.approachIndex.toStringAsFixed(3), b.avoidIndex.toStringAsFixed(3), b.netIndex.toStringAsFixed(3),
    ].join(','));
  }
  File('$kOutDir/$name.csv').writeAsStringSync(sb.toString());
}

String pf(bool ok) => ok ? 'PASS' : 'FAIL';

void main() {
  Directory(kOutDir).createSync(recursive: true);
  final sb = StringBuffer();
  sb.writeln('# Valence engine validation — opponent plasticity (D-028)');
  sb.writeln('\nseed=42, rng=777. opponentAlpha: baseline=0.0, opponent=0.5\n');

  // REG: 회귀(R1, α=0) — 기존 베이스라인 보존
  final reg = runRegime(NurturingRegime(), 0.0, 7);
  writeCsv('reg_R1_a0', reg);
  final regA = reg.last.b.probeA;
  final regPass = regA >= 0.80 && regA <= 0.87;
  sb.writeln('## REG (R1, α=0) 회귀');
  sb.writeln('- probeA_final=${regA.toStringAsFixed(3)} (기대 0.80~0.87) → ${pf(regPass)}\n');

  // V1: 변별 R6(α=0.5)
  final v1 = runRegime(ValenceDiscriminationRegime(), 0.5, 7);
  writeCsv('v1_R6_a05', v1);
  final netA1 = v1.last.b.netA, netB1 = v1.last.b.netB;
  final v1Pass = netA1 >= 0.30 && netB1 <= -0.20;
  sb.writeln('## V1 (R6 변별, α=0.5)');
  sb.writeln('- netA_final=${netA1.toStringAsFixed(3)} (기대 ≥ +0.30), netB_final=${netB1.toStringAsFixed(3)} (기대 ≤ −0.20) → ${pf(v1Pass)}\n');

  // V2: 충돌/역전 R7(α=0.5) — 처벌이 접근을 실제 억제하는가(부호 역전)
  final v2 = runRegime(ConflictReversalRegime(), 0.5, 8);
  writeCsv('v2_R7_a05', v2);
  final mid2 = v2[v2.length ~/ 2].b.netA, end2 = v2.last.b.netA;
  final v2Pass = mid2 >= 0.30 && end2 <= -0.10;
  sb.writeln('## V2 (R7 충돌/역전, α=0.5)');
  sb.writeln('- netA(build종료)=${mid2.toStringAsFixed(3)} (기대 ≥ +0.30), netA_final=${end2.toStringAsFixed(3)} (기대 ≤ −0.10, 부호 역전) → ${pf(v2Pass)}\n');

  // V3: ablation — 같은 R7을 α=0(기존)로. 신규가 접근을 더 강하게 억제해야 함.
  final v3 = runRegime(ConflictReversalRegime(), 0.0, 8);
  writeCsv('v3_R7_a0', v3);
  final end3 = v3.last.b.netA;
  final delta = end3 - end2;
  final v3Pass = delta >= 0.20;
  sb.writeln('## V3 (ablation: R7 α=0 vs α=0.5)');
  sb.writeln('- netA_final α=0=${end3.toStringAsFixed(3)}, α=0.5=${end2.toStringAsFixed(3)}, Δ=${delta.toStringAsFixed(3)} (기대 ≥ +0.20) → ${pf(v3Pass)}\n');

  final all = regPass && v1Pass && v2Pass && v3Pass;
  sb.writeln('## 종합: ${pf(all)}');
  File('$kOutDir/summary.md').writeAsStringSync(sb.toString());
  stdout.writeln(sb.toString());
}
