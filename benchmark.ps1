# ---------- Benchmark Function ----------
function Start-QuickBenchmark {
    [CmdletBinding()]
    param(
        [string]$ExternalBenchmark
    )

    Log 'Starting quick system benchmark...' 'Info'

    $results = [ordered]@{}
    $startTime = Get-Date

    try {
        # CPU test
        $cpuStart = Get-Date
        $sum = 0
        for ($i = 0; $i -lt 1000000; $i++) { $sum += $i }
        $results.CPU = ((Get-Date) - $cpuStart).TotalMilliseconds

        # Memory test
        $memStart = Get-Date
        $array = New-Object System.Collections.Generic.List[int]
        for ($i = 0; $i -lt 10000; $i++) { [void]$array.Add((Get-Random)) }
        $results.Memory = ((Get-Date) - $memStart).TotalMilliseconds

        # Disk write/read test
        $testFile = Join-Path $env:TEMP "koala_bench_test_$(Get-Date -Format 'yyyyMMddHHmmss').tmp"
        try {
            $diskWriteStart = Get-Date
            Set-Content -Path $testFile -Value ('x' * 1MB) -Encoding Ascii
            $results.DiskWrite = ((Get-Date) - $diskWriteStart).TotalMilliseconds

            $diskReadStart = Get-Date
            Get-Content -Path $testFile | Out-Null
            $results.DiskRead = ((Get-Date) - $diskReadStart).TotalMilliseconds
        }
        finally {
            Remove-Item -Path $testFile -Force -ErrorAction SilentlyContinue
        }

        # winsat integration when available
        $winsatOutput = $null
        $winsat = Get-Command 'winsat.exe' -ErrorAction SilentlyContinue
        if ($winsat) {
            try {
                $tempFile = Join-Path $env:TEMP "koala_winsat_$(Get-Date -Format 'yyyyMMddHHmmss').txt"
                $psi = Start-Process -FilePath $winsat.Source -ArgumentList 'cpuformal' -NoNewWindow -Wait -PassThru -RedirectStandardOutput $tempFile -ErrorAction Stop
                if ($psi.ExitCode -eq 0 -and (Test-Path $tempFile)) {
                    $winsatOutput = Get-Content -Path $tempFile -Raw
                    $results.WinSAT = 'cpuformal completed'
                }
                else {
                    $results.WinSAT = "cpuformal exited with code $($psi.ExitCode)"
                }
            }
            catch {
                $results.WinSAT = "cpuformal failed: $($_.Exception.Message)"
            }
            finally {
                if ($tempFile) { Remove-Item -Path $tempFile -Force -ErrorAction SilentlyContinue }
            }
        }
        elseif ($ExternalBenchmark) {
            if (-not (Test-Path $ExternalBenchmark)) {
                $results.External = 'External benchmark executable not found.'
            }
            else {
                try {
                    $tempExternal = Join-Path $env:TEMP "koala_external_bench_$(Get-Date -Format 'yyyyMMddHHmmss').log"
                    $proc = Start-Process -FilePath $ExternalBenchmark -ArgumentList @() -NoNewWindow -Wait -PassThru -RedirectStandardOutput $tempExternal -ErrorAction Stop
                    $results.External = if ($proc.ExitCode -eq 0) { 'Completed successfully' } else { "Exited with code $($proc.ExitCode)" }
                    if (Test-Path $tempExternal) {
                        $winsatOutput = (Get-Content -Path $tempExternal -Raw)
                    }
                }
                catch {
                    $results.External = "Failed to run external benchmark: $($_.Exception.Message)"
                }
                finally {
                    if ($tempExternal) { Remove-Item -Path $tempExternal -Force -ErrorAction SilentlyContinue }
                }
            }
        }

        $totalTime = (Get-Date) - $startTime
        $summary = @()
        $summary += 'Quick System Benchmark Results:'
        $summary += ''
        $summary += "CPU Performance: $([math]::Round($results.CPU, 2)) ms"
        $summary += "Memory Performance: $([math]::Round($results.Memory, 2)) ms"
        $summary += "Disk Write: $([math]::Round($results.DiskWrite, 2)) ms"
        $summary += "Disk Read: $([math]::Round($results.DiskRead, 2)) ms"
        if ($results.Contains('WinSAT')) { $summary += "WinSAT CPU: $($results.WinSAT)" }
        if ($results.Contains('External')) { $summary += "External Benchmark: $($results.External)" }
        $summary += ''
        $summary += "Total Time: $([math]::Round($totalTime.TotalMilliseconds, 2)) ms"
        $summary += ''
        $summary += 'Note: Lower times indicate better performance.'
        $summary += 'These are basic tests for comparison purposes.'

        [System.Windows.MessageBox]::Show($summary -join [Environment]::NewLine, 'Benchmark Results', 'OK', 'Information') | Out-Null

        if ($winsatOutput) {
            Log "WinSAT output:`n$winsatOutput" 'Info'
        }

        Log 'Benchmark completed successfully' 'Success'
    }
    catch {
        Log "Benchmark failed: $($_.Exception.Message)" 'Error'
        throw
    }
}
