@echo off
setlocal enabledelayedexpansion

set "SCRIPT_DIR=%~dp0"
set "MERGER=%SCRIPT_DIR%merger-update.ps1"
set "MERGER_ORIGINAL_ARGS=%*"
set "MERGER_BRANCH=main"

for /f "usebackq delims=" %%B in (`powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$branch = 'main';" ^
    "$raw = [Environment]::GetEnvironmentVariable('MERGER_ORIGINAL_ARGS');" ^
    "if (-not [string]::IsNullOrWhiteSpace($raw)) {" ^
    "    $tokens = [Management.Automation.Language.Parser]::SplitInput($raw, [ref]$null, [ref]$null);" ^
    "    for ($i = 0; $i -lt $tokens.Count; $i++) {" ^
    "        if ($tokens[$i] -eq '-Branch' -and $i + 1 -lt $tokens.Count) {" ^
    "            $branch = $tokens[$i + 1];" ^
    "            break" ^
    "        }" ^
    "    }" ^
    "}" ^
    "Write-Output $branch"`) do set "MERGER_BRANCH=%%B"

if not exist "%MERGER%" (
    echo [ERROR] Could not find merger-update.ps1 next to this batch file.
    exit /b 1
)

echo Refreshing merger-update.ps1 from GitHub (branch %MERGER_BRANCH%)...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$uri = 'https://raw.githubusercontent.com/KOALAaufPILLEN/KOALAOptimizerV3/%MERGER_BRANCH%/merger-update.ps1';" ^
    "$destination = '%MERGER%';" ^
    "try {" ^
    "    Invoke-WebRequest -Uri $uri -OutFile $destination -UseBasicParsing" ^
    "    Write-Host 'merger-update.ps1 refreshed.' -ForegroundColor Green" ^
    "} catch {" ^
    "    Write-Host ('WARNING: Could not refresh merger-update.ps1 - {0}' -f $_.Exception.Message) -ForegroundColor Yellow" ^
    "    exit 1" ^
    "}"
if errorlevel 1 (
    echo [WARNING] Continuing with local merger-update.ps1 copy.
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
