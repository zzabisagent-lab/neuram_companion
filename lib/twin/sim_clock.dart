/// 시뮬레이션 시간 모델: tick → hour/day/week, 각성/수면 구조.
/// week = days(7) × 24h × ticksPerHour(60) = 10,080 tick.
class SimClock {
  final int ticksPerHour;
  final int awakeHours;
  final int sleepHours;
  final int days;
  int tick = 0;

  SimClock({
    this.ticksPerHour = 60,
    this.awakeHours = 16,
    this.sleepHours = 8,
    this.days = 7,
  });

  int get hour => (tick ~/ ticksPerHour) % 24;
  int get day => tick ~/ (ticksPerHour * 24);
  int get tickInDay => tick % (ticksPerHour * 24);
  bool get awake => hour < awakeHours;
  int get totalTicks => days * 24 * ticksPerHour;
  double get weekFraction => totalTicks == 0 ? 0.0 : tick / totalTicks;

  void reset() => tick = 0;
}
