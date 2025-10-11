<#
.SYNOPSIS
    Downloads the latest KOALA Optimizer split scripts and builds a single merged script.

.DESCRIPTION
    merger-update.ps1 refreshes the local copy of the KOALA Optimizer split PowerShell
    scripts directly from GitHub and concatenates them into a single monolithic file.
    This makes it easy to keep the toolkit up to date and to distribute a one-file
    variant (similar to V3-testing.ps1) for quick local execution or inspection.

.PARAMETER Branch
    Git branch to download files from. Defaults to 'main'.

.PARAMETER Output
    File name for the merged script. Defaults to 'KOALAOptimizerV3-full.ps1'.

.PARAMETER SkipDownload
    If specified, skips the download step and only merges the already available local files.

.EXAMPLE
    PS> .\merger-update.ps1
    Downloads the latest scripts from GitHub and writes KOALAOptimizerV3-full.ps1.

.EXAMPLE
    PS> .\merger-update.ps1 -Branch dev -Output KOALAOptimizer-dev.ps1
    Fetches scripts from the 'dev' branch and writes the merged output to KOALAOptimizer-dev.ps1.
#>
[CmdletBinding()]
param(
    [Parameter()]
    [string]$Branch = 'main',

    [Parameter()]
    [string]$Output = 'KOALAOptimizerV3-full.ps1',

    [Parameter()]
    [switch]$SkipDownload,

    [Parameter()]
    [switch]$SkipExecutable
)

$ErrorActionPreference = 'Stop'

$repo = 'KOALAaufPILLEN/KOALAOptimizerV3'
$rawBaseUri = "https://raw.githubusercontent.com/$repo/$Branch"
$scriptRoot = $PSScriptRoot
$filesToProcess = @(
    'helpers.ps1',
    'networkTweaks.ps1',
    'systemTweaks.ps1',
    'serviceTweaks.ps1',
    'gamesTweaks.ps1',
    'backup.ps1',
    'benchmark.ps1',
    'orchestrator.ps1',
    'gui.ps1'
)

if (-not $SkipDownload) {
    try {
        # Ensure TLS 1.2+ is available for Invoke-WebRequest on older PowerShell builds
        if ([Net.ServicePointManager]::SecurityProtocol -band [Net.SecurityProtocolType]::Tls12 -eq 0) {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        }
    } catch {
        Write-Verbose "Failed to set TLS 1.2. Continuing with default security protocol."
    }

    foreach ($file in $filesToProcess) {
        $uri = "$rawBaseUri/$file"
        $destination = Join-Path $scriptRoot $file

        Write-Host "Downloading $file ..." -ForegroundColor Cyan
        try {
            Invoke-WebRequest -Uri $uri -OutFile $destination -UseBasicParsing
        } catch {
            Write-Host "Download failed for ${file}: $($_.Exception.Message)" -ForegroundColor Red
            throw
        }
    }

    # main.ps1 is small and primarily holds the entrypoint, so refresh it too
    $mainUri = "$rawBaseUri/main.ps1"
    $mainDestination = Join-Path $scriptRoot 'main.ps1'
    Write-Host 'Downloading main.ps1 ...' -ForegroundColor Cyan
    Invoke-WebRequest -Uri $mainUri -OutFile $mainDestination -UseBasicParsing
}

$mergedPath = Join-Path $scriptRoot $Output
Write-Host "Building merged script -> $Output" -ForegroundColor Green

$header = @(
    '# KOALA Gaming Optimizer v3.0 - merged script',
    "# Generated on $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
    '# Source repository: https://github.com/KOALAaufPILLEN/KOALAOptimizerV3',
    '' ,
    'Set-StrictMode -Version Latest',
    "$ErrorActionPreference = 'Stop'",
    ''
)

$entryPoint = @(
    'try {',
    '    Initialize-Application',
    '} catch {',
    '    Write-Host "Initialize-Application failed: $($_.Exception.Message)" -ForegroundColor Red',
    '}',
    ''
)

$allLines = [System.Collections.Generic.List[string]]::new()
foreach ($line in $header) {
    [void]$allLines.Add([string]$line)
}

foreach ($file in $filesToProcess) {
    $allLines.Add("#region ${file}")
    $modulePath = Join-Path $scriptRoot $file

    if (-not (Test-Path $modulePath)) {
        throw "Required file '$file' was not found at $modulePath."
    }

    $moduleLines = Get-Content -Path $modulePath -Encoding UTF8
    foreach ($line in [string[]]$moduleLines) {
        [void]$allLines.Add($line)
    }
    $allLines.Add("#endregion ${file}")
    $allLines.Add('')
}

foreach ($line in $entryPoint) {
    [void]$allLines.Add([string]$line)
}

$allLines | Set-Content -Path $mergedPath -Encoding UTF8BOM

Write-Host "Merged script written to $mergedPath" -ForegroundColor Green

if (-not $SkipExecutable) {
    $exeOutput = [System.IO.Path]::ChangeExtension($mergedPath, '.exe')
    Write-Host "Building standalone executable -> $exeOutput" -ForegroundColor Green

    $tempDir = Join-Path $scriptRoot 'temp-merger-tools'
    if (-not (Test-Path $tempDir)) {
        New-Item -Path $tempDir -ItemType Directory -Force | Out-Null
    }

    $ps2exeUrl = 'https://raw.githubusercontent.com/MScholtes/PS2EXE/master/ps2exe.ps1'
    $ps2exePath = Join-Path $tempDir 'ps2exe.ps1'

    try {
        Write-Host 'Downloading PS2EXE converter ...' -ForegroundColor Cyan
        Invoke-WebRequest -Uri $ps2exeUrl -OutFile $ps2exePath -UseBasicParsing
    } catch {
        Write-Host "Failed to download PS2EXE: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host 'Skipping executable creation. You can rerun with -SkipExecutable:$false after fixing connectivity.' -ForegroundColor Yellow
        return
    }

    try {
        $ps2exeArgs = @(
            '-inputFile', $mergedPath,
            '-outputFile', $exeOutput,
            '-noConsole',
            '-title', 'KOALA Optimizer V3',
            '-description', 'Merged KOALA Optimizer V3 toolkit'
        )

        Write-Host 'Converting merged script to executable ...' -ForegroundColor Cyan
        & $ps2exePath @ps2exeArgs
        Write-Host "Executable written to $exeOutput" -ForegroundColor Green
    } catch {
        Write-Host "Failed to create executable: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host 'The merged script is still available. You can rerun merger-update.ps1 to retry the conversion.' -ForegroundColor Yellow
    } finally {
        if (Test-Path $ps2exePath) {
            Remove-Item -Path $ps2exePath -Force -ErrorAction SilentlyContinue
        }

        if ((Get-ChildItem -Path $tempDir -Force | Measure-Object).Count -eq 0) {
            Remove-Item -Path $tempDir -Force -ErrorAction SilentlyContinue
        }
    }
}
