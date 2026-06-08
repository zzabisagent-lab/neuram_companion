import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'model.dart';

/// 바이너리 연결체 저장/로드 (원리 1·4, D-022).
/// Neuron record: id(4) type(1) tier(1) value(8) baseline(8) = 22 bytes
/// Synapse record: preId(4) postId(4) weight(8) tier(1) plastic(1)
///                 depression(8) depIncr(8) depTauSec(8) tLastMs(8) = 50 bytes
class Persistence {
  static const _magic = 0x4E52414D; // 'NRAM'
  static const _version = 1;

  Future<String> _docDir() async {
    final d = await getApplicationDocumentsDirectory();
    final sub = Directory('${d.path}/neuram');
    if (!await sub.exists()) await sub.create(recursive: true);
    return sub.path;
  }

  Future<Map<String, dynamic>?> loadMeta() async {
    try {
      final dir = await _docDir();
      final f = File('$dir/meta.json');
      if (!await f.exists()) return null;
      return jsonDecode(await f.readAsString()) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<(Map<int, Neuron>, List<Synapse>)?> load() async {
    try {
      final dir = await _docDir();
      final binFile = File('$dir/connectome.bin');
      if (!await binFile.exists()) return null;

      final bytes = await binFile.readAsBytes();
      final bd = ByteData.sublistView(bytes);
      int off = 0;

      final magic = bd.getUint32(off, Endian.little); off += 4;
      final ver = bd.getUint32(off, Endian.little); off += 4;
      final nCount = bd.getUint32(off, Endian.little); off += 4;
      final sCount = bd.getUint32(off, Endian.little); off += 4;

      if (magic != _magic || ver != _version) return null;

      final neurons = <int, Neuron>{};
      for (int i = 0; i < nCount; i++) {
        final id = bd.getInt32(off, Endian.little); off += 4;
        final type = NeuronType.values[bd.getUint8(off)]; off += 1;
        final tier = Tier.values[bd.getUint8(off)]; off += 1;
        final value = bd.getFloat64(off, Endian.little); off += 8;
        final baseline = bd.getFloat64(off, Endian.little); off += 8;
        neurons[id] = Neuron(id, type, tier, value: value, baseline: baseline);
      }

      final synapses = <Synapse>[];
      for (int i = 0; i < sCount; i++) {
        final preId = bd.getInt32(off, Endian.little); off += 4;
        final postId = bd.getInt32(off, Endian.little); off += 4;
        final weight = bd.getFloat64(off, Endian.little); off += 8;
        final tier = Tier.values[bd.getUint8(off)]; off += 1;
        final plastic = bd.getUint8(off) != 0; off += 1;
        final depression = bd.getFloat64(off, Endian.little); off += 8;
        final depIncr = bd.getFloat64(off, Endian.little); off += 8;
        final depTauSec = bd.getFloat64(off, Endian.little); off += 8;
        final tLastMs = bd.getInt64(off, Endian.little); off += 8;
        synapses.add(Synapse(preId, postId, weight, tier,
            plastic: plastic, depression: depression,
            depIncr: depIncr, depTauSec: depTauSec, tLastMs: tLastMs));
      }

      return (neurons, synapses);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(Map<int, Neuron> neurons, List<Synapse> synapses,
      {Map<String, dynamic>? meta}) async {
    final dir = await _docDir();
    final nList = neurons.values.toList();
    const neuronSize = 22;
    const synapseSize = 50;
    final totalBytes = 16 + nList.length * neuronSize + synapses.length * synapseSize;
    final bd = ByteData(totalBytes);
    int off = 0;

    bd.setUint32(off, _magic, Endian.little); off += 4;
    bd.setUint32(off, _version, Endian.little); off += 4;
    bd.setUint32(off, nList.length, Endian.little); off += 4;
    bd.setUint32(off, synapses.length, Endian.little); off += 4;

    for (final n in nList) {
      bd.setInt32(off, n.id, Endian.little); off += 4;
      bd.setUint8(off, n.type.index); off += 1;
      bd.setUint8(off, n.tier.index); off += 1;
      bd.setFloat64(off, n.value, Endian.little); off += 8;
      bd.setFloat64(off, n.baseline, Endian.little); off += 8;
    }

    for (final s in synapses) {
      bd.setInt32(off, s.preId, Endian.little); off += 4;
      bd.setInt32(off, s.postId, Endian.little); off += 4;
      bd.setFloat64(off, s.weight, Endian.little); off += 8;
      bd.setUint8(off, s.tier.index); off += 1;
      bd.setUint8(off, s.plastic ? 1 : 0); off += 1;
      bd.setFloat64(off, s.depression, Endian.little); off += 8;
      bd.setFloat64(off, s.depIncr, Endian.little); off += 8;
      bd.setFloat64(off, s.depTauSec, Endian.little); off += 8;
      bd.setInt64(off, s.tLastMs, Endian.little); off += 8;
    }

    await File('$dir/connectome.bin').writeAsBytes(bd.buffer.asUint8List());

    final metaMap = <String, dynamic>{
      'version': _version,
      'neuronCount': nList.length,
      'synapseCount': synapses.length,
      'savedAt': DateTime.now().millisecondsSinceEpoch,
      ...?meta,
    };
    await File('$dir/meta.json').writeAsString(jsonEncode(metaMap));
  }
}
