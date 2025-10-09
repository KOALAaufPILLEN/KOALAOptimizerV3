Set-StrictMode -Version Latest

$requiredApartment = [System.Threading.ApartmentState]::STA
$currentThread = [System.Threading.Thread]::CurrentThread
if ($currentThread.GetApartmentState() -ne $requiredApartment) {
    $staSet = $false
    try {
        $staSet = $currentThread.TrySetApartmentState($requiredApartment)
    }
    catch {
        $staSet = $false
    }

    if (-not $staSet) {
        if ($env:KOALA_GUI_STA_REDIRECT -ne '1') {
            $launcher = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
            $scriptPath = $null
            try {
                if ($MyInvocation.MyCommand -and $MyInvocation.MyCommand.Path) {
                    $scriptPath = $MyInvocation.MyCommand.Path
                }
            }
            catch {
                $scriptPath = $null
            }

            if ($launcher) {
                $psi = [System.Diagnostics.ProcessStartInfo]::new()
                $psi.FileName = $launcher
                $psi.UseShellExecute = $false
                $psi.EnvironmentVariables['KOALA_GUI_STA_REDIRECT'] = '1'

                $argumentBuilder = New-Object System.Text.StringBuilder
                if ($launcher -match 'pwsh|powershell') {
                    $null = $argumentBuilder.Append('-NoLogo -NoProfile -ExecutionPolicy Bypass')
                    if ($scriptPath) {
                        $escapedPath = '"' + ($scriptPath -replace '"', '""') + '"'
                        $null = $argumentBuilder.Append(" -File $escapedPath")
                    }
                }
                elseif ($scriptPath) {
                    $psi.FileName = $scriptPath
                }

                if ($args -and $args.Count -gt 0) {
                    $escapedArgs = foreach ($value in $args) {
                        '"' + ([string]$value -replace '"', '""') + '"'
                    }
                    $joinedArgs = [string]::Join(' ', $escapedArgs)

                    if ($argumentBuilder.Length -gt 0) {
                        $null = $argumentBuilder.Append(' ')
                    }
                    $null = $argumentBuilder.Append($joinedArgs)
                }

                if ($argumentBuilder.Length -gt 0) {
                    $psi.Arguments = $argumentBuilder.ToString()
                }

                try {
                    $process = [System.Diagnostics.Process]::Start($psi)
                    if ($process) {
                        $process.WaitForExit()
                        return
                    }
                }
                catch {
                    # fall through to error reporting below
                }
            }

            Write-Error 'Unable to enforce STA thread requirement for the KOALA Optimizer GUI.'
            return
        }
        else {
            Write-Error 'Unable to initialize KOALA Optimizer GUI in STA mode.'
            return
        }
    }
}

if ($env:KOALA_GUI_STA_REDIRECT -eq '1') {
    Remove-Item Env:KOALA_GUI_STA_REDIRECT -ErrorAction SilentlyContinue
}

$scriptDir = $null
try {
    if ($MyInvocation.MyCommand -and $MyInvocation.MyCommand.Path) {
        $scriptDir = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
    }
}
catch {
    # ignored – fallback logic below will handle resolution
}

