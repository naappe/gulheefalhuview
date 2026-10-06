# MachineObserver Domain Inspector V1.1 - isolated browser observation session.
[CmdletBinding()]
param(
    [string]$Domain,
    [ValidateSet("Chrome","Edge","Both")][string]$Browser="Both",
    [int]$Duration=60,
    [string]$BaseDir="C:\MachineObserver"
)
$ErrorActionPreference="Stop"

if([string]::IsNullOrWhiteSpace($Domain)){$Domain=Read-Host "Domain or URL"}
$raw=$Domain.Trim()
if($raw -notmatch '^https?://'){$raw="https://$raw"}
try{$u=[Uri]$raw}catch{throw "Invalid domain or URL"}
if($u.Scheme -notin @("http","https")){throw "Only http/https supported"}
$targetHost=$u.DnsSafeHost.ToLowerInvariant()
$stamp=Get-Date -Format "yyyy-MM-dd_HHmmss"
$safeHost=$targetHost -replace '[^a-zA-Z0-9._-]','_'
$session=Join-Path $BaseDir ("sessions\"+$stamp+"_"+$safeHost)
New-Item -ItemType Directory $session -Force|Out-Null

$deps=@("CdpSensor.ps1","ProcessGraph.ps1","SocketSensor.ps1","Correlate-V3.ps1")
foreach($f in $deps){
    $src=Join-Path $BaseDir $f
    if(-not(Test-Path $src)){throw "Missing sensor: $f"}
    $parseErrors=$null
    [void][Management.Automation.Language.Parser]::ParseFile($src,[ref]$null,[ref]$parseErrors)
    if($parseErrors.Count){throw "Sensor parser failure: $f : $($parseErrors[0].Message)"}
    Copy-Item $src (Join-Path $session $f) -Force
}

. (Join-Path $session "ProcessGraph.ps1")
. (Join-Path $session "Correlate-V3.ps1")

$chrome="C:\Program Files\Google\Chrome\Application\chrome.exe"
$edge="C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"

function Get-FreeTcpPort {
    $listener=[Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback,0)
    $listener.Start()
    try{return ([Net.IPEndPoint]$listener.LocalEndpoint).Port}
    finally{$listener.Stop()}
}
function Wait-Cdp([int]$Port){
    $end=(Get-Date).AddSeconds(20)
    while((Get-Date)-lt $end){
        try{$null=Invoke-RestMethod ("http://127.0.0.1:"+$Port+"/json/version") -TimeoutSec 1;return $true}catch{}
        Start-Sleep -Milliseconds 200
    }
    return $false
}
function Wait-CdpTarget([int]$Port,[string]$HostName){
    $end=(Get-Date).AddSeconds(20)
    while((Get-Date)-lt $end){
        try{
            $rawTargets=Invoke-RestMethod ("http://127.0.0.1:"+$Port+"/json/list") -TimeoutSec 1
            foreach($t in @($rawTargets|ForEach-Object{$_})){
                if([string]$t.type -ne "page"){continue}
                try{$h=([Uri]([string]$t.url)).DnsSafeHost.ToLowerInvariant()}catch{continue}
                if($h -eq $HostName){return $true}
            }
        }catch{}
        Start-Sleep -Milliseconds 200
    }
    return $false
}
function Launch-IsolatedBrowser([string]$Exe,[string]$Name,[int]$Port,[string]$Profile,[bool]$IsEdge){
    if(-not(Test-Path $Exe)){throw "$Name executable not found: $Exe"}
    New-Item -ItemType Directory $Profile -Force|Out-Null
    $args=@(
        "--remote-debugging-address=127.0.0.1",
        "--remote-debugging-port=$Port",
        "--user-data-dir=$Profile",
        "--disable-sync",
        "--no-first-run",
        "--no-default-browser-check",
        "--disable-background-mode",
        "--new-window",
        $raw
    )
    if($IsEdge){$args=@("--disable-features=msEdgeFirstRunExperience")+$args}
    $launcher=Start-Process $Exe -ArgumentList $args -PassThru
    if(-not(Wait-Cdp $Port)){throw "$Name CDP not ready on $Port"}
    if(-not(Wait-CdpTarget $Port $targetHost)){throw "$Name did not expose requested host '$targetHost' on CDP port $Port"}
    return $launcher
}

Write-Host "MachineObserver Domain Inspector V1.1" -ForegroundColor Cyan
Write-Host "Target:  $raw"
Write-Host "Session: $session"

$graphs=@()
$jobs=@()
$reports=@{}
$owned=@()

if($Browser -in @("Chrome","Both")){
    $cp=Get-FreeTcpPort
    $profile=Join-Path $session "profile-chrome"
    $launch=Launch-IsolatedBrowser $chrome "Chrome" $cp $profile $false
    $owned+=[pscustomobject]@{Browser="chrome";LauncherPID=$launch.Id;DebugPort=$cp;Profile=$profile}
    $cg=Get-ControlledProcessGraph chrome $cp $chrome
    $graphs+=$cg
    $cc=Join-Path $session "cdp-chrome.jsonl"
    $jobs+=Start-Job -ArgumentList $session,$cc,$Duration,$targetHost,$cp -ScriptBlock {
        param($d,$f,$s,$h,$p)
        . "$d\CdpSensor.ps1"
        Invoke-CdpCapture -Port $p -OutFile $f -Label chrome -Seconds $s -TargetHost $h
    }
}
if($Browser -in @("Edge","Both")){
    $ep=Get-FreeTcpPort
    $profile=Join-Path $session "profile-edge"
    $launch=Launch-IsolatedBrowser $edge "Edge" $ep $profile $true
    $owned+=[pscustomobject]@{Browser="edge";LauncherPID=$launch.Id;DebugPort=$ep;Profile=$profile}
    $eg=Get-ControlledProcessGraph msedge $ep $edge
    $graphs+=$eg
    $ec=Join-Path $session "cdp-edge.jsonl"
    $jobs+=Start-Job -ArgumentList $session,$ec,$Duration,$targetHost,$ep -ScriptBlock {
        param($d,$f,$s,$h,$p)
        . "$d\CdpSensor.ps1"
        Invoke-CdpCapture -Port $p -OutFile $f -Label edge -Seconds $s -TargetHost $h
    }
}

$sf=Join-Path $session "sockets.jsonl"
$jobs+=Start-Job -ArgumentList $session,$sf,$Duration,$graphs -ScriptBlock {
    param($d,$f,$s,$g)
    . "$d\SocketSensor.ps1"
    Start-SocketSensor -Graphs $g -OutFile $f -Seconds $s|Out-Null
}

# Sensors are now active. Reload only the isolated requested page so startup traffic is observable.
Start-Sleep -Seconds 2
foreach($o in $owned){
    try{
        $targets=Invoke-RestMethod ("http://127.0.0.1:"+$o.DebugPort+"/json/list") -TimeoutSec 2
        $page=$null
        foreach($t in @($targets|ForEach-Object{$_})){
            if([string]$t.type -ne "page"){continue}
            try{$h=([Uri]([string]$t.url)).DnsSafeHost.ToLowerInvariant()}catch{continue}
            if($h -eq $targetHost){$page=$t;break}
        }
        if($page){
            $ws=[Net.WebSockets.ClientWebSocket]::new()
            try{
                $null=$ws.ConnectAsync([Uri]([string]$page.webSocketDebuggerUrl),[Threading.CancellationToken]::None).GetAwaiter().GetResult()
                $bytes=[Text.Encoding]::UTF8.GetBytes('{"id":9001,"method":"Page.reload","params":{"ignoreCache":false}}')
                $null=$ws.SendAsync([ArraySegment[byte]]::new($bytes),[Net.WebSockets.WebSocketMessageType]::Text,$true,[Threading.CancellationToken]::None).GetAwaiter().GetResult()
            }finally{try{$ws.Dispose()}catch{}}
        }
    }catch{Write-Warning "Automatic reload failed for $($o.Browser): $($_.Exception.Message)"}
}

Wait-Job $jobs|Out-Null
foreach($j in $jobs){Receive-Job $j|Out-Host}
Remove-Job $jobs

if($Browser -in @("Chrome","Both")){$reports.chrome=@(Invoke-Correlate $cc $sf $cg chrome)}
if($Browser -in @("Edge","Both")){$reports.edge=@(Invoke-Correlate $ec $sf $eg edge)}

function CV($r,$v){@($r|Where-Object{$_.Verdict -eq $v}).Count}
$summary=@()
foreach($n in @("chrome","edge")){
    if($reports.ContainsKey($n)){
        $r=$reports[$n]
        $summary+=[pscustomobject]@{
            Browser=$n
            Requests=@($r).Count
            SINGLE=(CV $r "SINGLE")
            AMBIGUOUS=(CV $r "AMBIGUOUS")
            NO_SOCKET=(CV $r "NO_SOCKET")
            FOREIGN_ONLY=(CV $r "FOREIGN_ONLY")
            PROTOCOL_GAP=(CV $r "PROTOCOL_GAP")
            SENSOR_GAP=(CV $r "SENSOR_GAP")
        }
    }
}

$rf=Join-Path $session "report.json"
[ordered]@{
    schema="machineobserver.domain-inspector.v1.1"
    timestamp=(Get-Date).ToUniversalTime().ToString("o")
    target=[ordered]@{input=$Domain;url=$raw;host=$targetHost}
    browser=$Browser
    durationSeconds=$Duration
    session=$session
    isolation=[ordered]@{dynamicDebugPorts=$true;uniqueProfiles=$true;ownedBrowsers=$owned}
    exactRequestSocketProof=$false
    evidenceSemantics=@("SINGLE","AMBIGUOUS","NO_SOCKET","FOREIGN_ONLY","PROTOCOL_GAP","SENSOR_GAP")
    summary=$summary
    rows=$reports
}|ConvertTo-Json -Depth 15|Set-Content $rf -Encoding UTF8

Write-Host "=== SUMMARY ===" -ForegroundColor Cyan
$summary|Format-Table -AutoSize
Write-Host "Exact request -> socket proof: NO" -ForegroundColor Yellow
Write-Host "Report: $rf" -ForegroundColor Green
Write-Host "Browser processes are intentionally left open for inspection; only session-owned roots should be stopped during cleanup." -ForegroundColor DarkGray
