param(
  [Parameter(Mandatory = $true)]
  [string]$Config,

  [Parameter(Mandatory = $false)]
  [bool]$RunTests = $true
)

$ErrorActionPreference = "Stop"

# -------------------------
# Resolve repo + config
# -------------------------
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

$configPath = Join-Path $repoRoot $Config
if (-not (Test-Path -LiteralPath $configPath)) { throw "Config not found: $configPath" }

$cfg = Get-Content -Raw -LiteralPath $configPath | ConvertFrom-Json

Write-Host "=== deploy.ps1 ==="
Write-Host ("repoRoot: {0}" -f $repoRoot)
Write-Host ("configPath: {0}" -f $configPath)

# -------------------------
# Required config
# -------------------------
if (-not $cfg.server) { throw "Config missing: server" }
if (-not $cfg.databases) { throw "Config missing: databases" }
foreach ($k in @("Staging","ODS","DWH","ETL")) {
  if (-not $cfg.databases.$k) { throw "Config missing: databases.$k" }
}

Write-Host ("server: {0}" -f $cfg.server)
Write-Host ("databases: Staging={0}, ODS={1}, DWH={2}, ETL={3}" -f $cfg.databases.Staging, $cfg.databases.ODS, $cfg.databases.DWH, $cfg.databases.ETL)

# LocalDB-only MVP
if ($cfg.server -ne "(localdb)\MSSQLLocalDB") {
  throw "This MVP deploy.ps1 supports only '(localdb)\MSSQLLocalDB'. Got: $($cfg.server)"
}

# -------------------------
# Tools + paths
# -------------------------
$msbuild = Get-ChildItem -LiteralPath "C:\Program Files\Microsoft Visual Studio" -Recurse -Filter "MSBuild.exe" -File |
  Sort-Object FullName -Descending |
  Select-Object -First 1 -ExpandProperty FullName
if (-not $msbuild) { throw "MSBuild.exe not found under Visual Studio install." }

$sqlpackage = (Get-Command sqlpackage -ErrorAction Stop).Source
$sqlcmdExe  = (Get-Command sqlcmd -ErrorAction Stop).Source

$solution = Join-Path $repoRoot "data-warehouse.slnx"
if (-not (Test-Path -LiteralPath $solution)) { throw "Solution not found: $solution" }

$resetScript = Join-Path $repoRoot "build\localdb-reset.ps1"
if (-not (Test-Path -LiteralPath $resetScript)) { throw "Reset script not found: $resetScript" }

Write-Host ("msbuild: {0}" -f $msbuild)
Write-Host ("sqlpackage: {0}" -f $sqlpackage)
Write-Host ("sqlcmd: {0}" -f $sqlcmdExe)
Write-Host ("solution: {0}" -f $solution)
Write-Host ("resetScript: {0}" -f $resetScript)

# -------------------------
# Helpers
# -------------------------
function Get-DacpacPath([string]$name) {
  $p = Join-Path $repoRoot "$name\bin\Debug\$name.dacpac"
  if (-not (Test-Path -LiteralPath $p)) { throw "Missing dacpac: $p" }
  return $p
}

function Publish-Dacpac([string]$proj, [string]$db, [hashtable]$vars) {
  $dacpac = Get-DacpacPath $proj

  Write-Host ""
  Write-Host ("--- Publish: {0} -> {1} ---" -f $proj, $db)
  Write-Host ("dacpac: {0}" -f $dacpac)

  $args = @(
    "/Action:Publish",
    "/SourceFile:$dacpac",
    "/TargetServerName:$($cfg.server)",
    "/TargetDatabaseName:$db",
    "/p:BlockOnPossibleDataLoss=False",
    "/p:DropObjectsNotInSource=False"
  )

  if ($vars -and $vars.Count -gt 0) {
    Write-Host "sqlpackage vars:"
    foreach ($k in ($vars.Keys | Sort-Object)) {
      Write-Host ("  {0} = [{1}]" -f $k, $vars[$k])
      $args += "/v:$k=$($vars[$k])"
    }
  } else {
    Write-Host "sqlpackage vars: (none)"
  }

  Write-Host "sqlpackage argv:"
  for ($i=0; $i -lt $args.Count; $i++) {
    Write-Host ("  [{0}] {1}" -f $i, $args[$i])
  }

  & $sqlpackage @args
  if ($LASTEXITCODE -ne 0) { throw "Publish failed: $proj -> $db" }
}

