# Twin Weekly Report — R2_neglect (continual)

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
| 7 | 12 | 12 | 0 | 0.832 | 0.119 | 0.119 | 0.357 | 0.119 | 0.500 | 0.063 |
| 8 | 0 | 12 | 12 | 0.119 | 0.119 | 0.119 | 0.119 | 0.119 | 0.000 | 0.063 |
| 9 | 0 | 24 | 24 | 0.119 | 0.119 | 0.119 | 0.119 | 0.119 | 0.000 | 0.063 |
| 10 | 0 | 24 | 24 | 0.119 | 0.119 | 0.119 | 0.119 | 0.119 | 0.000 | 0.063 |
| 11 | 0 | 24 | 24 | 0.119 | 0.119 | 0.119 | 0.119 | 0.119 | 0.000 | 0.063 |
| 12 | 0 | 24 | 24 | 0.119 | 0.119 | 0.119 | 0.119 | 0.119 | 0.000 | 0.063 |
| 13 | 0 | 24 | 24 | 0.119 | 0.119 | 0.119 | 0.119 | 0.119 | 0.000 | 0.063 |
| 14 | 0 | 24 | 24 | 0.119 | 0.119 | 0.119 | 0.119 | 0.119 | 0.000 | 0.063 |

## Final (day 14)
- probeA=0.119  probeB=0.119  probeNovel=0.119
- approachIndex=0.119  avoidIndex=0.119
- activeSynapses=0  cumFormed=24  cumPruned=24
- meanWeight=0.000  kcSparsity=0.063
