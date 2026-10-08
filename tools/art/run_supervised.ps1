# 長批次出圖的看門狗：ComfyUI 中途當掉（本機 6GB 顯卡偶爾發生）就重開，再續跑 run_jobs.py（已出的圖會跳過）。
# 用法：powershell -File tools/art/run_supervised.ps1 tools/art/jobs/a.json tools/art/jobs/b.json
param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Jobs)
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$log = Join-Path $env:TEMP "xiaoyao_supervised.txt"
for ($round = 1; $round -le 30; $round++) {
    & (Join-Path $PSScriptRoot "start_comfyui.ps1") | Out-Null
    for ($i = 0; $i -lt 60; $i++) {
        try { Invoke-WebRequest -UseBasicParsing -TimeoutSec 3 http://127.0.0.1:8188/system_stats | Out-Null; break } catch { Start-Sleep 5 }
    }
    Push-Location $root
    python tools/art/run_jobs.py @Jobs *>> $log
    $code = $LASTEXITCODE
    Pop-Location
    if ($code -eq 0) { "all done (round $round)" | Out-File -Append $log; exit 0 }
    "round $round failed ($code); restarting ComfyUI" | Out-File -Append $log
    Start-Sleep 10
}
exit 1
