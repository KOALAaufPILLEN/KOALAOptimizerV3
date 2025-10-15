# ---------- KOALA Optimizer - Gaming Module ----------
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$global:ActiveGameProcesses = @()
$global:ActiveGames = @()
$global:GameDetectionTimer = $null
$global:AutoOptimizeEnabled = $false
$script:DetectedGpuVendor = $null

function Get-DetectedGpuVendor {
    if (-not $script:DetectedGpuVendor) {
        try {
            $script:DetectedGpuVendor = Get-GPUVendor
        }
        catch {
            $script:DetectedGpuVendor = 'Other'
        }
    }

    return $script:DetectedGpuVendor
}

function Test-GpuVendorSupport {
    param(
        [string[]]$SupportedVendors
    )

    $vendor = Get-DetectedGpuVendor
    return $SupportedVendors -contains $vendor
}

function Invoke-LoggedAction {
    param(
        [Parameter(Mandatory)]
        [string]$SuccessMessage,

        [Parameter(Mandatory)]
        [scriptblock]$Action,

        [string]$FailureMessage,
        [ValidateSet('Info','Warning','Error')]
        [string]$FailureLevel = 'Warning'
    )

    try {
        & $Action
        if ($SuccessMessage) {
            Log $SuccessMessage 'Success'
        }
        return $true
    }
    catch {
        if (-not $FailureMessage) {
            $FailureMessage = $SuccessMessage
        }

        if (-not $FailureMessage) {
            $FailureMessage = 'Operation failed'
        }

        Log "${FailureMessage}: $($_.Exception.Message)" $FailureLevel
        return $false
    }
}

function Get-RunningGameProcesses {
    try {
        $runningGames = @()
        $allProcesses = Get-Process -ErrorAction SilentlyContinue

        foreach ($entry in $GameProfiles.GetEnumerator()) {
            foreach ($processName in $entry.Value.ProcessNames) {
                $cleanName = $processName -replace '\.exe$',''
                $found = $allProcesses | Where-Object { $_.ProcessName -like "*$cleanName*" }
                if ($found) {
                    $runningGames += [PSCustomObject]@{
                        Key     = $entry.Key
                        Profile = $entry.Value
                        Process = $found | Select-Object -First 1
                    }
                    break
                }
            }
        }

        return $runningGames
    }
    catch {
        Log "Error detecting running games: $($_.Exception.Message)" 'Warning'
        return @()
    }
}

function Update-ActiveGamesTracking {
    try {
        $currentGames = Get-RunningGameProcesses
        $previousGames = $global:ActiveGameProcesses

        $newGames = $currentGames | Where-Object {
            $game = $_
            -not ($previousGames | Where-Object { $_.Process.Id -eq $game.Process.Id })
        }

        $stoppedGames = $previousGames | Where-Object {
            $game = $_
            -not ($currentGames | Where-Object { $_.Process.Id -eq $game.Process.Id })
        }

        $global:ActiveGameProcesses = $currentGames
        $global:ActiveGames = $currentGames | ForEach-Object { $_.Profile.DisplayName }

        foreach ($game in $newGames) {
            Log "Game started: $($game.Profile.DisplayName)" 'Success'
            if ($global:AutoOptimizeEnabled -and $game.Key -ne 'unknown') {
                Start-AutoGameOptimization -GameProfile $game | Out-Null
            }
        }

        foreach ($game in $stoppedGames) {
            Log "Game stopped: $($game.Profile.DisplayName)" 'Info'
        }
    }
    catch {
        Log "Error updating active games: $($_.Exception.Message)" 'Warning'
    }
}

function Start-AutoGameOptimization {
    param(
        [Parameter(Mandatory)]
        $GameProfile
    )

    if (-not $GameProfile) {
        return
    }

    try {
        $profile = $GameProfile.Profile
        if (-not $profile) { return }

        if (-not $GameProfile.Process -or $GameProfile.Process.HasExited) {
            Log 'Skipped auto-optimization because the target game process is no longer running.' 'Warning'
            return
        }

        Log "Auto-optimizing detected game: $($profile.DisplayName)" 'Info'

        if ($GameProfile.Process -and $profile.Priority -and $profile.Priority -ne 'Normal') {
            Invoke-LoggedAction -SuccessMessage "Set process priority to $($profile.Priority)" -FailureMessage "Failed to set process priority" -Action {
                $GameProfile.Process.PriorityClass = $profile.Priority
            } | Out-Null
        }

        if ($GameProfile.Process -and $profile.Affinity -eq 'Auto') {
            Invoke-LoggedAction -SuccessMessage 'Adjusted CPU affinity for gaming' -FailureMessage 'Failed to adjust CPU affinity' -Action {
                $coreCount = (Get-CimInstance Win32_Processor).NumberOfLogicalProcessors
                if ($coreCount -gt 4) {
                    $GameProfile.Process.ProcessorAffinity = [IntPtr]::new(15)
                }
            } | Out-Null
        }

        if ($profile.SpecificTweaks) {
            Apply-GameSpecificTweaks -GameKey $GameProfile.Key -TweakList $profile.SpecificTweaks
        }

        if ($profile.FPSBoostSettings) {
            Apply-FPSOptimizations -OptimizationList $profile.FPSBoostSettings
        }

        Log "Auto-optimization completed for $($profile.DisplayName)" 'Success'
    }
    catch {
        Log "Error applying game optimizations: $($_.Exception.Message)" 'Warning'
    }
}

function Get-CloudGamingServices {
    try {
        $cloudServices = @()

        $gamePassPaths = @(
            "$env:LOCALAPPDATA\Packages\Microsoft.GamingApp_*",
            "$env:ProgramFiles\Xbox Games",
            "$env:ProgramFiles\WindowsApps\Microsoft.GamingApp_*"
        )

        foreach ($path in $gamePassPaths) {
            $found = Get-ChildItem -Path $path -ErrorAction SilentlyContinue
            if ($found) {
                $cloudServices += [PSCustomObject]@{
                    Name    = 'Xbox Game Pass'
                    Path    = $found[0].FullName
                    Details = 'Cloud gaming platform from Microsoft'
                    Type    = 'CloudGaming'
                }
                break
            }
        }

        $geforcePath = "$env:LOCALAPPDATA\NVIDIA Corporation\GeForceNOW"
        if (Test-Path $geforcePath) {
            $cloudServices += [PSCustomObject]@{
                Name    = 'NVIDIA GeForce NOW'
                Path    = $geforcePath
                Details = 'Cloud gaming platform from NVIDIA'
                Type    = 'CloudGaming'
            }
        }

        $lunaPath = "$env:LOCALAPPDATA\Amazon Games\Luna"
        if (Test-Path $lunaPath) {
            $cloudServices += [PSCustomObject]@{
                Name    = 'Amazon Luna'
                Path    = $lunaPath
                Details = 'Cloud gaming platform from Amazon'
                Type    = 'CloudGaming'
            }
        }

        return $cloudServices
    }
    catch {
        Log "Error detecting cloud gaming services: $($_.Exception.Message)" 'Warning'
        return @()
    }
}

function Start-GameDetectionMonitoring {
    try {
        if ($global:GameDetectionTimer) {
            $global:GameDetectionTimer.Stop()
        }

        $global:GameDetectionTimer = New-Object System.Windows.Threading.DispatcherTimer
        $global:GameDetectionTimer.Interval = [TimeSpan]::FromSeconds(5)
        $global:GameDetectionTimer.Add_Tick({ Update-ActiveGamesTracking })
        $global:GameDetectionTimer.Start()
        Update-ActiveGamesTracking
        Log 'Game detection monitoring started' 'Success'
    }
    catch {
        Log "Error starting game detection monitoring: $($_.Exception.Message)" 'Error'
    }
}

