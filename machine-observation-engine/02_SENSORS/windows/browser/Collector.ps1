param(
    [string]$TargetUrl = "https://chat.deepseek.com/",
    [int]$Port         = 9222,
    [string]$OutFile   = "C:\MachineObserver\capture.jsonl",
    [string]$Chrome    = "C:\Program Files\Google\Chrome\Application\chrome.exe",
    [string]$Profile   = "$env:TEMP\mo-chrome-profile"
)
$ErrorActionPreference = "Stop"

function Get-HostClass {
    param([string]$HostName)
    switch -Wildcard ($HostName) {
        'fe-static.deepseek.com' { return 'static-cdn' }
        'chat.deepseek.com'      { return 'api-main' }
        'chat-dev.deepseek.com'  { return 'api-main-dev' }
        'hif-leim.deepseek.com'  { return 'hif-poller' }
        'hif-dliq.deepseek.com'  { return 'hif-poller' }
        'hif-test.deepseek.com'  { return 'hif-poller-test' }
        'apmplus.volces.com'     { return 'volc-apm' }
        'gator.volces.com'       { return 'volc-apm' }
        '*.volces.com'           { return 'volc-apm' }
        '*.volccdn.com'          { return 'volc-cdn' }
        '*.deepseek.com'         { return 'deepseek-other' }
        '*.cloudfront.net'       { return 'cloudfront' }
        '*.cdn-apple.com'          { return 'apple-auth' }
        '*.cloudflare.com'         { return 'turnstile' }
        '*.portal101.cn'           { return 'fingerprint' }
        default                  { return 'other' }
    }
}

function Get-ProcName {
    param([int]$ProcessId)
    if ($ProcessId -le 4) { return '(kernel/unknown)' }
    $proc = Get-Process -Id $ProcessId -ErrorAction SilentlyContinue
    if ($proc) { return $proc.ProcessName }
    return '(exited)'
}

Write-Host "[1/6] Starting Chrome on port $Port ..." -ForegroundColor Cyan
Start-Process $Chrome -ArgumentList @(
    "--remote-debugging-port=$Port",
    "--user-data-dir=$Profile",
    "--no-first-run",
    "--no-default-browser-check",
    $TargetUrl
) | Out-Null
Start-Sleep -Seconds 4

Write-Host "[2/6] Looking for a Chrome page target ..." -ForegroundColor Cyan
$targets = $null
for ($i = 0; $i -lt 10; $i++) {
    try { $targets = Invoke-RestMethod "http://127.0.0.1:$Port/json"; if ($targets) { break } }
    catch { Start-Sleep -Milliseconds 500 }
}
$page = $targets | Where-Object { $_.type -eq "page" } | Select-Object -First 1
if (-not $page) { Write-Host "No page target." -ForegroundColor Red; return }
Write-Host "      Attached to: $($page.url)" -ForegroundColor Green

Write-Host "[3/6] Connecting WebSocket ..." -ForegroundColor Cyan
$ws  = [System.Net.WebSockets.ClientWebSocket]::new()
$cts = [System.Threading.CancellationTokenSource]::new()
$ws.ConnectAsync([Uri]$page.webSocketDebuggerUrl, $cts.Token).Wait()

function Send-Cdp {
    param([hashtable]$Payload)
    $json  = $Payload | ConvertTo-Json -Compress -Depth 20
    $bytes = [Text.Encoding]::UTF8.GetBytes($json)
    $seg   = [ArraySegment[byte]]::new($bytes)
    $ws.SendAsync($seg, [System.Net.WebSockets.WebSocketMessageType]::Text, $true, $cts.Token).Wait()
}

Write-Host "[4/6] Enabling domains ..." -ForegroundColor Cyan
Send-Cdp @{ id = 1; method = "Network.enable" }
Send-Cdp @{ id = 2; method = "Page.enable" }
Send-Cdp @{ id = 3; method = "Runtime.enable" }

