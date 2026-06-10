import 'dart:io';
import '../lib/twin/regimes.dart';
import '../lib/twin/runner.dart';
import '../lib/twin/report.dart';

/// 사용법: dart run bin/twin_week.dart [independent|continual|all]
/// 인자 없으면 independent.
void main(List<String> args) {
  final arg = args.isEmpty ? 'independent' : args.first.toLowerCase();
  final cfg = twinConfig();
  final regimes = defaultRegimes();

  final modes = <PlanMode>[];
  if (arg == 'all') {
    modes.addAll([PlanMode.independent, PlanMode.continual]);
  } else if (arg == 'continual') {
    modes.add(PlanMode.continual);
  } else {
    modes.add(PlanMode.independent); // independent / 미지정 / 미지원 인자
  }

  for (final m in modes) {
    runAndWrite(SimPlan(m, regimes), cfg);
    final suffix = m == PlanMode.continual ? '_continual' : '';
    _printSummary(m.name, suffix);
  }

  writeManifest({
    'seed': cfg.seed,
    'nKC': cfg.nKC,
    'pruneTau': cfg.pruneTau,
    'lr': cfg.lr,
    'kWTA': cfg.kWTA,
    'clock': {
      'ticksPerHour': 60,
      'awakeHours': 16,
      'sleepHours': 8,
      'days': 7,
    },
    'plan': modes.map((m) => m.name).toList(),
    'regimes': regimes.map((r) => r.name).toList(),
    'generatedAt': DateTime.now().toIso8601String(),
  });
}

void _printSummary(String modeName, String suffix) {
  final f = File('out/comparison$suffix.csv');
  if (!f.existsSync()) return;
  print('=== $modeName : out/comparison$suffix.csv ===');
  for (final line in f.readAsLinesSync()) {
    print(line);
  }
  print('');
}
