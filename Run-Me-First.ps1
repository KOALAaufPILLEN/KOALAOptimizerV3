[CmdletBinding()]
param()

function Test-IsAdministrator {
    try {
        $currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = [Security.Principal.WindowsPrincipal]::new($currentIdentity)
        return $principal.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
    }
    catch {
        return $false
    }
}

try {
    Write-Host "Unblocking files..." -ForegroundColor Cyan
    Get-ChildItem -Recurse -File $PSScriptRoot | Unblock-File -ErrorAction SilentlyContinue
}
catch {
    Write-Warning "Unable to unblock all files: $($_.Exception.Message)"
}

$main = Join-Path $PSScriptRoot 'main.ps1'
if (-not (Test-Path $main)) {
    Write-Host "main.ps1 not found next to this script." -ForegroundColor Red
    return
}

if (Test-IsAdministrator) {
    try {
        Write-Host "Setting ExecutionPolicy = Bypass for this session..." -ForegroundColor Cyan
        Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force -ErrorAction Stop
    }
    catch {
        Write-Warning "Unable to adjust execution policy: $($_.Exception.Message)"
    }

    Write-Host "Launching main.ps1 ..." -ForegroundColor Green
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $main
    return
}

Write-Warning 'Administrative rights are required to adjust execution policy safely. Attempting to relaunch elevated...'
try {
    $arguments = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', '"{0}"' -f $main)
    Start-Process -FilePath 'powershell.exe' -ArgumentList $arguments -Verb RunAs -ErrorAction Stop | Out-Null
}
catch {
    Write-Warning "Elevated launch failed: $($_.Exception.Message)"
}
