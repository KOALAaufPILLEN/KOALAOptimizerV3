# KOALA Optimizer V3 (Split Edition)

This repository contains the split PowerShell modules that make up the KOALA Optimizer v3 experience. Each `.ps1` file focuses on a specific feature area (helpers, GUI, system tweaks, gaming automation, etc.) so that problems can be diagnosed without dealing with one monolithic script.

## Quick Start

```powershell
./Run-Me-First.ps1
```

The bootstrap script unblocks the local files, relaxes the execution policy for the current session, and launches `main.ps1`, which loads every module and opens the WPF interface.

## Updating or rebuilding a single file

Use `merger-update.ps1` to pull the latest split modules from GitHub and rebuild the single-file version of the optimizer:

```powershell
pwsh ./merger-update.ps1
```

By default the script downloads the `main` branch of `KOALAaufPILLEN/KOALAOptimizerV3`, refreshes the local modules, and writes the merged `KOALAOptimizerV3-full.ps1` alongside them. Override the source branch or output path with the optional parameters, or pass `-SkipDownload` to merge the already-downloaded files.
