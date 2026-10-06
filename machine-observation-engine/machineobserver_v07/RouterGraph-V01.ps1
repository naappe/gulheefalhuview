param(
 [string]$Router = "",
 [int]$Duration = 12,
 [string]$BaseDir = "C:\MachineObserver"
)
$ErrorActionPreference="Stop"
$boundary=Join-Path $BaseDir "RouterBoundarySensor-V01.ps1"
$reasoner=Join-Path $BaseDir "RouterBoundaryReasoner-V01.py"
$etw=Join-Path $BaseDir "EtwTransportSensor-V01.ps1"
foreach($f in @($boundary,$reasoner,$etw)){if(-not(Test-Path $f)){throw "Missing $f"}}
$route=Get-NetRoute -DestinationPrefix "0.0.0.0/0" -AddressFamily IPv4 | Where-Object {$_.NextHop -ne "0.0.0.0"} | Sort-Object @{Expression={$_.RouteMetric+$_.InterfaceMetric}} | Select-Object -First 1
if(-not $Router){$Router=$route.NextHop}
& $boundary -Gateway $Router -BaseDir $BaseDir
$boundarySession=Get-ChildItem (Join-Path $BaseDir "sessions") -Directory -Filter "ROUTER_*"|Sort-Object LastWriteTime -Descending|Select-Object -First 1
$boundaryReport=Join-Path $boundarySession.FullName "router-boundary.json"
$reasoning=Join-Path $boundarySession.FullName "router-reasoning.json"
& python $reasoner $boundaryReport -o $reasoning
if($LASTEXITCODE -ne 0){throw "Router reasoner failed."}
$stamp=Get-Date -Format "yyyy-MM-dd_HHmmss"
$session=Join-Path $BaseDir ("sessions\ROUTERGRAPH_"+$stamp)
New-Item -ItemType Directory -Path $session -Force|Out-Null
$transportOut=Join-Path $session "transport.jsonl"
# Launch a normal controlled browser after ETW starts. No login automation or credential capture.
$chrome=@("$env:ProgramFiles\Google\Chrome\Application\chrome.exe","$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe")|Where-Object{Test-Path $_}|Select-Object -First 1
if(-not $chrome){throw "Chrome not found"}
$profile=Join-Path $session "chrome-profile"
New-Item -ItemType Directory -Path $profile -Force|Out-Null
$l=[Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback,0);$l.Start();$port=([Net.IPEndPoint]$l.LocalEndpoint).Port;$l.Stop()
$launch=Join-Path $session "launch.ps1"
@"
param([string]\$Chrome,[string]\$Profile,[int]\$Port,[string]\$Url)
Start-Sleep -Seconds 2
Start-Process -FilePath \$Chrome -ArgumentList @("--remote-debugging-port=\$Port","--user-data-dir=\$Profile","--no-first-run","--no-default-browser-check","--new-window",\$Url)
"@ | Set-Content $launch -Encoding UTF8
$routerUrl="http://"+$Router+"/"
$helper=Start-Process powershell.exe -ArgumentList @("-NoProfile","-ExecutionPolicy","Bypass","-File",$launch,"-Chrome",$chrome,"-Profile",$profile,"-Port",$port,"-Url",$routerUrl) -PassThru
Write-Host "ETW first; controlled Chrome will open $routerUrl after 2 seconds." -ForegroundColor Cyan
& $etw -OutFile $transportOut -Duration $Duration
$helper.WaitForExit()
$txt=[IO.Path]::ChangeExtension($transportOut,"txt")
# Router-specific kernel evidence only. No port scan.
$kernel=@()
if(Test-Path $txt){
 $kernel=Select-String -Path $txt -Pattern ([regex]::Escape($Router)) | ForEach-Object {$_.Line}
}
$kernelFile=Join-Path $session "router-kernel-evidence.txt"
$kernel|Set-Content $kernelFile -Encoding UTF8
# Browser-side public page metadata via CDP HTTP discovery; do not read values from forms/storage/cookies.
$targets=@()
try{$targets=Invoke-RestMethod -Uri ("http://127.0.0.1:"+$port+"/json") -TimeoutSec 3}catch{}
$page=@($targets|Where-Object {$_.type -eq "page"}|Select-Object -First 1)
$targetInfo=$null
if($page.Count){
 $targetInfo=[ordered]@{id=$page[0].id;type=$page[0].type;url=$page[0].url;title=$page[0].title;webSocketDebuggerUrlPresent=[bool]$page[0].webSocketDebuggerUrl}
}
$b=Get-Content $boundaryReport -Raw|ConvertFrom-Json
$graph=[ordered]@{
 schema="machineobserver.router-graph.v0.1"
 capturedAt=(Get-Date).ToUniversalTime().ToString("o")
 router=$Router
 nodes=@(
  [ordered]@{id="pc";type="HOST";ipv4=$b.pc.ipv4},
  [ordered]@{id="interface";type="NETWORK_INTERFACE";name=$b.pc.interfaceName;index=$b.pc.interfaceIndex},
  [ordered]@{id="gateway";type="ROUTER_LAN";ipv4=$Router;mac=$b.gateway.mac},
  [ordered]@{id="page";type="BROWSER_TARGET";observation=$targetInfo}
 )
 edges=@(
  [ordered]@{from="pc";to="interface";evidence="OBSERVED_LOCAL_NETWORK_STATE"},
  [ordered]@{from="interface";to="gateway";evidence="OBSERVED_LOCAL_NETWORK_STATE"},
  [ordered]@{from="gateway";to="page";evidence=if($targetInfo){"OBSERVED_BROWSER_TARGET"}else{"UNKNOWN"}}
 )
 transport=[ordered]@{routerEvidenceLines=@($kernel).Count;evidenceFile=$kernelFile;source=$txt}
 unknowns=@("router WAN address","router NAT table/mapping","router firewall rules","router private firmware internals","authenticated management state")
 safety=[ordered]@{portScanPerformed=$false;loginAutomated=$false;credentialsCaptured=$false;cookieValuesCaptured=$false;configurationChanged=$false}
}
$graphFile=Join-Path $session "router-graph.json"
$graph|ConvertTo-Json -Depth 10|Set-Content $graphFile -Encoding UTF8
Write-Host ""
Write-Host "=== ROUTER GRAPH V0.1 ===" -ForegroundColor Green
Write-Host "Router       : $Router"
Write-Host "Browser URL  : $routerUrl"
Write-Host "CDP port     : $port"
Write-Host "Kernel lines : $(@($kernel).Count)"
Write-Host "Graph        : $graphFile"
Write-Host "Evidence     : $kernelFile"
Write-Host "Boundary     : $boundaryReport"
Write-Host "Reasoning    : $reasoning"
Write-Host ""
Write-Host "Authenticated/private router internals remain UNKNOWN." -ForegroundColor Yellow
