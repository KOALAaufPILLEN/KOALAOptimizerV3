# ---------- Network Optimization Functions ----------
function Apply-NetworkOptimizations {
    param([hashtable]$Settings)

    $count = 0

        if ($Settings.TCPAck) {
            # TCP ACK Frequency optimization
            $nicRoot = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces"
            if (Test-Path $nicRoot) {
                Get-ChildItem $nicRoot | ForEach-Object {
                    $nicPath = $_.PSPath
                    Set-Reg $nicPath "TcpAckFrequency" 'DWord' 1 -RequiresAdmin $true | Out-Null

                }
                $count++
                Log "TCP ACK Frequency optimized" 'Success'
            }
        }

        if ($Settings.DelAckTicks) {
            Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" "TcpDelAckTicks" 'DWord' 0 -RequiresAdmin $true | Out-Null
            $count++
            Log "Delayed ACK ticks disabled" 'Success'
        }

        if ($Settings.NetworkThrottling) {
            Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "NetworkThrottlingIndex" 'DWord' 0xFFFFFFFF -RequiresAdmin $true | Out-Null
            $count++
            Log "Network throttling disabled" 'Success'
        }

        if ($Settings.NagleAlgorithm) {
            Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" "TcpNoDelay" 'DWord' 1 -RequiresAdmin $true | Out-Null
            Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" "TCPNoDelay" 'DWord' 1 -RequiresAdmin $true | Out-Null
            $count++
            Log "Nagle algorithm disabled" 'Success'
        }

        if ($Settings.TCPTimestamps) {
                netsh int tcp set global timestamps=disabled | Out-Null
                $count++
                Log "TCP timestamps disabled" 'Success'
                Log "Failed to disable TCP timestamps" 'Warning'
            }
        }

        if ($Settings.ECN) {
                netsh int tcp set global ecncapability=disabled | Out-Null
                $count++
                Log "Explicit Congestion Notification disabled" 'Success'
                Log "Failed to disable ECN" 'Warning'
            }

        if ($Settings.RSS) {
                netsh int tcp set global rss=enabled | Out-Null
                $count++
                Log "Receive Side Scaling enabled" 'Success'
                Log "Failed to enable RSS" 'Warning'
            }

        if ($Settings.RSC) {
                netsh int tcp set global rsc=disabled | Out-Null
                $count++
                Log "Receive Segment Coalescing disabled" 'Success'
                Log "Failed to disable RSC" 'Warning'
            }

        if ($Settings.AutoTuning) {
                netsh int tcp set global autotuninglevel=normal | Out-Null
                $count++
                Log "TCP Auto-Tuning set to normal" 'Success'
                Log "Failed to set TCP auto-tuning" 'Warning'
            }

        Log "Network optimization error: $($_.Exception.Message)" 'Error'

    return $count

