# NeuRAM 디지털 트윈 — 무인 주간 킥오프 (Windows 작업 스케줄러가 매주 일요일 실행).
# 시뮬레이션을 자동 진행하고 커밋·푸시한다. 서술 리포트는 Claude가 다음 접속 시 작성.
$ErrorActionPreference = "Continue"
$repo = "D:\dev\neuram_companion"
$env:PATH = "D:\flutter\bin;D:\flutter\bin\cache\dart-sdk\bin;" + $env:PATH
Set-Location $repo

$log = Join-Path $repo "campaign\auto_run.log"
function Log($m) { Add-Content $log ("[{0}] {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $m) }

Log "=== auto kickoff start ==="
try { git checkout DigitalTwin 2>&1 | ForEach-Object { Log $_ } } catch { Log "checkout: $_" }

# 다음 주 자동 실행(상태+커리큘럼 기반, connectome 이월)
dart run bin/twin_campaign.dart auto 2>&1 | ForEach-Object { Log $_ }

# 커밋·푸시 (gh가 설정한 자격증명 사용)
git add -A 2>&1 | ForEach-Object { Log $_ }
git commit -m "chore(campaign): scheduled weekly kickoff [auto]" 2>&1 | ForEach-Object { Log $_ }
git push origin DigitalTwin 2>&1 | ForEach-Object { Log $_ }

Log "=== auto kickoff done ==="
