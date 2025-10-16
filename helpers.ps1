# ---------- Check PowerShell Version ----------
if ($PSVersionTable.PSVersion.Major -lt 5) {
    throw 'KOALA Optimizer requires PowerShell 5.0 or higher.'
}

# Detect whether the current platform supports the Windows-specific UI that the
# optimizer relies on. Older PowerShell builds do not expose the $IsWindows
# automatic variable, so fall back to the .NET APIs when necessary.
$script:IsWindowsPlatform = $false
$runtimeCheck = $false
$platformCheck = $false
try {
    $runtimeCheck = [System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform(
        [System.Runtime.InteropServices.OSPlatform]::Windows
    )
}
catch {
    $runtimeCheck = $false
}

try {
    $platformCheck = ([System.Environment]::OSVersion.Platform -eq [System.PlatformID]::Win32NT)
}
catch {
    $platformCheck = $false
}

$script:IsWindowsPlatform = ($runtimeCheck -or $platformCheck)

if (-not $script:IsWindowsPlatform) {
    Write-Warning 'KOALA Gaming Optimizer requires Windows because it depends on WPF and Windows-specific APIs.'
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
    $warning = 'WPF assemblies not available. This script requires Windows with .NET Framework.'
    Write-Warning $warning
    return
}

$BrushConverter = New-Object System.Windows.Media.BrushConverter

# ---------- Global Performance Variables ----------
# Global state containers shared across modules. These variables are intentionally
# scoped globally because multiple scripts update them (GUI handlers, service
# routines, etc.). Each entry is documented to clarify why it exists. Guard every
# script-scoped value so strict mode never throws when the helper library is
# dot-sourced before any initialization occurs.
$global:PerformanceCounters = @{}          # Real-time perf metrics surfaced in the dashboard
if (-not (Test-Path 'variable:script:LocalizationResources')) { $script:LocalizationResources = $null }
$languageVariable = Get-Variable -Name CurrentLanguage -Scope Script -ErrorAction SilentlyContinue
if (-not $languageVariable -or [string]::IsNullOrWhiteSpace([string]$languageVariable.Value)) {
    $script:CurrentLanguage = 'en'
}
$languageVariable = $null
if (-not (Test-Path 'variable:script:IsLanguageInitializing')) { $script:IsLanguageInitializing = $false }
if (-not (Test-Path 'variable:script:SafeConfigDirectory')) { $script:SafeConfigDirectory = $null }
if (-not (Test-Path 'variable:script:HasWarnedUnsafeConfigPath')) { $script:HasWarnedUnsafeConfigPath = $false }
if (-not (Test-Path 'variable:script:PrimaryGameListPanel')) { $script:PrimaryGameListPanel = $null }
if (-not (Test-Path 'variable:script:DashboardGameListPanel')) { $script:DashboardGameListPanel = $null }
if (-not (Test-Path 'variable:script:SharedBrushConverter')) { $script:SharedBrushConverter = $null }
$global:OptimizationCache = @{}            # Stores last-run optimization results
$global:ActiveGames = @()                  # Names of currently detected games
$global:MenuMode = 'Basic'                 # UI mode (Basic/Advanced)
$global:AutoOptimizeEnabled = $false       # Flag for automatic game optimization
$global:LastTimestamp = $null              # Timestamp caching for log entries
$global:CachedTimestamp = ''               # Cached string representation of timestamp
$global:LogBoxAvailable = $false           # Indicates whether UI log textbox is ready
$global:RegistryCache = @{}                # Cache of registry writes to avoid duplicates
$global:LastOptimizationTime = $null       # Last time optimizations were executed

# ---------- .NET Framework 4.8 Compatibility Helper Functions ----------
function Set-BorderBrushSafe {
    param(
        [System.Windows.FrameworkElement]$Element,
        [object]$BorderBrushValue,
        [string]$BorderThicknessValue = $null
    )

    if (-not $Element) { return }

    try {
        # Check if element supports BorderBrush
        if ($Element.GetType().GetProperty("BorderBrush")) {
            Set-BrushPropertySafe -Target $Element -Property 'BorderBrush' -Value $BorderBrushValue -AllowTransparentFallback
        }

        # Set BorderThickness if provided and supported
        if ($BorderThicknessValue -and $Element.GetType().GetProperty("BorderThickness")) {
            $Element.BorderThickness = $BorderThicknessValue
        }
    }
    catch [System.InvalidOperationException] {
        # Sealed object exception - skip assignment
        Write-Verbose "BorderBrush assignment skipped due to sealed object (compatible with .NET Framework 4.8)"
    }
    catch {
        # Other exceptions - log but don't fail
        Write-Verbose "BorderBrush assignment failed: $($_.Exception.Message)"
    }
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
if (-not $script:SharedBrushConverter) {
    $script:SharedBrushConverter = [System.Windows.Media.BrushConverter]::new()
}

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
} else {
    $ScriptRoot = (Get-Location).Path
}

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

    try {
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
    }
    catch {
        # Silent fail to prevent logging issues
        Write-Verbose "Failed to add log to history: $($_.Exception.Message)"
    }
}


