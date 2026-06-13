# Valence engine validation — opponent plasticity (D-028)

seed=42, rng=777. opponentAlpha: baseline=0.0, opponent=0.5

## REG (R1, α=0) 회귀
- probeA_final=0.832 (기대 0.80~0.87) → PASS

## V1 (R6 변별, α=0.5)
- netA_final=0.713 (기대 ≥ +0.30), netB_final=-0.739 (기대 ≤ −0.20) → PASS

## V2 (R7 충돌/역전, α=0.5)
- netA(build종료)=0.713 (기대 ≥ +0.30), netA_final=-0.713 (기대 ≤ −0.10, 부호 역전) → PASS

## V3 (ablation: R7 α=0 vs α=0.5)
- netA_final α=0=0.000, α=0.5=-0.713, Δ=0.713 (기대 ≥ +0.20) → PASS

## 종합: PASS
