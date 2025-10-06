# Run-Me-First.ps1 — Unblock, set policy for session, and launch KOALA-UDP
[CmdletBinding()]
param()

try {
    Write-Host "Unblocking files..." -ForegroundColor Cyan
    Get-ChildItem -Recurse -File $PSScriptRoot | Unblock-File -ErrorAction SilentlyContinue
} catch {
    # Non-fatal; continue even if Unblock-File is unavailable
}

Write-Host "Setting ExecutionPolicy = Bypass for this session..." -ForegroundColor Cyan
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

$main = Join-Path $PSScriptRoot "main.ps1"
if (Test-Path $main) {
    Write-Host "Launching main.ps1 ..." -ForegroundColor Green
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $main
} else {
    Write-Host "main.ps1 not found next to this script." -ForegroundColor Red
}
