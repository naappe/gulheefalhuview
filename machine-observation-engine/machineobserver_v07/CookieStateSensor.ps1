# MachineObserver CookieStateSensor V0.1
# Structural cookie observation only. Cookie values are never persisted or printed.
function Invoke-CdpCommand {
    param([Parameter(Mandatory)][Net.WebSockets.ClientWebSocket]$WebSocket,[Parameter(Mandatory)][int]$Id,[Parameter(Mandatory)][string]$Method,[hashtable]$Params=@{})
    $json=@{id=$Id;method=$Method;params=$Params}|ConvertTo-Json -Compress -Depth 8
    $bytes=[Text.Encoding]::UTF8.GetBytes($json)
    $null=$WebSocket.SendAsync([ArraySegment[byte]]::new($bytes),[Net.WebSockets.WebSocketMessageType]::Text,$true,[Threading.CancellationToken]::None).GetAwaiter().GetResult()
    $buf=New-Object byte[] 65536
    while($true){
        $ms=[IO.MemoryStream]::new()
        try{
            do{
                $res=$WebSocket.ReceiveAsync([ArraySegment[byte]]::new($buf),[Threading.CancellationToken]::None).GetAwaiter().GetResult()
                if($res.MessageType -eq [Net.WebSockets.WebSocketMessageType]::Close){throw "CDP socket closed"}
                if($res.Count){$ms.Write($buf,0,$res.Count)}
            }while(-not $res.EndOfMessage)
            $obj=([Text.Encoding]::UTF8.GetString($ms.ToArray())|ConvertFrom-Json)
            if($obj.id -eq $Id){return $obj}
        }finally{$ms.Dispose()}
    }
}
function Get-CookieStateSnapshot {
    [CmdletBinding()]param([Parameter(Mandatory)][int]$Port,[Parameter(Mandatory)][string]$TargetHost,[Parameter(Mandatory)][string]$Phase)
    $targets=@(Invoke-RestMethod ("http://127.0.0.1:"+$Port+"/json/list") -TimeoutSec 2)
    $page=$null
    foreach($t in $targets){
        if([string]$t.type -ne "page"){continue}
        try{$h=([Uri]([string]$t.url)).DnsSafeHost.ToLowerInvariant()}catch{continue}
        if($h -eq $TargetHost.ToLowerInvariant()){$page=$t;break}
    }
    if(-not $page){throw "No matching page for cookie-state snapshot: $TargetHost"}
    $ws=[Net.WebSockets.ClientWebSocket]::new()
    try{
        $null=$ws.ConnectAsync([Uri]([string]$page.webSocketDebuggerUrl),[Threading.CancellationToken]::None).GetAwaiter().GetResult()
        $r=Invoke-CdpCommand -WebSocket $ws -Id 7001 -Method "Network.getCookies" -Params @{urls=@([string]$page.url)}
        $cookies=@($r.result.cookies)
        $same=@{Strict=0;Lax=0;None=0;Unspecified=0}
        foreach($c in $cookies){
            $s=[string]$c.sameSite
            if($same.ContainsKey($s)){$same[$s]++}else{$same.Unspecified++}
        }
        [pscustomobject][ordered]@{
            timestamp=(Get-Date).ToUniversalTime().ToString("o")
            phase=$Phase
            targetHost=$TargetHost
            cookieCount=$cookies.Count
            secureCount=@($cookies|Where-Object{$_.secure -eq $true}).Count
            httpOnlyCount=@($cookies|Where-Object{$_.httpOnly -eq $true}).Count
            sessionCount=@($cookies|Where-Object{$_.session -eq $true}).Count
            persistentCount=@($cookies|Where-Object{$_.session -ne $true}).Count
            sameSite=[ordered]@{Strict=$same.Strict;Lax=$same.Lax;None=$same.None;Unspecified=$same.Unspecified}
            valuesCaptured=$false
            namesCaptured=$false
            capturePolicy="STRUCTURE_ONLY"
            evidenceClass="OBSERVED_BROWSER_STATE"
        }
    }finally{try{$ws.Dispose()}catch{}}
}
function Compare-CookieState {
    param([Parameter(Mandatory)]$Before,[Parameter(Mandatory)]$After)
    [pscustomobject][ordered]@{
        cookieCountDelta=([int]$After.cookieCount-[int]$Before.cookieCount)
        secureCountDelta=([int]$After.secureCount-[int]$Before.secureCount)
        httpOnlyCountDelta=([int]$After.httpOnlyCount-[int]$Before.httpOnlyCount)
        sessionCountDelta=([int]$After.sessionCount-[int]$Before.sessionCount)
        persistentCountDelta=([int]$After.persistentCount-[int]$Before.persistentCount)
        stateChanged=(
            [int]$After.cookieCount -ne [int]$Before.cookieCount -or
            [int]$After.secureCount -ne [int]$Before.secureCount -or
            [int]$After.httpOnlyCount -ne [int]$Before.httpOnlyCount -or
            [int]$After.sessionCount -ne [int]$Before.sessionCount
        )
        valuesCompared=$false
    }
}
