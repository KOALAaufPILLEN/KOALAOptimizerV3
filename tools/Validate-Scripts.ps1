<#!
.SYNOPSIS
    Validates every PowerShell script in the repository for parser errors and unbalanced delimiters.
.DESCRIPTION
    Uses the PowerShell parser to detect syntax errors and performs an additional delimiter balance
    check that ignores strings and both line and block comments. The script fails if any problems are
    detected and prints a compact summary of the offending files.
#>
[CmdletBinding()]
param(
    [Parameter()]
    [string]$Root = (Get-Location)
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $Root)) {
    throw "Root path '$Root' does not exist."
}

$resolvedRoot = (Resolve-Path -LiteralPath $Root).ProviderPath
Push-Location -LiteralPath $resolvedRoot
try {
    $script:parseFailures = New-Object System.Collections.Generic.List[object]
    $script:delimiterFailures = New-Object System.Collections.Generic.List[object]

    $pairs = @{
        '(' = ')'
        '[' = ']'
        '{' = '}'
    }
    $closing = @{}
    foreach ($entry in $pairs.GetEnumerator()) {
        $closing[$entry.Value] = $entry.Key
    }

    $scripts = Get-ChildItem -Filter '*.ps1' -File -Recurse | Sort-Object FullName
    foreach ($script in $scripts) {
        $errors = $null
        [System.Management.Automation.Language.Parser]::ParseFile($script.FullName, [ref]$null, [ref]$errors) | Out-Null
        if ($errors) {
            $script:parseFailures.Add([pscustomobject]@{
                Path = $script.FullName
                Errors = ($errors | ForEach-Object { $_.ToString() })
            })
        }

        $content = Get-Content -LiteralPath $script.FullName -Raw
        if ($null -eq $content) {
            $content = [string]::Empty
        }
        $stack = New-Object System.Collections.Generic.Stack[pscustomobject]
        $length = $content.Length
        $index = 0
        while ($index -lt $length) {
            $char = $content[$index]
            if ($char -eq "'" -or $char -eq '"') {
                $quote = $char
                $index++
                while ($index -lt $length) {
                    $current = $content[$index]
                    if ($current -eq '`') {
                        $index += 2
                        continue
                    }
                    if ($current -eq $quote) {
                        $index++
                        break
                    }
                    $index++
                }
                continue
            }

            if ($char -eq '#') {
                while ($index -lt $length -and $content[$index] -ne "`n") {
                    $index++
                }
                continue
            }

            if ($char -eq '<' -and ($index + 1) -lt $length -and $content[$index + 1] -eq '#') {
                $index += 2
                while ($index -lt $length - 1) {
                    if ($content[$index] -eq '#' -and $content[$index + 1] -eq '>') {
                        $index += 2
                        break
                    }
                    $index++
                }
                continue
            }

            if ($pairs.ContainsKey($char)) {
                $stack.Push([pscustomobject]@{ Char = $char; Index = $index })
                $index++
                continue
            }

            if ($closing.ContainsKey($char)) {
                if ($stack.Count -eq 0) {
                    $script:delimiterFailures.Add([pscustomobject]@{
                        Path = $script.FullName
                        Message = "Unmatched closing '$char' at offset $index"
                    })
                    break
                }

                $top = $stack.Pop()
                if ($pairs[$top.Char] -ne $char) {
                    $script:delimiterFailures.Add([pscustomobject]@{
                        Path = $script.FullName
                        Message = "Mismatched '$($top.Char)' and '$char' at offset $index"
                    })
                    break
                }
                $index++
                continue
            }

            $index++
        }

        if ($stack.Count -gt 0) {
            $remaining = $stack.Pop()
            $script:delimiterFailures.Add([pscustomobject]@{
                Path = $script.FullName
                Message = "Unclosed '$($remaining.Char)' at offset $($remaining.Index)"
            })
        }
    }

    if ($script:parseFailures.Count -eq 0 -and $script:delimiterFailures.Count -eq 0) {
        Write-Host "Validated $($scripts.Count) script(s). No syntax or delimiter issues detected." -ForegroundColor Green
        return
    }

    if ($script:parseFailures.Count -gt 0) {
        Write-Warning "Parser errors detected:"
        foreach ($failure in $script:parseFailures) {
            Write-Warning "  $($failure.Path)"
            foreach ($error in $failure.Errors) {
                Write-Warning "    $error"
            }
        }
    }

    if ($script:delimiterFailures.Count -gt 0) {
        Write-Warning "Delimiter balance issues detected:"
        foreach ($failure in $script:delimiterFailures) {
            Write-Warning "  $($failure.Path): $($failure.Message)"
        }
    }

    throw "Validation failed."
}
finally {
    Pop-Location
}