if (-not $scriptDir) {
    try {
        $scriptDir = [System.IO.Path]::GetDirectoryName([System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName)
    }
    catch {
        $scriptDir = (Get-Location).Path
    }
}

# Ensure that the WPF assemblies are loaded even when the script is executed on a
# fresh host that has not run helpers.ps1 yet.  The calls are wrapped in a
# try/catch block to provide a friendly error message instead of a cryptic
# exception that would immediately terminate the GUI start-up sequence.
$wpfAssemblies = @('PresentationFramework', 'PresentationCore', 'WindowsBase', 'System.Xaml')
foreach ($assembly in $wpfAssemblies) {
    if (-not ([AppDomain]::CurrentDomain.GetAssemblies().FullName -match "^$assembly,")) {
        try {
            Add-Type -AssemblyName $assembly -ErrorAction Stop
        }
        catch {
            Write-Error "Unable to load required assembly '$assembly'. GUI cannot start. $_"
            return
        }
    }
}

# Define a compact color palette that mirrors the soft neon purple theme used by
# the legacy UI.  The values are injected into the XAML resources so that we can
# reuse them when updating button states from code.
$defaultTheme = [ordered]@{
    Background    = '#0F0B1E'
    Sidebar       = '#1C1733'
    Accent        = '#8F6FFF'
    AccentLight   = '#B9A7FF'
    Hover         = '#2A214F'
    Selected      = '#403270'
    Header        = '#1D1834'
    Card          = '#221C3F'
    TextPrimary   = '#FFFFFF'
    TextSecondary = '#B8B5D1'
    Success       = '#22C55E'
    Warning       = '#F59E0B'
}

$existingTheme = $null
try {
    if (-not (Test-Path 'variable:script:theme')) {
        Set-Variable -Scope Script -Name theme -Value $null -Force
    }

    $existingTheme = Get-Variable -Name theme -Scope Script -ValueOnly -ErrorAction Stop
}
catch {
    $existingTheme = $null
}

if (-not ($existingTheme -is [System.Collections.IDictionary])) {
    $existingTheme = @{}
}

$theme = [ordered]@{}
foreach ($key in $defaultTheme.Keys) {
    $value = $null
    if ($existingTheme -and ($existingTheme.Keys -contains $key)) {
        $value = $existingTheme[$key]
    }

    if ([string]::IsNullOrWhiteSpace([string]$value)) {
        $value = $defaultTheme[$key]
    }

    $theme[$key] = $value
}

$script:theme = $theme

$resourceToThemeMap = @{
    AppBackground      = 'Background'
    SidebarBackground  = 'Sidebar'
    AccentBrush        = 'Accent'
    AccentLightBrush   = 'AccentLight'
    HoverBrush         = 'Hover'
    SelectedBrush      = 'Selected'
    HeaderBrush        = 'Header'
    CardBrush          = 'Card'
    TextPrimaryBrush   = 'TextPrimary'
    TextSecondaryBrush = 'TextSecondary'
    SuccessBrush       = 'Success'
    WarningBrush       = 'Warning'
}

# XAML definition for the window.  It intentionally keeps the structure simple:
# a sidebar with navigation buttons and several content panels that are toggled
# from code.  The emojis from the legacy UI are preserved to keep the playful
# touch that users expect from KOALA.
$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="KOALA Optimizer v3"
        Width="1300" Height="820"
        Background="{DynamicResource AppBackground}"
        WindowStartupLocation="CenterScreen">
    <Window.Resources>
        <SolidColorBrush x:Key="AppBackground" Color="$($theme.Background)" />
        <SolidColorBrush x:Key="SidebarBackground" Color="$($theme.Sidebar)" />
        <SolidColorBrush x:Key="AccentBrush" Color="$($theme.Accent)" />
        <SolidColorBrush x:Key="AccentLightBrush" Color="$($theme.AccentLight)" />
        <SolidColorBrush x:Key="HoverBrush" Color="$($theme.Hover)" />
        <SolidColorBrush x:Key="SelectedBrush" Color="$($theme.Selected)" />
        <SolidColorBrush x:Key="HeaderBrush" Color="$($theme.Header)" />
        <SolidColorBrush x:Key="CardBrush" Color="$($theme.Card)" />
        <SolidColorBrush x:Key="TextPrimaryBrush" Color="$($theme.TextPrimary)" />
        <SolidColorBrush x:Key="TextSecondaryBrush" Color="$($theme.TextSecondary)" />
        <SolidColorBrush x:Key="SuccessBrush" Color="$($theme.Success)" />
        <SolidColorBrush x:Key="WarningBrush" Color="$($theme.Warning)" />

        <Style x:Key="NavButtonStyle" TargetType="Button">
            <Setter Property="Background" Value="Transparent" />
            <Setter Property="Foreground" Value="{StaticResource TextSecondaryBrush}" />
            <Setter Property="BorderThickness" Value="0" />
            <Setter Property="Padding" Value="14,10" />
            <Setter Property="FontSize" Value="16" />
            <Setter Property="HorizontalContentAlignment" Value="Left" />
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="ButtonBorder" Background="{TemplateBinding Background}" CornerRadius="10">
                            <ContentPresenter Margin="6,0,0,0" />
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="ButtonBorder" Property="Background" Value="{StaticResource HoverBrush}" />
                                <Setter Property="Foreground" Value="{StaticResource TextPrimaryBrush}" />
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="ButtonBorder" Property="Background" Value="{StaticResource SelectedBrush}" />
                                <Setter Property="Foreground" Value="{StaticResource TextPrimaryBrush}" />
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter Property="Opacity" Value="0.6" />
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style x:Key="ActionButtonStyle" TargetType="Button">
            <Setter Property="Background" Value="{StaticResource CardBrush}" />
            <Setter Property="Foreground" Value="{StaticResource TextPrimaryBrush}" />
            <Setter Property="BorderThickness" Value="0" />
            <Setter Property="Padding" Value="12,8" />
            <Setter Property="FontSize" Value="14" />
            <Setter Property="Margin" Value="0,0,12,0" />
            <Setter Property="Cursor" Value="Hand" />
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="ActionBorder" Background="{TemplateBinding Background}" CornerRadius="8">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center" Margin="8,4" />
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="ActionBorder" Property="Background" Value="{StaticResource HoverBrush}" />
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="ActionBorder" Property="Background" Value="{StaticResource AccentBrush}" />
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>

    <Grid>
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="240" />
            <ColumnDefinition Width="*" />
        </Grid.ColumnDefinitions>

        <Border Grid.Column="0" Background="{StaticResource SidebarBackground}" Padding="24" >
            <StackPanel>
                <TextBlock Text="KOALA Optimizer" FontSize="24" FontWeight="Bold" Foreground="{StaticResource TextPrimaryBrush}" />
                <TextBlock x:Name="AdminStatus" Text="Checking privileges..." Margin="0,4,0,20" Foreground="{StaticResource TextSecondaryBrush}" />

                <StackPanel x:Name="NavigationHost" >
                    <Button x:Name="NavDashboard" Style="{StaticResource NavButtonStyle}" Content="🏠  Dashboard" Tag="Dashboard" />
                    <Button x:Name="NavQuick" Style="{StaticResource NavButtonStyle}" Content="⚡  Quick optimize" Tag="Quick" />
                    <Button x:Name="NavAdvanced" Style="{StaticResource NavButtonStyle}" Content="🛠️  Advanced" Tag="Advanced" />
                    <Button x:Name="NavGames" Style="{StaticResource NavButtonStyle}" Content="🎮  Games" Tag="Games" />
                    <Button x:Name="NavOptions" Style="{StaticResource NavButtonStyle}" Content="🎨  Options" Tag="Options" />
                    <Button x:Name="NavBackup" Style="{StaticResource NavButtonStyle}" Content="🗂️  Backup" Tag="Backup" />
                    <Button x:Name="NavLog" Style="{StaticResource NavButtonStyle}" Content="🧾  Activity" Tag="Log" />
                </StackPanel>

                <Border Background="{StaticResource CardBrush}" Padding="12" CornerRadius="10" Margin="0,32,0,0">
                    <StackPanel>
                        <TextBlock Text="Helpful tips" Foreground="{StaticResource TextPrimaryBrush}" FontWeight="SemiBold" />
                        <TextBlock Text="Switch between panels to explore optimizations." Foreground="{StaticResource TextSecondaryBrush}" TextWrapping="Wrap" />
                    </StackPanel>
                </Border>
            </StackPanel>
        </Border>

        <Grid Grid.Column="1" Background="{StaticResource AppBackground}">
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto" />
                <RowDefinition Height="*" />
                <RowDefinition Height="220" />
            </Grid.RowDefinitions>

            <Border Grid.Row="0" Background="{StaticResource HeaderBrush}" Padding="24" BorderThickness="0,0,0,1" BorderBrush="#221C3F">
                <StackPanel>
                    <TextBlock x:Name="HeaderTitle" Text="Dashboard" FontSize="30" FontWeight="Bold" Foreground="{StaticResource TextPrimaryBrush}" />
                    <TextBlock x:Name="HeaderSubtitle" Text="Monitor system health and launch optimizations." Foreground="{StaticResource TextSecondaryBrush}" />
                </StackPanel>
            </Border>

            <Grid Grid.Row="1" Margin="24">
                <Grid x:Name="DashboardPanel">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto" />
                        <RowDefinition Height="Auto" />
                        <RowDefinition Height="*" />
                    </Grid.RowDefinitions>
                    <StackPanel>
                        <TextBlock Text="Welcome back!" FontSize="20" FontWeight="Bold" Foreground="{StaticResource TextPrimaryBrush}" />
                        <TextBlock Text="Run quick actions below to keep your rig in top shape." Foreground="{StaticResource TextSecondaryBrush}" />
                    </StackPanel>
                    <WrapPanel Grid.Row="1" Margin="0,20,0,0" ItemWidth="230" ItemHeight="110">
                        <Border Background="{StaticResource CardBrush}" CornerRadius="12" Padding="16" Margin="0,0,16,16">
                            <StackPanel>
                                <TextBlock Text="⚙️ Quick optimize" FontWeight="SemiBold" Foreground="{StaticResource TextPrimaryBrush}" />
                                <TextBlock Text="Apply safe presets with a single click." Foreground="{StaticResource TextSecondaryBrush}" TextWrapping="Wrap" Margin="0,4,0,12" />
                                <Button x:Name="DashboardQuickButton" Content="Run quick optimize" Style="{StaticResource ActionButtonStyle}" />
                            </StackPanel>
                        </Border>
                        <Border Background="{StaticResource CardBrush}" CornerRadius="12" Padding="16" Margin="0,0,16,16">
                            <StackPanel>
                                <TextBlock Text="📈 Benchmark" FontWeight="SemiBold" Foreground="{StaticResource TextPrimaryBrush}" />
                                <TextBlock Text="Launch the benchmark script to verify gains." Foreground="{StaticResource TextSecondaryBrush}" TextWrapping="Wrap" Margin="0,4,0,12" />
                                <Button x:Name="DashboardBenchmarkButton" Content="Start benchmark" Style="{StaticResource ActionButtonStyle}" />
                            </StackPanel>
                        </Border>
                        <Border Background="{StaticResource CardBrush}" CornerRadius="12" Padding="16" Margin="0,0,16,16">
                            <StackPanel>
                                <TextBlock Text="🔄 Update" FontWeight="SemiBold" Foreground="{StaticResource TextPrimaryBrush}" />
                                <TextBlock Text="Check for new tweaks and script revisions." Foreground="{StaticResource TextSecondaryBrush}" TextWrapping="Wrap" Margin="0,4,0,12" />
                                <Button x:Name="DashboardUpdateButton" Content="Check for updates" Style="{StaticResource ActionButtonStyle}" />
                            </StackPanel>
                        </Border>
                    </WrapPanel>
                </Grid>

                <Grid x:Name="QuickPanel" Visibility="Collapsed">
                    <StackPanel>
                        <TextBlock Text="Quick optimization" FontSize="20" FontWeight="Bold" Foreground="{StaticResource TextPrimaryBrush}" />
                        <TextBlock Text="Select a preset to immediately tune your system." Foreground="{StaticResource TextSecondaryBrush}" />
                        <StackPanel Orientation="Horizontal" Margin="0,20,0,0">
                            <Button x:Name="QuickNetworkButton" Content="🌐 Network boost" Style="{StaticResource ActionButtonStyle}" />
                            <Button x:Name="QuickSystemButton" Content="💻 System boost" Style="{StaticResource ActionButtonStyle}" />
                            <Button x:Name="QuickGamingButton" Content="🎮 Gaming boost" Style="{StaticResource ActionButtonStyle}" />
                        </StackPanel>
                    </StackPanel>
                </Grid>

                <Grid x:Name="AdvancedPanel" Visibility="Collapsed">
                    <StackPanel>
                        <TextBlock Text="Advanced controls" FontSize="20" FontWeight="Bold" Foreground="{StaticResource TextPrimaryBrush}" />
                        <TextBlock Text="Run deep tweaks when you need full control." Foreground="{StaticResource TextSecondaryBrush}" />
                        <StackPanel Orientation="Horizontal" Margin="0,20,0,0">
                            <Button x:Name="AdvancedNetworkButton" Content="🌐 Apply network tweaks" Style="{StaticResource ActionButtonStyle}" />
                            <Button x:Name="AdvancedSystemButton" Content="🧠 Apply system tweaks" Style="{StaticResource ActionButtonStyle}" />
                            <Button x:Name="AdvancedServicesButton" Content="🛠️ Optimize services" Style="{StaticResource ActionButtonStyle}" />
                        </StackPanel>
                    </StackPanel>
                </Grid>

                <Grid x:Name="GamesPanel" Visibility="Collapsed">
                    <StackPanel>
                        <TextBlock Text="Game management" FontSize="20" FontWeight="Bold" Foreground="{StaticResource TextPrimaryBrush}" />
                        <TextBlock Text="Manage installed games and apply profiles." Foreground="{StaticResource TextSecondaryBrush}" />
                        <StackPanel Orientation="Horizontal" Margin="0,20,0,0">
                            <Button x:Name="GamesScanButton" Content="🔍 Scan library" Style="{StaticResource ActionButtonStyle}" />
                            <Button x:Name="GamesOptimizeButton" Content="🎯 Optimize selected" Style="{StaticResource ActionButtonStyle}" />
                        </StackPanel>
                    </StackPanel>
                </Grid>

                <Grid x:Name="OptionsPanel" Visibility="Collapsed">
                    <StackPanel>
                        <TextBlock Text="Options" FontSize="20" FontWeight="Bold" Foreground="{StaticResource TextPrimaryBrush}" />
                        <TextBlock Text="Adjust theme accents and behaviour." Foreground="{StaticResource TextSecondaryBrush}" />
                        <StackPanel Orientation="Horizontal" Margin="0,20,0,0">
                            <Button x:Name="OptionsDarkThemeButton" Content="🌙 Dark" Style="{StaticResource ActionButtonStyle}" />
                            <Button x:Name="OptionsVividThemeButton" Content="✨ Vivid" Style="{StaticResource ActionButtonStyle}" />
                        </StackPanel>
                    </StackPanel>
                </Grid>

                <Grid x:Name="BackupPanel" Visibility="Collapsed">
                    <StackPanel>
                        <TextBlock Text="Backups" FontSize="20" FontWeight="Bold" Foreground="{StaticResource TextPrimaryBrush}" />
                        <TextBlock Text="Save and restore your KOALA configuration." Foreground="{StaticResource TextSecondaryBrush}" />
                        <StackPanel Orientation="Horizontal" Margin="0,20,0,0">
                            <Button x:Name="BackupCreateButton" Content="💾 Create backup" Style="{StaticResource ActionButtonStyle}" />
                            <Button x:Name="BackupRestoreButton" Content="📥 Restore backup" Style="{StaticResource ActionButtonStyle}" />
                            <Button x:Name="BackupExportButton" Content="📤 Export config" Style="{StaticResource ActionButtonStyle}" />
                        </StackPanel>
                    </StackPanel>
                </Grid>

                <Grid x:Name="LogPanel" Visibility="Collapsed">
                    <StackPanel>
                        <TextBlock Text="Activity history" FontSize="20" FontWeight="Bold" Foreground="{StaticResource TextPrimaryBrush}" />
                        <TextBlock Text="Use the log below to track every optimization." Foreground="{StaticResource TextSecondaryBrush}" />
                        <Button x:Name="LogCopyButton" Content="📋 Copy log to clipboard" Style="{StaticResource ActionButtonStyle}" Margin="0,20,0,0" Width="220" />
                    </StackPanel>
                </Grid>
            </Grid>

            <Border Grid.Row="2" Background="{StaticResource CardBrush}" Margin="24" Padding="16" CornerRadius="12">
                <Grid>
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto" />
                        <RowDefinition Height="*" />
                    </Grid.RowDefinitions>
                    <TextBlock Text="Activity log" Foreground="{StaticResource TextPrimaryBrush}" FontWeight="SemiBold" />
                    <TextBox x:Name="LogTextBox" Grid.Row="1" Margin="0,12,0,0" Background="#110C25" Foreground="{StaticResource TextSecondaryBrush}" 
                             BorderThickness="0" IsReadOnly="True" VerticalScrollBarVisibility="Auto" TextWrapping="Wrap" AcceptsReturn="True" />
                </Grid>
            </Border>
        </Grid>
    </Grid>
</Window>
"@

function Show-CriticalError {
    param([string]$Message)

    try {
        [System.Windows.MessageBox]::Show(
            $Message,
            'KOALA Optimizer',
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Error
        ) | Out-Null
    }
    catch {
        Write-Error $Message
    }
}

# Parse XAML into a WPF window instance.
if (-not $xaml) {
    Show-CriticalError 'The GUI markup could not be loaded. The interface cannot be rendered.'
    return
}

$xamlXml = $null
try {
    [xml]$xamlXml = $xaml
}
catch {
    Show-CriticalError "The GUI markup is invalid XML: $($_.Exception.Message)"
    return
}

$reader = $null
$window = $null
try {
    $reader = New-Object System.Xml.XmlNodeReader $xamlXml
    $window = [Windows.Markup.XamlReader]::Load($reader)
}
catch {
    Show-CriticalError "Unable to construct the KOALA Optimizer window: $($_.Exception.Message)"
    return
}
finally {
    if ($reader) {
        $reader.Close()
    }
}

if (-not $window) {
    Show-CriticalError 'The KOALA Optimizer window failed to initialize.'
    return
}

# Convenience accessor for theme brushes defined in the resource dictionary.
function Get-Brush {
    param([string]$Key)
    if ($window -and $window.Resources -and $window.Resources.Contains($Key)) {
        return [System.Windows.Media.Brush]$window.Resources[$Key]
    }

    if ($resourceToThemeMap.ContainsKey($Key)) {
        $themeKey = $resourceToThemeMap[$Key]
        if ($theme[$themeKey]) {
            try {
                $color = [System.Windows.Media.ColorConverter]::ConvertFromString($theme[$themeKey])
                if ($color) {
                    return [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]$color)
                }
            }
            catch {
                # fall through to default brush
            }
        }
    }

    return [System.Windows.Media.Brushes]::Transparent
}

