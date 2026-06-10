# Twin Weekly Report — R4_intermittent (continual)

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
| 21 | 12 | 183 | 171 | 0.119 | 0.119 | 0.119 | 0.119 | 0.357 | 0.500 | 0.063 |
| 22 | 24 | 195 | 171 | 0.832 | 0.119 | 0.119 | 0.357 | 0.357 | 0.500 | 0.063 |
| 23 | 24 | 195 | 171 | 0.832 | 0.119 | 0.119 | 0.357 | 0.357 | 0.500 | 0.063 |
| 24 | 24 | 195 | 171 | 0.832 | 0.119 | 0.119 | 0.357 | 0.357 | 0.500 | 0.063 |
| 25 | 24 | 195 | 171 | 0.832 | 0.119 | 0.119 | 0.357 | 0.357 | 0.500 | 0.063 |
| 26 | 24 | 195 | 171 | 0.832 | 0.119 | 0.119 | 0.357 | 0.357 | 0.500 | 0.063 |
| 27 | 24 | 195 | 171 | 0.832 | 0.119 | 0.119 | 0.357 | 0.357 | 0.500 | 0.063 |
| 28 | 24 | 195 | 171 | 0.832 | 0.119 | 0.119 | 0.357 | 0.357 | 0.500 | 0.063 |

## Final (day 28)
- probeA=0.832  probeB=0.119  probeNovel=0.119
- approachIndex=0.357  avoidIndex=0.357
- activeSynapses=24  cumFormed=195  cumPruned=171
- meanWeight=0.500  kcSparsity=0.063
