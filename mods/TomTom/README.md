# 🧭 TomTom Mod (v1.4)

[![Author](https://img.shields.io/badge/Author-Telles0808-blue.svg)](https://github.com/telles0808)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/Platform-Windows-lightgrey.svg)]()
[![Game](https://img.shields.io/badge/Game-Tinkerlands-orange.svg)]()

A unified GPS waypoint and radar navigation system for **Tinkerlands**. **TomTom** seamlessly combines custom fullscreen map pins (drag-and-drop waypoints) with dynamic off-screen entity radar tracking for NPCs, multiplayer companions, and user-placed map markers.

![TomTom In-Game Interface Preview](preview.png)

---

## 🌟 Key Features

* **📍 Interactive Fullscreen Map Pins:**
  * **4 Distinct Pin Categories:** Waypoint (📍), Storage (📦), Point of Interest / Question Mark (❓), and Boss / Danger (💀).
  * **Drag & Drop Palette:** Simply drag any marker from the top-left palette onto the world map canvas to place it.
  * **Move & Reorder:** Click and drag existing pins anywhere across the map terrain; the pin stays attached to your cursor during movement.
  * **Illuminated Trash Bin:** Drag any pin to the glowing red trash can icon in the upper-left corner to delete it.
  * **Coordinate Labels:** Displays clear tile coordinates `(X, Y)` directly beneath every pin placed on the map.
* **🏹 Dynamic Gameplay Radar (TomTom Navigation):**
  * **Off-Screen Projection:** Automatically projects directional arrows along the edges of the screen pointing to NPCs, other players, and your placed map pins.
  * **Portraits & Identifiers:** Renders native NPC character portraits, multiplayer player names, and custom pin icons with real-time distance meters (`Xm`).
  * **In-Screen Indicators:** When near a target inside your viewport, displays floating identifiers directly above the entity.
* **🔘 HUD Sonar Toggle:**
  * Click the dedicated Sonar icon next to your minimap in the top right to instantly toggle NPC radar on/off without opening menus.
* **🗺️ Independent Map Controls:**
  * Toggle the fullscreen map at any time with `M` or the native HUD map button.
  * Opening your inventory or interacting with containers does not close the map canvas.
  * Press `ESC` or `M` to close the map.
* **📐 Player Coordinates:**
  * Real-time `(X, Y)` tile position of your player rendered in the bottom-right corner of the screen (color-matched with RealClock).
* **💾 Automatic Persistence:**
  * All placed pins and configurations are automatically saved to `tomtom_pins.cfg`.

---

## 🕹️ Controls & Usage

| Action | Control / Interaction |
| :--- | :--- |
| **Open / Close Map** | Press <kbd>M</kbd> or click the map button below the minimap. |
| **Close Map** | Press <kbd>ESC</kbd> or <kbd>M</kbd>. |
| **Place New Pin** | Drag a marker icon from the top-left palette onto the map canvas and release. |
| **Move Existing Pin** | Click and drag the pin on the map canvas to a new location. |
| **Delete Pin** | Drag any pin over the trash can icon (top-left) and release. |
| **Toggle Sonar Radar** | Click the Sonar accessory button below the minimap. |

---

## 📥 Installation

1. Download [`telles0808_id5004_tomtom.mod`](https://github.com/telles0808/Tinkerlands-Mods/raw/main/releases/telles0808_id5004_tomtom.mod).
2. Place `telles0808_id5004_tomtom.mod` inside your game mods folder:
   ```
   C:\Program Files (x86)\Steam\steamapps\common\Tinkerlands\mods\
   ```
3. Launch Tinkerlands!

---

## 🏗️ Architecture & Source Code

* **Unified Target Rendering:** Single high-performance trigonometric vector projection engine (`TomTom_DrawTarget`) for NPCs, multiplayer peers, and map pins.
* **Native $O(1)$ NPC Portraits:** Database lookup supporting all 38 native NPC IDs without string iteration overhead.
* **Source Code:** [src/telles0808_id5004_tomtom.gml](src/telles0808_id5004_tomtom.gml)