$navButtons = @()
if ($window) {
    $navButtons = @(
        $window.FindName('NavDashboard'),
        $window.FindName('NavQuick'),
        $window.FindName('NavAdvanced'),
        $window.FindName('NavGames'),
        $window.FindName('NavOptions'),
        $window.FindName('NavBackup'),
        $window.FindName('NavLog')
    ) | Where-Object { $_ -ne $null }
}

$panels = @{}
if ($window) {
    $panels = @{
        Dashboard = $window.FindName('DashboardPanel')
        Quick      = $window.FindName('QuickPanel')
        Advanced   = $window.FindName('AdvancedPanel')
        Games      = $window.FindName('GamesPanel')
        Options    = $window.FindName('OptionsPanel')
        Backup     = $window.FindName('BackupPanel')
        Log        = $window.FindName('LogPanel')
    }
}

$headerTitle    = if ($window) { $window.FindName('HeaderTitle') }
$headerSubtitle = if ($window) { $window.FindName('HeaderSubtitle') }
$adminStatus    = if ($window) { $window.FindName('AdminStatus') }
$logBox         = if ($window) { $window.FindName('LogTextBox') }

$panelMetadata = @{
    Dashboard = @{ Title = 'Dashboard'; Subtitle = 'Monitor system health and launch optimizations.' }
    Quick     = @{ Title = 'Quick optimize'; Subtitle = 'Instant presets for rapid tuning.' }
    Advanced  = @{ Title = 'Advanced tuning'; Subtitle = 'Granular tweaks for power users.' }
    Games     = @{ Title = 'Games library'; Subtitle = 'Scan, detect and boost installed titles.' }
    Options   = @{ Title = 'Appearance & behaviour'; Subtitle = 'Adjust theme accents and automation.' }
    Backup    = @{ Title = 'Backup & restore'; Subtitle = 'Keep your KOALA configuration safe.' }
    Log       = @{ Title = 'Activity history'; Subtitle = 'Review everything KOALA has changed.' }
}

