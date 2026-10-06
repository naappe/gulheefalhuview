param([int]$Port = 9333)

$listener = [System.Net.HttpListener]::new()
$listener.Prefixes.Add("http://127.0.0.1:$Port/")
$listener.Start()
Write-Host "Fake DevTools listening on http://127.0.0.1:$Port/ (Ctrl+C to stop)" -ForegroundColor Cyan

try {
    while ($listener.IsListening) {
        $ctx = $listener.GetContext()
        $path = $ctx.Request.Url.AbsolutePath

        if ($path -in @("/json","/json/list")) {
            $body = @(@{
                id = "fake-tab-1"
                type = "page"
                title = "MachineObserver synthetic target"
                url = "https://example.test/"
                webSocketDebuggerUrl = "ws://127.0.0.1:$Port/ws"
            }) | ConvertTo-Json -Depth 6 -Compress
            $bytes = [Text.Encoding]::UTF8.GetBytes($body)
            $ctx.Response.ContentType = "application/json"
            $ctx.Response.ContentLength64 = $bytes.Length
            $ctx.Response.OutputStream.Write($bytes,0,$bytes.Length)
            $ctx.Response.Close()
            continue
        }

        if ($path -eq "/ws" -and $ctx.Request.IsWebSocketRequest) {
            $wsCtx = $ctx.AcceptWebSocketAsync($null).Result
            $sock = $wsCtx.WebSocket

            for ($i=0; $i -lt 20; $i++) {
                $evt = @{
                    method = "Network.responseReceived"
                    params = @{
                        requestId = "synthetic-r$i"
                        response = @{
                            url = "https://example.test/static/fake$i.js"
                            status = 200
                            mimeType = "text/javascript"
                            remoteIPAddress = "203.0.113.10"
                            remotePort = 443
                            protocol = "h2"
                            securityDetails = @{
                                protocol = "TLS 1.3"
                                cipher = "AES_128_GCM"
                                subjectName = "example.test"
                                issuer = "MachineObserver synthetic test"
                            }
                        }
                    }
                } | ConvertTo-Json -Compress -Depth 10

                $msg = [Text.Encoding]::UTF8.GetBytes($evt)
                $seg = [ArraySegment[byte]]::new($msg)
                $sock.SendAsync($seg,[System.Net.WebSockets.WebSocketMessageType]::Text,$true,[Threading.CancellationToken]::None).Wait()
                Start-Sleep -Milliseconds 500
            }

            $sock.CloseAsync([System.Net.WebSockets.WebSocketCloseStatus]::NormalClosure,"done",[Threading.CancellationToken]::None).Wait()
            continue
        }

        $ctx.Response.StatusCode = 404
        $ctx.Response.Close()
    }
}
finally {
    $listener.Stop()
    $listener.Close()
}
