param(
 [Parameter(Mandatory=$true)][string]$Domain,
 [ValidateSet("Chrome")][string]$Browser="Chrome",
 [int]$Duration=45,
 [string]$BaseDir="C:\MachineObserver"
)
$ErrorActionPreference="Stop"
$inspector=Join-Path $BaseDir "DomainInspector-V131.ps1"
$pipeline=Join-Path $BaseDir "Run-EvidencePipeline.ps1"
foreach($f in @($inspector,$pipeline)){if(-not(Test-Path $f)){throw "Missing dependency: $f"}}
$before=@(Get-ChildItem (Join-Path $BaseDir "sessions") -Directory -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName)
Write-Host "=== MACHINEOBSERVER V1 MASTER RUN ===" -ForegroundColor Cyan
& $inspector -Domain $Domain -Browser $Browser -Duration $Duration
if($LASTEXITCODE -ne 0){throw "DomainInspector failed"}
$after=@(Get-ChildItem (Join-Path $BaseDir "sessions") -Directory -ErrorAction Stop | Sort-Object LastWriteTime -Descending)
$session=$after | Where-Object { $before -notcontains $_.FullName } | Select-Object -First 1
if(-not $session){$session=$after | Where-Object { Test-Path (Join-Path $_.FullName "report.json") } | Select-Object -First 1}
if(-not $session){throw "Could not resolve completed session directory"}
$report=Join-Path $session.FullName "report.json"
$cdp=Join-Path $session.FullName "cdp-chrome.jsonl"
if(-not(Test-Path $report)){throw "Session has no report.json: $($session.FullName)"}
if(-not(Test-Path $cdp)){throw "Session has no cdp-chrome.jsonl: $($session.FullName)"}
Write-Host "\nSESSION LOCKED FOR PIPELINE: $($session.FullName)" -ForegroundColor Green
& $pipeline -Session $session.FullName
if($LASTEXITCODE -ne 0){throw "Evidence pipeline failed"}
Write-Host "\n=== MACHINEOBSERVER COMPLETE ===" -ForegroundColor Green
Write-Host "Session: $($session.FullName)"
