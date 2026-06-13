import '../engine/halfmb/engine.dart';
import 'test_battery.dart';

/// CSV/표 컬럼 순서(단일 진실원).
const List<String> kMetricsFields = [
  'day',
  'activeSynapses',
  'cumFormed',
  'cumPruned',
  'probeA',
  'probeB',
  'probeNovel',
  'approachIndex',
  'avoidIndex',
  'netA',
  'netB',
  'netNovel',
  'meanWeight',
  'kcSparsity',
];

class MetricsRow {
  final int day;
  final int activeSynapses;
  final int cumFormed;
  final int cumPruned;
  final double probeA;
  final double probeB;
  final double probeNovel;
  final double approachIndex;
  final double avoidIndex;
  final double netA;
  final double netB;
  final double netNovel;
  final double meanWeight;
  final double kcSparsity;

  MetricsRow({
    required this.day,
    required this.activeSynapses,
    required this.cumFormed,
    required this.cumPruned,
    required this.probeA,
    required this.probeB,
    required this.probeNovel,
    required this.approachIndex,
    required this.avoidIndex,
    required this.netA,
    required this.netB,
    required this.netNovel,
    required this.meanWeight,
    required this.kcSparsity,
  });

  /// kMetricsFields 순서. 정수는 그대로, 실수는 소수 3자리.
  List<String> get cells => [
        day.toString(),
        activeSynapses.toString(),
        cumFormed.toString(),
        cumPruned.toString(),
        probeA.toStringAsFixed(3),
        probeB.toStringAsFixed(3),
        probeNovel.toStringAsFixed(3),
        approachIndex.toStringAsFixed(3),
        avoidIndex.toStringAsFixed(3),
        netA.toStringAsFixed(3),
        netB.toStringAsFixed(3),
        netNovel.toStringAsFixed(3),
        meanWeight.toStringAsFixed(3),
        kcSparsity.toStringAsFixed(3),
      ];
}

class MetricsLog {
  final String regime;
  final List<MetricsRow> rows = [];
  MetricsLog(this.regime);

  /// 고정 배터리 프로브 + 풀 카운터를 한 행으로 적재.
  void snapshot(Connectome cx, int dayLabel) {
    final b = runBattery(cx);
    rows.add(MetricsRow(
      day: dayLabel,
      activeSynapses: cx.pool.activeCount,
      cumFormed: cx.formed,
      cumPruned: cx.pruned,
      probeA: b.probeA,
      probeB: b.probeB,
      probeNovel: b.probeNovel,
      approachIndex: b.approachIndex,
      avoidIndex: b.avoidIndex,
      netA: b.netA,
      netB: b.netB,
      netNovel: b.netNovel,
      meanWeight: b.meanWeight,
      kcSparsity: b.kcSparsity,
    ));
  }

  MetricsRow get last => rows.last;
}
