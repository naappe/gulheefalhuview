# Builds a PID -> { Name, Path, ParentPID, RootPID } map for Chrome and Edge.
# The "family" is determined by walking up to the topmost ancestor whose
# executable matches the browser.

function Get-ProcessGraph {
    param(
        [string]$BrowserName,          # 'chrome' or 'msedge'
        [string]$BrowserExePath        # full path to the browser executable
    )

    $all = @{}
    Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | ForEach-Object {
        $all[[int]$_.ProcessId] = [pscustomobject]@{
            PID        = [int]$_.ProcessId
            ParentPID  = [int]$_.ParentProcessId
            Name       = $_.Name
            ExePath    = $_.ExecutablePath
            CommandLine= $_.CommandLine
        }
    }

    # Root = the topmost ancestor whose name matches
    function Get-RootPID {
        param([int]$Pid)
        $cur = $Pid
        $seen = @{}
        while ($cur -gt 4 -and -not $seen.ContainsKey($cur)) {
            $seen[$cur] = $true
            $p = $all[$cur]
            if (-not $p) { break }
            if ($p.Name -ne $BrowserName) { break }
            $parent = $all[$p.ParentPID]
            if (-not $parent -or $parent.Name -ne $BrowserName) {
                return $cur
            }
            $cur = $p.ParentPID
        }
        return $cur
    }

    # Index every process whose name equals the browser
    $members = @{}
    foreach ($kv in $all.GetEnumerator()) {
        $p = $kv.Value
        if ($p.Name -ne $BrowserName) { continue }

        $rootPid = Get-RootPID -Pid $p.PID
        $role    = "worker"
        if ($p.PID -eq $rootPid) { $role = "root" }
        elseif ($p.CommandLine -match '--utility-sub-type=network\.mojom\.NetworkService') { $role = "network-service" }
        elseif ($p.CommandLine -match '--type=renderer')  { $role = "renderer"  }
        elseif ($p.CommandLine -match '--type=gpu')       { $role = "gpu"       }
        elseif ($p.CommandLine -match '--type=utility')   { $role = "utility"   }

        $members[$p.PID] = [pscustomobject]@{
            PID       = $p.PID
            Name      = $p.Name
            Role      = $role
            RootPID   = $rootPid
            Family    = $BrowserName
        }
    }

    return $members
}
