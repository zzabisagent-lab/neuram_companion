enum NeuronType { pn, kc, mbon, dan, apl }

class Neuron {
  final int id;
  final NeuronType type;
  final int compartment; // MBON/DAN 구획(-1=없음)
  double act = 0.0;      // 현재 활성 graded 0..1
  Neuron(this.id, this.type, {this.compartment = -1});
}

class Synapse {
  int pre, post;
  double weight;   // 0이면 사실상 silent
  bool active;     // false=죽음(가지치기)
  int tLastUsed;
  Synapse(this.pre, this.post, this.weight, {this.active = true, this.tLastUsed = 0});
}

/// 동적 시냅스 풀: 생성=빈 슬롯 재사용/추가, 소멸=active=false + free-list 반환.
/// (시냅스=주소 포인터 원리 2 → 성장/소멸이 레코드 추가/제거)
class SynapsePool {
  final List<Synapse> _s = [];
  final List<int> _free = [];
  final Map<int, List<int>> _byPost = {};

  int create(int pre, int post, double w, int t) {
    int idx;
    if (_free.isNotEmpty) {
      idx = _free.removeLast();
      _s[idx] = Synapse(pre, post, w, tLastUsed: t);
    } else {
      idx = _s.length;
      _s.add(Synapse(pre, post, w, tLastUsed: t));
    }
    (_byPost[post] ??= []).add(idx);
    return idx;
  }

  void remove(int idx) {
    final s = _s[idx];
    s.active = false;
    _byPost[s.post]?.remove(idx);
    _free.add(idx);
  }

  Synapse operator [](int i) => _s[i];
  List<int> postSynapses(int post) => _byPost[post] ?? const [];
  int get activeCount => _s.length - _free.length;
  List<Synapse> get raw => _s;
}
