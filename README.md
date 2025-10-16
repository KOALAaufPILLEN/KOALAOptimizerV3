# 🐨 KOALA Optimizer V3 (Split Edition)

<div align="center">

[![Version](https://img.shields.io/badge/version-3.0-purple.svg?style=for-the-badge)]()
[![License](https://img.shields.io/badge/license-MIT-blue.svg?style=for-the-badge)](LICENSE)
[![Windows](https://img.shields.io/badge/platform-Windows-0078d4.svg?style=for-the-badge&logo=windows)]()
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-012456.svg?style=for-the-badge&logo=powershell)]()
[![Downloads](https://img.shields.io/github/downloads/KOALAaufPILLEN/KOALAOptimizerV3/total.svg?style=for-the-badge)](https://github.com/KOALAaufPILLEN/KOALAOptimizerV3/releases)
[![Stars](https://img.shields.io/github/stars/KOALAaufPILLEN/KOALAOptimizerV3.svg?style=for-the-badge)](https://github.com/KOALAaufPILLEN/KOALAOptimizerV3/stargazers)

</div>

**🚀 Die neueste Generation des KOALA Gaming Optimizers – modular, fehlertolerant und mit integrierter EXE-Erstellung!**

> ✅ **Modulares V3-Design** – Jede Funktionsgruppe liegt als eigene `.ps1` vor und kann separat getestet werden.
>
> ✅ **PS2EXE-Autobuild** – `merger-update.ps1` erstellt neben dem Gesamt-Skript automatisch eine eigenständige EXE.
>

<div align="center">
<em>PowerShell-basiertes Gaming-Toolkit mit automatischen Spielprofilen, Echtzeitüberwachung und schnellen Presets – jetzt besser wartbar als je zuvor.</em>
</div>

---

## ✨ Highlights

> 🎯 **One-Click Presets** – Sicherer Schnellstart für Netzwerk, System und Gaming.
>
> 🎮 **Auto Game Boost** – Umfangreiche Profile mit Hardware-Erkennung und Live-Optimierung.
>
> 🔧 **42+ Tweaks** – Registry-, Dienst- und Prozessanpassungen für niedrige Latenzen.
>
> 🧪 **Validierte Lade-Reihenfolge** – Module werden strukturiert geladen und mit Parser-Checks abgesichert.
>
> 🧩 **Modular Reload** – Fehler in einem Modul stoppen nicht mehr den kompletten Ablauf.

---

## 🚀 Schnellstart

```powershell
# Installation der Module & Vorbereitungen
./Run-Me-First.ps1

# GUI starten
pwsh ./main.ps1
```

### 🧰 Komplettskript & EXE bauen

```powershell
# Neuesten Stand aus dem Git-Repo beziehen und alles zusammenführen
pwsh ./merger-update.ps1

# Ohne neuen Download nur zusammenführen und EXE erzeugen
pwsh ./merger-update.ps1 -SkipDownload
```

> 💡 Das Skript erzeugt automatisch `KOALAOptimizerV3-full.ps1` sowie `KOALAOptimizerV3-full.exe` (via PS2EXE) im Root-Verzeichnis.

---

## 🎮 Game Profiles & Auto-Optimierung

- **Games Library Panel** scannt laufende Prozesse, erkennt Profile (z. B. CS2, Valorant, Apex, Cyberpunk) und
  wendet Prioritäten, Affinitäten sowie FPS-Optimierungen an.
- **GamesTweaks.ps1** wurde komplett neu strukturiert und kann dank Parser-Prüfung ohne Syntaxfehler ausgeführt werden.
- **Auto Optimize Toggle** im GUI aktiviert die Hintergrundüberwachung und wendet Profilanpassungen live an.

---

## 🧱 Modulübersicht

| Modul                 | Zweck                                                     |
|-----------------------|-----------------------------------------------------------|
| `helpers.ps1`         | Logging, UI-Helfer, Clipboard, Themenverwaltung           |
| `systemTweaks.ps1`    | Dienste, Stromsparpläne, Scheduler-Optimierungen          |
| `networkTweaks.ps1`   | TCP/IP-Tuning, Latenzreduzierung, Nagle-Off               |
| `serviceTweaks.ps1`   | Hintergrunddienste deaktivieren/reaktivieren             |
| `gamesTweaks.ps1`     | Spielprofile, FPS-Presets, GPU Scheduling, DX11/DX12      |
| `backup.ps1`          | Sicherung & Wiederherstellung der KOALA-Konfiguration     |
| `benchmark.ps1`       | Startet synthetische Benchmarks & Validierungs-Tools      |
| `gui.ps1`             | WPF-Oberfläche inkl. Navigation und Log                  |
| `main.ps1`            | Einstiegsdatei, lädt Module, startet GUI/CLI              |
| `merger-update.ps1`   | Lädt Repo-Dateien, führt sie zusammen, baut EXE (PS2EXE)  |

---

## 🧪 Tests & Qualitätsmaßnahmen

- ✅ Alle Module werden mit `tools/Validate-Scripts.ps1` geprüft (`pwsh ./tools/Validate-Scripts.ps1`).
- ✅ `gamesTweaks.ps1` & `gui.ps1` sind UTF-8 mit BOM gespeichert – Emojis bleiben stabil.
- ✅ `helpers.ps1` basiert auf der funktionierenden V2-Codebasis und wurde für V3 übernommen.

---

## 🛣️ Roadmap V3

| Bereich                   | Status          |
|---------------------------|-----------------|
| Weitere Spielprofile      | 🟡 In Arbeit     |
| Automatische Serviceprofile | 🟡 In Arbeit   |
| Zusätzliche Presets       | 🔵 Geplant       |
| Erweiterter Benchmark     | 🔵 Geplant       |

---

## 📜 Lizenz

<div align="center">
Dieses Projekt steht unter der **MIT-Lizenz**.

[![MIT License](https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge)](LICENSE)
</div>

---

<div align="center">
<sub>Made with 🐨 by the KOALA Team | © 2024 KOALA Gaming Optimizer</sub>
</div>
