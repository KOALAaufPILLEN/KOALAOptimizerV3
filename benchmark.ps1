# ---------- Benchmark Function ----------
function Start-QuickBenchmark {
    Log "Starting quick system benchmark..." 'Info'

        $startTime = Get-Date

        # CPU test
        $cpuStart = Get-Date
        $sum = 0
        for ($i = 0; $i -lt 1000000; $i++) { $sum += $i }
        $cpuTime = (Get-Date) - $cpuStart

        # Memory test
        $memStart = Get-Date
        $array = @()
        for ($i = 0; $i -lt 10000; $i++) { $array += Get-Random }
        $memTime = (Get-Date) - $memStart

        # Disk test
        $diskStart = Get-Date
        $testFile = Join-Path $env:TEMP "koala_bench_test.tmp"
        $testData = "x" * 1024 * 1024  # 1MB of data
        Set-Content -Path $testFile -Value $testData
        $diskWriteTime = (Get-Date) - $diskStart

        $diskReadStart = Get-Date
        Get-Content -Path $testFile | Out-Null
        $diskReadTime = (Get-Date) - $diskReadStart

        Remove-Item -Path $testFile -Force -ErrorAction SilentlyContinue

        $totalTime = (Get-Date) - $startTime

        $results = @"
Quick System Benchmark Results:

CPU Performance: $([math]::Round($cpuTime.TotalMilliseconds, 2)) ms
Memory Performance: $([math]::Round($memTime.TotalMilliseconds, 2)) ms
Disk Write: $([math]::Round($diskWriteTime.TotalMilliseconds, 2)) ms
Disk Read: $([math]::Round($diskReadTime.TotalMilliseconds, 2)) ms

Total Time: $([math]::Round($totalTime.TotalMilliseconds, 2)) ms

Note: Lower times indicate better performance.
These are basic tests for comparison purposes.
"@

        [System.Windows.MessageBox]::Show(
            $results,
            "Benchmark Results",
            'OK',
            'Information'
        )

        Log "Benchmark completed successfully" 'Success'

        Log "Benchmark failed: $($_.Exception.Message)" 'Error'
    }

