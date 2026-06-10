# Twin Weekly Report — R5_shift (continual)

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
| 28 | 24 | 195 | 171 | 0.832 | 0.119 | 0.119 | 0.357 | 0.357 | 0.500 | 0.063 |
| 29 | 24 | 195 | 171 | 0.832 | 0.119 | 0.119 | 0.357 | 0.357 | 0.500 | 0.063 |
| 30 | 24 | 195 | 171 | 0.832 | 0.119 | 0.119 | 0.357 | 0.357 | 0.500 | 0.063 |
| 31 | 24 | 195 | 171 | 0.832 | 0.119 | 0.119 | 0.357 | 0.357 | 0.500 | 0.063 |
| 32 | 36 | 207 | 171 | 0.282 | 0.631 | 0.119 | 0.344 | 0.357 | 0.327 | 0.063 |
| 33 | 24 | 207 | 183 | 0.119 | 0.858 | 0.119 | 0.366 | 0.357 | 0.500 | 0.063 |
| 34 | 24 | 207 | 183 | 0.119 | 0.858 | 0.119 | 0.366 | 0.357 | 0.500 | 0.063 |
| 35 | 24 | 207 | 183 | 0.119 | 0.858 | 0.119 | 0.366 | 0.357 | 0.500 | 0.063 |

## Final (day 35)
- probeA=0.119  probeB=0.858  probeNovel=0.119
- approachIndex=0.366  avoidIndex=0.357
- activeSynapses=24  cumFormed=207  cumPruned=183
- meanWeight=0.500  kcSparsity=0.063
