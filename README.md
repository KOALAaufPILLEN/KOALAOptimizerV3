# KOALA-UDP — Auto-Split (UTF-8 with BOM, adjusted mapping)

This build moves **Event Handlers**, **Initialize Application**, **Start Application**, and
**Invoke-PanelActions** sections into `gui.ps1` to avoid splitting `try { } catch { }` pairs
across files. All files are saved with **UTF-8 with BOM**.

## Quick Start
```powershell
.\Run-Me-First.ps1
```
