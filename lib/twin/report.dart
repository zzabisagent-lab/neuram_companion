import 'dart:convert';
import 'dart:io';
import 'metrics.dart';

void _ensureOut() {
  final d = Directory('out');
  if (!d.existsSync()) d.createSync(recursive: true);
}

void writeMetricsCsv(MetricsLog log, {String suffix = ''}) {
  _ensureOut();
  final sb = StringBuffer();
  sb.writeln(kMetricsFields.join(','));
  for (final r in log.rows) {
    sb.writeln(r.cells.join(','));
  }
  File('out/metrics_${log.regime}$suffix.csv').writeAsStringSync(sb.toString());
}

void writeRegimeReport(MetricsLog log, Map<String, dynamic> cfg,
    {String suffix = ''}) {
  _ensureOut();
  final sb = StringBuffer();
  final continual = suffix.isNotEmpty;
  sb.writeln('# Twin Weekly Report — ${log.regime}${continual ? ' (continual)' : ''}');
  sb.writeln();
  sb.writeln('## Config');
  cfg.forEach((k, v) => sb.writeln('- $k: $v'));
  sb.writeln();
  sb.writeln('## Daily metrics');
  sb.writeln('| ${kMetricsFields.join(' | ')} |');
  sb.writeln('|${kMetricsFields.map((_) => '---').join('|')}|');
  for (final r in log.rows) {
    sb.writeln('| ${r.cells.join(' | ')} |');
  }
  sb.writeln();
  final f = log.last;
  sb.writeln('## Final (day ${f.day})');
  sb.writeln('- probeA=${f.probeA.toStringAsFixed(3)}  '
      'probeB=${f.probeB.toStringAsFixed(3)}  '
      'probeNovel=${f.probeNovel.toStringAsFixed(3)}');
  sb.writeln('- approachIndex=${f.approachIndex.toStringAsFixed(3)}  '
      'avoidIndex=${f.avoidIndex.toStringAsFixed(3)}');
  sb.writeln('- activeSynapses=${f.activeSynapses}  '
      'cumFormed=${f.cumFormed}  cumPruned=${f.cumPruned}');
  sb.writeln('- meanWeight=${f.meanWeight.toStringAsFixed(3)}  '
      'kcSparsity=${f.kcSparsity.toStringAsFixed(3)}');
  File('out/report_${log.regime}$suffix.md').writeAsStringSync(sb.toString());
}

void writeComparison(List<MetricsLog> logs, Map<String, dynamic> cfg,
    {String suffix = ''}) {
  _ensureOut();
  final continual = suffix.isNotEmpty;

  // CSV: regime × 최종 메트릭
  final csv = StringBuffer();
  csv.writeln(['regime', ...kMetricsFields].join(','));
  for (final log in logs) {
    csv.writeln([log.regime, ...log.last.cells].join(','));
  }
  File('out/comparison$suffix.csv').writeAsStringSync(csv.toString());

  // MD: 최종 상태 비교표 + 읽기 가이드
  final md = StringBuffer();
  md.writeln('# Regime Comparison${continual ? ' (continual)' : ''}');
  md.writeln();
  md.writeln('| regime | probeA | probeB | probeNovel | approach | avoid | active | formed | pruned |');
  md.writeln('|---|---|---|---|---|---|---|---|---|');
  for (final log in logs) {
    final r = log.last;
    md.writeln('| ${log.regime} '
        '| ${r.probeA.toStringAsFixed(3)} '
        '| ${r.probeB.toStringAsFixed(3)} '
        '| ${r.probeNovel.toStringAsFixed(3)} '
        '| ${r.approachIndex.toStringAsFixed(3)} '
        '| ${r.avoidIndex.toStringAsFixed(3)} '
        '| ${r.activeSynapses} '
        '| ${r.cumFormed} '
        '| ${r.cumPruned} |');
  }
  md.writeln();
  md.writeln('## Reading guide');
  md.writeln('- **R1 nurturing**: probeA 최고, pruned≈0 — 안정적 긍정 연합(상한).');
  md.writeln('- **R2 neglect**: 약/무연합, 미사용 가지치기>0 — S1이 못 본 가지치기 절반.');
  md.writeln('- **R3 harsh**: avoidIndex 상승(처벌 구획), 일시 2차 CS 미사용으로 pruned>0.');
  md.writeln('- **R4 intermittent**: 50% 보상에도 연합 형성, 소거 저항.');
  md.writeln('- **R5 shift**: 보상이 B로 이전 → probeA 하락(소거/역조건화), probeB 상승.');
  md.writeln();
  md.writeln('## Config');
  cfg.forEach((k, v) => md.writeln('- $k: $v'));
  File('out/comparison$suffix.md').writeAsStringSync(md.toString());
}

void writeManifest(Map<String, dynamic> manifest) {
  _ensureOut();
  File('out/run_manifest.json')
      .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(manifest));
}
