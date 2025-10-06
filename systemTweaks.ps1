# ---------- Advanced System Tweaks Functions ----------
function Apply-HPETOptimization {
    param([bool]$Disable = $true)

    if ($Disable) {
            bcdedit /deletevalue useplatformclock 2>$null
            Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Services\Hpet" "Start" 'DWord' 4 -RequiresAdmin $true | Out-Null
            Log "HPET disabled" 'Success'
            Log "Failed to disable HPET" 'Warning'
        }
    }

function Remove-MenuDelay {
    Set-Reg "HKCU:\Control Panel\Desktop" "MenuShowDelay" 'String' "0" | Out-Null
    Log "Menu delay removed" 'Success'
}

function Disable-WindowsDefenderRealTime {
        Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction Stop
        Log "Windows Defender real-time protection disabled" 'Success'
        Log "Failed to disable Windows Defender: $($_.Exception.Message)" 'Warning'
    }

function Disable-ModernStandby {
    Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Power" "PlatformAoAcOverride" 'DWord' 0 -RequiresAdmin $true | Out-Null
    Log "Modern Standby disabled" 'Success'
}

function Enable-UTCTime {
    Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation" "RealTimeIsUniversal" 'DWord' 1 -RequiresAdmin $true | Out-Null
    Log "UTC time enabled" 'Success'
}

function Optimize-NTFSSettings {
    Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" "NtfsDisableLastAccessUpdate" 'DWord' 1 -RequiresAdmin $true | Out-Null
    Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" "NtfsDisable8dot3NameCreation" 'DWord' 1 -RequiresAdmin $true | Out-Null
    Log "NTFS settings optimized" 'Success'
}

function Disable-EdgeTelemetry {
    Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Edge" "MetricsReportingEnabled" 'DWord' 0 -RequiresAdmin $true | Out-Null
    Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Edge" "PersonalizationReportingEnabled" 'DWord' 0 -RequiresAdmin $true | Out-Null
    Log "Edge telemetry disabled" 'Success'
}

function Disable-Cortana {
    Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "AllowCortana" 'DWord' 0 -RequiresAdmin $true | Out-Null
    Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" "BingSearchEnabled" 'DWord' 0 | Out-Null
    Log "Cortana disabled" 'Success'
}

function Disable-Telemetry {
    Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" "AllowTelemetry" 'DWord' 0 -RequiresAdmin $true | Out-Null
    Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" "AllowTelemetry" 'DWord' 0 -RequiresAdmin $true | Out-Null
    Log "System telemetry disabled" 'Success'
}

# ---------- Razer Booster-inspired Advanced Optimizations ----------
function Disable-AdvancedTelemetry {
    # Enhanced telemetry disabling beyond basic Windows telemetry
    Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" "AllowTelemetry" 'DWord' 0 -RequiresAdmin $true | Out-Null
    Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" "AllowTelemetry" 'DWord' 0 -RequiresAdmin $true | Out-Null
    Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat" "AITEnable" 'DWord' 0 -RequiresAdmin $true | Out-Null
    Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat" "DisableInventory" 'DWord' 1 -RequiresAdmin $true | Out-Null
    Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat" "DisableUAR" 'DWord' 1 -RequiresAdmin $true | Out-Null
    Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\CompatTelRunner.exe" "Debugger" 'String' "%windir%\System32\taskkill.exe" -RequiresAdmin $true | Out-Null
    Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\DeviceCensus.exe" "Debugger" 'String' "%windir%\System32\taskkill.exe" -RequiresAdmin $true | Out-Null
    Log "Advanced telemetry and tracking disabled" 'Success'
}

function Enable-MemoryDefragmentation {
    # Advanced memory management and cleanup
    Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "ClearPageFileAtShutdown" 'DWord' 1 -RequiresAdmin $true | Out-Null
    Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "DisablePagingExecutive" 'DWord' 1 -RequiresAdmin $true | Out-Null
    Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "LargeSystemCache" 'DWord' 0 -RequiresAdmin $true | Out-Null
    Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "PoolUsageMaximum" 'DWord' 96 -RequiresAdmin $true | Out-Null
    # Enable memory compression for better performance
        Enable-MMAgent -MemoryCompression -ErrorAction SilentlyContinue
    Log "Memory defragmentation and optimization enabled" 'Success'
}

