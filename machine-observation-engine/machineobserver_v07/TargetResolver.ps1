# MachineObserver TargetResolver V0.1
# Resolves one exact browser page node and returns a locked target identity.
Set-StrictMode -Version Latest

function Resolve-LockedTarget {
 [CmdletBinding()]param(
  [Parameter(Mandatory=$true)][int]$Port,
  [Parameter(Mandatory=$true)][string]$TargetHost,
  [int]$TimeoutSeconds=60
 )
 $wanted=$TargetHost.Trim().ToLowerInvariant()
 $deadline=(Get-Date).AddSeconds($TimeoutSeconds)
 $lastUrls=@()
 while((Get-Date)-lt $deadline){
  try{
   $raw=Invoke-RestMethod -Uri ("http://127.0.0.1:"+$Port+"/json/list") -TimeoutSec 2
   $targets=New-Object System.Collections.Generic.List[object]
   foreach($item in $raw){
    if($null -eq $item){continue}
    if($item -is [System.Array]){foreach($sub in $item){$targets.Add($sub)}}else{$targets.Add($item)}
   }
   $lastUrls=@()
   foreach($t in $targets){
    if($null -eq $t){continue}
    $type=[string]$t.type;$url=[string]$t.url
    if($type -eq "page"){$lastUrls+=,$url}else{continue}
    try{$uri=[Uri]$url;if(-not $uri.IsAbsoluteUri){continue};$hostName=$uri.DnsSafeHost.ToLowerInvariant()}catch{continue}
    if([string]::Equals($hostName,$wanted,[StringComparison]::OrdinalIgnoreCase)){
     $ws=[string]$t.webSocketDebuggerUrl
     if([string]::IsNullOrWhiteSpace($ws)){throw "Matching page target has no WebSocket debugger URL"}
     return [pscustomobject][ordered]@{
      targetId=[string]$t.id
      type=$type
      title=[string]$t.title
      url=($uri.GetLeftPart([UriPartial]::Path))
      host=$hostName
      debugPort=$Port
      webSocketDebuggerUrl=$ws
      targetMatch=$true
      resolvedAt=(Get-Date).ToUniversalTime().ToString("o")
      evidenceClass="OBSERVED_BROWSER"
     }
    }
   }
  }catch{}
  Start-Sleep -Milliseconds 250
 }
 $seen=if($lastUrls.Count){$lastUrls -join "; "}else{"<none>"}
 throw ("No exact page node for host '"+$wanted+"' on CDP port "+$Port+". Observed pages: "+$seen)
}
