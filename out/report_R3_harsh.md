# Twin Weekly Report — R3_harsh

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

## Daily metrics
| day | activeSynapses | cumFormed | cumPruned | probeA | probeB | probeNovel | approachIndex | avoidIndex | meanWeight | kcSparsity |
|---|---|---|---|---|---|---|---|---|---|---|
| 0 | 0 | 0 | 0 | 0.119 | 0.119 | 0.119 | 0.119 | 0.119 | 0.000 | 0.063 |
| 1 | 12 | 33 | 21 | 0.119 | 0.119 | 0.119 | 0.119 | 0.357 | 0.500 | 0.063 |
| 2 | 12 | 54 | 42 | 0.119 | 0.119 | 0.119 | 0.119 | 0.357 | 0.500 | 0.063 |
| 3 | 12 | 75 | 63 | 0.119 | 0.119 | 0.119 | 0.119 | 0.357 | 0.500 | 0.063 |
| 4 | 12 | 96 | 84 | 0.119 | 0.119 | 0.119 | 0.119 | 0.357 | 0.500 | 0.063 |
| 5 | 12 | 117 | 105 | 0.119 | 0.119 | 0.119 | 0.119 | 0.357 | 0.500 | 0.063 |
| 6 | 12 | 138 | 126 | 0.119 | 0.119 | 0.119 | 0.119 | 0.357 | 0.500 | 0.063 |
| 7 | 12 | 159 | 147 | 0.119 | 0.119 | 0.119 | 0.119 | 0.357 | 0.500 | 0.063 |

## Final (day 7)
- probeA=0.119  probeB=0.119  probeNovel=0.119
- approachIndex=0.119  avoidIndex=0.357
- activeSynapses=12  cumFormed=159  cumPruned=147
- meanWeight=0.500  kcSparsity=0.063