function Write-AppLog {
    param(
        [Parameter(Mandatory)][string]$Message,
        [ValidateSet('Info','Success','Warning','Error')][string]$Level = 'Info'
    )

    $timestamp = (Get-Date).ToString('HH:mm:ss')
    $entry = "[$timestamp] [$Level] $Message"

    if ($window -and $logBox) {
        try {
            if ($window.Dispatcher.CheckAccess()) {
                $logBox.AppendText($entry + [Environment]::NewLine)
                $logBox.ScrollToEnd()
            }
            else {
                $window.Dispatcher.Invoke([action]{
                    $logBox.AppendText($entry + [Environment]::NewLine)
                    $logBox.ScrollToEnd()
                })
            }
        }
        catch {
            Write-Host $entry
        }
    }
    else {
        Write-Host $entry
    }
}

function Select-NavigationButton {
    param([string]$PanelKey)

    if (-not $navButtons -or $navButtons.Count -eq 0) {
        return
    }

    $selectedBrush = Get-Brush 'SelectedBrush'
    $textPrimary   = Get-Brush 'TextPrimaryBrush'
    $textSecondary = Get-Brush 'TextSecondaryBrush'

    foreach ($button in $navButtons) {
        if (-not $button) { continue }
        if ($button.Tag -eq $PanelKey) {
            $button.Background = $selectedBrush
            $button.Foreground = $textPrimary
        }
        else {
            $button.Background = [System.Windows.Media.Brushes]::Transparent
            $button.Foreground = $textSecondary
        }
    }
}