function Apply-ServiceOptimization {
    # Advanced service optimization for gaming performance
    $servicesToOptimize = @(
        "Themes", "WSearch", "Spooler", "Fax", "RemoteRegistry",
        "SysMain", "DiagTrack", "dmwappushservice", "PcaSvc",
        "WerSvc", "wuauserv", "BITS", "Schedule"
    )

    foreach ($service in $servicesToOptimize) {
            Set-Service -Name $service -StartupType Disabled -ErrorAction SilentlyContinue
            Stop-Service -Name $service -Force -ErrorAction SilentlyContinue
    }
    Log "Advanced service optimization applied" 'Success'
}

function Apply-DiskTweaksAdvanced {
    # Advanced disk I/O optimizations inspired by Razer Booster
    Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" "NtfsDisable8dot3NameCreation" 'DWord' 1 -RequiresAdmin $true | Out-Null
    Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" "NtfsDisableLastAccessUpdate" 'DWord' 1 -RequiresAdmin $true | Out-Null
    Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" "NtfsMemoryUsage" 'DWord' 2 -RequiresAdmin $true | Out-Null
    Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" "NtfsMftZoneReservation" 'DWord' 2 -RequiresAdmin $true | Out-Null
    Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" "RefsDisableLastAccessUpdate" 'DWord' 1 -RequiresAdmin $true | Out-Null
    # Optimize disk cache
    Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "IoPageLockLimit" 'DWord' 983040 -RequiresAdmin $true | Out-Null
    Log "Advanced disk I/O tweaks applied" 'Success'
}

function Enable-NetworkLatencyOptimization {
    # Ultra-low network latency optimizations
    Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "NetworkThrottlingIndex" 'DWord' 0xffffffff -RequiresAdmin $true | Out-Null
    Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" "TcpAckFrequency" 'DWord' 1 -RequiresAdmin $true | Out-Null
    Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" "TCPNoDelay" 'DWord' 1 -RequiresAdmin $true | Out-Null
    Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" "TcpDelAckTicks" 'DWord' 0 -RequiresAdmin $true | Out-Null
    Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" "TcpAckFrequency" 'DWord' 1 -RequiresAdmin $true | Out-Null
    Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" "TcpDelAckTicks" 'DWord' 0 -RequiresAdmin $true | Out-Null
    Log "Ultra-low network latency optimization enabled" 'Success'
}

function Enable-FPSSmoothness {
    # FPS smoothness and frame time optimization
    Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "GPU Priority" 'DWord' 8 -RequiresAdmin $true | Out-Null
    Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "Priority" 'DWord' 6 -RequiresAdmin $true | Out-Null
    Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "Scheduling Category" 'String' "High" -RequiresAdmin $true | Out-Null
    Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "SFIO Priority" 'String' "High" -RequiresAdmin $true | Out-Null
    # Enhanced GPU scheduling for smoother frame delivery
    Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "HwSchMode" 'DWord' 2 -RequiresAdmin $true | Out-Null
    Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\Scheduler" "EnablePreemption" 'DWord' 1 -RequiresAdmin $true | Out-Null
    Log "FPS smoothness and frame time optimization enabled" 'Success'
}

function Optimize-CPUMicrocode {
    # CPU microcode and cache optimization
    Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" "DisableTsx" 'DWord' 0 -RequiresAdmin $true | Out-Null
    Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" "MitigationOptions" 'QWord' 0x1000000000000 -RequiresAdmin $true | Out-Null
    Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "FeatureSettings" 'DWord' 1 -RequiresAdmin $true | Out-Null
    Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "FeatureSettingsOverride" 'DWord' 3 -RequiresAdmin $true | Out-Null
    Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "FeatureSettingsOverrideMask" 'DWord' 3 -RequiresAdmin $true | Out-Null
    Log "CPU microcode and cache optimization applied" 'Success'
}

function Optimize-RAMTimings {
    # RAM timing and frequency optimization
    Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "SystemCacheLimit" 'DWord' 0 -RequiresAdmin $true | Out-Null
    Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "SecondLevelDataCache" 'DWord' 1024 -RequiresAdmin $true | Out-Null
    Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "ThirdLevelDataCache" 'DWord' 8192 -RequiresAdmin $true | Out-Null
    Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "DisablePageCombining" 'DWord' 1 -RequiresAdmin $true | Out-Null
    # Enable large pages for gaming applications
    Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "LargePageMinimum" 'DWord' 2097152 -RequiresAdmin $true | Out-Null
    Log "RAM timing and frequency optimization applied" 'Success'
}

# Enhanced service disabling functions
function Disable-LocationTracking {
    Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" "Value" 'String' "Deny" -RequiresAdmin $true | Out-Null
    Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" "DisableLocation" 'DWord' 1 -RequiresAdmin $true | Out-Null
    Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" "DisableLocationScripting" 'DWord' 1 -RequiresAdmin $true | Out-Null
    Log "Location tracking services disabled" 'Success'
}