function Stop-GameDetectionMonitoring {
    try {
        if ($global:GameDetectionTimer) {
            $global:GameDetectionTimer.Stop()
            $global:GameDetectionTimer = $null
            Log 'Game detection monitoring stopped' 'Info'
        }

        $global:ActiveGameProcesses = @()
        $global:ActiveGames = @()
    }
    catch {
        Write-Verbose "Error stopping game detection monitoring: $($_.Exception.Message)"
    }
}
$GameProfiles = @{
    # Competitive Shooters
    'cs2' = @{
        DisplayName = 'Counter-Strike 2'
        ProcessNames = @('cs2', 'cs2.exe')
        Priority = 'High'
        Affinity = 'Auto'
        SpecificTweaks = @('DisableNagle', 'HighPrecisionTimer', 'NetworkOptimization', 'CPUCoreParkDisable')
        FPSBoostSettings = @('DirectXOptimization', 'ShaderCacheOptimization', 'InputLatencyReduction')
    }
    'csgo' = @{
        DisplayName = 'Counter-Strike: Global Offensive'
        ProcessNames = @('csgo', 'csgo.exe')
        Priority = 'High'
        Affinity = 'Auto'
        SpecificTweaks = @('DisableNagle', 'HighPrecisionTimer', 'SourceEngineOptimization')
        FPSBoostSettings = @('DirectXOptimization', 'InputLatencyReduction')
    }
    'valorant' = @{
        DisplayName = 'Valorant'
        ProcessNames = @('valorant', 'valorant-win64-shipping', 'RiotClientServices')
        Priority = 'High'
        Affinity = 'Auto'
        SpecificTweaks = @('DisableNagle', 'AntiCheatOptimization', 'MemoryOptimization')
        FPSBoostSettings = @('DirectXOptimization', 'GPUSchedulingOptimization', 'AudioLatencyOptimization')
    }
    'overwatch2' = @{
        DisplayName = 'Overwatch 2'
        ProcessNames = @('overwatch', 'overwatch.exe')
        Priority = 'High'
        Affinity = 'Auto'
        SpecificTweaks = @('DisableNagle', 'NetworkOptimization', 'BlizzardOptimization')
        FPSBoostSettings = @('DirectXOptimization', 'InputLatencyReduction', 'ShaderCacheOptimization')
    }
    'r6siege' = @{
        DisplayName = 'Rainbow Six Siege'
        ProcessNames = @('rainbowsix', 'rainbowsix_vulkan', 'RainbowSix.exe')
        Priority = 'High'
        Affinity = 'Auto'
        SpecificTweaks = @('DisableNagle', 'UbisoftOptimization', 'NetworkOptimization')
        FPSBoostSettings = @('VulkanOptimization', 'InputLatencyReduction', 'GPUSchedulingOptimization')
    }

    # Battle Royale Games
    'fortnite' = @{
        DisplayName = 'Fortnite'
        ProcessNames = @('fortniteclient-win64-shipping', 'FortniteClient-Win64-Shipping.exe')
        Priority = 'High'
        Affinity = 'Auto'
        SpecificTweaks = @('UnrealEngineOptimization', 'MemoryOptimization', 'NetworkOptimization')
        FPSBoostSettings = @('DirectXOptimization', 'ShaderCacheOptimization', 'TextureStreamingOptimization')
    }
    'apexlegends' = @{
        DisplayName = 'Apex Legends'
        ProcessNames = @('r5apex', 'r5apex.exe')
        Priority = 'High'
        Affinity = 'Auto'
        SpecificTweaks = @('DisableNagle', 'SourceEngineOptimization', 'EACOptimization')
        FPSBoostSettings = @('DirectXOptimization', 'GPUSchedulingOptimization', 'AudioLatencyOptimization')
    }
    'pubg' = @{
        DisplayName = 'PUBG: Battlegrounds'
        ProcessNames = @('tslgame', 'TslGame.exe')
        Priority = 'High'
        Affinity = 'Auto'
        SpecificTweaks = @('UnrealEngineOptimization', 'NetworkOptimization', 'MemoryOptimization')
        FPSBoostSettings = @('DirectXOptimization', 'TextureStreamingOptimization', 'ShaderCacheOptimization')
    }
    'warzone' = @{
        DisplayName = 'Call of Duty: Warzone'
        ProcessNames = @('cod', 'modernwarfare', 'cod.exe')
        Priority = 'High'
        Affinity = 'Auto'
        SpecificTweaks = @('CODOptimization', 'NetworkOptimization', 'MemoryOptimization')
        FPSBoostSettings = @('DirectXOptimization', 'MemoryPoolOptimization', 'ShaderCacheOptimization')
    }

    # Popular Multiplayer Games
    'lol' = @{
        DisplayName = 'League of Legends'
        ProcessNames = @('leagueclient', 'league of legends', 'LeagueClient.exe')
        Priority = 'High'
        Affinity = 'Auto'
        SpecificTweaks = @('RiotClientOptimization', 'NetworkOptimization')
        FPSBoostSettings = @('DirectXOptimization', 'InputLatencyReduction')
    }
    'rocketleague' = @{
        DisplayName = 'Rocket League'
        ProcessNames = @('rocketleague', 'RocketLeague.exe')
        Priority = 'High'
        Affinity = 'Auto'
        SpecificTweaks = @('UnrealEngineOptimization', 'NetworkOptimization')
        FPSBoostSettings = @('DirectXOptimization', 'InputLatencyReduction', 'PhysicsOptimization')
    }
    'dota2' = @{
        DisplayName = 'Dota 2'
        ProcessNames = @('dota2', 'dota2.exe')
        Priority = 'High'
        Affinity = 'Auto'
        SpecificTweaks = @('SourceEngineOptimization', 'NetworkOptimization')
        FPSBoostSettings = @('DirectXOptimization', 'VulkanOptimization', 'ShaderCacheOptimization')
    }
    'gta5' = @{
        DisplayName = 'Grand Theft Auto V'
        ProcessNames = @('gta5', 'gtavlauncher', 'GTA5.exe')
        Priority = 'High'
        Affinity = 'Auto'
        SpecificTweaks = @('RockstarOptimization', 'MemoryOptimization')
        FPSBoostSettings = @('DirectXOptimization', 'TextureStreamingOptimization', 'MemoryPoolOptimization')
    }

    # AAA Titles
    'hogwartslegacy' = @{
        DisplayName = 'Hogwarts Legacy'
        ProcessNames = @('hogwartslegacy', 'HogwartsLegacy.exe')
        Priority = 'High'
        Affinity = 'Auto'
        SpecificTweaks = @('UnrealEngineOptimization', 'MemoryOptimization')
        FPSBoostSettings = @('DirectX12Optimization', 'TextureStreamingOptimization', 'ShaderCacheOptimization')
    }
    'starfield' = @{
        DisplayName = 'Starfield'
        ProcessNames = @('starfield', 'Starfield.exe')
        Priority = 'High'
        Affinity = 'Auto'
        SpecificTweaks = @('CreationEngineOptimization', 'MemoryOptimization')
        FPSBoostSettings = @('DirectX12Optimization', 'TextureStreamingOptimization', 'MemoryPoolOptimization')
    }
    'baldursgate3' = @{
        DisplayName = "Baldur's Gate 3"
        ProcessNames = @('bg3', 'bg3_dx11', 'bg3.exe')
        Priority = 'High'
        Affinity = 'Auto'
        SpecificTweaks = @('LarianOptimization', 'MemoryOptimization')
        FPSBoostSettings = @('DirectXOptimization', 'VulkanOptimization', 'ShaderCacheOptimization')
    }
    'cyberpunk2077' = @{
        DisplayName = 'Cyberpunk 2077'
        ProcessNames = @('cyberpunk2077', 'Cyberpunk2077.exe')
        Priority = 'High'
        Affinity = 'Auto'
        SpecificTweaks = @('REDEngineOptimization', 'MemoryOptimization', 'RTXOptimization')
        FPSBoostSettings = @('DirectX12Optimization', 'DLSSOptimization', 'TextureStreamingOptimization')
    }

    # Survival & Crafting
    'minecraft' = @{
        DisplayName = 'Minecraft'
        ProcessNames = @('minecraft', 'javaw', 'javaw.exe')
        Priority = 'High'
        Affinity = 'Auto'
        SpecificTweaks = @('JavaOptimization', 'MemoryOptimization')
        FPSBoostSettings = @('OpenGLOptimization', 'ChunkRenderingOptimization')
    }
    'rust' = @{
        DisplayName = 'Rust'
        ProcessNames = @('rustclient', 'RustClient.exe')
        Priority = 'High'
        Affinity = 'Auto'
        SpecificTweaks = @('UnityEngineOptimization', 'NetworkOptimization', 'EACOptimization')
        FPSBoostSettings = @('DirectXOptimization', 'TextureStreamingOptimization', 'ShaderCacheOptimization')
    }
    'ark' = @{
        DisplayName = 'ARK: Survival Evolved'
        ProcessNames = @('shootergame', 'ShooterGame.exe')
        Priority = 'High'
        Affinity = 'Auto'
        SpecificTweaks = @('UnrealEngineOptimization', 'MemoryOptimization')
        FPSBoostSettings = @('DirectXOptimization', 'TextureStreamingOptimization', 'MemoryPoolOptimization')
    }
    'valheim' = @{
        DisplayName = 'Valheim'
        ProcessNames = @('valheim', 'valheim.exe')
        Priority = 'High'
        Affinity = 'Auto'
        SpecificTweaks = @('UnityEngineOptimization', 'MemoryOptimization')
        FPSBoostSettings = @('DirectXOptimization', 'ShaderCacheOptimization')
    }

    # Racing & Sports
    'f124' = @{
        DisplayName = 'F1 24'
        ProcessNames = @('f1_24', 'F1_24.exe')
        Priority = 'High'
        Affinity = 'Auto'
        SpecificTweaks = @('EGOEngineOptimization', 'InputLatencyOptimization')
        FPSBoostSettings = @('DirectX12Optimization', 'PhysicsOptimization', 'AudioLatencyOptimization')
    }
    'fifa24' = @{
        DisplayName = 'EA Sports FC 24'
        ProcessNames = @('fc24', 'FC24.exe')
        Priority = 'High'
        Affinity = 'Auto'
        SpecificTweaks = @('FrostbiteEngineOptimization', 'NetworkOptimization')
        FPSBoostSettings = @('DirectXOptimization', 'PhysicsOptimization', 'InputLatencyReduction')
    }
    'forzahorizon5' = @{
        DisplayName = 'Forza Horizon 5'
        ProcessNames = @('forzahorizon5', 'ForzaHorizon5.exe')
        Priority = 'High'
        Affinity = 'Auto'
        SpecificTweaks = @('ForzaTechOptimization', 'MemoryOptimization')
        FPSBoostSettings = @('DirectX12Optimization', 'TextureStreamingOptimization')
    }

    # Fighting Games
    'tekken8' = @{
        DisplayName = 'Tekken 8'
        ProcessNames = @('tekken8', 'Tekken8.exe')
        Priority = 'High'
        Affinity = 'Auto'
        SpecificTweaks = @('UnrealEngineOptimization', 'InputLatencyOptimization')
        FPSBoostSettings = @('DirectXOptimization', 'InputLatencyReduction', 'FramePacingOptimization')
    }
    'sf6' = @{
        DisplayName = 'Street Fighter 6'
        ProcessNames = @('streetfighter6', 'StreetFighter6.exe')
        Priority = 'High'
        Affinity = 'Auto'
        SpecificTweaks = @('REEngineOptimization', 'InputLatencyOptimization')
        FPSBoostSettings = @('DirectXOptimization', 'InputLatencyReduction', 'FramePacingOptimization')
    }
    'mortalkombat1' = @{
        DisplayName = 'Mortal Kombat 1'
        ProcessNames = @('mk1', 'MK1.exe')
        Priority = 'High'
        Affinity = 'Auto'
        SpecificTweaks = @('UnrealEngineOptimization', 'InputLatencyOptimization')
        FPSBoostSettings = @('DirectXOptimization', 'InputLatencyReduction')
    }

    # MMOs
    'wow' = @{
        DisplayName = 'World of Warcraft'
        ProcessNames = @('wow', 'wow-64', 'Wow.exe')
        Priority = 'High'
        Affinity = 'Auto'
        SpecificTweaks = @('BlizzardOptimization', 'NetworkOptimization')
        FPSBoostSettings = @('DirectXOptimization', 'ShaderCacheOptimization', 'AddonOptimization')
    }
    'ffxiv' = @{
        DisplayName = 'Final Fantasy XIV'
        ProcessNames = @('ffxiv_dx11', 'ffxiv', 'ffxiv_dx11.exe')
        Priority = 'High'
        Affinity = 'Auto'
        SpecificTweaks = @('SquareEnixOptimization', 'NetworkOptimization')
        FPSBoostSettings = @('DirectXOptimization', 'ShaderCacheOptimization', 'NetworkLatencyOptimization')
    }
    'guildwars2' = @{
        DisplayName = 'Guild Wars 2'
        ProcessNames = @('gw2-64', 'Gw2-64.exe')
        Priority = 'High'
        Affinity = 'Auto'
        SpecificTweaks = @('ArenaNetOptimization', 'NetworkOptimization')
        FPSBoostSettings = @('DirectXOptimization', 'CPUOptimization', 'ShaderCacheOptimization')
    }
    'elderscrollsonline' = @{
        DisplayName = 'Elder Scrolls Online'
        ProcessNames = @('eso64', 'eso64.exe')
        Priority = 'High'
        Affinity = 'Auto'
        SpecificTweaks = @('ZeniMaxOptimization', 'NetworkOptimization')
        FPSBoostSettings = @('DirectXOptimization', 'MemoryOptimization')
    }
    'newworld' = @{
        DisplayName = 'New World'
        ProcessNames = @('newworld', 'NewWorld.exe')
        Priority = 'High'
        Affinity = 'Auto'
        SpecificTweaks = @('LumberyardOptimization', 'NetworkOptimization')
        FPSBoostSettings = @('DirectXOptimization', 'GPUSchedulingOptimization')
    }

    # Indie Popular
    'hades2' = @{
        DisplayName = 'Hades II'
        ProcessNames = @('hades2', 'Hades2.exe')
        Priority = 'High'
        Affinity = 'Auto'
        SpecificTweaks = @('UnityEngineOptimization')
        FPSBoostSettings = @('DirectXOptimization', 'ShaderCacheOptimization')
    }
    'palworld' = @{
        DisplayName = 'Palworld'
        ProcessNames = @('palworld', 'Palworld.exe')
        Priority = 'High'
        Affinity = 'Auto'
        SpecificTweaks = @('UnrealEngineOptimization', 'MemoryOptimization')
        FPSBoostSettings = @('DirectXOptimization', 'TextureStreamingOptimization', 'ShaderCacheOptimization')
    }
    'stardewvalley' = @{
        DisplayName = 'Stardew Valley'
        ProcessNames = @('stardewvalley', 'StardewValley.exe')
        Priority = 'AboveNormal'
        Affinity = 'Auto'
        SpecificTweaks = @('MonoGameOptimization')
        FPSBoostSettings = @('DirectXOptimization')
    }

    # Simulation
    'msfs2020' = @{
        DisplayName = 'Microsoft Flight Simulator'
        ProcessNames = @('flightsimulator', 'FlightSimulator.exe')
        Priority = 'High'
        Affinity = 'Auto'
        SpecificTweaks = @('AsoboOptimization', 'MemoryOptimization')
        FPSBoostSettings = @('DirectX12Optimization', 'TextureStreamingOptimization', 'CPUOptimization')
    }
    'cityskylines2' = @{
        DisplayName = 'Cities: Skylines II'
        ProcessNames = @('cities2', 'Cities2.exe')
        Priority = 'High'
        Affinity = 'Auto'
        SpecificTweaks = @('UnityEngineOptimization', 'MemoryOptimization')
        FPSBoostSettings = @('DirectXOptimization', 'CPUOptimization')
    }

    # Horror
    'phasmophobia' = @{
        DisplayName = 'Phasmophobia'
        ProcessNames = @('phasmophobia', 'Phasmophobia.exe')
        Priority = 'High'
        Affinity = 'Auto'
        SpecificTweaks = @('UnityEngineOptimization')
        FPSBoostSettings = @('DirectXOptimization', 'AudioLatencyOptimization')
    }
    'deadbydaylight' = @{
        DisplayName = 'Dead by Daylight'
        ProcessNames = @('deadbydaylight', 'DeadByDaylight.exe')
        Priority = 'High'
        Affinity = 'Auto'
        SpecificTweaks = @('UnrealEngineOptimization', 'EACOptimization')
        FPSBoostSettings = @('DirectXOptimization', 'ShaderCacheOptimization')
    }
}