function Show-Panel {
    param([string]$PanelKey)

    if (-not $panels -or -not $panels.ContainsKey($PanelKey)) {
        Write-AppLog "Panel '$PanelKey' not found." 'Warning'
        return
    }

    if ($panels.Count -gt 0) {
        foreach ($panel in $panels.GetEnumerator()) {
            if ($panel.Value) {
                $panel.Value.Visibility = if ($panel.Key -eq $PanelKey) { 'Visible' } else { 'Collapsed' }
            }
        }
    }

    Select-NavigationButton -PanelKey $PanelKey

    if ($panelMetadata.ContainsKey($PanelKey)) {
        if ($headerTitle) { $headerTitle.Text = $panelMetadata[$PanelKey].Title }
        if ($headerSubtitle) { $headerSubtitle.Text = $panelMetadata[$PanelKey].Subtitle }
    }

    Write-AppLog "Switched to $PanelKey panel." 'Info'
}

function Invoke-IfAvailable {
    param(
        [Parameter(Mandatory)][string]$CommandName,
        [string]$Description,
        [hashtable]$Arguments
    )

    $description = if ($Description) { $Description } else { $CommandName }

    $command = Get-Command -Name $CommandName -ErrorAction SilentlyContinue
    if (-not $command) {
        Write-AppLog "Command '$CommandName' not available. Using built-in placeholder for $description." 'Info'
        return $false
    }

    try {
        if ($Arguments) {
            & $command @Arguments
        }
        else {
            & $command
        }
        Write-AppLog "$description completed." 'Success'
        return $true
    }
    catch {
        Write-AppLog "$description failed: $($_.Exception.Message)" 'Error'
        return $false
    }
}

