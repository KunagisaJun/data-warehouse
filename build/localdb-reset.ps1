param(
    [Parameter(Mandatory = $true)]
    [string]$InstanceName,

    [Parameter(Mandatory = $false)]
    [bool]$RecreateAndStart = $true
)

$ErrorActionPreference = "Stop"

# Ensure sqllocaldb exists
$exe = Get-Command sqllocaldb -ErrorAction Stop

function Kill-InstanceSqlservr([string]$inst) {
    # Kill sqlservr.exe processes hosting this LocalDB instance.
    # LocalDB sqlservr.exe command line contains: -s <InstanceName>
    $procs = Get-CimInstance Win32_Process -Filter "Name='sqlservr.exe'" -ErrorAction SilentlyContinue
    if (-not $procs) { return }

    $pattern = "\-s\s+$([regex]::Escape($inst))(\s|$)"
    foreach ($p in $procs) {
        if ($p.CommandLine -and ($p.CommandLine -match $pattern)) {
            try { Stop-Process -Id $p.ProcessId -Force -ErrorAction SilentlyContinue } catch {}
        }
    }
}

function Remove-InstanceFolder([string]$inst) {
    # LocalDB instance data lives here:
    # %LOCALAPPDATA%\Microsoft\Microsoft SQL Server Local DB\Instances\<InstanceName>\
    $root = Join-Path $env:LOCALAPPDATA "Microsoft\Microsoft SQL Server Local DB\Instances"
    $dir  = Join-Path $root $inst

    if (Test-Path -LiteralPath $dir) {
        try {
            # Take ownership-ish approach: clear read-only flags then delete
            Get-ChildItem -LiteralPath $dir -Recurse -Force -ErrorAction SilentlyContinue |
                ForEach-Object {
                    try { $_.Attributes = 'Normal' } catch {}
                }

            Remove-Item -LiteralPath $dir -Recurse -Force -ErrorAction SilentlyContinue
        } catch {
            # If it still fails, try once more after a short wait
            Start-Sleep -Milliseconds 300
            try { Remove-Item -LiteralPath $dir -Recurse -Force -ErrorAction SilentlyContinue } catch {}
        }
    }
}

function Invoke-BrutalReset([string]$inst, [bool]$startAfter) {
    # 1) Try stop -k (ignore failures)
    try { & sqllocaldb stop $inst -k 2>$null | Out-Null } catch {}

    # 2) Hard kill any remaining hosting processes
    Kill-InstanceSqlservr $inst

    # 3) Stop again after kill (ignore failures)
    try { & sqllocaldb stop $inst -k 2>$null | Out-Null } catch {}

    # 4) Delete instance (ignore failures)
    try { & sqllocaldb delete $inst 2>$null | Out-Null } catch {}

    # 5) Kill again (processes can linger briefly)
    Start-Sleep -Milliseconds 200
    Kill-InstanceSqlservr $inst

    # 6) Nuke instance folder (removes stale MDF/LDF like Staging_Primary.mdf)
    Remove-InstanceFolder $inst

    if ($startAfter) {
        # 7) Recreate + start
        & sqllocaldb create $inst | Out-Null
        & sqllocaldb start  $inst | Out-Null

        # 8) Verify Running (retry once after killing again)
        $info = & sqllocaldb info $inst 2>$null
        if (-not ($info -match "State:\s+Running")) {
            Kill-InstanceSqlservr $inst
            Start-Sleep -Milliseconds 200
            & sqllocaldb start $inst | Out-Null

            $info2 = & sqllocaldb info $inst 2>$null
            if (-not ($info2 -match "State:\s+Running")) {
                throw "LocalDB instance '$inst' did not reach Running state."
            }
        }
    }
}

Invoke-BrutalReset -inst $InstanceName -startAfter $RecreateAndStart
