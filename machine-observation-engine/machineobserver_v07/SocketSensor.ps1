# Polls Get-NetTCPConnection and records every established TCP connection
# whose OwningProcess is in the browser family set.

function Start-SocketSensor {
    param(
        [hashtable]$FamilyPIDs,   # PID -> { Name, Role, RootPID, Family }
        [string]$OutFile,
        [int]$Seconds
    )

    if (Test-Path $OutFile) { Remove-Item $OutFile -Force }

    $seen = @{}
    $end  = (Get-Date).AddSeconds($Seconds)

    while ((Get-Date) -lt $end) {
        try {
            Get-NetTCPConnection -State Established -ErrorAction SilentlyContinue | ForEach-Object {
                $pid_ = [int]$_.OwningProcess
                if (-not $FamilyPIDs.ContainsKey($pid_)) { return }

                $key = "$pid_|$($_.LocalAddress):$($_.LocalPort)->$($_.RemoteAddress):$($_.RemotePort)"
                if ($seen.ContainsKey($key)) { return }
                $seen[$key] = $true

                $fam = $FamilyPIDs[$pid_]
                $rec = [ordered]@{
                    timestamp  = (Get-Date).ToString("o")
                    pid        = $pid_
                    procName   = $fam.Name
                    role       = $fam.Role
                    family     = $fam.Family
                    rootPID    = $fam.RootPID
                    localAddr  = $_.LocalAddress
                    localPort  = $_.LocalPort
                    remoteAddr = $_.RemoteAddress
                    remotePort = $_.RemotePort
                }
                ($rec | ConvertTo-Json -Compress) | Add-Content -Path $OutFile -Encoding UTF8
            }
        } catch { }
        Start-Sleep -Milliseconds 200
    }
}
