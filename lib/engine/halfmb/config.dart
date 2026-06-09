class HalfMBConfig {
  final int nPN, nKC, nMBON, nCompartments, kcFanIn, kWTA;
  final double formThreshold, lr, weightFloor, synScaleTarget;
  final int pruneTau, synapseBudgetPerMBON;
  final int seed;
  const HalfMBConfig({
    required this.nPN, required this.nKC, required this.nMBON,
    required this.nCompartments, required this.kcFanIn, required this.kWTA,
    required this.formThreshold, required this.lr, required this.weightFloor,
    required this.synScaleTarget, required this.pruneTau,
    required this.synapseBudgetPerMBON, this.seed = 42,
  });
  // S1: 작게. S2에서 nKC=1000 등으로 스케일.
  static const s1 = HalfMBConfig(
    nPN: 6, nKC: 64, nMBON: 6, nCompartments: 2, kcFanIn: 4, kWTA: 4,
    formThreshold: 0.5, lr: 0.06, weightFloor: 0.02, synScaleTarget: 2.0,
    pruneTau: 150, synapseBudgetPerMBON: 48,
  );
}
