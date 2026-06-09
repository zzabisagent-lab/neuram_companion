import 'dart:convert';
import 'dart:io';
import 'engine.dart';

/// S1=JSON(간단). S2+에서 mmap 바이너리로 교체.
/// PN→KC는 seed로 재생성되므로 학습된 KC→MBON만 저장.
void saveConnectome(Connectome c, String path) {
  final syn = <Map<String, dynamic>>[];
  for (final s in c.pool.raw) {
    if (s.active) syn.add({'pre': s.pre, 'post': s.post, 'w': s.weight, 'tu': s.tLastUsed});
  }
  File(path).writeAsStringSync(jsonEncode({'t': c.t, 'formed': c.formed, 'pruned': c.pruned, 'syn': syn}));
}

void loadConnectome(Connectome c, String path) {
  final f = File(path);
  if (!f.existsSync()) return;
  final d = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
  c.t = d['t'] as int;
  for (final m in (d['syn'] as List)) {
    c.pool.create(m['pre'] as int, m['post'] as int, (m['w'] as num).toDouble(), m['tu'] as int);
  }
}
