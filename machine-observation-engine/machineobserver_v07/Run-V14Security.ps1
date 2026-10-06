param([Parameter(Mandatory=$true)][string]$Domain,[int]$Duration=12,[switch]$ActiveTls,[string]$BaseDir="C:\MachineObserver")
$ErrorActionPreference="Stop"
$test=Join-Path $BaseDir "Test-FreshHandshake.ps1"
$analyzer=Join-Path $BaseDir "TransportSecurityAnalyzer-V01.py"
if(-not(Test-Path $test)){throw "Missing $test"}
if(-not(Test-Path $analyzer)){throw "Missing $analyzer"}
& $test -Domain $Domain -Duration $Duration
$session=Get-ChildItem (Join-Path $BaseDir "sessions") -Directory -Filter "HANDSHAKE_*" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if(-not $session){throw "No HANDSHAKE session found."}
$transport=Join-Path $session.FullName "transport.txt"
$report=Join-Path $session.FullName "security-report.json"
$args=@($analyzer,"--domain",$Domain,"--transport",$transport,"-o",$report)
if($ActiveTls){$args+="--active-tls"}
Write-Host ""
Write-Host "=== TRANSPORT + SECURITY ANALYSIS ===" -ForegroundColor Cyan
& python @args
if($LASTEXITCODE -ne 0){throw "Security analyzer failed with exit code $LASTEXITCODE"}
Write-Host ""
Write-Host "SECURITY REPORT: $report" -ForegroundColor Green
Write-Host "ActiveTls only performs a standard TLS negotiation; no login, credentials, cookies, HTTP body capture, or exploitation." -ForegroundColor DarkGray
