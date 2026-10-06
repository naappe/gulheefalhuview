# MachineObserver PageStateObserver V0.1
# Read-only page structure sensor. It never reads input values, cookies, headers, bodies, or storage values.
function Get-PageState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][int]$Port,
        [Parameter(Mandatory)][string]$TargetHost
    )

    $targets=@(Invoke-RestMethod ("http://127.0.0.1:"+$Port+"/json/list") -TimeoutSec 2)
    $page=$null
    foreach($t in $targets){
        if([string]$t.type -ne "page"){continue}
        try{$h=([Uri]([string]$t.url)).DnsSafeHost.ToLowerInvariant()}catch{continue}
        if($h -eq $TargetHost.ToLowerInvariant()){$page=$t;break}
    }
    if(-not $page){throw "No matching page target for $TargetHost"}

    $ws=[Net.WebSockets.ClientWebSocket]::new()
    try{
        $null=$ws.ConnectAsync([Uri]([string]$page.webSocketDebuggerUrl),[Threading.CancellationToken]::None).GetAwaiter().GetResult()

        $expression=@'
(()=>JSON.stringify({
  url: location.origin + location.pathname,
  readyState: document.readyState,
  formCount: document.forms.length,
  inputCount: document.querySelectorAll("input").length,
  passwordFieldPresent: document.querySelectorAll('input[type="password"]').length > 0,
  submitControlPresent: document.querySelectorAll('button[type="submit"],input[type="submit"]').length > 0
}))()
'@
        $msg=@{id=8101;method="Runtime.evaluate";params=@{expression=$expression;returnByValue=$true}}|ConvertTo-Json -Compress -Depth 6
        $bytes=[Text.Encoding]::UTF8.GetBytes($msg)
        $null=$ws.SendAsync([ArraySegment[byte]]::new($bytes),[Net.WebSockets.WebSocketMessageType]::Text,$true,[Threading.CancellationToken]::None).GetAwaiter().GetResult()

        $buf=New-Object byte[] 65536
        while($true){
            $ms=[IO.MemoryStream]::new()
            try{
                do{
                    $res=$ws.ReceiveAsync([ArraySegment[byte]]::new($buf),[Threading.CancellationToken]::None).GetAwaiter().GetResult()
                    if($res.MessageType -eq [Net.WebSockets.WebSocketMessageType]::Close){throw "CDP socket closed"}
                    if($res.Count){$ms.Write($buf,0,$res.Count)}
                }while(-not $res.EndOfMessage)
                $obj=([Text.Encoding]::UTF8.GetString($ms.ToArray())|ConvertFrom-Json)
                if($obj.id -ne 8101){continue}
                $s=([string]$obj.result.result.value|ConvertFrom-Json)
                return [pscustomobject][ordered]@{
                    timestamp=(Get-Date).ToUniversalTime().ToString("o")
                    targetHost=$TargetHost
                    url=[string]$s.url
                    readyState=[string]$s.readyState
                    formCount=[int]$s.formCount
                    inputCount=[int]$s.inputCount
                    passwordFieldPresent=[bool]$s.passwordFieldPresent
                    submitControlPresent=[bool]$s.submitControlPresent
                    inputValuesCaptured=$false
                    cookieDataCaptured=$false
                    storageValuesCaptured=$false
                    stateClassification="OBSERVED_PAGE_STRUCTURE"
                    validationState="UNKNOWN"
                }
            }finally{$ms.Dispose()}
        }
    }finally{try{$ws.Dispose()}catch{}}
}
