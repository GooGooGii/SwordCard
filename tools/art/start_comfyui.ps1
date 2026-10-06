# 背景啟動 ComfyUI（脫離目前的終端機，關掉視窗也會繼續跑），供美術批次使用。
# 停止：Get-Process python | Where-Object { $_.CommandLine -like '*launch_without_av*' } | Stop-Process
$cu = "C:\AI\StabilityMatrix\Data\Packages\ComfyUI"
$launcher = "C:\Users\USER\source\repos\SwordCard\tools\comfyui\launch_without_av.py"
$log = Join-Path $env:TEMP "xiaoyao_comfyui.log"
try {
    Invoke-WebRequest -UseBasicParsing -TimeoutSec 3 http://127.0.0.1:8188/system_stats | Out-Null
    Write-Output "ComfyUI already running"
    exit 0
} catch {}
Start-Process -FilePath "$cu\venv\Scripts\python.exe" `
    -ArgumentList "`"$launcher`" `"$cu`" --listen 127.0.0.1 --port 8188 --reserve-vram 0.9 --use-pytorch-cross-attention --disable-auto-launch" `
    -WindowStyle Hidden -RedirectStandardOutput $log -RedirectStandardError "$log.err"
Write-Output "ComfyUI starting (log: $log)"
