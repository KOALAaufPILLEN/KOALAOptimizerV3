@echo off
setlocal enabledelayedexpansion

set "SCRIPT_DIR=%~dp0"
set "MERGER=%SCRIPT_DIR%merger-update.ps1"

if not exist "%MERGER%" (
    echo [ERROR] Could not find merger-update.ps1 next to this batch file.
    exit /b 1
)

echo Launching PowerShell merger (this may take a moment)...
powershell -NoProfile -ExecutionPolicy Bypass -File "%MERGER%" %*
set "EXIT_CODE=%ERRORLEVEL%"

if "%EXIT_CODE%" NEQ "0" (
    echo.
    echo [ERROR] merger-update.ps1 exited with code %EXIT_CODE%.
    echo If you saw a download error, please check your internet connection or firewall.
) else (
    echo.
    echo [SUCCESS] Merge and executable creation completed.
    echo You can now run KOALAOptimizerV3-full.ps1 or KOALAOptimizerV3-full.exe.
)

pause
exit /b %EXIT_CODE%
