param([string]$Domain="https://example.com",[int]$Duration=12,[string]$BaseDir="C:\MachineObserver")
$ErrorActionPreference="Stop"
$transport=Join-Path $BaseDir "EtwTransportSensor-V01.ps1"
if(-not(Test-Path $transport)){throw "Missing $transport"}
$chrome1="$env:ProgramFiles\Google\Chrome\Application\chrome.exe"
$chrome2="$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe"
$chrome=@($chrome1,$chrome2)|Where-Object{Test-Path $_}|Select-Object -First 1
if(-not $chrome){throw "Chrome executable not found."}
$stamp=Get-Date -Format "yyyy-MM-dd_HHmmss"
$session=Join-Path $BaseDir ("sessions\HANDSHAKE_"+$stamp)
$profile=Join-Path $session "chrome-profile"
New-Item -ItemType Directory -Path $profile -Force|Out-Null
$l=[Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback,0);$l.Start();$port=([Net.IPEndPoint]$l.LocalEndpoint).Port;$l.Stop()
$out=Join-Path $session "transport.jsonl"
$job=Start-Job -ScriptBlock {param($sensor,$outfile,$seconds)& $sensor -OutFile $outfile -Duration $seconds} -ArgumentList $transport,$out,$Duration
Start-Sleep -Seconds 2
$p=Start-Process -FilePath $chrome -ArgumentList @("--remote-debugging-port=$port","--user-data-dir=$profile","--no-first-run","--no-default-browser-check","--new-window",$Domain) -PassThru
Write-Host "CONTROLLED CHROME ROOT: $($p.Id)" -ForegroundColor Cyan
Write-Host "CDP PORT: $port"
Write-Host "TARGET: $Domain"
Write-Host "ETW started before Chrome." -ForegroundColor Green
Wait-Job $job|Out-Null
Receive-Job $job
Remove-Job $job
$txt=[IO.Path]::ChangeExtension($out,"txt")
if(-not(Test-Path $txt)){throw "Decoded ETW text missing: $txt"}
$hostName=([Uri]$Domain).DnsSafeHost
$ips=@()
try{$ips=@([Net.Dns]::GetHostAddresses($hostName)|ForEach-Object{$_.IPAddressToString}|Select-Object -Unique)}catch{}
$matches=@()
foreach($line in (Get-Content $txt)){
 $hit=$false
 foreach($ip in $ips){if($line -match [regex]::Escape($ip)){$hit=$true;break}}
 if($hit -and $line -match '(?i)SynSentState|SynRcvdState|EstablishedState|SYN|connect|connection .*exists|TCP send event|received NBL'){$matches+=$line}
}
$evidence=Join-Path $session "handshake-evidence.txt"
$matches|Set-Content $evidence -Encoding UTF8
[ordered]@{schema="machineobserver.handshake-test.v0.1";target=$Domain;targetHost=$hostName;resolvedIPs=$ips;controlledChromeRootPid=$p.Id;cdpPort=$port;etwStartedBeforeBrowser=$true;matchingEvidenceLines=$matches.Count;tcpHandshakeProven=$false;tlsHandshakeProven=$false;note="Candidate handshake evidence only. Promote SYN/SYN-ACK/ACK and TLS states only when directly decoded.";transportText=$txt;evidenceFile=$evidence}|ConvertTo-Json -Depth 6|Set-Content (Join-Path $session "handshake-report.json") -Encoding UTF8
Write-Host ""
Write-Host "=== HANDSHAKE CANDIDATE EVIDENCE ===" -ForegroundColor Yellow
$matches|Select-Object -First 80
Write-Host ""
Write-Host "SESSION: $session" -ForegroundColor Green
Write-Host "REPORT : $(Join-Path $session 'handshake-report.json')"
Write-Host "EVIDENCE: $evidence"
Write-Host "Chrome left open intentionally."
