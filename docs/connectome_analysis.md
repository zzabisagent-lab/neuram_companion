# M-App0 커넥톰 구조 및 가소성 상세 분석

> 작성: Claude Sonnet 4.6 / 분석 대상: `lib/engine/` 전체 소스  
> 버전: neuram_companion v1.0.0 (반사기 컴패니언, Stage 2 M-App0)

---

## 1. 커넥톰 개요

### 1.1 생물학적 모델 기반

M-App0의 커넥톰은 **C. elegans(예쁜꼬마선충) 반사 회로**를 추상화한 것이다.  
302개 뉴런 전체 커넥톰이 알려진 유일한 다세포 동물인 C. elegans에서 핵심 반사 경로(감각→중간→출력)의 구조적 원리를 빌려, 스마트폰 입력(마이크·터치·IMU)에 맞게 재매핑했다.

구체적으로는 C. elegans의 **기계 자극 회피 반사(mechanosensory withdrawal reflex)** 회로가 참조 모델이다:
- ASH/ALM 감각뉴런 → AVA/AVD 중간뉴런 → 운동뉴런
- 이 구조가 M-App0에서는 `S_sound/shake → I_startle → 출력` 경로로 사상된다.

**단, 중요한 차이점**: C. elegans는 연속 그레이디드 전위(graded potential)로 동작하는 뉴런이 많고, M-App0도 이를 따른다 — 발화/비발화 이진 스파이크가 아닌 `0..1` 범위의 연속값 전파.

### 1.2 커넥톰 규모

| 항목 | 값 |
|---|---|
| 총 뉴런 수 | **13개** |
| 총 시냅스 수 | **3개** (+ 1개 주석 예약) |
| 바이너리 저장 크기 | 헤더 16B + 뉴런 286B + 시냅스 150B = **452 bytes** |
| 파일 경로 | `<앱문서>/neuram/connectome.bin` + `meta.json` |

---

## 2. 뉴런 구성 상세

### 2.1 뉴런 목록 (ID 순)

```
ID  이름        타입        Tier    초기값  역할
──────────────────────────────────────────────────────────────────
 0  S_sound     sensory     genome   0.0   마이크 진폭 → 음량 (0..1)
 1  S_touch     sensory     genome   0.0   터치 입력 (soft - sharp)
 2  S_shake     sensory     genome   0.0   가속도계 분산 → 흔들림 (0..1)
 3  I_startle   inter       soma     0.0   놀람/경계 중간뉴런
 4  I_soothe    inter       soma     0.0   진정/안정 중간뉴런
 5  D_energy    drive       genome   0.9   에너지 드라이브 (포만도)
 6  D_social    drive       genome   0.2   사회 드라이브 (외로움)
 7  D_arousal   drive       soma     0.0   각성 드라이브
 8  M_valence   modulator   soma     0.1   정서 조절 모듈레이터
 9  O_faceVal   output      soma     0.0   얼굴 표정 readout (valence 축)
10  O_faceAro   output      soma     0.0   얼굴 표정 readout (arousal 축)
11  O_vocalize  output      soma     0.0   발성 트리거
12  O_purr      output      soma     0.0   그루밍/퍼링 트리거
```

### 2.2 NeuronType별 기능

| 타입 | 뉴런 | 기능 |
|---|---|---|
| `sensory` | S_sound, S_touch, S_shake | 하드웨어 → 커넥톰 경계. 폴링 없이 이벤트 기반 주입 |
| `inter` | I_startle, I_soothe | 감각 신호를 수렴·처리하는 중간 레이어 |
| `drive` | D_energy, D_social, D_arousal | 시간 기반 Lazy 감쇠. 항상성 기준값으로 수렴 |
| `modulator` | M_valence | 전체 회로의 정서적 배경(tone) 조절 |
| `output` | O_face*, O_vocalize, O_purr | 커넥톰 → 표현층 경계. UI/IO 드라이버 |

### 2.3 Tier(계층) 체계

3-Tier 설계는 **불변성 + 학습 가능성의 명시적 분리**다:

