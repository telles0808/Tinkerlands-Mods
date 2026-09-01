# 🛠️ Tinkerlands Mods Collection

A curated collection of quality-of-life, navigation, automation, and visual enhancement mods for **[Tinkerlands](https://store.steampowered.com/app/2617700/Tinkerlands/)** by **Telles0808**.

---

## 📥 Quick Downloads

All pre-compiled and ready-to-play `.mod` files are available in the table below and inside the [`releases/`](releases/) folder:

| Mod | ID | Description | Status | Direct Download |
| :--- | :---: | :--- | :---: | :--- |
| **[Fog](#-fog-id-5001)** | `5001` | Map surface translucency enhancer: renders explored fog of war with 95% opacity. | ✅ Stable | [⬇️ Download Fog.mod](https://github.com/telles0808/Tinkerlands-Mods/raw/main/releases/telles0808_id5001_fog.mod) |
| **[RealClock](#-realclock-id-5002)** | `5002` | Real-world 24-hour local computer time in the top-right corner without needing the Clock accessory. | ✅ Stable | [⬇️ Download RealClock.mod](https://github.com/telles0808/Tinkerlands-Mods/raw/main/releases/telles0808_id5002_realclock.mod) |
| **[Better Organizer](#-better-organizer-id-5003)** | `5003` | Chest automation & organization: 7-category filter bar with hotbar protection and persistent routing. | ✅ Stable | [⬇️ Download BO.mod](https://github.com/telles0808/Tinkerlands-Mods/raw/main/releases/telles0808_id5003_bo.mod) |
| **[GPS Radar](#-gps-radar-id-5004)** | `5004` | Advanced GPS waypoint manager with interactive map pins, 2D raycast directional tracking, minimap scaling, and automatic death tombstone pins. | ✅ Stable | [⬇️ Download GPS_Radar.mod](https://github.com/telles0808/Tinkerlands-Mods/raw/main/releases/telles0808_id5004_gps.mod) |
| **[Monitor Switcher](#-monitor-switcher-id-5005)** | `5005` | 1-click multi-monitor display switcher on the title screen for Borderless Fullscreen mode. | ✅ Stable | [⬇️ Download Monitor.mod](https://github.com/telles0808/Tinkerlands-Mods/raw/main/releases/telles0808_id5005_monitor.mod) |
| **[Godmod](#-godmod-id-5006)** | `5006` | Toggleable God Mode: infinite HP, MP, and Dashes locked to true dynamic maximums with complete damage immunity. | ✅ Stable | [⬇️ Download Godmod.mod](https://github.com/telles0808/Tinkerlands-Mods/raw/main/releases/telles0808_id5006_godmod.mod) |

---

## ⚡ Installation Guide

1. Download the desired `.mod` file from the table above.
2. Locate your **Tinkerlands** installation folder:
   ```
   C:\Program Files (x86)\Steam\steamapps\common\Tinkerlands\mods\
   ```
3. **⚠️ (Recommended) Remove Old Mod Versions:** Delete any previous versions of the mod from your `mods\` folder to prevent conflicts.
4. Paste the new `.mod` file into the `mods\` folder.
5. **💡 Clear Game Cache:**
   * Press <kbd>Win</kbd> + <kbd>R</kbd>, type `%LOCALAPPDATA%\Tinkerlands\temp` and press **Enter**.
   * Delete any files inside the `temp` folder so the engine loads the new scripts immediately.
6. Launch the game!

---

## 📦 Mod Catalog

### 🌫️ Fog (ID: 5001)
* **Translucent Minimap Exploration:** Adjusts the alpha channel on the minimap surface, rendering the explored map with 95% translucency.
* **Preview:**

  ![Fog Mod Preview](mods/Fog/preview.png)

* **Documentation & Source:** [mods/Fog/README.md](mods/Fog/README.md) • [mods/Fog/src/telles0808_id5001_fog.gml](mods/Fog/src/telles0808_id5001_fog.gml)

---

### 🕒 RealClock (ID: 5002)
* **Real Local Time:** Displays your computer's current 24-hour time (`HH:MM`) directly on the HUD.
* **No Accessory Required:** Works out of the box without occupying an equipment accessory slot.
* **Preview:**

  ![RealClock Preview](mods/RealClock/preview.png)

* **Documentation & Source:** [mods/RealClock/README.md](mods/RealClock/README.md) • [mods/RealClock/src/telles0808_id5002_realclock.gml](mods/RealClock/src/telles0808_id5002_realclock.gml)

---

### 📦 Better Organizer (ID: 5003)
* **Interactive 7-Category Filter Bar:** Pinned seamlessly onto the top frame of opened containers.
* **Two-Tier Priority Routing:** Fills incomplete piles first before claiming new slots.
* **Hotbar Action Row Guard:** Active hotbar slots are never touched during deposits.
* **Preview:**

  ![Better Organizer Preview](mods/BO/preview.png)

* **Documentation & Source:** [mods/BO/README.md](mods/BO/README.md) • [mods/BO/src/telles0808_id5003_bo.gml](mods/BO/src/telles0808_id5003_bo.gml)

---

### 🧭 GPS Radar (ID: 5004)
* **Collinear 2D Raycast Radar:** Off-screen directional arrows and entity icons projected directly along the line of sight from the player to the target.
* **Native Region Viewport Resolution:** Uses `Region.GetCurrent()` / `Region.GetWidth()` / `Region.GetHeight()` for perfect minimap boundary clamping across all room/island sizes.
* **Automatic Death Tombstone:** Automatically places a persistent grave pin where you die, guiding you straight back to your lost items.
* **Entity & Mob Tracking:** Detects nearby monsters, critters, and bosses with real creature portraits and distance in meters.
* **Interactive Fullscreen Map:** Drag and drop 6 pin categories (waypoints, chests, points of interest, bosses, teleports, and cleared locations) with live coordinates and trash deletion.
* **Modular Sonar Controller:** HUD master button with 3 dedicated sub-toggles to filter NPCs, chests, or mobs on the fly.
* **Clean In-Screen Aesthetics:** Hides portraits when NPCs enter your screen, displaying their name neatly beneath their feet.
* **Screenshots & In-Game Showcase:**

  | 2D Raycast Tracking | Minimap Radar Mode | Fullscreen Map & Death Pin |
  | :---: | :---: | :---: |
  | ![2D Raycast Tracking](mods/GPS_Radar/screenshot_radar_tracking.png) | ![Minimap Radar Mode](mods/GPS_Radar/screenshot_minimap_radar_mode.png) | ![Map Waypoints & Death Pin](mods/GPS_Radar/screenshot_map_death_pin.png) |

* **Documentation & Source:** [mods/GPS_Radar/README.md](mods/GPS_Radar/README.md) • [mods/GPS_Radar/src/telles0808_id5004_gps.gml](mods/GPS_Radar/src/telles0808_id5004_gps.gml)

---

### 🖥️ Monitor Switcher (ID: 5005)
* **1-Click Multi-Monitor Toggle:** Switch the game window across multiple monitors in Borderless Fullscreen directly from the title screen.
* **Visual States:** Active monitor highlighted in brilliant gold and blue; inactive monitors in high-contrast metallic silver (visible day and night).
* **Safe Native Boot:** Always defaults to Monitor 1 (primary display) on game restart.
* **Preview:**

  ![Monitor Switcher Preview](mods/Monitor/preview.png)

* **Documentation & Source:** [mods/Monitor/README.md](mods/Monitor/README.md) • [mods/Monitor/src/telles0808_id5005_monitor.gml](mods/Monitor/src/telles0808_id5005_monitor.gml)

---

### ⚡ Godmod (ID: 5006)
* **1-Key Toggle (<kbd>F9</kbd>):** Instantly toggle God Mode ON or OFF during gameplay.
* **Dynamic Max HP & MP:** Dynamically locks health and mana to your character's true maximum including all equipment bonuses and permanent upgrades (`calculate_max_hp`, `calculate_max_mp`).
* **Infinite Dashes & SP:** Never run out of energy; stamina and dashes are locked full with zero cooldown delay.
* **Complete Damage Immunity:** Provides total immunity to all incoming damage, hits, and environmental hazards.
* **Adaptive Centered HUD:** Displays a neat, resolution-scaled indicator at the top center of the screen when active.

* **Documentation & Source:** [mods/Godmod/README.md](mods/Godmod/README.md) • [mods/Godmod/src/telles0808_id5006_godmod.gml](mods/Godmod/src/telles0808_id5006_godmod.gml)

---

## 📖 Technical Documentation
For developers and modders looking to understand Tinkerlands' engine variables, lifecycle hooks, and NPC architecture:
* 📄 **[Tinkerlands Modding & Engine Reference Guide](MODDING_GUIDE.md):** Detailed guide on GML mod packaging, global variables, lifecycle events, $O(1)$ `npcID` resolution, container hooks, and minimap rendering.

---

## 🔨 Automated Build Scripts (`.cmd`)

Each mod folder includes a 1-click Windows Command Script (`.cmd`) to compile, package, deploy to Steam, and clear the engine cache automatically:

| Mod | 1-Click Script Path |
| :--- | :--- |
| **Fog** | [`mods/Fog/src/telles0808_id5001_fog.cmd`](mods/Fog/src/telles0808_id5001_fog.cmd) |
| **RealClock** | [`mods/RealClock/src/telles0808_id5002_realclock.cmd`](mods/RealClock/src/telles0808_id5002_realclock.cmd) |
| **Better Organizer** | [`mods/BO/src/telles0808_id5003_bo.cmd`](mods/BO/src/telles0808_id5003_bo.cmd) |
| **GPS Radar** | [`mods/GPS_Radar/src/telles0808_id5004_gps.cmd`](mods/GPS_Radar/src/telles0808_id5004_gps.cmd) |
| **Monitor Switcher** | [`mods/Monitor/src/telles0808_id5005_monitor.cmd`](mods/Monitor/src/telles0808_id5005_monitor.cmd) |
| **Godmod** | [`mods/Godmod/src/telles0808_id5006_godmod.cmd`](mods/Godmod/src/telles0808_id5006_godmod.cmd) |

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
