# MachineObserver V3.2.2 CDP metadata sensor. No headers/cookies/bodies; query/fragment removed.
function ConvertTo-RedactedUrl {
 param([string]$Url)
 try { $u=[Uri]$Url; $b=[UriBuilder]::new($u); $b.Query=""; $b.Fragment=""; return $b.Uri.AbsoluteUri } catch { return $Url }
}
function Invoke-CdpCapture {
 [CmdletBinding()]param([Parameter(Mandatory)][int]$Port,[Parameter(Mandatory)][string]$OutFile,[Parameter(Mandatory)][string]$Label,[int]$Seconds=60)
 if(Test-Path $OutFile){Remove-Item $OutFile -Force}
 $deadline=(Get-Date).AddSeconds($Seconds); $page=$null
 while((-not $page) -and ((Get-Date) -lt $deadline)){
  try { $targets=@(Invoke-RestMethod ("http://127.0.0.1:"+$Port+"/json/list") -TimeoutSec 2); $page=$targets|Where-Object {$_.type -eq "page"}|Select-Object -First 1 } catch {}
  if(-not $page){Start-Sleep -Milliseconds 250}
 }
 if(-not $page){throw "[$Label] no CDP page target on $Port"}
 $ws=[Net.WebSockets.ClientWebSocket]::new()
 $connectCts=[Threading.CancellationTokenSource]::new()
 $connectCts.CancelAfter(5000)
 try { $ws.ConnectAsync([Uri]$page.webSocketDebuggerUrl,$connectCts.Token).GetAwaiter().GetResult() } finally { $connectCts.Dispose() }
 $enableBytes=[Text.Encoding]::UTF8.GetBytes((@{id=1;method="Network.enable"}|ConvertTo-Json -Compress))
 $null=$ws.SendAsync([ArraySegment[byte]]::new($enableBytes),[Net.WebSockets.WebSocketMessageType]::Text,$true,[Threading.CancellationToken]::None).GetAwaiter().GetResult()
 Write-Host "[$Label] attached target=$($page.id) $($page.url)" -ForegroundColor Green
 $buf=New-Object byte[] 65536; $count=0
 try {
  while(((Get-Date) -lt $deadline) -and ($ws.State -eq [Net.WebSockets.WebSocketState]::Open)){
   $remain=[int][Math]::Max(1,($deadline-(Get-Date)).TotalMilliseconds)
   $receiveCts=[Threading.CancellationTokenSource]::new(); $receiveCts.CancelAfter($remain)
   $ms=[IO.MemoryStream]::new(); $cancelled=$false
   try {
    do {
     $res=$ws.ReceiveAsync([ArraySegment[byte]]::new($buf),$receiveCts.Token).GetAwaiter().GetResult()
     if($res.MessageType -eq [Net.WebSockets.WebSocketMessageType]::Close){break}
     if($res.Count -gt 0){$ms.Write($buf,0,$res.Count)}
     if($ms.Length -gt 4194304){throw "CDP message >4MiB"}
    } while(-not $res.EndOfMessage)
   } catch [OperationCanceledException] { $cancelled=$true } finally { $receiveCts.Dispose() }
   if($cancelled){$ms.Dispose();break}
   if($res.MessageType -eq [Net.WebSockets.WebSocketMessageType]::Close){$ms.Dispose();break}
   $obj=$null
   try { $obj=([Text.Encoding]::UTF8.GetString($ms.ToArray())|ConvertFrom-Json) } catch {}
   $ms.Dispose()
   if($null -eq $obj -or $obj.method -ne "Network.responseReceived"){continue}
   $p=$obj.params; $resp=$p.response
   if(-not $resp.remoteIPAddress){continue}
   $url=ConvertTo-RedactedUrl ([string]$resp.url)
   $hostName="-"; try { $hostName=([Uri]$resp.url).Host } catch {}
   $rec=[ordered]@{timestamp=(Get-Date).ToUniversalTime().ToString("o");source=$Label;debugPort=$Port;targetId=[string]$page.id;targetUrl=ConvertTo-RedactedUrl([string]$page.url);requestId=[string]$p.requestId;resourceType=[string]$p.type;url=$url;host=$hostName;status=$resp.status;mimeType=[string]$resp.mimeType;protocol=[string]$resp.protocol;remoteIP=[string]$resp.remoteIPAddress;remotePort=[int]$resp.remotePort;evidenceClass="OBSERVED_BROWSER";capturePolicy="METADATA_ONLY"}
   ($rec|ConvertTo-Json -Compress)|Add-Content $OutFile -Encoding UTF8
   $count++; Write-Host "[$Label] $($resp.status) $($resp.remoteIPAddress):$($resp.remotePort) $url"
  }
 } finally {
  try { $ws.Dispose() } catch {}
  Write-Host "[$Label] capture ended. events=$count" -ForegroundColor DarkGray
 }
}
