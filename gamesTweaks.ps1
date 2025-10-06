# ---------- Enhanced Game Detection and Auto-Optimization ----------
$global:ActiveGameProcesses = @()
$global:GameDetectionTimer = $null
$global:AutoOptimizationEnabled = $false

function Get-RunningGameProcesses {
    <#
    .SYNOPSIS
    Enhanced real-time detection of running games and game-related processes
    .DESCRIPTION
    Monitors system processes to detect active games and automatically trigger optimizations
    #>

    try {
        $runningGames = @()
        $gameProcesses = Get-Process | Where-Object {
            $_.ProcessName -and $_.MainWindowTitle -and (
                $_.ProcessName -match "^(cs2|csgo|valorant|overwatch|rainbow|fortnite|apex|pubg|warzone|modernwarfare|league|rocket|dota2|gta|cyberpunk|minecraft)" -or
                $_.MainWindowTitle -match "Counter-Strike|VALORANT|Overwatch|Rainbow Six|Fortnite|Apex Legends|PUBG|Warzone|Modern Warfare|League of Legends|Rocket League|Dota 2|Grand Theft Auto|Cyberpunk|Minecraft"
            )
        }

        foreach ($process in $gameProcesses) {
            $matchedProfile = $null
            foreach ($profileKey in $GameProfiles.Keys) {
                $profile = $GameProfiles[$profileKey]
                if ($profile.ProcessNames -and ($profile.ProcessNames -contains $process.ProcessName -or
                    ($profile.ProcessNames | Where-Object { $process.ProcessName -match $_ }))) {
                    $matchedProfile = @{
                        Key     = $profileKey
                        Profile = $profile
                        Process = $process
                    }
                    break
                }
            }

            if ($matchedProfile) {
                $runningGames += $matchedProfile
                Log "Detected running game: $($matchedProfile.Profile.DisplayName) (PID: $($process.Id))" 'Info'
            } else {
                $runningGames += @{
                    Key     = 'unknown'
                    Profile = @{ DisplayName = $process.MainWindowTitle; ProcessNames = @($process.ProcessName) }
                    Process = $process
                }
                Log "Detected unknown game: $($process.MainWindowTitle) ($($process.ProcessName))" 'Info'
            }
        }

        return $runningGames
    } catch {
        Log "Error detecting running games: $($_.Exception.Message)" 'Warning'
        return @()
    }
}

function Update-ActiveGamesTracking {
    <#
    .SYNOPSIS
    Updates the global active games list and triggers auto-optimization if enabled
    .DESCRIPTION
    Maintains real-time tracking of active games and applies optimizations automatically
    #>

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

        foreach ($newGame in $newGames) {
            Log "Game started: $($newGame.Profile.DisplayName)" 'Success'
            if ($global:AutoOptimizeEnabled -and $newGame.Key -ne 'unknown') {
                Log "Auto-optimization triggered for: $($newGame.Profile.DisplayName)" 'Info'
                Start-AutoGameOptimization -GameProfile $newGame
            }
        }

        foreach ($stoppedGame in $stoppedGames) {
            Log "Game stopped: $($stoppedGame.Profile.DisplayName)" 'Info'
        }

        if ($lblDashActiveGames) {
            $lblDashActiveGames.Dispatcher.Invoke([Action]{
                if ($currentGames.Count -gt 0) {
                    $lblDashActiveGames.Text = "$($currentGames.Count) active"
                    Set-BrushPropertySafe -Target $lblDashActiveGames -Property 'Foreground' -Value '#8F6FFF'
                } else {
                    $lblDashActiveGames.Text = 'None active'
                    Set-BrushPropertySafe -Target $lblDashActiveGames -Property 'Foreground' -Value '#A6AACF'
                }
            })
        }
    } catch {
        Log "Error updating active games tracking: $($_.Exception.Message)" 'Warning'
    }
}

function Start-AutoGameOptimization {
    <#
    .SYNOPSIS
    Automatically applies game-specific optimizations when a game is detected
    .PARAMETER GameProfile
    The detected game profile to optimize for
    #>
    param(
        [Parameter(Mandatory = $true)]
        $GameProfile
    )

    try {
        $profile = $GameProfile.Profile
        Log "Starting auto-optimization for: $($profile.DisplayName)" 'Info'

        if ($GameProfile.Key -ne 'unknown' -and $profile.SpecificTweaks) {
            foreach ($tweak in $profile.SpecificTweaks) {
                switch ($tweak) {
                    'DisableNagle' {
                        Set-Reg "HKLM:\SYSTEM\CurrentControlSet\services\Tcpip\Parameters\Interfaces" "TcpNoDelay" 'DWord' 1 -RequiresAdmin $true | Out-Null
                        Log 'Nagle algorithm disabled for gaming' 'Success'
                    }
                    'HighPrecisionTimer' {
                        Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" "GlobalTimerResolutionRequests" 'DWord' 1 -RequiresAdmin $true | Out-Null
                        Log 'High precision timer enabled' 'Success'
                    }
                    'NetworkOptimization' {
                        Set-Reg "HKLM:\SYSTEM\CurrentControlSet\services\Tcpip\Parameters" "TcpDelAckTicks" 'DWord' 0 -RequiresAdmin $true | Out-Null
                        Set-Reg "HKLM:\SYSTEM\CurrentControlSet\services\Tcpip\Parameters" "TCPNoDelay" 'DWord' 1 -RequiresAdmin $true | Out-Null
                        Log 'Network optimizations applied' 'Success'
                    }
                    'CPUCoreParkDisable' {
                        Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318583" "ValueMax" 'DWord' 0 -RequiresAdmin $true | Out-Null
                        Log 'CPU core parking disabled' 'Success'
                    }
                }
            }
        }

        if ($profile.Priority -and $GameProfile.Process) {
            try {
                switch ($profile.Priority) {
                    'High'        { $GameProfile.Process.PriorityClass = 'High' }
                    'AboveNormal' { $GameProfile.Process.PriorityClass = 'AboveNormal' }
                    'Normal'      { $GameProfile.Process.PriorityClass = 'Normal' }
                }
                Log "Process priority set to $($profile.Priority) for $($profile.DisplayName)" 'Success'
            } catch {
                Log "Could not set process priority: $($_.Exception.Message)" 'Warning'
            }
        }

        Log "Auto-optimization completed for: $($profile.DisplayName)" 'Success'
    } catch {
        Log "Error during auto-optimization: $($_.Exception.Message)" 'Error'
    }
}