function Log {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Message,

        [Parameter()]
        [ValidateSet('Info','Success','Warning','Error','Debug','Trace','Context','ErrorContext')]
        [string]$Level = 'Info'
    )

    $msg = $Message

    if (-not $global:LastTimestamp -or ((Get-Date) - $global:LastTimestamp).TotalMilliseconds -gt 100) {
        $global:CachedTimestamp = [DateTime]::Now.ToString('HH:mm:ss')
        $global:LastTimestamp = Get-Date
    }

    $logMessage = "[$global:CachedTimestamp] [$Level] $msg"

    $category = Get-LogCategory -Message $msg
    Add-LogToHistory -Message $msg -Level $Level -Category $category

    if ((Get-Random -Maximum 100) -eq 1) {
        Optimize-LogFile -MaxSizeMB 10
    }

    try {
        $logFilePath = Join-Path $ScriptRoot 'Koala-Activity.log'
        $logDir = Split-Path $logFilePath -Parent
        if (-not (Test-Path $logDir)) {
            New-Item -Path $logDir -ItemType Directory -Force -ErrorAction Stop | Out-Null
        }

        $enhancedLogMessage = "[$global:CachedTimestamp] [$Level] [$category] $msg"
        Add-Content -Path $logFilePath -Value $enhancedLogMessage -Encoding UTF8 -ErrorAction Stop

        if ($Level -in @('Error', 'Warning')) {
            $lastLine = Get-Content $logFilePath -Tail 1 -ErrorAction SilentlyContinue
            if ($lastLine -notmatch [regex]::Escape($msg)) {
                throw "File verification failed - log entry may not have been written"
            }
        }

        if ($msg -match "Theme|Game|Mode|Optimization|Service|System|Network|Settings|Backup|Import|Export|Search") {
            $adminStatus = if (Get-Command Test-AdminPrivileges -ErrorAction SilentlyContinue) { Test-AdminPrivileges } else { 'Unknown' }
            $contextMessage = "[$global:CachedTimestamp] [Context] [$category] User action '$($msg.Split(' ')[0])' in $global:MenuMode mode with Admin: $adminStatus"
            Add-Content -Path $logFilePath -Value $contextMessage -Encoding UTF8 -ErrorAction SilentlyContinue
            Add-LogToHistory -Message "User action '$($msg.Split(' ')[0])' in $global:MenuMode mode with Admin: $adminStatus" -Level 'Context' -Category $category
        }

        if ($Level -eq 'Error') {
            $platform = if ($IsWindows -ne $null) { if ($IsWindows) { 'Windows' } else { 'Non-Windows' } } else { 'Windows Legacy' }
            $errorContext = "[$global:CachedTimestamp] [ErrorContext] [$category] PowerShell: $($PSVersionTable.PSVersion), OS: $platform"
            Add-Content -Path $logFilePath -Value $errorContext -Encoding UTF8 -ErrorAction SilentlyContinue
            Add-LogToHistory -Message "PowerShell: $($PSVersionTable.PSVersion), OS: $platform" -Level 'ErrorContext' -Category $category
        }
    }
    catch {
        $errorContext = ''
        if ($_.Exception.Message -match 'Access.*denied|UnauthorizedAccess') {
            $errorContext = ' (Insufficient permissions - try running as Administrator)'
        }
        elseif ($_.Exception.Message -match 'path.*not found|DirectoryNotFound') {
            $errorContext = ' (Directory access issue - check script location)'
        }
        elseif ($_.Exception.Message -match 'file.*in use|sharing violation') {
            $errorContext = ' (File in use - another instance may be running)'
        }

        Write-Warning "LOG FILE ERROR: $($_.Exception.Message)$errorContext"
        Write-Output $logMessage
    }

    if ($global:LogBox -and $global:LogBoxAvailable) {
        try {
            $global:LogBox.Dispatcher.Invoke({
                if ($global:LogBox -and $global:LogBox.IsEnabled -ne $null) {
                    $global:LogBox.AppendText("$logMessage`r`n")
                    $global:LogBox.ScrollToEnd()

                    if (-not $global:DetailedLogBackup) {
                        $global:DetailedLogBackup = ''
                    }
                    $global:DetailedLogBackup += "$logMessage`r`n"

                    if ($global:LogViewDetailed -eq $false) {
                        if ($msg -notmatch 'Success|Error|Warning|Applied|Optimization') {
                            $lines = $global:LogBox.Text -split "`r`n"
                            $filteredLines = $lines | Where-Object { $_ -match 'Success|Error|Warning|Applied|Optimization' } | Select-Object -Last 20
                            $global:LogBox.Text = ($filteredLines -join "`r`n")
                        }
                    }

                    $global:LogBox.InvalidateVisual()
                    $global:LogBox.UpdateLayout()
                    if ([System.Windows.Threading.Dispatcher]::CurrentDispatcher) {
                        [System.Windows.Threading.Dispatcher]::CurrentDispatcher.Invoke({}, [System.Windows.Threading.DispatcherPriority]::Render)
                    }
                }
                else {
                    throw [System.InvalidOperationException]::new('LogBox is unavailable')
                }
            })
        }
        catch {
            $global:LogBoxAvailable = $false
            Write-Host $logMessage -ForegroundColor (Get-LogColor $Level)
            Write-Verbose "LogBox UI became unavailable: $($_.Exception.Message)"
        }
    }
    else {
        Write-Host $logMessage -ForegroundColor (Get-LogColor $Level)
    }
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

    $currentPath = if ($ScriptRoot) { $ScriptRoot } else { (Get-Location).Path }
    $isAdmin = Test-AdminPrivileges

    if ($isAdmin -and ($currentPath -match 'system32|windows|program files' -or $currentPath.Length -lt 10)) {
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
            try {
                New-Item -ItemType Directory -Path $script:SafeConfigDirectory -Force | Out-Null
                Log "Created safe configuration directory: $script:SafeConfigDirectory" 'Info'
            }
            catch {
                Log "Failed to create safe configuration directory: $script:SafeConfigDirectory - $($_.Exception.Message)" 'Warning'
            }
        }

        return Join-Path $script:SafeConfigDirectory $Filename
    }

    return Join-Path $currentPath $Filename
}


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
        'btnNavDashboard' = $btnNavDashboard
        'btnNavBasicOpt' = $btnNavBasicOpt
        'btnNavAdvanced' = $btnNavAdvanced
        'btnNavGames' = $btnNavGames
        'btnNavOptions' = $btnNavOptions
        'btnNavBackup' = $btnNavBackup
        'btnNavLog' = $btnNavLog
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
        'chkAutoOptimize' = $chkAutoOptimize
        'chkGamesAutoOptimize' = $chkGamesAutoOptimize
        'chkAutoBackup' = $chkAutoBackup
        'LogBox' = $global:LogBox
    }

    $missingControls = @()
    $availableControls = @()

    foreach ($controlName in $criticalControls.Keys) {
        $control = $criticalControls[$controlName]
        if ($control -eq $null) {
            $missingControls += $controlName
            Log "MISSING CONTROL: $controlName is null - event handlers will be skipped" 'Warning'
        }
        else {
            $availableControls += $controlName
        }
    }

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

        try {
            $message = "⚠️ STARTUP VALIDATION: $($missingControls.Count) UI controls are missing.`n`nMissing: $($missingControls -join ', ')`n`nThe application will continue to run, but some features may not work properly.`n`nCheck the Activity Log for detailed fix suggestions."
            if ([System.Windows.MessageBox] -and $form) {
                [System.Windows.MessageBox]::Show($message, 'Startup Control Validation', 'OK', 'Warning')
            }
            else {
                Log "UI feedback not available - continuing with console logging only" 'Info'
            }
        }
        catch {
            Log "Could not display UI feedback for missing controls: $($_.Exception.Message)" 'Warning'
        }

        return $false
    }

    Log "[OK] All critical controls found and bound successfully" 'Success'
    return $true
}

$SettingsPath = Get-SafeConfigPath 'koala-settings.cfg'

# ---------- UI Cloning and Mirroring Helpers (moved forward for availability) ----------
function Clone-UIElement {
    param(
        [Parameter(Mandatory = $true)]
        [System.Windows.UIElement]
        $Element
    )

    try {
        $xaml = [System.Windows.Markup.XamlWriter]::Save($Element)
        $stringReader = New-Object System.IO.StringReader $xaml
        $xmlReader = [System.Xml.XmlReader]::Create($stringReader)
        $clone = [Windows.Markup.XamlReader]::Load($xmlReader)
        $xmlReader.Close()
        $stringReader.Close()
        return $clone
    }
    catch {
        Write-Verbose "Clone-UIElement failed: $($_.Exception.Message)"
        return $null
    }
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

    try {
        $clone.Tag = Copy-TagValue -Value $Source.Tag
    }
    catch {
        Write-Verbose "Failed to copy checkbox Tag value: $($_.Exception.Message)"
    }

    return $clone
}

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

    try {
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
    }
    catch {
        Write-Verbose "Update-GameListMirrors failed: $($_.Exception.Message)"
    }
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
}

# Normalize theme tables so color values resolve to reusable brush instances.
function Normalize-ThemeColorTable {
    param([hashtable]$Theme)

    if (-not $Theme) { return $Theme }

    foreach ($key in @($Theme.Keys)) {
        $value = $Theme[$key]

        if ($null -eq $value) { continue }

        if ($value -is [string]) {
            $stringBrush = $null
            try {
                $stringBrush = New-SolidColorBrushSafe $value
            }
            catch {
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
            try {
                if ($value -is [System.Windows.Freezable] -and -not $value.IsFrozen) {
                    $value.Freeze()
                }
            }
            catch {
                Write-Verbose "Normalize-ThemeColorTable: Failed to freeze brush for key '$key'"
            }
            continue
        }

        if ($value -is [int] -or $value -is [double] -or $value -is [decimal]) { continue }

        $resolved = Get-ColorStringFromValue $value
        if (-not [string]::IsNullOrWhiteSpace($resolved)) {
            $Theme[$key] = $resolved
        }
    }

    return $Theme
}


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
        try {
            $clone = if ($current -is [System.Windows.Freezable]) { $current.Clone() } else { $current }
            if ($clone -is [System.Windows.Freezable] -and -not $clone.IsFrozen) {
                $clone.Freeze()
            }
            return $clone
        }
        catch {
            return $current
        }
    }

    if ($current -is [string]) {
        return New-SolidColorBrushSafe $current
    }

    $resolved = Get-ColorStringFromValue $current
    if ($resolved) {
        return New-SolidColorBrushSafe $resolved
    }

    return $null
}


