# Driver: launches Chrome + Edge, runs three sensors in parallel, correlates.

[CmdletBinding()]
param(
    [int]$Duration      = 90,
    [string]$OutDir     = "C:\MachineObserver",
    [string]$Chrome     = "C:\Program Files\Google\Chrome\Application\chrome.exe",
    [string]$Edge       = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
    [string]$ChromeProf = "$env:TEMP\mo-chrome-v3",
    [string]$EdgeProf   = "$env:TEMP\mo-edge-v3",
    [string]$TargetUrl  = "https://chat.deepseek.com/"
)

$ErrorActionPreference = "Stop"

# Load modules
. "$OutDir\CdpSensor.ps1"
. "$OutDir\ProcessGraph.ps1"
. "$OutDir\SocketSensor.ps1"
. "$OutDir\Correlate-V3.ps1"

if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir -Force | Out-Null }

$chromeCapture = Join-Path $OutDir "cdp-chrome.jsonl"
$edgeCapture   = Join-Path $OutDir "cdp-edge.jsonl"
$chromeSockets = Join-Path $OutDir "sock-chrome.jsonl"
$edgeSockets   = Join-Path $OutDir "sock-edge.jsonl"
$reportFile    = Join-Path $OutDir "report-v3.json"

foreach ($f in @($chromeCapture, $edgeCapture, $chromeSockets, $edgeSockets, $reportFile)) {
    if (Test-Path $f) { Remove-Item $f -Force }
}

Write-Host "=== MultiBrowser-V3 ===" -ForegroundColor Cyan
Write-Host "[1/5] Launching Chrome :9222" -ForegroundColor Cyan
Start-Process $Chrome -ArgumentList @(
    "--remote-debugging-port=9222",
    "--user-data-dir=$ChromeProf",
    "--no-first-run",
    "--no-default-browser-check",
    $TargetUrl
) | Out-Null

Write-Host "[2/5] Launching Edge   :9223" -ForegroundColor Cyan
Start-Process $Edge -ArgumentList @(
    "--remote-debugging-port=9223",
    "--user-data-dir=$EdgeProf",
    "--no-first-run",
    "--no-default-browser-check",
    $TargetUrl
) | Out-Null

Start-Sleep -Seconds 10

Write-Host "[3/5] Building process graphs ..." -ForegroundColor Cyan
$chromeGraph = Get-ProcessGraph -BrowserName "chrome" -BrowserExePath $Chrome
$edgeGraph   = Get-ProcessGraph -BrowserName "msedge" -BrowserExePath $Edge

Write-Host ("       Chrome family: {0} PIDs" -f $chromeGraph.Count) -ForegroundColor DarkCyan
Write-Host ("       Edge   family: {0} PIDs" -f $edgeGraph.Count)   -ForegroundColor DarkCyan

Write-Host "[4/5] Starting socket sensors + CDP captures ..." -ForegroundColor Cyan

$job = {
    param($ChromeCapture, $EdgeCapture, $ChromeSockets, $EdgeSockets,
          $ChromeGraph, $EdgeGraph, $Duration, $ModuleDir)

    . "$ModuleDir\CdpSensor.ps1"
    . "$ModuleDir\SocketSensor.ps1"

    $socketJob = Start-Job -ScriptBlock {
        param($OutDir, $ChromeSockets, $EdgeSockets, $ChromeGraph, $EdgeGraph, $Duration)
        . "$OutDir\SocketSensor.ps1"
        $end = (Get-Date).AddSeconds($Duration)
        while ((Get-Date) -lt $end) {
            $mid = (Get-Date).AddSeconds(1)
            Start-SocketSensor -FamilyPIDs $ChromeGraph -OutFile $ChromeSockets -Seconds 1
            Start-SocketSensor -FamilyPIDs $EdgeGraph   -OutFile $EdgeSockets   -Seconds 1
        }
    } -ArgumentList $ModuleDir, $ChromeSockets, $EdgeSockets, $ChromeGraph, $EdgeGraph, $Duration

    $edgeJob = Start-Job -ScriptBlock {
        param($OutDir, $Port, $Capture, $Label, $Duration)
        . "$OutDir\CdpSensor.ps1"
        Invoke-CdpCapture -Port $Port -OutFile $Capture -Label $Label -Seconds $Duration
    } -ArgumentList $ModuleDir, 9223, $EdgeCapture, "edge", $Duration

    Invoke-CdpCapture -Port 9222 -OutFile $ChromeCapture -Label "chrome" -Seconds $Duration

    Wait-Job $edgeJob, $socketJob | Out-Null
    Receive-Job $edgeJob | Out-Host
    Remove-Job $edgeJob
    Remove-Job $socketJob
}

