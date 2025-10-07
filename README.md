# KOALA Optimizer V3 (Split Edition)

This repository contains the split PowerShell modules that make up the KOALA Optimizer v3 experience. Each `.ps1` file focuses on a specific feature area (helpers, GUI, system tweaks, gaming automation, etc.) so that problems can be diagnosed without dealing with one monolithic script.

## Quick Start

```powershell
./Run-Me-First.ps1
```

## Update or merge into a single script

To refresh every split module from GitHub and rebuild a single-file version of the
optimizer, run the helper script:

```powershell
pwsh .\merger-update.ps1
```

By default the script grabs the latest files from the `main` branch of
`KOALAaufPILLEN/KOALAOptimizerV3`, refreshes the local copies, and writes a merged
`KOALAOptimizerV3-full.ps1` alongside the split modules. Use `-Branch` or `-Output`
parameters to override the defaults, or `-SkipDownload` to merge already-downloaded
files.
