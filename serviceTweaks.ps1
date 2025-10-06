# ---------- Service Optimization Functions ----------
function Apply-ServiceOptimizations {
    param([hashtable]$Settings)

    $count = 0
    $serviceErrors = @()

        if ($Settings.XboxServices) {
            $xboxServices = @("XblGameSave", "XblAuthManager", "XboxGipSvc", "XboxNetApiSvc")
            $xboxSuccessCount = 0
            foreach ($service in $xboxServices) {
                try {
                    $serviceStatus = Get-ServiceState -ServiceName $service
                    if ($serviceStatus) {
                        Stop-Service -Name $service -Force -ErrorAction Stop
                        Set-Service -Name $service -StartupType Disabled -ErrorAction Stop
                        $xboxSuccessCount++
                        Log "Xbox service '$service' disabled successfully" 'Info'
                    } else {
                        Log "Xbox service '$service' not found on this system" 'Warning'
                        $serviceErrors += "Xbox service '$service' not found"

                    }
                    Log "Failed to disable Xbox service '$service': $($_.Exception.Message)" 'Warning'
                    $serviceErrors += "Xbox service '$service': $($_.Exception.Message)"
                }
            }
            if ($xboxSuccessCount -gt 0) {
                $count++
                Log "Xbox services optimization completed: $xboxSuccessCount/$($xboxServices.Count) services disabled" 'Success'
            }
        }

        if ($Settings.PrintSpooler) {
                $serviceStatus = Get-ServiceState -ServiceName "Spooler"
                if ($serviceStatus) {
                    if ($serviceStatus.Status -eq 'Running') {
                        Stop-Service -Name "Spooler" -Force -ErrorAction Stop
                        Log "Print Spooler service stopped" 'Info'

                    }
                    Set-Service -Name "Spooler" -StartupType Disabled -ErrorAction Stop
                    $count++
                    Log "Print Spooler disabled successfully" 'Success'
                } else {
                    Log "Print Spooler service not found on this system" 'Warning'
                    $serviceErrors += "Print Spooler service not found"
                }
                Log "Failed to disable Print Spooler: $($_.Exception.Message)" 'Warning'
                $serviceErrors += "Print Spooler: $($_.Exception.Message)"

        if ($Settings.Superfetch) {
                $serviceStatus = Get-ServiceState -ServiceName "SysMain"
                if ($serviceStatus) {
                    if ($serviceStatus.Status -eq 'Running') {
                        Stop-Service -Name "SysMain" -Force -ErrorAction Stop
                        Log "SysMain (Superfetch) service stopped" 'Info'

                    }
                    Set-Service -Name "SysMain" -StartupType Disabled -ErrorAction Stop
                    $count++
                    Log "SysMain (Superfetch) disabled successfully" 'Success'
                } else {
                    Log "SysMain (Superfetch) service not found on this system" 'Warning'
                    $serviceErrors += "SysMain service not found"
                }
                Log "Failed to disable SysMain: $($_.Exception.Message)" 'Warning'
                $serviceErrors += "SysMain: $($_.Exception.Message)"

        if ($Settings.Telemetry) {
            $telemetryServices = @("DiagTrack", "dmwappushservice", "WerSvc")
            $telemetrySuccessCount = 0
            foreach ($service in $telemetryServices) {
                    $serviceStatus = Get-ServiceState -ServiceName $service
                    if ($serviceStatus) {
                        if ($serviceStatus.Status -eq 'Running') {
                            Stop-Service -Name $service -Force -ErrorAction Stop
                            Log "Telemetry service '$service' stopped" 'Info'

                        }
                        Set-Service -Name $service -StartupType Disabled -ErrorAction Stop
                        $telemetrySuccessCount++
                        Log "Telemetry service '$service' disabled successfully" 'Info'
                    } else {
                        Log "Telemetry service '$service' not found on this system" 'Warning'
                        $serviceErrors += "Telemetry service '$service' not found"
                    }
                    Log "Failed to disable telemetry service '$service': $($_.Exception.Message)" 'Warning'
                    $serviceErrors += "Telemetry service '$service': $($_.Exception.Message)"
                }
            if ($telemetrySuccessCount -gt 0) {
                $count++
                Log "Telemetry services optimization completed: $telemetrySuccessCount/$($telemetryServices.Count) services disabled" 'Success'
            }

        if ($Settings.WindowsSearch) {
                $serviceStatus = Get-ServiceState -ServiceName "WSearch"
                if ($serviceStatus) {
                    if ($serviceStatus.Status -eq 'Running') {
                        Stop-Service -Name "WSearch" -Force -ErrorAction Stop
                        Log "Windows Search service stopped" 'Info'

                    }
                    Set-Service -Name "WSearch" -StartupType Disabled -ErrorAction Stop
                    $count++
                    Log "Windows Search disabled successfully" 'Success'
                } else {
                    Log "Windows Search service not found on this system" 'Warning'
                    $serviceErrors += "Windows Search service not found"
                }
                Log "Failed to disable Windows Search: $($_.Exception.Message)" 'Warning'
                $serviceErrors += "Windows Search: $($_.Exception.Message)"

        if ($Settings.UnneededServices) {
            $unneededServices = @("Fax", "RemoteRegistry", "MapsBroker", "WMPNetworkSvc", "bthserv", "TabletInputService", "TouchKeyboard")
            $unneededSuccessCount = 0
            foreach ($service in $unneededServices) {
                    $serviceStatus = Get-ServiceState -ServiceName $service
                    if ($serviceStatus) {
                        if ($serviceStatus.Status -eq 'Running') {
                            Stop-Service -Name $service -Force -ErrorAction Stop
                            Log "Unneeded service '$service' stopped" 'Info'

                        }
                        Set-Service -Name $service -StartupType Disabled -ErrorAction Stop
                        $unneededSuccessCount++
                        Log "Unneeded service '$service' disabled successfully" 'Info'
                    } else {
                        Log "Unneeded service '$service' not found on this system (may already be removed)" 'Info'
                    }
                    Log "Failed to disable unneeded service '$service': $($_.Exception.Message)" 'Warning'
                    $serviceErrors += "Unneeded service '$service': $($_.Exception.Message)"
                }
            if ($unneededSuccessCount -gt 0) {
                $count++
                Log "Unneeded services optimization completed: $unneededSuccessCount/$($unneededServices.Count) services disabled" 'Success'
            }

        # Report summary of any errors encountered
        if ($serviceErrors.Count -gt 0) {
            Log "Service optimization completed with $($serviceErrors.Count) issues. Check individual service logs for details." 'Warning'
        } else {
            Log "Service optimization completed successfully with no errors" 'Success'

        Log "Service optimization error: $($_.Exception.Message)" 'Error'

    return $count

function Get-ServiceState {
    param([string]$ServiceName)

    if (-not $ServiceName) {
        Log "Get-ServiceState: Service name is required" 'Error'
        return $null
    }

        $service = Get-Service -Name $ServiceName -ErrorAction Stop
        return @{
            Name = $service.Name
            Status = $service.Status
            StartType = $service.StartType
            DisplayName = $service.DisplayName

        }
        Log "Get-ServiceState: Service '$ServiceName' not found on this system" 'Info'
        return $null
        Log "Get-ServiceState: Cannot access service '$ServiceName' - insufficient permissions or service is inaccessible" 'Warning'
        return $null
        Log "Get-ServiceState: Error getting service '$ServiceName': $($_.Exception.Message)" 'Warning'
        return $null
    }

