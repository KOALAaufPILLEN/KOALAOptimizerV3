# ---------- Network Optimization Functions ----------
function Apply-NetworkOptimizations {
    [CmdletBinding()]
    param(
        [hashtable]$Settings
    )

    if (-not $Settings) {
        return 0
    }

    $appliedCount = 0
    $netsh = Get-Command -Name 'netsh.exe' -ErrorAction SilentlyContinue

    if ($Settings.TCPAck) {
        $nicRoot = 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces'
        if (Test-Path $nicRoot) {
            Get-ChildItem -Path $nicRoot -ErrorAction SilentlyContinue | ForEach-Object {
                $nicPath = $_.PSPath
                if (-not $nicPath) { return }

                try {
                    if (Set-Reg -Path $nicPath -Name 'TcpAckFrequency' -Type 'DWord' -Value 1 -RequiresAdmin) {
                        $script:LastNetworkRegistry = $nicPath
                    }
                }
                catch {
                    Log "Failed to configure TcpAckFrequency at ${nicPath}: $($_.Exception.Message)" 'Warning'
                }
            }

            Log 'TCP ACK frequency optimized across detected adapters' 'Success'
            $appliedCount++
        }
        else {
            Log "Network adapter registry root not found at $nicRoot" 'Warning'
        }
    }

    if ($Settings.DelAckTicks) {
        if (Set-Reg -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters' -Name 'TcpDelAckTicks' -Type 'DWord' -Value 0 -RequiresAdmin) {
            Log 'Delayed ACK ticks disabled' 'Success'
            $appliedCount++
        }
    }

    if ($Settings.NetworkThrottling) {
        if (Set-Reg -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile' -Name 'NetworkThrottlingIndex' -Type 'DWord' -Value 0xFFFFFFFF -RequiresAdmin) {
            Log 'Network throttling disabled' 'Success'
            $appliedCount++
        }
    }

    if ($Settings.NagleAlgorithm) {
        if ((Set-Reg -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters' -Name 'TcpNoDelay' -Type 'DWord' -Value 1 -RequiresAdmin) -and
            (Set-Reg -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters' -Name 'TCPNoDelay' -Type 'DWord' -Value 1 -RequiresAdmin)) {
            Log 'Nagle algorithm disabled' 'Success'
            $appliedCount++
        }
    }

    if ($netsh) {
        if ($Settings.TCPTimestamps) {
            try {
                & $netsh.Path int tcp set global timestamps=disabled | Out-Null
                Log 'TCP timestamps disabled' 'Success'
                $appliedCount++
            }
            catch {
                Log "Failed to disable TCP timestamps: $($_.Exception.Message)" 'Warning'
            }
        }

        if ($Settings.ECN) {
            try {
                & $netsh.Path int tcp set global ecncapability=disabled | Out-Null
                Log 'Explicit Congestion Notification disabled' 'Success'
                $appliedCount++
            }
            catch {
                Log "Failed to disable ECN: $($_.Exception.Message)" 'Warning'
            }
        }

        if ($Settings.RSS) {
            try {
                & $netsh.Path int tcp set global rss=enabled | Out-Null
                Log 'Receive Side Scaling enabled' 'Success'
                $appliedCount++
            }
            catch {
                Log "Failed to enable RSS: $($_.Exception.Message)" 'Warning'
            }
        }

        if ($Settings.RSC) {
            try {
                & $netsh.Path int tcp set global rsc=disabled | Out-Null
                Log 'Receive Segment Coalescing disabled' 'Success'
                $appliedCount++
            }
            catch {
                Log "Failed to disable RSC: $($_.Exception.Message)" 'Warning'
            }
        }

        if ($Settings.AutoTuning) {
            try {
                & $netsh.Path int tcp set global autotuninglevel=normal | Out-Null
                Log 'TCP Auto-Tuning set to normal' 'Success'
                $appliedCount++
            }
            catch {
                Log "Failed to adjust TCP auto-tuning: $($_.Exception.Message)" 'Warning'
            }
        }
    }
    else {
        Log 'netsh.exe not found. Skipping socket-level tuning commands.' 'Warning'
    }

    return $appliedCount
}
