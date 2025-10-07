# KOALA Optimizer V3 (Split Edition)

This repository contains the split PowerShell modules that make up the KOALA Optimizer v3 experience. Each `.ps1` file focuses on a specific feature area (helpers, GUI, system tweaks, gaming automation, etc.) so that problems can be diagnosed without dealing with one monolithic script.

## Quick Start

```powershell
./Run-Me-First.ps1
```

The bootstrap script unblocks the local files, relaxes the execution policy for the current session, and launches `main.ps1`, which loads every module and opens the WPF interface.

## Updating or rebuilding a single file

Use `merger-update.ps1` to pull the latest split modules from GitHub and rebuild both the single-file script **and** a ready-to-run executable:

```powershell
pwsh ./merger-update.ps1
```

By default the script downloads the `main` branch of `KOALAaufPILLEN/KOALAOptimizerV3`, refreshes the local modules, and writes the merged `KOALAOptimizerV3-full.ps1` alongside a compiled `KOALAOptimizerV3-full.exe`. Override the source branch or output path with the optional parameters, pass `-SkipDownload` to merge the already-downloaded files, or `-SkipExecutable` if you only want the `.ps1` output.

Windows users who prefer sticking to Command Prompt can double-click `Run-Merger.bat` to launch the updater with a guided flow.
