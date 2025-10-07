# KOALA Optimizer – backup and configuration helpers

function Get-NetshTcpGlobal {
    <#
        .SYNOPSIS
        Return the current TCP stack configuration that `netsh int tcp show global` exposes.
    #>
    [CmdletBinding()]
    param()

    $settings = @{}

    try {
        $output = netsh int tcp show global 2>$null
        foreach ($line in $output) {
            if ($line -match '^\s*(.+?)\s*:\s*(.+?)\s*$') {
                $settings[$matches[1].Trim()] = $matches[2].Trim()
            }
        }
    } catch {
        Log "Unable to read TCP global state: $($_.Exception.Message)" 'Warning'
    }

    return $settings
}

function Create-RegFile {
    <#
        .SYNOPSIS
        Persist registry data from a backup payload as a .reg file.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$BackupData,
        [Parameter(Mandatory)]
        [string]$OutputPath
    )

    try {
        $builder = @()
        $builder += 'Windows Registry Editor Version 5.00'
        $builder += ''
        $builder += '; KOALA Gaming Optimizer – Registry Backup'
        $builder += "; Created: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        $builder += "; Version: $($BackupData.Version)"
        $builder += ''

        foreach ($regPath in $BackupData.Registry.GetEnumerator()) {
            $path = $regPath.Key -replace '^HKLM:', '[HKEY_LOCAL_MACHINE' -replace '^HKCU:', '[HKEY_CURRENT_USER' -replace '^HKCR:', '[HKEY_CLASSES_ROOT' -replace '^HKU:', '[HKEY_USERS' -replace '^HKCC:', '[HKEY_CURRENT_CONFIG'
            $builder += "$path]"

            foreach ($entry in $regPath.Value.GetEnumerator()) {
                $keyName = [string]$entry.Key
                if ($null -ne $entry.Value) {
                    $formatted = '{0:x8}' -f [uint32]$entry.Value
                    $builder += '"{0}"=dword:{1}' -f $keyName, $formatted
                } else {
                    $builder += '"{0}"=-' -f $keyName
                }
            }

            $builder += ''
        }

        foreach ($nic in $BackupData.RegistryNICs.GetEnumerator()) {
            $path = $nic.Key -replace '^HKLM:', '[HKEY_LOCAL_MACHINE'
            $builder += "$path]"
            if ($null -ne $nic.Value.TcpAckFrequency) {
                $formattedAck = '{0:x8}' -f [uint32]$nic.Value.TcpAckFrequency
                $builder += '"TcpAckFrequency"=dword:{0}' -f $formattedAck
            }
            if ($null -ne $nic.Value.TCPNoDelay) {
                $formattedNodelay = '{0:x8}' -f [uint32]$nic.Value.TCPNoDelay
                $builder += '"TCPNoDelay"=dword:{0}' -f $formattedNodelay
            }
            $builder += ''
        }

        $builder | Set-Content -Path $OutputPath -Encoding Unicode
        Log "Registry backup saved to $OutputPath" 'Success'
    } catch {
        Log "Failed to build registry export: $($_.Exception.Message)" 'Error'
        throw
    }
}

