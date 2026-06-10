# Regime Comparison

| regime | probeA | probeB | probeNovel | approach | avoid | active | formed | pruned |
|---|---|---|---|---|---|---|---|---|
| R1_nurturing | 0.832 | 0.119 | 0.119 | 0.357 | 0.119 | 12 | 12 | 0 |
| R2_neglect | 0.119 | 0.119 | 0.119 | 0.119 | 0.119 | 0 | 24 | 24 |
| R3_harsh | 0.119 | 0.119 | 0.119 | 0.119 | 0.357 | 12 | 159 | 147 |
| R4_intermittent | 0.832 | 0.119 | 0.119 | 0.357 | 0.119 | 12 | 12 | 0 |
| R5_shift | 0.119 | 0.858 | 0.119 | 0.366 | 0.119 | 12 | 24 | 12 |

## Reading guide
- **R1 nurturing**: probeA 최고, pruned≈0 — 안정적 긍정 연합(상한).
- **R2 neglect**: 약/무연합, 미사용 가지치기>0 — S1이 못 본 가지치기 절반.
- **R3 harsh**: avoidIndex 상승(처벌 구획), 일시 2차 CS 미사용으로 pruned>0.
- **R4 intermittent**: 50% 보상에도 연합 형성, 소거 저항.
- **R5 shift**: 보상이 B로 이전 → probeA 하락(소거/역조건화), probeB 상승.

## Config
- mode: independent
- seed: 42
- nKC: 64
- pruneTau: 600
- lr: 0.06
- kWTA: 4
- formThreshold: 0.5
- weightFloor: 0.02
- ticksPerHour: 60
- awakeHours: 16
- sleepHours: 8
- days: 7
- weeks: [R1_nurturing, R2_neglect, R3_harsh, R4_intermittent, R5_shift]