$OutDir = Split-Path -Parent $OutFile
if ($OutDir -and -not (Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir -Force | Out-Null }
if (Test-Path $OutFile) { Remove-Item $OutFile -Force }

Write-Host "[5/6] Writing log to: $OutFile" -ForegroundColor Cyan
Write-Host "[6/6] Capturing. Press Ctrl+C to stop." -ForegroundColor Yellow
Write-Host ""
Write-Host ("{0,-4} {1,-16} {2,-22} {3,-16} {4}" -f "ST","CLASS","TYPE","IP","URL") -ForegroundColor DarkYellow
Write-Host ("-" * 120) -ForegroundColor DarkGray

$buffer = New-Object byte[] 1048576
$inflight = @{}
$counter = 0
$classCounts = @{}
$pidCache = @{}

try {
    while ($ws.State -eq "Open") {
        $seg = [ArraySegment[byte]]::new($buffer)
        $res = $ws.ReceiveAsync($seg, $cts.Token).Result
        if ($res.Count -eq 0) { continue }

        $msg = [Text.Encoding]::UTF8.GetString($buffer, 0, $res.Count)
        try { $obj = $msg | ConvertFrom-Json } catch { continue }
        if (-not $obj.method) { continue }

        switch ($obj.method) {
            "Network.requestWillBeSent" {
                $r = $obj.params.request
                $inflight[$obj.params.requestId] = [pscustomobject]@{
                    Method = $r.method
                    Url = $r.url
                    Started = (Get-Date).ToString("o")
                }
            }
            "Network.responseReceived" {
                $p = $obj.params
                $resp = $p.response
                $req = $inflight[$p.requestId]
                $hostName = try { ([Uri]$resp.url).Host } catch { "-" }
                $path = try { ([Uri]$resp.url).AbsolutePath } catch { "-" }
                $class = [string](Get-HostClass -HostName $hostName)
                $ip = if ($resp.remoteIPAddress) { [string]$resp.remoteIPAddress } else { "-" }
                $pidForIp = $null
                if ($ip -ne "-") {
                    if (-not $pidCache.ContainsKey($ip)) {
                        $conn = Get-NetTCPConnection -RemoteAddress $ip -State Established -ErrorAction SilentlyContinue |
                                Sort-Object CreationTime -Descending | Select-Object -First 1
                        $pidCache[$ip] = if ($conn) { $conn.OwningProcess } else { $null }
                    }
                    $pidForIp = $pidCache[$ip]
                }
                $procName = if ($pidForIp) { Get-ProcName -ProcessId $pidForIp } else { "(unknown)" }
                $sec = $resp.securityDetails

                Write-Host ("{0,-4} {1,-16} {2,-22} {3,-16} {4}" -f $resp.status,$class,$resp.mimeType,$ip,$resp.url)

                if (-not $classCounts.ContainsKey($class)) { $classCounts[$class] = [int]0 }
                $classCounts[$class] = [int]$classCounts[$class] + 1

                $record = [ordered]@{
                    timestamp = (Get-Date).ToString("o")
                    sensor = "browser-cdp"
                    method = if ($req) { $req.Method } else { "-" }
                    class = $class
                    url = $resp.url
                    host = $hostName
                    path = $path
                    status = $resp.status
                    mimeType = $resp.mimeType
                    remoteIP = $ip
                    remotePort = $resp.remotePort
                    chromePID = $pidForIp
                    procName = $procName
                    resourceKey = ("{0}|{1}|{2}|{3}|{4}" -f (if ($req) { $req.Method } else { "-" }), $resp.url, $resp.status, $ip, $resp.remotePort)
                    protocol = $resp.protocol
                    fromCache = $resp.fromDiskCache
                    fromSW = $resp.fromServiceWorker
                    encodedLength = $resp.encodedDataLength
                    tls = if ($sec) {
                        [ordered]@{
                            protocol = $sec.protocol
                            cipher = $sec.cipher
                            keyGroup = $sec.keyExchangeGroup
                            subject = $sec.subjectName
                            issuer = $sec.issuer
                        }
                    } else { $null }
                }
                ($record | ConvertTo-Json -Compress -Depth 8) | Add-Content -Path $OutFile -Encoding UTF8
                $counter++
            }
            "Network.loadingFinished" {
                $inflight.Remove($obj.params.requestId) | Out-Null
            }
        }
    }
}
finally {
    Write-Host ""
    Write-Host ("=" * 60) -ForegroundColor DarkGray
    Write-Host "Capture stopped. $counter responses recorded." -ForegroundColor Yellow
    Write-Host "Responses by class:" -ForegroundColor Cyan
    $classCounts.GetEnumerator() | Sort-Object Value -Descending | ForEach-Object {
        Write-Host ("  {0,-20} {1,6}" -f $_.Key, $_.Value)
    }
    Write-Host "Log file: $OutFile" -ForegroundColor Yellow
    try { $ws.Dispose() } catch {}
    try { $cts.Dispose() } catch {}
}