function Invoke-PanelAction {
    param(
        [Parameter(Mandatory)][string]$Description,
        [Parameter(Mandatory)][scriptblock]$Action
    )

    Write-AppLog "Starting $Description..." 'Info'
    try {
        & $Action
        Write-AppLog "$Description finished." 'Success'
    }
    catch {
        Write-AppLog "$Description failed: $($_.Exception.Message)" 'Error'
    }
}

function Update-AdminStatus {
    if (-not $adminStatus) { return }
    try {
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = [Security.Principal.WindowsPrincipal]$identity
        if ($principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
            $adminStatus.Text = "🟢 Running with administrator rights"
            $adminStatus.Foreground = Get-Brush 'SuccessBrush'
        }
        else {
            $adminStatus.Text = "🟡 Limited privileges detected"
            $adminStatus.Foreground = Get-Brush 'WarningBrush'
        }
    }
    catch {
        $adminStatus.Text = "Privilege check unavailable"
        Write-AppLog "Failed to detect administrator privileges: $($_.Exception.Message)" 'Warning'
    }
}

# Optimization helpers ------------------------------------------------------

function Invoke-NetworkPreset {
    param(
        [ValidateSet('Quick','Advanced')]
        [string]$Preset = 'Quick'
    )

    $presets = @{
        Quick = @{
            TCPAck            = $true
            DelAckTicks       = $true
            NetworkThrottling = $true
            NagleAlgorithm    = $true
            RSS               = $true
            RSC               = $true
            AutoTuning        = $true
        }
        Advanced = @{
            TCPAck            = $true
            DelAckTicks       = $true
            NetworkThrottling = $true
            NagleAlgorithm    = $true
            TCPTimestamps     = $true
            ECN               = $true
            RSS               = $true
            RSC               = $true
            AutoTuning        = $true
        }
    }

    $settings = $presets[$Preset]
    if (-not $settings) {
        Write-AppLog "No network preset named '$Preset' was found." 'Warning'
        return $false
    }

    return Invoke-IfAvailable 'Apply-NetworkOptimizations' "Network optimizations ($Preset)" @{ Settings = $settings }
}

function Invoke-SystemPreset {
    param(
        [ValidateSet('Quick','Advanced')]
        [string]$Preset = 'Quick'
    )

    $presets = @{
        Quick = @{
            AdaptivePowerManagement = $true
            EnhancedPagingFile      = $true
        }
        Advanced = @{
            AutoDiskOptimization    = $true
            AdaptivePowerManagement = $true
            EnhancedPagingFile      = $true
            DirectStorageEnhanced   = $true
        }
    }

    $settings = $presets[$Preset]
    if (-not $settings) {
        Write-AppLog "No system preset named '$Preset' was found." 'Warning'
        return $false
    }

    $results = @()
    $results += Invoke-IfAvailable 'Apply-EnhancedSystemOptimizations' "Enhanced system optimizations ($Preset)" @{ Settings = $settings }

    if ($Preset -eq 'Advanced') {
        $results += Invoke-IfAvailable 'Disable-AdvancedTelemetry' 'Disable advanced telemetry'
        $results += Invoke-IfAvailable 'Enable-MemoryDefragmentation' 'Enable memory defragmentation'
        $results += Invoke-IfAvailable 'Apply-DiskTweaksAdvanced' 'Apply advanced disk tweaks'
    }

    return ($results -contains $true)
}

function Invoke-GamingPreset {
    param(
        [ValidateSet('Quick','Advanced')]
        [string]$Preset = 'Quick'
    )

    $optimizationSets = @{
        Quick = @('DirectXOptimization','ShaderCacheOptimization','InputLatencyReduction','GPUSchedulingOptimization')
        Advanced = @('DirectXOptimization','DirectX12Optimization','ShaderCacheOptimization','InputLatencyReduction','GPUSchedulingOptimization','MemoryPoolOptimization','AudioLatencyOptimization','CPUCoreParkDisable')
    }

    $results = @()
    $results += Invoke-IfAvailable 'Disable-GameDVR' 'Disable Game DVR'
    $results += Invoke-IfAvailable 'Enable-GPUScheduling' 'Enable GPU scheduling'

    $optimizations = $optimizationSets[$Preset]
    if ($optimizations) {
        $results += Invoke-IfAvailable 'Apply-FPSOptimizations' "FPS optimizations ($Preset)" @{ OptimizationList = $optimizations }
    }
    else {
        Write-AppLog "No gaming preset named '$Preset' was found." 'Warning'
    }

    if ($Preset -eq 'Advanced') {
        $results += Invoke-IfAvailable 'Enable-FPSSmoothness' 'Enable FPS smoothness tweaks'
        $results += Invoke-IfAvailable 'Optimize-CPUMicrocode' 'Optimize CPU microcode'
        $results += Invoke-IfAvailable 'Optimize-RAMTimings' 'Optimize RAM timings'
    }

    return ($results -contains $true)
}

