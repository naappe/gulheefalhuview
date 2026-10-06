# Joins browser-side CDP records with socket-side records and produces a
# per-request verdict with full family attribution.

function Invoke-Correlate {
    param(
        [string]$CdpFile,
        [string]$SocketFile,
        [hashtable]$FamilyPIDs,   # PID -> { Name, Role, RootPID, Family }
        [string]$BrowserName,
        [string]$OutFile
    )

    $cdp = @()
    if (Test-Path $CdpFile) {
        $cdp = Get-Content $CdpFile |
            ForEach-Object { try { $_ | ConvertFrom-Json } catch {} } |
            Where-Object { $_ -and $_.remoteIP -and $_.remoteIP -ne '-' }
    }

    $sock = @()
    if (Test-Path $SocketFile) {
        $sock = Get-Content $SocketFile |
            ForEach-Object { try { $_ | ConvertFrom-Json } catch {} } |
            Where-Object { $_ }
    }

    $rows = foreach ($r in $cdp) {
        # candidate sockets: same remote IP and port
        $candidates = $sock | Where-Object {
            $_.remoteAddr -eq $r.remoteIP -and $_.remotePort -eq $r.remotePort
        }
        $verdict = 'NO_SOCKET'
        $ownerPID = $null
        $ownerRole = $null
        $ownerName = $null
        $localPort = $null

        if ($candidates.Count -eq 1) {
            $verdict  = 'SINGLE'
            $c        = $candidates[0]
            $ownerPID = $c.pid
            $ownerRole= $c.role
            $ownerName= $c.procName
            $localPort= $c.localPort
        } elseif ($candidates.Count -gt 1) {
            $verdict  = 'AMBIGUOUS'
            $c        = $candidates | Select-Object -First 1
            $ownerPID = $c.pid
            $ownerRole= $c.role
            $ownerName= $c.procName
            $localPort= $c.localPort
        }

        [pscustomobject]@{
            Browser     = $BrowserName
            Host        = $r.host
            Path        = $r.url
            Status      = $r.status
            RemoteIP    = $r.remoteIP
            RemotePort  = $r.remotePort
            Verdict     = $verdict
            OwnerPID    = $ownerPID
            OwnerRole   = $ownerRole
            OwnerName   = $ownerName
            LocalPort   = $localPort
            Candidates  = $candidates.Count
            EvidenceClass = $r.evidenceClass
            PayloadKind   = $r.payloadKind
            AppJson       = $r.appJson
        }
    }

    if ($OutFile) {
        $rows | ConvertTo-Json -Depth 6 | Set-Content -Path $OutFile -Encoding UTF8
    }
    return $rows
}