# ---------- Game Detection and Auto-Optimization ----------

function Get-RunningGames {
    $processes = Get-RunningGameProcesses
    return $processes | ForEach-Object {
        [PSCustomObject]@{
            GameKey     = $_.Key
            DisplayName = $_.Profile.DisplayName
            Process     = $_.Process
        }
    }
}

function Start-GameDetectionLoop {
    param(
        [int]$IntervalSeconds = 5
    )

    $timer = New-Object System.Windows.Threading.DispatcherTimer
    $timer.Interval = [TimeSpan]::FromSeconds([Math]::Max(1, $IntervalSeconds))
    $timer.Add_Tick({
        $games = Get-RunningGames
        $global:ActiveGames = $games

        if ($lblActiveGames) {
            $lblActiveGames.Dispatcher.Invoke({
                if ($games.Count -gt 0) {
                    $lblActiveGames.Text = ($games.DisplayName -join ', ')
                }
                else {
                    $lblActiveGames.Text = 'None'
                }

                if ($lblLastRefresh) {
                    $lblLastRefresh.Text = Get-Date -Format 'HH:mm:ss'
                }
            })
        }

        if ($global:AutoOptimizeEnabled -and $games.Count -gt 0) {
            foreach ($game in $games) {
                Apply-GameOptimizations -GameKey $game.GameKey -Process $game.Process
            }
        }
    })

    $timer.Start()
    return $timer
}

