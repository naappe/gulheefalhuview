# MachineObserver V3.2.4 CDP metadata sensor - locked-target capable.
# Privacy: no headers, cookies, request/response bodies, storage values, query strings, or fragments.
function ConvertTo-RedactedUrl {
    param([string]$Url)
    try {
        $u = [Uri]$Url
        $b = [UriBuilder]::new($u)
        $b.Query = ""
        $b.Fragment = ""
        return $b.Uri.AbsoluteUri
    }
    catch { return $Url }
}

function Get-CdpTargets {
    param([Parameter(Mandatory)][int]$Port)

    $raw = Invoke-RestMethod ("http://127.0.0.1:" + $Port + "/json/list") -TimeoutSec 2 -ErrorAction Stop
    $items = New-Object System.Collections.Generic.List[object]

    if ($raw -is [System.Array]) {
        foreach ($item in $raw) { $items.Add($item) }
    }
    else {
        $items.Add($raw)
    }

    return $items.ToArray()
}

function Select-CdpPageTarget {
    param(
        [Parameter(Mandatory)][object[]]$Targets,
        [string]$TargetHost = "",
        [string]$TargetId = "",
        [string]$WebSocketDebuggerUrl = "",
        [string]$TargetUrl = ""
    )

    $wanted = $TargetHost.Trim().ToLowerInvariant()

    foreach ($candidate in $Targets) {
        if ([string]$candidate.type -ne "page") { continue }

        $candidateUrl = [string]$candidate.url
        try {
            $candidateHost = ([Uri]$candidateUrl).DnsSafeHost.ToLowerInvariant()
        }
        catch { continue }

        if ($wanted -and $candidateHost -ne $wanted) { continue }

        $id = [string]$candidate.id
        $ws = [string]$candidate.webSocketDebuggerUrl
        if ([string]::IsNullOrWhiteSpace($id)) { continue }
        if ([string]::IsNullOrWhiteSpace($ws)) { continue }

        return $candidate
    }

    return $null
}

