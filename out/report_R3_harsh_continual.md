# Twin Weekly Report — R3_harsh (continual)

## Config
- mode: continual
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

## Daily metrics
| day | activeSynapses | cumFormed | cumPruned | probeA | probeB | probeNovel | approachIndex | avoidIndex | meanWeight | kcSparsity |
|---|---|---|---|---|---|---|---|---|---|---|
| 14 | 0 | 24 | 24 | 0.119 | 0.119 | 0.119 | 0.119 | 0.119 | 0.000 | 0.063 |
| 15 | 12 | 57 | 45 | 0.119 | 0.119 | 0.119 | 0.119 | 0.357 | 0.500 | 0.063 |
| 16 | 12 | 78 | 66 | 0.119 | 0.119 | 0.119 | 0.119 | 0.357 | 0.500 | 0.063 |
| 17 | 12 | 99 | 87 | 0.119 | 0.119 | 0.119 | 0.119 | 0.357 | 0.500 | 0.063 |
| 18 | 12 | 120 | 108 | 0.119 | 0.119 | 0.119 | 0.119 | 0.357 | 0.500 | 0.063 |
| 19 | 12 | 141 | 129 | 0.119 | 0.119 | 0.119 | 0.119 | 0.357 | 0.500 | 0.063 |
| 20 | 12 | 162 | 150 | 0.119 | 0.119 | 0.119 | 0.119 | 0.357 | 0.500 | 0.063 |
| 21 | 12 | 183 | 171 | 0.119 | 0.119 | 0.119 | 0.119 | 0.357 | 0.500 | 0.063 |

## Final (day 21)
- probeA=0.119  probeB=0.119  probeNovel=0.119
- approachIndex=0.119  avoidIndex=0.357
- activeSynapses=12  cumFormed=183  cumPruned=171
- meanWeight=0.500  kcSparsity=0.063
