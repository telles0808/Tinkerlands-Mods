# 📡 NPC Radar Mod (v1.3)

[![Author](https://img.shields.io/badge/Author-Telles0808-blue.svg)](https://github.com/telles0808)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/Platform-Windows-lightgrey.svg)]()
[![Game](https://img.shields.io/badge/Game-Tinkerlands-orange.svg)]()

A high-performance, real-time NPC tracking and identification mod for **Tinkerlands**. **NPC Radar** provides directional edge pointers, distance meters, authentic character portraits, and an in-game HUD toggle button.

![NPC Radar In-Game Preview](preview.png)

---

## 🌟 Key Features

* **🧭 Dynamic Off-Screen Pointers:** Circular edge indicators with directional arrows pointing to every NPC on the island with real-time distance calculations in meters.
* **🏷️ In-Screen Entity Overlays:** Renders character portraits, localized titles (e.g. *"Wilson, o Guia"* / *"Wilson the Guide"*), and distance directly above NPCs within line of sight.
* **⚡ Native $O(1)$ ID Resolution:** Accurately identifies all 38 NPC IDs from `db_npc` using direct `_npc.npcID` lookup, seamlessly resolving both unique non-humanoids (Gizmo, Dryads, Loonaru) and composite humanoids using generic base sprites (Blacksmith, Nurse, Miner, Carpenter).
* **🔘 Interactive Sonar Toggle:** Pinned cleanly beside the minimap. Click the Sonar icon anytime to enable or disable the radar display on the fly.
* **🎬 Cutscene & Menu Occlusion:** Automatically hides during narrative sequences, dialogs, map viewing, and menus to maintain full cinematic immersion.
* **🚀 Zero Stutter Optimization:** Features batch coordinate updating and resolution throttling, guaranteeing a locked 60 FPS.

---

## 📥 Installation

1. Download [`Radar.mod`](https://github.com/telles0808/Tinkerlands-Mods/raw/main/releases/Radar.mod).
2. Place `Radar.mod` inside your game mods folder:
   ```
   C:\Program Files (x86)\Steam\steamapps\common\Tinkerlands\mods\
   ```
3. Launch Tinkerlands!

---

## 🛠️ Technical Details

* **Entity Hooking:** Dispatches from `OnNPCSpawn` and scans active `objNPC` instances upon island arrival.
* **Portrait Mapping:** Direct numeric table lookup avoiding regex or locale-dependent string searches.
* **Source Code:** [src/Radar.gml](src/Radar.gml)
