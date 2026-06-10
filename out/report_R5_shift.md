# Twin Weekly Report — R5_shift

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
| 1 | 12 | 12 | 0 | 0.832 | 0.119 | 0.119 | 0.357 | 0.119 | 0.500 | 0.063 |
| 2 | 12 | 12 | 0 | 0.832 | 0.119 | 0.119 | 0.357 | 0.119 | 0.500 | 0.063 |
| 3 | 12 | 12 | 0 | 0.832 | 0.119 | 0.119 | 0.357 | 0.119 | 0.500 | 0.063 |
| 4 | 24 | 24 | 0 | 0.282 | 0.631 | 0.119 | 0.344 | 0.119 | 0.241 | 0.063 |
| 5 | 12 | 24 | 12 | 0.119 | 0.858 | 0.119 | 0.366 | 0.119 | 0.500 | 0.063 |
| 6 | 12 | 24 | 12 | 0.119 | 0.858 | 0.119 | 0.366 | 0.119 | 0.500 | 0.063 |
| 7 | 12 | 24 | 12 | 0.119 | 0.858 | 0.119 | 0.366 | 0.119 | 0.500 | 0.063 |

## Final (day 7)
- probeA=0.119  probeB=0.858  probeNovel=0.119
- approachIndex=0.366  avoidIndex=0.119
- activeSynapses=12  cumFormed=24  cumPruned=12
- meanWeight=0.500  kcSparsity=0.063