```
Tier.genome  — 진화적 선천 회로. 재시작해도 구조 불변.
               값: 뉴런 초기값(부트스트랩)만 고정. 운동 중 값은 변할 수 있음.
               해당 뉴런: S_sound, S_touch, S_shake, D_energy, D_social

Tier.soma    — 개체 발생 중 확정(응고). 현재 M-App0에서는 실질적으로 genome에 준함.
               설계상 D-021에서 "연합 학습 후 잠금"을 위한 자리.
               해당 뉴런: I_startle, I_soothe, D_arousal, M_valence, 모든 output

Tier.plastic — 학습으로 변하는 시냅스/뉴런 (M-App0에서 미사용, M-App1 예약)
```

---

## 3. 시냅스 구성 상세

### 3.1 시냅스 목록

```
#  Pre → Post         Weight  Tier   Plastic  depIncr  depTauSec  역할
─────────────────────────────────────────────────────────────────────────
0  S_sound → I_startle  1.0   soma   false    0.25     8.0s       소리 놀람 (습관화 있음)
1  S_shake → I_startle  0.8   soma   false    0.0      8.0s       흔들림 놀람 (습관화 없음)
2  S_touch → I_soothe   1.0   soma   false    0.0      8.0s       쓰다듬 진정
── 예약 ──────────────────────────────────────────────────────────────────
3  S_sound → I_soothe   0.0   plastic true    —        —          주인 목소리 연합 (M-App1)
```

### 3.2 드라이브 → 출력 경로 (비-시냅스 직접 사상)

현재 구현에서 드라이브(D_*)와 모듈레이터(M_valence)는 시냅스를 거치지 않고 `DartNeuramEngine` 내부에서 직접 연산된다. 이는 M-App0의 간결성을 위한 설계상 단순화이며, 향후 시냅스로 명시화 예정이다:

```
D_social  ---(직접)--→ M_valence (감산: valence -= 0.4 * social)
D_arousal ---(직접)--→ O_faceAro
M_valence ---(직접)--→ O_faceVal
I_soothe  ---(직접)--→ O_purr (valence > 0 이고 arousal 낮을 때)
M_valence ---(직접)--→ O_vocalize (임계값 비교)
```

---

## 4. 가소성(Plasticity) 분석

### 4.1 현재 구현된 가소성: 단기 시냅스 우울 (Short-Term Synaptic Depression)

**유일하게 학습이 일어나는 시냅스**: `S_sound → I_startle`

이것이 M-App0의 **습관화(habituation)** 메커니즘의 핵심이다.

#### 동작 원리 (C. elegans 모델 직접 차용)

```
자극 발생 시:
  depression += depIncr * (1 - depression)   // 0.25씩 증가, 상한 1.0
  → 효과적 가중치 = weight * (1 - depression)
  → 반복 자극 시 시냅스 효율 감소 (최대 0.25 → 0.44 → 0.58 → 0.69... 점근)

자극 없는 동안 (Lazy 회복):
  depression *= exp(-dt / depTauSec)          // τ = 8초로 지수 회복
  → 8초 침묵이면 depression이 e^-1 ≈ 37%로 감소
  → ~24초(3τ) 침묵이면 거의 완전 회복
```

#### 파라미터 의미

| 파라미터 | 값 | 의미 |
|---|---|---|
| `depIncr` | 0.25 | 자극 1회당 시냅스 억제 증가율 (25%씩 포화 방향으로) |
| `depTauSec` | 8.0s | 회복 시상수. 8초마다 억제가 1/e ≈ 36.8%로 감소 |
| 4회 연속 자극 | — | depression ≈ 0.68 → 실효 가중치 32% (startled 반응 → 거의 무반응) |
| 완전 회복 | ~24s | 3τ 경과 시 depression < 5% |

#### 지속성

`depression` 값은 `connectome.bin`의 Synapse 레코드에 저장된다 (50B 레코드의 offset 18~25번째 바이트, Float64). **앱 재시작 후에도 습관화 상태가 유지**된다.

단, `tLastMs`(마지막 자극 시각)도 함께 저장되므로, 재시작 시 경과 시간을 반영해 Lazy 회복이 자동 적용된다.

### 4.2 현재 구현된 가소성: 드라이브 Lazy 감쇠

드라이브 3개가 시간에 따라 변한다. 이는 가소성이 아닌 **항상성 동역학**이지만, 앱 상태를 영속적으로 변화시킨다는 점에서 행동 변화를 유발한다.

