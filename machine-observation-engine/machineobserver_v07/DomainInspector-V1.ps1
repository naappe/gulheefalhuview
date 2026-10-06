# MachineObserver Domain Inspector V1
[CmdletBinding()]param([string]$Domain,[ValidateSet("Chrome","Edge","Both")][string]$Browser="Both",[int]$Duration=60,[string]$BaseDir="C:\MachineObserver")
$ErrorActionPreference="Stop"
if([string]::IsNullOrWhiteSpace($Domain)){$Domain=Read-Host "Domain or URL"}
$raw=$Domain.Trim();if($raw -notmatch '^https?://'){$raw="https://$raw"}
try{$u=[Uri]$raw}catch{throw "Invalid domain or URL"}
if($u.Scheme -notin @("http","https")){throw "Only http/https supported"}
$targetHost=$u.DnsSafeHost.ToLowerInvariant();$stamp=Get-Date -Format "yyyy-MM-dd_HHmmss";$safeHost=$targetHost -replace '[^a-zA-Z0-9._-]','_'
$session=Join-Path $BaseDir ("sessions\"+$stamp+"_"+$safeHost);New-Item -ItemType Directory $session -Force|Out-Null
foreach($f in @("CdpSensor.ps1","ProcessGraph.ps1","SocketSensor.ps1","Correlate-V3.ps1")){if(-not(Test-Path (Join-Path $BaseDir $f))){throw "Missing sensor: $f"};Copy-Item (Join-Path $BaseDir $f) (Join-Path $session $f) -Force}
. (Join-Path $session "ProcessGraph.ps1");. (Join-Path $session "Correlate-V3.ps1")
$chrome="C:\Program Files\Google\Chrome\Application\chrome.exe";$edge="C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
function Wait-Cdp([int]$p){$e=(Get-Date).AddSeconds(20);while((Get-Date)-lt $e){try{$null=Invoke-RestMethod ("http://127.0.0.1:"+$p+"/json/version") -TimeoutSec 1;return $true}catch{};Start-Sleep -Milliseconds 250};$false}
function Launch($exe,$port,$profile,$isEdge){$a=@("--remote-debugging-address=127.0.0.1","--remote-debugging-port=$port","--user-data-dir=$profile","--disable-sync","--no-first-run","--no-default-browser-check","--disable-background-mode","--new-window",$raw);if($isEdge){$a=@("--disable-features=msEdgeFirstRunExperience")+$a};Start-Process $exe -ArgumentList $a|Out-Null;if(-not(Wait-Cdp $port)){throw "CDP not ready on $port"}}
Write-Host "MachineObserver Domain Inspector V1" -ForegroundColor Cyan;Write-Host "Target: $raw";Write-Host "Session: $session"
$graphs=@();$jobs=@();$reports=@{}
if($Browser -in @("Chrome","Both")){Launch $chrome 9222 (Join-Path $BaseDir "profiles\chrome-9222") $false;$cg=Get-ControlledProcessGraph chrome 9222 $chrome;$graphs+=$cg;$cc=Join-Path $session "cdp-chrome.jsonl";$jobs+=Start-Job -ArgumentList $session,$cc,$Duration -ScriptBlock {param($d,$f,$s);. "$d\CdpSensor.ps1";Invoke-CdpCapture 9222 $f chrome $s}}
if($Browser -in @("Edge","Both")){Launch $edge 9223 (Join-Path $BaseDir "profiles\edge-9223") $true;$eg=Get-ControlledProcessGraph msedge 9223 $edge;$graphs+=$eg;$ec=Join-Path $session "cdp-edge.jsonl";$jobs+=Start-Job -ArgumentList $session,$ec,$Duration -ScriptBlock {param($d,$f,$s);. "$d\CdpSensor.ps1";Invoke-CdpCapture 9223 $f edge $s}}
$sf=Join-Path $session "sockets.jsonl";$jobs+=Start-Job -ArgumentList $session,$sf,$Duration,$graphs -ScriptBlock {param($d,$f,$s,$g);. "$d\SocketSensor.ps1";Start-SocketSensor -Graphs $g -OutFile $f -Seconds $s|Out-Null}
Wait-Job $jobs|Out-Null;foreach($j in $jobs){Receive-Job $j|Out-Host};Remove-Job $jobs
if($Browser -in @("Chrome","Both")){$reports.chrome=@(Invoke-Correlate $cc $sf $cg chrome)}
if($Browser -in @("Edge","Both")){$reports.edge=@(Invoke-Correlate $ec $sf $eg edge)}
function CV($r,$v){@($r|Where-Object Verdict -eq $v).Count};$summary=@()
foreach($n in @("chrome","edge")){if($reports.ContainsKey($n)){$r=$reports[$n];$summary+=[PSCustomObject]@{Browser=$n;Requests=@($r).Count;SINGLE=(CV $r "SINGLE");AMBIGUOUS=(CV $r "AMBIGUOUS");NO_SOCKET=(CV $r "NO_SOCKET");CONTRADICTION_V32=(CV $r "CONTRADICTION")}}}
$rf=Join-Path $session "report.json";[ordered]@{schema="machineobserver.domain-inspector.v1";timestamp=(Get-Date).ToUniversalTime().ToString("o");target=[ordered]@{input=$Domain;url=$raw;host=$targetHost};browser=$Browser;durationSeconds=$Duration;session=$session;exactRequestSocketProof=$false;summary=$summary;rows=$reports}|ConvertTo-Json -Depth 15|Set-Content $rf -Encoding UTF8
Write-Host "=== SUMMARY ===" -ForegroundColor Cyan;$summary|Format-Table -AutoSize;Write-Host "Exact request -> socket proof: NO" -ForegroundColor Yellow;Write-Host "Report: $rf" -ForegroundColor Green
