Set-StrictMode -Version Latest

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
$theme = [ordered]@{
    Background            = '#0F0B1E'
    Sidebar               = '#1C1733'
    Accent                = '#8F6FFF'
    AccentLight           = '#B9A7FF'
    Hover                 = '#2A214F'
    Selected              = '#403270'
    Header                = '#1D1834'
    Card                  = '#221C3F'
    TextPrimary           = '#FFFFFF'
    TextSecondary         = '#B8B5D1'
    Success               = '#22C55E'
    Warning               = '#F59E0B'
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
        <SolidColorBrush x:Key="AppBackground" Color="#${($theme.Background.TrimStart('#'))}" />
        <SolidColorBrush x:Key="SidebarBackground" Color="#${($theme.Sidebar.TrimStart('#'))}" />
        <SolidColorBrush x:Key="AccentBrush" Color="#${($theme.Accent.TrimStart('#'))}" />
        <SolidColorBrush x:Key="AccentLightBrush" Color="#${($theme.AccentLight.TrimStart('#'))}" />
        <SolidColorBrush x:Key="HoverBrush" Color="#${($theme.Hover.TrimStart('#'))}" />
        <SolidColorBrush x:Key="SelectedBrush" Color="#${($theme.Selected.TrimStart('#'))}" />
        <SolidColorBrush x:Key="HeaderBrush" Color="#${($theme.Header.TrimStart('#'))}" />
        <SolidColorBrush x:Key="CardBrush" Color="#${($theme.Card.TrimStart('#'))}" />
        <SolidColorBrush x:Key="TextPrimaryBrush" Color="#${($theme.TextPrimary.TrimStart('#'))}" />
        <SolidColorBrush x:Key="TextSecondaryBrush" Color="#${($theme.TextSecondary.TrimStart('#'))}" />
        <SolidColorBrush x:Key="SuccessBrush" Color="#${($theme.Success.TrimStart('#'))}" />
        <SolidColorBrush x:Key="WarningBrush" Color="#${($theme.Warning.TrimStart('#'))}" />

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

# Parse XAML into a WPF window instance.
[xml]$xamlXml = $xaml
$reader = New-Object System.Xml.XmlNodeReader $xamlXml
$window = [Windows.Markup.XamlReader]::Load($reader)

# Convenience accessor for theme brushes defined in the resource dictionary.
function Get-Brush {
    param([string]$Key)
    return [System.Windows.Media.Brush]$window.Resources[$Key]
}

$navButtons = @(
    $window.FindName('NavDashboard'),
    $window.FindName('NavQuick'),
    $window.FindName('NavAdvanced'),
    $window.FindName('NavGames'),
    $window.FindName('NavOptions'),
    $window.FindName('NavBackup'),
    $window.FindName('NavLog')
) | Where-Object { $_ -ne $null }

$panels = @{
    Dashboard = $window.FindName('DashboardPanel')
    Quick      = $window.FindName('QuickPanel')
    Advanced   = $window.FindName('AdvancedPanel')
    Games      = $window.FindName('GamesPanel')
    Options    = $window.FindName('OptionsPanel')
    Backup     = $window.FindName('BackupPanel')
    Log        = $window.FindName('LogPanel')
}

$headerTitle    = $window.FindName('HeaderTitle')
$headerSubtitle = $window.FindName('HeaderSubtitle')
$adminStatus    = $window.FindName('AdminStatus')
$logBox         = $window.FindName('LogTextBox')

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

    if ($logBox) {
        $window.Dispatcher.Invoke([action]{
            $logBox.AppendText($entry + [Environment]::NewLine)
            $logBox.ScrollToEnd()
        })
    }
    else {
        Write-Host $entry
    }
}

