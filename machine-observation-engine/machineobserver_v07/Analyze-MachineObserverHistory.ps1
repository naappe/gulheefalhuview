param([string]$History="",[string]$BaseDir="C:\MachineObserver")
$ErrorActionPreference="Stop"
if(-not $History){$History=(Get-ChildItem (Join-Path $BaseDir "history") -Directory -Filter "RUN_*"|Sort-Object LastWriteTime -Descending|Select-Object -First 1).FullName}
if(-not $History){throw "No history run found."}
$an=Join-Path $BaseDir "DeepHistoryAnalyzer-V01.py"
if(-not(Test-Path $an)){throw "Missing $an"}
$out=Join-Path $History "deep-history.json"
python $an $History -o $out
if($LASTEXITCODE -ne 0){throw "Deep analyzer failed."}
$d=Get-Content $out -Raw|ConvertFrom-Json
Write-Host ""
Write-Host "=== MACHINEOBSERVER DEEP HISTORY ===" -ForegroundColor Cyan
Write-Host "Trace files        : $($d.sourceFiles)"
Write-Host "Connection objects : $($d.connectionObjects)"
Write-Host "TX events          : $($d.transport.txEvents)"
Write-Host "RX events          : $($d.transport.rxEvents)"
Write-Host "ACK events         : $($d.transport.ackEvents)"
Write-Host "RTT events         : $($d.transport.rttEvents)"
Write-Host "Deep graph         : $out" -ForegroundColor Green
