# 디지털 트윈 장기 육성 캠페인

NeuRAM Half-MB 트윈 **하나의 개체**를 실제 달력 주 단위로 계속 학습시키는 종단 운영.
`twin_week`(독립/연속 비교 실험)과 달리, 캠페인은 connectome을 매주 이월하며
주차별 리포트를 누적한다.

## 목적

> **안정 애착·변별·회복탄력성을 갖춘 디지털 트윈 육성.**
> ① 애착: 양육자 신호(소리A)에 강한 접근(probeA ≥ 0.70)
> ② 변별: 무관 신호(소리B) 변별(probeB ≤ 0.30)
> ③ 회복탄력성: 부분강화·위협·전환에도 붕괴 없는 적응(active 8~48, 적절 avoidIndex)

## 주간 사이클 (실제 달력)

| 시점(KST) | 동작 |
|---|---|
| **일 20:00 (또는 월)** | 그 주 레짐 결정·시뮬 시작 (`run` 실행, connectome 이월) |
| 금 18:00 | 그 주 시뮬 종료(개념적; 계산은 즉시) |
| **토 06:00** | 주간 리포트 작성·분석·다음 주 레짐 결정, 커밋·푸시 |

> 첫 주(Week 1)는 수요일 출생이라 3일(수~금) 단축 운영, 06-13(토) 리포트.

## 파일 구조

```
campaign/
  connectome.json     ← 영속 개체(매주 이월). 삭제 시 재출생.
  state.json          ← 캠페인 상태(week, lastRegime, plannedNextRegime, 누적·history)
  history.csv         ← 전 주차 일별 학습곡선(누적)
  reports/
    week_NN_metrics.md            ← 하니스 자동 생성(표·목표대비)
    week_NN_<date>_report.md      ← Claude 서술 리포트(분석·다음주 결정)
  README.md           ← 이 파일
```

## 명령

```powershell
# 환경
$env:PATH = "D:\flutter\bin;D:\flutter\bin\cache\dart-sdk\bin;" + $env:PATH
Set-Location "D:\dev\neuram_companion"

# 한 주 실행 (레짐 week 일수 [날짜라벨])
dart run bin/twin_campaign.dart run R4_intermittent 2 7 2026-06-20

# 현재 상태 확인
dart run bin/twin_campaign.dart status
```

레짐: `R1_nurturing` `R2_neglect` `R3_harsh` `R4_intermittent` `R5_shift`

## 커리큘럼 (적응적 — 매주 리포트 보고 조정)

| 주 | 레짐 | 목표 축 | 비고 |
|---|---|---|---|
| W1 | R1 양육 | ①애착 ②변별 | 출생·안정기지 (3일) |
| W2 | R4 변동강화 | ③회복탄력성 | 부분강화 소거저항 시험 |
| W3+ | (리포트 분석 후 결정) | — | 위협학습(R3)·전환(R5)·재안정(R1) 등 |

## 자동 스케줄 (durable cron, 자기영속)

이 캠페인은 Claude Code의 durable cron으로 구동된다. **cron은 7일 후 자동 만료**되므로,
매 실행이 끝날 때 다음 주 cron을 재등록하는 자기영속(self-perpetuating) 방식이다.

- 토 06:00 "주간 리포트": 그 주 `run` → 서술 리포트 작성 → 커밋·푸시 → 다음 주 cron 재등록
- 일 20:00 "킥오프": `plannedNextRegime`로 다음 주 시작 기록

### 제약 (반드시 인지)
- **노트북이 켜져 있고 Claude Code가 실행 중**일 때만 cron이 발화한다. 꺼져 있으면 건너뜀.
- 놓친 슬롯은 다음 접속 시 수동 `run`으로 따라잡을 수 있다(결정론적이라 결과 동일).

## 수동 트리거 / 중단

- **수동 실행**: 위 `run` 명령 직접 실행 후 리포트 작성.
- **중단**: Claude에게 "캠페인 스케줄 중단" 요청 → 등록된 cron 삭제(CronDelete).
- **재출생**: `campaign/connectome.json` 삭제 후 week 1부터.