# Creates a frozen SolidColorBrush from a color-like value when possible.
function New-SolidColorBrushSafe {
    param([Parameter(ValueFromPipeline = $true)][object]$ColorValue)

    if ($null -eq $ColorValue) { return $null }

    $existingBrush = Resolve-BrushInstance $ColorValue
    if ($existingBrush -is [System.Windows.Media.SolidColorBrush]) {
        return $existingBrush
    }

    if ($existingBrush -is [System.Windows.Media.Brush]) {
        try {
            $colorText = $existingBrush.ToString()
            if (-not [string]::IsNullOrWhiteSpace($colorText)) {
                $colorCandidate = [System.Windows.Media.ColorConverter]::ConvertFromString($colorText)
                if ($colorCandidate -is [System.Windows.Media.Color]) {
                    $fromBrush = New-Object System.Windows.Media.SolidColorBrush $colorCandidate
                    $fromBrush.Freeze()
                    return $fromBrush
                }
            }
        }
        catch {
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
        try {
            $converted = $converter.ConvertFromString($resolvedValue)
            $convertedBrush = Resolve-BrushInstance $converted
            if ($convertedBrush -is [System.Windows.Media.SolidColorBrush]) {
                return $convertedBrush
            }
        }
        catch {
            Write-Verbose "BrushConverter could not convert '$resolvedValue' to SolidColorBrush: $($_.Exception.Message)"
        }
    }

    try {
        $color = [System.Windows.Media.ColorConverter]::ConvertFromString($resolvedValue)
        if ($color -is [System.Windows.Media.Color]) {
            $brush = New-Object System.Windows.Media.SolidColorBrush $color
            $brush.Freeze()
            return $brush
        }
    }
    catch {
        Write-Verbose "Failed to convert '$resolvedValue' to SolidColorBrush: $($_.Exception.Message)"
    }

    return $null
}


function Get-SharedBrushConverter {
    if (-not $script:SharedBrushConverter -or $script:SharedBrushConverter.GetType().FullName -ne 'System.Windows.Media.BrushConverter') {
        $script:SharedBrushConverter = [System.Windows.Media.BrushConverter]::new()
    }

    return $script:SharedBrushConverter
}

function Set-ShapeFillSafe {
    param(
        [object]$Shape,
        [object]$Value
    )

    if (-not $Shape) { return }

    try {
        Set-BrushPropertySafe -Target $Shape -Property 'Fill' -Value $Value -AllowTransparentFallback
    }
    catch {
        Write-Verbose "Set-ShapeFillSafe failed: $($_.Exception.Message)"
    }
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
        try {
            if ($brush -is [System.Windows.Freezable] -and $brush.IsFrozen) {
                $Target.$Property = $brush.Clone()
            }
            else {
                $Target.$Property = $brush
            }
            return
        }
        catch {
            Write-Verbose "Set-BrushPropertySafe: failed to apply resolved brush to property '$Property' on $($Target.GetType().Name): $($_.Exception.Message)"
        }
    }

    $colorString = Get-ColorStringFromValue $resolvedValue
    if (-not [string]::IsNullOrWhiteSpace($colorString)) {
        $converter = Get-SharedBrushConverter
        if ($converter) {
            try {
                $converted = $converter.ConvertFromString($colorString)
                $convertedBrush = Resolve-BrushInstance $converted
                if (-not $convertedBrush) {
                    $convertedBrush = New-SolidColorBrushSafe $converted
                }

                if ($convertedBrush -is [System.Windows.Media.Brush]) {
                    if ($convertedBrush -is [System.Windows.Freezable] -and $convertedBrush.IsFrozen) {
                        $Target.$Property = $convertedBrush.Clone()
                    }
                    else {
                        $Target.$Property = $convertedBrush
                    }
                    return
                }
            }
            catch {
                Write-Verbose "Set-BrushPropertySafe: converter could not produce brush for '$colorString': $($_.Exception.Message)"
            }
        }

        if ($AllowTransparentFallback) {
            try {
                $fallbackBrush = New-SolidColorBrushSafe $colorString
                if ($fallbackBrush) {
                    $Target.$Property = $fallbackBrush
                    return
                }
            }
            catch {
                Write-Verbose "Set-BrushPropertySafe: fallback conversion failed for '$colorString': $($_.Exception.Message)"
            }
        }
    }

    if ($AllowTransparentFallback) {
        try {
            $transparent = [System.Windows.Media.Brushes]::Transparent
            if ($transparent -is [System.Windows.Freezable] -and $transparent.IsFrozen) {
                $Target.$Property = $transparent.Clone()
            }
            else {
                $Target.$Property = $transparent
            }
        }
        catch {
            Write-Verbose "Set-BrushPropertySafe: unable to apply transparent fallback for property '$Property' on $($Target.GetType().Name): $($_.Exception.Message)"
        }
    }
}


function Convert-ToBrushResource {
    param(
        [object]$Value,
        [switch]$AllowTransparentFallback
    )

    if ($null -eq $Value) { return $null }

    $probe = New-Object System.Windows.Controls.Border

    try {
        if ($AllowTransparentFallback) {
            Set-BrushPropertySafe -Target $probe -Property 'Background' -Value $Value -AllowTransparentFallback
        }
        else {
            Set-BrushPropertySafe -Target $probe -Property 'Background' -Value $Value
        }
    }
    catch {
        return $null
    }

    $result = $probe.Background
    if ($null -eq $result) { return $null }

    if ($result -is [System.Windows.Freezable]) {
        try {
            $clone = $result.Clone()
            if ($clone -is [System.Windows.Freezable] -and -not $clone.IsFrozen) {
                $clone.Freeze()
            }
            return $clone
        }
        catch {
            return $result
        }
    }

    return $result
}


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
    }
    else {
        $targetKeys = @($Resources.Keys)
    }

    foreach ($key in $targetKeys) {
        if (-not $Resources.Contains($key)) { continue }

        $resourceValue = $Resources[$key]
        if ($resourceValue -is [System.Windows.Media.Brush]) { continue }

        $normalizedBrush = if ($AllowTransparentFallback) {
            Convert-ToBrushResource -Value $resourceValue -AllowTransparentFallback
        }
        else {
            Convert-ToBrushResource -Value $resourceValue
        }

        if ($normalizedBrush -is [System.Windows.Media.Brush]) {
            $Resources[$key] = $normalizedBrush
            continue
        }

        if ($AllowTransparentFallback) {
            $Resources[$key] = [System.Windows.Media.Brushes]::Transparent
        }
        else {
            Write-Verbose "Normalize-BrushResources skipped '$key' due to unresolved brush value"
        }
    }
}


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
        $propertyInfo = $null
        try { $propertyInfo = $Element.GetType().GetProperty($propertyName) } catch { $propertyInfo = $null }
        if (-not $propertyInfo -or -not $propertyInfo.CanRead -or -not $propertyInfo.CanWrite) { continue }

        $currentValue = $null
        try { $currentValue = $propertyInfo.GetValue($Element, $null) } catch { $currentValue = $null }
        if ($null -eq $currentValue) { continue }
        if ($currentValue -is [System.Windows.Media.Brush]) { continue }

        Set-BrushPropertySafe -Target $Element -Property $propertyName -Value $currentValue -AllowTransparentFallback
    }
}


function Normalize-VisualTreeBrushes {
    param([System.Windows.DependencyObject]$Root)

    if ($null -eq $Root) { return }

    $visited = New-Object 'System.Collections.Generic.HashSet[int]'
    $stack = New-Object System.Collections.Stack
    $stack.Push($Root)

    while ($stack.Count -gt 0) {
        $current = $stack.Pop()
        if ($current -isnot [System.Windows.DependencyObject]) { continue }

        $hash = $null
        try { $hash = [System.Runtime.CompilerServices.RuntimeHelpers]::GetHashCode($current) } catch { $hash = $null }
        if ($hash -eq $null) { continue }
        if (-not $visited.Add($hash)) { continue }

        Normalize-ElementBrushProperties -Element $current

        $childCount = 0
        try { $childCount = [System.Windows.Media.VisualTreeHelper]::GetChildrenCount($current) } catch { $childCount = 0 }

        for ($i = 0; $i -lt $childCount; $i++) {
            $child = $null
            try { $child = [System.Windows.Media.VisualTreeHelper]::GetChild($current, $i) } catch { $child = $null }
            if ($child) { $stack.Push($child) }
        }

        try {
            foreach ($logicalChild in [System.Windows.LogicalTreeHelper]::GetChildren($current)) {
                if ($logicalChild -is [System.Windows.DependencyObject]) {
                    $stack.Push($logicalChild)
                }
            }
        }
        catch {
            # Ignore logical tree traversal issues
        }
    }
}