```
드라이브      τ        기준값(baseline)  방향           물리적 의미
──────────────────────────────────────────────────────────────────
D_social    3600s    1.0 (최대 외로움)   시간↑ → social↑  방치할수록 외로워짐
D_energy    7200s    0.0 (최대 허기)     시간↑ → energy↓  방치할수록 배고파짐
D_arousal   20s      0.0 (각성 없음)     이벤트 후 빠른 진정  흥분은 20초 내 가라앉음
```

이 값들은 `meta.json`에 저장되며 재시작 후 복원된다.

### 4.3 현재 미구현 (M-App1+ 예약) 가소성

#### 4.3.1 Hebbian 연합 학습 (주석 처리된 시냅스)

```dart
// connectome.dart line 33 (주석):
// Synapse(Ids.sSound, Ids.iSoothe, 0.0, Tier.plastic, plastic: true)
```

이 시냅스가 활성화되면 **주인 목소리 → 진정 연합**이 가능해진다:
- 규칙: `S_sound`와 `I_soothe`가 동시에 활성일 때(주인이 말하며 쓰다듬을 때) weight 증가
- 헤비안 형식: `Δw = η * pre.value * post.value * (1 - weight)`

이것이 구현되면 디크리는 특정 목소리에 진정하는 **조건 반사**를 획득한다.

#### 4.3.2 시냅스 가중치 학습의 구조적 준비

`Synapse.plastic = true` 플래그와 `Tier.plastic`이 이미 데이터 구조에 존재한다. `connectome.bin`에도 1바이트로 직렬화된다 (offset 12, `plastic` 필드). 따라서 **학습 엔진만 추가하면** 바이너리 포맷 변경 없이 가중치 학습이 가능하다.

---

## 5. 고정 영역 vs 학습 가능 영역 전체 지도

```
┌─────────────────────────────────────────────────────────────────┐
│                    M-App0 커넥톰 가소성 지도                      │
├──────────────────┬──────────────────┬───────────────────────────┤
│  완전 고정        │  단기 가변        │  장기 가변                │
│  (Tier.genome)   │  (단기 우울/Lazy) │  (현재 미구현)            │
├──────────────────┼──────────────────┼───────────────────────────┤
│ S_sound 뉴런     │ S→I_startle      │ S_sound→I_soothe weight   │
│ S_touch 뉴런     │   .depression    │ (주인 목소리 연합, M-App1)  │
│ S_shake 뉴런     │   (τ=8s, 재시작  │                           │
│ D_energy 구조    │    후 복원)       │ 발달 단계 파라미터          │
│ D_social 구조    ├──────────────────┤ (머리:몸 비율, 표현 레퍼토리│
│                  │ D_social (Lazy)  │  M-App2+ 성장 시스템)      │
│ 시냅스 topol.    │   (τ=3600s)      │                           │
│ (연결 패턴 자체) │ D_energy (Lazy)  │ 새 시냅스 추가              │
│                  │   (τ=7200s)      │ (구조적 가소성,             │
│                  │ D_arousal (Lazy) │  M-App3+)                 │
│                  │   (τ=20s)        │                           │
│                  │ M_valence (이벤트│                           │
│                  │  기반 단기 변화) │                           │
└──────────────────┴──────────────────┴───────────────────────────┘
```

---

## 6. 학습 한계 및 현재 제약

### 6.1 현재 배울 수 없는 것

| 항목 | 이유 | 해제 조건 |
|---|---|---|
| 주인 인식 | S_sound→I_soothe weight = 0 고정 | M-App1: plastic 시냅스 활성화 |
| 새 감각-반응 연합 | 시냅스 구조 자체가 추가되지 않음 | M-App3+: 구조적 가소성 |
| 표현 레퍼토리 확장 | O_vocalize 임계값 고정 | M-App2: 발성 학습 |
| 개체별 성격 분화 | 모든 개체가 동일 connectome.bin 시작 | born 이후 경험 누적 시 자연 발생 |
| 사용자 얼굴 인식 | 카메라 없음 | M-App3: 카메라 모듈 추가 시 |

### 6.2 현재 배울 수 있는 것

| 학습 내용 | 메커니즘 | 지속 시간 |
|---|---|---|
| "이 소리는 위협이 아니다" | S→I_startle depression | 재시작 후에도 유지 |
| "지금은 각성 상태다" | D_arousal Lazy | 20초 반감 |
| "오래 혼자였다" | D_social Lazy 3600s | 영속 (meta.json) |
| "배고프다" | D_energy Lazy 7200s | 영속 (meta.json) |
| "방금 쓰다듬 받았다" | M_valence 단기 증가 | 수 분 내 감쇠 |

