# 🎮 Tinkerlands Mods Collection

A personal collection of high-quality, lightweight, and performance-driven Quality of Life (QoL) mods for **Tinkerlands**. Continuously maintained and updated with new features and enhancements whenever inspiration strikes!

[![Author](https://img.shields.io/badge/Author-Telles0808-blue.svg)](https://github.com/telles0808)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/Platform-Windows-lightgrey.svg)]()
[![Game](https://img.shields.io/badge/Game-Tinkerlands-orange.svg)]()

---

## 📦 Available Mods

| Mod | Description | Status | Download |
| :--- | :--- | :---: | :---: |
| **[NPC Radar (v1.3)](#-npc-radar-v13)** | Real-time NPC tracker with HUD toggle button, custom portraits, and distance indicators. Zero FPS lag. | ✅ Stable | [⬇️ Download Radar.mod](https://github.com/telles0808/Tinkerlands-Mods/raw/main/releases/Radar.mod) |
| **[Fog (v1.0)](#-fog-v10)** | Modifies the minimap fog layer to provide 95% translucent visibility across explored areas. | ✅ Stable | [⬇️ Download Fog.mod](https://github.com/telles0808/Tinkerlands-Mods/raw/main/releases/Fog.mod) |
| **[RealClock (v1.0)](#-realclock-v10)** | Displays the computer's real local time in a responsive 24-hour HUD clock without requiring the Clock accessory. | ✅ Stable | [⬇️ Download RealClock.mod](https://github.com/telles0808/Tinkerlands-Mods/raw/main/releases/RealClock.mod) |

---

## 📥 Installation

1. Download the `.mod` file for the desired mod from the [Releases](releases/) folder (or individual mod `dist/` folders).
2. Locate your **Tinkerlands** installation folder:
   ```
   C:\Program Files (x86)\Steam\steamapps\common\Tinkerlands\mods\
   ```
   *(or wherever your Steam library is located)*
3. Paste the `.mod` file directly inside the `mods` folder.
4. **💡 (Recommended) Clear Game Cache:** To ensure newly added or updated mods are immediately reloaded by the engine without using cached scripts:
   * Press `Win + R`, paste `%LOCALAPPDATA%\Tinkerlands\temp` and press **Enter**.
   * Delete all cached files inside this `temp` folder.
5. Launch the game!

---

## 🛠️ Mod Details

### 📡 NPC Radar (v1.3)
* **Dynamic Off-Screen Tracking:** Shows directional arrows with character portraits pointing to all NPCs on the island.
* **In-Screen Identification:** Displays NPC portraits and names directly above entities within your field of view.
* **On/Off Toggle Button:** Integrated cleanly onto the HUD near the minimap (click the Sonar icon to toggle).
* **Native $O(1)$ ID Lookup:** Resolves character portraits via the game's internal `npcID` database table, ensuring full compatibility with localized and generic humanoid NPCs.
* **Ultra-Smooth 60 FPS:** Uses batch coordinate updating and identity resolution throttling for zero stutters.
* **Source:** [mods/Radar/src/Radar.gml](mods/Radar/src/Radar.gml)

### 🌫️ Fog (v1.0)
* **Enhanced Exploration:** Adjusts the alpha channel on the minimap surface, rendering the explored map with 95% translucency.
* **Seamless:** Hooks directly into `MINIMAP.render_surface` without interfering with game saves or world generation.
* **Source:** [mods/Fog/src/Fog.gml](mods/Fog/src/Fog.gml)

### 🕒 RealClock (v1.0)
* **Real Local Time:** Displays the computer's current time in 24-hour `HH:MM` format instead of the in-game day cycle.
* **No Accessory Required:** Remains available without equipping the Clock accessory.
* **Native HUD Style:** Uses Tinkerlands' embedded pixel font with high-visibility yellow text.
* **Responsive Placement:** Scales from a 1920×1080 reference area and stays anchored to the top-right corner at other resolutions.
* **Correct Draw Layer:** Renders after the native GUI so the minimap cannot cover it.
* **Source:** [mods/RealClock/src/RealClock.gml](mods/RealClock/src/RealClock.gml)

---

## 📖 Technical Documentation
For developers and modders looking to understand Tinkerlands' engine variables, lifecycle hooks, and NPC architecture:
* 📄 **[Tinkerlands Modding & Engine Reference Guide](MODDING_GUIDE.md):** Detailed guide on GML mod packaging, global variables, lifecycle events, $O(1)$ `npcID` resolution, and minimap rendering hooks.

---

## 🔨 Building from Source

### ⚙️ Prerequisites & Environment
Before building the mods from source, ensure you have:
* **Operating System:** Windows 10 or 11.
* **PowerShell:** Version 5.1+ (built into Windows) or [PowerShell 7+](https://github.com/PowerShell/PowerShell).
* **Git:** [Git for Windows](https://git-scm.com/) to clone the repository.
* **Tinkerlands (Steam):** Required only if using the `-Deploy` flag to auto-copy to your game's directory.

> [!NOTE]
> **No external compilers or C++ tools are needed.** The automated build script (`build.ps1`) handles all GML string encoding (`#$#` / `%$%`), JSON manifest generation, and ZIP `.mod` packaging natively via PowerShell.

### 🚀 Build Steps

1. **Clone the Repository:**
   ```powershell
   git clone https://github.com/telles0808/Tinkerlands-Mods.git
   cd Tinkerlands-Mods
   ```

2. **(If needed) Allow PowerShell Script Execution:**
   Windows may restrict running unsigned `.ps1` scripts by default. In your PowerShell terminal, run:
   ```powershell
   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
   ```

3. **Compile the Mods:**
   ```powershell
   # Compile Radar mod:
   .\tools\build.ps1 -ModName Radar

   # Compile Fog mod:
   .\tools\build.ps1 -ModName Fog

   # Compile RealClock mod:
   .\tools\build.ps1 -ModName RealClock

   # Compile and automatically deploy directly to your Steam Tinkerlands mods folder:
   .\tools\build.ps1 -ModName Radar -Deploy
   ```

The compiled mod packages will be output to both `mods/<ModName>/dist/<ModName>.mod` and `releases/<ModName>.mod`.

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