# ---------- Theme and Styling Helpers (moved forward for availability) ----------
function Resolve-ControlType {
    param(
        [object]$ControlType
    )

    if ($ControlType -is [Type]) {
        return $ControlType
    }

    if (-not $ControlType) {
        return $null
    }

    $typeName = $null
    if ($ControlType -is [string]) {
        $typeName = $ControlType.Trim()
    }
    else {
        try { $typeName = $ControlType.ToString() } catch { $typeName = $null }
    }

    if (-not $typeName) {
        return $null
    }

    if ($typeName.StartsWith('[') -and $typeName.EndsWith(']')) {
        $typeName = $typeName.Trim('[', ']')
    }

    $knownTypes = @{
        'System.Windows.Controls.Button' = [System.Windows.Controls.Button]
        'System.Windows.Controls.ComboBox' = [System.Windows.Controls.ComboBox]
        'System.Windows.Controls.TextBlock' = [System.Windows.Controls.TextBlock]
        'System.Windows.Controls.Label' = [System.Windows.Controls.Label]
        'System.Windows.Controls.Border' = [System.Windows.Controls.Border]
        'System.Windows.Controls.Primitives.ScrollBar' = [System.Windows.Controls.Primitives.ScrollBar]
    }

    if ($knownTypes.ContainsKey($typeName)) {
        return $knownTypes[$typeName]
    }

    $resolvedType = $null
    try { $resolvedType = [Type]::GetType($typeName, $false) } catch { $resolvedType = $null }
    if ($resolvedType) { return $resolvedType }

    try { $resolvedType = [Type]::GetType("$typeName, PresentationFramework", $false) } catch { $resolvedType = $null }
    return $resolvedType
}

function Find-AllControlsOfType {
    param(
        [System.Windows.DependencyObject]$Parent,
        [object]$ControlType,
        [ref]$Collection
    )

    if (-not $Parent -or -not $Collection) {
        return
    }

    if ($null -eq $Collection.Value) {
        $Collection.Value = @()
    }

    $resolvedType = Resolve-ControlType -ControlType $ControlType
    if (-not $resolvedType) {
        return
    }

    if ($Parent -is $resolvedType) {
        $Collection.Value += $Parent
    }

    $childCandidates = @()
    $childCollections = @()

    foreach ($collectionProperty in 'Children','Items','Controls','Inlines','RowDefinitions','ColumnDefinitions','Blocks') {
        $value = $null
        try { $value = $Parent.$collectionProperty } catch { $value = $null }
        if ($value) { $childCollections += ,$value }
    }

    foreach ($collection in $childCollections) {
        if (-not $collection) { continue }
        foreach ($child in $collection) {
            if ($child -is [System.Windows.DependencyObject]) {
                $childCandidates += $child
            }
        }
    }

    foreach ($propertyName in 'Content','Child') {
        if ($Parent.PSObject.Properties[$propertyName]) {
            $value = $Parent.$propertyName
            if ($value -is [System.Windows.DependencyObject]) {
                $childCandidates += $value
            }
        }
    }

    if ($Parent -is [System.Windows.DependencyObject]) {
        $visualCount = 0
        try { $visualCount = [System.Windows.Media.VisualTreeHelper]::GetChildrenCount($Parent) } catch { $visualCount = 0 }
        for ($index = 0; $index -lt $visualCount; $index++) {
            $visualChild = $null
            try { $visualChild = [System.Windows.Media.VisualTreeHelper]::GetChild($Parent, $index) } catch { $visualChild = $null }

            if ($visualChild -is [System.Windows.DependencyObject]) {
                $childCandidates += $visualChild
            }
        }
    }

        try {
            foreach ($logicalChild in [System.Windows.LogicalTreeHelper]::GetChildren($Parent)) {
                if ($logicalChild -is [System.Windows.DependencyObject]) {
                    $childCandidates += $logicalChild
                }
            }
        }
        catch {
            # Ignore logical tree issues
        }
    }

    foreach ($childCandidate in $childCandidates) {
        if ($null -ne $childCandidate) {
            Find-AllControlsOfType -Parent $childCandidate -ControlType $resolvedType -Collection $Collection
        }
    }
}

function Set-StackPanelChildSpacing {
    param(
        [System.Windows.Controls.StackPanel]$Panel,
        [double]$Spacing
    )

    if (-not $Panel -or -not $Panel.Children) {
        return
    }

    $count = $Panel.Children.Count
    if ($count -le 1) {
        return
    }

    for ($index = 0; $index -lt $count; $index++) {
        $child = $Panel.Children[$index]
        if ($child -isnot [System.Windows.FrameworkElement]) {
            continue
        }

        $margin = if ($child.Margin) { $child.Margin } else { [System.Windows.Thickness]::new(0) }
        $newMargin = [System.Windows.Thickness]::new($margin.Left, $margin.Top, $margin.Right, $margin.Bottom)

        if ($Panel.Orientation -eq [System.Windows.Controls.Orientation]::Horizontal) {
            if ($index -lt $count - 1) {
                if ($newMargin.Right -lt $Spacing) {
                    $newMargin.Right = $Spacing
                }
            }
            elseif ($newMargin.Right -ne 0) {
                $newMargin.Right = 0
            }
        }
        else {
            if ($index -lt $count - 1) {
                if ($newMargin.Bottom -lt $Spacing) {
                    $newMargin.Bottom = $Spacing
                }
            }
            elseif ($newMargin.Bottom -ne 0) {
                $newMargin.Bottom = 0
            }
        }

        $child.Margin = $newMargin
    }
}


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
    try {
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
    }
    catch {
        Write-Verbose "WinMM timer API not available: $($_.Exception.Message)"
    }
}

# ---------- Performance Monitoring API ----------
if (-not ([System.Management.Automation.PSTypeName]'PerfMon').Type) {
    try {
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
    }
    catch {
        Write-Verbose "Performance monitoring API not available: $($_.Exception.Message)"
    }
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
    try {
        $healthData = [ordered]@{
            LastHealthCheck   = Get-Date
            HealthStatus      = 'Good'
            HealthWarnings    = @()
            HealthScore       = 100
            Recommendations   = @()
            Issues            = @()
            Metrics           = @{}
            LastResult        = $null
        }

        try {
            $cpuInfo = Get-CimInstance -ClassName Win32_Processor -ErrorAction Stop
            $cpuLoad = ($cpuInfo | Measure-Object -Property LoadPercentage -Average).Average
            if ($cpuLoad -ne $null) {
                $cpuLoad = [math]::Round([double]$cpuLoad, 0)
                $healthData.Metrics['CpuLoadPercent'] = $cpuLoad
                if ($cpuLoad -gt 85) {
                    $healthData.HealthWarnings += 'High CPU load detected'
                    $healthData.Recommendations += 'Close background applications to reduce CPU usage'
                    $healthData.HealthScore -= 10
                }
            }
        }
        catch {
            Write-Verbose "CPU health check failed: $($_.Exception.Message)"
        }

        try {
            $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
            $totalMemory = [double]$osInfo.TotalVisibleMemorySize
            $freeMemory = [double]$osInfo.FreePhysicalMemory
            if ($totalMemory -gt 0) {
                $usedPercent = [math]::Round((($totalMemory - $freeMemory) / $totalMemory) * 100, 0)
                $healthData.Metrics['MemoryUsagePercent'] = $usedPercent
                if ($usedPercent -gt 85) {
                    $healthData.HealthWarnings += 'High RAM usage detected'
                    $healthData.Recommendations += 'Close unused applications to free up RAM'
                    $healthData.HealthScore -= 10
                }
            }
        }
        catch {
            Write-Verbose "Memory health check failed: $($_.Exception.Message)"
        }

        try {
            $systemDrive = (Get-Item -Path Env:SystemDrive).Value
            $driveInfo = Get-PSDrive -Name $systemDrive.TrimEnd(':') -ErrorAction Stop
            $freePercent = [math]::Round(($driveInfo.Free / $driveInfo.UsedAndFree) * 100, 0)
            $healthData.Metrics['SystemDriveFreePercent'] = $freePercent
            if ($freePercent -lt 15) {
                $healthData.HealthWarnings += 'Low free space on system drive'
                $healthData.Recommendations += 'Free up disk space on the system drive to ensure stable performance'
                $healthData.HealthScore -= 10
            }
        }
        catch {
            Write-Verbose "Disk space check failed: $($_.Exception.Message)"
        }

        try {
            $pendingUpdates = Get-CimInstance -Namespace root\cimv2 -ClassName Win32_QuickFixEngineering -ErrorAction Stop
            $lastUpdate = $pendingUpdates | Sort-Object -Property InstalledOn -Descending | Select-Object -First 1
            if ($lastUpdate -and $lastUpdate.InstalledOn) {
                $healthData.Metrics['LastUpdateInstalledOn'] = $lastUpdate.InstalledOn
            }
        }
        catch {
            Write-Verbose "Windows update check failed: $($_.Exception.Message)"
        }

        try {
            $gameMode = Get-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\GameBar' -Name 'AllowAutoGameMode' -ErrorAction SilentlyContinue
            if (-not $gameMode -or $gameMode.AllowAutoGameMode -ne 1) {
                $healthData.HealthWarnings += 'Windows Game Mode is disabled'
                $healthData.Recommendations += 'Enable Windows Game Mode for improved gaming responsiveness'
                $healthData.HealthScore -= 5
            }
        }
        catch {
            Write-Verbose "Game Mode check failed: $($_.Exception.Message)"
        }

        try {
            $hwSch = Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers' -Name 'HwSchMode' -ErrorAction SilentlyContinue
            if (-not $hwSch -or $hwSch.HwSchMode -ne 2) {
                $healthData.HealthWarnings += 'Hardware GPU scheduling is disabled'
                $healthData.Recommendations += 'Enable hardware GPU scheduling for lower latency'
                $healthData.HealthScore -= 5
            }
        }
        catch {
            Write-Verbose "Hardware scheduling check failed: $($_.Exception.Message)"
        }

        try {
            $networkAdapters = Get-CimInstance -ClassName Win32_NetworkAdapter -Filter 'NetEnabled=True' -ErrorAction Stop
            $activeAdapters = $networkAdapters | Where-Object { $_.NetConnectionStatus -eq 2 }
            $healthData.Metrics['ActiveNetworkAdapters'] = $activeAdapters.Count
            if ($activeAdapters.Count -eq 0) {
                $healthData.Issues += 'No active network connections detected'
                $healthData.Recommendations += 'Check network connectivity for online features'
                $healthData.HealthScore -= 20
            }
            elseif ($activeAdapters.Count -gt 2) {
                $healthData.HealthWarnings += 'Multiple active network adapters detected'
                $healthData.Recommendations += 'Disable unused network adapters to reduce latency'
                $healthData.HealthScore -= 5
            }
        }
        catch {
            Write-Verbose "Network health check failed: $($_.Exception.Message)"
        }

        if ($healthData.HealthScore -lt 0) { $healthData.HealthScore = 0 }

        if ($healthData.HealthScore -ge 90) {
            $healthData.HealthStatus = 'Excellent'
        }
        elseif ($healthData.HealthScore -ge 75) {
            $healthData.HealthStatus = 'Good'
        }
        elseif ($healthData.HealthScore -ge 60) {
            $healthData.HealthStatus = 'Fair'
        }
        elseif ($healthData.HealthScore -ge 40) {
            $healthData.HealthStatus = 'Poor'
        }
        else {
            $healthData.HealthStatus = 'Critical'
        }

        $healthData.LastResult = Get-Date
        return $healthData
    }
    catch {
        Log "Error performing system health check: $($_.Exception.Message)" 'Error'
        return @{
            OverallScore   = 0
            Issues         = @('Health check failed')
            Warnings       = @()
            Recommendations = @('Run as Administrator for complete health analysis')
            Status         = 'Unknown'
            Metrics        = @{}
        }
    }
}


