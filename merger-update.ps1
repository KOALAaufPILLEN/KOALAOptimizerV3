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

# Prefer the central logger provided by helpers.ps1 when available.
$script:MergerLogger = $null
try {
    $helpersPath = Join-Path $PSScriptRoot 'helpers.ps1'
    if (Test-Path $helpersPath) {
        . $helpersPath
        if (Get-Command -Name Log -ErrorAction SilentlyContinue) {
            $script:MergerLogger = { param($Message, $Level) Log $Message $Level }
        }
    }
}
catch {
    # Fallback to basic stdout logging if helpers.ps1 cannot be loaded.
    $script:MergerLogger = $null
}

function Write-MergerLog {
    param(
        [Parameter(Mandatory)]
        [string]$Message,

        [ValidateSet('Info','Success','Warning','Error')]
        [string]$Level = 'Info'
    )

    if ($script:MergerLogger) {
        & $script:MergerLogger $Message $Level
    }
    else {
        Write-Output "[$Level] $Message"
    }
}

$repo = 'KOALAaufPILLEN/KOALAOptimizerV3'
$rawBaseUri = "https://raw.githubusercontent.com/$repo/$Branch"
$scriptRoot = $PSScriptRoot
[string[]]$filesToProcess = @(
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
    }
    catch {
        Write-MergerLog "Failed to set TLS 1.2. Continuing with default security protocol. $_" 'Warning'
    }

    foreach ($file in $filesToProcess) {
        $uri = "$rawBaseUri/$file"
        $destination = Join-Path $scriptRoot $file

        Write-MergerLog "Downloading $file ..."
        try {
            Invoke-WebRequest -Uri $uri -OutFile $destination -UseBasicParsing -ErrorAction Stop
            Write-MergerLog "Downloaded $file" 'Success'
        }
        catch {
            Write-MergerLog "Download failed for ${file}: $($_.Exception.Message)" 'Error'
            throw
        }
    }

    # main.ps1 is small and primarily holds the entrypoint, so refresh it too
    $mainUri = "$rawBaseUri/main.ps1"
    $mainDestination = Join-Path $scriptRoot 'main.ps1'
    Write-MergerLog 'Downloading main.ps1 ...'
    try {
        Invoke-WebRequest -Uri $mainUri -OutFile $mainDestination -UseBasicParsing -ErrorAction Stop
        Write-MergerLog 'Downloaded main.ps1' 'Success'
    }
    catch {
        Write-MergerLog "Download failed for main.ps1: $($_.Exception.Message)" 'Error'
        throw
    }
}

$mergedPath = Join-Path $scriptRoot $Output
Write-MergerLog "Building merged script -> $Output"

[string[]]$header = @(
    '# KOALA Gaming Optimizer v3.0 - merged script',
    "# Generated on $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
    '# Source repository: https://github.com/KOALAaufPILLEN/KOALAOptimizerV3',
    '',
    'Set-StrictMode -Version Latest',
    "$ErrorActionPreference = 'Stop'",
    ''
)

[string[]]$entryPoint = @(
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
    $allLines += "#region ${file}"
    $modulePath = Join-Path $scriptRoot $file

    if (-not (Test-Path $modulePath)) {
        throw "Required file '$file' was not found at $modulePath."
    }

    try {
        [string[]]$moduleLines = Get-Content -Path $modulePath -Encoding UTF8 -ErrorAction Stop
        $allLines.AddRange($moduleLines)
    }
    catch {
        Write-MergerLog "Failed to read ${modulePath}: $($_.Exception.Message)" 'Error'
        throw
    }

    $allLines.Add("#endregion ${file}")
    $allLines.Add('')
}

$allLines.AddRange($entryPoint)

try {
    # Older Windows PowerShell releases do not support the UTF8BOM encoding token.
    # Use a UTF-8 encoding instance with BOM to stay compatible across versions.
    $utf8WithBom = New-Object System.Text.UTF8Encoding($true)
    [System.IO.File]::WriteAllLines($mergedPath, $allLines.ToArray(), $utf8WithBom)
    Write-MergerLog "Merged script written to $mergedPath" 'Success'
}
catch {
    Write-MergerLog "Failed to write merged script: $($_.Exception.Message)" 'Error'
    throw
}

if (-not $SkipExecutable) {
    $exeOutput = [System.IO.Path]::ChangeExtension($mergedPath, '.exe')
    Write-MergerLog "Building standalone executable -> $exeOutput"

    $tempDir = Join-Path $scriptRoot 'temp-merger-tools'
    if (-not (Test-Path $tempDir)) {
        New-Item -Path $tempDir -ItemType Directory -Force | Out-Null
    }

    $ps2exeUrl = 'https://raw.githubusercontent.com/MScholtes/PS2EXE/master/ps2exe.ps1'
    $ps2exePath = Join-Path $tempDir 'ps2exe.ps1'

    if (-not $SkipDownload -or -not (Test-Path $ps2exePath)) {
        try {
            Write-MergerLog -Message 'Downloading PS2EXE converter ...'
            Invoke-WebRequest -Uri $ps2exeUrl -OutFile $ps2exePath -UseBasicParsing -ErrorAction Stop
            Write-MergerLog -Message 'PS2EXE converter downloaded' -Level 'Success'
        }
        catch {
            Write-MergerLog -Message "Failed to download PS2EXE: $($_.Exception.Message)" -Level 'Warning'
            Write-MergerLog -Message 'Skipping executable creation. You can rerun merger-update.ps1 to retry once connectivity is restored.' -Level 'Warning'
            return
        }
    }

    if (-not (Test-Path $ps2exePath)) {
        Write-MergerLog -Message "PS2EXE converter not found at $ps2exePath. Skipping executable build." -Level 'Warning'
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

        Write-MergerLog -Message 'Converting merged script to executable ...'
        & $ps2exePath @ps2exeArgs
        Write-MergerLog -Message "Executable written to $exeOutput" -Level 'Success'
    }
    catch {
        Write-MergerLog -Message "Failed to create executable: $($_.Exception.Message)" -Level 'Error'
        Write-MergerLog -Message 'The merged script is still available. You can rerun merger-update.ps1 to retry the conversion.' -Level 'Warning'
    }
    finally {
        if (Test-Path $ps2exePath) {
            Remove-Item -Path $ps2exePath -Force -ErrorAction SilentlyContinue
        }

        if ((Get-ChildItem -Path $tempDir -Force | Measure-Object).Count -eq 0) {
            Remove-Item -Path $tempDir -Force -ErrorAction SilentlyContinue
        }
    }
}
