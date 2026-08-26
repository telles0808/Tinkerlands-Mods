# 🕒 RealClock Mod (v1.0)

[![Author](https://img.shields.io/badge/Author-Telles0808-blue.svg)](https://github.com/telles0808)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/Platform-Windows-lightgrey.svg)]()
[![Game](https://img.shields.io/badge/Game-Tinkerlands-orange.svg)]()

A clean, responsive, top-layer HUD mod for **Tinkerlands** that displays your computer's actual real-world local time directly in the corner of your screen.

![RealClock In-Game Preview](preview.png)

---

## 🌟 Key Features

* **⏰ Real Local Time:** Displays your system clock in 24-hour `HH:MM` format in real-time.
* **🔓 No Accessory Required:** Works instantly out-of-the-box without consuming an accessory slot or requiring the in-game Clock item.
* **🎨 Authentic Pixel Typography:** Rendered using Tinkerlands' native pixel font with high-visibility yellow coloring and crisp drop shadows.
* **📐 Responsive Top-Right HUD Anchor:** Mathematically scaled against a 1920×1080 reference geometry, maintaining perfect pixel-aligned positioning across any monitor resolution or aspect ratio.
* **🔝 Topmost GUI Stage:** Registered via the late-stage GUI callback pipeline to ensure it is never obstructed by the minimap frame, cutscene letterboxing, or menu overlays.

---

## 📥 Installation

1. Download [`telles0808_id5002_realclock.mod`](https://github.com/telles0808/Tinkerlands-Mods/raw/main/releases/telles0808_id5002_realclock.mod).
2. Place `telles0808_id5002_realclock.mod` inside your game mods folder:
   ```
   C:\Program Files (x86)\Steam\steamapps\common\Tinkerlands\mods\
   ```
3. Launch Tinkerlands!

---

## 🛠️ Technical Details

* **Topmost Draw Layer:** Renders in `OnModDrawGUIEnd` after the native in-game GUI controllers.
* **Aspect-Ratio Scaling:** Scales with `display_get_gui_height() / 1080.0`.
* **Source Code:** [src/telles0808_id5002_realclock.gml](src/telles0808_id5002_realclock.gml)