function Update-SystemHealthSummary {
    try {
        $status = if ($global:SystemHealthData.HealthStatus) { $global:SystemHealthData.HealthStatus } else { 'Not Run' }
        $score = $global:SystemHealthData.HealthScore
        $lastRun = $global:SystemHealthData.LastHealthCheck

        $text = 'Not Run'
        $foreground = '#A6AACF'

        if ($status -eq 'Error') {
            $text = 'Error (see log)'
            $foreground = '#FF4444'
        }
        elseif ($lastRun) {
            $timeStamp = $lastRun.ToString('HH:mm')
            if ($score -ne $null) {
                $roundedScore = [Math]::Round([double]$score, 0)
                $text = '{0} ({1}% @ {2})' -f $status, [int]$roundedScore, $timeStamp
            }
            else {
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
        }

        if ($lblDashSystemHealth) {
            $lblDashSystemHealth.Dispatcher.Invoke([Action]{
                $lblDashSystemHealth.Text = $text
                Set-BrushPropertySafe -Target $lblDashSystemHealth -Property 'Foreground' -Value $foreground
            })
        }
    }
    catch {
        Log "Error updating dashboard health summary: $($_.Exception.Message)" 'Warning'
    }
}


function Update-SystemHealthDisplay {
    param([switch]$RunCheck)

    try {
        if ($RunCheck) {
            $healthData = Get-SystemHealthStatus
            if ($healthData) {
                $timestamp = Get-Date
                $global:SystemHealthData.LastHealthCheck = $timestamp
                $global:SystemHealthData.HealthStatus = $healthData.HealthStatus
                $global:SystemHealthData.HealthScore = $healthData.HealthScore
                $global:SystemHealthData.HealthWarnings = $healthData.HealthWarnings
                $global:SystemHealthData.Recommendations = $healthData.Recommendations
                $global:SystemHealthData.Issues = $healthData.Issues
                $global:SystemHealthData.Metrics = $healthData.Metrics
                $global:SystemHealthData.LastResult = $healthData
                Log "Health check complete: $($healthData.HealthStatus) ($($healthData.HealthScore)% score)" 'Info'
            }
        }

        Update-SystemHealthSummary
        return $global:SystemHealthData
    }
    catch {
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
        Update-SystemHealthSummary
        return $global:SystemHealthData
    }
}


function Show-SystemHealthDialog {
    try {
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

        $reader = New-Object System.Xml.XmlNodeReader $healthDialogXaml
        $healthWindow = [Windows.Markup.XamlReader]::Load($reader)
        Initialize-LayoutSpacing -Root $healthWindow

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

        $updateDisplay = {
            param([bool]$RunCheck = $false)

            try {
                $data = Update-SystemHealthDisplay -RunCheck:$RunCheck
                if (-not $data -or -not $data.LastHealthCheck) {
                    $lblHealthStatus.Text = 'Status: Not Run'
                    $lblHealthScore.Text = 'Health Score: N/A'
                    $lblCpuMetric.Text = '--%'
                    $lblMemoryMetric.Text = '--%'
                    if ($lblDiskMetric) { $lblDiskMetric.Text = '--%' }
                    $lstIssues.ItemsSource = @()
                    $lstRecommendations.ItemsSource = @('Click Refresh to run a health check.')
                    return $null
                }

                $timestamp = $data.LastHealthCheck.ToString('g')
                $lblHealthStatus.Text = "Status: $($data.HealthStatus) (Last: $timestamp)"
                $lblHealthScore.Text = if ($data.HealthScore -ne $null) { "Health Score: $($data.HealthScore)%" } else { 'Health Score: N/A' }

                if ($data.Metrics.ContainsKey('CpuUsage') -and $data.Metrics.CpuUsage -ne $null) {
                    $lblCpuMetric.Text = "$($data.Metrics.CpuUsage)%"
                } else {
                    $lblCpuMetric.Text = '--%'
                }

                if ($data.Metrics.ContainsKey('MemoryUsage') -and $data.Metrics.MemoryUsage -ne $null) {
                    $lblMemoryMetric.Text = "$($data.Metrics.MemoryUsage)%"
                } else {
                    $lblMemoryMetric.Text = '--%'
                }

                $issues = @()
                if ($data.Issues) { $issues += $data.Issues }
                if ($data.HealthWarnings) { $issues += $data.HealthWarnings }
                $lstIssues.ItemsSource = $issues

                if ($data.Recommendations) {
                    $lstRecommendations.ItemsSource = $data.Recommendations
                } else {
                    $lstRecommendations.ItemsSource = @('No recommendations available. Great job!')
                }

                Log "System health dialog updated: $($data.HealthStatus)" 'Info'
                return $data
            }
            catch {
                Log "Error updating System Health dialog: $($_.Exception.Message)" 'Error'
                return $null
            }
        }.GetNewClosure()

        $btnRefreshHealth.Add_Click({
            param($sender, $args)

            $btnRefreshHealth.IsEnabled = $false
            try {
                Log 'Manual health check triggered from System Health dialog' 'Info'
                & $updateDisplay -RunCheck:$true | Out-Null
            }
            catch {
                Log "Health check refresh failed: $($_.Exception.Message)" 'Error'
                [System.Windows.MessageBox]::Show("Error running health check: $($_.Exception.Message)", 'Health Monitor', 'OK', 'Error') | Out-Null
            }
            finally {
                $btnRefreshHealth.IsEnabled = $true
            }
        }.GetNewClosure())

        $btnOptimizeNow.Add_Click({
            param($sender, $args)

            try {
                $command = Get-Command -Name 'Invoke-QuickOptimization' -ErrorAction SilentlyContinue
                if (-not $command) {
                    [System.Windows.MessageBox]::Show('Quick optimization is not available in the current session.', 'Quick Optimization', 'OK', 'Information') | Out-Null
                    return
                }

                Log 'Quick optimization requested from System Health dialog' 'Info'
                $result = & $command
                if ($result) {
                    Log 'Quick optimization completed successfully from health dialog' 'Success'
                } else {
                    Log 'Quick optimization finished without backend actions' 'Warning'
                }

                & $updateDisplay -RunCheck:$false | Out-Null
            }
            catch {
                Log "Quick optimization from health dialog failed: $($_.Exception.Message)" 'Error'
                [System.Windows.MessageBox]::Show("Could not run quick optimization: $($_.Exception.Message)", 'Quick Optimization', 'OK', 'Error') | Out-Null
            }
        }.GetNewClosure())

        $btnOpenTaskManager.Add_Click({
            param($sender, $args)

            try {
                Start-Process 'taskmgr.exe' -ErrorAction Stop
                Log 'Task Manager opened from System Health dialog' 'Info'
            }
            catch {
                Log "Task Manager launch failed: $($_.Exception.Message)" 'Warning'
                [System.Windows.MessageBox]::Show("Could not open Task Manager: $($_.Exception.Message)", 'Task Manager', 'OK', 'Warning') | Out-Null
            }
        }.GetNewClosure())

        $btnCloseHealth.Add_Click({
            param($sender, $args)
            Log 'System Health dialog closed by user' 'Info'
            $healthWindow.Close()
        })

        & $updateDisplay -RunCheck:$false | Out-Null
        $healthWindow.ShowDialog() | Out-Null
    }
    catch {
        Log "Error showing System Health dialog: $($_.Exception.Message)" 'Error'
        [System.Windows.MessageBox]::Show("Error displaying system health window: $($_.Exception.Message)", 'Health Monitor', 'OK', 'Error') | Out-Null
    }
}

function Search-LogHistory {
    param(
        [string]$SearchTerm = '',
        [string[]]$Level = @(),
        [string]$Category = 'All',
        [DateTime]$StartDate = (Get-Date).AddDays(-1),
        [DateTime]$EndDate = (Get-Date)
    )

    try {
        $results = $global:LogHistory | Where-Object {
            $_.Timestamp -ge $StartDate -and $_.Timestamp -le $EndDate
        }

        if ($SearchTerm) {
            $regex = [regex]::Escape($SearchTerm)
            $results = $results | Where-Object { $_.Message -match $regex }
        }

        if ($Level -and $Level.Count -gt 0) {
            $results = $results | Where-Object { $_.Level -in $Level }
        }

        if ($Category -and $Category -ne 'All') {
            $results = $results | Where-Object { $_.Category -eq $Category }
        }

        return $results | Sort-Object Timestamp -Descending
    }
    catch {
        Log "Error searching log history: $($_.Exception.Message)" 'Error'
        return @()
    }
}

function Export-LogHistory {
    param(
        [string]$Path,
        [ValidateSet('TXT','CSV','JSON')]
        [string]$Format = 'TXT',
        [array]$FilteredResults = $null
    )

    try {
        $logsToExport = if ($FilteredResults) { $FilteredResults } else { $global:LogHistory }
        if (-not $logsToExport -or $logsToExport.Count -eq 0) {
            throw 'No log entries to export.'
        }

        switch ($Format) {
            'TXT' {
                $content = $logsToExport | ForEach-Object {
                    "[$($_.Timestamp.ToString('yyyy-MM-dd HH:mm:ss'))] [$($_.Level)] [$($_.Category)] $($_.Message)"
                }
                $content | Out-File -FilePath $Path -Encoding UTF8
            }
            'CSV' {
                $logsToExport | Select-Object Timestamp, Level, Category, Message, Thread |
                    Export-Csv -Path $Path -NoTypeInformation -Encoding UTF8
            }
            'JSON' {
                $logsToExport | ConvertTo-Json -Depth 4 | Out-File -FilePath $Path -Encoding UTF8
            }
        }

        Log "Log history exported to $Path as $Format" 'Success'
        return $true
    }
    catch {
        Log "Error exporting log history: $($_.Exception.Message)" 'Error'
        return $false
    }
}

function Show-LogSearchDialog {
    try {
        [xml]$logSearchXaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Log Search and Filter"
        Width="900" Height="700"
        Background="{DynamicResource AppBackgroundBrush}"
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

    <Border Grid.Row="0" Background="{DynamicResource CardBackgroundBrush}" BorderBrush="{DynamicResource CardBorderBrush}" BorderThickness="2" CornerRadius="8" Padding="15" Margin="0,0,0,15">
      <TextBlock Text="Log Search and Filter" Foreground="{DynamicResource AccentBrush}" FontWeight="Bold" FontSize="18" HorizontalAlignment="Center"/>
    </Border>

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

        <StackPanel Grid.Row="0" Grid.Column="0" Margin="0,0,10,10">
          <TextBlock Text="Search Term:" Foreground="{DynamicResource PrimaryTextBrush}" FontSize="12" Margin="0,0,0,5"/>
          <TextBox x:Name="txtSearchTerm" Height="25" Background="{DynamicResource CardBackgroundBrush}" Foreground="{DynamicResource PrimaryTextBrush}" BorderBrush="{DynamicResource CardBorderBrush}"/>
        </StackPanel>

        <StackPanel Grid.Row="0" Grid.Column="1" Margin="0,0,0,10">
          <TextBlock Text="Category:" Foreground="{DynamicResource PrimaryTextBrush}" FontSize="12" Margin="0,0,0,5"/>
          <ComboBox x:Name="cmbCategory" Height="25" Background="{DynamicResource CardBackgroundBrush}" Foreground="{DynamicResource PrimaryTextBrush}" BorderBrush="{DynamicResource CardBorderBrush}"/>
        </StackPanel>

        <Button x:Name="btnSearch" Grid.Row="0" Grid.Column="2" Content="Search" Width="80" Height="25"
                Background="{StaticResource CardBorderBrush}" Foreground="{DynamicResource PrimaryTextBrush}" BorderThickness="0" FontWeight="SemiBold"
                VerticalAlignment="Bottom" Margin="10,0,0,10"/>

        <StackPanel Grid.Row="1" Grid.ColumnSpan="3" Orientation="Horizontal" Margin="0,0,0,10">
          <TextBlock Text="Levels:" Foreground="{DynamicResource PrimaryTextBrush}" FontSize="12" Margin="0,0,10,0" VerticalAlignment="Center"/>
          <CheckBox x:Name="chkInfo" Content="Info" Foreground="{DynamicResource PrimaryTextBrush}" IsChecked="True" Margin="0,0,15,0"/>
          <CheckBox x:Name="chkSuccess" Content="Success" Foreground="{DynamicResource PrimaryTextBrush}" IsChecked="True" Margin="0,0,15,0"/>
          <CheckBox x:Name="chkWarning" Content="Warning" Foreground="{DynamicResource PrimaryTextBrush}" IsChecked="True" Margin="0,0,15,0"/>
          <CheckBox x:Name="chkError" Content="Error" Foreground="{DynamicResource PrimaryTextBrush}" IsChecked="True" Margin="0,0,15,0"/>
          <CheckBox x:Name="chkContext" Content="Context" Foreground="{DynamicResource PrimaryTextBrush}" IsChecked="False" Margin="0,0,15,0"/>
        </StackPanel>

        <TextBlock x:Name="lblResultsInfo" Grid.Row="2" Grid.ColumnSpan="3"
                   Text="Total log entries: 0" Foreground="{DynamicResource SecondaryTextBrush}" FontSize="11"/>
      </Grid>
    </Border>

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
                    <TextBlock Text="{Binding Category}" FontSize="10" Foreground="{DynamicResource AccentBrush}"/>
                  </StackPanel>
                  <TextBlock Text="{Binding Message}" FontSize="11" Foreground="{DynamicResource PrimaryTextBrush}" Margin="0,3,0,0" TextWrapping="Wrap"/>
                </StackPanel>
              </Border>
            </DataTemplate>
          </ListBox.ItemTemplate>
        </ListBox>
      </ScrollViewer>
    </Border>

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

        $reader = New-Object System.Xml.XmlNodeReader $logSearchXaml
        $searchWindow = [Windows.Markup.XamlReader]::Load($reader)
        Initialize-LayoutSpacing -Root $searchWindow

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

        $global:LogCategories | ForEach-Object { $cmbCategory.Items.Add($_) }
        $cmbCategory.SelectedIndex = 0
        $lblResultsInfo.Text = "Total log entries: $($global:LogHistory.Count)"

        $performSearch = {
            $searchTerm = $txtSearchTerm.Text
            $category = if ($cmbCategory.SelectedItem) { $cmbCategory.SelectedItem.ToString() } else { 'All' }

            $levels = @()
            if ($chkInfo.IsChecked) { $levels += 'Info' }
            if ($chkSuccess.IsChecked) { $levels += 'Success' }
            if ($chkWarning.IsChecked) { $levels += 'Warning' }
            if ($chkError.IsChecked) { $levels += 'Error' }
            if ($chkContext.IsChecked) { $levels += 'Context' }

            $results = Search-LogHistory -SearchTerm $searchTerm -Level $levels -Category $category
            $lstLogResults.ItemsSource = $results
            $lblResultsInfo.Text = "Search results: $($results.Count) entries (Total: $($global:LogHistory.Count))"

            Log "Log search executed: '$searchTerm' in $category ($($results.Count) results)" 'Info'
        }.GetNewClosure()

        $btnSearch.Add_Click({
            param($sender, $args)
            try { & $performSearch }
            catch {
                Log "Log search failed: $($_.Exception.Message)" 'Error'
                [System.Windows.MessageBox]::Show("Search failed: $($_.Exception.Message)", 'Log Search', 'OK', 'Error') | Out-Null
            }
        })

        $txtSearchTerm.Add_KeyDown({
            param($sender, $args)
            if ($args.Key -eq 'Return') {
                $btnSearch.RaiseEvent([System.Windows.RoutedEventArgs]::new([System.Windows.Controls.Button]::ClickEvent))
            }
        })

        $btnExportTXT.Add_Click({
            param($sender, $args)
            $dialog = New-Object Microsoft.Win32.SaveFileDialog
            $dialog.Filter = 'Text files (*.txt)|*.txt'
            $dialog.Title = 'Export Log History as TXT'
            $dialog.FileName = "KOALA-GameOptimizer-Logs-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"
            if ($dialog.ShowDialog()) {
                Export-LogHistory -Path $dialog.FileName -Format 'TXT' -FilteredResults $lstLogResults.ItemsSource | Out-Null
            }
        })

        $btnExportCSV.Add_Click({
            param($sender, $args)
            $dialog = New-Object Microsoft.Win32.SaveFileDialog
            $dialog.Filter = 'CSV files (*.csv)|*.csv'
            $dialog.Title = 'Export Log History as CSV'
            $dialog.FileName = "KOALA-GameOptimizer-Logs-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"
            if ($dialog.ShowDialog()) {
                Export-LogHistory -Path $dialog.FileName -Format 'CSV' -FilteredResults $lstLogResults.ItemsSource | Out-Null
            }
        })

        $btnExportJSON.Add_Click({
            param($sender, $args)
            $dialog = New-Object Microsoft.Win32.SaveFileDialog
            $dialog.Filter = 'JSON files (*.json)|*.json'
            $dialog.Title = 'Export Log History as JSON'
            $dialog.FileName = "KOALA-GameOptimizer-Logs-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
            if ($dialog.ShowDialog()) {
                Export-LogHistory -Path $dialog.FileName -Format 'JSON' -FilteredResults $lstLogResults.ItemsSource | Out-Null
            }
        })

        $btnClearSearch.Add_Click({
            param($sender, $args)
            $txtSearchTerm.Text = ''
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
            param($sender, $args)
            $searchWindow.Close()
        })

        & $performSearch
        $searchWindow.ShowDialog() | Out-Null
    }
    catch {
        Log "Error showing log search dialog: $($_.Exception.Message)" 'Error'
        [System.Windows.MessageBox]::Show("Error displaying log search window: $($_.Exception.Message)", 'Log Search', 'OK', 'Error') | Out-Null
    }
}

function Get-SystemPerformanceMetrics {
    <#
    .SYNOPSIS
    Collects current CPU, memory, and activity metrics for dashboard display.
    #>
    try {
        $metrics = @{}

        $idleTime = [long]0
        $kernelTime = [long]0
        $userTime = [long]0
        $currentTime = [DateTime]::Now

        if ([PerfMon]::GetSystemTimes([ref]$idleTime, [ref]$kernelTime, [ref]$userTime)) {
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
        }

        $global:LastCpuTime = @{
            Idle = $idleTime
            Kernel = $kernelTime
            User = $userTime
            Timestamp = $currentTime
        }

        $memStatus = New-Object PerfMon+MEMORYSTATUSEX
        $memStatus.dwLength = [System.Runtime.InteropServices.Marshal]::SizeOf($memStatus)
        if ([PerfMon]::GlobalMemoryStatusEx([ref]$memStatus)) {
            $totalGB = [Math]::Round($memStatus.ullTotalPhys / 1GB, 1)
            $availableGB = [Math]::Round($memStatus.ullAvailPhys / 1GB, 1)
            $metrics.MemoryTotalGB = $totalGB
            $metrics.MemoryUsedGB = [Math]::Round($totalGB - $availableGB, 1)
            $metrics.MemoryUsagePercent = [Math]::Round($memStatus.dwMemoryLoad, 1)
        } else {
            $metrics.MemoryTotalGB = 0
            $metrics.MemoryUsedGB = 0
            $metrics.MemoryUsagePercent = 0
        }

        $metrics.ActiveGamesCount = if ($global:ActiveGames) { $global:ActiveGames.Count } else { 0 }

        if ($global:LastOptimizationTime) {
            $timeSince = (Get-Date) - $global:LastOptimizationTime
            if ($timeSince.Days -gt 0) {
                $metrics.LastOptimization = "$($timeSince.Days)d ago"
            } elseif ($timeSince.Hours -gt 0) {
                $metrics.LastOptimization = "$($timeSince.Hours)h ago"
            } elseif ($timeSince.Minutes -gt 0) {
                $metrics.LastOptimization = "$($timeSince.Minutes)m ago"
            } else {
                $metrics.LastOptimization = 'Just now'
            }
        } else {
            $metrics.LastOptimization = 'Never'
        }

        return $metrics
    }
    catch {
        Log "Error gathering performance metrics: $($_.Exception.Message)" 'Warning'
        return @{
            CpuUsage = 0
            MemoryUsedGB = 0
            MemoryTotalGB = 0
            MemoryUsagePercent = 0
            ActiveGamesCount = 0
            LastOptimization = 'Error'
        }
    }
}

function Update-DashboardMetrics {
    try {
        $metrics = Get-SystemPerformanceMetrics

        if ($lblDashCpuUsage) {
            $lblDashCpuUsage.Dispatcher.Invoke([Action]{
                $lblDashCpuUsage.Text = "$($metrics.CpuUsage)%"
                if ($metrics.CpuUsage -ge 80) {
                    Set-BrushPropertySafe -Target $lblDashCpuUsage -Property 'Foreground' -Value '#FF4444'
                } elseif ($metrics.CpuUsage -ge 60) {
                    Set-BrushPropertySafe -Target $lblDashCpuUsage -Property 'Foreground' -Value '#A78BFA'
                } else {
                    Set-BrushPropertySafe -Target $lblDashCpuUsage -Property 'Foreground' -Value '#8F6FFF'
                }
            })
        }

        if ($lblDashMemoryUsage) {
            $lblDashMemoryUsage.Dispatcher.Invoke([Action]{
                $lblDashMemoryUsage.Text = "$($metrics.MemoryUsedGB) / $($metrics.MemoryTotalGB) GB"
                if ($metrics.MemoryUsagePercent -ge 85) {
                    Set-BrushPropertySafe -Target $lblDashMemoryUsage -Property 'Foreground' -Value '#FF4444'
                } elseif ($metrics.MemoryUsagePercent -ge 70) {
                    Set-BrushPropertySafe -Target $lblDashMemoryUsage -Property 'Foreground' -Value '#A78BFA'
                } else {
                    Set-BrushPropertySafe -Target $lblDashMemoryUsage -Property 'Foreground' -Value '#8F6FFF'
                }
            })
        }

        if ($lblHeroProfiles) {
            $lblHeroProfiles.Dispatcher.Invoke([Action]{ $lblHeroProfiles.Text = [string]$metrics.ActiveGamesCount })
        }

        $optimizationsCount = if ($global:OptimizationCache) { $global:OptimizationCache.Count } else { 0 }
        if ($lblHeroOptimizations) {
            $lblHeroOptimizations.Dispatcher.Invoke([Action]{ $lblHeroOptimizations.Text = [string]$optimizationsCount })
        }

        if ($lblHeroAutoMode) {
            $lblHeroAutoMode.Dispatcher.Invoke([Action]{ $lblHeroAutoMode.Text = if ($global:AutoOptimizeEnabled) { 'On' } else { 'Off' } })
        }

        if ($lblDashActiveGames) {
            $lblDashActiveGames.Dispatcher.Invoke([Action]{
                if ($metrics.ActiveGamesCount -gt 0) {
                    $lblDashActiveGames.Text = "$($metrics.ActiveGamesCount) running"
                    Set-BrushPropertySafe -Target $lblDashActiveGames -Property 'Foreground' -Value '#8F6FFF'
                } else {
                    $lblDashActiveGames.Text = 'None detected'
                    Set-BrushPropertySafe -Target $lblDashActiveGames -Property 'Foreground' -Value '#A6AACF'
                }
            })
        }

        if ($lblDashLastOptimization) {
            $lblDashLastOptimization.Dispatcher.Invoke([Action]{ $lblDashLastOptimization.Text = $metrics.LastOptimization })
        }

        if ($lblHeaderLastRun) {
            $lblHeaderLastRun.Dispatcher.Invoke([Action]{ $lblHeaderLastRun.Text = $metrics.LastOptimization })
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
            })
        }

        Update-SystemHealthSummary
    }
    catch {
        Write-Verbose "Dashboard metrics update failed: $($_.Exception.Message)"
    }
}

