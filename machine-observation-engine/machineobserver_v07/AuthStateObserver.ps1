# MachineObserver AuthStateObserver V0.1
# Read-only DOM state classification. Never reads input values or credentials.
function Get-AuthUiState {
    [CmdletBinding()]param([Parameter(Mandatory)][int]$Port,[Parameter(Mandatory)][string]$TargetHost)
    $targets=@(Invoke-RestMethod ("http://127.0.0.1:"+$Port+"/json/list") -TimeoutSec 2)
    $page=$null
    foreach($t in $targets){
        if([string]$t.type -ne "page"){continue}
        try{$h=([Uri]([string]$t.url)).DnsSafeHost.ToLowerInvariant()}catch{continue}
        if($h -eq $TargetHost.ToLowerInvariant()){$page=$t;break}
    }
    if(-not $page){throw "No matching page for auth-state observation: $TargetHost"}
    $ws=[Net.WebSockets.ClientWebSocket]::new()
    try{
        $null=$ws.ConnectAsync([Uri]([string]$page.webSocketDebuggerUrl),[Threading.CancellationToken]::None).GetAwaiter().GetResult()
        . "$PSScriptRoot\CookieStateSensor.ps1"
        $expr=@'
(()=>{const q=s=>Array.from(document.querySelectorAll(s));const forms=q("form");const pw=q('input[type="password"]');const user=q('input[type="text"],input[type="email"],input[type="tel"]');const submit=q('button[type="submit"],input[type="submit"]');return JSON.stringify({url:location.origin+location.pathname,ready:document.readyState,formCount:forms.length,passwordFieldCount:pw.length,identityFieldCount:user.length,submitControlCount:submit.length});})()
'@
        $r=Invoke-CdpCommand -WebSocket $ws -Id 7101 -Method "Runtime.evaluate" -Params @{expression=$expr;returnByValue=$true}
        $state=([string]$r.result.result.value|ConvertFrom-Json)
        [pscustomobject][ordered]@{
            timestamp=(Get-Date).ToUniversalTime().ToString("o")
            targetHost=$TargetHost
            url=[string]$state.url
            readyState=[string]$state.ready
            formCount=[int]$state.formCount
            identityFieldPresent=([int]$state.identityFieldCount -gt 0)
            passwordFieldPresent=([int]$state.passwordFieldCount -gt 0)
            submitControlPresent=([int]$state.submitControlCount -gt 0)
            inputValueCaptured=$false
            validationState="UNKNOWN"
            authSuccess="UNKNOWN"
            authFailure="UNKNOWN"
            evidenceClass="OBSERVED_BROWSER_UI"
            capturePolicy="STRUCTURE_ONLY"
        }
    }finally{try{$ws.Dispose()}catch{}}
}
