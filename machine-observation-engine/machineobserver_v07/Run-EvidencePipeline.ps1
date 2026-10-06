param(
 [Parameter(Mandatory=$true)][string]$Session,
 [string]$BaseDir="C:\MachineObserver"
)
$ErrorActionPreference="Stop"
$server=Join-Path $BaseDir "ServerEvidenceSensor.py"
$unified=Join-Path $BaseDir "UnifiedAgentInput-V02.py"
$resolver=Join-Path $BaseDir "EvidenceResolver-V01.py"
$agents=Join-Path $BaseDir "agents\run_agents.py"
$report=Join-Path $Session "report.json"
$cdp=Join-Path $Session "cdp-chrome.jsonl"
foreach($p in @($server,$unified,$resolver,$agents,$report,$cdp)){if(-not(Test-Path $p)){throw "Missing dependency: $p"}}
Write-Host "=== MACHINEOBSERVER EVIDENCE PIPELINE ===" -ForegroundColor Cyan
python $server $cdp --out (Join-Path $Session "server-evidence.json")
if($LASTEXITCODE -ne 0){throw "ServerEvidenceSensor failed"}
python $resolver $Session -o (Join-Path $Session "evidence-resolution.json")
if($LASTEXITCODE -ne 0){throw "EvidenceResolver failed"}
python $unified $Session -o (Join-Path $Session "agent-input.json")
if($LASTEXITCODE -ne 0){throw "UnifiedAgentInput failed"}
python $agents (Join-Path $Session "agent-input.json") --out (Join-Path $Session "reasoning-v02.json")
if($LASTEXITCODE -ne 0){throw "Five-agent reasoning failed"}
Write-Host "\n=== COMPLETE ===" -ForegroundColor Green
Get-Item (Join-Path $Session "server-evidence.json"),(Join-Path $Session "evidence-resolution.json"),(Join-Path $Session "agent-input.json"),(Join-Path $Session "reasoning-v02.json") | Select-Object Name,Length,LastWriteTime | Format-Table -AutoSize
Write-Host "\n=== EVIDENCE RESOLUTION ===" -ForegroundColor Cyan
Get-Content (Join-Path $Session "evidence-resolution.json") -Raw
Write-Host "\n=== FINAL REASONING ===" -ForegroundColor Cyan
Get-Content (Join-Path $Session "reasoning-v02.json") -Raw