function Start-PerformanceMonitoring {
    try {
        if ($global:PerformanceTimer) {
            $global:PerformanceTimer.Stop()
        }

        $global:PerformanceTimer = New-Object System.Windows.Threading.DispatcherTimer
        $global:PerformanceTimer.Interval = [TimeSpan]::FromSeconds(3)
        $global:PerformanceTimer.Add_Tick({ Update-DashboardMetrics })
        $global:PerformanceTimer.Start()

        Update-DashboardMetrics
        Log 'Real-time performance monitoring started (3s interval)' 'Success'
    }
    catch {
        Log "Error starting performance monitoring: $($_.Exception.Message)" 'Error'
    }
}

function Stop-PerformanceMonitoring {
    try {
        if ($global:PerformanceTimer) {
            $global:PerformanceTimer.Stop()
            $global:PerformanceTimer = $null
            Log 'Performance monitoring stopped' 'Info'
        }
    }
    catch {
        Write-Verbose "Error stopping performance monitoring: $($_.Exception.Message)"
    }
}

function Show-ElevationMessage {
    param(
        [string]$Title = 'Administrator Privileges Required',
        [string]$Message = 'Some optimizations require administrator privileges for system-level changes.',
        [string[]]$Operations = @(),
        [switch]$ForceElevation
    )

    $prompt = $Message
    if ($Operations.Count -gt 0) {
        $prompt += "`n`nOperations requiring elevation:"
        $Operations | ForEach-Object { $prompt += "`n* $_" }
    }

    $prompt += "`n`nWould you like to:"                + "`n* Yes: Restart with administrator privileges"                + "`n* No: Continue with limited functionality"                + "`n* Cancel: Exit application"

    $result = [System.Windows.MessageBox]::Show(
        $prompt,
        "KOALA Gaming Optimizer v3.0 - $Title",
        'YesNoCancel',
        'Warning'
    )

    switch ($result) {
        'Yes' {
            try {
                $scriptPath = if ($PSCommandPath) { $PSCommandPath } else { Join-Path $ScriptRoot 'koalafixed.ps1' }
                Start-Process -FilePath 'powershell.exe' -ArgumentList "-ExecutionPolicy Bypass -File `"$scriptPath`"" -Verb RunAs -ErrorAction Stop
                if ($form) { $form.Close() }
                return $true
            }
            catch {
                Log "Failed to elevate privileges: $($_.Exception.Message)" 'Error'
                return $false
            }
        }
        'No' {
            Log 'Running in limited mode - some optimizations will be unavailable' 'Warning'
            return $false
        }
        'Cancel' {
            Log 'User cancelled - exiting application' 'Info'
            if ($form) { $form.Close() }
            return $false
        }
    }
}

function Get-SystemInfo {
    try {
        $info = @{
            OS = (Get-CimInstance Win32_OperatingSystem).Caption
            CPU = (Get-CimInstance Win32_Processor).Name
            RAM = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
            GPU = (Get-CimInstance Win32_VideoController | Where-Object { $_.Name -notlike '*Basic*' -and $_.Name -notlike '*Generic*' }).Name -join ', '
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

        [System.Windows.MessageBox]::Show($infoText, 'System Information', 'OK', 'Information') | Out-Null
    }
    catch {
        Log "Failed to gather system info: $($_.Exception.Message)" 'Error'
    }
}

function Get-GPUVendor {
    try {
        $gpus = Get-CimInstance -ClassName Win32_VideoController -ErrorAction Stop |
            Where-Object { $_.Name -notlike '*Basic*' -and $_.Name -notlike '*Generic*' -and $_.PNPDeviceID -notlike 'ROOT\*' }

        foreach ($gpu in $gpus) {
            if ($gpu.Name -match 'NVIDIA|GeForce|GTX|RTX|Quadro') { return 'NVIDIA' }
            if ($gpu.Name -match 'AMD|RADEON|RX|FirePro') { return 'AMD' }
            if ($gpu.Name -match 'Intel|HD Graphics|UHD Graphics|Iris') { return 'Intel' }
        }

        return 'Other'
    }
    catch {
        Log "Unable to detect GPU vendor: $($_.Exception.Message)" 'Warning'
        return 'Other'
    }
}

function Set-Reg {
    param(
        [string]$Path,
        [string]$Name,
        [ValidateSet('String','ExpandString','Binary','DWord','QWord','MultiString')]
        [string]$Type = 'DWord',
        $Value,
        [switch]$RequiresAdmin
    )

    if (-not $Path -or -not $Name) {
        Log "Set-Reg: Invalid parameters - Path: '$Path', Name: '$Name'" 'Error'
        return $false
    }

    if ($RequiresAdmin -and -not (Test-AdminPrivileges)) {
        Log "Set-Reg: Administrative privileges required for $Path\$Name" 'Warning'
        return $false
    }

    $cacheKey = "$Path\$Name"
    if ($global:RegistryCache.ContainsKey($cacheKey) -and $global:RegistryCache[$cacheKey] -eq $Value) {
        return $true
    }

    try {
        $parent = Split-Path $Path -Parent
        if ($parent -and -not (Test-Path $Path)) {
            New-Item -Path $Path -Force -ErrorAction Stop | Out-Null
        }

        $exists = $null -ne (Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue)
        if ($exists) {
            Set-ItemProperty -Path $Path -Name $Name -Value $Value -Force -ErrorAction Stop
        } else {
            New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $Type -Force -ErrorAction Stop | Out-Null
        }

        $verify = Get-ItemProperty -Path $Path -Name $Name -ErrorAction Stop
        if ($null -ne $verify -and $verify.$Name -eq $Value) {
            $global:RegistryCache[$cacheKey] = $Value
            return $true
        }

        Log "Set-Reg: Verification failed for $Path\$Name" 'Error'
        return $false
    }
    catch {
        Log "Set-Reg: Error setting ${Path}\${Name}: $($_.Exception.Message)" 'Error'
        return $false
    }
}

function Get-Reg {
    param(
        [string]$Path,
        [string]$Name
    )

    try {
        return (Get-ItemProperty -Path $Path -Name $Name -ErrorAction Stop).$Name
    }
    catch {
        return $null
    }
}

function Remove-Reg {
    param(
        [string]$Path,
        [string]$Name
    )

    try {
        Remove-ItemProperty -Path $Path -Name $Name -Force -ErrorAction Stop
        return $true
    }
    catch {
        return $false
    }
}
