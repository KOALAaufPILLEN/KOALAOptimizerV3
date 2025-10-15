[CmdletBinding()]
param(
    [switch]$NoGui
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:MainLogger = $null
function Write-MainLog {
    param(
        [string]$Message,
        [string]$Level = 'Info'
    )

    if ($script:MainLogger) {
        & $script:MainLogger $Message $Level
    }
    else {
        Write-Output "[$Level] $Message"
    }
}

$moduleList = @(
    'helpers.ps1',
    'networkTweaks.ps1',
    'systemTweaks.ps1',
    'serviceTweaks.ps1',
    'gamesTweaks.ps1',
    'backup.ps1',
    'benchmark.ps1',
    'gui.ps1'
)

foreach ($module in $moduleList) {
    $modulePath = Join-Path $PSScriptRoot $module
    if (-not (Test-Path $modulePath)) {
        Write-MainLog "Module not found: $modulePath" 'Error'
        if ($module -eq 'helpers.ps1' -or $module -eq 'gui.ps1') {
            throw "Required module missing: $modulePath"
        }
        else {
            continue
        }
    }

    try {
        . $modulePath
        Write-MainLog "Loaded module: $module" 'Success'
        if ($module -eq 'helpers.ps1' -and (Get-Command -Name Log -ErrorAction SilentlyContinue)) {
            $script:MainLogger = { param($Message, $Level) Log $Message $Level }
        }
    }
    catch {
        Write-MainLog "Failed to load ${module}: $($_.Exception.Message)" 'Error'
        throw
    }
}

$orchestratorPath = Join-Path $PSScriptRoot 'orchestrator.ps1'
if (Test-Path $orchestratorPath) {
    try {
        . $orchestratorPath
        Write-MainLog 'Loaded orchestrator.ps1' 'Success'
    }
    catch {
        Write-MainLog "Failed to load orchestrator.ps1: $($_.Exception.Message)" 'Error'
    }
}
else {
    Write-MainLog 'orchestrator.ps1 not found. Continuing without orchestration helpers.' 'Warning'
}

if ($NoGui) {
    Write-MainLog 'KOALA Optimizer launched in CLI mode (-NoGui).' 'Info'
    return
}

try {
    Initialize-Application
    Write-MainLog 'KOALA Optimizer GUI initialization triggered.' 'Info'
}
catch {
    Write-MainLog "Initialize-Application failed: $($_.Exception.Message)" 'Error'
    throw
}