& $job $chromeCapture $edgeCapture $chromeSockets $edgeSockets `
    $chromeGraph $edgeGraph $Duration $OutDir

Write-Host "[5/5] Correlating ..." -ForegroundColor Cyan

# NOTE: the socket records were written by two different jobs; reload them
$chromeSocketsLoaded = @()
if (Test-Path $chromeSockets) {
    $chromeSocketsLoaded = Get-Content $chromeSockets |
        ForEach-Object { try { $_ | ConvertFrom-Json } catch {} } | Where-Object { $_ }
}
$edgeSocketsLoaded = @()
if (Test-Path $edgeSockets) {
    $edgeSocketsLoaded = Get-Content $edgeSockets |
        ForEach-Object { try { $_ | ConvertFrom-Json } catch {} } | Where-Object { $_ }
}

# Merge socket records into one file for the correlator
$mergedSockets = Join-Path $OutDir "sock-all.jsonl"
if (Test-Path $mergedSockets) { Remove-Item $mergedSockets -Force }
if ($chromeSocketsLoaded) { $chromeSocketsLoaded | ForEach-Object { $_ | ConvertTo-Json -Compress } | Add-Content $mergedSockets }
if ($edgeSocketsLoaded)   { $edgeSocketsLoaded   | ForEach-Object { $_ | ConvertTo-Json -Compress } | Add-Content $mergedSockets }

$chromeRows = Invoke-Correlate -CdpFile $chromeCapture -SocketFile $mergedSockets `
    -FamilyPIDs $chromeGraph -BrowserName "chrome" -OutFile $null

$edgeRows = Invoke-Correlate -CdpFile $edgeCapture -SocketFile $mergedSockets `
    -FamilyPIDs $edgeGraph -BrowserName "edge" -OutFile $null

Write-Host ""
Write-Host "=== Chrome side ===" -ForegroundColor Cyan
$chromeRows | Select-Object Status, Host, RemoteIP, Verdict, OwnerName, OwnerRole, LocalPort |
    Format-Table -AutoSize

Write-Host "=== Edge side ===" -ForegroundColor Cyan
$edgeRows | Select-Object Status, Host, RemoteIP, Verdict, OwnerName, OwnerRole, LocalPort |
    Format-Table -AutoSize

Write-Host "=== Family summary ===" -ForegroundColor Cyan
Write-Host ("Chrome family: {0} PIDs" -f $chromeGraph.Count)
$chromeGraph.Values | Sort-Object Role | Format-Table PID, Role, RootPID -AutoSize

Write-Host ("Edge family: {0} PIDs" -f $edgeGraph.Count)
$edgeGraph.Values | Sort-Object Role | Format-Table PID, Role, RootPID -AutoSize

function Get-Verdict {
    param($Rows, [string]$ExpectedFamily)
    if (-not $Rows -or $Rows.Count -eq 0) { return 'NO_DATA' }

    $resolved = $Rows | Where-Object { $_.OwnerName }
    if ($resolved.Count -eq 0) { return 'NO_DATA' }

    $correct = ($resolved | Where-Object { $_.OwnerName -eq $ExpectedFamily }).Count
    $wrong   = ($resolved | Where-Object { $_.OwnerName -ne $ExpectedFamily }).Count
    $ambig   = ($Rows | Where-Object { $_.Verdict -eq 'AMBIGUOUS' }).Count

    if ($wrong -eq 0 -and $ambig -eq 0) { return 'PASS' }
    if ($wrong -eq 0 -and $ambig -gt 0) { return 'PARTIAL' }
    if ($wrong -gt 0)                   { return 'AMBIGUOUS' }
    return 'PARTIAL'
}

$chromeVerdict = Get-Verdict -Rows $chromeRows -ExpectedFamily 'chrome'
$edgeVerdict   = Get-Verdict -Rows $edgeRows   -ExpectedFamily 'msedge'

Write-Host ""
Write-Host "=== Final verdict ===" -ForegroundColor Cyan
Write-Host ("Chrome: {0}" -f $chromeVerdict) -ForegroundColor Green
Write-Host ("Edge  : {0}" -f $edgeVerdict)   -ForegroundColor Green

$report = [ordered]@{
    timestamp       = (Get-Date).ToString("o")
    chrome_verdict  = $chromeVerdict
    edge_verdict    = $edgeVerdict
    chrome_rows     = $chromeRows
    edge_rows       = $edgeRows
    chrome_family   = $chromeGraph.Values
    edge_family     = $edgeGraph.Values
}
$report | ConvertTo-Json -Depth 8 | Set-Content -Path $reportFile -Encoding UTF8
Write-Host ""
Write-Host "Report: $reportFile" -ForegroundColor Yellow
