import 'dart:convert';
import 'dart:io';
import '../lib/twin/campaign.dart';
import '../lib/twin/runner.dart'; // twinConfig

/// 디지털 트윈 장기 육성 캠페인 CLI.
///
/// 사용법:
///   dart run bin/twin_campaign.dart run <regime> <week> <days> [dateLabel]
///   dart run bin/twin_campaign.dart auto      # 상태+커리큘럼으로 다음 주 자동 실행(무인 스케줄러용)
///   dart run bin/twin_campaign.dart next      # auto가 실행할 내용 미리보기(부작용 없음)
///   dart run bin/twin_campaign.dart status
const String kPurpose = '안정 애착·변별·회복탄력성을 갖춘 디지털 트윈 육성: '
    '양육자 신호(소리A)에 대한 강한 접근(probeA↑), 무관 신호(소리B) 변별(probeB↓), '
    '진짜 위협 학습 시 적절한 회피(avoidIndex), 시냅스 붕괴 없는 가소성 유지.';

const Map<String, dynamic> kTarget = {
  'probeA': '>= 0.70',
  'probeB': '<= 0.30',
  'probeNovel': '0.2 ~ 0.6',
  'approachIndex': '>= 0.35',
  'avoidIndex': '문맥의존(위협주 >=0.30, 평시 낮음)',
  'activeSynapses': '8 ~ 48 (붕괴/폭주 없음)',
  'netA': '식욕주(R6/R7전반/R1) >= +0.30, 처벌 후(R7후반) 음수로 역전',
  'netB': '혐오주(R6) <= -0.20, 무관 주 ~0',
};

// 커리큘럼 기본값(campaign/curriculum.json 없을 때 폴백).
const List<String> kDefaultPlan = [
  'R1_nurturing', 'R6_valence', 'R7_conflict', 'R5_shift', 'R1_nurturing',
];
const int kLoopFrom = 2; // 1-based
const int kDaysPerWeek = 6;

void main(List<String> args) {
  if (args.isEmpty) {
    _usage();
    return;
  }
  switch (args.first) {
    case 'run':
      _run(args.sublist(1));
      break;
    case 'auto':
      _auto(execute: true);
      break;
    case 'next':
      _auto(execute: false);
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
  stdout.writeln('  dart run bin/twin_campaign.dart auto    # 무인 스케줄러용 자동 실행');
  stdout.writeln('  dart run bin/twin_campaign.dart next    # auto 미리보기(부작용 없음)');
  stdout.writeln('  dart run bin/twin_campaign.dart status');
  stdout.writeln('  regimes: R1_nurturing R2_neglect R3_harsh R4_intermittent R5_shift');
}

// ── 커리큘럼 ─────────────────────────────────────────────────────

Map<String, dynamic> _loadCurriculum() {
  final f = File('campaign/curriculum.json');
  if (f.existsSync()) {
    return jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
  }
  return {'plan': kDefaultPlan, 'daysPerWeek': kDaysPerWeek, 'loopFrom': kLoopFrom};
}

String _regimeForWeek(int week, List<dynamic> plan, int loopFrom) {
  final idx = week - 1;
  if (idx < plan.length) return plan[idx] as String;
  final tail = plan.sublist(loopFrom - 1);
  return tail[(idx - (loopFrom - 1)) % tail.length] as String;
}

String _upcomingSaturday() {
  final now = DateTime.now();
  var add = (6 - now.weekday) % 7; // Mon=1..Sun=7, Sat=6
  if (add < 0) add += 7;
  final sat = now.add(Duration(days: add));
  return '${sat.year.toString().padLeft(4, '0')}-'
      '${sat.month.toString().padLeft(2, '0')}-'
      '${sat.day.toString().padLeft(2, '0')}';
}

// ── auto / next ──────────────────────────────────────────────────

void _auto({required bool execute}) {
  final state = loadState();
  final cur = _loadCurriculum();
  final plan = (cur['plan'] as List).cast<dynamic>();
  final loopFrom = (cur['loopFrom'] as int?) ?? kLoopFrom;
  final daysPerWeek = (cur['daysPerWeek'] as int?) ?? kDaysPerWeek;

  final week = (state['plannedNextWeek'] as int?) ??
      (((state['week'] as int?) ?? 0) + 1);
  final stopAfterWeek = cur['stopAfterWeek'] as int?;
  if (stopAfterWeek != null && week > stopAfterWeek) {
    stdout.writeln('[campaign] 종료: week $week > stopAfterWeek $stopAfterWeek — 더 이상 실행하지 않습니다.');
    return;
  }
  final regime = (state['plannedNextRegime'] as String?) ??
      _regimeForWeek(week, plan, loopFrom);
  final days = (state['plannedNextDays'] as int?) ?? daysPerWeek;
  final dateLabel = _upcomingSaturday();

  if (!execute) {
    stdout.writeln('[next] week=$week regime=$regime days=$days date=$dateLabel');
    final nextWeek = week + 1;
    stdout.writeln('[next] (이후 기본) week=$nextWeek '
        'regime=${_regimeForWeek(nextWeek, plan, loopFrom)} days=$daysPerWeek');
    return;
  }

  _runCore(regime, week, days, dateLabel);

  // 다음 주 기본값 큐잉(Claude가 리포트에서 override 가능).
  final st = loadState();
  final nextWeek = week + 1;
  st['plannedNextWeek'] = nextWeek;
  st['plannedNextRegime'] = _regimeForWeek(nextWeek, plan, loopFrom);
  st['plannedNextDays'] = daysPerWeek;
  saveState(st);
  stdout.writeln('next planned → week $nextWeek ${st['plannedNextRegime']}');
}

// ── run (수동) ───────────────────────────────────────────────────

void _run(List<String> a) {
  if (a.length < 3) {
    _usage();
    return;
  }
  final regimeName = a[0];
  final week = int.parse(a[1]);
  final days = int.parse(a[2]);
  final dateLabel = a.length >= 4 ? a[3] : _today();
  _runCore(regimeName, week, days, dateLabel);
}

/// 시뮬 실행 + history + 메트릭 리포트 + 상태 갱신(plannedNext는 건드리지 않음).
void _runCore(String regimeName, int week, int days, String dateLabel) {
  final regime = regimeByName(regimeName);
  if (regime == null) {
    stderr.writeln('Unknown regime: $regimeName');
    return;
  }

  final cfg = twinConfig(opponentAlpha: 0.5);
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

  stdout.writeln('=== Campaign Week $week ($regimeName, ${days}d, $dateLabel) ===');
  stdout.writeln('probeA=${f.probeA.toStringAsFixed(3)} '
      'probeB=${f.probeB.toStringAsFixed(3)} '
      'probeNovel=${f.probeNovel.toStringAsFixed(3)}');
  stdout.writeln('approach=${f.approachIndex.toStringAsFixed(3)} '
      'avoid=${f.avoidIndex.toStringAsFixed(3)} '
      'active=${f.activeSynapses} weekFormed=${f.cumFormed} weekPruned=${f.cumPruned}');
  stdout.writeln('cumFormed=${state['cumFormed']} cumPruned=${state['cumPruned']}');
  stdout.writeln('metrics → $kReportsDir/week_${week.toString().padLeft(2, '0')}_metrics.md');
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