function Invoke-QuickOptimization {
    $results = @()
    $results += Invoke-NetworkPreset -Preset 'Quick'
    $results += Invoke-SystemPreset -Preset 'Quick'
    $results += Invoke-GamingPreset -Preset 'Quick'

    if ($results -contains $true) {
        Write-AppLog 'Quick optimization preset completed with at least one successful routine.' 'Success'
        return $true
    }

    Write-AppLog 'Quick optimization preset finished without triggering any backend routines.' 'Warning'
    return $false
}

function Invoke-GameLibraryScan {
    param(
        [switch]$Silent
    )

    $command = Get-Command -Name 'Get-RunningGames' -ErrorAction SilentlyContinue
    if (-not $command) {
        if (-not $Silent) {
            Write-AppLog "Game scanning is unavailable because 'Get-RunningGames' is not loaded." 'Warning'
        }
        return @()
    }

    try {
        $games = & $command
        if (-not $Silent) {
            if ($games.Count -gt 0) {
                $names = ($games | ForEach-Object { $_.DisplayName }) -join ', '
                Write-AppLog "Detected running games: $names" 'Info'
            }
            else {
                Write-AppLog 'No running games detected right now.' 'Info'
            }
        }
        return $games
    }
    catch {
        Write-AppLog "Game scan failed: $($_.Exception.Message)" 'Error'
        return @()
    }
}

function Invoke-GameOptimization {
    $games = Invoke-GameLibraryScan -Silent
    if (-not $games -or $games.Count -eq 0) {
        Write-AppLog 'No detected games to optimize.' 'Warning'
        return $false
    }

    $success = $false
    foreach ($game in $games) {
        $process = $game.Process
        if ($process -is [System.Array]) {
            $process = if ($process.Length -gt 0) { $process[0] } else { $null }
        }

        if (-not $game.GameKey) {
            Write-AppLog "Skipping optimization for '${($game.DisplayName)}' because no profile key is available." 'Warning'
            continue
        }

        $gameOptimizationArgs = @{
            GameKey = $game.GameKey
            Process = $process
        }
        if (Invoke-IfAvailable 'Apply-GameOptimizations' "Optimize $($game.DisplayName)" $gameOptimizationArgs) {
            $success = $true
        }
    }

    if ($success) {
        Write-AppLog 'Game optimization routines executed.' 'Success'
    }
    else {
        Write-AppLog 'No game optimization routines were executed.' 'Warning'
    }

    return $success
}

# Event wiring --------------------------------------------------------------