function Apply-GameOptimizations {
    param(
        [string]$GameKey,
        [System.Diagnostics.Process]$Process
    )

    try {
        if (-not $GameProfiles.ContainsKey($GameKey)) {
            return
        }

        $profile = $GameProfiles[$GameKey]
        Log "Applying optimizations for $($profile.DisplayName)" 'Info'

        if ($Process -and $Process.HasExited) {
            Log "Process for $($profile.DisplayName) is no longer running. Skipping process-specific tweaks." 'Warning'
            $Process = $null
        }
        elseif (-not $Process) {
            Log "No active process handle supplied for $($profile.DisplayName). Applying profile-level tweaks only." 'Info'
        }

        if ($Process -and $profile.Priority -and $profile.Priority -ne 'Normal') {
            Invoke-LoggedAction -SuccessMessage "Set process priority to $($profile.Priority)" -FailureMessage "Failed to set process priority" -Action {
                $Process.PriorityClass = $profile.Priority
            } | Out-Null
        }

        if ($Process -and $profile.Affinity -eq 'Auto') {
            Invoke-LoggedAction -SuccessMessage 'Adjusted CPU affinity for gaming' -FailureMessage 'Failed to adjust CPU affinity' -Action {
                $coreCount = (Get-CimInstance Win32_Processor).NumberOfLogicalProcessors
                if ($coreCount -gt 4) {
                    $Process.ProcessorAffinity = [IntPtr]::new(15)
                }
            } | Out-Null
        }

        if ($profile.SpecificTweaks) {
            Apply-GameSpecificTweaks -GameKey $GameKey -TweakList $profile.SpecificTweaks
        }

        if ($profile.FPSBoostSettings) {
            Apply-FPSOptimizations -OptimizationList $profile.FPSBoostSettings
        }

        Log "Finished applying optimizations for $($profile.DisplayName)" 'Success'
    }
    catch {
        Log "Error applying optimizations for ${GameKey}: $($_.Exception.Message)" 'Warning'
    }
}

