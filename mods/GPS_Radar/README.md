# 🧭 GPS Radar — Unified GPS & Radar Navigation

[![Author](https://img.shields.io/badge/Author-Telles0808-blue.svg)](https://github.com/telles0808)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/Platform-Windows-lightgrey.svg)]()
[![Game](https://img.shields.io/badge/Game-Tinkerlands-orange.svg)]()

**GPS Radar** is the definitive, unified navigation and tracking system for **Tinkerlands**. It seamlessly unifies normal in-game HUD directional tracking (Radar), native minimap projection, and persistent waypoint management on the full expanded map.

GPS Radar tracks **NPCs and multiplayer companions**, **world chests and user pins**, and **monsters, critters, and bosses**. Its controls remain accessible on the HUD with zero screen clutter.

---

## 📸 Screenshots

| Normal HUD Tracking | Minimap Presentation | Expanded Map and Pins |
| :---: | :---: | :---: |
| ![Normal HUD Tracking](screenshot_radar_tracking.png) | ![Minimap Presentation](screenshot_minimap_radar_mode.png) | ![Expanded Map and Pins](screenshot_map_death_pin.png) |
| *Directional raycast tracking integrated directly into the normal HUD.* | *Tracked categories rendered natively inside the minimap with edge-clamping.* | *Top-left pin menu, persistent waypoints, and automatic death marker.* |

---

## 🧭 One System, Dual Presentation Modes

GPS Radar maintains a single, unified tracking state and category filter set. The main Sonar button instantly switches where tracking is displayed:

- **Normal HUD (Radar Mode):** Targets are projected on-screen or clamped along the monitor boundaries with directional arrows, accurate raycasting, distances in meters, and entity icons.
- **Minimap Mode:** Targets are rendered directly inside the native minimap viewport, properly scaling and clamping to the map frame when out of view.

### Main Sonar Button

Clicking the large Sonar icon switches between **Normal HUD** and **Minimap** presentation modes.

### Category Filter Buttons

The three badge buttons independently control tracked entity categories:

| Button | Tracked Category |
| :---: | --- |
| 👤 | NPCs and multiplayer companions |
| 📦 | World chests, storage containers, and custom map pins |
| 👹 | Monsters, critters, and bosses |

Filters are shared across both presentation modes and saved persistently.

---

## 🖥️ Normal HUD Tracking (Collinear 2D Raycasting)

When active on the normal game HUD:

### Targets outside the visible screen
- **2D Raycast Edge Clamping:** The indicator is placed at the exact intersection between the screen edge and the line of sight connecting the player character on-screen to the target in the world.
- **Directional Arrow:** An arrow (`sprGUIIngameArrowRight`) rotates to point along the true line of sight toward the target.
- **Category / Entity Icon:** Accurately identifies the chest, mob portrait, NPC portrait, or waypoint.
- **Distance:** Meter reading (`Xm`) based on tile distance (`TILE_SIZE = 16`).
- **Comfort Margins:** Icons and labels never clip into or overflow the monitor edges.

### Targets inside the visible screen
- Redundant icons are suppressed to avoid visual clutter.
- NPCs display their resolved character names below the entity.
- Monsters display their name and distance in meters.
- Chests display their distance in meters.
- Waypoint pins display their identifying sprite and distance.

---

## 🗺️ Minimap Tracking & Dimension Scaling

When Minimap Mode is selected, tracked elements are rendered cleanly inside the game's minimap:

- **Native Region Dimension Resolution:** Reads `Region.GetCurrent()` and queries `Region.GetWidth()` / `Region.GetHeight()` from the engine to calculate exact room and island boundaries.
- **Perfect Border Locking:** When the player approaches the border of small islands, dungeons, or event caves, the minimap viewport locks to the terrain boundary while pins remain physically fixed to ground tiles.
- **Edge Clamping:** Out-of-view targets clamp to the minimap frame, showing their respective category icons.
- **Multiplayer & Dimension Isolation:** Fully isolates `netRegion` so markers from caves, dungeons, or other islands never bleed into the current map.

---

## 🌍 Expanded Map Overlay & Pin Editor

Opening the full map (<kbd>M</kbd>) displays the interactive pin palette and overlay:

- **Full World Entity Rendering:** All active sonar filters (chests, mobs, NPCs, and custom pins) are drawn directly on the full map in real time.
- **Pin Palette:** Drag and drop pins from the upper-left palette onto any map coordinate.
- **Coordinate Readouts:** Each pin displays its exact tile coordinates (`X, Y`).
- **Pin Movement & Deletion:** Drag existing pins to reposition, or drag them into the trash icon to delete.
- **Persistent Storage:** Saves pins per island key and network region in `gps_pins.cfg`.

### Placeable Pins

| Type | Purpose | Normal HUD | Minimap | Expanded Map |
| --- | --- | :---: | :---: | :---: |
| Waypoint | General destination | ✅ | ✅ | ✅ |
| Storage | Chest or resource cache | ✅ | ✅ | ✅ |
| Question | Unexplored point of interest | ✅ | ✅ | ✅ |
| Boss | Boss or high-threat encounter | ✅ | ✅ | ✅ |
| Teleport | Portal or teleport station | ✅ | ✅ | ✅ |
| Completed | Cleared or completed location | ❌ | ✅ | ✅ |

---

## ✅ Special Completed Pin

The green completed/check pin marks cleared points of interest:
- Selectable and placeable from the expanded map palette.
- Appears on the expanded map and minimap.
- Deliberately omitted from normal HUD tracking to keep HUD navigation uncluttered.

---

## 🪦 Automatic Death Waypoint & Toggle Button

When enabled, a tombstone pin (`sprTombStone`) is automatically placed at the exact death tile and region upon player death, persisting after respawn until dragged into the trash bin.

- **Palette Toggle Button:** Located in the top-left map palette next to the checkmark pin.
- **Active (Color):** Automatic tombstone pin creation is **ON**.
- **Inactive (Gray):** Automatic tombstone pin creation is **OFF**.
- Click the tombstone button on the large map to toggle this feature at any time (saved persistently in `gps_pins.cfg`).

---

## 👥 Multiplayer Companion Tracking

- Automatically detects and tracks other active `objPlayer` instances in the same `netRegion`.
- Displays companion names and distances.
- Players entering caves or other dimensions disappear seamlessly until you enter the same region.

---

## 🕹️ Controls Summary

| Action | Key or Interaction |
| --- | --- |
| Switch HUD / Minimap Mode | Click large Sonar button |
| Toggle Tracked Categories | Click 👤 (NPCs), 📦 (Chests/Pins), or 👹 (Mobs) |
| Toggle Auto Death Tombstone | Click 🪦 (Tombstone) button on top-left map palette |
| Open / Close Expanded Map | Press <kbd>M</kbd> or click the map icon |
| Place Custom Pin | Drag pin from upper-left palette onto map |
| Move Existing Pin | Click and drag pin to new location |
| Delete Pin | Drag pin into upper-left trash icon |

---

## 💾 Persistence

GPS Radar persists its entire configuration (Sonar mode, active filters, and custom pins per island/region) in `gps_pins.cfg`.

---

## 📥 Installation

1. Download `telles0808_id5004_gps.mod` from releases.
2. Place the `.mod` file in your Tinkerlands `mods/` directory.
3. Remove any obsolete radar or older map mod files.
4. Launch Tinkerlands.
