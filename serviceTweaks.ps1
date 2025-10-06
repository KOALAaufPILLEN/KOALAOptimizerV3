# ---------- Service Optimization Functions ----------

function Get-ServiceState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ServiceName
    )

    try {
        $service = Get-Service -Name $ServiceName -ErrorAction Stop
        return [ordered]@{
            Name        = $service.Name
            Status      = $service.Status
            StartType   = $service.StartType
            DisplayName = $service.DisplayName
        }
    } catch [System.InvalidOperationException] {
        Log "Get-ServiceState: Service '$ServiceName' not found on this system" 'Info'
        return $null
    } catch {
        Log "Get-ServiceState: Error retrieving '$ServiceName' - $($_.Exception.Message)" 'Warning'
        return $null
    }
}

function Disable-ServiceSafe {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ServiceName,
        [string]$DisplayName,
        [switch]$ForceStop
    )

    $state = Get-ServiceState -ServiceName $ServiceName
    if (-not $state) {
        return @{ Success = $false; Message = "$DisplayName not found" }
    }

    try {
        if ($ForceStop -and $state.Status -eq 'Running') {
            Stop-Service -Name $ServiceName -Force -ErrorAction Stop
            Log "$DisplayName service stopped" 'Info'
        }

        Set-Service -Name $ServiceName -StartupType Disabled -ErrorAction Stop
        Log "$DisplayName service disabled" 'Success'
        return @{ Success = $true }
    } catch {
        $message = "Failed to disable ${DisplayName}: $($_.Exception.Message)"
        Log $message 'Warning'
        return @{ Success = $false; Message = $message }
    }
}

function Apply-ServiceOptimizations {
    [CmdletBinding()]
    param(
        [hashtable]$Settings
    )

    $appliedCount = 0
    $serviceErrors = New-Object System.Collections.Generic.List[string]

    if ($Settings.XboxServices) {
        $xboxServices = @(
            @{ Name = 'XblGameSave'; Display = 'Xbox Game Save' },
            @{ Name = 'XblAuthManager'; Display = 'Xbox Auth Manager' },
            @{ Name = 'XboxGipSvc'; Display = 'Xbox Accessory Management' },
            @{ Name = 'XboxNetApiSvc'; Display = 'Xbox Networking' }
        )

        foreach ($svc in $xboxServices) {
            $result = Disable-ServiceSafe -ServiceName $svc.Name -DisplayName $svc.Display -ForceStop
            if ($result.Success) {
                $appliedCount++
            } elseif ($result.Message) {
                $serviceErrors.Add($result.Message)
            }
        }
    }

    if ($Settings.PrintSpooler) {
        $result = Disable-ServiceSafe -ServiceName 'Spooler' -DisplayName 'Print Spooler' -ForceStop
        if ($result.Success) {
            $appliedCount++
        } elseif ($result.Message) {
            $serviceErrors.Add($result.Message)
        }
    }

    if ($Settings.Superfetch) {
        $result = Disable-ServiceSafe -ServiceName 'SysMain' -DisplayName 'SysMain (Superfetch)' -ForceStop
        if ($result.Success) {
            $appliedCount++
        } elseif ($result.Message) {
            $serviceErrors.Add($result.Message)
        }
    }

    if ($Settings.Telemetry) {
        $telemetry = @(
            @{ Name = 'DiagTrack'; Display = 'Connected User Experiences and Telemetry' },
            @{ Name = 'dmwappushservice'; Display = 'dmwappushsvc' },
            @{ Name = 'WerSvc'; Display = 'Windows Error Reporting' }
        )

        foreach ($svc in $telemetry) {
            $result = Disable-ServiceSafe -ServiceName $svc.Name -DisplayName $svc.Display -ForceStop
            if ($result.Success) {
                $appliedCount++
            } elseif ($result.Message) {
                $serviceErrors.Add($result.Message)
            }
        }
    }

    if ($Settings.WindowsSearch) {
        $result = Disable-ServiceSafe -ServiceName 'WSearch' -DisplayName 'Windows Search' -ForceStop
        if ($result.Success) {
            $appliedCount++
        } elseif ($result.Message) {
            $serviceErrors.Add($result.Message)
        }
    }

    if ($Settings.UnneededServices) {
        $unneeded = @(
            @{ Name = 'Fax'; Display = 'Fax' },
            @{ Name = 'RemoteRegistry'; Display = 'Remote Registry' },
            @{ Name = 'MapsBroker'; Display = 'Maps Broker' },
            @{ Name = 'WMPNetworkSvc'; Display = 'Windows Media Player Network Sharing' },
            @{ Name = 'bthserv'; Display = 'Bluetooth Support' },
            @{ Name = 'TabletInputService'; Display = 'Touch Keyboard and Handwriting Panel' },
            @{ Name = 'TouchKeyboard'; Display = 'Touch Keyboard' }
        )

        foreach ($svc in $unneeded) {
            $result = Disable-ServiceSafe -ServiceName $svc.Name -DisplayName $svc.Display -ForceStop
            if ($result.Success) {
                $appliedCount++
            } elseif ($result.Message) {
                $serviceErrors.Add($result.Message)
            }
        }
    }

    if ($serviceErrors.Count -gt 0) {
        Log "Service optimization completed with $($serviceErrors.Count) issues. Review log for details." 'Warning'
    } else {
        Log 'Service optimization completed successfully with no errors.' 'Success'
    }

    return $appliedCount
}