function Get-CloudGamingServices {
    <#
    .SYNOPSIS
    Detects cloud gaming services and streaming platforms
    .DESCRIPTION
    Identifies Xbox Game Pass, GeForce Now, Stadia, Amazon Luna, etc.
    #>

        $cloudServices = @()

        # Xbox Game Pass detection - Microsoft.GamingApp and WindowsApps integration
        $gamePassPaths = @(
            "$env:LOCALAPPDATA\Packages\Microsoft.GamingApp_*",
            "$env:ProgramFiles\Xbox Games",
            "$env:ProgramFiles\WindowsApps\Microsoft.GamingApp_*"
        )

        foreach ($path in $gamePassPaths) {
            $found = Get-ChildItem -Path $path -ErrorAction SilentlyContinue
            if ($found) {
                $cloudServices += [PSCustomObject]@{
                    Name = "Xbox Game Pass"
                    Path = $found[0].FullName
                    Details = "Cloud Gaming Service - Microsoft"
                    Type = "CloudGaming"

                }
                break
            }
        }

        # NVIDIA GeForce NOW detection - NVIDIA Corporation\GeForceNOW path scanning
        $geforceNowPath = "$env:LOCALAPPDATA\NVIDIA Corporation\GeForceNOW"
        if (Test-Path $geforceNowPath) {
            $cloudServices += [PSCustomObject]@{
                Name = "NVIDIA GeForce NOW"
                Path = $geforceNowPath
                Details = "Cloud Gaming Service - NVIDIA"
                Type = "CloudGaming"
            }
        }

        # Amazon Luna detection - Amazon Games\Luna cloud gaming platform
        $lunaPath = "$env:LOCALAPPDATA\Amazon Games\Luna"
        if (Test-Path $lunaPath) {
            $cloudServices += [PSCustomObject]@{
                Name = "Amazon Luna"
                Path = $lunaPath
                Details = "Cloud Gaming Service - Amazon"
                Type = "CloudGaming"
            }
        }

        # Browser-based cloud gaming detection (stadia.google.com, xbox.com/play, playstation.com services)
        $browserCloudGaming = @(
            @{ Name = "Google Stadia"; URL = "stadia.google.com" },
            @{ Name = "Xbox Cloud Gaming"; URL = "xbox.com/play" },
            @{ Name = "PlayStation Now"; URL = "playstation.com/ps-now" }
        )

        foreach ($service in $browserCloudGaming) {
            # Check for browser shortcuts or bookmarks (simplified detection)
            $shortcutPaths = @(
                "$env:USERPROFILE\Desktop\*.lnk",
                "$env:USERPROFILE\Desktop\*.url",
                "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\*.lnk"
            )

            foreach ($shortcutPath in $shortcutPaths) {
                $shortcuts = Get-ChildItem -Path $shortcutPath -ErrorAction SilentlyContinue
                foreach ($shortcut in $shortcuts) {
                    $content = Get-Content $shortcut.FullName -Raw -ErrorAction SilentlyContinue
                    if ($content -and $content -match $service.URL) {
                        $cloudServices += [PSCustomObject]@{
                            Name = $service.Name
                            Path = $shortcut.FullName
                            Details = "Browser-based Cloud Gaming"
                            Type = "CloudGaming"
                        }
                        break
                    }
                }
            }
        }

        return $cloudServices

        Log "Error detecting cloud gaming services: $($_.Exception.Message)" 'Warning'
        return @()
    }

function Start-GameDetectionMonitoring {
    <#
    .SYNOPSIS
    Starts real-time game detection monitoring with configurable intervals
    .DESCRIPTION
    Initializes a dispatcher timer for monitoring running games and auto-optimization
    #>

        if ($global:GameDetectionTimer) {
            $global:GameDetectionTimer.Stop()

        }

        # Create dispatcher timer for game detection
        $global:GameDetectionTimer = New-Object System.Windows.Threading.DispatcherTimer
        $global:GameDetectionTimer.Interval = [TimeSpan]::FromSeconds(5)  # Check every 5 seconds

        # Set up timer event
        $global:GameDetectionTimer.Add_Tick({
            Update-ActiveGamesTracking
        })

        # Start the timer
        $global:GameDetectionTimer.Start()

        # Initial check
        Update-ActiveGamesTracking

        Log "Game detection monitoring started (5s intervals)" 'Success'

        Log "Error starting game detection monitoring: $($_.Exception.Message)" 'Error'
    }

