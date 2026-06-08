enum NeuronType { sensory, inter, drive, modulator, output }
enum Tier { genome, soma, plastic }

class Neuron {
  final int id;
  final NeuronType type;
  final Tier tier;
  double value;       // 현재 활성(graded)
  final double baseline;
  Neuron(this.id, this.type, this.tier, {this.value = 0.0, this.baseline = 0.0});
}

class Synapse {
  final int preId;
  final int postId;
  double weight;
  final Tier tier;
  final bool plastic;
  double depression;  // 0..1 (단기 우울, 습관화)
  final double depIncr;
  final double depTauSec;
  int tLastMs;
  Synapse(this.preId, this.postId, this.weight, this.tier,
      {this.plastic = false, this.depression = 0.0,
       this.depIncr = 0.0, this.depTauSec = 8.0, this.tLastMs = 0});
}