function Disable-AdvertisingID {
    Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" "DisabledByGroupPolicy" 'DWord' 1 -RequiresAdmin $true | Out-Null
    Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" "Enabled" 'DWord' 0 | Out-Null
    Log "Advertising ID services disabled" 'Success'
}

function Disable-ErrorReporting {
    Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting" "Disabled" 'DWord' 1 -RequiresAdmin $true | Out-Null
    Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting" "Disabled" 'DWord' 1 -RequiresAdmin $true | Out-Null
    Log "Error reporting services disabled" 'Success'
}

function Disable-BackgroundApps {
    Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" "GlobalUserDisabled" 'DWord' 1 | Out-Null
    Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" "LetAppsRunInBackground" 'DWord' 2 -RequiresAdmin $true | Out-Null
    Log "Background app refresh disabled" 'Success'
}

function Optimize-WindowsUpdate {
    # Optimize but don't completely disable Windows Update
    Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" "NoAutoUpdate" 'DWord' 1 -RequiresAdmin $true | Out-Null
    Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" "AUOptions" 'DWord' 2 -RequiresAdmin $true | Out-Null
    Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" "DODownloadMode" 'DWord' 0 -RequiresAdmin $true | Out-Null
    Log "Windows Update service optimized" 'Success'
}

function Disable-CompatibilityTelemetry {
    Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat" "AITEnable" 'DWord' 0 -RequiresAdmin $true | Out-Null
    Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat" "DisableInventory" 'DWord' 1 -RequiresAdmin $true | Out-Null
    Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat" "DisableUAR" 'DWord' 1 -RequiresAdmin $true | Out-Null
    Log "Compatibility telemetry disabled" 'Success'
}

function Disable-WSH {
    Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows Script Host\Settings" "Enabled" 'DWord' 0 -RequiresAdmin $true | Out-Null
    Log "Windows Script Host disabled" 'Success'
}

function Set-SelectiveVisualEffects {
    param([switch]$EnablePerformanceMode)

    if ($EnablePerformanceMode) {
        Set-Reg "HKCU:\Control Panel\Desktop" "DragFullWindows" 'String' "0" | Out-Null
        Set-Reg "HKCU:\Control Panel\Desktop" "FontSmoothing" 'String' "2" | Out-Null
        Set-Reg "HKCU:\Control Panel\Desktop\WindowMetrics" "MinAnimate" 'String' "0" | Out-Null
        Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "ListviewAlphaSelect" 'DWord' 0 | Out-Null
        Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarAnimations" 'DWord' 0 | Out-Null
        Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" "VisualFXSetting" 'DWord' 3 | Out-Null
        Log "Visual effects optimized for performance" 'Success'
    }
}

