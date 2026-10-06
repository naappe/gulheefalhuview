# Attaches to a browser via CDP, records Network.responseReceived events.
# Handles: fragmented WebSocket frames, socket closure, target disappearance.

function Invoke-CdpCapture {
    [CmdletBinding()]
    param(
        [int]$Port,
        [string]$OutFile,
        [string]$Label,
        [int]$Seconds
    )

    $deadline = (Get-Date).AddSeconds($Seconds)
    $buffer   = New-Object byte[] 1048576

    if (Test-Path $OutFile) { Remove-Item $OutFile -Force }

    function Resolve-PageTarget {
        param([int]$P)
        for ($i = 0; $i -lt 40; $i++) {
            try {
                $t = Invoke-RestMethod "http://127.0.0.1:$P/json"
                $pg = $t | Where-Object { $_.type -eq "page" } | Select-Object -First 1
                if ($pg) { return $pg }
            } catch { }
            Start-Sleep -Milliseconds 500
        }
        return $null
    }

    function Connect-ToPage {
        param($Page, [string]$Lbl)
        $ws  = [System.Net.WebSockets.ClientWebSocket]::new()
        $cts = [System.Threading.CancellationTokenSource]::new()
        try {
            $ws.ConnectAsync([Uri]$Page.webSocketDebuggerUrl, $cts.Token).Wait()
        } catch {
            Write-Host "[$Lbl] connect failed: $_" -ForegroundColor Red
            try { $ws.Dispose() } catch { }
            try { $cts.Dispose() } catch { }
            return $null
        }
        $json  = @{ id = 1; method = "Network.enable" } | ConvertTo-Json -Compress
        $bytes = [Text.Encoding]::UTF8.GetBytes($json)
        $seg   = [ArraySegment[byte]]::new($bytes)
        try {
            $ws.SendAsync($seg, [System.Net.WebSockets.WebSocketMessageType]::Text, $true, $cts.Token).Wait()
        } catch {
            Write-Host "[$Lbl] Network.enable failed: $_" -ForegroundColor Red
            try { $ws.Dispose() } catch { }
            try { $cts.Dispose() } catch { }
            return $null
        }
        return [pscustomobject]@{ Ws = $ws; Cts = $cts }
    }

    function Disconnect-FromPage {
        param($Conn)
        if (-not $Conn) { return }
        try { $Conn.Ws.Dispose() } catch { }
        try { $Conn.Cts.Dispose() } catch { }
    }

    $page = Resolve-PageTarget -P $Port
    if (-not $page) {
        Write-Host "[$Label] no page target after retries" -ForegroundColor Red
        return
    }
    Write-Host "[$Label] attached to: $($page.url)" -ForegroundColor Green

    $conn = Connect-ToPage -Page $page -Lbl $Label
    if (-not $conn) { return }

    $eventCount = 0
    $reconnects = 0

    try {
        while ((Get-Date) -lt $deadline) {

            # If socket dropped, try one reconnect
            if ($conn.Ws.State -ne "Open") {
                Disconnect-FromPage -Conn $conn
                $page2 = Resolve-PageTarget -P $Port
                if (-not $page2) {
                    Write-Host "[$Label] target gone, stopping" -ForegroundColor DarkGray
                    break
                }
                $conn = Connect-ToPage -Page $page2 -Lbl $Label
                if (-not $conn) {
                    Write-Host "[$Label] reconnect failed, stopping" -ForegroundColor DarkGray
                    break
                }
                $reconnects++
                Write-Host "[$Label] reconnected (total $reconnects)" -ForegroundColor DarkCyan
                continue
            }

            $seg = [ArraySegment[byte]]::new($buffer)
            $res = $null
            try {
                $task = $conn.Ws.ReceiveAsync($seg, $conn.Cts.Token)
                if (-not $task.Wait(500)) { continue }
                $res = $task.Result
            } catch {
                # socket died - loop will reconnect on next iteration
                continue
            }
            if (-not $res -or $res.Count -eq 0) { continue }

            # ---- Fragmented message assembly ----
            $ms = New-Object System.IO.MemoryStream
            $ms.Write($buffer, 0, $res.Count)
            while (-not $res.EndOfMessage) {
                $seg2 = [ArraySegment[byte]]::new($buffer)
                try {
                    $task2 = $conn.Ws.ReceiveAsync($seg2, $conn.Cts.Token)
                    if (-not $task2.Wait(500)) { break }
                    $res = $task2.Result
                } catch { break }
                if (-not $res -or $res.Count -eq 0) { break }
                $ms.Write($buffer, 0, $res.Count)
            }
            $msg = [Text.Encoding]::UTF8.GetString($ms.ToArray())
            $ms.Dispose()

            try { $obj = $msg | ConvertFrom-Json } catch { continue }
            if (-not $obj.method) { continue }

            if ($obj.method -eq "Network.responseReceived") {
                $p    = $obj.params
                $resp = $p.response
                $ip   = $resp.remoteIPAddress
                if (-not $ip) { $ip = '-' }

                $hostName = '-'
                try { $hostName = ([Uri]$resp.url).Host } catch { }

                $rec = [ordered]@{
                    timestamp  = (Get-Date).ToString("o")
                    source     = $Label
                    url        = $resp.url
                    host       = $hostName
                    status     = $resp.status
                    mimeType   = $resp.mimeType
                    remoteIP   = $ip
                    remotePort = $resp.remotePort
                }
                ($rec | ConvertTo-Json -Compress) | Add-Content -Path $OutFile -Encoding UTF8
                $eventCount++
                Write-Host ("[{0}] {1,3} {2,-16} {3}" -f $Label, $resp.status, $ip, $resp.url) -ForegroundColor White
            }
        }
    } finally {
        Disconnect-FromPage -Conn $conn
        Write-Host "[$Label] capture ended. events=$eventCount reconnects=$reconnects" -ForegroundColor DarkGray
    }
}