function Select-NavigationButton {
    param([string]$PanelKey)

    $selectedBrush = Get-Brush 'SelectedBrush'
    $accentBrush   = Get-Brush 'AccentBrush'
    $textPrimary   = Get-Brush 'TextPrimaryBrush'
    $textSecondary = Get-Brush 'TextSecondaryBrush'

    foreach ($button in $navButtons) {
        if (-not $button) { continue }
        if ($button.Tag -eq $PanelKey) {
            $button.Background = $selectedBrush
            $button.Foreground = $textPrimary
        }
        else {
            $button.Background = [System.Windows.Media.Brush]::Transparent
            $button.Foreground = $textSecondary
        }
    }
}

function Show-Panel {
    param([string]$PanelKey)

    if (-not $panels.ContainsKey($PanelKey)) {
        Write-AppLog "Panel '$PanelKey' not found." 'Warning'
        return
    }

    foreach ($panel in $panels.GetEnumerator()) {
        if ($panel.Value) {
            $panel.Value.Visibility = if ($panel.Key -eq $PanelKey) { 'Visible' } else { 'Collapsed' }
        }
    }

    Select-NavigationButton -PanelKey $PanelKey

    if ($panelMetadata.ContainsKey($PanelKey)) {
        $headerTitle.Text = $panelMetadata[$PanelKey].Title
        $headerSubtitle.Text = $panelMetadata[$PanelKey].Subtitle
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

        if (Invoke-IfAvailable 'Apply-GameOptimizations' "Optimize $($game.DisplayName)" @{ GameKey = $game.GameKey; Process = $process }) {
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
            $updater = Join-Path -Path (Split-Path $PSCommandPath) -ChildPath 'merger-update.ps1'
            if (Test-Path $updater) {
                Start-Process -FilePath "powershell" -ArgumentList "-NoProfile","-ExecutionPolicy","Bypass","-File","$updater" | Out-Null
                Write-AppLog "Updater launched." 'Info'
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
            $window.Resources['AppBackground'].Color   = [System.Windows.Media.ColorConverter]::ConvertFromString($theme.Background)
            $window.Resources['HeaderBrush'].Color      = [System.Windows.Media.ColorConverter]::ConvertFromString($theme.Header)
            $window.Resources['SidebarBackground'].Color = [System.Windows.Media.ColorConverter]::ConvertFromString($theme.Sidebar)
            $window.Resources['CardBrush'].Color        = [System.Windows.Media.ColorConverter]::ConvertFromString($theme.Card)
            $window.Resources['AccentBrush'].Color      = [System.Windows.Media.ColorConverter]::ConvertFromString($theme.Accent)
            $window.Resources['HoverBrush'].Color       = [System.Windows.Media.ColorConverter]::ConvertFromString($theme.Hover)
            Write-AppLog "Dark theme colors restored." 'Info'
        }
    }
    OptionsVividThemeButton = {
        Invoke-PanelAction 'Apply vivid theme' {
            $window.Resources['AccentBrush'].Color = [System.Windows.Media.ColorConverter]::ConvertFromString('#FF6BFF')
            $window.Resources['HoverBrush'].Color  = [System.Windows.Media.ColorConverter]::ConvertFromString('#6B3FA0')
            Write-AppLog "Vivid theme applied." 'Info'
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

foreach ($entry in $actionMap.GetEnumerator()) {
    $control = $window.FindName($entry.Key)
    if ($control -and $control -is [System.Windows.Controls.Button]) {
        $control.Add_Click($entry.Value)
    }
}

foreach ($button in $navButtons) {
    if (-not $button) { continue }
    $panelKey = [string]$button.Tag
    $button.Add_Click({ param($sender,$args) Show-Panel -PanelKey $panelKey })
}

Update-AdminStatus
Show-Panel -PanelKey 'Dashboard'

function Initialize-Application {
    param()

    $application = [System.Windows.Application]::Current
    if (-not $application) {
        $application = [System.Windows.Application]::new()
        $application.ShutdownMode = [System.Windows.ShutdownMode]::OnMainWindowClose
    }

    $application.MainWindow = $window
    $application.Run($window) | Out-Null
}

if ($MyInvocation.InvocationName -ne '.') {
    if ($PSCommandPath -eq $MyInvocation.MyCommand.Path) {
        Initialize-Application
    }
}
