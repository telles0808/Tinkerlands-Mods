# 🌫️ Fog Mod (v1.0)

[![Author](https://img.shields.io/badge/Author-Telles0808-blue.svg)](https://github.com/telles0808)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/Platform-Windows-lightgrey.svg)]()
[![Game](https://img.shields.io/badge/Game-Tinkerlands-orange.svg)]()

A lightweight, seamless map enhancement mod for **Tinkerlands** that provides clear visibility over explored territories through a customized translucent fog of war layer.

![Fog Mod In-Game Preview](preview.png)

---

## 🌟 Key Features

* **🗺️ 95% Translucent Fog of War:** Replaces the pitch-black unexplored exploration mask with a 95% translucent surface, allowing you to clearly see biomes, coastlines, structures, and terrain contours.
* **🔍 Effortless Navigation:** Easily identify unexplored regions, dungeons, and island edges on the full-screen world map without blind guesswork.
* **🛡️ Non-Destructive Surface Hook:** Directly intercepts the engine's `MINIMAP.render_surface` pipeline. It does not alter your save files, map data, or world generation parameters.
* **⚡ Maximum Performance:** Uses GPU alpha blending directly within the native GameMaker draw pass with zero frame drops.

---

## 📥 Installation

1. Download [`telles0808_id5001_fog.mod`](https://github.com/telles0808/Tinkerlands-Mods/raw/main/releases/telles0808_id5001_fog.mod).
2. Place `telles0808_id5001_fog.mod` inside your game mods folder:
   ```
   C:\Program Files (x86)\Steam\steamapps\common\Tinkerlands\mods\
   ```
3. Launch Tinkerlands!

---

## 🛠️ Technical Details

* **Surface Hook:** Intercepts the minimap composite pass by adjusting the surface blend alpha channel before the final UI blit.
* **Source Code:** [src/telles0808_id5001_fog.gml](src/telles0808_id5001_fog.gml)