function Create-Backup {
    <#
        .SYNOPSIS
        Capture registry, service, TCP and power configuration to a user selected location.
    #>
    [CmdletBinding()]
    param()

    Log 'Creating comprehensive backup with user-selected location...' 'Info'

    $dialog = New-Object Microsoft.Win32.SaveFileDialog
    $dialog.Title = 'Select Backup Location'
    $dialog.Filter = 'JSON files (*.json)|*.json|Registry files (*.reg)|*.reg|All files (*.*)|*.*'
    $dialog.DefaultExt = '.json'
    $dialog.FileName = "KOALA_Backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    $dialog.InitialDirectory = [Environment]::GetFolderPath('MyDocuments')

    if (-not $dialog.ShowDialog()) {
        Log 'Backup cancelled by user' 'Info'
        return
    }

    $selectedPath = $dialog.FileName
    $selectedExtension = [System.IO.Path]::GetExtension($selectedPath).ToLowerInvariant()

    $backupData = [ordered]@{
        Timestamp       = Get-Date
        Version         = '3.0'
        GPU             = Get-GPUVendor
        AdminPrivileges = Test-AdminPrivileges
        Registry        = @{}
        RegistryNICs    = @{}
        Services        = @{}
        NetshTcp        = @{}
        PowerSettings   = @{}
    }

    $regList = @(
        @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile'; Name = 'SystemResponsiveness' }
        @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile'; Name = 'NetworkThrottlingIndex' }
        @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games'; Name = 'GPU Priority' }
        @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games'; Name = 'Priority' }
        @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games'; Name = 'Scheduling Category' }
        @{ Path = 'HKCU:\System\GameConfigStore'; Name = 'GameDVR_Enabled' }
        @{ Path = 'HKCU:\System\GameConfigStore'; Name = 'GameDVR_FSEBehaviorMode' }
        @{ Path = 'HKCU:\System\GameConfigStore'; Name = 'GameDVR_FSEBehavior' }
        @{ Path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR'; Name = 'AppCaptureEnabled' }
        @{ Path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR'; Name = 'GameDVR_Enabled' }
    )

    foreach ($entry in $regList) {
        try {
            $value = Get-Reg $entry.Path $entry.Name
            if (-not $backupData.Registry.ContainsKey($entry.Path)) {
                $backupData.Registry[$entry.Path] = @{}
            }
            $backupData.Registry[$entry.Path][$entry.Name] = $value
        } catch {
            Log "Failed to read $($entry.Path)::$($entry.Name): $($_.Exception.Message)" 'Warning'
        }
    }

    $nicRoot = 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces'
    if (Test-Path $nicRoot) {
        Get-ChildItem $nicRoot | ForEach-Object {
            $nicPath = $_.PSPath
            $ack = Get-Reg $nicPath 'TcpAckFrequency'
            $nodelay = Get-Reg $nicPath 'TCPNoDelay'
            if ($null -ne $ack -or $null -ne $nodelay) {
                $backupData.RegistryNICs[$nicPath] = @{
                    TcpAckFrequency = $ack
                    TCPNoDelay      = $nodelay
                }
            }
        }
    }

    $svcTargets = @(
        'XblGameSave','XblAuthManager','XboxGipSvc','XboxNetApiSvc',
        'Spooler','SysMain','DiagTrack','WSearch','NvTelemetryContainer',
        'AMD External Events','Fax','RemoteRegistry','MapsBroker',
        'WMPNetworkSvc','WpnUserService','bthserv','TabletInputService',
        'TouchKeyboard','WerSvc','PcaSvc','Themes'
    )

    foreach ($serviceName in $svcTargets) {
        $service = Get-ServiceState $serviceName
        if ($service) {
            $backupData.Services[$service.Name] = $service
        }
    }

    $backupData.NetshTcp = Get-NetshTcpGlobal

    try {
        $scheme = (powercfg /getactivescheme 2>$null)
        if ($scheme) {
            $backupData.PowerSettings = @{ ActivePowerScheme = ($scheme -replace '^.*: ', '') -replace ' \(.*\)', '' }
        }
    } catch {
        Log "Unable to capture power scheme: $($_.Exception.Message)" 'Warning'
    }

    try {
        switch ($selectedExtension) {
            '.json' {
                $json = $backupData | ConvertTo-Json -Depth 10
                Set-Content -Path $selectedPath -Value $json -Encoding UTF8
                $regPath = $selectedPath -replace '\.json$', '.reg'
                Create-RegFile -BackupData $backupData -OutputPath $regPath
                $message = "JSON backup saved to:`n$selectedPath`n`nRegistry export:`n$regPath"
                break
            }
            '.reg' {
                Create-RegFile -BackupData $backupData -OutputPath $selectedPath
                $jsonPath = $selectedPath -replace '\.reg$', '.json'
                $json = $backupData | ConvertTo-Json -Depth 10
                Set-Content -Path $jsonPath -Value $json -Encoding UTF8
                $message = "Registry backup saved to:`n$selectedPath`n`nJSON copy:`n$jsonPath"
                $selectedPath = $jsonPath
                break
            }
            default {
                $json = $backupData | ConvertTo-Json -Depth 10
                Set-Content -Path $selectedPath -Value $json -Encoding UTF8
                $message = "Backup saved to:`n$selectedPath"
                break
            }
        }

        $global:BackupPath = $selectedPath
        [System.Windows.MessageBox]::Show($message, 'Backup Complete', 'OK', 'Information') | Out-Null
        Log "Backup saved successfully to $selectedPath" 'Success'
    } catch {
        Log "Failed to save backup: $($_.Exception.Message)" 'Error'
        [System.Windows.MessageBox]::Show("Failed to save backup:`n$($_.Exception.Message)", 'Backup Failed', 'OK', 'Error') | Out-Null
    }
}

function Restore-FromBackup {
    <#
        .SYNOPSIS
        Restore the system state from a previously generated backup file.
    #>
    [CmdletBinding()]
    param(
        [string]$Path = $global:BackupPath
    )

    if (-not $Path -or -not (Test-Path $Path)) {
        Log "No backup file found at: $Path" 'Error'
        [System.Windows.MessageBox]::Show('No backup file was found. Create a backup before attempting to restore.', 'Backup Not Found', 'OK', 'Warning') | Out-Null
        return $false
    }

    try {
        $backupData = Get-Content -Path $Path -Raw | ConvertFrom-Json

        foreach ($regPath in $backupData.Registry.GetEnumerator()) {
            foreach ($entry in $regPath.Value.GetEnumerator()) {
                if ($null -ne $entry.Value) {
                    Set-Reg $regPath.Key $entry.Key 'DWord' $entry.Value -RequiresAdmin $true | Out-Null
                } else {
                    Remove-RegValue -Path $regPath.Key -Name $entry.Key -RequiresAdmin $true
                }
            }
        }

        foreach ($nic in $backupData.RegistryNICs.GetEnumerator()) {
            if ($nic.Value.TcpAckFrequency) {
                Set-Reg $nic.Key 'TcpAckFrequency' 'DWord' $nic.Value.TcpAckFrequency -RequiresAdmin $true | Out-Null
            }
            if ($nic.Value.TCPNoDelay) {
                Set-Reg $nic.Key 'TCPNoDelay' 'DWord' $nic.Value.TCPNoDelay -RequiresAdmin $true | Out-Null
            }
        }

        foreach ($service in $backupData.Services.GetEnumerator()) {
            Set-Service -Name $service.Key -StartupType $service.Value.StartType -ErrorAction SilentlyContinue
            if ($service.Value.Status -eq 'Running') {
                Start-Service -Name $service.Key -ErrorAction SilentlyContinue
            } else {
                Stop-Service -Name $service.Key -ErrorAction SilentlyContinue
            }
        }

        Log 'Backup restored successfully.' 'Success'
        [System.Windows.MessageBox]::Show('Backup restored successfully.', 'Restore Complete', 'OK', 'Information') | Out-Null
        return $true
    } catch {
        Log "Failed to restore backup: $($_.Exception.Message)" 'Error'
        [System.Windows.MessageBox]::Show("Failed to restore backup:`n$($_.Exception.Message)", 'Restore Failed', 'OK', 'Error') | Out-Null
        return $false
    }
}

function Export-Configuration {
    <#
        .SYNOPSIS
        Persist the current UI selections and runtime flags to a JSON configuration file.
    #>
    [CmdletBinding()]
    param()

    try {
        $config = [ordered]@{
            Timestamp            = Get-Date
            Version              = '3.0'
            GameProfile          = if ($cmbGameProfile.SelectedItem) { $cmbGameProfile.SelectedItem.Tag } else { 'custom' }
            CustomGameExecutable = if ($txtCustomGame.Text) { $txtCustomGame.Text.Trim() } else { '' }
            MenuMode             = $global:MenuMode
            AutoOptimize         = $global:AutoOptimizeEnabled
            NetworkSettings      = @{
                TCPAck          = $chkAck.IsChecked
                DelAckTicks     = $chkDelAckTicks.IsChecked
                NetworkThrottle = $chkThrottle.IsChecked
                NagleAlgorithm  = $chkNagle.IsChecked
                TCPTimestamps   = $chkTcpTimestamps.IsChecked
                ECN             = $chkTcpECN.IsChecked
                RSS             = $chkRSS.IsChecked
                RSC             = $chkRSC.IsChecked
                AutoTuning      = $chkTcpAutoTune.IsChecked
            }
            GamingSettings = @{
                Responsiveness = $chkResponsiveness.IsChecked
                GamesTask      = $chkGamesTask.IsChecked
                GameDVR        = $chkGameDVR.IsChecked
                FSE            = $chkFSE.IsChecked
                GpuScheduler   = $chkGpuScheduler.IsChecked
                TimerRes       = $chkTimerRes.IsChecked
                VisualEffects  = $chkVisualEffects.IsChecked
                Hibernation    = $chkHibernation.IsChecked
            }
        }

        $dialog = New-Object Microsoft.Win32.SaveFileDialog
        $dialog.Filter = 'JSON files (*.json)|*.json|All files (*.*)|*.*'
        $dialog.DefaultExt = '.json'
        $dialog.FileName = "KOALAConfig_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"

        if ($dialog.ShowDialog()) {
            $config | ConvertTo-Json -Depth 10 | Set-Content -Path $dialog.FileName -Encoding UTF8
            Log "Configuration exported to: $($dialog.FileName)" 'Success'
            [System.Windows.MessageBox]::Show("Configuration exported to:`n$($dialog.FileName)", 'Export Complete', 'OK', 'Information') | Out-Null
        }
    } catch {
        Log "Failed to export configuration: $($_.Exception.Message)" 'Error'
        [System.Windows.MessageBox]::Show("Failed to export configuration:`n$($_.Exception.Message)", 'Export Failed', 'OK', 'Error') | Out-Null
    }
}

function Import-Configuration {
    <#
        .SYNOPSIS
        Load a JSON configuration file and apply the captured UI selections.
    #>
    [CmdletBinding()]
    param()

    try {
        $dialog = New-Object Microsoft.Win32.OpenFileDialog
        $dialog.Filter = 'JSON files (*.json)|*.json|All files (*.*)|*.*'
        $dialog.DefaultExt = '.json'

        if (-not $dialog.ShowDialog()) {
            return
        }

        $config = Get-Content -Path $dialog.FileName -Raw | ConvertFrom-Json

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
        }

        if ($config.NetworkSettings) {
            $chkAck.IsChecked            = $config.NetworkSettings.TCPAck
            $chkDelAckTicks.IsChecked    = $config.NetworkSettings.DelAckTicks
            $chkThrottle.IsChecked       = $config.NetworkSettings.NetworkThrottle
            $chkNagle.IsChecked          = $config.NetworkSettings.NagleAlgorithm
            $chkTcpTimestamps.IsChecked  = $config.NetworkSettings.TCPTimestamps
            $chkTcpECN.IsChecked         = $config.NetworkSettings.ECN
            $chkRSS.IsChecked            = $config.NetworkSettings.RSS
            $chkRSC.IsChecked            = $config.NetworkSettings.RSC
            $chkTcpAutoTune.IsChecked    = $config.NetworkSettings.AutoTuning
        }

        if ($config.GamingSettings) {
            $chkResponsiveness.IsChecked = $config.GamingSettings.Responsiveness
            $chkGamesTask.IsChecked      = $config.GamingSettings.GamesTask
            $chkGameDVR.IsChecked        = $config.GamingSettings.GameDVR
            $chkFSE.IsChecked            = $config.GamingSettings.FSE
            $chkGpuScheduler.IsChecked   = $config.GamingSettings.GpuScheduler
            $chkTimerRes.IsChecked       = $config.GamingSettings.TimerRes
            $chkVisualEffects.IsChecked  = $config.GamingSettings.VisualEffects
            $chkHibernation.IsChecked    = $config.GamingSettings.Hibernation
        }

        Log "Configuration imported from: $($dialog.FileName)" 'Success'
        [System.Windows.MessageBox]::Show('Configuration imported successfully.', 'Import Complete', 'OK', 'Information') | Out-Null
    } catch {
        Log "Failed to import configuration: $($_.Exception.Message)" 'Error'
        [System.Windows.MessageBox]::Show("Failed to import configuration:`n$($_.Exception.Message)", 'Import Failed', 'OK', 'Error') | Out-Null
    }
}