function Stop-GameDetectionMonitoring {
    <#
    .SYNOPSIS
    Stops the game detection monitoring timer
    #>

        if ($global:GameDetectionTimer) {
            $global:GameDetectionTimer.Stop()
            $global:GameDetectionTimer = $null
            Log "Game detection monitoring stopped" 'Info'

        }
        $global:ActiveGameProcesses = @()
        $global:ActiveGames = @()
        if ($lblDashActiveGames) {
            $lblDashActiveGames.Dispatcher.Invoke([Action]{
                $lblDashActiveGames.Text = "None detected"
                Set-BrushPropertySafe -Target $lblDashActiveGames -Property 'Foreground' -Value '#A6AACF'
            })
        }
        Write-Verbose "Error stopping game detection monitoring: $($_.Exception.Message)"
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
    $runningGames = @()
    $allProcesses = Get-Process -ErrorAction SilentlyContinue

    foreach ($profile in $GameProfiles.GetEnumerator()) {
        foreach ($processName in $profile.Value.ProcessNames) {
            $cleanName = $processName -replace '\.exe$', ''
            $foundProcess = $allProcesses | Where-Object { $_.ProcessName -like "*$cleanName*" }
            if ($foundProcess) {
                $runningGames += @{
                    GameKey = $profile.Key
                    DisplayName = $profile.Value.DisplayName
                    Process = $foundProcess
                    ProcessName = $processName
                }
                break
            }
        }
    }

    return $runningGames
}