function Invoke-CdpCapture {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][int]$Port,
        [Parameter(Mandatory)][string]$OutFile,
        [Parameter(Mandatory)][string]$Label,
        [int]$Seconds = 60,
        [string]$TargetHost = ""
    )

    if (Test-Path $OutFile) { Remove-Item $OutFile -Force }

    $deadline = (Get-Date).AddSeconds($Seconds)
    $page = $null
    $lastDiscoveryError = $null
    $targetId = $TargetId
    $targetUrl = $TargetUrl
    $wsUrl = $WebSocketDebuggerUrl

    if ([string]::IsNullOrWhiteSpace($wsUrl)) {
        while (($null -eq $page) -and ((Get-Date) -lt $deadline)) {
            try {
                $targets = @(Get-CdpTargets -Port $Port)
                $page = Select-CdpPageTarget -Targets $targets -TargetHost $TargetHost
            }
            catch { $lastDiscoveryError = $_.Exception.Message }
            if ($null -eq $page) { Start-Sleep -Milliseconds 250 }
        }
        if ($null -eq $page) {
            if ($lastDiscoveryError) { throw "[$Label] no matching CDP page target on port $Port. Last discovery error: $lastDiscoveryError" }
            throw "[$Label] no matching CDP page target on port $Port for host '$TargetHost'"
        }
        $targetId = [string]$page.id
        $targetUrl = [string]$page.url
        $wsUrl = [string]$page.webSocketDebuggerUrl
    }
    elseif ([string]::IsNullOrWhiteSpace($targetId)) {
        throw "[$Label] TargetId required with WebSocketDebuggerUrl"
    }

    if ([string]::IsNullOrWhiteSpace($wsUrl)) {
        throw "[$Label] selected target '$targetId' has no WebSocket debugger URL"
    }

    Write-Host "[$Label] selected target=$targetId" -ForegroundColor Cyan
    Write-Host "[$Label] selected URL=$(ConvertTo-RedactedUrl $targetUrl)" -ForegroundColor DarkCyan

    $ws = [Net.WebSockets.ClientWebSocket]::new()
    $connectCts = [Threading.CancellationTokenSource]::new()

    try {
        $connectCts.CancelAfter(5000)
        $null = $ws.ConnectAsync([Uri]$wsUrl, $connectCts.Token).GetAwaiter().GetResult()
    }
    catch {
        $message = $_.Exception.Message
        try { $ws.Dispose() } catch {}
        throw "[$Label] CDP WebSocket connection failed for target '$targetId': $message"
    }
    finally {
        $connectCts.Dispose()
    }

    if ($ws.State -ne [Net.WebSockets.WebSocketState]::Open) {
        try { $ws.Dispose() } catch {}
        throw "[$Label] CDP WebSocket is not open. State=$($ws.State)"
    }

    try {
        $enableJson = @{ id = 1; method = "Network.enable" } | ConvertTo-Json -Compress
        $enableBytes = [Text.Encoding]::UTF8.GetBytes($enableJson)
        $null = $ws.SendAsync(
            [ArraySegment[byte]]::new($enableBytes),
            [Net.WebSockets.WebSocketMessageType]::Text,
            $true,
            [Threading.CancellationToken]::None
        ).GetAwaiter().GetResult()

        Write-Host "[$Label] attached target=$targetId $(ConvertTo-RedactedUrl $targetUrl)" -ForegroundColor Green

        $buf = New-Object byte[] 65536
        $count = 0

        while (((Get-Date) -lt $deadline) -and ($ws.State -eq [Net.WebSockets.WebSocketState]::Open)) {
            $remain = [int][Math]::Max(1, ($deadline - (Get-Date)).TotalMilliseconds)
            $receiveCts = [Threading.CancellationTokenSource]::new()
            $receiveCts.CancelAfter($remain)
            $ms = [IO.MemoryStream]::new()
            $cancelled = $false
            $res = $null

            try {
                do {
                    $res = $ws.ReceiveAsync(
                        [ArraySegment[byte]]::new($buf),
                        $receiveCts.Token
                    ).GetAwaiter().GetResult()

                    if ($res.MessageType -eq [Net.WebSockets.WebSocketMessageType]::Close) { break }
                    if ($res.Count -gt 0) { $ms.Write($buf, 0, $res.Count) }
                    if ($ms.Length -gt 4194304) { throw "CDP message >4MiB" }
                } while (-not $res.EndOfMessage)
            }
            catch [OperationCanceledException] {
                $cancelled = $true
            }
            finally {
                $receiveCts.Dispose()
            }

            if ($cancelled) {
                $ms.Dispose()
                break
            }

            if (($null -eq $res) -or ($res.MessageType -eq [Net.WebSockets.WebSocketMessageType]::Close)) {
                $ms.Dispose()
                break
            }

            $obj = $null
            try {
                $json = [Text.Encoding]::UTF8.GetString($ms.ToArray())
                $obj = $json | ConvertFrom-Json
            }
            catch {}
            finally {
                $ms.Dispose()
            }

            if (($null -eq $obj) -or ($obj.method -ne "Network.responseReceived")) { continue }

            $p = $obj.params
            $resp = $p.response
            if (-not $resp.remoteIPAddress) { continue }

            $url = ConvertTo-RedactedUrl ([string]$resp.url)
            $hostName = "-"
            try { $hostName = ([Uri]([string]$resp.url)).DnsSafeHost } catch {}

            $rec = [ordered]@{
                timestamp = (Get-Date).ToUniversalTime().ToString("o")
                source = $Label
                debugPort = $Port
                targetId = $targetId
                targetUrl = ConvertTo-RedactedUrl $targetUrl
                requestId = [string]$p.requestId
                resourceType = [string]$p.type
                url = $url
                host = $hostName
                status = $resp.status
                mimeType = [string]$resp.mimeType
                protocol = [string]$resp.protocol
                remoteIP = [string]$resp.remoteIPAddress
                remotePort = [int]$resp.remotePort
                evidenceClass = "OBSERVED_BROWSER"
                capturePolicy = "METADATA_ONLY"
            }

            ($rec | ConvertTo-Json -Compress) | Add-Content $OutFile -Encoding UTF8
            $count++
            Write-Host "[$Label] $($resp.status) $($resp.remoteIPAddress):$($resp.remotePort) $url"
        }
    }
    finally {
        try { $ws.Dispose() } catch {}
        Write-Host "[$Label] capture ended. events=$count" -ForegroundColor DarkGray
    }
}
