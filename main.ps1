Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. "$PSScriptRoot\helpers.ps1"
. "$PSScriptRoot\networkTweaks.ps1"
. "$PSScriptRoot\systemTweaks.ps1"
. "$PSScriptRoot\serviceTweaks.ps1"
. "$PSScriptRoot\gamesTweaks.ps1"
. "$PSScriptRoot\backup.ps1"
. "$PSScriptRoot\benchmark.ps1"
. "$PSScriptRoot\orchestrator.ps1"
. "$PSScriptRoot\gui.ps1"

try {
    Initialize-Application
} catch {
    Write-Host "Initialize-Application failed: $($_.Exception.Message)" -ForegroundColor Red
}
