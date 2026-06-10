import 'dart:io';
import '../lib/twin/campaign.dart';
import '../lib/twin/runner.dart'; // twinConfig

/// 디지털 트윈 장기 육성 캠페인 CLI.
///
/// 사용법:
///   dart run bin/twin_campaign.dart run <regime> <week> <days> [dateLabel]
///   dart run bin/twin_campaign.dart status
///
/// 예: dart run bin/twin_campaign.dart run R1_nurturing 1 3 2026-06-13
const String kPurpose =
    '안정 애착·변별·회복탄력성을 갖춘 디지털 트윈 육성: '
    '양육자 신호(소리A)에 대한 강한 접근(probeA↑), 무관 신호(소리B) 변별(probeB↓), '
    '진짜 위협 학습 시 적절한 회피(avoidIndex), 시냅스 붕괴 없는 가소성 유지.';

const Map<String, dynamic> kTarget = {
  'probeA': '>= 0.70',
  'probeB': '<= 0.30',
  'probeNovel': '0.2 ~ 0.6',
  'approachIndex': '>= 0.35',
  'avoidIndex': '문맥의존(위협주 >=0.30, 평시 낮음)',
  'activeSynapses': '8 ~ 48 (붕괴/폭주 없음)',
};

void main(List<String> args) {
  if (args.isEmpty) {
    _usage();
    return;
  }
  switch (args.first) {
    case 'run':
      _run(args.sublist(1));
      break;
    case 'status':
      _status();
      break;
    default:
      _usage();
  }
}

void _usage() {
  stdout.writeln('Usage:');
  stdout.writeln('  dart run bin/twin_campaign.dart run <regime> <week> <days> [dateLabel]');
  stdout.writeln('  dart run bin/twin_campaign.dart status');
  stdout.writeln('  regimes: R1_nurturing R2_neglect R3_harsh R4_intermittent R5_shift');
}

void _run(List<String> a) {
  if (a.length < 3) {
    _usage();
    return;
  }
  final regimeName = a[0];
  final week = int.parse(a[1]);
  final days = int.parse(a[2]);
  final dateLabel = a.length >= 4 ? a[3] : _today();

  final regime = regimeByName(regimeName);
  if (regime == null) {
    stderr.writeln('Unknown regime: $regimeName');
    return;
  }

  final cfg = twinConfig();
  final log = runCampaignWeek(
      regime: regime, week: week, days: days, cfg: cfg);
  appendHistory(log, week, dateLabel);
  writeWeekMetricsReport(
    log: log,
    week: week,
    days: days,
    regimeName: regimeName,
    cfg: cfg,
    dateLabel: dateLabel,
    target: kTarget,
  );

  // 상태 갱신(누적 formed/pruned는 주간 델타 합산).
  final state = loadState();
  final prevCumFormed = (state['cumFormed'] as int?) ?? 0;
  final prevCumPruned = (state['cumPruned'] as int?) ?? 0;
  final f = log.last;
  final hist = (state['history'] as List?)?.cast<Map<String, dynamic>>() ??
      <Map<String, dynamic>>[];
  hist.add({
    'week': week,
    'regime': regimeName,
    'days': days,
    'date': dateLabel,
    'probeA': double.parse(f.probeA.toStringAsFixed(3)),
    'probeB': double.parse(f.probeB.toStringAsFixed(3)),
    'probeNovel': double.parse(f.probeNovel.toStringAsFixed(3)),
    'approachIndex': double.parse(f.approachIndex.toStringAsFixed(3)),
    'avoidIndex': double.parse(f.avoidIndex.toStringAsFixed(3)),
    'activeSynapses': f.activeSynapses,
    'weekFormed': f.cumFormed,
    'weekPruned': f.cumPruned,
  });

  final now = DateTime.now().toIso8601String();
  state['purpose'] = kPurpose;
  state['target'] = kTarget;
  state['createdAt'] = state['createdAt'] ?? now;
  state['updatedAt'] = now;
  state['week'] = week;
  state['lastRegime'] = regimeName;
  state['lastDays'] = days;
  state['lastDate'] = dateLabel;
  state['cumFormed'] = prevCumFormed + f.cumFormed;
  state['cumPruned'] = prevCumPruned + f.cumPruned;
  state['finalMetrics'] = {
    'probeA': double.parse(f.probeA.toStringAsFixed(3)),
    'probeB': double.parse(f.probeB.toStringAsFixed(3)),
    'probeNovel': double.parse(f.probeNovel.toStringAsFixed(3)),
    'approachIndex': double.parse(f.approachIndex.toStringAsFixed(3)),
    'avoidIndex': double.parse(f.avoidIndex.toStringAsFixed(3)),
    'activeSynapses': f.activeSynapses,
    'meanWeight': double.parse(f.meanWeight.toStringAsFixed(3)),
    'kcSparsity': double.parse(f.kcSparsity.toStringAsFixed(3)),
  };
  state['history'] = hist;
  saveState(state);

  // 콘솔 요약(cron-fired Claude가 읽음).
  stdout.writeln('=== Campaign Week $week ($regimeName, ${days}d, $dateLabel) ===');
  stdout.writeln('probeA=${f.probeA.toStringAsFixed(3)} '
      'probeB=${f.probeB.toStringAsFixed(3)} '
      'probeNovel=${f.probeNovel.toStringAsFixed(3)}');
  stdout.writeln('approach=${f.approachIndex.toStringAsFixed(3)} '
      'avoid=${f.avoidIndex.toStringAsFixed(3)} '
      'active=${f.activeSynapses} weekFormed=${f.cumFormed} weekPruned=${f.cumPruned}');
  stdout.writeln('cumFormed=${state['cumFormed']} cumPruned=${state['cumPruned']}');
  stdout.writeln('metrics report → $kReportsDir/week_${week.toString().padLeft(2, '0')}_metrics.md');
}

void _status() {
  final f = File(kStatePath);
  if (!f.existsSync()) {
    stdout.writeln('(no campaign state yet — run week 1 first)');
    return;
  }
  stdout.writeln(f.readAsStringSync());
}

String _today() {
  final d = DateTime.now();
  return '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
