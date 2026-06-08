import 'dart:math' as math;

/// 시간 의존 값. 접근 시점에 지수 감쇠를 계산(Lazy Evaluation, D-012).
class LazyValue {
  double _value;
  int _tLastMs; // epoch ms
  final double tauSec;
  final double baseline; // 감쇠가 수렴하는 기준값

  LazyValue(this._value, this._tLastMs, this.tauSec, {this.baseline = 0.0});

  double valueAt(int nowMs) {
    final dt = (nowMs - _tLastMs) / 1000.0;
    if (dt <= 0) return _value;
    final e = math.exp(-dt / tauSec);
    return baseline + (_value - baseline) * e;
  }

  void set(double v, int nowMs) { _value = v; _tLastMs = nowMs; }
  void add(double dv, int nowMs) { _value = valueAt(nowMs) + dv; _tLastMs = nowMs; }
  double get raw => _value;
  int get tLast => _tLastMs;
}