function Disable-GameDVR {
    $operations = @(
        { Set-Reg "HKCU:\System\GameConfigStore" "GameDVR_Enabled" 'DWord' 0 },
        { Set-Reg "HKCU:\System\GameConfigStore" "GameDVR_FSEBehaviorMode" 'DWord' 2 },
        { Set-Reg "HKCU:\System\GameConfigStore" "GameDVR_FSEBehavior" 'DWord' 2 },
        { Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" "AppCaptureEnabled" 'DWord' 0 },
        { Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" "GameDVR_Enabled" 'DWord' 0 },
        { Set-Reg "HKCU:\SOFTWARE\Microsoft\GameBar" "AllowAutoGameMode" 'DWord' 0 },
        { Set-Reg "HKCU:\SOFTWARE\Microsoft\GameBar" "AutoGameModeEnabled" 'DWord' 0 },
        { Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" "AllowGameDVR" 'DWord' 0 -RequiresAdmin $true },
        { Set-Reg "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\ApplicationManagement\AllowGameDVR" "value" 'DWord' 0 -RequiresAdmin $true }
    )

    $result = $true
    foreach ($operation in $operations) {
        if (-not (Invoke-LoggedAction -SuccessMessage $null -FailureMessage 'Game DVR tweak failed' -Action $operation)) {
            $result = $false
        }
    }

    Invoke-LoggedAction -SuccessMessage 'Disabled Game Bar presence writer service' -FailureMessage 'Failed to disable Game Bar presence writer service' -Action {
        $svc = Get-Service -Name 'GameBarPresenceWriter' -ErrorAction Stop
        if ($svc.Status -ne 'Stopped') {
            Stop-Service -Name 'GameBarPresenceWriter' -Force -ErrorAction Stop
        }
        Set-Service -Name 'GameBarPresenceWriter' -StartupType Disabled -ErrorAction Stop
    } | Out-Null

    if ($result) {
        Log 'Game DVR disabled globally' 'Success'
    }
    else {
        Log 'Game DVR settings applied with warnings' 'Warning'
    }

    return $result
}

function Enable-GPUScheduling {
    $gpuRegistryPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers'

    try {
        $osVersion = [Environment]::OSVersion.Version
        if ($osVersion.Major -lt 10 -or ($osVersion.Major -eq 10 -and $osVersion.Build -lt 19041)) {
            return $false
        }

        if (-not (Test-Path $gpuRegistryPath -ErrorAction SilentlyContinue)) {
            return $false
        }

        $vendor = Get-DetectedGpuVendor
        if ($vendor -eq 'Other') {
            Log 'Unable to detect GPU vendor. Skipping hardware scheduling tweak.' 'Warning'
            return $false
        }

        $result = Invoke-LoggedAction -SuccessMessage "Hardware GPU scheduling enabled for $vendor" -FailureMessage 'Failed to enable hardware GPU scheduling' -Action {
            Set-Reg $gpuRegistryPath 'HwSchMode' 'DWord' 2 -RequiresAdmin $true | Out-Null
            Set-Reg "$gpuRegistryPath\Scheduler" 'EnablePreemption' 'DWord' 1 -RequiresAdmin $true | Out-Null
            Set-Reg $gpuRegistryPath 'PlatformSupportMiracast' 'DWord' 0 -RequiresAdmin $true | Out-Null
        }

        return $result
    }
    catch {
        Log "Failed to enable hardware GPU scheduling: $($_.Exception.Message)" 'Warning'
        return $false
    }
}

# ---------- FPS Optimization Functions ----------
$script:fpsOptimizationHandlers = @{
    DirectXOptimization           = {
        Invoke-LoggedAction -SuccessMessage 'DirectX optimizations applied' -FailureMessage 'Failed to apply DirectX optimizations' -Action {
            Set-Reg "HKLM:\SOFTWARE\Microsoft\Direct3D" "DisableVidMemVirtualization" 'DWord' 1 -RequiresAdmin $true | Out-Null
            Set-Reg "HKLM:\SOFTWARE\Microsoft\DirectX" "D3D12_ENABLE_UNSAFE_COMMAND_BUFFER_REUSE" 'DWord' 1 -RequiresAdmin $true | Out-Null
            Set-Reg "HKLM:\SOFTWARE\Microsoft\DirectX" "D3D12_ENABLE_RUNTIME_DRIVER_OPTIMIZATIONS" 'DWord' 1 -RequiresAdmin $true | Out-Null
        } | Out-Null
    }
    DirectX12Optimization         = {
        Invoke-LoggedAction -SuccessMessage 'DirectX 12 optimizations applied' -FailureMessage 'Failed to apply DirectX 12 optimizations' -Action {
            Set-Reg "HKLM:\SOFTWARE\Microsoft\DirectX" "D3D12_ENABLE_UNSAFE_COMMAND_BUFFER_REUSE" 'DWord' 1 -RequiresAdmin $true | Out-Null
            Set-Reg "HKLM:\SOFTWARE\Microsoft\DirectX" "D3D12_RESOURCE_ALIGNMENT" 'DWord' 1 -RequiresAdmin $true | Out-Null
            Set-Reg "HKLM:\SOFTWARE\Microsoft\DirectX" "D3D12_MULTITHREADED_COMMAND_QUEUE" 'DWord' 1 -RequiresAdmin $true | Out-Null
        } | Out-Null
    }
    ShaderCacheOptimization       = {
        Invoke-LoggedAction -SuccessMessage 'Shader cache optimization applied' -FailureMessage 'Failed to optimize shader cache' -Action {
            Set-Reg "HKCU:\SOFTWARE\Microsoft\Direct3D" "ShaderCache" 'DWord' 1 | Out-Null
            Set-Reg "HKCU:\SOFTWARE\Microsoft\Direct3D" "DisableShaderRecompilation" 'DWord' 1 | Out-Null
            Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "DisableShaderCache" 'DWord' 0 -RequiresAdmin $true | Out-Null
        } | Out-Null
    }
    InputLatencyReduction         = {
        Invoke-LoggedAction -SuccessMessage 'Input latency reduction applied' -FailureMessage 'Failed to apply input latency reduction' -Action {
            Set-Reg "HKCU:\Control Panel\Mouse" "MouseSpeed" 'String' '0' | Out-Null
            Set-Reg "HKCU:\Control Panel\Mouse" "MouseThreshold1" 'String' '0' | Out-Null
            Set-Reg "HKCU:\Control Panel\Mouse" "MouseThreshold2" 'String' '0' | Out-Null
            Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Services\mouclass\Parameters" "MouseDataQueueSize" 'DWord' 100 -RequiresAdmin $true | Out-Null
            Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Services\kbdclass\Parameters" "KeyboardDataQueueSize" 'DWord' 100 -RequiresAdmin $true | Out-Null
        } | Out-Null
    }
    GPUSchedulingOptimization     = {
        if (Enable-GPUScheduling) {
            Log 'GPU scheduling optimization applied' 'Success'
        }
        else {
            Log 'GPU scheduling optimization skipped (requires admin rights or compatible hardware)' 'Warning'
        }
    }
    MemoryCompressionDisable      = {
        Invoke-LoggedAction -SuccessMessage 'Memory compression disabled' -FailureMessage 'Failed to disable memory compression' -Action {
            Disable-MMAgent -MemoryCompression -ErrorAction Stop
        } | Out-Null
    }
    CPUCoreParkDisable            = {
        Invoke-LoggedAction -SuccessMessage 'CPU core parking disabled' -FailureMessage 'Failed to disable CPU core parking' -Action {
            $path = "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318583"
            Set-Reg $path 'ValueMax' 'DWord' 0 -RequiresAdmin $true | Out-Null
            Set-Reg $path 'ValueMin' 'DWord' 0 -RequiresAdmin $true | Out-Null
        } | Out-Null
    }
    InterruptModerationOptimization = {
        Invoke-LoggedAction -SuccessMessage 'Interrupt moderation optimized' -FailureMessage 'Failed to optimize interrupt moderation' -Action {
            Get-NetAdapter | ForEach-Object {
                Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName 'Interrupt Moderation' -DisplayValue 'Disabled' -ErrorAction SilentlyContinue
                Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName 'Interrupt Moderation Rate' -DisplayValue 'Off' -ErrorAction SilentlyContinue
            }
        } | Out-Null
    }
    AudioLatencyOptimization      = {
        Invoke-LoggedAction -SuccessMessage 'Audio latency optimization applied' -FailureMessage 'Failed to optimize audio latency' -Action {
            Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Audio" "DisableProtectedAudioDG" 'DWord' 1 -RequiresAdmin $true | Out-Null
            Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Audio" "DisableProtectedAudio" 'DWord' 1 -RequiresAdmin $true | Out-Null
            Set-Reg "HKCU:\SOFTWARE\Microsoft\Multimedia\Audio" "UserDuckingPreference" 'DWord' 3 | Out-Null
        } | Out-Null
    }
    MemoryPoolOptimization        = {
        Invoke-LoggedAction -SuccessMessage 'Memory pool optimization applied' -FailureMessage 'Failed to optimize memory pool' -Action {
            $mmPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
            Set-Reg $mmPath 'PoolUsageMaximum' 'DWord' 96 -RequiresAdmin $true | Out-Null
            Set-Reg $mmPath 'PagedPoolSize' 'DWord' 0xFFFFFFFF -RequiresAdmin $true | Out-Null
            Set-Reg $mmPath 'NonPagedPoolSize' 'DWord' 0 -RequiresAdmin $true | Out-Null
        } | Out-Null
    }
    TextureStreamingOptimization  = {
        Invoke-LoggedAction -SuccessMessage 'Texture streaming optimization applied' -FailureMessage 'Failed to optimize texture streaming' -Action {
            Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" "VKPoolSize" 'DWord' 1073741824 | Out-Null
            $driversPath = "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"
            Set-Reg $driversPath 'TdrLevel' 'DWord' 0 -RequiresAdmin $true | Out-Null
            Set-Reg $driversPath 'TdrDelay' 'DWord' 10 -RequiresAdmin $true | Out-Null
        } | Out-Null
    }
    VulkanOptimization            = {
        Invoke-LoggedAction -SuccessMessage 'Vulkan optimization applied' -FailureMessage 'Failed to optimize Vulkan settings' -Action {
            Set-Reg "HKLM:\SOFTWARE\Khronos\Vulkan\ImplicitLayers" "VK_LAYER_VALVE_steam_overlay" 'DWord' 0 -RequiresAdmin $true | Out-Null
            Set-Reg "HKLM:\SOFTWARE\Khronos\Vulkan\Drivers" "VulkanAPIVersion" 'DWord' 1 -RequiresAdmin $true | Out-Null
        } | Out-Null
    }
    OpenGLOptimization            = {
        Invoke-LoggedAction -SuccessMessage 'OpenGL optimization applied' -FailureMessage 'Failed to optimize OpenGL settings' -Action {
            Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "DisableOpenGLShaderCache" 'DWord' 0 -RequiresAdmin $true | Out-Null
            Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\OpenGLDrivers" "EnableThreadedOptimizations" 'DWord' 1 -RequiresAdmin $true | Out-Null
        } | Out-Null
    }
    PhysicsOptimization           = {
        Invoke-LoggedAction -SuccessMessage 'Physics optimization applied' -FailureMessage 'Failed to optimize physics settings' -Action {
            Set-Reg "HKLM:\SOFTWARE\NVIDIA Corporation\PhysX" "AsyncSceneCreation" 'DWord' 1 -RequiresAdmin $true | Out-Null
            Set-Reg "HKLM:\SOFTWARE\NVIDIA Corporation\Global\FTS" "EnableRID66610" 'DWord' 0 -RequiresAdmin $true | Out-Null
        } | Out-Null
    }
    DLSSOptimization              = {
        Invoke-LoggedAction -SuccessMessage 'DLSS optimization enabled' -FailureMessage 'Failed to configure DLSS' -Action {
            Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Services\nvlddmkm" "DLSSEnable" 'DWord' 1 -RequiresAdmin $true | Out-Null
            Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Services\nvlddmkm\FTS" "EnableDLSS" 'DWord' 1 -RequiresAdmin $true | Out-Null
        } | Out-Null
    }
    RTXOptimization               = {
        Invoke-LoggedAction -SuccessMessage 'RTX optimizations applied' -FailureMessage 'Failed to apply RTX optimizations' -Action {
            Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Services\nvlddmkm" "RayTracingEnable" 'DWord' 1 -RequiresAdmin $true | Out-Null
            Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Services\nvlddmkm" "EnableResizableBar" 'DWord' 1 -RequiresAdmin $true | Out-Null
        } | Out-Null
    }
    FramePacingOptimization       = {
        Invoke-LoggedAction -SuccessMessage 'Frame pacing optimization applied' -FailureMessage 'Failed to optimize frame pacing' -Action {
            Set-Reg "HKLM:\SOFTWARE\Microsoft\Direct3D" "FramePacingMode" 'DWord' 2 -RequiresAdmin $true | Out-Null
        } | Out-Null
    }
    DynamicResolutionScaling      = {
        Invoke-LoggedAction -SuccessMessage 'Dynamic resolution scaling preferences updated' -FailureMessage 'Failed to update dynamic resolution scaling preferences' -Action {
            Set-Reg "HKCU:\SOFTWARE\Microsoft\GameBar" "AllowAutoGameMode" 'DWord' 1 | Out-Null
            Set-Reg "HKCU:\SOFTWARE\Microsoft\GameBar" "AutoGameModeEnabled" 'DWord' 1 | Out-Null
        } | Out-Null
    }
    EnhancedFramePacing           = {
        Invoke-LoggedAction -SuccessMessage 'Enhanced frame pacing applied' -FailureMessage 'Failed to apply enhanced frame pacing' -Action {
            Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "AdaptiveVSync" 'DWord' 1 -RequiresAdmin $true | Out-Null
        } | Out-Null
    }
    ProfileBasedGPUOverclocking   = {
        Log 'Profile-based GPU overclocking requires vendor utilities – skipped' 'Warning'
    }
    CompetitiveLatencyReduction   = {
        Invoke-LoggedAction -SuccessMessage 'Competitive latency optimizations applied' -FailureMessage 'Failed to adjust competitive latency settings' -Action {
            $processes = Get-Process -Name 'nvcontainer','rtss','msiafterburner' -ErrorAction SilentlyContinue
            foreach ($proc in $processes) {
                try { $proc.PriorityClass = 'High' } catch { }
            }
        } | Out-Null
    }
    ChunkRenderingOptimization    = {
        Invoke-LoggedAction -SuccessMessage 'Chunk rendering optimization applied' -FailureMessage 'Failed to optimize chunk rendering' -Action {
            Set-Reg "HKCU:\SOFTWARE\Mojang" "RenderDistance" 'DWord' 12 | Out-Null
            [Environment]::SetEnvironmentVariable("_JAVA_OPTIONS", "-Xmx4G -Xms2G -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200", 'User')
        } | Out-Null
    }
    NetworkLatencyOptimization    = {
        Invoke-LoggedAction -SuccessMessage 'Network latency optimization applied' -FailureMessage 'Failed to apply network latency optimization' -Action {
            & netsh int tcp set supplemental internet congestionprovider=ctcp | Out-Null
        } | Out-Null
    }
    CPUOptimization               = {
        Invoke-LoggedAction -SuccessMessage 'CPU optimization applied' -FailureMessage 'Failed to apply CPU optimization' -Action {
            $kernelPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel"
            Set-Reg $kernelPath 'ThreadDpcEnable' 'DWord' 1 -RequiresAdmin $true | Out-Null
            Set-Reg $kernelPath 'DpcWatchdogProfileOffset' 'DWord' 10000 -RequiresAdmin $true | Out-Null
        } | Out-Null
    }
}

function Apply-FPSOptimizations {
    param([string[]]$OptimizationList)

    if (-not $OptimizationList -or $OptimizationList.Count -eq 0) {
        return
    }

    Log 'Applying FPS optimizations...' 'Info'
    foreach ($optimization in $OptimizationList) {
        $handler = $script:fpsOptimizationHandlers[$optimization]
        if ($handler) {
            & $handler
        }
        else {
            Log "Unknown FPS optimization '$optimization'" 'Warning'
        }
    }
}

# ---------- DirectX 11 Optimization Functions ----------
$script:dx11OptimizationHandlers = @{
    DX11EnhancedGpuScheduling = {
        Invoke-LoggedAction -SuccessMessage 'Enhanced GPU scheduling for DX11 applied' -FailureMessage 'Failed to enhance DX11 GPU scheduling' -Action {
            $path = "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"
            Set-Reg $path 'HwSchMode' 'DWord' 2 -RequiresAdmin $true | Out-Null
            Set-Reg "$path\Scheduler" 'EnablePreemption' 'DWord' 1 -RequiresAdmin $true | Out-Null
            Set-Reg $path 'TdrLevel' 'DWord' 0 -RequiresAdmin $true | Out-Null
            Set-Reg $path 'TdrDelay' 'DWord' 60 -RequiresAdmin $true | Out-Null
        } | Out-Null
    }
    DX11GameProcessPriority = {
        Invoke-LoggedAction -SuccessMessage 'Game process priority optimizations applied' -FailureMessage 'Failed to adjust DX11 game priority settings' -Action {
            Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options" 'UseLargePages' 'DWord' 1 -RequiresAdmin $true | Out-Null
            Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" 'Win32PrioritySeparation' 'DWord' 38 -RequiresAdmin $true | Out-Null
            Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" 'LargeSystemCache' 'DWord' 0 -RequiresAdmin $true | Out-Null
        } | Out-Null
    }
    DX11DisableBackgroundServices = {
        Invoke-LoggedAction -SuccessMessage 'Background services disabled for gaming performance' -FailureMessage 'Failed to disable background services' -Action {
            $servicesToDisable = @('Themes','TabletInputService','Fax','WSearch','HomeGroupListener','HomeGroupProvider')
            foreach ($service in $servicesToDisable) {
                $svc = Get-Service -Name $service -ErrorAction SilentlyContinue
                if ($svc -and $svc.Status -eq 'Running') {
                    Set-Service -Name $service -StartupType Disabled -ErrorAction SilentlyContinue
                    Stop-Service -Name $service -Force -ErrorAction SilentlyContinue
                }
            }
        } | Out-Null
    }
    DX11HardwareAcceleration = {
        Invoke-LoggedAction -SuccessMessage 'Hardware-accelerated GPU scheduling enabled' -FailureMessage 'Failed to enable hardware acceleration for DX11' -Action {
            $path = "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"
            Set-Reg $path 'HwSchMode' 'DWord' 2 -RequiresAdmin $true | Out-Null
            Set-Reg $path 'EnableHWSched' 'DWord' 1 -RequiresAdmin $true | Out-Null
            Set-Reg "HKLM:\SOFTWARE\Microsoft\DirectX" 'D3D_DISABLE_9EX' 'DWord' 0 -RequiresAdmin $true | Out-Null
        } | Out-Null
    }
    DX11MaxPerformanceMode = {
        Invoke-LoggedAction -SuccessMessage 'Maximum performance mode configured' -FailureMessage 'Failed to configure maximum performance mode' -Action {
            Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Power" 'HibernateEnabledDefault' 'DWord' 0 -RequiresAdmin $true | Out-Null
            Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" 'HiberbootEnabled' 'DWord' 0 -RequiresAdmin $true | Out-Null
            $powerPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\893dee8e-2bef-41e0-89c6-b55d0929964c"
            Set-Reg $powerPath 'ValueMax' 'DWord' 0 -RequiresAdmin $true | Out-Null
            Set-Reg $powerPath 'ValueMin' 'DWord' 0 -RequiresAdmin $true | Out-Null
        } | Out-Null
    }
    DX11RegistryOptimizations = {
        Invoke-LoggedAction -SuccessMessage 'DirectX 11 registry optimizations applied' -FailureMessage 'Failed to apply DirectX 11 registry optimizations' -Action {
            Set-Reg "HKLM:\SOFTWARE\Microsoft\DirectX" 'D3D11_MULTITHREADED' 'DWord' 1 -RequiresAdmin $true | Out-Null
            Set-Reg "HKLM:\SOFTWARE\Microsoft\DirectX" 'D3D11_ENABLE_BREAK_ON_MESSAGE' 'DWord' 0 -RequiresAdmin $true | Out-Null
            Set-Reg "HKLM:\SOFTWARE\Microsoft\DirectX" 'D3D11_ENABLE_SHADER_CACHING' 'DWord' 1 -RequiresAdmin $true | Out-Null
            Set-Reg "HKLM:\SOFTWARE\Microsoft\DirectX" 'D3D11_FORCE_SINGLE_THREADED' 'DWord' 0 -RequiresAdmin $true | Out-Null
            Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" 'DisableWriteCombining' 'DWord' 0 -RequiresAdmin $true | Out-Null
        } | Out-Null
    }
}

function Apply-DX11Optimizations {
    param([string[]]$OptimizationList)

    if (-not $OptimizationList -or $OptimizationList.Count -eq 0) {
        return
    }

    Log 'Applying DirectX 11 optimizations...' 'Info'
    foreach ($optimization in $OptimizationList) {
        $handler = $script:dx11OptimizationHandlers[$optimization]
        if ($handler) {
            & $handler
        }
        else {
            Log "Unknown DX11 optimization '$optimization'" 'Warning'
        }
    }
}

# ---------- Apply Game-Specific Tweaks ----------
$script:gameSpecificTweakHandlers = @{
    DisableNagle              = {
        Invoke-LoggedAction -SuccessMessage "Nagle's algorithm disabled" -FailureMessage "Failed to disable Nagle's algorithm" -Action {
            $tcpPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"
            Set-Reg $tcpPath 'TcpNoDelay' 'DWord' 1 -RequiresAdmin $true | Out-Null
            Set-Reg $tcpPath 'TCPNoDelay' 'DWord' 1 -RequiresAdmin $true | Out-Null
            Set-Reg $tcpPath 'TcpDelAckTicks' 'DWord' 0 -RequiresAdmin $true | Out-Null
        } | Out-Null
    }
    HighPrecisionTimer        = {
        Invoke-LoggedAction -SuccessMessage 'High precision timer enabled' -FailureMessage 'Failed to enable high precision timer' -Action {
            Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" 'GlobalTimerResolutionRequests' 'DWord' 1 -RequiresAdmin $true | Out-Null
            [WinMM]::timeBeginPeriod(1) | Out-Null
        } | Out-Null
    }
    NetworkOptimization       = {
        Invoke-LoggedAction -SuccessMessage 'Network optimization applied' -FailureMessage 'Failed to apply network optimization' -Action {
            $tcpPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"
            Set-Reg $tcpPath 'MaxConnectionsPerServer' 'DWord' 16 -RequiresAdmin $true | Out-Null
            Set-Reg $tcpPath 'MaxConnectionsPer1_0Server' 'DWord' 16 -RequiresAdmin $true | Out-Null
            Set-Reg $tcpPath 'DefaultTTL' 'DWord' 64 -RequiresAdmin $true | Out-Null
            Set-Reg $tcpPath 'TcpTimedWaitDelay' 'DWord' 30 -RequiresAdmin $true | Out-Null
        } | Out-Null
    }
    AntiCheatOptimization     = {
        Invoke-LoggedAction -SuccessMessage 'Anti-cheat optimizations applied' -FailureMessage 'Failed to apply anti-cheat optimizations' -Action {
            $mmPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
            Set-Reg $mmPath 'DisablePagingExecutive' 'DWord' 1 -RequiresAdmin $true | Out-Null
            Set-Reg $mmPath 'SecondLevelDataCache' 'DWord' 1024 -RequiresAdmin $true | Out-Null
        } | Out-Null
    }
    MemoryOptimization        = {
        Invoke-LoggedAction -SuccessMessage 'Memory optimization applied' -FailureMessage 'Failed to apply memory optimization' -Action {
            $mmPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
            Set-Reg $mmPath 'LargeSystemCache' 'DWord' 0 -RequiresAdmin $true | Out-Null
            Set-Reg $mmPath 'SystemPages' 'DWord' 0 -RequiresAdmin $true | Out-Null
            Set-Reg $mmPath 'DisablePagingExecutive' 'DWord' 1 -RequiresAdmin $true | Out-Null
            Set-Reg $mmPath 'NonPagedPoolQuota' 'DWord' 0 -RequiresAdmin $true | Out-Null
            Set-Reg $mmPath 'PagedPoolQuota' 'DWord' 0 -RequiresAdmin $true | Out-Null
        } | Out-Null
    }
    UnrealEngineOptimization  = {
        Invoke-LoggedAction -SuccessMessage 'Unreal Engine optimizations applied' -FailureMessage 'Failed to apply Unreal Engine optimizations' -Action {
            $uePath = "HKCU:\SOFTWARE\Epic Games\Unreal Engine"
            Set-Reg $uePath 'DisableAsyncCompute' 'DWord' 0 | Out-Null
            Set-Reg $uePath 'bUseVSync' 'DWord' 0 | Out-Null
            Set-Reg $uePath 'bSmoothFrameRate' 'DWord' 0 | Out-Null
            Set-Reg $uePath 'MaxSmoothedFrameRate' 'DWord' 144 | Out-Null
        } | Out-Null
    }
    SourceEngineOptimization  = {
        Invoke-LoggedAction -SuccessMessage 'Source Engine optimizations applied' -FailureMessage 'Failed to apply Source Engine optimizations' -Action {
            $sourcePath = "HKCU:\SOFTWARE\Valve\Source"
            Set-Reg $sourcePath 'mat_queue_mode' 'DWord' 2 | Out-Null
            Set-Reg $sourcePath 'cl_threaded_bone_setup' 'DWord' 1 | Out-Null
            Set-Reg $sourcePath 'cl_threaded_client_leaf_system' 'DWord' 1 | Out-Null
            Set-Reg $sourcePath 'r_threaded_client_shadow_manager' 'DWord' 1 | Out-Null
            Set-Reg $sourcePath 'r_threaded_particles' 'DWord' 1 | Out-Null
            Set-Reg $sourcePath 'r_threaded_renderables' 'DWord' 1 | Out-Null
            Set-Reg $sourcePath 'r_queued_ropes' 'DWord' 1 | Out-Null
        } | Out-Null
    }
    FrostbiteEngineOptimization = {
        Invoke-LoggedAction -SuccessMessage 'Frostbite Engine optimizations applied' -FailureMessage 'Failed to apply Frostbite Engine optimizations' -Action {
            $path = "HKCU:\SOFTWARE\EA\Frostbite"
            Set-Reg $path 'DisableLayeredRendering' 'DWord' 0 | Out-Null
            Set-Reg $path 'RenderAheadLimit' 'DWord' 1 | Out-Null
            Set-Reg $path 'ThreadedRendering' 'DWord' 1 | Out-Null
        } | Out-Null
    }
    UnityEngineOptimization    = {
        Invoke-LoggedAction -SuccessMessage 'Unity Engine optimizations applied' -FailureMessage 'Failed to apply Unity Engine optimizations' -Action {
            Set-Reg "HKCU:\SOFTWARE\Unity Technologies\Unity Editor" 'EnableMetalSupport' 'DWord' 0 | Out-Null
            Set-Reg "HKCU:\SOFTWARE\Unity Technologies\Unity" 'GraphicsJobMode' 'DWord' 2 | Out-Null
            Set-Reg "HKCU:\SOFTWARE\Unity Technologies\Unity" 'ThreadedRendering' 'DWord' 1 | Out-Null
        } | Out-Null
    }
    BlizzardOptimization       = {
        Invoke-LoggedAction -SuccessMessage 'Blizzard game optimizations applied' -FailureMessage 'Failed to apply Blizzard optimizations' -Action {
            $path = "HKCU:\SOFTWARE\Blizzard Entertainment"
            Set-Reg $path 'DisableHardwareAcceleration' 'DWord' 0 | Out-Null
            Set-Reg $path 'Sound_OutputDriverName' 'String' 'Windows Audio Session' | Out-Null
            Set-Reg $path 'StreamingEnabled' 'DWord' 0 | Out-Null
        } | Out-Null
    }
    RiotClientOptimization     = {
        Invoke-LoggedAction -SuccessMessage 'Riot client optimizations applied' -FailureMessage 'Failed to apply Riot client optimizations' -Action {
            $path = "HKCU:\SOFTWARE\Riot Games"
            Set-Reg $path 'DisableHardwareAcceleration' 'DWord' 0 | Out-Null
            Set-Reg $path 'EnableLowSpecMode' 'DWord' 0 | Out-Null
            Set-Reg $path 'UseRawInput' 'DWord' 1 | Out-Null
        } | Out-Null
    }
    UbisoftOptimization        = {
        Invoke-LoggedAction -SuccessMessage 'Ubisoft optimizations applied' -FailureMessage 'Failed to apply Ubisoft optimizations' -Action {
            $path = "HKCU:\SOFTWARE\Ubisoft"
            Set-Reg $path 'DisableOverlay' 'DWord' 1 | Out-Null
            Set-Reg $path 'EnableMultiThreadedRendering' 'DWord' 1 | Out-Null
        } | Out-Null
    }
    CreationEngineOptimization = {
        Invoke-LoggedAction -SuccessMessage 'Creation Engine optimizations applied' -FailureMessage 'Failed to apply Creation Engine optimizations' -Action {
            $path = "HKCU:\SOFTWARE\Bethesda Softworks"
            Set-Reg $path 'bUseThreadedAI' 'DWord' 1 | Out-Null
            Set-Reg $path 'bUseThreadedMorpher' 'DWord' 1 | Out-Null
            Set-Reg $path 'bUseThreadedTempEffects' 'DWord' 1 | Out-Null
            Set-Reg $path 'bUseThreadedParticleSystem' 'DWord' 1 | Out-Null
        } | Out-Null
    }
    REDEngineOptimization      = {
        Invoke-LoggedAction -SuccessMessage 'RED Engine optimizations applied' -FailureMessage 'Failed to apply RED Engine optimizations' -Action {
            $path = "HKCU:\SOFTWARE\CD Projekt Red\REDengine"
            Set-Reg $path 'TextureStreamingEnabled' 'DWord' 1 | Out-Null
            Set-Reg $path 'AsyncComputeEnabled' 'DWord' 1 | Out-Null
            Set-Reg $path 'HybridSSR' 'DWord' 1 | Out-Null
        } | Out-Null
    }
    JavaOptimization           = {
        Invoke-LoggedAction -SuccessMessage 'Java optimizations applied' -FailureMessage 'Failed to apply Java optimizations' -Action {
            [Environment]::SetEnvironmentVariable("_JAVA_OPTIONS", "-Xmx4G -Xms2G -XX:+UseG1GC -XX:+ParallelRefProcEnabled", 'User')
            [Environment]::SetEnvironmentVariable("JAVA_TOOL_OPTIONS", "-XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions", 'User')
        } | Out-Null
    }
    EACOptimization            = {
        Invoke-LoggedAction -SuccessMessage 'EAC optimization applied' -FailureMessage 'Failed to apply EAC optimization' -Action {
            Set-Reg "HKLM:\SOFTWARE\EasyAntiCheat" "DisableAnalytics" 'DWord' 1 -RequiresAdmin $true | Out-Null
        } | Out-Null
    }
    RTXOptimization            = {
        Invoke-LoggedAction -SuccessMessage 'RTX optimizations applied' -FailureMessage 'Failed to apply RTX optimizations' -Action {
            Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Services\nvlddmkm" "RayTracingEnable" 'DWord' 1 -RequiresAdmin $true | Out-Null
        } | Out-Null
    }
    MonoGameOptimization       = {
        Invoke-LoggedAction -SuccessMessage 'MonoGame optimizations applied' -FailureMessage 'Failed to apply MonoGame optimizations' -Action {
            Set-Reg "HKCU:\SOFTWARE\MonoGame" 'PreferMultiThreaded' 'DWord' 1 | Out-Null
        } | Out-Null
    }
    LarianOptimization         = {
        Invoke-LoggedAction -SuccessMessage 'Larian engine optimizations applied' -FailureMessage 'Failed to apply Larian optimizations' -Action {
            Set-Reg "HKCU:\SOFTWARE\Larian Studios" 'AllowShaderCaching' 'DWord' 1 | Out-Null
        } | Out-Null
    }
    RockstarOptimization       = {
        Invoke-LoggedAction -SuccessMessage 'Rockstar launcher optimizations applied' -FailureMessage 'Failed to apply Rockstar optimizations' -Action {
            Set-Reg "HKCU:\SOFTWARE\Rockstar Games" 'DisableOverlay' 'DWord' 1 | Out-Null
        } | Out-Null
    }
    SquareEnixOptimization     = {
        Invoke-LoggedAction -SuccessMessage 'Square Enix optimizations applied' -FailureMessage 'Failed to apply Square Enix optimizations' -Action {
            Set-Reg "HKCU:\SOFTWARE\SquareEnix" 'UseFullScreenOptimizations' 'DWord' 0 | Out-Null
        } | Out-Null
    }
    ArenaNetOptimization       = {
        Invoke-LoggedAction -SuccessMessage 'ArenaNet optimizations applied' -FailureMessage 'Failed to apply ArenaNet optimizations' -Action {
            Set-Reg "HKCU:\SOFTWARE\ArenaNet" 'UseThreadedRenderer' 'DWord' 1 | Out-Null
        } | Out-Null
    }
    ZeniMaxOptimization        = {
        Invoke-LoggedAction -SuccessMessage 'ZeniMax optimizations applied' -FailureMessage 'Failed to apply ZeniMax optimizations' -Action {
            Set-Reg "HKCU:\SOFTWARE\Zenimax Online" 'DisableOverlay' 'DWord' 1 | Out-Null
        } | Out-Null
    }
    LumberyardOptimization     = {
        Invoke-LoggedAction -SuccessMessage 'Lumberyard optimizations applied' -FailureMessage 'Failed to apply Lumberyard optimizations' -Action {
            Set-Reg "HKCU:\SOFTWARE\Amazon Game Studios" 'ThreadedRendering' 'DWord' 1 | Out-Null
        } | Out-Null
    }
    CODOptimization            = {
        Invoke-LoggedAction -SuccessMessage 'Call of Duty optimizations applied' -FailureMessage 'Failed to apply Call of Duty optimizations' -Action {
            Set-Reg "HKCU:\SOFTWARE\Activision\Call of Duty" 'DisableOverlay' 'DWord' 1 | Out-Null
        } | Out-Null
    }
    AsoboOptimization          = {
        Invoke-LoggedAction -SuccessMessage 'Flight Simulator optimizations applied' -FailureMessage 'Failed to apply Flight Simulator optimizations' -Action {
            Set-Reg "HKCU:\SOFTWARE\Asobo Studio\FlightSimulator" 'UseShaderCaching' 'DWord' 1 | Out-Null
        } | Out-Null
    }
    ForzaTechOptimization      = {
        Invoke-LoggedAction -SuccessMessage 'ForzaTech optimizations applied' -FailureMessage 'Failed to apply ForzaTech optimizations' -Action {
            Set-Reg "HKCU:\SOFTWARE\Microsoft\Forza" 'UseThreadedRendering' 'DWord' 1 | Out-Null
        } | Out-Null
    }
    EGOEngineOptimization      = {
        Invoke-LoggedAction -SuccessMessage 'EGO engine optimizations applied' -FailureMessage 'Failed to apply EGO engine optimizations' -Action {
            Set-Reg "HKCU:\SOFTWARE\Codemasters" 'EnableMultiThreadedRendering' 'DWord' 1 | Out-Null
        } | Out-Null
    }
    InputLatencyOptimization   = {
        Invoke-LoggedAction -SuccessMessage 'Input latency optimization applied' -FailureMessage 'Failed to apply input latency optimization' -Action {
            Set-Reg "HKCU:\Control Panel\Keyboard" 'KeyboardDelay' 'String' '0' | Out-Null
        } | Out-Null
    }
}

function Apply-GameSpecificTweaks {
    param(
        [string]$GameKey,
        [string[]]$TweakList
    )

    foreach ($tweak in $TweakList) {
        $handler = $script:gameSpecificTweakHandlers[$tweak]
        if ($handler) {
            & $handler
        }
        else {
            Log "Unknown game-specific tweak '$tweak' for $GameKey" 'Warning'
        }
    }
}

function Apply-CustomGameOptimizations {
    param([string]$GameExecutable)

    try {
        Log "Applying custom optimizations for: $GameExecutable" 'Info'

        $processes = Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -like "*$($GameExecutable.Replace('.exe',''))*" }
        foreach ($proc in $processes) {
            Invoke-LoggedAction -SuccessMessage "Set high priority for $($proc.ProcessName)" -FailureMessage "Failed to set priority for $($proc.ProcessName)" -Action {
                $proc.PriorityClass = 'High'
            } | Out-Null
        }

        Invoke-LoggedAction -SuccessMessage 'Network latency optimizations applied' -FailureMessage 'Failed to apply network latency optimizations' -Action {
            Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" "TcpNoDelay" 'DWord' 1 -RequiresAdmin $true | Out-Null
            Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" "TcpDelAckTicks" 'DWord' 0 -RequiresAdmin $true | Out-Null
        } | Out-Null

        if (-not (Enable-GPUScheduling)) {
            Log 'GPU scheduling optimization skipped' 'Warning'
        }

        Invoke-LoggedAction -SuccessMessage 'Game Mode optimizations applied' -FailureMessage 'Failed to apply Game Mode optimizations' -Action {
            Set-Reg "HKCU:\SOFTWARE\Microsoft\GameBar" "AllowAutoGameMode" 'DWord' 1 | Out-Null
            Set-Reg "HKCU:\SOFTWARE\Microsoft\GameBar" "AutoGameModeEnabled" 'DWord' 1 | Out-Null
        } | Out-Null

        Invoke-LoggedAction -SuccessMessage 'High precision timer enabled' -FailureMessage 'Failed to enable high precision timer' -Action {
            [WinMM]::timeBeginPeriod(1) | Out-Null
        } | Out-Null

        Log "Custom optimizations completed for: $GameExecutable" 'Success'
    }
    catch {
        Log "Error applying custom game optimizations: $($_.Exception.Message)" 'Error'
    }
}
