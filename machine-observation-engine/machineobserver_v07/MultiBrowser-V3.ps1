# MachineObserver V3.2 driver. SINGLE = consistent with one family socket, not proof.
[CmdletBinding()]param([int]$Duration=60,[string]$OutDir="C:\MachineObserver",[string]$Chrome="C:\Program Files\Google\Chrome\Application\chrome.exe",[string]$Edge="C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",[string]$ChromeProf="$env:TEMP\mo-chrome-v32",[string]$EdgeProf="$env:TEMP\mo-edge-v32",[string]$TargetUrl="https://chat.deepseek.com/")
$ErrorActionPreference="Stop";if(-not(Test-Path $OutDir)){New-Item -ItemType Directory $OutDir -Force|Out-Null};. "$OutDir\CdpSensor.ps1";. "$OutDir\ProcessGraph.ps1";. "$OutDir\SocketSensor.ps1";. "$OutDir\Correlate-V3.ps1"
$cc=Join-Path $OutDir "cdp-chrome-v32.jsonl";$ec=Join-Path $OutDir "cdp-edge-v32.jsonl";$sf=Join-Path $OutDir "sockets-v32.jsonl";$rf=Join-Path $OutDir "report-v32.json";foreach($f in @($cc,$ec,$sf,$rf)){if(Test-Path $f){Remove-Item $f -Force}}
function Wait-Cdp([int]$Port){$e=(Get-Date).AddSeconds(15);while((Get-Date)-lt $e){try{$null=Invoke-RestMethod "http://127.0.0.1:$Port/json/version" -TimeoutSec 1;return $true}catch{};Start-Sleep -Milliseconds 250};$false}
Write-Host "=== MachineObserver V3.2 ===" -ForegroundColor Cyan
Start-Process $Chrome -ArgumentList @("--remote-debugging-address=127.0.0.1","--remote-debugging-port=9222","--user-data-dir=$ChromeProf","--disable-sync","--no-first-run","--no-default-browser-check",$TargetUrl)|Out-Null
Start-Process $Edge -ArgumentList @("--remote-debugging-address=127.0.0.1","--remote-debugging-port=9223","--user-data-dir=$EdgeProf","--disable-sync","--no-first-run","--no-default-browser-check",$TargetUrl)|Out-Null
if(-not(Wait-Cdp 9222)){throw "Chrome CDP not ready"};if(-not(Wait-Cdp 9223)){throw "Edge CDP not ready"}
$cg=Get-ControlledProcessGraph chrome 9222 $Chrome;$eg=Get-ControlledProcessGraph msedge 9223 $Edge;Write-Host "Chrome root=$($cg.RootPID) members=$($cg.Members.Count)";Write-Host "Edge root=$($eg.RootPID) members=$($eg.Members.Count)"
# Run collectors concurrently as background jobs; functions are loaded inside each job.
$sj=Start-Job -ArgumentList $OutDir,$sf,$Duration,$Chrome,$Edge -ScriptBlock {param($d,$f,$sec,$ch,$ed);. "$d\ProcessGraph.ps1";. "$d\SocketSensor.ps1";$a=Get-ControlledProcessGraph chrome 9222 $ch;$b=Get-ControlledProcessGraph msedge 9223 $ed;Start-SocketSensor -Graphs @($a,$b) -OutFile $f -Seconds $sec|Out-Null}
$cj=Start-Job -ArgumentList $OutDir,$cc,$Duration -ScriptBlock {param($d,$f,$sec);. "$d\CdpSensor.ps1";Invoke-CdpCapture 9222 $f chrome $sec}
$ej=Start-Job -ArgumentList $OutDir,$ec,$Duration -ScriptBlock {param($d,$f,$sec);. "$d\CdpSensor.ps1";Invoke-CdpCapture 9223 $f edge $sec}
Wait-Job $sj,$cj,$ej|Out-Null;Receive-Job $cj,$ej|Out-Host;Remove-Job $sj,$cj,$ej
$cr=@(Invoke-Correlate $cc $sf $cg chrome);$er=@(Invoke-Correlate $ec $sf $eg edge)
function Summary($r){if(-not $r -or $r.Count -eq 0){return "UNKNOWN"};if(@($r|Where-Object Verdict -eq SINGLE).Count -eq 0){return "UNKNOWN"};if(@($r|Where-Object Verdict -eq CONTRADICTION).Count){return "MIXED"};"CONSISTENT"}
$cs=Summary $cr;$es=Summary $er
Write-Host "=== Chrome observations ===" -ForegroundColor Cyan;$cr|Select-Object Status,Host,RemoteIP,RemotePort,Verdict,CandidateCount,@{N="LocalPorts";E={$_.CandidateLocalPorts -join ","}}|Format-Table -AutoSize
Write-Host "=== Edge observations ===" -ForegroundColor Cyan;$er|Select-Object Status,Host,RemoteIP,RemotePort,Verdict,CandidateCount,@{N="LocalPorts";E={$_.CandidateLocalPorts -join ","}}|Format-Table -AutoSize
Write-Host "=== Summary (not PASS/FAIL) ===" -ForegroundColor Cyan;Write-Host "Chrome: $cs";Write-Host "Edge  : $es";Write-Host "SINGLE = consistent with one observed family socket; not causal proof." -ForegroundColor Yellow
[ordered]@{version="3.2";timestamp=(Get-Date).ToUniversalTime().ToString("o");principle="Attributes requests to process families, not causally to specific TCP connections.";chrome_summary=$cs;edge_summary=$es;chrome_root=$cg.RootPID;edge_root=$eg.RootPID;chrome_rows=$cr;edge_rows=$er}|ConvertTo-Json -Depth 10|Set-Content $rf -Encoding UTF8;Write-Host "Report: $rf" -ForegroundColor Yellow
