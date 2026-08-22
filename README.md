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
| **[Better Organizer (v1.0)](#-better-organizer-bo-v10)** | Smart inventory deposit system with interactive 7-channel chest filter bars, category routing, and hotbar protection. | ✅ Stable | [⬇️ Download BO.mod](https://github.com/telles0808/Tinkerlands-Mods/raw/main/releases/BO.mod) |
| **[NPC Radar (v1.3)](#-npc-radar-v13)** | Real-time NPC tracker with HUD toggle button, custom portraits, and distance indicators. Zero FPS lag. | ✅ Stable | [⬇️ Download Radar.mod](https://github.com/telles0808/Tinkerlands-Mods/raw/main/releases/Radar.mod) |
| **[RealClock (v1.0)](#-realclock-v10)** | Displays the computer's real local time in a responsive 24-hour HUD clock without requiring the Clock accessory. | ✅ Stable | [⬇️ Download RealClock.mod](https://github.com/telles0808/Tinkerlands-Mods/raw/main/releases/RealClock.mod) |
| **[Fog (v1.0)](#-fog-v10)** | Modifies the minimap fog layer to provide 95% translucent visibility across explored areas. | ✅ Stable | [⬇️ Download Fog.mod](https://github.com/telles0808/Tinkerlands-Mods/raw/main/releases/Fog.mod) |

---

## 📥 Installation

1. Download the `.mod` file for the desired mod from the [Releases](releases/) folder (or direct links above).
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

### 📦 Better Organizer / BO (v1.0)
* **Interactive 7-Category Filter Bar:** Pinned seamlessly onto the top frame of any opened chest (standard or astral).
* **Two-Tier Priority Routing:** Fills existing incomplete piles first before claiming new chest slots.
* **Hotbar Action Row Guard:** Row 0 (active inventory action slots) is never touched during automatic deposits.
* **Native Engine Transfer:** Integrates directly with `container_item_move` for instant, duplicate-free transfers.
* **Physical Position Persistence:** Filter settings are keyed by real world-coordinates (`chest_x[X]_y[Y]`) and automatically saved in `BO_filters.cfg`.
* **Dedicated HUD Button:** Adds a custom `BO` button right next to the native inventory quick-stack controls.
* **Preview:**

  ![Better Organizer Preview](mods/BO/preview.png)

* **Documentation & Source:** [mods/BO/README.md](mods/BO/README.md) • [mods/BO/src/BO.gml](mods/BO/src/BO.gml)

---

### 📡 NPC Radar (v1.3)
* **Dynamic Off-Screen Tracking:** Shows directional arrows with character portraits pointing to all NPCs on the island.
* **In-Screen Identification:** Displays NPC portraits and names directly above entities within your field of view.
* **On/Off Toggle Button:** Integrated cleanly onto the HUD near the minimap (click the Sonar icon to toggle).
* **Native $O(1)$ ID Lookup:** Resolves character portraits via the game's internal `npcID` database table, ensuring full compatibility with localized and generic humanoid NPCs.
* **Ultra-Smooth 60 FPS:** Uses batch coordinate updating and identity resolution throttling for zero stutters.
* **Preview:**

  ![NPC Radar Preview](mods/Radar/preview.png)

* **Documentation & Source:** [mods/Radar/README.md](mods/Radar/README.md) • [mods/Radar/src/Radar.gml](mods/Radar/src/Radar.gml)

---

### 🕒 RealClock (v1.0)
* **Real Local Time:** Displays the computer's current time in 24-hour `HH:MM` format instead of the in-game day cycle.
* **No Accessory Required:** Remains available without equipping the Clock accessory.
* **Native HUD Style:** Uses Tinkerlands' embedded pixel font with high-visibility yellow text.
* **Responsive Placement:** Scales from a 1920×1080 reference area and stays anchored to the top-right corner across all resolutions.
* **Topmost Draw Layer:** Renders on top of the native GUI so the minimap cannot cover it.
* **Preview:**

  ![RealClock Preview](mods/RealClock/preview.png)

* **Documentation & Source:** [mods/RealClock/README.md](mods/RealClock/README.md) • [mods/RealClock/src/RealClock.gml](mods/RealClock/src/RealClock.gml)

---

### 🌫️ Fog (v1.0)
* **Enhanced Exploration:** Adjusts the alpha channel on the minimap surface, rendering the explored map with 95% translucency.
* **Seamless:** Hooks directly into `MINIMAP.render_surface` without interfering with game saves or world generation.
* **Preview:**

  ![Fog Mod Preview](mods/Fog/preview.png)

* **Documentation & Source:** [mods/Fog/README.md](mods/Fog/README.md) • [mods/Fog/src/Fog.gml](mods/Fog/src/Fog.gml)

---

## 📖 Technical Documentation
For developers and modders looking to understand Tinkerlands' engine variables, lifecycle hooks, and NPC architecture:
* 📄 **[Tinkerlands Modding & Engine Reference Guide](MODDING_GUIDE.md):** Detailed guide on GML mod packaging, global variables, lifecycle events, $O(1)$ `npcID` resolution, container hooks, and minimap rendering.

---

## 🔨 Building from Source & 1-Click `.cmd` Scripts

### ⚙️ Prerequisites & Environment
Before building the mods from source, ensure you have:
* **Operating System:** Windows 10 or 11.
* **PowerShell:** Version 5.1+ (built into Windows) or [PowerShell 7+](https://github.com/PowerShell/PowerShell).
* **Git:** [Git for Windows](https://git-scm.com/) to clone the repository.
* **Tinkerlands (Steam):** Required only if using the `-Deploy` flag to auto-copy to your game's directory.

---

### ⚡ 1-Click Automated Build Scripts (`.cmd`)

Each mod directory contains a ready-to-run Windows Command Script (`.cmd`) located right alongside its source file:

| Mod | 1-Click Script Path | What It Does |
| :--- | :--- | :--- |
| **Better Organizer** | `mods/BO/src/Build_BO.cmd` *(or `mods/BO/Build_BO.cmd`)* | Compiles `BO.gml` ➔ builds `.mod` ➔ deploys to Steam ➔ increments `packver` ➔ clears game cache. |
| **NPC Radar** | `mods/Radar/src/Build_Radar.cmd` *(or `mods/Radar/Build_Radar.cmd`)* | Compiles `Radar.gml` ➔ builds `.mod` ➔ deploys to Steam ➔ increments `packver` ➔ clears game cache. |
| **RealClock** | `mods/RealClock/src/Build_RealClock.cmd` *(or `mods/RealClock/Build_RealClock.cmd`)* | Compiles `RealClock.gml` ➔ builds `.mod` ➔ deploys to Steam ➔ increments `packver` ➔ clears game cache. |
| **Fog** | `mods/Fog/src/Build_Fog.cmd` *(or `mods/Fog/Build_Fog.cmd`)* | Compiles `Fog.gml` ➔ builds `.mod` ➔ deploys to Steam ➔ increments `packver` ➔ clears game cache. |
| **All Mods** | `tools/Build_All.cmd` | Compiles and deploys all 4 mods sequentially in a single click. |

Simply **double-click** the `.cmd` file to execute the complete build, packaging, hot-reload, and cache-clearing pipeline automatically!

---

### ✏️ How to Edit & Customize the `.cmd` Scripts

Right-click any `Build_<ModName>.cmd` file and select **Edit** (or open in VS Code / Notepad).

#### 1. Custom Steam Library Path
By default, the script automatically searches all common Steam library locations and queries the Windows Registry. If your Tinkerlands is installed in a custom non-standard directory:
Open [tools/build.ps1](tools/build.ps1) and add your custom path to the `$candidatePaths` array:
```powershell
$candidatePaths = @(
    "D:\CustomGames\SteamLibrary\steamapps\common\Tinkerlands\mods",
    "C:\Games\Steam\steamapps\common\Tinkerlands\mods",
    "C:\Program Files (x86)\Steam\steamapps\common\Tinkerlands\mods"
)
```

#### 2. Disable Automatic Steam Deployment
If you only want to compile the `.mod` file into `dist/` and `releases/` without copying to your game folder, remove the `-Deploy` flag from the `.cmd` command:
```diff
- & $buildTool -ModName 'BO' -Deploy;
+ & $buildTool -ModName 'BO';
```

#### 3. Automatic Silent Mode
To prevent the terminal window from waiting for a keypress upon completion, remove the `pause` command at the bottom of the `.cmd` file.

---

### 🚀 Manual PowerShell Build Commands

You can also run builds directly from PowerShell:
```powershell
# Compile Better Organizer (BO) mod:
.\tools\build.ps1 -ModName BO

# Compile and automatically deploy directly to Steam:
.\tools\build.ps1 -ModName BO -Deploy

# Compile other mods:
.\tools\build.ps1 -ModName Radar -Deploy
.\tools\build.ps1 -ModName RealClock -Deploy
.\tools\build.ps1 -ModName Fog -Deploy
```

The compiled mod packages are saved to `mods/<ModName>/dist/<ModName>.mod` and `releases/<ModName>.mod`.

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
