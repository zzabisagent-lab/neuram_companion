import 'dart:convert';
import 'dart:io';
import 'dart:math';
import '../engine/halfmb/config.dart';
import '../engine/halfmb/topology.dart';
import '../engine/halfmb/persistence.dart';
import 'sim_clock.dart';
import 'regime.dart';
import 'regimes.dart';
import 'metrics.dart';

/// 디지털 트윈 장기 육성 캠페인.
///
/// twin_week(독립/연속 비교 실험)과 달리, 캠페인은 **하나의 개체**를 실제 달력 주
/// 단위로 계속 학습시키는 종단(longitudinal) 운영이다. connectome을 디스크에 영속
/// 하여 매주 이월하고, 주차별 리포트를 누적한다. 매 실행은 새 프로세스이므로 상태는
/// 전부 파일(`campaign/`)에 보관한다.
const String kCampaignDir = 'campaign';
const String kConnectomePath = '$kCampaignDir/connectome.json';
const String kStatePath = '$kCampaignDir/state.json';
const String kHistoryPath = '$kCampaignDir/history.csv';
const String kReportsDir = '$kCampaignDir/reports';

/// 이름으로 레짐 조회 (R1~R5).
WeeklyRegime? regimeByName(String name) {
  for (final r in defaultRegimes()) {
    if (r.name == name) return r;
  }
  return null;
}

void ensureCampaignDirs() {
  for (final d in [kCampaignDir, kReportsDir]) {
    final dir = Directory(d);
    if (!dir.existsSync()) dir.createSync(recursive: true);
  }
}

Map<String, dynamic> loadState() {
  final f = File(kStatePath);
  if (!f.existsSync()) return <String, dynamic>{};
  return jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
}

void saveState(Map<String, dynamic> state) {
  ensureCampaignDirs();
  File(kStatePath)
      .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(state));
}

/// 한 주(또는 N일) 실행. connectome 이월(있으면 로드) → 학습 → 저장.
/// 반환 MetricsLog의 cumFormed/cumPruned는 **이번 주 델타**(새 프로세스 카운터).
MetricsLog runCampaignWeek({
  required WeeklyRegime regime,
  required int week,
  required int days,
  required HalfMBConfig cfg,
}) {
  ensureCampaignDirs();
  final cx = buildHalfMB(cfg);
  // 이월: 기존 connectome 있으면 로드(KC→MBON 시냅스 + t 복원).
  if (File(kConnectomePath).existsSync()) {
    loadConnectome(cx, kConnectomePath);
  }
  final rng = Random(777 + week); // 주마다 재현 가능한 별도 난수 흐름
  final log = MetricsLog(regime.name);
  final clk = SimClock(days: days);

  log.snapshot(cx, 0); // 주 시작 스냅샷(day 0)
  int lastDay = 0;
  while (clk.tick < clk.totalTicks) {
    final it = regime.at(clk, rng);
    cx.step(it?.inputs ?? const <int, double>{},
        it?.valence ?? const <int, double>{});
    clk.tick++;
    if (clk.day != lastDay) {
      lastDay = clk.day;
      log.snapshot(cx, clk.day);
    }
  }
  saveConnectome(cx, kConnectomePath);
  return log;
}

/// 주간 학습곡선을 campaign/history.csv에 누적(일별 행).
void appendHistory(MetricsLog log, int week, String dateLabel) {
  ensureCampaignDirs();
  final f = File(kHistoryPath);
  final sb = StringBuffer();
  if (!f.existsSync()) {
    sb.writeln(['week', 'date', ...kMetricsFields].join(','));
  }
  for (final r in log.rows) {
    sb.writeln([week, dateLabel, ...r.cells].join(','));
  }
  f.writeAsStringSync(sb.toString(), mode: FileMode.append);
}

/// 주간 메트릭 리포트(자동 생성 부분: 설정·일별표·최종·목표대비).
/// 서술 분석은 Claude가 별도 .md로 덧붙인다.
void writeWeekMetricsReport({
  required MetricsLog log,
  required int week,
  required int days,
  required String regimeName,
  required HalfMBConfig cfg,
  required String dateLabel,
  required Map<String, dynamic> target,
}) {
  ensureCampaignDirs();
  final f = log.last;
  final sb = StringBuffer();
  sb.writeln('# Campaign Week $week — metrics ($regimeName)');
  sb.writeln();
  sb.writeln('- date: $dateLabel  |  days: $days  |  regime: $regimeName');
  sb.writeln('- config: nKC=${cfg.nKC} seed=${cfg.seed} pruneTau=${cfg.pruneTau} '
      'lr=${cfg.lr} kWTA=${cfg.kWTA}');
  sb.writeln();
  sb.writeln('## Daily metrics');
  sb.writeln('| ${kMetricsFields.join(' | ')} |');
  sb.writeln('|${kMetricsFields.map((_) => '---').join('|')}|');
  for (final r in log.rows) {
    sb.writeln('| ${r.cells.join(' | ')} |');
  }
  sb.writeln();
  sb.writeln('## Final vs target');
  sb.writeln('| metric | final | target |');
  sb.writeln('|---|---|---|');
  sb.writeln('| probeA | ${f.probeA.toStringAsFixed(3)} | ${target['probeA']} |');
  sb.writeln('| probeB | ${f.probeB.toStringAsFixed(3)} | ${target['probeB']} |');
  sb.writeln('| probeNovel | ${f.probeNovel.toStringAsFixed(3)} | ${target['probeNovel']} |');
  sb.writeln('| approachIndex | ${f.approachIndex.toStringAsFixed(3)} | ${target['approachIndex']} |');
  sb.writeln('| avoidIndex | ${f.avoidIndex.toStringAsFixed(3)} | ${target['avoidIndex']} |');
  sb.writeln('| netA | ${f.netA.toStringAsFixed(3)} | ${target['netA']} |');
  sb.writeln('| netB | ${f.netB.toStringAsFixed(3)} | ${target['netB']} |');
  sb.writeln('| activeSynapses | ${f.activeSynapses} | ${target['activeSynapses']} |');
  sb.writeln('| meanWeight | ${f.meanWeight.toStringAsFixed(3)} | — |');
  sb.writeln('| kcSparsity | ${f.kcSparsity.toStringAsFixed(3)} | — |');
  sb.writeln('| weekFormed | ${f.cumFormed} | — |');
  sb.writeln('| weekPruned | ${f.cumPruned} | — |');
  File('$kReportsDir/week_${week.toString().padLeft(2, '0')}_metrics.md')
      .writeAsStringSync(sb.toString());
}
