# ---------- Check PowerShell Version ----------
if ($PSVersionTable.PSVersion.Major -lt 5) {
    Write-Host "This script requires PowerShell 5.0 or higher" -ForegroundColor Red
    exit 1
}

# Detect whether the current platform supports the Windows-specific UI that the
# optimizer relies on. Older PowerShell builds do not expose the $IsWindows
# automatic variable, so fall back to the .NET APIs when necessary.
$script:IsWindowsPlatform = $false
    $script:IsWindowsPlatform = [System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform(
        [System.Runtime.InteropServices.OSPlatform]::Windows
    )
    $script:IsWindowsPlatform = ([System.Environment]::OSVersion.Platform -eq [System.PlatformID]::Win32NT)

if (-not $script:IsWindowsPlatform) {
    Write-Host 'KOALA Gaming Optimizer requires Windows because it depends on WPF and Windows-specific APIs.' -ForegroundColor Yellow
    return
}

# ---------- WPF Assemblies ----------
# Load required assemblies for the WPF-based UI. Breaking the list of
# assemblies into an array keeps the code readable and avoids issues with
# extremely long lines or accidental line wraps.
$assemblies = @(
    'PresentationFramework'
    'PresentationCore'
    'WindowsBase'
    'System.Xaml'
    'System.Windows.Forms'
    'Microsoft.VisualBasic'
)

try {
    Add-Type -AssemblyName $assemblies -ErrorAction Stop
}
catch {
    $warning = "Warning: WPF assemblies not available. This script requires Windows with .NET Framework."
    Write-Host $warning -ForegroundColor Yellow
    return
}

$BrushConverter = New-Object System.Windows.Media.BrushConverter

# ---------- Global Performance Variables ----------
$global:PerformanceCounters = @{}
$script:LocalizationResources = $null
if (-not $script:CurrentLanguage) {
    $script:CurrentLanguage = 'en'
}
$script:IsLanguageInitializing = $false
$global:OptimizationCache = @{}
$global:ActiveGames = @()
$global:MenuMode = "Basic"  # Basic or Advanced
$global:AutoOptimizeEnabled = $false
$global:LastTimestamp = $null
$global:CachedTimestamp = ""
$global:LogBoxAvailable = $false
$global:RegistryCache = @{}
$global:LastOptimizationTime = $null  # Track when optimizations were last applied

# ---------- .NET Framework 4.8 Compatibility Helper Functions ----------
function Set-BorderBrushSafe {
    param(
        [System.Windows.FrameworkElement]$Element,
        [object]$BorderBrushValue,
        [string]$BorderThicknessValue = $null
    )

    if (-not $Element) { return }

        # Check if element supports BorderBrush
        if ($Element.GetType().GetProperty("BorderBrush")) {
            Set-BrushPropertySafe -Target $Element -Property 'BorderBrush' -Value $BorderBrushValue -AllowTransparentFallback

        }

        # Set BorderThickness if provided and supported
        if ($BorderThicknessValue -and $Element.GetType().GetProperty("BorderThickness")) {
            $Element.BorderThickness = $BorderThicknessValue
        }
        # Sealed object exception - skip assignment
        Write-Verbose "BorderBrush assignment skipped due to sealed object (compatible with .NET Framework 4.8)"
        # Other exceptions - log but don't fail
        Write-Verbose "BorderBrush assignment failed: $($_.Exception.Message)"
    }

# ---------- CENTRALIZED THEME ARRAY - ONLY CHANGE HERE! ----------
# ---------- COMPLETE THEME ARRAY - ALL COLORS CENTRALIZED! ----------
$global:ThemeDefinitions = @{
    'OptimizerDark' = @{
        Name = 'Optimizer Dark'
        Background = $BrushConverter.ConvertFromString('#0F0B1E')
        Primary = '#8F6FFF'
        Hover = '#2A214F'
        Text = '#FFFFFF'
        Secondary = $BrushConverter.ConvertFromString('#141129')
        Accent = '#8F6FFF'
        TextSecondary = '#B8B5D1'
        LogBg = $BrushConverter.ConvertFromString('#181230')
        SidebarBg = $BrushConverter.ConvertFromString('#1C1733')
        HeaderBg = $BrushConverter.ConvertFromString('#1D1834')
        Success = '#22C55E'
        Warning = '#F59E0B'
        Danger = '#EF4444'
        Info = '#38BDF8'
        CardBackgroundStart = $BrushConverter.ConvertFromString('#1D1834')
        CardBackgroundEnd = $BrushConverter.ConvertFromString('#221C3F')
        SummaryBackgroundStart = $BrushConverter.ConvertFromString('#211B3B')
        SummaryBackgroundEnd = $BrushConverter.ConvertFromString('#241E45')
        CardBorder = '#2E2752'
        GlowAccent = '#403270'
        GaugeBackground = $BrushConverter.ConvertFromString('#2A214F')
        GaugeStroke = '#8F6FFF'
        SelectedBackground = $BrushConverter.ConvertFromString('#403270')
        UnselectedBackground = $BrushConverter.ConvertFromString('#2A214F')
        SelectedForeground = $BrushConverter.ConvertFromString('#F7F6FF')
        UnselectedForeground = $BrushConverter.ConvertFromString('#B8B5D1')
        HoverBackground = $BrushConverter.ConvertFromString('#2A214F')
        IsLight = $false
    }
}

# Pre-instantiate the shared brush converter so later theming fallbacks never
# leave string literals or PSObject wrappers parked in resource dictionaries.
    $script:SharedBrushConverter = [System.Windows.Media.BrushConverter]::new()
    $script:SharedBrushConverter = $null

$script:BrushResourceKeys = @(
    'AppBackgroundBrush'
    'SidebarBackgroundBrush'
    'SidebarAccentBrush'
    'SidebarHoverBrush'
    'SidebarSelectedBrush'
    'SidebarSelectedForegroundBrush'
    'HeaderBackgroundBrush'
    'HeaderBorderBrush'
    'CardBackgroundBrush'
    'ContentBackgroundBrush'
    'CardBorderBrush'
    'HeroCardBrush'
    'AccentBrush'
    'PrimaryTextBrush'
    'SecondaryTextBrush'
    'SuccessBrush'
    'WarningBrush'
    'DangerBrush'
    'InfoBrush'
    'ButtonBackgroundBrush'
    'ButtonBorderBrush'
    'ButtonHoverBrush'
    'ButtonPressedBrush'
    'HeroChipBrush'
    'DialogBackgroundBrush'
)


function Register-BrushResourceKeys {
    param([System.Collections.IEnumerable]$Keys)

    if (-not $Keys) { return }

    foreach ($rawKey in $Keys) {
        if ($null -eq $rawKey) { continue }

        $keyText = $null
        try { $keyText = [string]$rawKey } catch { $keyText = $null }
        if ([string]::IsNullOrWhiteSpace($keyText)) { continue }
        if (-not $keyText.EndsWith('Brush')) { continue }

        if (-not $script:BrushResourceKeys) {
            $script:BrushResourceKeys = @()
        }

        if ($script:BrushResourceKeys -notcontains $keyText) {
            $script:BrushResourceKeys += $keyText
        }
    }
}


# Storage for the last applied custom theme so navigation refreshes reuse the same colors
$global:CustomThemeColors = $null


# Einfache Funktion zum Abrufen eines Themes
function Get-ThemeColors {
    param([string]$ThemeName = 'OptimizerDark')

    if ($global:ThemeDefinitions.ContainsKey($ThemeName)) {
        return Normalize-ThemeColorTable $global:ThemeDefinitions[$ThemeName]
    } else {
        Log "Theme '$ThemeName' nicht gefunden, verwende Optimizer Dark" 'Warning'
        return Normalize-ThemeColorTable $global:ThemeDefinitions['OptimizerDark']
    }

function Optimize-LogFile {
    param([int]$MaxSizeMB = 10)

        $logFilePath = Join-Path $ScriptRoot 'Koala-Activity.log'

        if (Test-Path $logFilePath) {
            $logFile = Get-Item $logFilePath
            $sizeMB = [math]::Round($logFile.Length / 1MB, 2)

            if ($sizeMB -gt $MaxSizeMB) {
                # Keep only the last 70% of the file
                $content = Get-Content $logFilePath
                $keepLines = [math]::Floor($content.Count * 0.7)
                $content[-$keepLines..-1] | Set-Content $logFilePath

                # Add optimization notice
                Add-Content $logFilePath "[$([DateTime]::Now.ToString('HH:mm:ss'))] [Info] Log file optimized - size reduced from $sizeMB MB"

            }
        }
        # Silent failure for log optimization to prevent recursion
    }

function Get-SystemPerformanceMetrics {
    param([switch]$Detailed)

    try {
        $metrics = @{
            CPU = 0
            Memory = 0
            Disk = 0
            Network = 0
        }

        try {
            $cpu = Get-WmiObject -Class Win32_Processor | Measure-Object -Property LoadPercentage -Average
            if ($cpu -and $cpu.Average -ne $null) {
                $metrics.CPU = [math]::Round($cpu.Average, 1)
            }
        }
        catch {
            Write-Verbose "Failed to retrieve CPU metrics: $($_.Exception.Message)"
        }

        try {
            $totalMemory = (Get-WmiObject -Class Win32_ComputerSystem).TotalPhysicalMemory
            $availableMemory = (Get-WmiObject -Class Win32_OperatingSystem).AvailablePhysicalMemory

            if ($totalMemory -and $availableMemory) {
                $usedMemory = $totalMemory - $availableMemory
                $metrics.Memory = [math]::Round(($usedMemory / $totalMemory) * 100, 1)
            }
        }
        catch {
            Write-Verbose "Failed to retrieve memory metrics: $($_.Exception.Message)"
        }

        try {
            $diskUsage = Get-Counter -Counter "\PhysicalDisk(_Total)\% Disk Time" -ErrorAction Stop
            if ($diskUsage -and $diskUsage.CounterSamples) {
                $metrics.Disk = [math]::Round($diskUsage.CounterSamples.CookedValue, 1)
            }
        }
        catch {
            Write-Verbose "Failed to retrieve disk metrics: $($_.Exception.Message)"
        }

        try {
            $networkUsage = Get-Counter -Counter "\Network Interface(*)\Bytes Total/sec" -ErrorAction Stop
            if ($networkUsage -and $networkUsage.CounterSamples) {
                $metrics.Network = [math]::Round((($networkUsage.CounterSamples | Measure-Object CookedValue -Average).Average) / 1KB, 2)
            }
        }
        catch {
            Write-Verbose "Failed to retrieve network metrics: $($_.Exception.Message)"
        }

        if ($Detailed) {
            $metrics.Timestamp = Get-Date
            $metrics.Source = "WMI"
        }

        return $metrics
    }
    catch {
        Write-Verbose "Falling back to default system performance metrics: $($_.Exception.Message)"
        return @{
            CPU = 0
            Memory = 0
            Disk = 0
            Network = 0
        }
    }
}

function Ensure-NavigationVisibility {
    param([System.Windows.Controls.Panel]$NavigationPanel)

        if (-not $NavigationPanel) {
            return

        }

        # Ensure all navigation buttons are visible and properly styled
        $navigationButtons = @(
            'btnNavDashboard', 'btnNavBasicOpt', 'btnNavAdvanced', 'btnNavGames',
            'btnNavOptions', 'btnNavBackup', 'btnNavLog'
        )

        foreach ($buttonName in $navigationButtons) {
                $button = $form.FindName($buttonName)
                if ($button) {
                    $button.Visibility = [System.Windows.Visibility]::Visible

                    # Ensure proper styling
                    if (-not $button.Style) {
                        Set-BrushPropertySafe -Target $button -Property 'Background' -Value '#2F285A'
                        Set-BrushPropertySafe -Target $button -Property 'Foreground' -Value '#F5F3FF'
                        $button.BorderThickness = '0'
                        $button.Margin = '0,2'
                        $button.Padding = '15,10'

                    }
                }
                # Silent failure for individual buttons
            }
        }
        # Silent failure for navigation visibility


# ---------- Paths with Admin-safe Configuration ----------
if ($PSScriptRoot) {
    $ScriptRoot = $PSScriptRoot
} elseif ($MyInvocation -and $MyInvocation.MyCommand -and $MyInvocation.MyCommand.Path) {
    $ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
    $ScriptRoot = (Get-Location).Path

# Function moved to after helper functions to fix call order

# Initialize global variables for custom paths
$global:CustomConfigPath = $null
$global:CustomGamePaths = @()

# ---------- Core Logging Functions (moved to top to fix call order issues) ----------
function Get-LogColor($Level) {
    switch ($Level) {
        'Error' { 'Red' }
        'Warning' { 'Yellow' }
        'Success' { 'Green' }
        default { 'White' }
    }
}


$global:LogFilterSettings = @{
    ShowInfo = $true
    ShowSuccess = $true
    ShowWarning = $true
    ShowError = $true
    ShowContext = $false
    ShowDebug = $false
    SearchTerm = ""
    CategoryFilter = "All"
}
$global:LogCategories = @("All", "System", "Gaming", "Network", "UI", "Performance", "Security", "Optimization", "Status", "Debug")
$global:LogHistory = [System.Collections.ArrayList]::new()
$global:MaxLogHistorySize = 1000

function Get-EnhancedLogCategories {
    <#
    .SYNOPSIS
    Enhanced logging categories for better organization and filtering
    .DESCRIPTION
    Provides categorization system for logs to enable filtering and organization
    #>

    return @{
        "System" = @("Registry", "Service", "Process", "Hardware", "Driver")
        "Gaming" = @("Game", "Profile", "Optimization", "FPS", "Latency", "Auto-Detect")
        "Network" = @("TCP", "UDP", "Latency", "Bandwidth", "DNS", "Firewall")
        "UI" = @("Theme", "Panel", "Control", "Navigation", "Scale", "Layout")
        "Performance" = @("CPU", "Memory", "Disk", "GPU", "Benchmark", "Monitor")
        "Security" = @("Admin", "Permission", "UAC", "Privilege", "Access")
        "Optimization" = @("Applied", "Reverted", "Backup", "Restore", "Config")
        "Status" = @("Success", "Completed", "Ready", "Warning", "Alert", "Caution", "Healthy")
        "Debug" = @("Verbose", "Trace", "Internal", "Exception", "Stack")
    }
}

function Get-LogCategory {
    <#
    .SYNOPSIS
    Determines the category of a log message based on content analysis
    .PARAMETER Message
    The log message to categorize
    #>
    param([string]$Message)

    $categories = Get-EnhancedLogCategories

    foreach ($category in $categories.Keys) {
        foreach ($keyword in $categories[$category]) {
            if ($Message -match $keyword) {
                return $category
            }
        }
    }

    return "General"
}

function Add-LogToHistory {
    <#
    .SYNOPSIS
    Adds a log entry to the searchable history with metadata
    .PARAMETER Message
    The log message
    .PARAMETER Level
    The log level
    .PARAMETER Category
    The log category
    #>
    param(
        [string]$Message,
        [string]$Level = 'Info',
        [string]$Category = 'General'
    )

        if (-not $global:LogHistory -or -not ($global:LogHistory -is [System.Collections.IList])) {
            $global:LogHistory = [System.Collections.ArrayList]::new()

        }

        if (-not $global:MaxLogHistorySize -or $global:MaxLogHistorySize -lt 10) {
            $global:MaxLogHistorySize = 1000
        }

        $logEntry = @{
            Timestamp = Get-Date
            Message = $Message
            Level = $Level
            Category = $Category
            Thread = [System.Threading.Thread]::CurrentThread.ManagedThreadId
        }

        [void]$global:LogHistory.Add($logEntry)

        while ($global:LogHistory.Count -gt $global:MaxLogHistorySize) {
            $global:LogHistory.RemoveAt(0)

        }

        # Silent fail to prevent logging issues
        Write-Verbose "Failed to add log to history: $($_.Exception.Message)"
    }

function Log {
    param([string]$msg, [string]$Level = 'Info')

    if (-not $global:LastTimestamp -or ((Get-Date) - $global:LastTimestamp).TotalMilliseconds -gt 100) {
        $global:CachedTimestamp = [DateTime]::Now.ToString('HH:mm:ss')
        $global:LastTimestamp = Get-Date
    }

    $logMessage = "[$global:CachedTimestamp] [$Level] $msg"

    # Enhanced categorization and history tracking
    $category = Get-LogCategory -Message $msg
    Add-LogToHistory -Message $msg -Level $Level -Category $category

    # Periodic log file optimization
    if ((Get-Random -Maximum 100) -eq 1) {  # 1% chance per log entry
        Optimize-LogFile -MaxSizeMB 10
    }

    # Enhanced activity logging with persistent file logging and administrator mode awareness
        $logFilePath = Join-Path $ScriptRoot 'Koala-Activity.log'

        # Additional reliability check: ensure directory exists
        $logDir = Split-Path $logFilePath -Parent
        if (-not (Test-Path $logDir)) {
            New-Item -Path $logDir -ItemType Directory -Force -ErrorAction Stop | Out-Null

        }

        # Enhanced file writing with retry mechanism
        $maxRetries = 3
        $retryCount = 0
        $success = $false

        while (-not $success -and $retryCount -lt $maxRetries) {
                # Enhanced log entry with category information
                $enhancedLogMessage = "[$global:CachedTimestamp] [$Level] [$category] $msg"
                Add-Content -Path $logFilePath -Value $enhancedLogMessage -Encoding UTF8 -ErrorAction Stop
                $success = $true
                $retryCount++
                if ($retryCount -lt $maxRetries) {
                    Start-Sleep -Milliseconds 100
                } else {
                    throw
                }
            }

        # Verify file write was successful for critical operations
        if ($Level -eq 'Error' -or $Level -eq 'Warning') {
            $lastLine = Get-Content $logFilePath -Tail 1 -ErrorAction SilentlyContinue
            if ($lastLine -notmatch [regex]::Escape($msg)) {
                throw "File verification failed - log entry may not have been written"
            }
        }

        # Enhanced context logging for comprehensive user action tracking
        if ($msg -match "Theme|Game|Mode|Optimization|Service|System|Network|Settings|Backup|Import|Export|Search") {
                $adminStatus = if (Get-Command Test-AdminPrivileges -ErrorAction SilentlyContinue) { Test-AdminPrivileges } else { "Unknown" }
                $contextMessage = "[$global:CachedTimestamp] [Context] [$category] User action '$($msg.Split(' ')[0])' in $global:MenuMode mode with Admin: $adminStatus"
                Add-Content -Path $logFilePath -Value $contextMessage -Encoding UTF8 -ErrorAction SilentlyContinue

                # Add to history as well
                Add-LogToHistory -Message "User action '$($msg.Split(' ')[0])' in $global:MenuMode mode with Admin: $adminStatus" -Level "Context" -Category $category
                # Ignore context logging errors to prevent circular issues
            }

        # Additional validation logging for critical operations
        if ($Level -eq 'Error') {
                $errorContext = "[$global:CachedTimestamp] [ErrorContext] [$category] PowerShell: $($PSVersionTable.PSVersion), OS: $(if ($IsWindows -ne $null) { if ($IsWindows) {'Windows'} else {'Non-Windows'} } else {'Windows Legacy'})"
                Add-Content -Path $logFilePath -Value $errorContext -Encoding UTF8 -ErrorAction SilentlyContinue

                # Add to history as well
                Add-LogToHistory -Message "PowerShell: $($PSVersionTable.PSVersion), OS: $(if ($IsWindows -ne $null) { if ($IsWindows) {'Windows'} else {'Non-Windows'} } else {'Windows Legacy'})" -Level "ErrorContext" -Category $category
                # Ignore additional context logging errors
            }

        # Enhanced error reporting for administrator mode and permission issues
        $errorContext = ""
        if ($_.Exception.Message -match "Access.*denied|UnauthorizedAccess") {
            $errorContext = " (Insufficient permissions - try running as Administrator)"
        } elseif ($_.Exception.Message -match "path.*not found|DirectoryNotFound") {
            $errorContext = " (Directory access issue - check script location)"
            $errorContext = " (File in use - another instance may be running)"

        # Fallback to console with enhanced error context
        Write-Host "LOG FILE ERROR: $($_.Exception.Message)$errorContext" -ForegroundColor Red
        Write-Host $logMessage -ForegroundColor $(Get-LogColor $Level)

    if ($global:LogBox -and $global:LogBoxAvailable) {
        # Use Dispatcher.Invoke instead of BeginInvoke for more reliable UI updates
        try {
            $global:LogBox.Dispatcher.Invoke({
                try {
                    # Check if LogBox is still accessible
                    if ($global:LogBox -and $global:LogBox.IsEnabled -ne $null) {
                        $global:LogBox.AppendText("$logMessage`r`n")
                        $global:LogBox.ScrollToEnd()

                        # Maintain detailed log backup for toggle functionality
                        if (-not $global:DetailedLogBackup) {
                            $global:DetailedLogBackup = ""
                        }
                        $global:DetailedLogBackup += "$logMessage`r`n"

                        # If in compact mode, apply filtering
                        if ($global:LogViewDetailed -eq $false) {
                            if ($msg -match "Success|Error|Warning|Applied|Optimization") {
                                # Important messages are shown in compact view

                            } else {
                                # Hide non-essential messages in compact view
                                $currentText = $global:LogBox.Text
                                $lines = $currentText -split "`r`n"
                                $filteredLines = $lines | Where-Object {
                                    $_ -match "Success|Error|Warning|Applied|Optimization"
                                } | Select-Object -Last 20
                                $global:LogBox.Text = ($filteredLines -join "`r`n")
                            }
                        }

                        # Force immediate UI update to ensure text appears
                        $global:LogBox.InvalidateVisual()
                        $global:LogBox.UpdateLayout()

                        # Process pending UI operations
                        if ([System.Windows.Threading.Dispatcher]::CurrentDispatcher) {
                            [System.Windows.Threading.Dispatcher]::CurrentDispatcher.Invoke({}, [System.Windows.Threading.DispatcherPriority]::Render)
                        }
                    } else {
                        throw [System.InvalidOperationException]::new("LogBox is unavailable")
                    }
            } catch {
                $global:LogBoxAvailable = $false
                Write-Host $logMessage -ForegroundColor $(Get-LogColor $Level)
                Log "LogBox UI became unavailable: $($_.Exception.Message)" 'Warning'
            }
            })
        } catch {
            $global:LogBoxAvailable = $false
            Write-Host $logMessage -ForegroundColor $(Get-LogColor $Level)
            Log "LogBox UI became unavailable: $($_.Exception.Message)" 'Warning'
        }
    } else {
        Write-Host $logMessage -ForegroundColor $(Get-LogColor $Level)
    }

# ---------- Essential Helper Functions (moved to top to fix call order) ----------
function Test-AdminPrivileges {
    if (-not $script:IsWindowsPlatform) {
        return $false
    }

        $id = [Security.Principal.WindowsIdentity]::GetCurrent()
        if (-not $id) {
            return $false

        }

        $principal = New-Object Security.Principal.WindowsPrincipal($id)
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        $warningMessage = 'Admin privilege detection unavailable: {0}' -f $_.Exception.Message
        Log $warningMessage 'Warning'
        return $false
    }

function Get-SafeConfigPath {
    param([string]$Filename)

    if ($global:CustomConfigPath) {
        return Join-Path $global:CustomConfigPath $Filename
    }

    # Check if current path is system32 or other sensitive location
    $currentPath = if ($ScriptRoot) { $ScriptRoot } else { (Get-Location).Path }
    $isAdmin = Test-AdminPrivileges

    if ($isAdmin -and ($currentPath -match "system32|windows|program files" -or $currentPath.Length -lt 10)) {
        if (-not $script:SafeConfigDirectory) {
            $documentsRoot = try { [Environment]::GetFolderPath('MyDocuments') } catch { $null }
            if ([string]::IsNullOrWhiteSpace($documentsRoot)) {
                $documentsRoot = Join-Path $env:USERPROFILE 'Documents'
            }

            $script:SafeConfigDirectory = Join-Path $documentsRoot 'KOALA Gaming Optimizer'
        }

        if (-not $script:HasWarnedUnsafeConfigPath) {
            Log "Admin mode detected with unsafe path ($currentPath) - using user documents folder" 'Warning'
            $script:HasWarnedUnsafeConfigPath = $true
        }

        if (-not (Test-Path $script:SafeConfigDirectory)) {
                New-Item -ItemType Directory -Path $script:SafeConfigDirectory -Force | Out-Null
                Log "Created safe configuration directory: $script:SafeConfigDirectory" 'Info'
                Log "Failed to create safe configuration directory: $script:SafeConfigDirectory - $($_.Exception.Message)" 'Warning'
            }
        }

        return Join-Path $script:SafeConfigDirectory $Filename
    }

    return Join-Path $currentPath $Filename

# Initialize paths after function definition
$BackupPath = Get-SafeConfigPath 'Koala-Backup.json'
$ConfigPath = Get-SafeConfigPath 'Koala-Config.json'

# ---------- Control Validation Function ----------
function Test-StartupControls {
    <#
    .SYNOPSIS
    Validates all critical UI controls are properly bound and logs missing controls
    #>

    $criticalControls = @{
        # Navigation controls
        'btnNavDashboard' = $btnNavDashboard
        'btnNavBasicOpt' = $btnNavBasicOpt
        'btnNavAdvanced' = $btnNavAdvanced
        'btnNavGames' = $btnNavGames
        'btnNavOptions' = $btnNavOptions
        'btnNavBackup' = $btnNavBackup
        'btnNavLog' = $btnNavLog

        # Panels
        'panelDashboard' = $panelDashboard
        'panelBasicOpt' = $panelBasicOpt
        'panelAdvanced' = $panelAdvanced
        'panelGames' = $panelGames
        'panelOptions' = $panelOptions
        'panelBackup' = $panelBackup
        'panelLog' = $panelLog
        'btnAdvancedNetwork' = $btnAdvancedNetwork
        'btnAdvancedSystem' = $btnAdvancedSystem
        'btnAdvancedServices' = $btnAdvancedServices

        # Critical buttons mentioned in problem statement
        'btnInstalledGames' = $btnInstalledGames
        'btnSaveSettings' = $btnSaveSettings
        'btnLoadSettings' = $btnLoadSettings
        'btnResetSettings' = $btnResetSettings
        'btnSearchGames' = $btnSearchGames
        'btnAddGameFolder' = $btnAddGameFolder
        'btnCustomSearch' = $btnCustomSearch
        'btnInstalledGamesDash' = $btnInstalledGamesDash
        'btnSearchGamesPanel' = $btnSearchGamesPanel
        'btnAddGameFolderPanel' = $btnAddGameFolderPanel
        'btnCustomSearchPanel' = $btnCustomSearchPanel
        'btnAddGameFolderDash' = $btnAddGameFolderDash
        'btnCustomSearchDash' = $btnCustomSearchDash
        'btnOptimizeSelected' = $btnOptimizeSelected
        'btnImportOptions' = $btnImportOptions
        'btnChooseBackupFolder' = $btnChooseBackupFolder
        'cmbOptionsLanguage' = $cmbOptionsLanguage

        # System optimization and service management controls
        'btnOptimizeGame' = $btnOptimizeGame
        'btnDashQuickOptimize' = $btnDashQuickOptimize
        'btnBasicSystem' = $btnBasicSystem
        'btnBasicNetwork' = $btnBasicNetwork
        'btnBasicGaming' = $btnBasicGaming
        'btnSystemInfo' = $btnSystemInfo
        'expanderServices' = $expanderServices
        'expanderNetworkTweaks' = $expanderNetworkTweaks
        'expanderSystemOptimizations' = $expanderSystemOptimizations
        'expanderServiceManagement' = $expanderServiceManagement

        # Checkboxes for optimizations
        'chkAutoOptimize' = $chkAutoOptimize
        'chkDashAutoOptimize' = $chkDashAutoOptimize
        'chkGameDVR' = $chkGameDVR
        'chkFullscreenOptimizations' = $chkFullscreenOptimizations
        'chkGPUScheduling' = $chkGPUScheduling
        'chkTimerResolution' = $chkTimerResolution
        'chkGameMode' = $chkGameMode
        'chkMPO' = $chkMPO
        'chkGameDVRSystem' = $chkGameDVRSystem
        'chkGPUSchedulingSystem' = $chkGPUSchedulingSystem
        'chkFullscreenOptimizationsSystem' = $chkFullscreenOptimizationsSystem
        'chkTimerResolutionSystem' = $chkTimerResolutionSystem
        'chkGameModeSystem' = $chkGameModeSystem
        'chkMPOSystem' = $chkMPOSystem

        # Logging
        'LogBox' = $global:LogBox
    }

    $missingControls = @()
    $availableControls = @()

    foreach ($controlName in $criticalControls.Keys) {
        $control = $criticalControls[$controlName]
        if ($control -eq $null) {
            $missingControls += $controlName
            Log "MISSING CONTROL: $controlName is null - event handlers will be skipped" 'Warning'
        } else {
            $availableControls += $controlName
        }
    }

    # Log startup summary
    Log "STARTUP CONTROL VALIDATION COMPLETE" 'Info'
    Log "Available controls: $($availableControls.Count)/$($criticalControls.Count)" 'Info'

    if ($missingControls.Count -gt 0) {
        Log "MISSING CONTROLS DETECTED: $($missingControls.Count) controls not found" 'Warning'
        Log "Missing controls: $($missingControls -join ', ')" 'Warning'
        Log "Suggestions for fixing missing controls:" 'Info'

        foreach ($missing in $missingControls) {
            switch -Wildcard ($missing) {
                'btn*' { Log "  * Add <Button x:Name=`"$missing`" .../> to XAML" 'Info' }
                'chk*' { Log "  * Add <CheckBox x:Name=`"$missing`" .../> to XAML" 'Info' }
                'panel*' { Log "  * Add <StackPanel x:Name=`"$missing`" .../> to XAML" 'Info' }
                'LogBox' { Log "  * Add <TextBox x:Name=`"LogBox`" .../> to XAML for logging" 'Info' }
                'expanderServices' { Log "  * Add <Expander x:Name=`"expanderServices`" Header=`"Service Management`" .../> to XAML" 'Info' }
                'btnSystemInfo' { Log "  * Add <Button x:Name=`"btnSystemInfo`" Content=`"System Info`" .../> for system information" 'Info' }
                '*Optimize*' { Log "  * Add <Button x:Name=`"$missing`" .../> for optimization functionality" 'Info' }
                default { Log "  * Add control with x:Name=`"$missing`" to XAML" 'Info' }
            }
        }

        # Provide UI feedback but do not block startup
            $message = "⚠️ STARTUP VALIDATION: $($missingControls.Count) UI controls are missing.`n`nMissing: $($missingControls -join ', ')`n`nThe application will continue to run, but some features may not work properly.`n`nCheck the Activity Log for detailed fix suggestions."

            # Only show message box if WPF is available
            if ([System.Windows.MessageBox] -and $form) {
                [System.Windows.MessageBox]::Show($message, "Startup Control Validation", 'OK', 'Warning')

            } else {
                Log "UI feedback not available - continuing with console logging only" 'Info'
            }
            Log "Could not display UI feedback for missing controls: $($_.Exception.Message)" 'Warning'

        return $false
        Log "[OK] All critical controls found and bound successfully" 'Success'
        return $true
$SettingsPath = Get-SafeConfigPath 'koala-settings.cfg'

# ---------- UI Cloning and Mirroring Helpers (moved forward for availability) ----------
function Clone-UIElement {
    param(
        [Parameter(Mandatory = $true)]
        [System.Windows.UIElement]
        $Element
    )

        $xaml = [System.Windows.Markup.XamlWriter]::Save($Element)
        $stringReader = New-Object System.IO.StringReader $xaml
        $xmlReader = [System.Xml.XmlReader]::Create($stringReader)
        $clone = [Windows.Markup.XamlReader]::Load($xmlReader)
        $xmlReader.Close()
        $stringReader.Close()
        return $clone
        Write-Verbose "Clone-UIElement failed: $($_.Exception.Message)"
        return $null
    }

function Copy-TagValue {
    param($Value)

    if (-not $Value) { return $Value }

    if ($Value -is [System.Management.Automation.PSObject]) {
        $hashtable = [ordered]@{}
        foreach ($property in $Value.PSObject.Properties) {
            $hashtable[$property.Name] = $property.Value
        }
        return [PSCustomObject]$hashtable
    }

    return $Value
}

function New-ClonedTextBlock {
    param([System.Windows.Controls.TextBlock]$Source)

    $clone = New-Object System.Windows.Controls.TextBlock
    try { $clone.Text = $Source.Text } catch { }
    try { if ($Source.Foreground) { $clone.Foreground = $Source.Foreground.Clone() } } catch { }
    try { $clone.FontStyle = $Source.FontStyle } catch { }
    try { $clone.FontWeight = $Source.FontWeight } catch { }
    try { $clone.FontSize = $Source.FontSize } catch { }
    try { $clone.Margin = $Source.Margin } catch { }
    try { $clone.HorizontalAlignment = $Source.HorizontalAlignment } catch { }
    try { $clone.TextWrapping = $Source.TextWrapping } catch { }
    try { $clone.FontFamily = $Source.FontFamily } catch { }
    try { $clone.TextAlignment = $Source.TextAlignment } catch { }
    return $clone
}

function New-ClonedCheckBox {
    param([System.Windows.Controls.CheckBox]$Source)

    $clone = New-Object System.Windows.Controls.CheckBox
    try { $clone.Content = $Source.Content } catch { }
    try { if ($Source.Foreground) { $clone.Foreground = $Source.Foreground.Clone() } } catch { }
    try { $clone.FontWeight = $Source.FontWeight } catch { }
    try { $clone.FontSize = $Source.FontSize } catch { }
    try { $clone.Margin = $Source.Margin } catch { }
    try { $clone.Padding = $Source.Padding } catch { }
    try { $clone.HorizontalAlignment = $Source.HorizontalAlignment } catch { }
    try { $clone.IsChecked = $Source.IsChecked } catch { }
    try { $clone.ToolTip = $Source.ToolTip } catch { }

        $clone.Tag = Copy-TagValue -Value $Source.Tag
    } catch {
        Write-Verbose "Failed to copy checkbox Tag value: $($_.Exception.Message)"

    return $clone

function Copy-ChildElement {
    param([System.Windows.UIElement]$Source)

    if (-not $Source) { return $null }

    $typeName = $Source.GetType().Name

    switch ($typeName) {
        'TextBlock' { return New-ClonedTextBlock -Source $Source }
        'CheckBox'  { return New-ClonedCheckBox -Source $Source }
        'StackPanel' {
            $stackClone = New-Object System.Windows.Controls.StackPanel
            try { $stackClone.Orientation = $Source.Orientation } catch { }
            try { $stackClone.Margin = $Source.Margin } catch { }

            foreach ($child in $Source.Children) {
                $clonedChild = Copy-ChildElement -Source $child
                if ($clonedChild) {
                    $stackClone.Children.Add($clonedChild)
                }
            }

            return $stackClone
        }
        default { return Clone-UIElement -Element $Source }
    }
}

function Update-GameListMirrors {
    if (-not $script:PrimaryGameListPanel -or -not $script:DashboardGameListPanel) { return }

        $script:DashboardGameListPanel.Children.Clear()
        foreach ($child in $script:PrimaryGameListPanel.Children) {
            if ($child -is [System.Windows.Controls.TextBlock]) {
                $clonedText = New-ClonedTextBlock -Source $child
                if ($clonedText) { $script:DashboardGameListPanel.Children.Add($clonedText) }
                continue

            }

            if ($child -is [System.Windows.Controls.Border]) {
                $borderClone = New-Object System.Windows.Controls.Border
                try { $borderClone.Background = if ($child.Background) { $child.Background.Clone() } else { $null } } catch { }
                try { $borderClone.BorderBrush = if ($child.BorderBrush) { $child.BorderBrush.Clone() } else { $null } } catch { }
                try { $borderClone.BorderThickness = $child.BorderThickness } catch { }
                try { $borderClone.CornerRadius = $child.CornerRadius } catch { }
                try { $borderClone.Margin = $child.Margin } catch { }
                try { $borderClone.Padding = $child.Padding } catch { }

                if ($child.Child) {
                    $clonedChild = Copy-ChildElement -Source $child.Child
                    if ($clonedChild) { $borderClone.Child = $clonedChild }
                }

                $script:DashboardGameListPanel.Children.Add($borderClone)
                continue
            }

            $fallback = Clone-UIElement -Element $child
            if ($fallback) {
                $script:DashboardGameListPanel.Children.Add($fallback)
            }
        }
        Write-Verbose "Update-GameListMirrors failed: $($_.Exception.Message)"
    }

# Resolve a color-like value (string, brush, PSObject) to a usable color string.
function Get-ColorStringFromValue {
    param([object]$ColorValue)

    if ($null -eq $ColorValue) { return $null }

    if ($ColorValue -is [string]) { return $ColorValue }

    if ($ColorValue -is [System.Windows.Media.Color]) {
        return $ColorValue.ToString()
    }

    if ($ColorValue -is [System.Windows.Media.Brush]) {
        try { return $ColorValue.ToString() } catch { return $null }
    }

    if ($ColorValue -is [System.Management.Automation.PSObject]) {
        foreach ($propName in 'Brush','Color','Value','Hex','Text','Background','Primary') {
            if ($ColorValue.PSObject.Properties[$propName]) {
                $resolved = Get-ColorStringFromValue $ColorValue.$propName
                if (-not [string]::IsNullOrWhiteSpace($resolved)) { return $resolved }
            }
        }

        if ($ColorValue.PSObject.BaseObject -ne $ColorValue) {
            $resolved = Get-ColorStringFromValue $ColorValue.PSObject.BaseObject
            if (-not [string]::IsNullOrWhiteSpace($resolved)) { return $resolved }
        }

        try { return $ColorValue.ToString() } catch { return $null }
    }

    if ($ColorValue -is [System.Collections.IDictionary]) {
        foreach ($propName in 'Brush','Color','Value','Hex','Text','Background','Primary') {
            if ($ColorValue.Contains($propName)) {
                $resolved = Get-ColorStringFromValue $ColorValue[$propName]
                if (-not [string]::IsNullOrWhiteSpace($resolved)) { return $resolved }
            }
        }
    }

    if ($ColorValue -is [System.Array]) {
        $length = $ColorValue.Length
        if ($length -eq 4) {
            $bytes = @()
            foreach ($item in $ColorValue) { $bytes += [byte]$item }
            $color = [System.Windows.Media.Color]::FromArgb($bytes[0], $bytes[1], $bytes[2], $bytes[3])
            return $color.ToString()
        } elseif ($length -eq 3) {
            $bytes = @()
            foreach ($item in $ColorValue) { $bytes += [byte]$item }
            $color = [System.Windows.Media.Color]::FromRgb($bytes[0], $bytes[1], $bytes[2])
            return $color.ToString()
        }
    }

    if ($ColorValue -is [System.ValueType]) {
        return $ColorValue.ToString()
    }

    try { return [string]$ColorValue } catch { return $null }

# Normalize theme tables so color values resolve to reusable brush instances.
function Normalize-ThemeColorTable {
    param([hashtable]$Theme)

    if (-not $Theme) { return $Theme }

    foreach ($key in @($Theme.Keys)) {
        $value = $Theme[$key]

        if ($null -eq $value) { continue }

        if ($value -is [string]) {
            $stringBrush = $null
                $stringBrush = New-SolidColorBrushSafe $value
                $stringBrush = $null
            }

            if ($stringBrush -is [System.Windows.Media.Brush]) {
                $Theme[$key] = $stringBrush
                continue
            }

            continue
        }

        if ($value -is [bool]) { continue }
        if ($value -is [System.Windows.Media.Brush]) {
                if ($value -is [System.Windows.Freezable] -and -not $value.IsFrozen) {
                    $value.Freeze()

                }
                Write-Verbose "Normalize-ThemeColorTable: Failed to freeze brush for key '$key'"
            }
            continue
        }
        if ($value -is [int] -or $value -is [double] -or $value -is [decimal]) { continue }

        $resolved = Get-ColorStringFromValue $value
        if (-not [string]::IsNullOrWhiteSpace($resolved)) {
            $Theme[$key] = $resolved
        }

    return $Theme

# Creates a cloneable brush instance from a variety of incoming values.
function Resolve-BrushInstance {
    param([object]$BrushCandidate)

    if ($null -eq $BrushCandidate) { return $null }

    $current = $BrushCandidate
    $previous = $null

    while ($current -is [System.Management.Automation.PSObject] -and $current -ne $previous) {
        $previous = $current
        $current = $current.PSObject.BaseObject
    }

    if ($current -is [System.Windows.Media.Brush]) {
            $clone = if ($current -is [System.Windows.Freezable]) { $current.Clone() } else { $current }
            if ($clone -is [System.Windows.Freezable] -and -not $clone.IsFrozen) {
                try { $clone.Freeze() } catch { }

            }
            return $clone
        } catch {
            return $current
        }

    return $null

# Creates a frozen SolidColorBrush from a color-like value when possible.
function New-SolidColorBrushSafe {
    param([Parameter(ValueFromPipeline = $true)][object]$ColorValue)

    if ($null -eq $ColorValue) { return $null }

    $existingBrush = Resolve-BrushInstance $ColorValue
    if ($existingBrush -is [System.Windows.Media.SolidColorBrush]) {
        return $existingBrush
    }

    if ($existingBrush -is [System.Windows.Media.Brush]) {
            $colorText = $existingBrush.ToString()
            if (-not [string]::IsNullOrWhiteSpace($colorText)) {
                $colorCandidate = [System.Windows.Media.ColorConverter]::ConvertFromString($colorText)
                if ($colorCandidate -is [System.Windows.Media.Color]) {
                    $fromBrush = New-Object System.Windows.Media.SolidColorBrush $colorCandidate
                    $fromBrush.Freeze()
                    return $fromBrush

                }
            }
            Write-Verbose "Failed to coerce brush value '$existingBrush' to SolidColorBrush: $($_.Exception.Message)"
        }
    }

    if ($ColorValue -is [System.Windows.Media.Color]) {
        $brushFromColor = New-Object System.Windows.Media.SolidColorBrush $ColorValue
        $brushFromColor.Freeze()
        return $brushFromColor
    }

    $resolvedValue = Get-ColorStringFromValue $ColorValue
    if ([string]::IsNullOrWhiteSpace($resolvedValue)) { return $null }

    $converter = Get-SharedBrushConverter
    if ($converter) {
            $converted = $converter.ConvertFromString($resolvedValue)
            $convertedBrush = Resolve-BrushInstance $converted
            if ($convertedBrush -is [System.Windows.Media.SolidColorBrush]) {
                return $convertedBrush

            }
            Write-Verbose "BrushConverter could not convert '$resolvedValue' to SolidColorBrush: $($_.Exception.Message)"
        }

        $color = [System.Windows.Media.ColorConverter]::ConvertFromString($resolvedValue)
        if ($color -is [System.Windows.Media.Color]) {
            $brush = New-Object System.Windows.Media.SolidColorBrush $color
            $brush.Freeze()
            return $brush

        }
        Write-Verbose "Failed to convert '$resolvedValue' to SolidColorBrush: $($_.Exception.Message)"

    return $null

function Get-SharedBrushConverter {
    if (-not $script:SharedBrushConverter -or $script:SharedBrushConverter.GetType().FullName -ne 'System.Windows.Media.BrushConverter') {
            $script:SharedBrushConverter = [System.Windows.Media.BrushConverter]::new()
            $script:SharedBrushConverter = $null
        }
    }

    return $script:SharedBrushConverter

function Set-ShapeFillSafe {
    param(
        [object]$Shape,
        [object]$Value
    )

    if (-not $Shape) { return }

        Set-BrushPropertySafe -Target $Shape -Property 'Fill' -Value $Value -AllowTransparentFallback
        Write-Verbose "Set-ShapeFillSafe failed: $($_.Exception.Message)"
    }

# Centralized helper to assign Brush-like theme values to WPF dependency properties.
function Set-BrushPropertySafe {
    param(
        [Parameter(Mandatory = $true)][object]$Target,
        [Parameter(Mandatory = $true)][string]$Property,
        [object]$Value,
        [switch]$AllowTransparentFallback
    )

    if (-not $Target) { return }
    if ([string]::IsNullOrWhiteSpace($Property)) { return }

        $resolvedValue = $Value
        $previousValue = $null
        while ($resolvedValue -is [System.Management.Automation.PSObject] -and $resolvedValue -ne $previousValue) {
            $previousValue = $resolvedValue
            $resolvedValue = $resolvedValue.PSObject.BaseObject

        }

        $brush = Resolve-BrushInstance $resolvedValue
        if (-not $brush) {
            $brush = New-SolidColorBrushSafe $resolvedValue
        }
        $previousBrush = $null
        while ($brush -is [System.Management.Automation.PSObject] -and $brush -ne $previousBrush) {
            $previousBrush = $brush
            $brush = $brush.PSObject.BaseObject
        }

        if ($brush -is [System.Windows.Media.Brush]) {
            if ($brush -is [System.Windows.Freezable] -and $brush.IsFrozen) {
                $Target.$Property = $brush.Clone()
            } else {
                $Target.$Property = $brush
            }
            return
        }

        $colorValue = Get-ColorStringFromValue $resolvedValue
        $previousColor = $null
        while ($colorValue -is [System.Management.Automation.PSObject] -and $colorValue -ne $previousColor) {
            $previousColor = $colorValue
            $colorValue = $colorValue.PSObject.BaseObject
        }

        $colorString = $null
        if ($null -ne $colorValue) {
            if ($colorValue -is [string]) {
                $colorString = $colorValue
            } else {
                try { $colorString = [string]$colorValue } catch { $colorString = $null }
            }

        if (-not [string]::IsNullOrWhiteSpace($colorString)) {
            $converter = Get-SharedBrushConverter
            if ($converter) {
                    $converted = $converter.ConvertFromString($colorString)
                    $convertedBrush = Resolve-BrushInstance $converted
                    if (-not $convertedBrush) {
                        $convertedBrush = New-SolidColorBrushSafe $converted

                    }

                    if ($convertedBrush -is [System.Windows.Media.Brush]) {
                        if ($convertedBrush -is [System.Windows.Freezable] -and $convertedBrush.IsFrozen) {
                            $Target.$Property = $convertedBrush.Clone()
                        } else {
                            $Target.$Property = $convertedBrush
                        }
                        return
                    }
                    Write-Verbose "BrushConverter fallback for property '$Property' failed: $($_.Exception.Message)"
                }

            $fallbackBrush = New-SolidColorBrushSafe $colorString
            if ($fallbackBrush -is [System.Windows.Media.Brush]) {
                if ($fallbackBrush -is [System.Windows.Freezable] -and $fallbackBrush.IsFrozen) {
                    $Target.$Property = $fallbackBrush.Clone()
                } else {
                    $Target.$Property = $fallbackBrush
                }
                return

        if ($AllowTransparentFallback) {
            $transparentBrush = [System.Windows.Media.Brushes]::Transparent
            if ($transparentBrush -is [System.Windows.Freezable] -and $transparentBrush.IsFrozen) {
                $Target.$Property = $transparentBrush.Clone()
            } else {
                $Target.$Property = $transparentBrush
            }
            try { $Target.$Property = $null } catch { }
        Write-Verbose "Set-BrushPropertySafe failed for property '$Property' on $($Target.GetType().Name): $($_.Exception.Message)"

function Convert-ToBrushResource {
    param(
        [object]$Value,
        [switch]$AllowTransparentFallback
    )

    if ($null -eq $Value) { return $null }

    $probe = New-Object System.Windows.Controls.Border

        if ($AllowTransparentFallback) {
            Set-BrushPropertySafe -Target $probe -Property 'Background' -Value $Value -AllowTransparentFallback

        } else {
            Set-BrushPropertySafe -Target $probe -Property 'Background' -Value $Value
        }
        return $null

    $result = $probe.Background
    if ($null -eq $result) { return $null }

    if ($result -is [System.Windows.Freezable]) {
            $clone = $result.Clone()
            if ($clone -is [System.Windows.Freezable] -and -not $clone.IsFrozen) {
                try { $clone.Freeze() } catch { }

            }
            return $clone
        } catch {
            return $result

    return $result

function Normalize-BrushResources {
    param(
        [System.Windows.ResourceDictionary]$Resources,
        [string[]]$Keys,
        [switch]$AllowTransparentFallback
    )

    if (-not $Resources) { return }

    $targetKeys = @()
    if ($Keys -and $Keys.Count -gt 0) {
        $targetKeys = $Keys
    } else {
        $targetKeys = @($Resources.Keys)
    }

    foreach ($key in $targetKeys) {
        if (-not $Resources.Contains($key)) { continue }

        $resourceValue = $Resources[$key]
        if ($resourceValue -is [System.Windows.Media.Brush]) { continue }

        if ($AllowTransparentFallback) {
            $normalizedBrush = Convert-ToBrushResource -Value $resourceValue -AllowTransparentFallback
        } else {
            $normalizedBrush = Convert-ToBrushResource -Value $resourceValue
        }

        if ($normalizedBrush -is [System.Windows.Media.Brush]) {
            $Resources[$key] = $normalizedBrush
            continue
        }

        if ($AllowTransparentFallback) {
            $Resources[$key] = [System.Windows.Media.Brushes]::Transparent
        } else {
            Write-Verbose "Normalize-BrushResources skipped '$key' due to unresolved brush value"

function Normalize-ElementBrushProperties {
    param([System.Windows.DependencyObject]$Element)

    if ($null -eq $Element) { return }

    $brushPropertyNames = @(
        'Background',
        'Foreground',
        'BorderBrush',
        'SelectionBrush',
        'CaretBrush',
        'Stroke',
        'Fill',
        'OpacityMask',
        'SelectionForeground',
        'HighlightBrush'
    )

    foreach ($propertyName in $brushPropertyNames) {
            $propertyInfo = $Element.GetType().GetProperty($propertyName)
            $propertyInfo = $null
        }

        if (-not $propertyInfo -or -not $propertyInfo.CanRead -or -not $propertyInfo.CanWrite) { continue }

            $currentValue = $propertyInfo.GetValue($Element, $null)
            continue
        }

        if ($null -eq $currentValue) { continue }
        if ($currentValue -is [System.Windows.Media.Brush]) { continue }

        Set-BrushPropertySafe -Target $Element -Property $propertyName -Value $currentValue -AllowTransparentFallback

function Normalize-VisualTreeBrushes {
    param([System.Windows.DependencyObject]$Root)

    if ($null -eq $Root) { return }

    $visited = New-Object 'System.Collections.Generic.HashSet[int]'
    $stack = New-Object System.Collections.Stack
    $stack.Push($Root)

    while ($stack.Count -gt 0) {
        $current = $stack.Pop()

        if ($current -isnot [System.Windows.DependencyObject]) { continue }

            $hash = [System.Runtime.CompilerServices.RuntimeHelpers]::GetHashCode($current)
            continue
        }

        if (-not $visited.Add($hash)) { continue }

        Normalize-ElementBrushProperties -Element $current

        $childCount = 0
            $childCount = [System.Windows.Media.VisualTreeHelper]::GetChildrenCount($current)
            $childCount = 0
        }

        for ($i = 0; $i -lt $childCount; $i++) {
            $child = $null
            try { $child = [System.Windows.Media.VisualTreeHelper]::GetChild($current, $i) } catch { $child = $null }
            if ($child) { $stack.Push($child) }
        }

            foreach ($logicalChild in [System.Windows.LogicalTreeHelper]::GetChildren($current)) {
                if ($logicalChild -is [System.Windows.DependencyObject]) {
                    $stack.Push($logicalChild)

                }
            }

# ---------- Theme and Styling Helpers (moved forward for availability) ----------
function Find-AllControlsOfType {
    param(
        $Parent,
        [object]$ControlType,
        [ref]$Collection
    )

    if (-not $Parent) { return }

    if ($ControlType -isnot [Type]) {
        $typeName = $null
        if ($ControlType -is [string]) {
            $typeName = $ControlType.Trim()
            if ($typeName.StartsWith('[') -and $typeName.EndsWith(']')) {
                $typeName = $typeName.Trim('[', ']')
            }
        } elseif ($ControlType) {
            $typeName = $ControlType.ToString()
        }

        if ($typeName) {
            $resolvedType = $null
            try { $resolvedType = [Type]::GetType($typeName, $false) } catch { }
            if (-not $resolvedType) {
                switch ($typeName) {
                    'System.Windows.Controls.Button' { $resolvedType = [System.Windows.Controls.Button] }
                    'System.Windows.Controls.ComboBox' { $resolvedType = [System.Windows.Controls.ComboBox] }
                    'System.Windows.Controls.TextBlock' { $resolvedType = [System.Windows.Controls.TextBlock] }
                    'System.Windows.Controls.Label' { $resolvedType = [System.Windows.Controls.Label] }
                    'System.Windows.Controls.Border' { $resolvedType = [System.Windows.Controls.Border] }
                    'System.Windows.Controls.Primitives.ScrollBar' { $resolvedType = [System.Windows.Controls.Primitives.ScrollBar] }
                    default {
                        try { $resolvedType = [Type]::GetType("$typeName, PresentationFramework", $false) } catch { }
                    }
                }
            }

            $ControlType = $resolvedType
        }
    }

    if (-not $ControlType -or $ControlType -isnot [Type]) {
        return
    }

        if ($Parent -is $ControlType) {
            $Collection.Value += $Parent

        }

        if ($Parent.Children) {
            foreach ($child in $Parent.Children) {
                Find-AllControlsOfType -Parent $child -ControlType $ControlType -Collection $Collection
            }
        } elseif ($Parent.Content -and $Parent.Content -is [System.Windows.UIElement]) {
            Find-AllControlsOfType -Parent $Parent.Content -ControlType $ControlType -Collection $Collection
            Find-AllControlsOfType -Parent $Parent.Child -ControlType $ControlType -Collection $Collection
        # Continue searching even if error occurs with specific element

function Set-StackPanelChildSpacing {
    param(
        [System.Windows.Controls.StackPanel]$Panel,
        [double]$Spacing
    )

    if (-not $Panel -or -not $Panel.Children) { return }

    $count = $Panel.Children.Count
    if ($count -le 1) { return }

    for ($index = 0; $index -lt $count; $index++) {
        $child = $Panel.Children[$index]
        if ($child -isnot [System.Windows.FrameworkElement]) { continue }

        $margin = $child.Margin
        if (-not $margin) {
            $margin = [System.Windows.Thickness]::new(0)
        }

        $newMargin = [System.Windows.Thickness]::new($margin.Left, $margin.Top, $margin.Right, $margin.Bottom)

        if ($Panel.Orientation -eq [System.Windows.Controls.Orientation]::Horizontal) {
            $current = $margin.Right
            if ($index -lt $count - 1) {
                if ([math]::Abs($current) -lt 0.01) {
                    $newMargin.Right = $Spacing
                } elseif ($current -lt $Spacing) {
                    $newMargin.Right = $Spacing
                }
            } else {
                if ([math]::Abs($current) -lt 0.01) {
                    $newMargin.Right = 0
                }
            }
        } else {
            $current = $margin.Bottom
            if ($index -lt $count - 1) {
                if ([math]::Abs($current) -lt 0.01) {
                    $newMargin.Bottom = $Spacing
                } elseif ($current -lt $Spacing) {
                    $newMargin.Bottom = $Spacing
                }
                if ([math]::Abs($current) -lt 0.01) {
                    $newMargin.Bottom = 0
                }

        $child.Margin = $newMargin

function Set-GridColumnSpacing {
    param(
        [System.Windows.Controls.Grid]$Grid,
        [double]$Spacing
    )

    if (-not $Grid -or -not $Grid.Children -or $Spacing -le 0) { return }

    foreach ($child in $Grid.Children) {
        if ($child -isnot [System.Windows.FrameworkElement]) { continue }

        $columnIndex = [System.Windows.Controls.Grid]::GetColumn($child)
        if ($columnIndex -le 0) { continue }

        $margin = $child.Margin
        if (-not $margin) {
            $margin = [System.Windows.Thickness]::new(0)
        }

        $newMargin = [System.Windows.Thickness]::new($margin.Left, $margin.Top, $margin.Right, $margin.Bottom)
        if ($newMargin.Left -lt $Spacing) {
            $newMargin.Left = $Spacing
        }

        $child.Margin = $newMargin
    }
}

function Initialize-LayoutSpacing {
    param(
        [System.Windows.DependencyObject]$Root
    )

    if (-not $Root) { return }

    $stackPanels = New-Object System.Collections.ArrayList
    Find-AllControlsOfType -Parent $Root -ControlType ([System.Windows.Controls.StackPanel]) -Collection ([ref]$stackPanels)

    foreach ($panel in $stackPanels) {
        if (-not $panel.Tag) { continue }

        $tagText = $panel.Tag.ToString()
        $match = [regex]::Match($tagText, 'Spacing\s*:\s*(?<value>-?[0-9]+(?:\.[0-9]+)?)')
        if (-not $match.Success) { continue }

        $valueText = $match.Groups['value'].Value
        $spacing = 0.0
        if (-not [double]::TryParse($valueText, [System.Globalization.NumberStyles]::Float, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$spacing)) {
            continue
        }

        Set-StackPanelChildSpacing -Panel $panel -Spacing $spacing
        $panel.Tag = $null
    }

    $grids = New-Object System.Collections.ArrayList
    Find-AllControlsOfType -Parent $Root -ControlType ([System.Windows.Controls.Grid]) -Collection ([ref]$grids)

    foreach ($grid in $grids) {
        if (-not $grid.Tag) { continue }

        $tagText = $grid.Tag.ToString()
        $match = [regex]::Match($tagText, 'ColumnSpacing\s*:\s*(?<value>-?[0-9]+(?:\.[0-9]+)?)')
        if (-not $match.Success) { continue }

        $valueText = $match.Groups['value'].Value
        $spacing = 0.0
        if (-not [double]::TryParse($valueText, [System.Globalization.NumberStyles]::Float, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$spacing)) {
            continue
        }

        Set-GridColumnSpacing -Grid $grid -Spacing $spacing
        $grid.Tag = $null
    }
}

function Get-XamlDuplicateNames {
    param(
        [Parameter(Mandatory = $true)][string]$Xaml
    )

    $pattern = [regex]'\b(?:x:)?Name\s*=\s*"([^"]+)"'
    $occurrences = @()
    $lineNumber = 1

    foreach ($line in $Xaml -split "`r?`n") {
        foreach ($match in $pattern.Matches($line)) {
            $occurrences += [pscustomobject]@{
                Name     = $match.Groups[1].Value
                Line     = $lineNumber
                LineText = $line.Trim()
            }
        }

        $lineNumber++
    }

    return $occurrences |
        Group-Object -Property Name |
        Where-Object { $_.Count -gt 1 } |
        ForEach-Object {
            [pscustomobject]@{
                Name        = $_.Name
                Occurrences = $_.Group
            }
        }
}

function Test-XamlNameUniqueness {
    param(
        [Parameter(Mandatory = $true)][string]$Xaml
    )

    $duplicates = Get-XamlDuplicateNames -Xaml $Xaml
    if (-not $duplicates -or $duplicates.Count -eq 0) {
        return
    }

    Write-Host 'Duplicate x:Name/Name values detected in XAML:' -ForegroundColor Red
    foreach ($duplicate in $duplicates) {
        foreach ($occurrence in $duplicate.Occurrences) {
            $lineInfo = if ($occurrence.Line -gt 0) { "line $($occurrence.Line)" } else { 'unknown line' }
            Write-Host ("  {0} ({1}): {2}" -f $duplicate.Name, $lineInfo, $occurrence.LineText) -ForegroundColor Red
        }
    }

    throw "Duplicate element names detected in XAML content."
}

function Get-XamlDuplicateNames {
    param(
        [Parameter(Mandatory = $true)][string]$Xaml
    )

    $pattern = [regex]'\b(?:x:)?Name\s*=\s*"([^"]+)"'
    $occurrences = @()
    $lineNumber = 1

    foreach ($line in $Xaml -split "`r?`n") {
        foreach ($match in $pattern.Matches($line)) {
            $occurrences += [pscustomobject]@{
                Name     = $match.Groups[1].Value
                Line     = $lineNumber
                LineText = $line.Trim()
            }
        }

        $lineNumber++
    }

    return $occurrences |
        Group-Object -Property Name |
        Where-Object { $_.Count -gt 1 } |
        ForEach-Object {
            [pscustomobject]@{
                Name        = $_.Name
                Occurrences = $_.Group
            }
        }
}

function Test-XamlNameUniqueness {
    param(
        [Parameter(Mandatory = $true)][string]$Xaml
    )

    $duplicates = Get-XamlDuplicateNames -Xaml $Xaml
    if (-not $duplicates -or $duplicates.Count -eq 0) {
        return
    }

    Write-Host 'Duplicate x:Name/Name values detected in XAML:' -ForegroundColor Red
    foreach ($duplicate in $duplicates) {
        foreach ($occurrence in $duplicate.Occurrences) {
            $lineInfo = if ($occurrence.Line -gt 0) { "line $($occurrence.Line)" } else { 'unknown line' }
            Write-Host ("  {0} ({1}): {2}" -f $duplicate.Name, $lineInfo, $occurrence.LineText) -ForegroundColor Red
        }
    }

    throw "Duplicate element names detected in XAML content."
}

function Apply-FallbackThemeColors {
    param(
        [System.Windows.DependencyObject]$Element,
        [hashtable]$Colors
    )

    if (-not $Element -or -not $Colors) {
        return
    }

    try {
        $elementType = $Element.GetType().Name

        switch ($elementType) {
            'Window' {
                if ($Colors.ContainsKey('Background')) {
                    Set-BrushPropertySafe -Target $Element -Property 'Background' -Value $Colors.Background
                }
            }
            'Border' {
                if ($Colors.ContainsKey('Secondary')) {
                    Set-BrushPropertySafe -Target $Element -Property 'Background' -Value $Colors.Secondary
                }
            }
            'TextBlock' {
                if ($Colors.ContainsKey('Text')) {
                    Set-BrushPropertySafe -Target $Element -Property 'Foreground' -Value $Colors.Text
                }
            }
            'Label' {
                if ($Colors.ContainsKey('Text')) {
                    Set-BrushPropertySafe -Target $Element -Property 'Foreground' -Value $Colors.Text
                }
            }
            'Button' {
                if ($Colors.ContainsKey('Primary')) {
                    Set-BrushPropertySafe -Target $Element -Property 'Background' -Value $Colors.Primary
                }
                Set-BrushPropertySafe -Target $Element -Property 'Foreground' -Value 'White'
            }
        }

        if ($Element -is [System.Windows.Controls.Panel]) {
            foreach ($child in $Element.Children) {
                Apply-FallbackThemeColors -Element $child -Colors $Colors
            }
        } elseif ($Element -is [System.Windows.Controls.ContentControl]) {
            $content = $Element.Content
            if ($content -is [System.Windows.DependencyObject]) {
                Apply-FallbackThemeColors -Element $content -Colors $Colors
            }
        } elseif ($Element -is [System.Windows.Controls.Decorator]) {
            if ($Element.Child -is [System.Windows.DependencyObject]) {
                Apply-FallbackThemeColors -Element $Element.Child -Colors $Colors
            }
        }
    } catch {
        Write-Verbose ("Apply-FallbackThemeColors skipped: {0}" -f $_.Exception.Message)
    }

    # Ignore errors in fallback theming to avoid breaking the UI
}

function Update-AllUIElementsRecursively {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Windows.DependencyObject]$Element,
        [Parameter(Mandatory)]
        [hashtable]$Colors
    )

    if (-not $Element -or -not $Colors) {
        return
    }

    $typeName = $Element.GetType().Name

    switch ($typeName) {
        'Window' {
            if ($Colors.ContainsKey('Background')) {
                Set-BrushPropertySafe -Target $Element -Property 'Background' -Value $Colors.Background
            }
            if ($Colors.ContainsKey('Primary') -and $Element.BorderBrush) {
                Set-BrushPropertySafe -Target $Element -Property 'BorderBrush' -Value $Colors.Primary -AllowTransparentFallback
            }
        }
        'Border' {
            if ($Colors.ContainsKey('Secondary')) {
                Set-BrushPropertySafe -Target $Element -Property 'Background' -Value $Colors.Secondary
            } elseif ($Colors.ContainsKey('Background')) {
                Set-BrushPropertySafe -Target $Element -Property 'Background' -Value $Colors.Background -AllowTransparentFallback
            }

            if ($Colors.ContainsKey('Primary')) {
                Set-BrushPropertySafe -Target $Element -Property 'BorderBrush' -Value $Colors.Primary -AllowTransparentFallback
            }
        }
        'GroupBox' {
            if ($Colors.ContainsKey('Secondary')) {
                Set-BrushPropertySafe -Target $Element -Property 'Background' -Value $Colors.Secondary
            }
            if ($Colors.ContainsKey('Text')) {
                Set-BrushPropertySafe -Target $Element -Property 'Foreground' -Value $Colors.Text
            }
            if ($Colors.ContainsKey('Primary')) {
                Set-BrushPropertySafe -Target $Element -Property 'BorderBrush' -Value $Colors.Primary -AllowTransparentFallback
            }
        }
        'StackPanel' {
            if ($Colors.ContainsKey('Secondary')) {
                Set-BrushPropertySafe -Target $Element -Property 'Background' -Value $Colors.Secondary
            } elseif ($Colors.ContainsKey('Background')) {
                Set-BrushPropertySafe -Target $Element -Property 'Background' -Value $Colors.Background -AllowTransparentFallback
            }
        }
        'Grid' {
            if ($Colors.ContainsKey('Secondary')) {
                Set-BrushPropertySafe -Target $Element -Property 'Background' -Value $Colors.Secondary
            } elseif ($Colors.ContainsKey('Background')) {
                Set-BrushPropertySafe -Target $Element -Property 'Background' -Value $Colors.Background -AllowTransparentFallback
            }
        }
        'WrapPanel' {
            if ($Colors.ContainsKey('Secondary')) {
                Set-BrushPropertySafe -Target $Element -Property 'Background' -Value $Colors.Secondary
            } elseif ($Colors.ContainsKey('Background')) {
                Set-BrushPropertySafe -Target $Element -Property 'Background' -Value $Colors.Background -AllowTransparentFallback
            }
        }
        'DockPanel' {
            if ($Colors.ContainsKey('Secondary')) {
                Set-BrushPropertySafe -Target $Element -Property 'Background' -Value $Colors.Secondary
            } elseif ($Colors.ContainsKey('Background')) {
                Set-BrushPropertySafe -Target $Element -Property 'Background' -Value $Colors.Background -AllowTransparentFallback
            }
        }
        'TabControl' {
            if ($Colors.ContainsKey('Background')) {
                Set-BrushPropertySafe -Target $Element -Property 'Background' -Value $Colors.Background
            }
            if ($Colors.ContainsKey('Primary')) {
                Set-BrushPropertySafe -Target $Element -Property 'BorderBrush' -Value $Colors.Primary -AllowTransparentFallback
            }
        }
        'TabItem' {
            if ($Colors.ContainsKey('Secondary')) {
                Set-BrushPropertySafe -Target $Element -Property 'Background' -Value $Colors.Secondary
            }
            if ($Colors.ContainsKey('Text')) {
                Set-BrushPropertySafe -Target $Element -Property 'Foreground' -Value $Colors.Text
            }
            if ($Colors.ContainsKey('Primary')) {
                Set-BrushPropertySafe -Target $Element -Property 'BorderBrush' -Value $Colors.Primary -AllowTransparentFallback
            }
        }
        'Expander' {
            if ($Colors.ContainsKey('Secondary')) {
                Set-BrushPropertySafe -Target $Element -Property 'Background' -Value $Colors.Secondary
            }
            if ($Colors.ContainsKey('Text')) {
                Set-BrushPropertySafe -Target $Element -Property 'Foreground' -Value $Colors.Text
            }
            if ($Element.Header -is [System.Windows.Controls.TextBlock] -and $Colors.ContainsKey('Text')) {
                Set-BrushPropertySafe -Target $Element.Header -Property 'Foreground' -Value $Colors.Text
            }
        }
        'TextBlock' {
            if ($Colors.ContainsKey('Text')) {
                Set-BrushPropertySafe -Target $Element -Property 'Foreground' -Value $Colors.Text
            }
        }
        'Label' {
            if ($Colors.ContainsKey('Text')) {
                Set-BrushPropertySafe -Target $Element -Property 'Foreground' -Value $Colors.Text
            }
            if ($Element.Background -and $Colors.ContainsKey('Secondary')) {
                Set-BrushPropertySafe -Target $Element -Property 'Background' -Value $Colors.Secondary
            }
        }
        'TextBox' {
            if ($Colors.ContainsKey('Secondary')) {
                Set-BrushPropertySafe -Target $Element -Property 'Background' -Value $Colors.Secondary
            }
            if ($Colors.ContainsKey('Text')) {
                Set-BrushPropertySafe -Target $Element -Property 'Foreground' -Value $Colors.Text
            }
            if ($Colors.ContainsKey('Primary')) {
                Set-BrushPropertySafe -Target $Element -Property 'BorderBrush' -Value $Colors.Primary -AllowTransparentFallback
            }
        }
        'ComboBox' {
            if ($Colors.ContainsKey('Secondary')) {
                Set-BrushPropertySafe -Target $Element -Property 'Background' -Value $Colors.Secondary
            }
            if ($Colors.ContainsKey('Text')) {
                Set-BrushPropertySafe -Target $Element -Property 'Foreground' -Value $Colors.Text
            }
            if ($Colors.ContainsKey('Primary')) {
                Set-BrushPropertySafe -Target $Element -Property 'BorderBrush' -Value $Colors.Primary -AllowTransparentFallback
            }
        }
        'ListBox' {
            if ($Colors.ContainsKey('Secondary')) {
                Set-BrushPropertySafe -Target $Element -Property 'Background' -Value $Colors.Secondary
            }
            if ($Colors.ContainsKey('Text')) {
                Set-BrushPropertySafe -Target $Element -Property 'Foreground' -Value $Colors.Text
            }
            if ($Colors.ContainsKey('Primary')) {
                Set-BrushPropertySafe -Target $Element -Property 'BorderBrush' -Value $Colors.Primary -AllowTransparentFallback
            }
        }
        'ListView' {
            if ($Colors.ContainsKey('Secondary')) {
                Set-BrushPropertySafe -Target $Element -Property 'Background' -Value $Colors.Secondary
            }
            if ($Colors.ContainsKey('Text')) {
                Set-BrushPropertySafe -Target $Element -Property 'Foreground' -Value $Colors.Text
            }
            if ($Colors.ContainsKey('Primary')) {
                Set-BrushPropertySafe -Target $Element -Property 'BorderBrush' -Value $Colors.Primary -AllowTransparentFallback
            }
        }
        'CheckBox' {
            if ($Colors.ContainsKey('Text')) {
                Set-BrushPropertySafe -Target $Element -Property 'Foreground' -Value $Colors.Text
            }
            if ($Element.Background -and $Colors.ContainsKey('Secondary')) {
                Set-BrushPropertySafe -Target $Element -Property 'Background' -Value $Colors.Secondary
            }
        }
        'RadioButton' {
            if ($Colors.ContainsKey('Text')) {
                Set-BrushPropertySafe -Target $Element -Property 'Foreground' -Value $Colors.Text
            }
            if ($Element.Background -and $Colors.ContainsKey('Secondary')) {
                Set-BrushPropertySafe -Target $Element -Property 'Background' -Value $Colors.Secondary
            }
        }
        'Button' {
            if ($Element.Name -and $Element.Name -match 'btnNav') {
                if ($Element.Tag -eq 'Selected') {
                    if ($Colors.ContainsKey('SelectedBackground')) {
                        Set-BrushPropertySafe -Target $Element -Property 'Background' -Value $Colors.SelectedBackground -AllowTransparentFallback
                    } elseif ($Colors.ContainsKey('Primary')) {
                        Set-BrushPropertySafe -Target $Element -Property 'Background' -Value $Colors.Primary
                    }
                    if ($Colors.ContainsKey('SelectedForeground')) {
                        Set-BrushPropertySafe -Target $Element -Property 'Foreground' -Value $Colors.SelectedForeground -AllowTransparentFallback
                    } elseif ($Colors.ContainsKey('Text')) {
                        Set-BrushPropertySafe -Target $Element -Property 'Foreground' -Value $Colors.Text
                    }
                } else {
                    if ($Colors.ContainsKey('UnselectedBackground')) {
                        Set-BrushPropertySafe -Target $Element -Property 'Background' -Value $Colors.UnselectedBackground -AllowTransparentFallback
                    } elseif ($Colors.ContainsKey('Secondary')) {
                        Set-BrushPropertySafe -Target $Element -Property 'Background' -Value $Colors.Secondary
                    }
                    if ($Colors.ContainsKey('UnselectedForeground')) {
                        Set-BrushPropertySafe -Target $Element -Property 'Foreground' -Value $Colors.UnselectedForeground -AllowTransparentFallback
                    } elseif ($Colors.ContainsKey('Text')) {
                        Set-BrushPropertySafe -Target $Element -Property 'Foreground' -Value $Colors.Text
                    }
                }
                if ($Colors.ContainsKey('Primary')) {
                    Set-BrushPropertySafe -Target $Element -Property 'BorderBrush' -Value $Colors.Primary -AllowTransparentFallback
                }
            } else {
                if ($Colors.ContainsKey('Primary')) {
                    Set-BrushPropertySafe -Target $Element -Property 'Background' -Value $Colors.Primary
                    Set-BrushPropertySafe -Target $Element -Property 'BorderBrush' -Value $Colors.Primary -AllowTransparentFallback
                }
                if ($Colors.ContainsKey('Text')) {
                    Set-BrushPropertySafe -Target $Element -Property 'Foreground' -Value $Colors.Text
                } else {
                    Set-BrushPropertySafe -Target $Element -Property 'Foreground' -Value 'White'
                }
            }
        }
        'ProgressBar' {
            if ($Colors.ContainsKey('Secondary')) {
                Set-BrushPropertySafe -Target $Element -Property 'Background' -Value $Colors.Secondary
            }
            if ($Colors.ContainsKey('Primary')) {
                Set-BrushPropertySafe -Target $Element -Property 'Foreground' -Value $Colors.Primary
                Set-BrushPropertySafe -Target $Element -Property 'BorderBrush' -Value $Colors.Primary -AllowTransparentFallback
            }
        }
        'Slider' {
            if ($Colors.ContainsKey('Secondary')) {
                Set-BrushPropertySafe -Target $Element -Property 'Background' -Value $Colors.Secondary
            }
            if ($Colors.ContainsKey('Primary')) {
                Set-BrushPropertySafe -Target $Element -Property 'Foreground' -Value $Colors.Primary
                Set-BrushPropertySafe -Target $Element -Property 'BorderBrush' -Value $Colors.Primary -AllowTransparentFallback
            }
        }
        'Menu' {
            if ($Colors.ContainsKey('Secondary')) {
                Set-BrushPropertySafe -Target $Element -Property 'Background' -Value $Colors.Secondary
            }
            if ($Colors.ContainsKey('Text')) {
                Set-BrushPropertySafe -Target $Element -Property 'Foreground' -Value $Colors.Text
            }
        }
        'MenuItem' {
            if ($Colors.ContainsKey('Secondary')) {
                Set-BrushPropertySafe -Target $Element -Property 'Background' -Value $Colors.Secondary
            }
            if ($Colors.ContainsKey('Text')) {
                Set-BrushPropertySafe -Target $Element -Property 'Foreground' -Value $Colors.Text
            }
        }
        'ScrollViewer' {
            if ($Colors.ContainsKey('Background')) {
                Set-BrushPropertySafe -Target $Element -Property 'Background' -Value $Colors.Background
            }
        }
    }

    try {
        $Element.InvalidateVisual()
    } catch {
        Write-Verbose ("Update-AllUIElementsRecursively: InvalidateVisual skipped: {0}" -f $_.Exception.Message)
    }

    if ($Element -is [System.Windows.Controls.Panel]) {
        foreach ($child in $Element.Children) {
            Update-AllUIElementsRecursively -Element $child -Colors $Colors
        }
        return
    }

    if ($Element -is [System.Windows.Controls.ContentControl]) {
        $content = $Element.Content
        if ($content -is [System.Windows.DependencyObject]) {
            Update-AllUIElementsRecursively -Element $content -Colors $Colors
        }
        return
    }

    if ($Element -is [System.Windows.Controls.Decorator]) {
        if ($Element.Child -is [System.Windows.DependencyObject]) {
            Update-AllUIElementsRecursively -Element $Element.Child -Colors $Colors
        }
        return
    }

    if ($Element -is [System.Windows.Media.Visual]) {
        $childCount = [System.Windows.Media.VisualTreeHelper]::GetChildrenCount($Element)
        for ($i = 0; $i -lt $childCount; $i++) {
            $child = [System.Windows.Media.VisualTreeHelper]::GetChild($Element, $i)
            if ($child -is [System.Windows.DependencyObject]) {
                Update-AllUIElementsRecursively -Element $child -Colors $Colors
            }
        }
    }
}

function Update-ButtonStyles {
    [CmdletBinding()]
    param(
        [string]$Primary,
        [string]$Hover,
        [hashtable]$ThemeColors = $null
    )

    if (-not $form) {
        return
    }

    try {
        $buttons = @()
        Find-AllControlsOfType -Parent $form -ControlType 'System.Windows.Controls.Button' -Collection ([ref]$buttons)

        foreach ($button in $buttons) {
            if ($button.Style -and $form.Resources.Contains('ModernButton') -and $button.Style -eq $form.Resources['ModernButton']) {
                if ($Primary) {
                    Set-BrushPropertySafe -Target $button -Property 'Background' -Value $Primary
                    Set-BrushPropertySafe -Target $button -Property 'BorderBrush' -Value $Primary -AllowTransparentFallback
                }
                if ($ThemeColors -and $ThemeColors.ContainsKey('Text')) {
                    Set-BrushPropertySafe -Target $button -Property 'Foreground' -Value $ThemeColors.Text
                } else {
                    Set-BrushPropertySafe -Target $button -Property 'Foreground' -Value 'White'
                }
            }

            if ($Hover) {
                try {
                    $hoverBrush = New-SolidColorBrushSafe $Hover
                    if ($hoverBrush) {
                        $button.Resources['HoverBackground'] = $hoverBrush
                    }
                } catch {
                    Write-Verbose ("Update-ButtonStyles: Hover brush skipped: {0}" -f $_.Exception.Message)
                }
            }
        }
    } catch {
        $errorMessage = 'Error updating button styles: {0}' -f $_.Exception.Message
        Log $errorMessage 'Warning'
    }
}

function Update-ComboBoxStyles {
    [CmdletBinding()]
    param(
        [string]$Background,
        [string]$Foreground,
        [string]$Border,
        [string]$ThemeName = 'OptimizerDark',
        [hashtable]$ThemeColors = $null
    )

    if (-not $form) {
        return
    }

    try {
        if (-not $ThemeColors) {
            $ThemeColors = Get-ThemeColors -ThemeName $ThemeName
        }
        if ($ThemeColors) {
            $ThemeColors = Normalize-ThemeColorTable $ThemeColors
        }

        $actualBackground = if ($ThemeColors -and $ThemeColors.ContainsKey('Secondary')) { $ThemeColors.Secondary } else { $Background }
        $actualForeground = if ($ThemeColors -and $ThemeColors.ContainsKey('Text')) { $ThemeColors.Text } else { $Foreground }
        $actualBorder = if ($ThemeColors -and $ThemeColors.ContainsKey('Primary')) { $ThemeColors.Primary } else { $Border }

        $comboBoxes = @()
        Find-AllControlsOfType -Parent $form -ControlType 'System.Windows.Controls.ComboBox' -Collection ([ref]$comboBoxes)

        foreach ($combo in $comboBoxes) {
            if ($actualBackground) {
                Set-BrushPropertySafe -Target $combo -Property 'Background' -Value $actualBackground
            }
            if ($actualForeground) {
                Set-BrushPropertySafe -Target $combo -Property 'Foreground' -Value $actualForeground
            }
            if ($actualBorder) {
                Set-BrushPropertySafe -Target $combo -Property 'BorderBrush' -Value $actualBorder -AllowTransparentFallback
            }

            foreach ($item in $combo.Items) {
                if ($item -is [System.Windows.Controls.ComboBoxItem]) {
                    if ($actualBackground) {
                        Set-BrushPropertySafe -Target $item -Property 'Background' -Value $actualBackground
                    }
                    if ($actualForeground) {
                        Set-BrushPropertySafe -Target $item -Property 'Foreground' -Value $actualForeground
                    }
                }
            }

            try {
                $combo.InvalidateVisual()
                $combo.UpdateLayout()
            } catch {
                Write-Verbose ("Update-ComboBoxStyles: refresh skipped: {0}" -f $_.Exception.Message)
            }
        }
    } catch {
        $errorMessage = 'Error updating ComboBox styles: {0}' -f $_.Exception.Message
        Log $errorMessage 'Warning'
    }
}

function Update-TextStyles {
    [CmdletBinding()]
    param(
        [string]$Foreground,
        [string]$Header,
        [string]$ThemeName = 'OptimizerDark',
        [hashtable]$ThemeColors = $null
    )

    if (-not $form) {
        return
    }

    try {
        if (-not $ThemeColors) {
            $ThemeColors = Get-ThemeColors -ThemeName $ThemeName
        }
        if ($ThemeColors) {
            $ThemeColors = Normalize-ThemeColorTable $ThemeColors
        }

        $textColor = if ($ThemeColors -and $ThemeColors.ContainsKey('Text')) { $ThemeColors.Text } else { $Foreground }
        $headerColor = if ($ThemeColors -and $ThemeColors.ContainsKey('Accent')) { $ThemeColors.Accent } else { $Header }

        $textBlocks = @()
        Find-AllControlsOfType -Parent $form -ControlType 'System.Windows.Controls.TextBlock' -Collection ([ref]$textBlocks)
        foreach ($textBlock in $textBlocks) {
            if ($textBlock.Tag -eq 'AccentText') { continue }

            $target = if ($textBlock.Style -and $form.Resources.Contains('HeaderText') -and $textBlock.Style -eq $form.Resources['HeaderText']) {
                $headerColor
            } else {
                $textColor
            }

            if ($target) {
                Set-BrushPropertySafe -Target $textBlock -Property 'Foreground' -Value $target
            }
        }

        $labels = @()
        Find-AllControlsOfType -Parent $form -ControlType 'System.Windows.Controls.Label' -Collection ([ref]$labels)
        foreach ($label in $labels) {
            if ($textColor) {
                Set-BrushPropertySafe -Target $label -Property 'Foreground' -Value $textColor
            }
        }
    } catch {
        $errorMessage = 'Error updating text styles: {0}' -f $_.Exception.Message
        Log $errorMessage 'Warning'
    }
}

function Update-ThemeColorPreview {
    [CmdletBinding()]
    param(
        [string]$ThemeName,
        [hashtable]$ThemeColors = $null
    )

    if (-not $previewBg -or -not $previewPrimary -or -not $previewHover -or -not $previewText) {
        return
    }

    try {
        if (-not $ThemeColors) {
            if ($ThemeName -eq 'Custom' -and $global:CustomThemeColors) {
                $ThemeColors = $global:CustomThemeColors
            } else {
                $ThemeColors = Get-ThemeColors -ThemeName $ThemeName
            }
        }

        if (-not $ThemeColors) {
            return
        }

        $ThemeColors = Normalize-ThemeColorTable $ThemeColors

        $bgBrush = if ($ThemeColors.ContainsKey('Background')) { New-SolidColorBrushSafe $ThemeColors.Background } else { $null }
        $primaryBrush = if ($ThemeColors.ContainsKey('Primary')) { New-SolidColorBrushSafe $ThemeColors.Primary } else { $null }
        $hoverBrush = if ($ThemeColors.ContainsKey('Hover')) { New-SolidColorBrushSafe $ThemeColors.Hover } else { $null }
        $textBrush = if ($ThemeColors.ContainsKey('Text')) { New-SolidColorBrushSafe $ThemeColors.Text } else { $null }

        if ($bgBrush) { $previewBg.Fill = $bgBrush.Clone() }
        if ($primaryBrush) { $previewPrimary.Fill = $primaryBrush.Clone() }
        if ($hoverBrush) { $previewHover.Fill = $hoverBrush.Clone() }
        if ($textBrush) { $previewText.Fill = $textBrush.Clone() }

        if ($previewBgCustom -and $bgBrush) { $previewBgCustom.Fill = $bgBrush.Clone() }
        if ($previewPrimaryCustom -and $primaryBrush) { $previewPrimaryCustom.Fill = $primaryBrush.Clone() }
        if ($previewHoverCustom -and $hoverBrush) { $previewHoverCustom.Fill = $hoverBrush.Clone() }
        if ($previewTextCustom -and $textBrush) { $previewTextCustom.Fill = $textBrush.Clone() }

        if ($ThemeName -eq 'Custom' -and $global:CustomThemeColors) {
            if ($txtCustomBg) { $txtCustomBg.Text = $global:CustomThemeColors.Background }
            if ($txtCustomPrimary) { $txtCustomPrimary.Text = $global:CustomThemeColors.Primary }
            if ($txtCustomHover) { $txtCustomHover.Text = $global:CustomThemeColors.Hover }
            if ($txtCustomText) { $txtCustomText.Text = $global:CustomThemeColors.Text }
        }

        if ($ThemeColors.ContainsKey('Name')) {
            Log ("Farb-Vorschau für '{0}' aktualisiert" -f $ThemeColors.Name) 'Info'
        }
    } catch {
        Log ("Fehler bei Farb-Vorschau: {0}" -f $_.Exception.Message) 'Warning'
    }
}

function Apply-ThemeColors {
    [CmdletBinding(DefaultParameterSetName='ByTheme')]
    param(
        [Parameter(ParameterSetName='ByTheme')]
        [string]$ThemeName = 'OptimizerDark',
        [Parameter(ParameterSetName='ByCustom')]
        [string]$Background,
        [Parameter(ParameterSetName='ByCustom')]
        [string]$Primary,
        [Parameter(ParameterSetName='ByCustom')]
        [string]$Hover,
        [Parameter(ParameterSetName='ByCustom')]
        [string]$Foreground,
        [Parameter(ParameterSetName='__AllParameterSets')]
        [switch]$IsFallback
    )

    try {
        if (-not $form) {
            Log 'UI-Formular nicht verfügbar, Theme kann nicht angewendet werden.' 'Error'
            return
        }

        if ($PSCmdlet.ParameterSetName -eq 'ByCustom') {
            $colors = (Get-ThemeColors -ThemeName 'OptimizerDark').Clone()
            $colors['Name'] = 'Custom Theme'

            if ($PSBoundParameters.ContainsKey('Background') -and -not [string]::IsNullOrWhiteSpace($Background)) {
                $colors['Background'] = $Background
                $colors['Secondary'] = $Background
                $colors['SidebarBg'] = $Background
                $colors['HeaderBg'] = $Background
                $colors['LogBg'] = $Background
            }

            if ($PSBoundParameters.ContainsKey('Primary') -and -not [string]::IsNullOrWhiteSpace($Primary)) {
                $colors['Primary'] = $Primary
                $colors['Accent'] = $Primary
            }

            if ($PSBoundParameters.ContainsKey('Hover') -and -not [string]::IsNullOrWhiteSpace($Hover)) {
                $colors['Hover'] = $Hover
            }

            if ($PSBoundParameters.ContainsKey('Foreground') -and -not [string]::IsNullOrWhiteSpace($Foreground)) {
                $colors['Text'] = $Foreground
                $colors['TextSecondary'] = $Foreground
            }
        } else {
            $colors = Get-ThemeColors -ThemeName $ThemeName
            if (-not $colors) {
                throw "Theme '$ThemeName' wurde nicht gefunden."
            }
        }

        $colors = Normalize-ThemeColorTable $colors
        $appliedThemeName = if ($colors.ContainsKey('Name')) { $colors.Name } else { $ThemeName }

        $form.Dispatcher.Invoke([Action]{
            if ($colors.ContainsKey('Background')) {
                Set-BrushPropertySafe -Target $form -Property 'Background' -Value $colors.Background
            }
            Update-AllUIElementsRecursively -Element $form -Colors $colors
        }, [System.Windows.Threading.DispatcherPriority]::Render)

        Update-ButtonStyles -Primary $colors.Primary -Hover $colors.Hover -ThemeColors $colors
        Update-ComboBoxStyles -Background $colors.Secondary -Foreground $colors.Text -Border $colors.Primary -ThemeName $appliedThemeName -ThemeColors $colors
        Update-TextStyles -Foreground $colors.Text -Header $colors.Accent -ThemeName $appliedThemeName -ThemeColors $colors

        Normalize-VisualTreeBrushes -Root $form

        $global:CurrentTheme = $appliedThemeName
        Update-ThemeColorPreview -ThemeName $appliedThemeName -ThemeColors $colors

        if ($global:CurrentPanel -eq 'Advanced' -and $global:CurrentAdvancedSection) {
            try {
                $form.Dispatcher.BeginInvoke([Action]{
                    Set-ActiveAdvancedSectionButton -Section $global:CurrentAdvancedSection -CurrentTheme $appliedThemeName
                }, [System.Windows.Threading.DispatcherPriority]::Background) | Out-Null
            } catch {
                Log "Could not refresh advanced section highlight: $($_.Exception.Message)" 'Warning'
            }
        }

        Log ("[OK] Theme '{0}' erfolgreich angewendet." -f $appliedThemeName) 'Success'
    } catch {
        Log ("❌ Fehler beim Theme-Wechsel: {0}" -f $_.Exception.Message) 'Error'

        $shouldAttemptFallback = -not $IsFallback -and ($PSCmdlet.ParameterSetName -ne 'ByTheme' -or $ThemeName -ne 'OptimizerDark')

        if ($shouldAttemptFallback) {
            try {
                Log 'Versuche Fallback-Theme (OptimizerDark)...' 'Warning'
                Apply-ThemeColors -ThemeName 'OptimizerDark' -IsFallback
            } catch {
                Log 'KRITISCHER FEHLER: Kein Theme kann angewendet werden.' 'Error'
            }
        } elseif (-not $IsFallback) {
            Log 'KRITISCHER FEHLER: Kein Theme kann angewendet werden.' 'Error'
        }
    }
}

function Switch-Theme {
    [CmdletBinding()]
    param(
        [string]$ThemeName
    )

    if ([string]::IsNullOrWhiteSpace($ThemeName)) {
        Log 'Theme-Name ist leer, verwende Standard.' 'Warning'
        $ThemeName = 'OptimizerDark'
    }

    if ($ThemeName -eq 'Custom') {
        if (-not $global:CustomThemeColors) {
            Log 'Kein benutzerdefiniertes Theme hinterlegt.' 'Warning'
            return
        }
        Apply-ThemeColors -ThemeName $ThemeName
        return
    }

    if (-not $global:ThemeDefinitions.ContainsKey($ThemeName)) {
        Log ("Theme '{0}' nicht gefunden, wechsle zu OptimizerDark." -f $ThemeName) 'Warning'
        $ThemeName = 'OptimizerDark'
    }

    if (${function:Apply-ThemeColors}) {
        Apply-ThemeColors -ThemeName $ThemeName
    } else {
        Log 'Apply-ThemeColors Funktion nicht verfügbar - Theme kann nicht angewendet werden.' 'Error'
    }
}

# Log functions moved to top of script to fix call order issues

# ---------- WinMM Timer (1ms precision) ----------
if (-not ([System.Management.Automation.PSTypeName]'WinMM').Type) {
        Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class WinMM {
    [DllImport("winmm.dll", EntryPoint="timeBeginPeriod")]
    public static extern uint timeBeginPeriod(uint uPeriod);
    [DllImport("winmm.dll", EntryPoint="timeEndPeriod")]
    public static extern uint timeEndPeriod(uint uPeriod);

}
'@ -ErrorAction Stop
        Write-Verbose "WinMM timer API not available: $($_.Exception.Message)"
    }

# ---------- Performance Monitoring API ----------
if (-not ([System.Management.Automation.PSTypeName]'PerfMon').Type) {
        Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class PerfMon {
    [DllImport("kernel32.dll")]
    public static extern bool GetSystemTimes(out long idleTime, out long kernelTime, out long userTime);

    [DllImport("kernel32.dll")]
    public static extern bool GlobalMemoryStatusEx(ref MEMORYSTATUSEX lpBuffer);

    [StructLayout(LayoutKind.Sequential)]
    public struct MEMORYSTATUSEX {  // Memory structure with ullTotalPhys and ullAvailPhys for detailed monitoring
        public uint dwLength;
        public uint dwMemoryLoad;
        public ulong ullTotalPhys;
        public ulong ullAvailPhys;
        public ulong ullTotalPageFile;
        public ulong ullAvailPageFile;
        public ulong ullTotalVirtual;
        public ulong ullAvailVirtual;
        public ulong ullAvailExtendedVirtual;

    }
}
'@ -ErrorAction Stop
        Write-Verbose "Performance monitoring API not available: $($_.Exception.Message)"
    }

# ---------- System Health Monitoring and Alerts ----------
$global:SystemHealthData = @{
    LastHealthCheck = $null
    HealthStatus = 'Not Run'
    HealthWarnings = @()
    HealthScore = $null
    Recommendations = @()
    Issues = @()
    Metrics = @{}
    LastResult = $null
}

function Get-SystemHealthStatus {
    <#
    .SYNOPSIS
    Comprehensive system health monitoring with performance analysis and recommendations
    .DESCRIPTION
    Analyzes system health across multiple dimensions and provides actionable recommendations
    #>

        $healthData = @{
            OverallScore = 100
            Issues = @()
            Warnings = @()
            Recommendations = @()
            Status = "Excellent"
            Metrics = @{}

        }

        # 1. Memory Health Check - MemoryUsagePercent gt 90 triggers Critical memory usage alerts
        $memMetrics = Get-SystemPerformanceMetrics
        if ($memMetrics.MemoryUsagePercent) {
            $healthData.Metrics.MemoryUsage = $memMetrics.MemoryUsagePercent

            if ($memMetrics.MemoryUsagePercent -gt 90) {
                $healthData.Issues += "Critical memory usage: $($memMetrics.MemoryUsagePercent)%"
                $healthData.Recommendations += "Close unnecessary applications to free memory"
                $healthData.OverallScore -= 20  # OverallScore minus 20 for critical memory
            } elseif ($memMetrics.MemoryUsagePercent -gt 80) {
                $healthData.Warnings += "High memory usage: $($memMetrics.MemoryUsagePercent)%"
                $healthData.Recommendations += "Consider closing some applications for better gaming performance"
                $healthData.OverallScore -= 10  # OverallScore minus 10 for high memory
            }
        }

        # 2. CPU Health Check - CpuUsage gt 90 triggers Critical CPU usage alerts
        if ($memMetrics.CpuUsage) {
            $healthData.Metrics.CpuUsage = $memMetrics.CpuUsage

            if ($memMetrics.CpuUsage -gt 90) {
                $healthData.Issues += "Critical CPU usage: $($memMetrics.CpuUsage)%"
                $healthData.Recommendations += "Check for background processes consuming CPU"
                $healthData.OverallScore -= 15  # OverallScore minus 15 for critical CPU
            } elseif ($memMetrics.CpuUsage -gt 75) {
                $healthData.Warnings += "High CPU usage: $($memMetrics.CpuUsage)%"
                $healthData.Recommendations += "Monitor CPU-intensive applications"
                $healthData.OverallScore -= 8
            }

        # 3. Disk Space Health Check - REMOVED due to PowerShell parser errors
        # The following disk space health check code has been commented out to resolve parsing issues:
        # - Removed variables: $freeSpaceGB, $freeSpacePercent
        # - Removed problematic string formatting: ($freeSpaceGB GB)
        # - Removed healthData.Issues, healthData.Warnings, healthData.Recommendations for disk space
        <#
            $systemDrive = $env:SystemDrive
            $driveInfo = Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='$systemDrive'" -ErrorAction SilentlyContinue
            if ($driveInfo) {
                $freeSpaceGB = [math]::Round($driveInfo.FreeSpace / 1GB, 2)
                $totalSpaceGB = [math]::Round($driveInfo.Size / 1GB, 2)
                $freeSpacePercent = [math]::Round(($driveInfo.FreeSpace / $driveInfo.Size) * 100, 1)

                $healthData.Metrics.DiskFreeSpace = $freeSpacePercent

                if ($freeSpacePercent -lt 10) {
                    $healthData.Issues += "Critical disk space: $freeSpacePercent% free ($freeSpaceGB GB)"
                    $healthData.Recommendations += "Free up disk space immediately to prevent system issues"
                    $healthData.OverallScore -= 25

                } elseif ($freeSpacePercent -lt 20) {
                    $healthData.Warnings += "Low disk space: $freeSpacePercent% free ($freeSpaceGB GB)"
                    $healthData.Recommendations += "Consider cleaning up temporary files and uninstalling unused programs"
                    $healthData.OverallScore -= 12
                }
            Log "Warning: Could not check disk space: $($_.Exception.Message)" 'Warning'
        #>

        # 4. Running Processes Health Check - processCount gt 200 analysis and optimization detection
            $processCount = (Get-Process).Count
            $healthData.Metrics.ProcessCount = $processCount

            if ($processCount -gt 200) {
                $healthData.Warnings += "High number of running processes: $processCount"
                $healthData.Recommendations += "Consider using Task Manager to close unnecessary processes"
                $healthData.OverallScore -= 8

            }

            # Check for known problematic processes
            $problematicProcesses = Get-Process | Where-Object {
                $_.ProcessName -match "miner|crypto|torrent" -and $_.WorkingSet -gt 100MB
            }

            if ($problematicProcesses) {
                $healthData.Warnings += "Detected potentially problematic processes affecting gaming performance"
                $healthData.Recommendations += "Review and close mining, crypto, or torrent applications while gaming"
                $healthData.OverallScore -= 15
            }
            Log "Warning: Could not analyze running processes: $($_.Exception.Message)" 'Warning'

        # 5. Windows Update Health Check - Microsoft.Update.Session for pendingUpdates analysis
            $updateSession = New-Object -ComObject Microsoft.Update.Session -ErrorAction SilentlyContinue
            if ($updateSession) {
                $updateSearcher = $updateSession.CreateUpdateSearcher()
                $pendingUpdates = $updateSearcher.Search("IsInstalled=0 and IsHidden=0").Updates.Count

                if ($pendingUpdates -gt 0) {
                    $healthData.Metrics.PendingUpdates = $pendingUpdates
                    $healthData.Warnings += "$pendingUpdates pending Windows updates"
                    $healthData.Recommendations += "Install pending Windows updates for security and performance improvements"
                    $healthData.OverallScore -= 5

                }
            }
            # Silent fail for Windows Update check

        # 6. Gaming Optimization Status - GameBar AllowAutoGameMode and HwSchMode validation
            $gameMode = Get-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\GameBar" -Name "AllowAutoGameMode" -ErrorAction SilentlyContinue
            if (-not $gameMode -or $gameMode.AllowAutoGameMode -ne 1) {
                $healthData.Warnings += "Windows Game Mode is not enabled"
                $healthData.Recommendations += "Enable Game Mode in Windows Settings for better gaming performance"
                $healthData.OverallScore -= 5

            }

            $hardwareScheduling = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" -Name "HwSchMode" -ErrorAction SilentlyContinue
            if (-not $hardwareScheduling -or $hardwareScheduling.HwSchMode -ne 2) {
                $healthData.Warnings += "Hardware GPU Scheduling is not enabled"
                $healthData.Recommendations += "Enable Hardware GPU Scheduling for improved graphics performance"
                $healthData.OverallScore -= 5
            }
            # Silent fail for optimization checks

        # 7. Network Health Check - Win32_NetworkAdapter NetEnabled and NetConnectionStatus analysis
            $networkAdapters = Get-WmiObject -Class Win32_NetworkAdapter -Filter "NetEnabled=True" -ErrorAction SilentlyContinue
            $activeAdapters = $networkAdapters | Where-Object { $_.NetConnectionStatus -eq 2 }

            if ($activeAdapters.Count -eq 0) {
                $healthData.Issues += "No active network connections detected"
                $healthData.Recommendations += "Check network connectivity for online gaming"
                $healthData.OverallScore -= 20

            } elseif ($activeAdapters.Count -gt 2) {
                $healthData.Warnings += "Multiple active network adapters detected"
                $healthData.Recommendations += "Disable unused network adapters to reduce latency"
                $healthData.OverallScore -= 5
            # Silent fail for network check

        # Determine overall status - OverallScore ge 90 Excellent, ge 75 Good, ge 60 Fair, Poor, Critical
        if ($healthData.OverallScore -ge 90) {
            $healthData.Status = "Excellent"
        } elseif ($healthData.OverallScore -ge 75) {
            $healthData.Status = "Good"
            $healthData.Status = "Fair"
            $healthData.Status = "Poor"
            $healthData.Status = "Critical"

        return $healthData

        Log "Error performing system health check: $($_.Exception.Message)" 'Error'
        return @{
            OverallScore = 0
            Issues = @("Health check failed")
            Warnings = @()
            Recommendations = @("Run as Administrator for complete health analysis")
            Status = "Unknown"
            Metrics = @{}
        }

function Update-SystemHealthSummary {
        $status = if ($global:SystemHealthData.HealthStatus) { $global:SystemHealthData.HealthStatus } else { 'Not Run' }
        $score = $global:SystemHealthData.HealthScore
        $lastRun = $global:SystemHealthData.LastHealthCheck

        $text = 'Not Run'
        $foreground = '#A6AACF'

        if ($status -eq 'Error') {
            $text = 'Error (see log)'
            $foreground = '#FF4444'

        } elseif ($lastRun) {
            $timeStamp = $lastRun.ToString('HH:mm')
            if ($score -ne $null) {
                $roundedScore = [Math]::Round([double]$score, 0)
                $text = '{0} ({1}% @ {2})' -f $status, [int]$roundedScore, $timeStamp
            } else {
                $text = '{0} (Last: {1})' -f $status, $timeStamp
            }

            switch ($status) {
                'Excellent' { $foreground = '#8F6FFF' }
                'Good' { $foreground = '#A7F3D0' }
                'Fair' { $foreground = '#A78BFA' }
                'Poor' { $foreground = '#FFA500' }
                'Critical' { $foreground = '#FF6B6B' }
                default { $foreground = '#A6AACF' }
            }

        if ($lblDashSystemHealth) {
            $lblDashSystemHealth.Dispatcher.Invoke([Action]{
                $lblDashSystemHealth.Text = $text
                Set-BrushPropertySafe -Target $lblDashSystemHealth -Property 'Foreground' -Value $foreground
            })
        }
        Log "Error updating dashboard health summary: $($_.Exception.Message)" 'Warning'

function Update-SystemHealthDisplay {
    param([switch]$RunCheck)

        $shouldRun = [bool]$RunCheck

        if ($shouldRun) {
            $healthData = Get-SystemHealthStatus
            if ($healthData) {
                $timestamp = Get-Date
                $global:SystemHealthData.LastHealthCheck = $timestamp
                $global:SystemHealthData.HealthStatus = $healthData.Status
                $global:SystemHealthData.HealthScore = $healthData.OverallScore
                $global:SystemHealthData.HealthWarnings = $healthData.Warnings
                $global:SystemHealthData.Recommendations = $healthData.Recommendations
                $global:SystemHealthData.Issues = $healthData.Issues
                $global:SystemHealthData.Metrics = $healthData.Metrics
                $global:SystemHealthData.LastResult = $healthData
                Log "Health check complete: $($healthData.Status) ($($healthData.OverallScore)% score)" 'Info'

            }
        }
        $errorMessage = 'Error in Update-SystemHealthDisplay: {0}' -f $_.Exception.Message
        Log $errorMessage 'Error'
        $global:SystemHealthData.LastHealthCheck = Get-Date
        $global:SystemHealthData.HealthStatus = 'Error'
        $global:SystemHealthData.HealthScore = $null
        $global:SystemHealthData.HealthWarnings = @($errorMessage)
        $global:SystemHealthData.Recommendations = @()
        $global:SystemHealthData.Issues = @($errorMessage)
        $global:SystemHealthData.Metrics = @{}
        $global:SystemHealthData.LastResult = $null
    }

    Update-SystemHealthSummary

    return $global:SystemHealthData

function Show-SystemHealthDialog {
    <#
    .SYNOPSIS
    Shows a detailed system health dialog with recommendations and actions
    .DESCRIPTION
    Creates a WPF dialog displaying comprehensive system health information
    #>


        [xml]$healthDialogXaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="System Health Monitor"
        Width="750" Height="600"
        Background="#080716"
        WindowStartupLocation="CenterScreen"
        ResizeMode="CanResize">

  <Window.Resources>
    <SolidColorBrush x:Key="CardBackgroundBrush" Color="#14132B"/>
    <SolidColorBrush x:Key="CardBorderBrush" Color="#2F285A"/>
    <SolidColorBrush x:Key="AccentBrush" Color="#8F6FFF"/>
    <SolidColorBrush x:Key="PrimaryTextBrush" Color="#F5F3FF"/>
    <SolidColorBrush x:Key="SecondaryTextBrush" Color="#A9A5D9"/>
    <Style TargetType="TextBlock">
      <Setter Property="FontFamily" Value="Segoe UI"/>
      <Setter Property="Foreground" Value="{StaticResource PrimaryTextBrush}"/>
    </Style>
    <Style x:Key="DialogButton" TargetType="Button">
      <Setter Property="FontFamily" Value="Segoe UI"/>
      <Setter Property="FontSize" Value="12"/>
      <Setter Property="Foreground" Value="#120B22"/>
      <Setter Property="Background" Value="{StaticResource AccentBrush}"/>
      <Setter Property="BorderThickness" Value="0"/>
      <Setter Property="Padding" Value="14,6"/>
      <Setter Property="FontWeight" Value="SemiBold"/>

      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Background" Value="{StaticResource AccentBrush}"/>
      <Setter Property="BorderThickness" Value="0"/>
      <Setter Property="Foreground" Value="White"/>
      <Setter Property="HorizontalContentAlignment" Value="Center"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border Background="{TemplateBinding Background}" CornerRadius="10">

              <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">

              <Setter Property="Background" Value="#A78BFA"/>
              </Trigger>
              <Trigger Property="IsEnabled" Value="False">
                <Setter Property="Opacity" Value="0.4"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
    <Style x:Key="SecondaryDialogButton" TargetType="Button" BasedOn="{StaticResource DialogButton}">
      <Setter Property="Background" Value="#1F1B3F"/>
      <Setter Property="Foreground" Value="{StaticResource PrimaryTextBrush}"/>
    </Style>
    <Style x:Key="WarningDialogButton" TargetType="Button" BasedOn="{StaticResource DialogButton}">
      <Setter Property="Background" Value="#FBBF24"/>
      <Setter Property="Foreground" Value="#1B1302"/>
    </Style>
  </Window.Resources>

  <Grid Margin="15">
    <Grid.RowDefinitions>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="*"/>
      <RowDefinition Height="Auto"/>
    </Grid.RowDefinitions>

    <!-- Header -->
    <Border Grid.Row="0" Background="{DynamicResource CardBackgroundBrush}" BorderBrush="{DynamicResource CardBorderBrush}" BorderThickness="2" CornerRadius="8" Padding="20" Margin="0,0,0,15">
      <Grid>
        <Grid.ColumnDefinitions>
          <ColumnDefinition Width="*"/>
          <ColumnDefinition Width="Auto"/>
        </Grid.ColumnDefinitions>

        <StackPanel Grid.Column="0">
          <TextBlock Text="System Health Monitor" Foreground="{DynamicResource AccentBrush}" FontWeight="Bold" FontSize="20"/>
          <TextBlock x:Name="lblHealthStatus" Text="Status: Unknown" Foreground="{DynamicResource PrimaryTextBrush}" FontSize="14" Margin="0,5,0,0"/>
          <TextBlock x:Name="lblHealthScore" Text="Health Score: 0%" Foreground="{DynamicResource PrimaryTextBrush}" FontSize="12" Margin="0,2,0,0"/>
        </StackPanel>

        <Button x:Name="btnRefreshHealth" Grid.Column="1" Content="🔄 Refresh" Width="100" Height="35"
                Background="{StaticResource CardBorderBrush}" Foreground="{DynamicResource PrimaryTextBrush}" BorderThickness="0" FontWeight="SemiBold"/>
      </Grid>
    </Border>

    <!-- Metrics -->
    <Border Grid.Row="1" Background="{DynamicResource CardBackgroundBrush}" BorderBrush="{DynamicResource CardBorderBrush}" BorderThickness="2" CornerRadius="8" Padding="15" Margin="0,0,0,15">
      <Grid>
        <Grid.ColumnDefinitions>
          <ColumnDefinition Width="*"/>
          <ColumnDefinition Width="*"/>
          <ColumnDefinition Width="*"/>
        </Grid.ColumnDefinitions>

        <StackPanel Grid.Column="0">
          <TextBlock Text="CPU Usage" Foreground="{DynamicResource PrimaryTextBrush}" FontSize="12" FontWeight="Bold"/>
          <TextBlock x:Name="lblCpuMetric" Text="--%" Foreground="{DynamicResource AccentBrush}" FontSize="14" Margin="0,2,0,0"/>
        </StackPanel>

        <StackPanel Grid.Column="1">
          <TextBlock Text="Memory Usage" Foreground="{DynamicResource PrimaryTextBrush}" FontSize="12" FontWeight="Bold"/>
          <TextBlock x:Name="lblMemoryMetric" Text="--%" Foreground="{DynamicResource AccentBrush}" FontSize="14" Margin="0,2,0,0"/>
        </StackPanel>
        <StackPanel Grid.Column="2" Visibility="Collapsed">
          <TextBlock Text="Disk Free Space" Foreground="{DynamicResource PrimaryTextBrush}" FontSize="12" FontWeight="Bold"/>
          <TextBlock x:Name="lblDiskMetric" Text="--%" Foreground="{DynamicResource AccentBrush}" FontSize="14" Margin="0,2,0,0"/>
        </StackPanel>
      </Grid>
    </Border>

    <!-- Issues and Recommendations -->
    <Border Grid.Row="2" Background="{DynamicResource CardBackgroundBrush}" BorderBrush="{DynamicResource CardBorderBrush}" BorderThickness="2" CornerRadius="8" Padding="15">

      <Grid>
        <Grid.RowDefinitions>
          <RowDefinition Height="Auto"/>
          <RowDefinition Height="*"/>
          <RowDefinition Height="Auto"/>
          <RowDefinition Height="*"/>
        </Grid.RowDefinitions>

        <TextBlock Grid.Row="0" Text="Issues &amp; Warnings" Foreground="#FF6B6B" FontWeight="Bold" FontSize="14" Margin="0,0,0,10"/>
        <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto" MaxHeight="150">
          <ListBox x:Name="lstIssues" Background="Transparent" BorderThickness="0" Foreground="{DynamicResource PrimaryTextBrush}" FontSize="11">
            <ListBox.ItemTemplate>
              <DataTemplate>
                <TextBlock Text="{Binding}" Foreground="#FF6B6B" Margin="5" TextWrapping="Wrap"/>
              </DataTemplate>
            </ListBox.ItemTemplate>
          </ListBox>
        </ScrollViewer>

        <TextBlock Grid.Row="2" Text="Recommendations" Foreground="{DynamicResource AccentBrush}" FontWeight="Bold" FontSize="14" Margin="0,15,0,10"/>
        <ScrollViewer Grid.Row="3" VerticalScrollBarVisibility="Auto">
          <ListBox x:Name="lstRecommendations" Background="Transparent" BorderThickness="0" Foreground="{DynamicResource PrimaryTextBrush}" FontSize="11">
            <ListBox.ItemTemplate>
              <DataTemplate>
                <Border Background="{DynamicResource CardBackgroundBrush}" BorderBrush="{DynamicResource CardBorderBrush}" BorderThickness="1" CornerRadius="3" Padding="8" Margin="2">
                  <TextBlock Text="{Binding}" Foreground="{DynamicResource SecondaryTextBrush}" TextWrapping="Wrap"/>
                </Border>
              </DataTemplate>
            </ListBox.ItemTemplate>
          </ListBox>
        </ScrollViewer>
      </Grid>
    </Border>

    <!-- Action Buttons -->
    <Border Grid.Row="3" Background="{DynamicResource CardBackgroundBrush}" BorderBrush="{DynamicResource CardBorderBrush}" BorderThickness="2" CornerRadius="8" Padding="10" Margin="0,15,0,0">
      <StackPanel Orientation="Horizontal" HorizontalAlignment="Center">
        <Button x:Name="btnOptimizeNow" Content="⚡ Quick Optimize" Width="140" Height="34" Style="{StaticResource DialogButton}" Margin="0,0,10,0"/>
        <Button x:Name="btnOpenTaskManager" Content="📊 Task Manager" Width="130" Height="34" Style="{StaticResource SecondaryDialogButton}" Margin="0,0,10,0"/>
        <Button x:Name="btnCloseHealth" Content="Close" Width="100" Height="34" Style="{StaticResource WarningDialogButton}"/>
      </StackPanel>
    </Border>
  </Grid>
</Window>
'@

        # Create the window
        $reader = New-Object System.Xml.XmlNodeReader $healthDialogXaml
        $healthWindow = [Windows.Markup.XamlReader]::Load($reader)
        Initialize-LayoutSpacing -Root $healthWindow

        # Get controls
        $lblHealthStatus = $healthWindow.FindName('lblHealthStatus')
        $lblHealthScore = $healthWindow.FindName('lblHealthScore')
        $lblCpuMetric = $healthWindow.FindName('lblCpuMetric')
        $lblMemoryMetric = $healthWindow.FindName('lblMemoryMetric')
        $lblDiskMetric = $healthWindow.FindName('lblDiskMetric')
        $lstIssues = $healthWindow.FindName('lstIssues')
        $lstRecommendations = $healthWindow.FindName('lstRecommendations')
        $btnRefreshHealth = $healthWindow.FindName('btnRefreshHealth')
        $btnOptimizeNow = $healthWindow.FindName('btnOptimizeNow')
        $btnOpenTaskManager = $healthWindow.FindName('btnOpenTaskManager')
        $btnCloseHealth = $healthWindow.FindName('btnCloseHealth')

        # Update display function
        $updateDisplay = {
            param([bool]$RunCheck = $false)

            $data = Update-SystemHealthDisplay -RunCheck:$RunCheck

            if (-not $data.LastHealthCheck) {
                $lblHealthStatus.Text = 'Status: Not Run'
                $lblHealthScore.Text = 'Health Score: N/A'
                $lblCpuMetric.Text = '--%'
                $lblMemoryMetric.Text = '--%'
                if ($lblDiskMetric) { $lblDiskMetric.Text = '--%' }
                $lstIssues.ItemsSource = @()
                $lstRecommendations.ItemsSource = @("Click Refresh to run a health check.")
                return

            }

            $timestamp = $data.LastHealthCheck.ToString('g')
            $lblHealthStatus.Text = "Status: $($data.HealthStatus) (Last: $timestamp)"
            if ($data.HealthScore -ne $null) {
                $lblHealthScore.Text = "Health Score: $($data.HealthScore)%"
            } else {
                $lblHealthScore.Text = 'Health Score: N/A'
            }

            if ($data.Metrics.ContainsKey('CpuUsage') -and $data.Metrics.CpuUsage -ne $null) {
                $lblCpuMetric.Text = "$($data.Metrics.CpuUsage)%"
            } else {
                $lblCpuMetric.Text = '--%'
            }

            if ($data.Metrics.ContainsKey('MemoryUsage') -and $data.Metrics.MemoryUsage -ne $null) {
                $lblMemoryMetric.Text = "$($data.Metrics.MemoryUsage)%"
            } else {
                $lblMemoryMetric.Text = '--%'

            # Disk metric intentionally omitted (legacy compatibility)

            $issues = @()
            if ($data.Issues) { $issues += $data.Issues }
            if ($data.HealthWarnings) { $issues += $data.HealthWarnings }
            $lstIssues.ItemsSource = $issues

            if ($data.Recommendations) {
                $lstRecommendations.ItemsSource = $data.Recommendations
            } else {
                $lstRecommendations.ItemsSource = @('No recommendations available. Great job!')

            Log "System health dialog updated with cached status: $($data.HealthStatus)" 'Info'

        # Event handlers
        $btnRefreshHealth.Add_Click({
            Log "Manual health check requested from System Health dialog" 'Info'
            # removed invalid call $true
        })

        $btnOptimizeNow.Add_Click({
            if ($btnApply) {
                Log "Quick optimization triggered from System Health dialog" 'Info'
                $healthWindow.Close()

                    $btnApply.RaiseEvent([System.Windows.RoutedEventArgs]::new([System.Windows.Controls.Primitives.ButtonBase]::ClickEvent))
                    Log "Error triggering optimization from health dialog: $($_.Exception.Message)" 'Error'
                }
            } else {
                [System.Windows.MessageBox]::Show("Quick optimization is not available. Please use the main optimization features.", "Optimization", 'OK', 'Information')

        $btnOpenTaskManager.Add_Click({
                Start-Process "taskmgr.exe" -ErrorAction Stop
                Log "Task Manager opened from System Health dialog" 'Info'
                Log "Error opening Task Manager: $($_.Exception.Message)" 'Warning'
                [System.Windows.MessageBox]::Show("Could not open Task Manager: $($_.Exception.Message)", "Task Manager Error", 'OK', 'Warning')
            }

        $btnCloseHealth.Add_Click({
            Log "System Health dialog closed by user" 'Info'
            $healthWindow.Close()
        })

        # Initial display update using cached data (no automatic check)
        # removed invalid call $false

        # Show the window
        $healthWindow.ShowDialog() | Out-Null

        Log "Error showing system health dialog: $($_.Exception.Message)" 'Error'
        [System.Windows.MessageBox]::Show("Error displaying system health window: $($_.Exception.Message)", "Health Monitor Error", 'OK', 'Error')

function Search-LogHistory {
    <#
    .SYNOPSIS
    Searches log history with advanced filtering capabilities
    .PARAMETER SearchTerm
    Text to search for in log messages
    .PARAMETER Level
    Filter by log level
    .PARAMETER Category
    Filter by log category
    .PARAMETER StartDate
    Filter logs from this date
    .PARAMETER EndDate
    Filter logs to this date
    #>
    param(
        [string]$SearchTerm = "",
        [string[]]$Level = @(),
        [string]$Category = "All",
        [DateTime]$StartDate = (Get-Date).AddDays(-1),
        [DateTime]$EndDate = (Get-Date)
    )

        $results = $global:LogHistory | Where-Object {
            # Date range filter
            $_.Timestamp -ge $StartDate -and $_.Timestamp -le $EndDate

        }

        # Search term filter
        if ($SearchTerm) {
            $results = $results | Where-Object { $_.Message -match [regex]::Escape($SearchTerm) }
        }

        # Level filter
        if ($Level.Count -gt 0) {
            $results = $results | Where-Object { $_.Level -in $Level }
        }

        # Category filter
        if ($Category -ne "All") {
            $results = $results | Where-Object { $_.Category -eq $Category }
        }

        return $results | Sort-Object Timestamp -Descending

        Log "Error searching log history: $($_.Exception.Message)" 'Error'
        return @()

    }

function Export-LogHistory {
    <#
    .SYNOPSIS
    Exports log history to various formats (TXT, CSV, JSON)
    .PARAMETER Path
    Export file path
    .PARAMETER Format
    Export format (TXT, CSV, JSON)
    .PARAMETER FilteredResults
    Pre-filtered log entries to export
    #>
    param(
        [string]$Path,
        [ValidateSet("TXT", "CSV", "JSON")]
        [string]$Format = "TXT",
        [array]$FilteredResults = $null
    )

        $logsToExport = if ($FilteredResults) { $FilteredResults } else { $global:LogHistory }

        if ($logsToExport.Count -eq 0) {
            throw "No log entries to export"

        }

        switch ($Format) {
            "TXT" {
                $content = $logsToExport | ForEach-Object {
                    "[$($_.Timestamp.ToString('yyyy-MM-dd HH:mm:ss'))] [$($_.Level)] [$($_.Category)] $($_.Message)"
                }
                $content | Out-File -FilePath $Path -Encoding UTF8
            }
            "CSV" {
                $logsToExport | Select-Object Timestamp, Level, Category, Message, Thread | Export-Csv -Path $Path -NoTypeInformation -Encoding UTF8
            }
            "JSON" {
                $logsToExport | ConvertTo-Json -Depth 3 | Out-File -FilePath $Path -Encoding UTF8
            }
        }

        Log "Log history exported to: $Path ($Format format, $($logsToExport.Count) entries)" 'Success'
        return $true

        Log "Error exporting log history: $($_.Exception.Message)" 'Error'
        return $false
    }

function Optimize-LogFile {
    <#
    .SYNOPSIS
    Optimizes and rotates log files when they become too large
    .PARAMETER MaxSizeMB
    Maximum log file size in MB before rotation
    #>
    param([int]$MaxSizeMB = 10)

        $logFilePath = Join-Path $ScriptRoot 'Koala-Activity.log'

        if (Test-Path $logFilePath) {
            $fileInfo = Get-Item $logFilePath
            $fileSizeMB = [math]::Round($fileInfo.Length / 1MB, 2)

            if ($fileSizeMB -gt $MaxSizeMB) {
                # Create backup of current log
                $backupPath = Join-Path $ScriptRoot "Koala-Activity.log.bak.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
                Copy-Item $logFilePath $backupPath -Force

                # Keep only last 500 lines in main log
                $lastLines = Get-Content $logFilePath -Tail 500
                $lastLines | Out-File $logFilePath -Encoding UTF8

                Log "Log file rotated: $fileSizeMB MB -> backup created at $backupPath" 'Info'

                # Clean up old backup files (keep only 5 most recent)
                $backupFiles = Get-ChildItem -Path $ScriptRoot -Name "Koala-Activity.log.bak.*" | Sort-Object Name -Descending
                if ($backupFiles.Count -gt 5) {
                    $filesToDelete = $backupFiles | Select-Object -Skip 5
                    foreach ($file in $filesToDelete) {
                        Remove-Item (Join-Path $ScriptRoot $file) -Force -ErrorAction SilentlyContinue

                    }
                }
            }
        }

        Log "Error optimizing log file: $($_.Exception.Message)" 'Warning'
    }

function Show-LogSearchDialog {
    <#
    .SYNOPSIS
    Shows a search dialog for log history with filtering options
    .DESCRIPTION
    Creates a WPF dialog for advanced log searching and filtering
    #>

        [xml]$logSearchXaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Log Search and Filter"
        Width="900" Height="700"
        Background="{StaticResource AppBackgroundBrush}"
        WindowStartupLocation="CenterScreen"
        ResizeMode="CanResize">

  <Window.Resources>
    <SolidColorBrush x:Key="DialogBackgroundBrush" Color="#080716"/>
    <SolidColorBrush x:Key="CardBackgroundBrush" Color="#14132B"/>
    <SolidColorBrush x:Key="CardBorderBrush" Color="#2F285A"/>
    <SolidColorBrush x:Key="AccentBrush" Color="#8F6FFF"/>
    <SolidColorBrush x:Key="PrimaryTextBrush" Color="#F5F3FF"/>
    <SolidColorBrush x:Key="SecondaryTextBrush" Color="#A9A5D9"/>
    <Style TargetType="TextBlock">
        <Setter Property="FontFamily" Value="Segoe UI"/>
        <Setter Property="FontSize" Value="12"/>
        <Setter Property="Foreground" Value="{StaticResource PrimaryTextBrush}"/>
    </Style>
    <Style TargetType="ComboBox">
        <Setter Property="FontFamily" Value="Segoe UI"/>
        <Setter Property="FontSize" Value="12"/>
        <Setter Property="Background" Value="#1B2345"/>
        <Setter Property="Foreground" Value="{StaticResource PrimaryTextBrush}"/>
        <Setter Property="BorderBrush" Value="{StaticResource AccentBrush}"/>
        <Setter Property="BorderThickness" Value="1"/>
    </Style>
    <Style TargetType="Button" x:Key="DialogButton">
        <Setter Property="FontFamily" Value="Segoe UI"/>
        <Setter Property="FontSize" Value="12"/>
        <Setter Property="Foreground" Value="#120B22"/>
        <Setter Property="Background" Value="{StaticResource AccentBrush}"/>
        <Setter Property="BorderThickness" Value="0"/>
        <Setter Property="Padding" Value="14,6"/>
        <Setter Property="FontWeight" Value="SemiBold"/>
        <Setter Property="Cursor" Value="Hand"/>
        <Setter Property="Template">
            <Setter.Value>
                <ControlTemplate TargetType="Button">
                    <Border Background="{TemplateBinding Background}" CornerRadius="10">
                        <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                    </Border>
                    <ControlTemplate.Triggers>
                        <Trigger Property="IsMouseOver" Value="True">
                            <Setter Property="Background" Value="#A78BFA"/>
                        </Trigger>
                        <Trigger Property="IsEnabled" Value="False">
                            <Setter Property="Opacity" Value="0.4"/>
                        </Trigger>
                    </ControlTemplate.Triggers>
                </ControlTemplate>
            </Setter.Value>
        </Setter>
    </Style>
    <Style x:Key="SecondaryDialogButton" TargetType="Button" BasedOn="{StaticResource DialogButton}">
        <Setter Property="Background" Value="#1F1B3F"/>
        <Setter Property="Foreground" Value="{StaticResource PrimaryTextBrush}"/>
    </Style>
    <Style x:Key="DangerDialogButton" TargetType="Button" BasedOn="{StaticResource DialogButton}">
        <Setter Property="Background" Value="#F87171"/>
        <Setter Property="Foreground" Value="#21060B"/>
    </Style>
  </Window.Resources>

  <Grid Margin="15">
    <Grid.RowDefinitions>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="*"/>
      <RowDefinition Height="Auto"/>
    </Grid.RowDefinitions>

    <!-- Header -->
    <Border Grid.Row="0" Background="{DynamicResource CardBackgroundBrush}" BorderBrush="{DynamicResource CardBorderBrush}" BorderThickness="2" CornerRadius="8" Padding="15" Margin="0,0,0,15">
      <TextBlock Text="Log Search and Filter" Foreground="{DynamicResource AccentBrush}" FontWeight="Bold" FontSize="18" HorizontalAlignment="Center"/>
    </Border>

    <!-- Search Controls -->
    <Border Grid.Row="1" Background="{DynamicResource CardBackgroundBrush}" BorderBrush="{DynamicResource CardBorderBrush}" BorderThickness="2" CornerRadius="8" Padding="15" Margin="0,0,0,15">
      <Grid>
        <Grid.RowDefinitions>
          <RowDefinition Height="Auto"/>
          <RowDefinition Height="Auto"/>
          <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        <Grid.ColumnDefinitions>
          <ColumnDefinition Width="*"/>
          <ColumnDefinition Width="*"/>
          <ColumnDefinition Width="Auto"/>
        </Grid.ColumnDefinitions>

        <!-- Search Term -->
        <StackPanel Grid.Row="0" Grid.Column="0" Margin="0,0,10,10">
          <TextBlock Text="Search Term:" Foreground="{DynamicResource PrimaryTextBrush}" FontSize="12" Margin="0,0,0,5"/>
          <TextBox x:Name="txtSearchTerm" Height="25" Background="{DynamicResource CardBackgroundBrush}" Foreground="{DynamicResource PrimaryTextBrush}" BorderBrush="{DynamicResource CardBorderBrush}"/>
        </StackPanel>

        <!-- Category Filter -->
        <StackPanel Grid.Row="0" Grid.Column="1" Margin="0,0,0,10">
          <TextBlock Text="Category:" Foreground="{DynamicResource PrimaryTextBrush}" FontSize="12" Margin="0,0,0,5"/>
          <ComboBox x:Name="cmbCategory" Height="25" Background="{DynamicResource CardBackgroundBrush}" Foreground="{DynamicResource PrimaryTextBrush}" BorderBrush="{DynamicResource CardBorderBrush}"/>
        </StackPanel>

        <!-- Search Button -->
        <Button x:Name="btnSearch" Grid.Row="0" Grid.Column="2" Content="Search" Width="80" Height="25"
                Background="{StaticResource CardBorderBrush}" Foreground="{DynamicResource PrimaryTextBrush}" BorderThickness="0" FontWeight="SemiBold"
                VerticalAlignment="Bottom" Margin="10,0,0,10"/>

        <!-- Level Checkboxes -->
        <StackPanel Grid.Row="1" Grid.ColumnSpan="3" Orientation="Horizontal" Margin="0,0,0,10">
          <TextBlock Text="Levels:" Foreground="{DynamicResource PrimaryTextBrush}" FontSize="12" Margin="0,0,10,0" VerticalAlignment="Center"/>
          <CheckBox x:Name="chkInfo" Content="Info" Foreground="{DynamicResource PrimaryTextBrush}" IsChecked="True" Margin="0,0,15,0"/>
          <CheckBox x:Name="chkSuccess" Content="Success" Foreground="{DynamicResource PrimaryTextBrush}" IsChecked="True" Margin="0,0,15,0"/>
          <CheckBox x:Name="chkWarning" Content="Warning" Foreground="{DynamicResource PrimaryTextBrush}" IsChecked="True" Margin="0,0,15,0"/>
          <CheckBox x:Name="chkError" Content="Error" Foreground="{DynamicResource PrimaryTextBrush}" IsChecked="True" Margin="0,0,15,0"/>
          <CheckBox x:Name="chkContext" Content="Context" Foreground="{DynamicResource PrimaryTextBrush}" IsChecked="False" Margin="0,0,15,0"/>
        </StackPanel>

        <!-- Results Info -->
        <TextBlock x:Name="lblResultsInfo" Grid.Row="2" Grid.ColumnSpan="3"
                   Text="Total log entries: 0" Foreground="{DynamicResource SecondaryTextBrush}" FontSize="11"/>
      </Grid>
    </Border>

    <!-- Results List -->
    <Border Grid.Row="2" Background="{DynamicResource CardBackgroundBrush}" BorderBrush="{DynamicResource CardBorderBrush}" BorderThickness="2" CornerRadius="8" Padding="10">
      <ScrollViewer VerticalScrollBarVisibility="Auto">
        <ListBox x:Name="lstLogResults" Background="Transparent" BorderThickness="0" Foreground="{DynamicResource PrimaryTextBrush}" FontSize="11" FontFamily="Consolas">
          <ListBox.ItemTemplate>
            <DataTemplate>
              <Border Background="{DynamicResource CardBackgroundBrush}" BorderBrush="{DynamicResource CardBorderBrush}" BorderThickness="1" CornerRadius="3" Padding="8" Margin="2">
                <StackPanel>
                  <StackPanel Orientation="Horizontal">
                    <TextBlock Text="{Binding Timestamp, StringFormat='yyyy-MM-dd HH:mm:ss'}" FontWeight="Bold" FontSize="10" Foreground="{DynamicResource AccentBrush}" Margin="0,0,10,0"/>
                    <TextBlock Text="{Binding Level}" FontWeight="Bold" FontSize="10" Foreground="{DynamicResource AccentBrush}" Margin="0,0,10,0"/>
                    <TextBlock Text="{Binding Category}" FontSize="10" Foreground="{DynamicResource AccentBrush}" Margin="0,0,0,0"/>
                  </StackPanel>
                  <TextBlock Text="{Binding Message}" FontSize="11" Foreground="{DynamicResource PrimaryTextBrush}" Margin="0,3,0,0" TextWrapping="Wrap"/>
                </StackPanel>
              </Border>
            </DataTemplate>
          </ListBox.ItemTemplate>
        </ListBox>
      </ScrollViewer>
    </Border>

    <!-- Action Buttons -->
    <Border Grid.Row="3" Background="{DynamicResource CardBackgroundBrush}" BorderBrush="{DynamicResource CardBorderBrush}" BorderThickness="2" CornerRadius="8" Padding="10" Margin="0,15,0,0">
      <StackPanel Orientation="Horizontal" HorizontalAlignment="Center">
        <Button x:Name="btnExportTXT" Content="Export TXT" Width="110" Height="32" Style="{StaticResource SecondaryDialogButton}" Margin="0,0,10,0"/>
        <Button x:Name="btnExportCSV" Content="Export CSV" Width="110" Height="32" Style="{StaticResource SecondaryDialogButton}" Margin="0,0,10,0"/>
        <Button x:Name="btnExportJSON" Content="Export JSON" Width="110" Height="32" Style="{StaticResource SecondaryDialogButton}" Margin="0,0,10,0"/>
        <Button x:Name="btnClearSearch" Content="Clear" Width="90" Height="32" Style="{StaticResource DialogButton}" Margin="0,0,10,0"/>
        <Button x:Name="btnCloseSearch" Content="Close" Width="90" Height="32" Style="{StaticResource SecondaryDialogButton}"/>
      </StackPanel>
    </Border>
  </Grid>
</Window>
'@

        # Create the window
        $reader = New-Object System.Xml.XmlNodeReader $logSearchXaml
        $searchWindow = [Windows.Markup.XamlReader]::Load($reader)
        Initialize-LayoutSpacing -Root $searchWindow

        # Get controls
        $txtSearchTerm = $searchWindow.FindName('txtSearchTerm')
        $cmbCategory = $searchWindow.FindName('cmbCategory')
        $btnSearch = $searchWindow.FindName('btnSearch')
        $chkInfo = $searchWindow.FindName('chkInfo')
        $chkSuccess = $searchWindow.FindName('chkSuccess')
        $chkWarning = $searchWindow.FindName('chkWarning')
        $chkError = $searchWindow.FindName('chkError')
        $chkContext = $searchWindow.FindName('chkContext')
        $lblResultsInfo = $searchWindow.FindName('lblResultsInfo')
        $lstLogResults = $searchWindow.FindName('lstLogResults')
        $btnExportTXT = $searchWindow.FindName('btnExportTXT')
        $btnExportCSV = $searchWindow.FindName('btnExportCSV')
        $btnExportJSON = $searchWindow.FindName('btnExportJSON')
        $btnClearSearch = $searchWindow.FindName('btnClearSearch')
        $btnCloseSearch = $searchWindow.FindName('btnCloseSearch')

        # Initialize category dropdown
        $global:LogCategories | ForEach-Object { $cmbCategory.Items.Add($_) }
        $cmbCategory.SelectedIndex = 0

        # Update results info
        $lblResultsInfo.Text = "Total log entries: $($global:LogHistory.Count)"

        # Search function
        $performSearch = {
            $searchTerm = $txtSearchTerm.Text
            $category = $cmbCategory.SelectedItem.ToString()

            $levels = @()
            if ($chkInfo.IsChecked) { $levels += "Info" }
            if ($chkSuccess.IsChecked) { $levels += "Success" }
            if ($chkWarning.IsChecked) { $levels += "Warning" }
            if ($chkError.IsChecked) { $levels += "Error" }
            if ($chkContext.IsChecked) { $levels += "Context" }

            $results = Search-LogHistory -SearchTerm $searchTerm -Level $levels -Category $category

            $lstLogResults.ItemsSource = $results
            $lblResultsInfo.Text = "Search results: $($results.Count) entries (Total: $($global:LogHistory.Count))"

            Log "Log search performed: '$searchTerm' in $category category, $($results.Count) results" 'Info'

        }

        # Event handlers
$btnSearch.Add_Click({
    try {
        $searchTerm = $txtSearchTerm.Text
        $category   = if ($cmbCategory.SelectedItem) { $cmbCategory.SelectedItem.Content } else { 'All' }
        $levels = @(); if ($chkInfo.IsChecked){$levels+='Info'}; if($chkWarning.IsChecked){$levels+='Warning'}; if($chkError.IsChecked){$levels+='Error'}
        $results = Search-LogHistory -SearchTerm $searchTerm -Level $levels -Category $category
        $lstLogResults.ItemsSource = $results
        $lblResultsInfo.Text = "Search results: $($results.Count) entries (Total: $($global:LogHistory.Count))"
        Log "Log search performed via button: '$searchTerm'" 'Info'
})
$txtSearchTerm.Add_KeyDown({
    if ($_.Key -eq 'Return') { $btnSearch.RaiseEvent([System.Windows.RoutedEventArgs]::new([System.Windows.Controls.Button]::ClickEvent)) }
})
        $levels = @(); if ($chkInfo.IsChecked){$levels+='Info'}; if($chkWarning.IsChecked){$levels+='Warning'}; if($chkError.IsChecked){$levels+='Error'}
        $results = Search-LogHistory -SearchTerm $searchTerm -Level $levels -Category $category
        $lstLogResults.ItemsSource = $results
        $lblResultsInfo.Text = "Search results: $($results.Count) entries (Total: $($global:LogHistory.Count))"
        Log "Log search performed via button: '$searchTerm'" 'Info'
})
            if ($saveDialog.ShowDialog()) {
                $results = $lstLogResults.ItemsSource
                Export-LogHistory -Path $saveDialog.FileName -Format "TXT" -FilteredResults $results
            }
        })

        $btnExportCSV.Add_Click({
            $saveDialog = New-Object Microsoft.Win32.SaveFileDialog
            $saveDialog.Filter = "CSV files (*.csv)|*.csv"
            $saveDialog.Title = "Export Log History as CSV"
            $saveDialog.FileName = "KOALA-GameOptimizer-Logs-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"

            if ($saveDialog.ShowDialog()) {
                $results = $lstLogResults.ItemsSource
                Export-LogHistory -Path $saveDialog.FileName -Format "CSV" -FilteredResults $results
            }
        })

        $btnExportJSON.Add_Click({
            $saveDialog = New-Object Microsoft.Win32.SaveFileDialog
            $saveDialog.Filter = "JSON files (*.json)|*.json"
            $saveDialog.Title = "Export Log History as JSON"
            $saveDialog.FileName = "KOALA-GameOptimizer-Logs-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"

            if ($saveDialog.ShowDialog()) {
                $results = $lstLogResults.ItemsSource
                Export-LogHistory -Path $saveDialog.FileName -Format "JSON" -FilteredResults $results
            }
        })

        $btnClearSearch.Add_Click({
            $txtSearchTerm.Text = ""
            $cmbCategory.SelectedIndex = 0
            $chkInfo.IsChecked = $true
            $chkSuccess.IsChecked = $true
            $chkWarning.IsChecked = $true
            $chkError.IsChecked = $true
            $chkContext.IsChecked = $false
            $lstLogResults.ItemsSource = $null
            $lblResultsInfo.Text = "Total log entries: $($global:LogHistory.Count)"
        })

        $btnCloseSearch.Add_Click({
            $searchWindow.Close()
        })

        # Show initial results (all logs)
        # removed invalid call

        # Show the window
        $searchWindow.ShowDialog() | Out-Null

        Log "Error showing log search dialog: $($_.Exception.Message)" 'Error'
        [System.Windows.MessageBox]::Show("Error displaying log search window: $($_.Exception.Message)", "Log Search Error", 'OK', 'Error')
$global:PerformanceTimer = $null
$global:LastCpuTime = @{ Idle = 0; Kernel = 0; User = 0; Timestamp = [DateTime]::Now }

function Get-SystemPerformanceMetrics {
    <#
    .SYNOPSIS
    Enhanced real-time system performance monitoring with CPU, Memory, and basic disk metrics
    .DESCRIPTION
    Provides comprehensive system metrics for dashboard display with efficient polling
    #>

        $metrics = @{}

        # Get CPU Usage using existing PerfMon API
        try {
            $idleTime = [long]0
            $kernelTime = [long]0
            $userTime = [long]0

            if ([PerfMon]::GetSystemTimes([ref]$idleTime, [ref]$kernelTime, [ref]$userTime)) {
            $currentTime = [DateTime]::Now
            $timeDiff = ($currentTime - $global:LastCpuTime.Timestamp).TotalMilliseconds

            if ($timeDiff -gt 500 -and $global:LastCpuTime.Idle -gt 0) {
                $idleDiff = $idleTime - $global:LastCpuTime.Idle
                $kernelDiff = $kernelTime - $global:LastCpuTime.Kernel
                $userDiff = $userTime - $global:LastCpuTime.User
                $totalDiff = $kernelDiff + $userDiff

                if ($totalDiff -gt 0) {
                    $cpuUsage = [Math]::Round((($totalDiff - $idleDiff) / $totalDiff) * 100, 1)
                    $metrics.CpuUsage = [Math]::Max(0, [Math]::Min(100, $cpuUsage))
                } else {
                    $metrics.CpuUsage = 0

                }
            } else {
                $metrics.CpuUsage = 0
            }
        } else {
            $metrics.CpuUsage = 0
            # Safe defaults on error for Windows API performance monitoring calls
            $metrics.CpuUsage = 0
            Write-Verbose "CPU monitoring failed: $($_.Exception.Message)"

        # Update LastCpuTime with Idle, Kernel, User times and Timestamp for accurate CPU delta calculations
        $global:LastCpuTime = @{
            Idle = $idleTime
            Kernel = $kernelTime
            User = $userTime
            Timestamp = $currentTime
        }

        # Get Memory Usage using existing PerfMon API
            $memStatus = New-Object PerfMon+MEMORYSTATUSEX
            $memStatus.dwLength = [System.Runtime.InteropServices.Marshal]::SizeOf($memStatus)

            if ([PerfMon]::GlobalMemoryStatusEx([ref]$memStatus)) {
            # Math.Round calculations for accurate GB conversions and percentage
            $totalGB = [Math]::Round($memStatus.ullTotalPhys / 1GB, 1)
            $availableGB = [Math]::Round($memStatus.ullAvailPhys / 1GB, 1)
            $usedGB = [Math]::Round($totalGB - $availableGB, 1)
            $usagePercent = [Math]::Round($memStatus.dwMemoryLoad, 1)

            $metrics.MemoryUsedGB = $usedGB
            $metrics.MemoryTotalGB = $totalGB
            $metrics.MemoryUsagePercent = $usagePercent

        } else {
            $metrics.MemoryUsedGB = 0
            $metrics.MemoryTotalGB = 0
            $metrics.MemoryUsagePercent = 0
            # Safe defaults on error for memory monitoring Windows API calls
            $metrics.MemoryUsedGB = 0
            $metrics.MemoryTotalGB = 0
            $metrics.MemoryUsagePercent = 0
            Write-Verbose "Memory monitoring failed: $($_.Exception.Message)"

        # Get Active Games Count (from existing global variable)
        $metrics.ActiveGamesCount = if ($global:ActiveGames) { $global:ActiveGames.Count } else { 0 }

        # Get Last Optimization Time (from logs or global variable)
        if ($global:LastOptimizationTime) {
            $timeSince = (Get-Date) - $global:LastOptimizationTime
            if ($timeSince.Days -gt 0) {
                $metrics.LastOptimization = "$($timeSince.Days)d ago"
            } elseif ($timeSince.Hours -gt 0) {
                $metrics.LastOptimization = "$($timeSince.Hours)h ago"
            } elseif ($timeSince.Minutes -gt 0) {
                $metrics.LastOptimization = "$($timeSince.Minutes)m ago"
                $metrics.LastOptimization = "Just now"
            $metrics.LastOptimization = "Never"

        return $metrics

        # Return safe defaults on error
        return @{
            CpuUsage = 0
            MemoryUsedGB = 0
            MemoryTotalGB = 0
            MemoryUsagePercent = 0
            ActiveGamesCount = 0
            LastOptimization = "Error"
        }

function Update-DashboardMetrics {
    <#
    .SYNOPSIS
    Updates dashboard performance metrics with real-time data
    .DESCRIPTION
    Safely updates dashboard UI elements with current system performance data
    #>

        $metrics = Get-SystemPerformanceMetrics

        # Update CPU Usage
        if ($lblDashCpuUsage) {
            $lblDashCpuUsage.Dispatcher.Invoke([Action]{
                $lblDashCpuUsage.Text = "$($metrics.CpuUsage)%"

                # Color coding based on CpuUsage and MemoryUsagePercent for dynamic metrics display
                if ($metrics.CpuUsage -ge 80) {
                    Set-BrushPropertySafe -Target $lblDashCpuUsage -Property 'Foreground' -Value '#FF4444'  # Red for high

                } elseif ($metrics.CpuUsage -ge 60) {
                    Set-BrushPropertySafe -Target $lblDashCpuUsage -Property 'Foreground' -Value '#A78BFA'  # Purple for medium load
                } else {
                    Set-BrushPropertySafe -Target $lblDashCpuUsage -Property 'Foreground' -Value '#8F6FFF'  # Accent for low load
                }
            })

        # Update Memory Usage
        if ($lblDashMemoryUsage) {
            $lblDashMemoryUsage.Dispatcher.Invoke([Action]{
                $lblDashMemoryUsage.Text = "$($metrics.MemoryUsedGB) / $($metrics.MemoryTotalGB) GB"

                # Color coding based on percentage
                if ($metrics.MemoryUsagePercent -ge 85) {
                    Set-BrushPropertySafe -Target $lblDashMemoryUsage -Property 'Foreground' -Value '#FF4444'  # Red for high
                } elseif ($metrics.MemoryUsagePercent -ge 70) {
                    Set-BrushPropertySafe -Target $lblDashMemoryUsage -Property 'Foreground' -Value '#A78BFA'  # Purple for medium
                } else {
                    Set-BrushPropertySafe -Target $lblDashMemoryUsage -Property 'Foreground' -Value '#8F6FFF'  # Accent for normal
                }

        if ($lblHeroProfiles) {
            $lblHeroProfiles.Dispatcher.Invoke([Action]{
                $lblHeroProfiles.Text = [string]$metrics.ActiveGamesCount
            })
        }

        $optimizationsCount = if ($global:OptimizationCache) { $global:OptimizationCache.Count } else { 0 }
        if ($lblHeroOptimizations) {
            $lblHeroOptimizations.Dispatcher.Invoke([Action]{
                $lblHeroOptimizations.Text = [string]$optimizationsCount
            })
        }

        if ($lblHeroAutoMode) {
            $lblHeroAutoMode.Dispatcher.Invoke([Action]{
                $lblHeroAutoMode.Text = if ($global:AutoOptimizeEnabled) { 'On' } else { 'Off' }
            })
        }

        # Update Active Games
        if ($lblDashActiveGames) {
            $lblDashActiveGames.Dispatcher.Invoke([Action]{
                if ($metrics.ActiveGamesCount -gt 0) {
                    $lblDashActiveGames.Text = "$($metrics.ActiveGamesCount) running"
                    Set-BrushPropertySafe -Target $lblDashActiveGames -Property 'Foreground' -Value '#8F6FFF'  # Accent for active games
                } else {
                    $lblDashActiveGames.Text = "None detected"
                    Set-BrushPropertySafe -Target $lblDashActiveGames -Property 'Foreground' -Value '#A6AACF'  # Default color
                }
            })

        # Update Last Optimization
        if ($lblDashLastOptimization) {
            $lblDashLastOptimization.Dispatcher.Invoke([Action]{
                $lblDashLastOptimization.Text = $metrics.LastOptimization
            })
        }

        if ($lblHeaderLastRun) {
            $lblHeaderLastRun.Dispatcher.Invoke([Action]{
                $lblHeaderLastRun.Text = $metrics.LastOptimization
            })
        }

        if ($lblHeaderSystemStatus) {
            $lblHeaderSystemStatus.Dispatcher.Invoke([Action]{
                if ($metrics.CpuUsage -ge 80 -or $metrics.MemoryUsagePercent -ge 85) {
                    $lblHeaderSystemStatus.Text = 'High Load'
                    Set-BrushPropertySafe -Target $lblHeaderSystemStatus -Property 'Foreground' -Value [System.Windows.Media.Brushes]::Salmon
                } elseif ($metrics.CpuUsage -ge 60 -or $metrics.MemoryUsagePercent -ge 70) {
                    $lblHeaderSystemStatus.Text = 'Monitoring'
                    Set-BrushPropertySafe -Target $lblHeaderSystemStatus -Property 'Foreground' -Value [System.Windows.Media.Brushes]::Gold
                } else {
                    $lblHeaderSystemStatus.Text = 'Stable'
                    Set-BrushPropertySafe -Target $lblHeaderSystemStatus -Property 'Foreground' -Value [System.Windows.Media.Brushes]::LightGreen
                }

        # Refresh System Health summary without running a full check
        Update-SystemHealthSummary

        # Silent fail to prevent UI disruption
        Write-Verbose "Dashboard metrics update failed: $($_.Exception.Message)"

function Start-PerformanceMonitoring {
    <#
    .SYNOPSIS
    Starts real-time performance monitoring with configurable update interval
    .DESCRIPTION
    Initializes a dispatcher timer for regular dashboard updates
    #>

        if ($global:PerformanceTimer) {
            $global:PerformanceTimer.Stop()

        }

        # Create dispatcher timer for UI updates
        $global:PerformanceTimer = New-Object System.Windows.Threading.DispatcherTimer
        $global:PerformanceTimer.Interval = [TimeSpan]::FromSeconds(3)  # Update every 3 seconds

        # Set up timer event
        $global:PerformanceTimer.Add_Tick({
            Update-DashboardMetrics
        })

        # Start the timer
        $global:PerformanceTimer.Start()

        # Initial update
        Update-DashboardMetrics

        Log "Real-time performance monitoring started (3s intervals)" 'Success'

        Log "Error starting performance monitoring: $($_.Exception.Message)" 'Error'
    }

function Stop-PerformanceMonitoring {
    <#
    .SYNOPSIS
    Stops the performance monitoring timer
    #>

        if ($global:PerformanceTimer) {
            $global:PerformanceTimer.Stop()
            $global:PerformanceTimer = $null
            Log "Performance monitoring stopped" 'Info'

        }
        Write-Verbose "Error stopping performance monitoring: $($_.Exception.Message)"
    }

# ---------- Functions moved to top to fix call order ----------

function Show-ElevationMessage {
    param(
        [string]$Title = "Administrator Privileges Required",
        [string]$Message = "Some optimizations require administrator privileges for system-level changes.",
        [string[]]$Operations = @(),
        [switch]$ForceElevation
    )

    $elevationText = $Message
    if ($Operations.Count -gt 0) {
        $elevationText += "`n`nOperations requiring elevation:"
        $Operations | ForEach-Object { $elevationText += "`n* $_" }
    }

    $elevationText += "`n`nWould you like to:"
    $elevationText += "`n* Yes: Restart with administrator privileges"
    $elevationText += "`n* No: Continue with limited functionality"
    $elevationText += "`n* Cancel: Exit application"

    $result = [System.Windows.MessageBox]::Show(
        $elevationText,
        "KOALA Gaming Optimizer v3.0 - $Title",
        'YesNoCancel',
        'Warning'
    )

    switch ($result) {
        'Yes' {
                $scriptPath = $PSCommandPath
                if (-not $scriptPath) {
                    $scriptPath = Join-Path $ScriptRoot "koalafixed.ps1"

                }

                Start-Process -FilePath "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File `"$scriptPath`"" -Verb RunAs -ErrorAction Stop
                $form.Close()
                return $true
                Log "Failed to elevate privileges: $($_.Exception.Message)" 'Error'
                return $false
            }
        }
        'No' {
            Log "Running in limited mode - some optimizations will be unavailable" 'Warning'
            return $false
        }
        'Cancel' {
            Log "User cancelled - exiting application" 'Info'
            $form.Close()
            return $false
        }
    }

function Get-SystemInfo {
        $info = @{
            OS = (Get-CimInstance Win32_OperatingSystem).Caption
            CPU = (Get-CimInstance Win32_Processor).Name
            RAM = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
            GPU = (Get-CimInstance Win32_VideoController | Where-Object { $_.Name -notlike "*Basic*" -and $_.Name -notlike "*Generic*" }).Name -join ", "
            AdminRights = Test-AdminPrivileges
            PowerShellVersion = $PSVersionTable.PSVersion.ToString()

        }

        $infoText = "System Information:`n"
        $infoText += "OS: $($info.OS)`n"
        $infoText += "CPU: $($info.CPU)`n"
        $infoText += "RAM: $($info.RAM) GB`n"
        $infoText += "GPU: $($info.GPU)`n"
        $infoText += "Admin Rights: $($info.AdminRights)`n"
        $infoText += "PowerShell: $($info.PowerShellVersion)"

        [System.Windows.MessageBox]::Show($infoText, "System Information", 'OK', 'Information')

        Log "Failed to gather system info: $($_.Exception.Message)" 'Error'
    }

function Get-GPUVendor {
        $gpus = Get-CimInstance -ClassName Win32_VideoController -ErrorAction Stop | Where-Object {
            $_.Name -notlike "*Basic*" -and
            $_.Name -notlike "*Generic*" -and
            $_.PNPDeviceID -notlike "ROOT\*"

        }

        $primaryGPU = $null

        foreach ($gpu in $gpus) {
            if ($gpu -and $gpu.Name) {
                if ($gpu.Name -match 'NVIDIA|GeForce|GTX|RTX|Quadro') {
                    $primaryGPU = 'NVIDIA'
                }
                elseif ($gpu.Name -match 'AMD|RADEON|RX|FirePro') {
                    $primaryGPU = 'AMD'
                }
                elseif ($gpu.Name -match 'Intel|HD Graphics|UHD Graphics|Iris') {
                    $primaryGPU = 'Intel'
                }
            }
        }

        return if ($primaryGPU) { $primaryGPU } else { 'Other' }
        return 'Other'
    }

function Set-Reg {
    param($Path,$Name,$Type='DWord',$Value,$RequiresAdmin=$false)

    # Enhanced parameter validation
    if (-not $Path -or -not $Name) {
        Log "Set-Reg: Invalid parameters - Path: '$Path', Name: '$Name'" 'Error'
        return $false
    }

    # Admin privilege check
    if ($RequiresAdmin -and -not (Test-AdminPrivileges)) {
        Log "Set-Reg: Administrative privileges required for $Path\$Name" 'Warning'
        return $false
    }

    # Cache optimization
    $cacheKey = "$Path\$Name"
    if ($global:RegistryCache.ContainsKey($cacheKey) -and $global:RegistryCache[$cacheKey] -eq $Value) {
        Log "Set-Reg: Using cached value for $cacheKey" 'Info'
        return $true
    }

        # Enhanced parent path creation and checking
        $parentPaths = @()
        $currentPath = $Path

        # Build list of parent paths that need to be created
        while ($currentPath -and -not (Test-Path $currentPath -ErrorAction SilentlyContinue)) {
            $parentPaths += $currentPath
            $parent = Split-Path $currentPath -Parent
            if ($parent -eq $currentPath) { break } # Reached root
            $currentPath = $parent

        }

        # Create parent paths from top down
        for ($i = $parentPaths.Count - 1; $i -ge 0; $i--) {
            $pathToCreate = $parentPaths[$i]
                Log "Set-Reg: Creating registry path: $pathToCreate" 'Info'
                New-Item -Path $pathToCreate -Force -ErrorAction Stop | Out-Null
                Log "Set-Reg: Failed to create registry path '$pathToCreate': $($_.Exception.Message)" 'Error'
                return $false
            }
        }

        # Verify final path exists
        if (-not (Test-Path $Path -ErrorAction SilentlyContinue)) {
            Log "Set-Reg: Final path verification failed for: $Path" 'Error'
            return $false
        }

        # Set or update the registry value
        $valueExists = $null -ne (Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue)

        if ($valueExists) {
            Log "Set-Reg: Updating existing value $Path\$Name = $Value" 'Info'
            Set-ItemProperty -Path $Path -Name $Name -Value $Value -Force -ErrorAction Stop
        } else {
            Log "Set-Reg: Creating new value $Path\$Name = $Value (Type: $Type)" 'Info'
            New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $Type -Force -ErrorAction Stop | Out-Null

        # Verify the value was set correctly
        $verifyValue = Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue
        if ($null -ne $verifyValue -and $verifyValue.$Name -eq $Value) {
            $global:RegistryCache[$cacheKey] = $Value
            Log "Set-Reg: Successfully set and verified $Path\$Name = $Value" 'Success'
            return $true
        } else {
            Log "Set-Reg: Value verification failed for $Path\$Name" 'Error'
            return $false

        Log "Set-Reg: Error setting registry value ${Path}\${Name}: $($_.Exception.Message)" 'Error'
        return $false

function Get-Reg {
    param($Path, $Name)
        (Get-ItemProperty -Path $Path -Name $Name -ErrorAction Stop).$Name
        $null
    }

function Remove-Reg {
    param($Path, $Name)
        Remove-ItemProperty -Path $Path -Name $Name -Force -ErrorAction Stop
        return $true
        return $false
    }

