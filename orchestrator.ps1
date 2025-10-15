[CmdletBinding()]
param(
    [Parameter()]
    [string[]]$Scripts = @(
        'helpers.ps1',
        'networkTweaks.ps1',
        'systemTweaks.ps1',
        'serviceTweaks.ps1',
        'gamesTweaks.ps1',
        'backup.ps1',
        'benchmark.ps1',
        'gui.ps1'
    ),

    [Parameter()]
    [string]$RootPath = $PSScriptRoot,

    [Parameter()]
    [switch]$StopOnError
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Attempt to use the shared logging routine if helpers.ps1 is available.
$script:OrchestratorLogger = $null
try {
    $helpersPath = Join-Path $RootPath 'helpers.ps1'
    if (Test-Path $helpersPath) {
        . $helpersPath
        if (Get-Command -Name Log -ErrorAction SilentlyContinue) {
            $script:OrchestratorLogger = { param($Message, $Level) Log $Message $Level }
        }
    }
}
catch {
    $script:OrchestratorLogger = $null
}

function Write-OrchestratorLog {
    param(
        [Parameter(Mandatory)]
        [string]$Message,

        [ValidateSet('Info','Success','Warning','Error')]
        [string]$Level = 'Info'
    )

    if ($script:OrchestratorLogger) {
        & $script:OrchestratorLogger $Message $Level
    }
    else {
        Write-Output "[$Level] $Message"
    }
}

function Resolve-ScriptPath {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if ([System.IO.Path]::IsPathRooted($Path)) {
        return $Path
    }

    if ([string]::IsNullOrWhiteSpace($RootPath)) {
        return (Join-Path $PSScriptRoot $Path)
    }

    return (Join-Path $RootPath $Path)
}

$loadedScripts = 0
foreach ($scriptPath in $Scripts) {
    $resolvedPath = Resolve-ScriptPath -Path $scriptPath

    if (-not (Test-Path $resolvedPath)) {
        Write-OrchestratorLog "Script not found: $resolvedPath" 'Error'
        if ($StopOnError) {
            throw "Script not found: $resolvedPath"
        }
        else {
            continue
        }
    }

    try {
        Write-OrchestratorLog "Loading script: $resolvedPath"
        . $resolvedPath
        $loadedScripts++
        Write-OrchestratorLog "Loaded script: $resolvedPath" 'Success'
    }
    catch {
        Write-OrchestratorLog "Failed to load ${resolvedPath}: $($_.Exception.Message)" 'Error'
        if ($StopOnError) {
            throw
        }
    }
}

Write-OrchestratorLog "Total scripts loaded: $loadedScripts" 'Info'
