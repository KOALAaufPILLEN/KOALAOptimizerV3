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
    [switch]$SkipDownload
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
$allLines.AddRange($header)

foreach ($file in $filesToProcess) {
    $allLines.Add("#region ${file}")
    $modulePath = Join-Path $scriptRoot $file

    if (-not (Test-Path $modulePath)) {
        throw "Required file '$file' was not found at $modulePath."
    }

    $moduleContent = Get-Content -Path $modulePath -Raw
    $moduleLines = $moduleContent -split "`r?`n"
    $allLines.AddRange($moduleLines)
    $allLines.Add("#endregion ${file}")
    $allLines.Add('')
}

$allLines.AddRange($entryPoint)

$allLines | Set-Content -Path $mergedPath -Encoding UTF8

Write-Host "Merged script written to $mergedPath" -ForegroundColor Green