$actionMap = @{
    DashboardQuickButton   = {
        Invoke-PanelAction 'Quick optimize' {
            Invoke-QuickOptimization | Out-Null
        }
    }
    DashboardBenchmarkButton = {
        Invoke-PanelAction 'Benchmark run' {
            if (-not (Invoke-IfAvailable 'Start-QuickBenchmark' 'Benchmark')) {
                Write-AppLog 'Benchmark routine not available.' 'Warning'
            }
        }
    }
    DashboardUpdateButton  = {
        Invoke-PanelAction 'Update check' {
            $updater = if ($scriptDir) { Join-Path -Path $scriptDir -ChildPath 'merger-update.ps1' } else { 'merger-update.ps1' }
            if (Test-Path $updater) {
                try {
                    Start-Process -FilePath "powershell" -ArgumentList "-NoProfile","-ExecutionPolicy","Bypass","-File","$updater" | Out-Null
                    Write-AppLog "Updater launched." 'Info'
                }
                catch {
                    Write-AppLog "Failed to launch updater: $($_.Exception.Message)" 'Error'
                }
            }
            else {
                Write-AppLog "Updater script not found." 'Warning'
            }
        }
    }
    QuickNetworkButton     = {
        Invoke-PanelAction 'Network boost' {
            Invoke-NetworkPreset -Preset 'Quick' | Out-Null
        }
    }
    QuickSystemButton      = {
        Invoke-PanelAction 'System boost' {
            Invoke-SystemPreset -Preset 'Quick' | Out-Null
        }
    }
    QuickGamingButton      = {
        Invoke-PanelAction 'Gaming boost' {
            Invoke-GamingPreset -Preset 'Quick' | Out-Null
        }
    }
    AdvancedNetworkButton  = {
        Invoke-PanelAction 'Advanced network tweaks' {
            Invoke-NetworkPreset -Preset 'Advanced' | Out-Null
        }
    }
    AdvancedSystemButton   = {
        Invoke-PanelAction 'Advanced system tweaks' {
            Invoke-SystemPreset -Preset 'Advanced' | Out-Null
        }
    }
    AdvancedServicesButton = {
        Invoke-PanelAction 'Service optimization' {
            if (-not (Invoke-IfAvailable 'Apply-ServiceOptimizations' 'Service optimization')) {
                Write-AppLog 'Service optimization routine unavailable.' 'Warning'
            }
        }
    }
    GamesScanButton        = {
        Invoke-PanelAction 'Library scan' {
            Invoke-GameLibraryScan | Out-Null
        }
    }
    GamesOptimizeButton    = {
        Invoke-PanelAction 'Game optimization' {
            Invoke-GameOptimization | Out-Null
        }
    }
    OptionsDarkThemeButton = {
        Invoke-PanelAction 'Apply dark theme' {
            if (-not ($window -and $window.Resources)) {
                Write-AppLog 'UI resources are not available to update.' 'Warning'
                return
            }

            try {
                $window.Resources['AppBackground'].Color    = [System.Windows.Media.ColorConverter]::ConvertFromString($theme.Background)
                $window.Resources['HeaderBrush'].Color      = [System.Windows.Media.ColorConverter]::ConvertFromString($theme.Header)
                $window.Resources['SidebarBackground'].Color = [System.Windows.Media.ColorConverter]::ConvertFromString($theme.Sidebar)
                $window.Resources['CardBrush'].Color        = [System.Windows.Media.ColorConverter]::ConvertFromString($theme.Card)
                $window.Resources['AccentBrush'].Color      = [System.Windows.Media.ColorConverter]::ConvertFromString($theme.Accent)
                $window.Resources['HoverBrush'].Color       = [System.Windows.Media.ColorConverter]::ConvertFromString($theme.Hover)
                Write-AppLog "Dark theme colors restored." 'Info'
            }
            catch {
                Write-AppLog "Failed to apply dark theme colors: $($_.Exception.Message)" 'Error'
            }
        }
    }
    OptionsVividThemeButton = {
        Invoke-PanelAction 'Apply vivid theme' {
            if (-not ($window -and $window.Resources)) {
                Write-AppLog 'UI resources are not available to update.' 'Warning'
                return
            }

            try {
                $window.Resources['AccentBrush'].Color = [System.Windows.Media.ColorConverter]::ConvertFromString('#FF6BFF')
                $window.Resources['HoverBrush'].Color  = [System.Windows.Media.ColorConverter]::ConvertFromString('#6B3FA0')
                Write-AppLog "Vivid theme applied." 'Info'
            }
            catch {
                Write-AppLog "Failed to apply vivid theme colors: $($_.Exception.Message)" 'Error'
            }
        }
    }
    BackupCreateButton     = {
        Invoke-PanelAction 'Create backup' {
            if (-not (Invoke-IfAvailable 'Create-Backup' 'Create backup')) {
                Write-AppLog 'Backup creation routine unavailable.' 'Warning'
            }
        }
    }
    BackupRestoreButton    = {
        Invoke-PanelAction 'Restore backup' {
            if (-not (Invoke-IfAvailable 'Restore-FromBackup' 'Restore backup')) {
                Write-AppLog 'Backup restore routine unavailable.' 'Warning'
            }
        }
    }
    BackupExportButton     = {
        Invoke-PanelAction 'Export configuration' {
            if (-not (Invoke-IfAvailable 'Export-Configuration' 'Export configuration')) {
                Write-AppLog 'Configuration export routine unavailable.' 'Warning'
            }
        }
    }
    LogCopyButton          = {
        Invoke-PanelAction 'Copy log' {
            if ($logBox) {
                [System.Windows.Clipboard]::SetText($logBox.Text)
            }
        }
    }
}

if ($window) {
    foreach ($entry in $actionMap.GetEnumerator()) {
        $control = $window.FindName($entry.Key)
        if ($control -and $control -is [System.Windows.Controls.Button]) {
            $null = $control.Add_Click($entry.Value)
        }
    }

    foreach ($button in $navButtons) {
        if (-not $button) { continue }
        $null = $button.Add_Click({
            param($sender,$args)
            $targetKey = $null
            if ($sender -and $sender.Tag) {
                $targetKey = [string]$sender.Tag
            }
            elseif ($args -and $args.Source -and $args.Source.Tag) {
                $targetKey = [string]$args.Source.Tag
            }

            if ($targetKey) {
                Show-Panel -PanelKey $targetKey
            }
        })
    }
}

Update-AdminStatus
Show-Panel -PanelKey 'Dashboard'

function Initialize-Application {
    param()

    if (-not $window) { return }

    $runAction = {
        param($wnd)

        if (-not $wnd) { return }

        $app = [System.Windows.Application]::Current
        if ($app -and $app.Dispatcher -and -not $app.Dispatcher.CheckAccess()) {
            $app = $null
        }

        if (-not $app) {
            $app = [System.Windows.Application]::new()
            $app.ShutdownMode = [System.Windows.ShutdownMode]::OnMainWindowClose
        }

        try {
            $app.MainWindow = $wnd
        }
        catch {
            $message = "Unable to set the KOALA Optimizer main window.`n$_"
            [System.Windows.MessageBox]::Show($message, 'KOALA Optimizer', [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error) | Out-Null
            return
        }

        try {
            $null = $app.Run($wnd)
        }
        catch {
            $message = "Unable to start the KOALA Optimizer interface.`n$_"
            [System.Windows.MessageBox]::Show($message, 'KOALA Optimizer', [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error) | Out-Null
        }
    }

    $dispatcher = $window.Dispatcher
    if ($dispatcher -and -not $dispatcher.CheckAccess()) {
        $dispatcher.Invoke($runAction, $window)
    }
    else {
        & $runAction $window
    }
}

if ($MyInvocation.InvocationName -ne '.' -and $window) {
    Initialize-Application
}
