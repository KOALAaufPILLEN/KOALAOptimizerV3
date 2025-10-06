# ---------- Backup and Restore Functions ----------
function Get-NetshTcpGlobal {
        $output = netsh int tcp show global
        $settings = @{}
        foreach ($line in $output) {
            if ($line -match '^\s*(.+?)\s*:\s*(.+?)\s*$') {
                $key = $matches[1].Trim()
                $value = $matches[2].Trim()
                $settings[$key] = $value

            }
        }
        return $settings
        return @{}
    }

# ---------- Registry File Creation Function ----------
function Create-RegFile {
    param(
        [Parameter(Mandatory=$true)]
        $BackupData,
        [Parameter(Mandatory=$true)]
        [string]$OutputPath
    )

        $regContent = @"
Windows Registry Editor Version 5.00

; KOALA Gaming Optimizer - Registry Backup
; Created: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
; Version: $($BackupData.Version)
;
; Double-click this file to restore registry settings to their backed-up values
; WARNING: This will modify your Windows registry. Create a backup before proceeding.

"@

        # Convert registry data to .reg format
        foreach ($regPath in $BackupData.Registry.PSObject.Properties.Name) {
            $regPathFormatted = $regPath -replace '^HKLM:', '[HKEY_LOCAL_MACHINE'
            $regPathFormatted = $regPathFormatted -replace '^HKCU:', '[HKEY_CURRENT_USER'
            $regPathFormatted = $regPathFormatted -replace '^HKCR:', '[HKEY_CLASSES_ROOT'
            $regPathFormatted = $regPathFormatted -replace '^HKU:', '[HKEY_USERS'
            $regPathFormatted = $regPathFormatted -replace '^HKCC:', '[HKEY_CURRENT_CONFIG'
            $regPathFormatted += ']'

            $regContent += "`n$regPathFormatted`n"

            foreach ($regName in $BackupData.Registry.$regPath.PSObject.Properties.Name) {
                $value = $BackupData.Registry.$regPath.$regName
                if ($null -ne $value) {
                    # Format as DWORD value
                    $regContent += "`"$regName`"=dword:$('{0:x8}' -f $value)`n"

                } else {
                    # Delete the value if it was null
                    $regContent += "`"$regName`"=-`n"
                }
            }
        }

        # Add NIC registry settings
        foreach ($nicPath in $BackupData.RegistryNICs.PSObject.Properties.Name) {
            $nicData = $BackupData.RegistryNICs.$nicPath
            $nicPathFormatted = $nicPath -replace '^HKLM:', '[HKEY_LOCAL_MACHINE'
            $nicPathFormatted += ']'

            $regContent += "`n$nicPathFormatted`n"

            if ($null -ne $nicData.TcpAckFrequency) {
                $regContent += "`"TcpAckFrequency`"=dword:$('{0:x8}' -f $nicData.TcpAckFrequency)`n"
            }
            if ($null -ne $nicData.TCPNoDelay) {
                $regContent += "`"TCPNoDelay`"=dword:$('{0:x8}' -f $nicData.TCPNoDelay)`n"
            }
        }

        Set-Content -Path $OutputPath -Value $regContent -Encoding Unicode -ErrorAction Stop
        Log "Registry file created successfully: $OutputPath" 'Success'

        Log "Failed to create registry file: $($_.Exception.Message)" 'Error'

function Create-Backup {
    Log "Creating comprehensive backup with user-selected location..." 'Info'

    # Allow user to select backup location and format
    $saveDialog = New-Object Microsoft.Win32.SaveFileDialog; $saveDialog.Title = "Select Backup Location"
    $saveDialog.Filter = "JSON files (*.json)|*.json|Registry files (*.reg)|*.reg|All files (*.*)|*.*"
    $saveDialog.DefaultExt = ".json"
    $saveDialog.FileName = "KOALA_Backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    $saveDialog.InitialDirectory = [Environment]::GetFolderPath("MyDocuments")

    if (-not $saveDialog.ShowDialog()) {
        Log "Backup cancelled by user" 'Info'
        return
    }

    $selectedPath = $saveDialog.FileName
    $selectedExtension = [System.IO.Path]::GetExtension($selectedPath).ToLower()

    Log "User selected backup path: $selectedPath (Format: $selectedExtension)" 'Info'

    $backupData = @{
        Timestamp = Get-Date
        Version = "3.0"
        GPU = Get-GPUVendor
        AdminPrivileges = Test-AdminPrivileges
        Registry = @{}
        RegistryNICs = @{}
        Services = @{}
        NetshTcp = @{}
        PowerSettings = @{}
    }

    # Extended registry backup list
    $regList = @(
        # Gaming optimizations
        @{Path="HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"; Name="SystemResponsiveness"},
        @{Path="HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"; Name="NetworkThrottlingIndex"},
        @{Path="HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"; Name="GPU Priority"},
        @{Path="HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"; Name="Priority"},
        @{Path="HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"; Name="Scheduling Category"},
        @{Path="HKCU:\System\GameConfigStore"; Name="GameDVR_Enabled"},
        @{Path="HKCU:\System\GameConfigStore"; Name="GameDVR_FSEBehaviorMode"},
        @{Path="HKCU:\System\GameConfigStore"; Name="GameDVR_FSEBehavior"},
        @{Path="HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR"; Name="AppCaptureEnabled"},
        @{Path="HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR"; Name="GameDVR_Enabled"}
    )

    # Backup registry values
    foreach ($r in $regList) {
            $value = Get-Reg $r.Path $r.Name
            if (-not $backupData.Registry.ContainsKey($r.Path)) {
                $backupData.Registry[$r.Path] = @{}

            }
            $backupData.Registry[$r.Path][$r.Name] = $value
            # Silently continue
        }
    }

    # Per-NIC registry backup
    $nicRoot = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces"
    if (Test-Path $nicRoot) {
        Get-ChildItem $nicRoot | ForEach-Object {
            $nicPath = $_.PSPath
            $ack = Get-Reg $nicPath 'TcpAckFrequency'
            $nodelay = Get-Reg $nicPath 'TCPNoDelay'
            if ($null -ne $ack -or $null -ne $nodelay) {
                $backupData.RegistryNICs[$nicPath] = @{
                    TcpAckFrequency = $ack
                    TCPNoDelay = $nodelay
                }
            }
        }
    }

    # Service backup
    $svcTargets = @(
        "XblGameSave", "XblAuthManager", "XboxGipSvc", "XboxNetApiSvc",
        "Spooler", "SysMain", "DiagTrack", "WSearch", "NvTelemetryContainer",
        "AMD External Events", "Fax", "RemoteRegistry", "MapsBroker",
        "WMPNetworkSvc", "WpnUserService", "bthserv", "TabletInputService",
        "TouchKeyboard", "WerSvc", "PcaSvc", "Themes"
    )

    foreach ($serviceName in $svcTargets) {
        $service = Get-ServiceState $serviceName
        if ($service) {
            $backupData.Services[$service.Name] = $service
        }
    }

    # Network settings backup
    $backupData.NetshTcp = Get-NetshTcpGlobal

    # Power settings backup
        $backupData.PowerSettings = @{
            ActivePowerScheme = (powercfg /getactivescheme 2>$null) -replace '^.*: ', '' -replace ' \(.*\)', ''

        }
        # Continue

    # Save backup based on user selection
        if ($selectedExtension -eq ".json") {
            # Save as JSON
            $backupJson = $backupData | ConvertTo-Json -Depth 10 -ErrorAction Stop
            Set-Content -Path $selectedPath -Value $backupJson -Encoding UTF8 -ErrorAction Stop
            Log "JSON backup successfully saved to: $selectedPath" 'Success'

            # Also create .reg file in the same directory
            $regFilePath = $selectedPath -replace '\.json$', '.reg'
            Create-RegFile -BackupData $backupData -OutputPath $regFilePath

            [System.Windows.MessageBox]::Show(
                "Backup created successfully!`n`nJSON Backup: $selectedPath`nRegistry File: $regFilePath`nTimestamp: $(Get-Date)`n`nThe JSON file contains complete backup data for script restoration.`nThe .reg file can be double-clicked to restore registry settings directly.",
                "Backup Complete",
                'OK',
                'Information'
            )

        } elseif ($selectedExtension -eq ".reg") {
            # Save as .reg file only
            Create-RegFile -BackupData $backupData -OutputPath $selectedPath

            # Also save JSON version for complete restoration
            $jsonFilePath = $selectedPath -replace '\.reg$', '.json'
            $backupJson = $backupData | ConvertTo-Json -Depth 10 -ErrorAction Stop
            Set-Content -Path $jsonFilePath -Value $backupJson -Encoding UTF8 -ErrorAction Stop

            [System.Windows.MessageBox]::Show(
                "Backup created successfully!`n`nRegistry File: $selectedPath`nJSON Backup: $jsonFilePath`nTimestamp: $(Get-Date)`n`nDouble-click the .reg file to restore registry settings.`nThe JSON file contains complete backup data for script restoration.",
                "Backup Complete",
                'OK',
                'Information'
            )
            # Default to JSON for unknown extensions
            $backupJson = $backupData | ConvertTo-Json -Depth 10 -ErrorAction Stop
            Set-Content -Path $selectedPath -Value $backupJson -Encoding UTF8 -ErrorAction Stop
            Log "Backup saved as JSON to: $selectedPath" 'Success'

            [System.Windows.MessageBox]::Show(
                "Backup created successfully!`n`nBackup File: $selectedPath`nTimestamp: $(Get-Date)`n`nSaved in JSON format for complete restoration.",
                "Backup Complete",
                'OK',
                'Information'
            )

        # Update the global backup path for restore operations
        $global:BackupPath = if ($selectedExtension -eq ".reg") { $selectedPath -replace '\.reg$', '.json' } else { $selectedPath }

        Log "Failed to save backup: $($_.Exception.Message)" 'Error'
        [System.Windows.MessageBox]::Show(
            "Failed to save backup!`n`nError: $($_.Exception.Message)`n`nPlease check the selected location and try again.",
            "Backup Failed",
            'OK',
            'Error'
        )

function Restore-FromBackup {
    if (-not (Test-Path $BackupPath)) {
        Log "No backup file found at: $BackupPath" 'Error'
        [System.Windows.MessageBox]::Show(
            "No backup file found!`n`nPlease create a backup before applying optimizations.",
            "Backup Not Found",
            'OK',
            'Warning'
        )
        return $false
    }

        $backupData = Get-Content $BackupPath -Raw | ConvertFrom-Json
        Log "Restoring from backup created: $($backupData.Timestamp)" 'Info'

        # Restore registry values
        foreach ($regPath in $backupData.Registry.PSObject.Properties.Name) {
            foreach ($regName in $backupData.Registry.$regPath.PSObject.Properties.Name) {
                $value = $backupData.Registry.$regPath.$regName
                if ($null -ne $value) {
                    Set-Reg $regPath $regName 'DWord' $value -RequiresAdmin $true | Out-Null

                }
            }
        }

        # Restore NIC registry values
        foreach ($nicPath in $backupData.RegistryNICs.PSObject.Properties.Name) {
            $nicData = $backupData.RegistryNICs.$nicPath
            if ($nicData.TcpAckFrequency) {
                Set-Reg $nicPath "TcpAckFrequency" 'DWord' $nicData.TcpAckFrequency -RequiresAdmin $true | Out-Null
            }
            if ($nicData.TCPNoDelay) {
                Set-Reg $nicPath "TCPNoDelay" 'DWord' $nicData.TCPNoDelay -RequiresAdmin $true | Out-Null
            }
        }

        # Restore services
        foreach ($serviceName in $backupData.Services.PSObject.Properties.Name) {
            $serviceData = $backupData.Services.$serviceName
                Set-Service -Name $serviceName -StartupType $serviceData.StartType -ErrorAction SilentlyContinue
                if ($serviceData.Status -eq 'Running') {
                    Start-Service -Name $serviceName -ErrorAction SilentlyContinue

                }
        }

        Log "Backup restored successfully!" 'Success'

        [System.Windows.MessageBox]::Show(
            "Backup restored successfully!`n`nSystem has been reverted to previous state.",
            "Restore Complete",
            'OK',
            'Information'
        )

        return $true

        Log "Failed to restore backup: $($_.Exception.Message)" 'Error'
        return $false
    }

# ---------- Configuration Import/Export ----------
function Export-Configuration {
        $config = @{
            Timestamp = Get-Date
            Version = "3.0"
            GameProfile = if ($cmbGameProfile.SelectedItem) { $cmbGameProfile.SelectedItem.Tag } else { "custom" }
            CustomGameExecutable = if ($txtCustomGame.Text) { $txtCustomGame.Text.Trim() } else { "" }
            MenuMode = $global:MenuMode
            AutoOptimize = $global:AutoOptimizeEnabled
            NetworkSettings = @{
                TCPAck = $chkAck.IsChecked
                DelAckTicks = $chkDelAckTicks.IsChecked
                NetworkThrottling = $chkThrottle.IsChecked
                NagleAlgorithm = $chkNagle.IsChecked
                TCPTimestamps = $chkTcpTimestamps.IsChecked
                ECN = $chkTcpECN.IsChecked
                RSS = $chkRSS.IsChecked
                RSC = $chkRSC.IsChecked
                AutoTuning = $chkTcpAutoTune.IsChecked

            }
            GamingSettings = @{
                Responsiveness = $chkResponsiveness.IsChecked
                GamesTask = $chkGamesTask.IsChecked
                GameDVR = $chkGameDVR.IsChecked
                FSE = $chkFSE.IsChecked
                GpuScheduler = $chkGpuScheduler.IsChecked
                TimerRes = $chkTimerRes.IsChecked
                VisualEffects = $chkVisualEffects.IsChecked
                Hibernation = $chkHibernation.IsChecked
            }
        }

        $saveDialog = New-Object Microsoft.Win32.SaveFileDialog
        $saveDialog.Filter = "JSON files (*.json)|*.json|All files (*.*)|*.*"
        $saveDialog.DefaultExt = ".json"
        $saveDialog.FileName = "KOALAConfig_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"

        if ($saveDialog.ShowDialog()) {
            $configJson = $config | ConvertTo-Json -Depth 10
            Set-Content -Path $saveDialog.FileName -Value $configJson -Encoding UTF8
            Log "Configuration exported to: $($saveDialog.FileName)" 'Success'

            [System.Windows.MessageBox]::Show(
                "Configuration exported successfully!`n`nLocation: $($saveDialog.FileName)",
                "Export Complete",
                'OK',
                'Information'
            )
        }
        Log "Failed to export configuration: $($_.Exception.Message)" 'Error'
    }

function Import-Configuration {
        $openDialog = New-Object Microsoft.Win32.OpenFileDialog
        $openDialog.Filter = "JSON files (*.json)|*.json|All files (*.*)|*.*"
        $openDialog.DefaultExt = ".json"

        if ($openDialog.ShowDialog()) {
            $configJson = Get-Content $openDialog.FileName -Raw
            $config = $configJson | ConvertFrom-Json

            # Apply configuration
            if ($config.GameProfile) {
                foreach ($item in $cmbGameProfile.Items) {
                    if ($item.Tag -eq $config.GameProfile) {
                        $cmbGameProfile.SelectedItem = $item
                        break

                    }
                }
            }

            if ($config.CustomGameExecutable) {
                $txtCustomGame.Text = $config.CustomGameExecutable
            }

            if ($config.MenuMode) {
                Switch-MenuMode -Mode $config.MenuMode
                # Menu mode control removed from header - mode managed through Options panel only
                # foreach ($item in $cmbMenuMode.Items) {
                #     if ($item.Tag -eq $config.MenuMode) {
                #         $cmbMenuMode.SelectedItem = $item
                #         break
                #     }
                # }
            }

            # Apply network settings
            if ($config.NetworkSettings) {
                $chkAck.IsChecked = $config.NetworkSettings.TCPAck
                $chkDelAckTicks.IsChecked = $config.NetworkSettings.DelAckTicks
                $chkThrottle.IsChecked = $config.NetworkSettings.NetworkThrottling
                $chkNagle.IsChecked = $config.NetworkSettings.NagleAlgorithm
                $chkTcpTimestamps.IsChecked = $config.NetworkSettings.TCPTimestamps
                $chkTcpECN.IsChecked = $config.NetworkSettings.ECN
                $chkRSS.IsChecked = $config.NetworkSettings.RSS
                $chkRSC.IsChecked = $config.NetworkSettings.RSC
                $chkTcpAutoTune.IsChecked = $config.NetworkSettings.AutoTuning
            }

            # Apply gaming settings
            if ($config.GamingSettings) {
                $chkResponsiveness.IsChecked = $config.GamingSettings.Responsiveness
                $chkGamesTask.IsChecked = $config.GamingSettings.GamesTask
                $chkGameDVR.IsChecked = $config.GamingSettings.GameDVR
                $chkFSE.IsChecked = $config.GamingSettings.FSE
                $chkGpuScheduler.IsChecked = $config.GamingSettings.GpuScheduler
                $chkTimerRes.IsChecked = $config.GamingSettings.TimerRes
                $chkVisualEffects.IsChecked = $config.GamingSettings.VisualEffects
                $chkHibernation.IsChecked = $config.GamingSettings.Hibernation
            }

            Log "Configuration imported from: $($openDialog.FileName)" 'Success'

            [System.Windows.MessageBox]::Show(
                "Configuration imported successfully!`n`nSettings have been applied.",
                "Import Complete",
                'OK',
                'Information'
            )
        }
        Log "Failed to import configuration: $($_.Exception.Message)" 'Error'
    }