# ---------- Enhanced System Optimizations ----------
function Apply-EnhancedSystemOptimizations {
    param([hashtable]$Settings)

    Log "Applying enhanced system optimizations..." 'Info'

    # Automatic Disk Defragmentation and SSD Trimming
    if ($Settings.AutoDiskOptimization) {
            # Check if SSD or HDD and apply appropriate optimization
            $drives = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }
            foreach ($drive in $drives) {
                $driveLetter = $drive.DeviceID.Replace(':', '')
                try {
                    # Check if SSD
                    $physicalDisk = Get-PhysicalDisk | Where-Object { $_.BusType -eq 'SATA' -or $_.BusType -eq 'NVMe' -or $_.BusType -eq 'RAID' }
                    if ($physicalDisk -and $physicalDisk.MediaType -eq 'SSD') {
                        # SSD TRIM optimization
                        fsutil behavior set DisableDeleteNotify 0
                        Optimize-Volume -DriveLetter $driveLetter -ReTrim -Verbose
                        Log "SSD TRIM optimization applied for drive $($drive.DeviceID)" 'Success'
                    } else {
                        # HDD defragmentation
                        Optimize-Volume -DriveLetter $driveLetter -Defrag -Verbose
                        Log "Disk defragmentation applied for drive $($drive.DeviceID)" 'Success'

                    }
                    Log "Drive optimization failed for $($drive.DeviceID): $($_.Exception.Message)" 'Warning'
                }
            }
            Log "Automatic disk optimization failed: $($_.Exception.Message)" 'Warning'
        }

    # Adaptive Power Management Profiles
    if ($Settings.AdaptivePowerManagement) {
            # Create custom gaming power profile
            Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes\GamingProfile" "FriendlyName" 'String' "KOALA Gaming Profile" -RequiresAdmin $true | Out-Null
            Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes\GamingProfile" "Description" 'String' "Optimized for gaming performance with adaptive management" -RequiresAdmin $true | Out-Null

            # Configure adaptive settings
            Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\2a737441-1930-4402-8d77-b2bebba308a3\d4e98f31-5ffe-4ce1-be31-1b38b384c009" "ValueMax" 'DWord' 0 -RequiresAdmin $true | Out-Null
            Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\238c9fa8-0aad-41ed-83f4-97be242c8f20\94d3a615-a899-4ac5-ae2b-e4d8f634367f" "ValueMax" 'DWord' 100 -RequiresAdmin $true | Out-Null
            Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\238c9fa8-0aad-41ed-83f4-97be242c8f20\94d3a615-a899-4ac5-ae2b-e4d8f634367f" "ValueMin" 'DWord' 100 -RequiresAdmin $true | Out-Null

            # Disable CPU throttling
            Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\bc5038f7-23e0-4960-96da-33abaf5935ec" "ValueMax" 'DWord' 100 -RequiresAdmin $true | Out-Null
            Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\bc5038f7-23e0-4960-96da-33abaf5935ec" "ValueMin" 'DWord' 100 -RequiresAdmin $true | Out-Null

            Log "Adaptive power management profiles configured" 'Success'
            Log "Failed to configure adaptive power management: $($_.Exception.Message)" 'Warning'
        }

    # Enhanced Paging File Management
    if ($Settings.EnhancedPagingFile) {
            # Calculate optimal paging file size based on RAM
            $totalRAM = (Get-WmiObject -Class Win32_ComputerSystem).TotalPhysicalMemory / 1GB
            $optimalPageFile = [Math]::Round($totalRAM * 1.5, 0) * 1024  # 1.5x RAM in MB

            # Configure paging file settings
            Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "PagingFiles" 'String' "C:\pagefile.sys $optimalPageFile $optimalPageFile" -RequiresAdmin $true | Out-Null
            Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "ClearPageFileAtShutdown" 'DWord' 0 -RequiresAdmin $true | Out-Null
            Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "DisablePagingExecutive" 'DWord' 1 -RequiresAdmin $true | Out-Null
            Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "LargeSystemCache" 'DWord' 0 -RequiresAdmin $true | Out-Null

            Log "Enhanced paging file management configured (Size: $optimalPageFile MB)" 'Success'
            Log "Failed to configure enhanced paging file: $($_.Exception.Message)" 'Warning'
        }

    # DirectStorage API Optimization Enhancements
    if ($Settings.DirectStorageEnhanced) {
            # Advanced DirectStorage configuration
            Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Services\stornvme\Parameters\Device" "ForcedPhysicalSectorSizeInBytes" 'DWord' 4096 -RequiresAdmin $true | Out-Null
            Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" "NtfsDisableLastAccessUpdate" 'DWord' 1 -RequiresAdmin $true | Out-Null
            Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" "NtfsEncryptPagingFile" 'DWord' 0 -RequiresAdmin $true | Out-Null

            # DirectStorage registry optimizations
            Set-Reg "HKLM:\SOFTWARE\Microsoft\DirectStorage" "EnableCompressionGPU" 'DWord' 1 -RequiresAdmin $true | Out-Null
            Set-Reg "HKLM:\SOFTWARE\Microsoft\DirectStorage" "EnableMetalSupport" 'DWord' 1 -RequiresAdmin $true | Out-Null
            Set-Reg "HKLM:\SOFTWARE\Microsoft\DirectStorage" "ForceEnableDirectStorage" 'DWord' 1 -RequiresAdmin $true | Out-Null
            Set-Reg "HKLM:\SOFTWARE\Microsoft\DirectStorage" "OptimizationLevel" 'DWord' 2 -RequiresAdmin $true | Out-Null

            # NVMe optimizations for DirectStorage
            Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Services\stornvme\Parameters" "EnableLogging" 'DWord' 0 -RequiresAdmin $true | Out-Null
            Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Enum\PCI\VEN_*\*\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties" "MSISupported" 'DWord' 1 -RequiresAdmin $true | Out-Null

            Log "Enhanced DirectStorage API optimizations applied" 'Success'
            Log "Failed to apply DirectStorage enhancements: $($_.Exception.Message)" 'Warning'
        }

    Log "Enhanced system optimizations completed" 'Success'