### 6.3 설계상 의도적 제약

**genome Tier 뉴런의 연결 패턴(topology)은 학습으로 변하지 않는다.** 이는 C. elegans의 실제 커넥톰과 동일한 원칙이다 — 302개 뉴런의 연결 패턴은 모든 C. elegans 개체에서 동일하며, 개체 간 차이는 시냅스 가중치와 활성 패턴에서 나온다.

M-App0 디크리도 동일 원칙을 따른다: **구조(topology)는 genome으로 고정, 경험(weight·depression·drive)은 soma/plastic으로 변한다.**

---

## 7. 바이너리 커넥톰 포맷 참조

```
connectome.bin 레이아웃:
┌─────────────────────────────────────────────────┐
│ HEADER (16 bytes)                               │
│   magic:   0x4E52414D ('NRAM') [4B LE uint32]  │
│   version: 1               [4B LE uint32]       │
│   nCount:  13 (뉴런 수)    [4B LE uint32]       │
│   sCount:  3  (시냅스 수)  [4B LE uint32]       │
├─────────────────────────────────────────────────┤
│ NEURON RECORDS (13 × 22 bytes = 286 bytes)      │
│   id:       [4B LE int32]                       │
│   type:     [1B uint8 enum]                     │
│   tier:     [1B uint8 enum]                     │
│   value:    [8B LE float64]   ← 학습으로 변함   │
│   baseline: [8B LE float64]                     │
├─────────────────────────────────────────────────┤
│ SYNAPSE RECORDS (3 × 50 bytes = 150 bytes)      │
│   preId:      [4B LE int32]                     │
│   postId:     [4B LE int32]                     │
│   weight:     [8B LE float64] ← plastic=true시 변함 │
│   tier:       [1B uint8 enum]                   │
│   plastic:    [1B uint8 flag] ← 0=고정, 1=학습가능 │
│   depression: [8B LE float64] ← 습관화 상태     │
│   depIncr:    [8B LE float64]                   │
│   depTauSec:  [8B LE float64]                   │
│   tLastMs:    [8B LE int64]   ← Lazy 기준 시각  │
└─────────────────────────────────────────────────┘
총: 452 bytes (현재 13뉴런 + 3시냅스 기준)
```

---

## 8. 향후 가소성 로드맵

| 단계 | 목표 | 추가 가소성 메커니즘 |
|---|---|---|
| **M-App0** (현재) | 반사·습관화 | 단기 시냅스 우울 (S→I_startle) |
| **M-App1** | 주인 인식 | Hebbian: S_sound→I_soothe weight 학습 |
| **M-App2** | 발성 학습 | 강화: vocalize 패턴 → 반응 기반 선택 |
| **M-App3** | 시각 연합 | 카메라 시냅스 추가, 얼굴 각인 |
| **M-App4+** | 성격 분화 | 드라이브 τ 자체 변화, 구조적 가소성 |

---

## 9. 요약

M-App0 디크리의 커넥톰은 **C. elegans 반사 회로를 원형으로 삼은 13뉴런 3시냅스의 최소 생존 가능 회로**다.

- **고정된 것**: 13개 뉴런의 ID·타입·Tier·연결 패턴(topology). 이것이 디크리의 "종(種) 정체성"이다.
- **단기적으로 변하는 것**: S→I_startle 시냅스의 depression(습관화), D_arousal(각성). 이것이 "지금 이 순간"의 상태다.
- **장기적으로 변하는 것**: D_social(외로움), D_energy(배고픔), M_valence(기분 기조). 이것이 "이번 생"의 경험이다.
- **앞으로 변할 수 있도록 준비된 것**: Tier.plastic 플래그, `plastic=true` 시냅스 자리, `weight` 필드의 직렬화. M-App1에서 Hebbian 학습 활성화 시 주인 목소리 연합이 가능하다.

현재 디크리가 진짜로 "배우는" 유일한 내용은 **"이 소리는 더 이상 놀랍지 않다"**는 것이다. 그것만으로도 C. elegans의 첫 번째 학습 기준(반복 자극 습관화)을 충족한다.
