/// 입력: 정규화된 자극(0..1). 출력: 표현 상태.
class SensorInput {
  final double soundSharp;  // 날카로운 소리 성분
  final double soundLevel;  // 전체 음량
  final double touchSoft;   // 쓰다듬(부드러움)
  final double touchSharp;  // 탭(날카로움)
  final double shake;       // 가속도 편차
  const SensorInput({this.soundSharp = 0, this.soundLevel = 0,
    this.touchSoft = 0, this.touchSharp = 0, this.shake = 0});
}

class CreatureState {
  final double valence;   // -1..1
  final double arousal;   // 0..1
  final double social;    // 0..1 (외로움)
  final double energy;    // 0..1 (포만)
  final String? vocalize; // null이면 무음, 아니면 소리 종류
  final double purr;      // 0..1
  const CreatureState({required this.valence, required this.arousal,
    required this.social, required this.energy, this.vocalize, this.purr = 0});
}

abstract class NeuramEngine {
  Future<void> load();           // 영속 연결체 로드(없으면 출생)
  void onSensor(SensorInput s);  // 입력 이벤트
  CreatureState tick();          // 저빈도 틱(Lazy 감쇠 반영 + readout)
  Future<void> save();           // 영속 저장
}
