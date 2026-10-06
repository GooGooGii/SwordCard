param([switch]$Login)
$ErrorActionPreference = 'Stop'
$taskRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$taskCommand = Get-Command claude -ErrorAction SilentlyContinue
$taskExecutable = if ($taskCommand) { $taskCommand.Source } else { $null }
if (-not $taskExecutable) {
    $taskPackageRoot = Join-Path $env:LOCALAPPDATA 'Packages/Claude_pzs8sxrjxfjjc/LocalCache/Roaming/Claude/claude-code'
    $taskExecutable = Get-ChildItem -LiteralPath $taskPackageRoot -Filter claude.exe -Recurse |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1 -ExpandProperty FullName
}
if (-not $taskExecutable) { throw '找不到 Claude CLI' }
Set-Location -LiteralPath $taskRoot
if ($Login) { & $taskExecutable auth login; exit $LASTEXITCODE }
$taskLogs = Join-Path $taskRoot 'capture_out/claude-cli'
New-Item -ItemType Directory -Path $taskLogs -Force | Out-Null
$taskPidFile = Join-Path $taskLogs 'mobile-qa.pid'
if (Test-Path -LiteralPath $taskPidFile) {
    $taskExistingPid = [int](Get-Content -LiteralPath $taskPidFile -Raw)
    $taskExisting = Get-CimInstance Win32_Process -Filter "ProcessId=$taskExistingPid" -ErrorAction SilentlyContinue
    if ($taskExisting -and $taskExisting.ExecutablePath -eq $taskExecutable -and $taskExisting.CommandLine -match 'mobile-qa-task') {
        throw "QA-003 已在執行，PID $taskExistingPid；不要重複派工"
    }
}
$taskPrompt = 'Read tools/claude/mobile-qa-task.md and complete QA-003 now. Follow its scope and restrictions. Update TASKS.md with real progress percentages. Do not commit, push, deploy, or create new art.'
$taskProcess = Start-Process -FilePath $taskExecutable -WorkingDirectory $taskRoot -WindowStyle Hidden -PassThru -ArgumentList @(
    '-p', '--permission-mode', 'acceptEdits', '--allowedTools', 'Bash,PowerShell,Read,Write,Edit,Glob,Grep', '--', ('"' + $taskPrompt + '"')
) -RedirectStandardOutput (Join-Path $taskLogs 'mobile-qa.out.log') -RedirectStandardError (Join-Path $taskLogs 'mobile-qa.err.log')
Set-Content -LiteralPath $taskPidFile -Value $taskProcess.Id
Write-Output "QA-003 啟動程序 PID $($taskProcess.Id)，是否已開始工作需查看 TASKS.md 與 capture_out/claude-cli 日誌。"