function Start-GameDetectionLoop {
    $timer = New-Object System.Windows.Threading.DispatcherTimer
    $timer.Interval = [TimeSpan]::FromSeconds(5)

    $timer.Add_Tick({
        $currentGames = Get-RunningGames
        $global:ActiveGames = $currentGames

        if ($lblActiveGames) {
            $gamesList = if ($currentGames.Count -gt 0) {
                ($currentGames | ForEach-Object { $_.DisplayName }) -join ", "
            } else {
                "None"
            }

            if ($lblActiveGames) {
                $lblActiveGames.Dispatcher.Invoke({
                    $lblActiveGames.Text = $gamesList
                    if ($lblLastRefresh) {
                        $lblLastRefresh.Text = Get-Date -Format "HH:mm:ss"
                    }
                })
            }
        }

        if ($global:AutoOptimizeEnabled -and $currentGames.Count -gt 0) {
            foreach ($game in $currentGames) {
                Apply-GameOptimizations -GameKey $game.GameKey -Process $game.Process
            }
        }
    })

    $timer.Start()
    return $timer

function Apply-GameOptimizations {
    param([string]$GameKey, [System.Diagnostics.Process]$Process)

    if (-not $GameProfiles.ContainsKey($GameKey)) { return }

    $profile = $GameProfiles[$GameKey]
    Log "Auto-optimizing detected game: $($profile.DisplayName)" 'Info'

        if ($profile.Priority -and $profile.Priority -ne 'Normal') {
            $Process.PriorityClass = $profile.Priority
            Log "Set process priority to $($profile.Priority) for $($profile.DisplayName)" 'Success'

        }

        if ($profile.Affinity -eq 'Auto') {
            $coreCount = (Get-CimInstance Win32_Processor).NumberOfLogicalProcessors
            if ($coreCount -gt 4) {
                $Process.ProcessorAffinity = [IntPtr]::new(15)
                Log "Set CPU affinity for $($profile.DisplayName) (using 4 cores)" 'Success'
            }
        }
        Log "Warning: Could not adjust process priority/affinity for $($profile.DisplayName)" 'Warning'
    }

    if ($profile.SpecificTweaks) {
        Log "Applying specific tweaks for $($profile.DisplayName)" 'Info'
        Apply-GameSpecificTweaks -GameKey $GameKey -TweakList $profile.SpecificTweaks
    }

    if ($profile.FPSBoostSettings) {
        Log "Applying FPS optimizations for $($profile.DisplayName)" 'Info'
        Apply-FPSOptimizations -OptimizationList $profile.FPSBoostSettings
    }

    Log "Auto-optimization completed for $($profile.DisplayName)" 'Success'

# ---------- Targeted Gaming Optimization Helpers ----------
function Disable-GameDVR {
    $allOperationsSucceeded = $true

        Log "Disabling Game DVR background recording and overlays..." 'Info'

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

        foreach ($operation in $operations) {
    try { & $operation } catch { $allOperationsSucceeded = $false }

        }

            $presenceWriter = Get-Service -Name 'GameBarPresenceWriter' -ErrorAction Stop
            if ($presenceWriter.Status -ne 'Stopped') {
                Stop-Service -Name 'GameBarPresenceWriter' -Force -ErrorAction Stop

            }
            Set-Service -Name 'GameBarPresenceWriter' -StartupType Disabled -ErrorAction Stop
            Log "Game Bar presence writer service disabled" 'Info'
            Write-Verbose "Game Bar Presence Writer service update skipped: $($_.Exception.Message)"
            $allOperationsSucceeded = $false
        }

        if ($allOperationsSucceeded) {
            Log "Game DVR disabled globally" 'Success'
        } else {
            Log "Game DVR registry updates applied with warnings (administrator rights may be required)" 'Warning'

        return $allOperationsSucceeded
        Log "Failed to disable Game DVR: $($_.Exception.Message)" 'Warning'
        return $false

function Enable-GPUScheduling {
    $gpuRegistryPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers'

        $osVersion = [Environment]::OSVersion.Version
        if ($osVersion.Major -lt 10 -or ($osVersion.Major -eq 10 -and $osVersion.Build -lt 19041)) {
            Log "Hardware GPU scheduling requires Windows 10 version 2004 or newer - skipping" 'Warning'
            return $false

        }

        if (-not (Test-Path $gpuRegistryPath -ErrorAction SilentlyContinue)) {
            Log "GPU scheduling registry path not found - hardware may not support this feature" 'Warning'
            return $false
        }

        $results = @(
            Set-Reg $gpuRegistryPath 'HwSchMode' 'DWord' 2 -RequiresAdmin $true,
            Set-Reg "$gpuRegistryPath\Scheduler" 'EnablePreemption' 'DWord' 1 -RequiresAdmin $true,
            Set-Reg $gpuRegistryPath 'PlatformSupportMiracast' 'DWord' 0 -RequiresAdmin $true
        )

        if ($results -contains $false) {
            Log "Hardware GPU scheduling applied with warnings (administrator rights may be required)" 'Warning'
            return $false
        }

        Log "Hardware GPU scheduling enabled" 'Success'
        return $true
        Log "Failed to enable hardware GPU scheduling: $($_.Exception.Message)" 'Warning'
        return $false
    }

# ---------- FPS Optimization Functions ----------
function Apply-FPSOptimizations {
    param([string[]]$OptimizationList)

    Log "Applying FPS optimizations..." 'Info'

    foreach ($optimization in $OptimizationList) {
        switch ($optimization) {
            'DirectXOptimization' {
                Set-Reg "HKLM:\SOFTWARE\Microsoft\Direct3D" "DisableVidMemVirtualization" 'DWord' 1 -RequiresAdmin $true | Out-Null
                Set-Reg "HKLM:\SOFTWARE\Microsoft\DirectX" "D3D12_ENABLE_UNSAFE_COMMAND_BUFFER_REUSE" 'DWord' 1 -RequiresAdmin $true | Out-Null
                Set-Reg "HKLM:\SOFTWARE\Microsoft\DirectX" "D3D12_ENABLE_RUNTIME_DRIVER_OPTIMIZATIONS" 'DWord' 1 -RequiresAdmin $true | Out-Null
                Log "DirectX optimizations applied" 'Success'
            }

            'DirectX12Optimization' {
                Set-Reg "HKLM:\SOFTWARE\Microsoft\DirectX" "D3D12_ENABLE_UNSAFE_COMMAND_BUFFER_REUSE" 'DWord' 1 -RequiresAdmin $true | Out-Null
                Set-Reg "HKLM:\SOFTWARE\Microsoft\DirectX" "D3D12_RESOURCE_ALIGNMENT" 'DWord' 1 -RequiresAdmin $true | Out-Null
                Set-Reg "HKLM:\SOFTWARE\Microsoft\DirectX" "D3D12_MULTITHREADED_COMMAND_QUEUE" 'DWord' 1 -RequiresAdmin $true | Out-Null
                Log "DirectX 12 optimizations applied" 'Success'
            }

            'ShaderCacheOptimization' {
                Set-Reg "HKCU:\SOFTWARE\Microsoft\Direct3D" "ShaderCache" 'DWord' 1 | Out-Null
                Set-Reg "HKCU:\SOFTWARE\Microsoft\Direct3D" "DisableShaderRecompilation" 'DWord' 1 | Out-Null
                Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "DisableShaderCache" 'DWord' 0 -RequiresAdmin $true | Out-Null
                Log "Shader cache optimization applied" 'Success'
            }

            'InputLatencyReduction' {
                Set-Reg "HKCU:\Control Panel\Mouse" "MouseSpeed" 'String' "0" | Out-Null
                Set-Reg "HKCU:\Control Panel\Mouse" "MouseThreshold1" 'String' "0" | Out-Null
                Set-Reg "HKCU:\Control Panel\Mouse" "MouseThreshold2" 'String' "0" | Out-Null
                Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Services\mouclass\Parameters" "MouseDataQueueSize" 'DWord' 100 -RequiresAdmin $true | Out-Null
                Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Services\kbdclass\Parameters" "KeyboardDataQueueSize" 'DWord' 100 -RequiresAdmin $true | Out-Null
                Log "Input latency reduction applied" 'Success'
            }

            'GPUSchedulingOptimization' {
                [void](Enable-GPUScheduling)
            }

            'MemoryCompressionDisable' {
                    Disable-MMAgent -MemoryCompression -ErrorAction Stop
                    Log "Memory compression disabled" 'Success'
                    Log "Failed to disable memory compression: $($_.Exception.Message)" 'Warning'
                }
            }

            'CPUCoreParkDisable' {
                Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318583" "ValueMax" 'DWord' 0 -RequiresAdmin $true | Out-Null
                Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318583" "ValueMin" 'DWord' 0 -RequiresAdmin $true | Out-Null
                Log "CPU core parking disabled" 'Success'
            }

            'InterruptModerationOptimization' {
                    Get-NetAdapter | ForEach-Object {
                        Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName "Interrupt Moderation" -DisplayValue "Disabled" -ErrorAction SilentlyContinue
                        Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName "Interrupt Moderation Rate" -DisplayValue "Off" -ErrorAction SilentlyContinue

                    }
                    Log "Interrupt moderation optimized" 'Success'
                    Log "Network adapter interrupt moderation failed: $($_.Exception.Message)" 'Warning'
                }
            }

            'AudioLatencyOptimization' {
                Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Audio" "DisableProtectedAudioDG" 'DWord' 1 -RequiresAdmin $true | Out-Null
                Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Audio" "DisableProtectedAudio" 'DWord' 1 -RequiresAdmin $true | Out-Null
                Set-Reg "HKCU:\SOFTWARE\Microsoft\Multimedia\Audio" "UserDuckingPreference" 'DWord' 3 | Out-Null
                Log "Audio latency optimization applied" 'Success'
            }

            'MemoryPoolOptimization' {
                Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "PoolUsageMaximum" 'DWord' 96 -RequiresAdmin $true | Out-Null
                Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "PagedPoolSize" 'DWord' 0xFFFFFFFF -RequiresAdmin $true | Out-Null
                Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "NonPagedPoolSize" 'DWord' 0 -RequiresAdmin $true | Out-Null
                Log "Memory pool optimization applied" 'Success'
            }

            'TextureStreamingOptimization' {
                Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" "VKPoolSize" 'DWord' 1073741824 | Out-Null
                Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "TdrLevel" 'DWord' 0 -RequiresAdmin $true | Out-Null
                Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "TdrDelay" 'DWord' 10 -RequiresAdmin $true | Out-Null
                Log "Texture streaming optimization applied" 'Success'
            }

            'VulkanOptimization' {
                Set-Reg "HKLM:\SOFTWARE\Khronos\Vulkan\ImplicitLayers" "VK_LAYER_VALVE_steam_overlay" 'DWord' 0 -RequiresAdmin $true | Out-Null
                Set-Reg "HKLM:\SOFTWARE\Khronos\Vulkan\Drivers" "VulkanAPIVersion" 'DWord' 1 -RequiresAdmin $true | Out-Null
                Log "Vulkan optimization applied" 'Success'
            }

            'OpenGLOptimization' {
                Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "DisableOpenGLShaderCache" 'DWord' 0 -RequiresAdmin $true | Out-Null
                Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\OpenGLDrivers" "EnableThreadedOptimizations" 'DWord' 1 -RequiresAdmin $true | Out-Null
                Log "OpenGL optimization applied" 'Success'
            }

            'PhysicsOptimization' {
                Set-Reg "HKLM:\SOFTWARE\NVIDIA Corporation\PhysX" "AsyncSceneCreation" 'DWord' 1 -RequiresAdmin $true | Out-Null
                Set-Reg "HKLM:\SOFTWARE\NVIDIA Corporation\Global\FTS" "EnableRID66610" 'DWord' 0 -RequiresAdmin $true | Out-Null
                Log "Physics optimization applied" 'Success'
            }

            'DLSSOptimization' {
                Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Services\nvlddmkm" "DLSSEnable" 'DWord' 1 -RequiresAdmin $true | Out-Null
                Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Services\nvlddmkm\FTS" "EnableDLSS" 'DWord' 1 -RequiresAdmin $true | Out-Null
                Log "DLSS optimization enabled" 'Success'
            }

            'RTXOptimization' {
                Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Services\nvlddmkm" "RayTracingEnable" 'DWord' 1 -RequiresAdmin $true | Out-Null
                Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Services\nvlddmkm" "EnableResizableBar" 'DWord' 1 -RequiresAdmin $true | Out-Null
                Log "RTX optimization configured" 'Success'
            }

            'FramePacingOptimization' {
                Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "PerfAnalysisInterval" 'DWord' 0 -RequiresAdmin $true | Out-Null
                Set-Reg "HKCU:\SOFTWARE\Microsoft\DirectX\UserGpuPreferences" "AutoHDREnable" 'DWord' 0 | Out-Null
                Log "Frame pacing optimization applied" 'Success'
            }

            'DynamicResolutionScaling' {
                Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "EnableAdaptiveResolution" 'DWord' 1 -RequiresAdmin $true | Out-Null
                Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "DynamicResolutionTarget" 'DWord' 60 -RequiresAdmin $true | Out-Null
                Set-Reg "HKLM:\SOFTWARE\Microsoft\DirectX" "D3D12_ENABLE_DYNAMIC_RESOLUTION" 'DWord' 1 -RequiresAdmin $true | Out-Null
                Set-Reg "HKCU:\SOFTWARE\Microsoft\DirectX\UserGpuPreferences" "EnableDynamicResolution" 'DWord' 1 | Out-Null
                Log "Dynamic resolution scaling for adaptive performance enabled" 'Success'
            }

            'EnhancedFramePacing' {
                Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "FramePacingEnabled" 'DWord' 1 -RequiresAdmin $true | Out-Null
                Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "FramePacingTargetFPS" 'DWord' 144 -RequiresAdmin $true | Out-Null
                Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "MicroStutterReduction" 'DWord' 1 -RequiresAdmin $true | Out-Null
                Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "FrameTimeSmoothening" 'DWord' 1 -RequiresAdmin $true | Out-Null
                Log "Enhanced frame pacing with micro stutter reduction applied" 'Success'
            }

            'ProfileBasedGPUOverclocking' {
                Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "EnableGPUOverclock" 'DWord' 1 -RequiresAdmin $true | Out-Null
                Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "GPUClockOffsetProfile1" 'DWord' 100 -RequiresAdmin $true | Out-Null
                Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "MemoryClockOffsetProfile1" 'DWord' 200 -RequiresAdmin $true | Out-Null
                Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "PowerLimitProfile1" 'DWord' 120 -RequiresAdmin $true | Out-Null
                Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "TempLimitProfile1" 'DWord' 83 -RequiresAdmin $true | Out-Null
                Log "Profile-based GPU overclocking configuration applied" 'Success'
            }

            'CompetitiveLatencyReduction' {
                Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "UltraLowLatencyMode" 'DWord' 1 -RequiresAdmin $true | Out-Null
                Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "PreRenderLimit" 'DWord' 1 -RequiresAdmin $true | Out-Null
                Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Services\DXGKrnl" "MonitorLatencyTolerance" 'DWord' 0 -RequiresAdmin $true | Out-Null
                Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Services\DXGKrnl" "MonitorRefreshLatencyTolerance" 'DWord' 0 -RequiresAdmin $true | Out-Null
                Set-Reg "HKCU:\Control Panel\Mouse" "SmoothMouseXCurve" 'Binary' @(0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xC0,0xCC,0x0C,0x00,0x00,0x00,0x00,0x00,0x80,0x99,0x19,0x00,0x00,0x00,0x00,0x00,0x40,0x66,0x26,0x00,0x00,0x00,0x00,0x00,0x00,0x33,0x33,0x00,0x00,0x00,0x00,0x00) | Out-Null
                Set-Reg "HKCU:\Control Panel\Mouse" "SmoothMouseYCurve" 'Binary' @(0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x38,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x70,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xA8,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xE0,0x00,0x00,0x00,0x00,0x00) | Out-Null
                Log "Enhanced competitive gaming latency reduction applied" 'Success'
            }

            'ChunkRenderingOptimization' {
                Set-Reg "HKCU:\SOFTWARE\Mojang" "RenderDistance" 'DWord' 12 | Out-Null
                [Environment]::SetEnvironmentVariable("_JAVA_OPTIONS", "-Xmx4G -Xms2G -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200", "User")
                Log "Chunk rendering optimization applied" 'Success'
            }

            'NetworkLatencyOptimization' {
                    netsh int tcp set supplemental internet congestionprovider=ctcp | Out-Null
                    Log "Network latency optimization applied" 'Success'
                    Log "Failed to apply network latency optimization" 'Warning'
                }
            }

            'CPUOptimization' {
                Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" "ThreadDpcEnable" 'DWord' 1 -RequiresAdmin $true | Out-Null
                Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" "DpcWatchdogProfileOffset" 'DWord' 10000 -RequiresAdmin $true | Out-Null
                Log "CPU optimization applied" 'Success'
            }

# ---------- DirectX 11 Optimization Functions ----------
function Apply-DX11Optimizations {
    param([string[]]$OptimizationList)

    Log "Applying DirectX 11 optimizations..." 'Info'

    foreach ($optimization in $OptimizationList) {
        switch ($optimization) {
            'DX11EnhancedGpuScheduling' {
                    Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "HwSchMode" 'DWord' 2 -RequiresAdmin $true | Out-Null
                    Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\Scheduler" "EnablePreemption" 'DWord' 1 -RequiresAdmin $true | Out-Null
                    Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "TdrLevel" 'DWord' 0 -RequiresAdmin $true | Out-Null
                    Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "TdrDelay" 'DWord' 60 -RequiresAdmin $true | Out-Null
                    Log "Enhanced GPU scheduling for DX11 applied" 'Success'
                    Log "Failed to apply enhanced GPU scheduling: $($_.Exception.Message)" 'Warning'
                }
            }

            'DX11GameProcessPriority' {
                    Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options" "UseLargePages" 'DWord' 1 -RequiresAdmin $true | Out-Null
                    Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" "Win32PrioritySeparation" 'DWord' 38 -RequiresAdmin $true | Out-Null
                    Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "LargeSystemCache" 'DWord' 0 -RequiresAdmin $true | Out-Null
                    Log "Game process priority optimizations applied" 'Success'
                    Log "Failed to apply process priority optimizations: $($_.Exception.Message)" 'Warning'
                }
            }

            'DX11DisableBackgroundServices' {
                    $servicesToDisable = @('Themes', 'TabletInputService', 'Fax', 'WSearch', 'HomeGroupListener', 'HomeGroupProvider')
                    foreach ($service in $servicesToDisable) {
                        $svc = Get-Service -Name $service -ErrorAction SilentlyContinue
                        if ($svc -and $svc.Status -eq 'Running') {
                            Set-Service -Name $service -StartupType Disabled -ErrorAction SilentlyContinue
                            Stop-Service -Name $service -Force -ErrorAction SilentlyContinue

                        }
                    }
                    Log "Background services disabled for gaming performance" 'Success'
                    Log "Failed to disable some background services: $($_.Exception.Message)" 'Warning'
                }
            }

            'DX11HardwareAcceleration' {
                    Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "HwSchMode" 'DWord' 2 -RequiresAdmin $true | Out-Null
                    Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "EnableHWSched" 'DWord' 1 -RequiresAdmin $true | Out-Null
                    Set-Reg "HKLM:\SOFTWARE\Microsoft\DirectX" "D3D_DISABLE_9EX" 'DWord' 0 -RequiresAdmin $true | Out-Null
                    Log "Hardware-accelerated GPU scheduling enabled" 'Success'
                    Log "Failed to enable hardware-accelerated GPU scheduling: $($_.Exception.Message)" 'Warning'
                }

            'DX11MaxPerformanceMode' {
                    Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Power" "HibernateEnabledDefault" 'DWord' 0 -RequiresAdmin $true | Out-Null
                    Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" "HiberbootEnabled" 'DWord' 0 -RequiresAdmin $true | Out-Null
                    Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\893dee8e-2bef-41e0-89c6-b55d0929964c" "ValueMax" 'DWord' 0 -RequiresAdmin $true | Out-Null
                    Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\893dee8e-2bef-41e0-89c6-b55d0929964c" "ValueMin" 'DWord' 0 -RequiresAdmin $true | Out-Null
                    Log "Maximum performance mode configured" 'Success'
                    Log "Failed to configure maximum performance mode: $($_.Exception.Message)" 'Warning'
                }

            'DX11RegistryOptimizations' {
                    Set-Reg "HKLM:\SOFTWARE\Microsoft\DirectX" "D3D11_MULTITHREADED" 'DWord' 1 -RequiresAdmin $true | Out-Null
                    Set-Reg "HKLM:\SOFTWARE\Microsoft\DirectX" "D3D11_ENABLE_BREAK_ON_MESSAGE" 'DWord' 0 -RequiresAdmin $true | Out-Null
                    Set-Reg "HKLM:\SOFTWARE\Microsoft\DirectX" "D3D11_ENABLE_SHADER_CACHING" 'DWord' 1 -RequiresAdmin $true | Out-Null
                    Set-Reg "HKLM:\SOFTWARE\Microsoft\DirectX" "D3D11_FORCE_SINGLE_THREADED" 'DWord' 0 -RequiresAdmin $true | Out-Null
                    Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "DisableWriteCombining" 'DWord' 0 -RequiresAdmin $true | Out-Null
                    Log "DirectX 11 registry optimizations applied" 'Success'
                    Log "Failed to apply DirectX 11 registry optimizations: $($_.Exception.Message)" 'Warning'
                }

# ---------- Apply Game-Specific Tweaks ----------
function Apply-GameSpecificTweaks {
    param([string]$GameKey, [array]$TweakList)

    foreach ($tweak in $TweakList) {
        switch ($tweak) {
            'DisableNagle' {
                Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" "TcpNoDelay" 'DWord' 1 -RequiresAdmin $true | Out-Null
                Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" "TCPNoDelay" 'DWord' 1 -RequiresAdmin $true | Out-Null
                Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" "TcpDelAckTicks" 'DWord' 0 -RequiresAdmin $true | Out-Null
                Log "Nagle's algorithm disabled" 'Success'
            }

            'HighPrecisionTimer' {
                Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" "GlobalTimerResolutionRequests" 'DWord' 1 -RequiresAdmin $true | Out-Null
                    [WinMM]::timeBeginPeriod(1) | Out-Null
                Log "High precision timer enabled" 'Success'
            }

            'NetworkOptimization' {
                Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" "MaxConnectionsPerServer" 'DWord' 16 -RequiresAdmin $true | Out-Null
                Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" "MaxConnectionsPer1_0Server" 'DWord' 16 -RequiresAdmin $true | Out-Null
                Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" "DefaultTTL" 'DWord' 64 -RequiresAdmin $true | Out-Null
                Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" "TcpTimedWaitDelay" 'DWord' 30 -RequiresAdmin $true | Out-Null
                Log "Network optimization applied" 'Success'
            }

            'AntiCheatOptimization' {
                Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "DisablePagingExecutive" 'DWord' 1 -RequiresAdmin $true | Out-Null
                Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "SecondLevelDataCache" 'DWord' 1024 -RequiresAdmin $true | Out-Null
                Log "Anti-cheat compatibility optimizations applied" 'Success'
            }

            'MemoryOptimization' {
                Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "LargeSystemCache" 'DWord' 0 -RequiresAdmin $true | Out-Null
                Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "SystemPages" 'DWord' 0 -RequiresAdmin $true | Out-Null
                Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "DisablePagingExecutive" 'DWord' 1 -RequiresAdmin $true | Out-Null
                Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "NonPagedPoolQuota" 'DWord' 0 -RequiresAdmin $true | Out-Null
                Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "PagedPoolQuota" 'DWord' 0 -RequiresAdmin $true | Out-Null
                Log "Memory optimization applied" 'Success'
            }

            'UnrealEngineOptimization' {
                Set-Reg "HKCU:\SOFTWARE\Epic Games\Unreal Engine" "DisableAsyncCompute" 'DWord' 0 | Out-Null
                Set-Reg "HKCU:\SOFTWARE\Epic Games\Unreal Engine" "bUseVSync" 'DWord' 0 | Out-Null
                Set-Reg "HKCU:\SOFTWARE\Epic Games\Unreal Engine" "bSmoothFrameRate" 'DWord' 0 | Out-Null
                Set-Reg "HKCU:\SOFTWARE\Epic Games\Unreal Engine" "MaxSmoothedFrameRate" 'DWord' 144 | Out-Null
                Log "Unreal Engine optimizations applied" 'Success'
            }

            'SourceEngineOptimization' {
                Set-Reg "HKCU:\SOFTWARE\Valve\Source" "mat_queue_mode" 'DWord' 2 | Out-Null
                Set-Reg "HKCU:\SOFTWARE\Valve\Source" "cl_threaded_bone_setup" 'DWord' 1 | Out-Null
                Set-Reg "HKCU:\SOFTWARE\Valve\Source" "cl_threaded_client_leaf_system" 'DWord' 1 | Out-Null
                Set-Reg "HKCU:\SOFTWARE\Valve\Source" "r_threaded_client_shadow_manager" 'DWord' 1 | Out-Null
                Set-Reg "HKCU:\SOFTWARE\Valve\Source" "r_threaded_particles" 'DWord' 1 | Out-Null
                Set-Reg "HKCU:\SOFTWARE\Valve\Source" "r_threaded_renderables" 'DWord' 1 | Out-Null
                Set-Reg "HKCU:\SOFTWARE\Valve\Source" "r_queued_ropes" 'DWord' 1 | Out-Null
                Log "Source Engine optimizations applied" 'Success'
            }

            'FrostbiteEngineOptimization' {
                Set-Reg "HKCU:\SOFTWARE\EA\Frostbite" "DisableLayeredRendering" 'DWord' 0 | Out-Null
                Set-Reg "HKCU:\SOFTWARE\EA\Frostbite" "RenderAheadLimit" 'DWord' 1 | Out-Null
                Set-Reg "HKCU:\SOFTWARE\EA\Frostbite" "ThreadedRendering" 'DWord' 1 | Out-Null
                Log "Frostbite Engine optimizations applied" 'Success'
            }

            'UnityEngineOptimization' {
                Set-Reg "HKCU:\SOFTWARE\Unity Technologies\Unity Editor" "EnableMetalSupport" 'DWord' 0 | Out-Null
                Set-Reg "HKCU:\SOFTWARE\Unity Technologies\Unity" "GraphicsJobMode" 'DWord' 2 | Out-Null
                Set-Reg "HKCU:\SOFTWARE\Unity Technologies\Unity" "ThreadedRendering" 'DWord' 1 | Out-Null
                Log "Unity Engine optimizations applied" 'Success'
            }

            'BlizzardOptimization' {
                Set-Reg "HKCU:\SOFTWARE\Blizzard Entertainment" "DisableHardwareAcceleration" 'DWord' 0 | Out-Null
                Set-Reg "HKCU:\SOFTWARE\Blizzard Entertainment" "Sound_OutputDriverName" 'String' "Windows Audio Session" | Out-Null
                Set-Reg "HKCU:\SOFTWARE\Blizzard Entertainment" "StreamingEnabled" 'DWord' 0 | Out-Null
                Log "Blizzard game optimizations applied" 'Success'
            }

            'RiotClientOptimization' {
                Set-Reg "HKCU:\SOFTWARE\Riot Games" "DisableHardwareAcceleration" 'DWord' 0 | Out-Null
                Set-Reg "HKCU:\SOFTWARE\Riot Games" "EnableLowSpecMode" 'DWord' 0 | Out-Null
                Set-Reg "HKCU:\SOFTWARE\Riot Games" "UseRawInput" 'DWord' 1 | Out-Null
                Log "Riot client optimizations applied" 'Success'
            }

            'UbisoftOptimization' {
                Set-Reg "HKCU:\SOFTWARE\Ubisoft" "DisableOverlay" 'DWord' 1 | Out-Null
                Set-Reg "HKCU:\SOFTWARE\Ubisoft" "EnableMultiThreadedRendering" 'DWord' 1 | Out-Null
                Log "Ubisoft optimizations applied" 'Success'
            }

            'CreationEngineOptimization' {
                Set-Reg "HKCU:\SOFTWARE\Bethesda Softworks" "bUseThreadedAI" 'DWord' 1 | Out-Null
                Set-Reg "HKCU:\SOFTWARE\Bethesda Softworks" "bUseThreadedMorpher" 'DWord' 1 | Out-Null
                Set-Reg "HKCU:\SOFTWARE\Bethesda Softworks" "bUseThreadedTempEffects" 'DWord' 1 | Out-Null
                Set-Reg "HKCU:\SOFTWARE\Bethesda Softworks" "bUseThreadedParticleSystem" 'DWord' 1 | Out-Null
                Log "Creation Engine optimizations applied" 'Success'
            }

            'REDEngineOptimization' {
                Set-Reg "HKCU:\SOFTWARE\CD Projekt Red\REDengine" "TextureStreamingEnabled" 'DWord' 1 | Out-Null
                Set-Reg "HKCU:\SOFTWARE\CD Projekt Red\REDengine" "AsyncComputeEnabled" 'DWord' 1 | Out-Null
                Set-Reg "HKCU:\SOFTWARE\CD Projekt Red\REDengine" "HybridSSR" 'DWord' 1 | Out-Null
                Log "RED Engine optimizations applied" 'Success'
            }

            'JavaOptimization' {
                [Environment]::SetEnvironmentVariable("_JAVA_OPTIONS", "-Xmx4G -Xms2G -XX:+UseG1GC -XX:+ParallelRefProcEnabled", "User")
                [Environment]::SetEnvironmentVariable("JAVA_TOOL_OPTIONS", "-XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions", "User")
                Log "Java optimizations applied" 'Success'
            }

            'EACOptimization' {
                Set-Reg "HKLM:\SOFTWARE\EasyAntiCheat" "DisableAnalytics" 'DWord' 1 -RequiresAdmin $true | Out-Null
                Log "EAC optimization applied" 'Success'
            }

            'RTXOptimization' {
                Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Services\nvlddmkm" "RayTracingEnable" 'DWord' 1 -RequiresAdmin $true | Out-Null
                Log "RTX optimizations applied" 'Success'
            }
        }
    }
}

# ---------- Custom Game Optimization Function ----------
function Apply-CustomGameOptimizations {
    param([string]$GameExecutable)

    Log "Applying standard gaming optimizations for: $GameExecutable in $global:MenuMode mode" 'Info'
    Log "Executable detection request - searching for running processes" 'Info'

        # Process Priority Optimization
        $processes = Get-Process | Where-Object { $_.ProcessName -like "*$($GameExecutable.Replace('.exe', ''))*" }
        foreach ($process in $processes) {
            try {
                $process.PriorityClass = 'High'
                Log "Set high priority for process: $($process.ProcessName)" 'Success'
            } catch {
                Log "Could not set priority for $($process.ProcessName)" 'Warning'
            }
        }

        # Standard Network Optimizations
        Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" "TcpNoDelay" 'DWord' 1 -RequiresAdmin $true | Out-Null
        Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" "TcpDelAckTicks" 'DWord' 0 -RequiresAdmin $true | Out-Null
        Log "Network latency optimizations applied" 'Success'

        # GPU Scheduling Optimization
        Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "HwSchMode" 'DWord' 2 -RequiresAdmin $true | Out-Null
        Log "Hardware GPU scheduling optimized" 'Success'

        # Game Mode Registry Settings
        Set-Reg "HKCU:\SOFTWARE\Microsoft\GameBar" "AllowAutoGameMode" 'DWord' 1 | Out-Null
        Set-Reg "HKCU:\SOFTWARE\Microsoft\GameBar" "AutoGameModeEnabled" 'DWord' 1 | Out-Null
        Log "Game Mode optimizations applied" 'Success'

        # Timer Resolution
            [WinMM]::timeBeginPeriod(1) | Out-Null
            Log "High precision timer enabled" 'Success'
            Log "Could not set timer resolution" 'Warning'

        Log "Custom game optimizations completed for: $GameExecutable" 'Success'

        Log "Error applying custom game optimizations: $($_.Exception.Message)" 'Error'

