import 'dart:math';
import 'config.dart';
import 'model.dart';
import 'engine.dart';

/// Half-MB 빌드: PN→KC 랜덤 확장은 "씨앗"(고정 시작점, 잠금 아님),
/// KC→MBON은 공백으로 시작해 구조 학습으로 성장.
Connectome buildHalfMB(HalfMBConfig c) {
  final rng = Random(c.seed);
  final neurons = <Neuron>[];
  final pn = <int>[], kc = <int>[], mbon = <int>[], dan = <int>[];
  int id = 0;
  for (var i = 0; i < c.nPN; i++) { neurons.add(Neuron(id, NeuronType.pn)); pn.add(id++); }
  for (var i = 0; i < c.nKC; i++) { neurons.add(Neuron(id, NeuronType.kc)); kc.add(id++); }
  final apl = id; neurons.add(Neuron(id, NeuronType.apl)); id++;
  for (var i = 0; i < c.nMBON; i++) { neurons.add(Neuron(id, NeuronType.mbon, compartment: i % c.nCompartments)); mbon.add(id++); }
  for (var i = 0; i < c.nCompartments; i++) { neurons.add(Neuron(id, NeuronType.dan, compartment: i)); dan.add(id++); }

  // PN→KC 랜덤 fan-in (재현용 seed)
  final pnToKc = <int, List<int>>{};
  for (final k in kc) {
    final picks = <int>{};
    while (picks.length < c.kcFanIn) picks.add(pn[rng.nextInt(pn.length)]);
    pnToKc[k] = picks.toList();
  }
  return Connectome(c, neurons, SynapsePool(),
      pn: pn, kc: kc, mbon: mbon, dan: dan, apl: apl, pnToKc: pnToKc);
}
