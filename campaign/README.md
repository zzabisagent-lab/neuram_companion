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
| W3 | R1 양육 | ①공고화 | 재안정·연합 공고화 |
| W4 | R3 엄격 | 위협학습 | 적절한 회피 형성 |
| W5 | R1 양육 | 회복 | 스트레스 후 재안정 |
| W6 | R5 전환 | 인지유연성 | 소거→재학습 |
| W7 | R4 변동강화 | ③회복탄력성 | 재시험 |
| W8 | R1 양육 | 공고화 | 이후 W2부터 순환 |

> 위는 `curriculum.json` 기본값. 매주 리포트 분석 후 Claude가 `plannedNextRegime`로 조정 가능.

## 자동화 설계 (확정) — OS 스케줄러 + Claude 리포트

이 환경은 durable cron이 영속되지 않고 `claude` 헤드리스 CLI도 없어, **무인 정시 리포트
작성은 불가능**하다. 따라서 역할을 분리한다:

### ① 시뮬레이션 = Windows 작업 스케줄러 (무인·자동)
- 작업명 `NeuRAM_TwinKickoff`, **매주 일요일 20:10 KST** 실행 → `campaign/run_week_auto.ps1`.
- 스크립트가 `dart run bin/twin_campaign.dart auto` 호출 → 상태+커리큘럼으로 다음 주
  레짐 결정, connectome 이월 실행, `plannedNext` 큐잉 → `git add/commit/push`.
- **노트북만 켜져 있으면 Claude 없이도 트윈이 매주 발달한다.** 재부팅에도 생존.
- 로그: `campaign/auto_run.log` (gitignore). 점검 명령:
  `schtasks /Query /TN NeuRAM_TwinKickoff /FO LIST /V`

### ② 서술 리포트 = Claude (접속 시 작성)
- 분석·다음 주 레짐 결정은 Claude가 한다. **노트북에서 Claude Code를 열면**, Claude가
  `state.json`을 확인해 *시뮬은 돌았으나 리포트가 없는 주*를 찾아 서술 리포트를 작성한다.
  - `campaign/reports/week_NN_metrics.md`(자동) + `state.json`을 읽고
  - `week_01_2026-06-13_report.md`를 템플릿으로
    `campaign/reports/week_NN_<토요일날짜>_report.md` 작성
  - 분석 결과로 다음 주 레짐을 바꿀 경우 `state.json`의 `plannedNextRegime`를 수정
    (OS 스케줄러의 커리큘럼 기본값을 override).
  - 커밋·푸시.
- 즉 **토요일 정시 무인 작성은 보장되지 않으며**, 사용자가 그 즈음 Claude를 열면 그때
  작성된다(놓쳐도 데이터는 무인 스케줄러가 보존하므로 결손 없음).

### 커리큘럼 (`campaign/curriculum.json`)
OS 스케줄러가 따르는 기본 순서. Claude가 매주 리포트에서 `plannedNextRegime`로 조정 가능.
week가 plan 길이를 넘으면 `loopFrom`(기본 W2)부터 순환.

## 수동 트리거 / 중단

- **수동 한 주 실행**: `dart run bin/twin_campaign.dart auto` (또는 `run <regime> <week> <days> [date]`).
- **다음 실행 미리보기**: `dart run bin/twin_campaign.dart next` (부작용 없음).
- **무인 자동 중단**: `schtasks /Delete /TN NeuRAM_TwinKickoff /F`.
- **재출생**: `campaign/connectome.json` 삭제 후 다음 실행이 week 1부터 새 개체.
