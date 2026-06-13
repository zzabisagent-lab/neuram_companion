# Campaign Week 1 — metrics (R1_nurturing)

- date: 2026-06-13  |  days: 3  |  regime: R1_nurturing
- config: nKC=64 seed=42 pruneTau=600 lr=0.06 kWTA=4

## Daily metrics
| day | activeSynapses | cumFormed | cumPruned | probeA | probeB | probeNovel | approachIndex | avoidIndex | meanWeight | kcSparsity |
|---|---|---|---|---|---|---|---|---|---|---|
| 0 | 0 | 0 | 0 | 0.119 | 0.119 | 0.119 | 0.119 | 0.119 | 0.000 | 0.063 |
| 1 | 12 | 12 | 0 | 0.832 | 0.119 | 0.119 | 0.357 | 0.119 | 0.500 | 0.063 |
| 2 | 12 | 12 | 0 | 0.832 | 0.119 | 0.119 | 0.357 | 0.119 | 0.500 | 0.063 |
| 3 | 12 | 12 | 0 | 0.832 | 0.119 | 0.119 | 0.357 | 0.119 | 0.500 | 0.063 |

## Final vs target
| metric | final | target |
|---|---|---|
| probeA | 0.832 | >= 0.70 |
| probeB | 0.119 | <= 0.30 |
| probeNovel | 0.119 | 0.2 ~ 0.6 |
| approachIndex | 0.357 | >= 0.35 |
| avoidIndex | 0.119 | 문맥의존(위협주 >=0.30, 평시 낮음) |
| activeSynapses | 12 | 8 ~ 48 (붕괴/폭주 없음) |
| meanWeight | 0.500 | — |
| kcSparsity | 0.063 | — |
| weekFormed | 12 | — |
| weekPruned | 0 | — |
