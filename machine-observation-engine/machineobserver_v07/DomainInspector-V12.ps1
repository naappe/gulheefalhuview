# MachineObserver Domain Inspector V1.2 - page-state integration
# Extends V1.1 with read-only page structure snapshots.
[CmdletBinding()]param(
 [string]$Domain,
 [ValidateSet("Chrome","Edge")][string]$Browser="Chrome",
 [int]$Duration=45,
 [string]$BaseDir="C:\MachineObserver"
)
$ErrorActionPreference="Stop"
if([string]::IsNullOrWhiteSpace($Domain)){$Domain=Read-Host "Domain or URL"}
$raw=$Domain.Trim();if($raw -notmatch '^https?://'){$raw="https://$raw"}
$u=[Uri]$raw;if($u.Scheme -notin @("http","https")){throw "Only http/https supported"}
$targetHost=$u.DnsSafeHost.ToLowerInvariant()
$stamp=Get-Date -Format "yyyy-MM-dd_HHmmss";$safeHost=$targetHost -replace '[^a-zA-Z0-9._-]','_'
$session=Join-Path $BaseDir ("sessions\"+$stamp+"_"+$safeHost);New-Item -ItemType Directory $session -Force|Out-Null

$deps=@("CdpSensor.ps1","ProcessGraph.ps1","SocketSensor.ps1","Correlate-V3.ps1","PageStateObserver.ps1")
foreach($f in $deps){
 $src=Join-Path $BaseDir $f;if(-not(Test-Path $src)){throw "Missing sensor: $f"}
 $tok=$null;$err=$null;[void][Management.Automation.Language.Parser]::ParseFile($src,[ref]$tok,[ref]$err)
 if($err.Count){throw "Parser failure in $f : $($err[0].Message)"}
 Copy-Item $src (Join-Path $session $f) -Force
}
. (Join-Path $session "ProcessGraph.ps1")
. (Join-Path $session "Correlate-V3.ps1")
. (Join-Path $session "PageStateObserver.ps1")

function FreePort{$l=[Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback,0);$l.Start();try{([Net.IPEndPoint]$l.LocalEndpoint).Port}finally{$l.Stop()}}
function WaitCdp([int]$p){$e=(Get-Date).AddSeconds(20);while((Get-Date)-lt $e){try{$null=Invoke-RestMethod ("http://127.0.0.1:"+$p+"/json/version") -TimeoutSec 1;return $true}catch{};Start-Sleep -Milliseconds 200};$false}
function WaitTarget([int]$p){
 $e=(Get-Date).AddSeconds(60);$last=@()
 while((Get-Date)-lt $e){
  try{
   $last=@(Invoke-RestMethod ("http://127.0.0.1:"+$p+"/json/list") -TimeoutSec 2)
   foreach($t in $last){
    if(([string]$t.type) -ne "page"){continue}
    $targetUrl=[string]$t.url
    try{$tu=[Uri]$targetUrl;if(-not $tu.IsAbsoluteUri){continue};$h=$tu.DnsSafeHost.ToLowerInvariant()}catch{continue}
    if([string]::Equals($h,$targetHost,[StringComparison]::OrdinalIgnoreCase)){return $true}
   }
  }catch{}
  Start-Sleep -Milliseconds 250
 }
 Write-Warning ("WaitTarget timeout. Requested host: "+$targetHost)
 foreach($t in $last){if(([string]$t.type) -eq "page"){Write-Warning ("Observed page target: "+[string]$t.url)}}
 return $false
}
function ReloadPage([int]$p){
 $page=$null;foreach($t in @(Invoke-RestMethod ("http://127.0.0.1:"+$p+"/json/list") -TimeoutSec 2)){if($t.type -ne "page"){continue};try{$h=([Uri]$t.url).DnsSafeHost.ToLowerInvariant()}catch{continue};if($h -eq $targetHost){$page=$t;break}}
 if(-not $page){throw "Target page disappeared"}
 $ws=[Net.WebSockets.ClientWebSocket]::new();try{$null=$ws.ConnectAsync([Uri]([string]$page.webSocketDebuggerUrl),[Threading.CancellationToken]::None).GetAwaiter().GetResult();$b=[Text.Encoding]::UTF8.GetBytes('{"id":9001,"method":"Page.reload"}');$null=$ws.SendAsync([ArraySegment[byte]]::new($b),[Net.WebSockets.WebSocketMessageType]::Text,$true,[Threading.CancellationToken]::None).GetAwaiter().GetResult()}finally{$ws.Dispose()}
}

if($Browser -eq "Chrome"){$exe="C:\Program Files\Google\Chrome\Application\chrome.exe";$family="chrome";$label="chrome"}
else{$exe="C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe";$family="msedge";$label="edge"}
if(-not(Test-Path $exe)){throw "Browser executable not found: $exe"}
$port=FreePort;$profile=Join-Path $session ("profile-"+$label)
$args=@("--remote-debugging-address=127.0.0.1","--remote-debugging-port=$port","--user-data-dir=$profile","--disable-sync","--no-first-run","--no-default-browser-check","--disable-background-mode","--new-window",$raw)
$launch=Start-Process $exe -ArgumentList $args -PassThru
if(-not(WaitCdp $port)){throw "CDP not ready on $port"};if(-not(WaitTarget $port)){throw "Requested host not exposed on CDP"}

Write-Host "MachineObserver Domain Inspector V1.2" -ForegroundColor Cyan
Write-Host "Target: $raw";Write-Host "Session: $session";Write-Host "CDP port: $port"
$graph=Get-ControlledProcessGraph $family $port $exe
$pre=Get-PageState -Port $port -TargetHost $targetHost
Write-Host ("PRE page: forms={0} inputs={1} password={2} submit={3}" -f $pre.formCount,$pre.inputCount,$pre.passwordFieldPresent,$pre.submitControlPresent)

$cdp=Join-Path $session ("cdp-"+$label+".jsonl");$sock=Join-Path $session "sockets.jsonl"
$j1=Start-Job -ArgumentList $session,$cdp,$Duration,$targetHost,$port,$label -ScriptBlock {param($d,$f,$s,$h,$p,$l);. "$d\CdpSensor.ps1";Invoke-CdpCapture -Port $p -OutFile $f -Label $l -Seconds $s -TargetHost $h}
$j2=Start-Job -ArgumentList $session,$sock,$Duration,$graph -ScriptBlock {param($d,$f,$s,$g);. "$d\SocketSensor.ps1";Start-SocketSensor -Graphs @($g) -OutFile $f -Seconds $s|Out-Null}
Start-Sleep -Seconds 2;ReloadPage $port
Wait-Job @($j1,$j2)|Out-Null;Receive-Job $j1|Out-Host;Receive-Job $j2|Out-Host;Remove-Job @($j1,$j2)
$post=Get-PageState -Port $port -TargetHost $targetHost
$rows=@(Invoke-Correlate $cdp $sock $graph $label)
function CV($v){@($rows|Where-Object{$_.Verdict -eq $v}).Count}
$summary=[pscustomobject]@{Browser=$label;Requests=$rows.Count;SINGLE=(CV "SINGLE");AMBIGUOUS=(CV "AMBIGUOUS");NO_SOCKET=(CV "NO_SOCKET");FOREIGN_ONLY=(CV "FOREIGN_ONLY");PROTOCOL_GAP=(CV "PROTOCOL_GAP");SENSOR_GAP=(CV "SENSOR_GAP")}
$report=[ordered]@{
 schema="machineobserver.domain-inspector.v1.2";timestamp=(Get-Date).ToUniversalTime().ToString("o")
 target=[ordered]@{url=$raw;host=$targetHost};session=$session
 isolation=[ordered]@{debugPort=$port;profile=$profile;launcherPID=$launch.Id}
 pageState=[ordered]@{before=$pre;after=$post}
 privacy=[ordered]@{inputValuesCaptured=$false;cookieDataCaptured=$false;storageValuesCaptured=$false}
 exactRequestSocketProof=$false;summary=$summary;rows=$rows
}
$rf=Join-Path $session "report.json";$report|ConvertTo-Json -Depth 16|Set-Content $rf -Encoding UTF8
Write-Host "=== SUMMARY ===" -ForegroundColor Cyan;$summary|Format-Table -AutoSize
Write-Host ("POST page: forms={0} inputs={1} password={2} submit={3}" -f $post.formCount,$post.inputCount,$post.passwordFieldPresent,$post.submitControlPresent)
Write-Host "Validation state: UNKNOWN" -ForegroundColor Yellow
Write-Host "Exact request -> socket proof: NO" -ForegroundColor Yellow
Write-Host "Report: $rf" -ForegroundColor Green
