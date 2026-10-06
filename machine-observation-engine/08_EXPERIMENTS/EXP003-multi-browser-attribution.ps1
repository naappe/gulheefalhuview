param([int]$Duration=60)
$ErrorActionPreference="Stop"
$root="C:\MachineObserver"
$socketFile=Join-Path $root "sockets-multi.jsonl"
$targets=@(
 [pscustomobject]@{Label="chrome";Exe="C:\Program Files\Google\Chrome\Application\chrome.exe";Port=9222;Profile="$env:TEMP\mo-chrome-profile2"},
 [pscustomobject]@{Label="edge";Exe="C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe";Port=9223;Profile="$env:TEMP\mo-edge-profile"}
)
New-Item -ItemType Directory -Path $root -Force|Out-Null
Remove-Item $socketFile -Force -ErrorAction SilentlyContinue

$socketJob=Start-Job -ArgumentList $socketFile,$Duration -ScriptBlock {
 param($file,$seconds)
 $seen=@{};$until=(Get-Date).AddSeconds($seconds)
 while((Get-Date)-lt $until){
  Get-NetTCPConnection -State Established -ErrorAction SilentlyContinue|ForEach-Object{
   $key="$($_.LocalAddress):$($_.LocalPort)>$($_.RemoteAddress):$($_.RemotePort)"
   if($seen.ContainsKey($key)){return};$seen[$key]=$true
   $p=Get-CimInstance Win32_Process -Filter "ProcessId=$($_.OwningProcess)" -ErrorAction SilentlyContinue
   $role="unknown"
   if($p.CommandLine -match '--utility-sub-type=network\.mojom\.NetworkService'){$role="network-service"}
   elseif($p.CommandLine -match '--type=renderer'){$role="renderer"}
   elseif($p.CommandLine -match '--type=gpu'){$role="gpu"}
   elseif($p.CommandLine -match '--type=utility'){$role="utility"}
   elseif($p.Name -in @("chrome.exe","msedge.exe")){$role="browser"}
   [ordered]@{timestamp=(Get-Date).ToString("o");localAddr=$_.LocalAddress;localPort=$_.LocalPort;remoteAddr=$_.RemoteAddress;remotePort=$_.RemotePort;pid=$_.OwningProcess;procName=$p.Name;executable=$p.ExecutablePath;parentPid=$p.ParentProcessId;commandLine=$p.CommandLine;role=$role}|ConvertTo-Json -Compress|Add-Content $file -Encoding UTF8
  }
  Start-Sleep -Milliseconds 250
 }
}

$jobs=@()
foreach($t in $targets){
 if(-not(Test-Path $t.Exe)){Write-Warning "$($t.Label) not found";continue}
 $file=Join-Path $root "capture-$($t.Label).jsonl";Remove-Item $file -Force -ErrorAction SilentlyContinue
 Start-Process $t.Exe -ArgumentList "--remote-debugging-port=$($t.Port)","--user-data-dir=$($t.Profile)","--no-first-run","--no-default-browser-check","https://chat.deepseek.com/"|Out-Null
 Start-Sleep 3
 $jobs+=Start-Job -ArgumentList $t.Port,$file,$t.Label,$Duration -ScriptBlock {
  param($port,$file,$label,$seconds)
  $targets=$null
  for($i=0;$i-lt 20;$i++){try{$targets=Invoke-RestMethod "http://127.0.0.1:$port/json";if($targets){break}}catch{};Start-Sleep -Milliseconds 500}
  $page=$targets|Where-Object{$_.type -eq "page" -and $_.url -like "https://chat.deepseek.com/*"}|Select-Object -First 1
  if(-not $page){throw "No DeepSeek page target for $label"}
  $ws=[Net.WebSockets.ClientWebSocket]::new();$cts=[Threading.CancellationTokenSource]::new()
  $ws.ConnectAsync([Uri]$page.webSocketDebuggerUrl,$cts.Token).Wait()
  $j=@{id=1;method="Network.enable"}|ConvertTo-Json -Compress;$b=[Text.Encoding]::UTF8.GetBytes($j);$s=[ArraySegment[byte]]::new($b)
  $ws.SendAsync($s,[Net.WebSockets.WebSocketMessageType]::Text,$true,$cts.Token).Wait()
  $buf=New-Object byte[] 65536;$until=(Get-Date).AddSeconds($seconds)
  while($ws.State -eq "Open" -and (Get-Date)-lt $until){
   $mem=[IO.MemoryStream]::new();$res=$null
   do{
    $seg=[ArraySegment[byte]]::new($buf);$task=$ws.ReceiveAsync($seg,$cts.Token)
    if(-not $task.Wait(500)){break};$res=$task.Result
    if($res.Count){$mem.Write($buf,0,$res.Count)}
   }while(-not $res.EndOfMessage)
   if($mem.Length -eq 0){$mem.Dispose();continue}
   try{$o=[Text.Encoding]::UTF8.GetString($mem.ToArray())|ConvertFrom-Json}catch{$mem.Dispose();continue};$mem.Dispose()
   if($o.method -ne "Network.responseReceived"){continue}
   $r=$o.params.response;$hostName="-";try{$hostName=([Uri]$r.url).Host}catch{}
   [ordered]@{timestamp=(Get-Date).ToString("o");sensor="browser-cdp";browser=$label;targetId=$page.id;url=$r.url;host=$hostName;status=$r.status;mimeType=$r.mimeType;remoteIP=$r.remoteIPAddress;remotePort=$r.remotePort}|ConvertTo-Json -Compress|Add-Content $file -Encoding UTF8
  }
  $ws.Dispose();$cts.Dispose()
 }
}
$jobs|Wait-Job|Receive-Job|Out-Host;$jobs|Remove-Job
Wait-Job $socketJob|Receive-Job|Out-Host;Remove-Job $socketJob

$sockets=@(Get-Content $socketFile -ErrorAction SilentlyContinue|ForEach-Object{try{$_|ConvertFrom-Json}catch{}})
foreach($t in $targets){
 $file=Join-Path $root "capture-$($t.Label).jsonl";if(-not(Test-Path $file)){Write-Host "$($t.Label): NO CAPTURE";continue}
 Write-Host "=== $($t.Label.ToUpper()) ==="
 Get-Content $file|ForEach-Object{try{$_|ConvertFrom-Json}catch{}}|ForEach-Object{
  $r=$_;$matches=@($sockets|Where-Object{$_.remoteAddr -eq $r.remoteIP -and $_.remotePort -eq $r.remotePort})
  $apps=@($matches|ForEach-Object{if($_.executable){[IO.Path]::GetFileNameWithoutExtension($_.executable)}elseif($_.procName){[IO.Path]::GetFileNameWithoutExtension($_.procName)}}|Sort-Object -Unique)
  $roles=@($matches|Where-Object{$_.role}|Select-Object -ExpandProperty role -Unique)
  [pscustomobject]@{Browser=$t.Label;Host=$r.host;RemoteIP=$r.remoteIP;Port=$r.remotePort;SocketApps=($apps-join ",");SocketRoles=($roles-join ",");Candidates=$matches.Count}
 }|Format-Table -AutoSize
}
