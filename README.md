# KOALA-UDP — Auto-Split (UTF-8 with BOM, adjusted mapping)

This build moves **Event Handlers**, **Initialize Application**, **Start Application**, and
**Invoke-PanelActions** sections into `gui.ps1` to avoid splitting `try { } catch { }` pairs
across files. All files are saved with **UTF-8 with BOM**.

## Quick Start
```powershell
.\Run-Me-First.ps1
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
