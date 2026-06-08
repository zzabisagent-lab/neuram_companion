import 'model.dart';

class Ids {
  static const sSound=0, sTouch=1, sShake=2, iStartle=3, iSoothe=4,
    dEnergy=5, dSocial=6, dArousal=7, mValence=8,
    oFaceVal=9, oFaceAro=10, oVocalize=11, oPurr=12;
}

/// 반사기 커넥톰(genome+soma). 반환: (뉴런맵, 시냅스리스트)
(Map<int,Neuron>, List<Synapse>) buildReflexConnectome() {
  final neurons = <Neuron>[
    Neuron(Ids.sSound, NeuronType.sensory, Tier.genome),
    Neuron(Ids.sTouch, NeuronType.sensory, Tier.genome),
    Neuron(Ids.sShake, NeuronType.sensory, Tier.genome),
    Neuron(Ids.iStartle, NeuronType.inter, Tier.soma),
    Neuron(Ids.iSoothe, NeuronType.inter, Tier.soma),
    Neuron(Ids.dEnergy, NeuronType.drive, Tier.genome, value: 0.9),
    Neuron(Ids.dSocial, NeuronType.drive, Tier.genome, value: 0.2),
    Neuron(Ids.dArousal, NeuronType.drive, Tier.soma),
    Neuron(Ids.mValence, NeuronType.modulator, Tier.soma, value: 0.1),
    Neuron(Ids.oFaceVal, NeuronType.output, Tier.soma),
    Neuron(Ids.oFaceAro, NeuronType.output, Tier.soma),
    Neuron(Ids.oVocalize, NeuronType.output, Tier.soma),
    Neuron(Ids.oPurr, NeuronType.output, Tier.soma),
  ];
  final synapses = <Synapse>[
    // 습관화 시냅스(단기 우울): S_sound → I_startle
    Synapse(Ids.sSound, Ids.iStartle, 1.0, Tier.soma,
        depIncr: 0.25, depTauSec: 8.0),
    Synapse(Ids.sShake, Ids.iStartle, 0.8, Tier.soma),
    Synapse(Ids.sTouch, Ids.iSoothe, 1.0, Tier.soma),
    // (M-App1) 주인 목소리↔soothe 연합용 plastic 시냅스 자리:
    // Synapse(Ids.sSound, Ids.iSoothe, 0.0, Tier.plastic, plastic: true),
  ];
  return ({for (final x in neurons) x.id: x}, synapses);
}
