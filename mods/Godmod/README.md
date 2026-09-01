# ⚡ Godmod (ID: 5006)

[![Author](https://img.shields.io/badge/Author-Telles0808-blue.svg)](https://github.com/telles0808)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/Platform-Windows-lightgrey.svg)]()
[![Game](https://img.shields.io/badge/Game-Tinkerlands-orange.svg)]()

A lightweight, native toggleable God Mode trainer mod for **Tinkerlands** that locks HP, MP, SP, and Dashes at their true maximum values with complete damage immunity.

---

## 🌟 Key Features

* **⚡ 1-Key Toggle (<kbd>F9</kbd>):** Turn God Mode ON or OFF at any time during gameplay.
* **❤️ Dynamic Max HP Lock:** Automatically calculates and locks health to your character's true maximum including all equipment buffs, accessories, and permanent upgrades (`calculate_max_hp`).
* **💙 Dynamic Max MP Lock:** Keeps mana full at your exact current capacity (`calculate_max_mp`).
* **⚡ Infinite Dashes (SP):** Locks stamina/dashes to your full capacity with zero recharge cooldown delay.
* **🛡️ Damage Immunity & iFrames:** Prevents all incoming damage and knockback while active.
* **🖥️ Adaptive Centered HUD:** Displays a centered, resolution-scaled indicator at the top of the screen when active.
* **🔒 Seamless Map Transitions:** God Mode state persists across room, dungeon, and island transitions.

---

## 📥 Installation

1. Download [`telles0808_id5006_godmod.mod`](https://github.com/telles0808/Tinkerlands-Mods/raw/main/releases/telles0808_id5006_godmod.mod).
2. Place `telles0808_id5006_godmod.mod` inside your game mods folder:
   ```
   C:\Program Files (x86)\Steam\steamapps\common\Tinkerlands\mods\
   ```
3. Launch Tinkerlands!

---

## 🎮 Controls

* **<kbd>F9</kbd>**: Toggle God Mode ON / OFF.

---

## 🛠️ Technical Details

* **Hook Lifecycle:** `OnModLoad` initializes `Godmod_Update` and `Godmod_DrawGUI`.
* **State Persistence:** `OnWorldGenerationEnd` preserves active state across map generation.
* **Source Code:** [src/telles0808_id5006_godmod.gml](src/telles0808_id5006_godmod.gml)