function Invoke-SqlCmdFile([string]$database, [string]$file) {
  if (-not (Test-Path -LiteralPath $file)) { throw "SQL file not found: $file" }

  $args = @("-S", $cfg.server, "-d", $database, "-b", "-i", $file)

  Write-Host ""
  Write-Host ("--- sqlcmd: db={0} file={1} ---" -f $database, $file)
  Write-Host ("sqlcmd exe: {0}" -f $sqlcmdExe)
  Write-Host ("pwd: {0}" -f (Get-Location).Path)

  Write-Host "sqlcmd argv tokens:"
  for ($i=0; $i -lt $args.Count; $i++) {
    Write-Host ("  [{0}] {1}" -f $i, $args[$i])
  }

  # -------------------------
  # SURGICAL CHANGE:
  # Capture stdout/stderr so we can reliably show SQL errors.
  # -------------------------
  $psi = New-Object System.Diagnostics.ProcessStartInfo
  $psi.FileName = $sqlcmdExe
  $psi.Arguments = ($args | ForEach-Object {
    # Preserve simple quoting for args with spaces
    if ($_ -match '\s') { '"' + $_.Replace('"','\"') + '"' } else { $_ }
  }) -join ' '
  $psi.WorkingDirectory = (Get-Location).Path
  $psi.UseShellExecute = $false
  $psi.RedirectStandardOutput = $true
  $psi.RedirectStandardError  = $true
  $psi.CreateNoWindow = $true

  $proc = New-Object System.Diagnostics.Process
  $proc.StartInfo = $psi

  [void]$proc.Start()

  $stdout = $proc.StandardOutput.ReadToEnd()
  $stderr = $proc.StandardError.ReadToEnd()

  $proc.WaitForExit()
  $exitCode = $proc.ExitCode

  # Replay captured output to console (keeps current behavior, but now controlled)
  if ($stdout) { Write-Host $stdout -NoNewline }
  if ($stderr) {
    Write-Host ""
    Write-Host "---- sqlcmd STDERR ----"
    Write-Host $stderr -NoNewline
    Write-Host ""
    Write-Host "-----------------------"
  }

  Write-Host ("sqlcmd exit code: {0}" -f $exitCode)
  return $exitCode
}

# ETL sqlcmd vars (only ETL dacpac needs them)
# NOTE: tests no longer use sqlcmd vars at all
$etlVars = @{}
if ($cfg.sqlcmd) {
  $cfg.sqlcmd.PSObject.Properties | ForEach-Object {
    $etlVars[$_.Name] = $_.Value
  }
}

Write-Host ""
Write-Host "etl sqlcmd vars (for ETL publish):"
if ($etlVars.Count -eq 0) {
  Write-Host "  (none)"
} else {
  foreach ($k in ($etlVars.Keys | Sort-Object)) {
    Write-Host ("  {0} = [{1}]" -f $k, $etlVars[$k])
  }
}

# -------------------------
# Always reset before + after
# -------------------------
Write-Host ""
Write-Host "--- LocalDB reset (start) ---"
& $resetScript -InstanceName "MSSQLLocalDB" -RecreateAndStart:$true
if ($LASTEXITCODE -ne 0) { throw "LocalDB reset (start) failed." }

try {
  # Build
  Write-Host ""
  Write-Host "--- Build ---"
  & $msbuild $solution /t:Build /p:Configuration=Debug /m
  if ($LASTEXITCODE -ne 0) { throw "Build failed." }

  # Deploy in order
  Publish-Dacpac "Staging" $cfg.databases.Staging @{}
  Publish-Dacpac "ODS"     $cfg.databases.ODS     @{}
  Publish-Dacpac "DWH"     $cfg.databases.DWH     @{}
  Publish-Dacpac "ETL"     $cfg.databases.ETL     $etlVars

  # Tests: run 0*.sql in name order; scripts decide DB via USE
  if ($RunTests) {
    Write-Host ""
    Write-Host "--- Tests ---"

    $testsDir = Join-Path $repoRoot "build\tests"
    if (-not (Test-Path -LiteralPath $testsDir)) { throw "Tests dir not found: $testsDir" }

    $tests = Get-ChildItem -LiteralPath $testsDir -Filter "0*.sql" -File | Sort-Object Name
    if (-not $tests -or $tests.Count -eq 0) { throw "No tests found in: $testsDir" }

    foreach ($t in $tests) {
      Write-Host ""
      Write-Host ("Running test: {0}" -f $t.Name)

      # Connect to master; each script can: USE [ETL]/[DWH]/etc
      $exit = Invoke-SqlCmdFile -database "master" -file $t.FullName
      if ($exit -ne 0) { throw "Test failed: $($t.Name)" }
    }
  }
  else {
    Write-Host ""
    Write-Host "Tests skipped (RunTests=false)."
  }

  Write-Host ""
  Write-Host ("Deploy complete: {0}" -f $cfg.server)
}
finally {
  Write-Host ""
  Write-Host "--- LocalDB reset (end) ---"
  & $resetScript -InstanceName "MSSQLLocalDB" -RecreateAndStart:$false | Out-Null
}
