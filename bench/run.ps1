# bench/run.ps1 — Windows / PowerShell orchestrator for the bench suite.
#
# Same behaviour as bench/run.sh but uses native Docker calls so it works
# under Docker Desktop on Windows without any path-translation grief.
#
# Usage:
#   .\run.ps1                         # all targets, 3 runs each
#   .\run.ps1 -Target easynginx       # one tool only
#   .\run.ps1 -Runs 1                 # quick smoke
#
# Output: results\<UTC-stamp>\raw.csv plus a markdown summary.

[CmdletBinding()]
param(
    [string]$Target = "",
    [int]   $Runs   = 3
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path

$AllTargets = @('easynginx', 'easyengine', 'webinoly')
$Targets    = if ($Target) { @($Target) } else { $AllTargets }
$ImgTag     = 'easynginx-bench:ubuntu-24.04'

function DockerFlagsFor([string]$t) {
    if ($t -eq 'easyengine') { return @('--privileged') }
    return @()
}

# --- check docker -----------------------------------------------------------
& docker --version | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Error "docker is required."
}

# --- output dir -------------------------------------------------------------
$Stamp  = (Get-Date).ToUniversalTime().ToString('yyyyMMdd-HHmmss')
$OutDir = Join-Path $Root "results\$Stamp"
New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
$Csv = Join-Path $OutDir 'raw.csv'
$Log = Join-Path $OutDir 'run.log'
'target,scenario,run,wall_seconds,disk_added_kb,rss_added_kb,ok' `
    | Out-File -FilePath $Csv -Encoding ascii -Force

# --- build image ------------------------------------------------------------
Write-Host "==> building benchmark image: $ImgTag"
& docker build -q -t $ImgTag -f (Join-Path $Root 'Dockerfile.ubuntu') $Root | Out-Null
if ($LASTEXITCODE -ne 0) { Write-Error "docker build failed." }

# --- run --------------------------------------------------------------------
foreach ($t in $Targets) {
    $flags = DockerFlagsFor $t
    for ($r = 1; $r -le $Runs; $r++) {
        Write-Host "==> $t / run $r"
        Add-Content $Log "==> $t / run $r"

        $args = @('run', '--rm') + $flags + @(
            '-e', "BENCH_TARGET=$t",
            '-e', "BENCH_RUN=$r",
            $ImgTag,
            'bash', '/work/driver.sh'
        )

        # Capture stdout into the CSV; stderr into the log.
        $stdout = [System.IO.Path]::GetTempFileName()
        $stderr = [System.IO.Path]::GetTempFileName()
        try {
            $proc = Start-Process -FilePath 'docker' -ArgumentList $args `
                                  -NoNewWindow -PassThru -Wait `
                                  -RedirectStandardOutput $stdout `
                                  -RedirectStandardError  $stderr
            Get-Content $stdout | Add-Content $Csv
            Get-Content $stderr | Add-Content $Log
            if ($proc.ExitCode -ne 0) {
                Add-Content $Log "  [warn] docker run exited $($proc.ExitCode)"
                Write-Host    "  [warn] docker run exited $($proc.ExitCode); see $Log"
            }
        } finally {
            Remove-Item $stdout, $stderr -Force -ErrorAction SilentlyContinue
        }
    }
}

# --- aggregate --------------------------------------------------------------
Write-Host ""
Write-Host "==> aggregating"
$Summary = Join-Path $OutDir 'summary.md'
if (Get-Command py -ErrorAction SilentlyContinue) {
    $py = 'py'
} else {
    $py = 'python'
}
& $py (Join-Path $Root 'aggregate.py') $Csv `
    | Out-File -FilePath $Summary -Encoding utf8 -Force

Write-Host ""
Write-Host "Done."
Write-Host "  Raw CSV: $Csv"
Write-Host "  Summary: $Summary"
Write-Host "  Logs:    $Log"
