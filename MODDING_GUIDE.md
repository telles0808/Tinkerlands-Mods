# 📖 Tinkerlands Modding & Engine Reference Guide

> **Author:** Telles0808  
> **Repository:** [Tinkerlands-Mods (GitHub)](https://github.com/telles0808/Tinkerlands-Mods)  
> **Engine:** GameMaker Studio YYC + Apollo Runtime (`Apollo_x64.dll`)

---

## 1. 🏗️ Engine Architecture & Packaging

Tinkerlands is compiled using GameMaker Studio's **YYC (YoYo Compiler)** into native C++ code, integrated with the **Apollo** modding interface.

### GML String Encoding Rules
Due to how Apollo and the internal mod parser process GML script files, certain characters must be encoded during the packaging step:

| Character | Encoded Format | Description |
| :--- | :---: | :--- |
| `,` (Comma) | `#$#` | Prevents CSV/JSON argument splitting collisions |
| `"` (Double Quote) | `%$%` | Prevents string delimiter breaking |
| `\r\n` / `\n` | `\n` | Standardizes line endings |

### Package Structure (`.mod`)
Mods are packaged as standard ZIP archives renamed to `<ModName>.mod`:
```
<ModName>.mod (ZIP archive)
├── info.json
└── scripts/
    └── <ModName>@<modname_lower>.json
```

* **`info.json`**:
  ```json
  {
      "name": "Radar",
      "author": "Telles0808",
      "version": "1.3.0",
      "description": "High-performance NPC Radar for Tinkerlands"
  }
  ```

* **`scripts/<ModName>@<modname_lower>.json`**:
  ```json
  {
      "id": 5001,
      "key": "Radar@radar",
      "event": "E_CS_EVENT.None",
      "code": "<ENCODED_GML_CODE>"
  }
  ```

### Cache & Hot-Reload Behavior
* **Mod Installation Path:** `C:\Program Files (x86)\Steam\steamapps\common\Tinkerlands\mods\<modname>.mod`
* **Local AppData Cache:** `%LOCALAPPDATA%\Tinkerlands\temp`
* **Pack Version Increment:** `%LOCALAPPDATA%\Tinkerlands\packver` (incrementing this number forces the engine to discard cached scripts and unpack the latest `.mod` files).

---

## 2. ⏱️ Lifecycle Events & Mod Instances

The Apollo modding interface exposes lifecycle hooks:

```gml
// Triggered when world generation begins
OnWorldGenerationStart(function() {
    // Initialization
});

// Triggered when world generation completes
OnWorldGenerationEnd(function() {
    ModInstance.Create(
        "Radar",
        "Radar_Create",   // Create callback
        "Radar_Update",   // Step/Update callback
        undefined,        // Draw world callback
        "Radar_Draw",     // Draw GUI callback
        undefined         // Destroy callback
    );
});

// Triggered when the player travels to a new island
OnIslandArrive(function() {
    var _m = ModInstance.Get("Radar");
    if (_m != undefined) {
        _m.npcs = [];
        _m.scan = true;
    }
});

// Triggered when an NPC entity spawns into the world
OnNPCSpawn(function(_npc) {
    Radar_Add(_npc);
});
```

---

## 3. 🌐 Engine Globals, Macros & Built-in APIs

### Player & World
* **`MY_PLAYER`**: Active player instance struct.
  * `MY_PLAYER.x`, `MY_PLAYER.y`: World coordinates.
  * `MY_PLAYER.hp`: Current hit points.
* **`objPlayer`**: Player object index (`instance_exists(objPlayer)`).
* **`TILE_SIZE`**: World grid tile size (in pixels).
* **`CAMERA_X` / `CAMERA_Y`**: Active viewport top-left world coordinates.

### GUI & Coordinate Systems
* **`WINDOW.width` / `WINDOW.height`**: Current GUI viewport dimensions.
* **`GUI_SCALE`**: Engine GUI scaling multiplier.
* **`display_get_gui_width()` / `display_get_gui_height()`**: Raw display GUI dimensions.
* **`device_mouse_x_to_gui(0)` / `device_mouse_y_to_gui(0)`**: Mouse cursor coordinates converted to GUI space.

### Built-in Drawing APIs
* **`Draw.Sprite(sprite, subimg, x, y, xscale, yscale, rot, color, alpha)`**: Native sprite rendering.
* **`GUI.DrawText(x, y, string, font_id, color, alpha, scale)`**: Text rendering using embedded game fonts.

### Responsive 1080p HUD Scaling Formula
To ensure UI elements (such as HUD toggle buttons) remain proportionally positioned and sized across all monitor resolutions (720p, 1080p, 1440p, 4K):
```gml
function Radar_ScaleRatio() {
    var _h = display_get_gui_height();
    return (_h > 0) ? (_h / 1080.0) : 1.0;
}
```

---

## 4. 🎭 NPC Anatomy & Portrait Resolution (Radar Mod)

Through engine analysis, we discovered how Tinkerlands handles different NPC archetypes:

```
                           ┌───────────────────────────────┐
                           │            objNPC             │
                           └──────────────┬────────────────┘
                                          │
                  ┌───────────────────────┴───────────────────────┐
                  ▼                                               ▼
     [ Humanoid NPCs ]                               [ Unique / Monster NPCs ]
  • Blacksmith, Guide, Miner,                      • Gizmo, Goggs, Gumns, Penguin,
    Nurse, Carpenter, Chef, etc.                     Robot, Skeleton, Dryads, etc.
  • Base Generic Sprites:                          • Dedicated Custom Sprites:
    - sprBasePlayerIdle01/02/03                      - sprNPCGizmoIdle01
    - sprBasePlayerHead01/02/03                      - sprNPCDryadIdle01
  • Visuals composed via Equipment:                  - sprNPCBankerPenguinIdle01
    - npc_blacksmith_helmet                          - sprNPCTownGhost
    - npc_blacksmith_armor                         • Sprite name matches entity name
  • Sprite name DOES NOT contain role!
```

### The Native `npcID` Solution
Each `objNPC` instance holds an internal numeric property: **`_npc.npcID`**.  
Instead of parsing localized names or checking sprite name strings, querying `_npc.npcID` directly provides instant $O(1)$ portrait resolution that works across all languages:

```gml
function Radar_GetPortrait(_npc) {
    if (!variable_instance_exists(_npc, "npcID")) return -1;
    var _id = variable_instance_get(_npc, "npcID");
    if (!is_numeric(_id)) return -1;

    switch(_id) {
        case 0:  return sprNPCPortraitGuide;
        case 1:  return sprNPCPortraitBlacksmith;
        case 3:  return sprNPCPortraitMerchant;
        case 4:  return sprNPCPortraitWanderingMerchant;
        case 5:  return sprNPCPortraitBard;
        case 6:  return sprNPCPortraitWitch;
        case 8:  return sprNPCPortraitMiner;
        case 9:  return sprNPCPortraitFarmer;
        case 10: return sprNPCPortraitCarpenter;
        case 11: return sprNPCPortraitSkeleton;
        case 12: return sprNPCPortraitChef;
        case 13: return sprNPCPortraitFisherman;
        case 14: return sprNPCPortraitSummoner;
        case 15: return sprNPCPortraitElectrician;
        case 18: return sprNPCPortraitStylish;
        case 19: return sprNPCPortraitGhost;
        case 21: return sprNPCPortraitCartographer;
        case 22: return sprNPCPortraitMichael;
        case 23: return sprNPCPortraitGizmo;
        case 24: return sprNPCPortraitGoggs;
        case 25: return sprNPCPortraitGumns;
        case 26: return sprNPCPortraitNurse;
        case 27: return sprNPCPortraitLibrarian;
        case 28: return sprNPCPortraitRobot;
        case 29: return sprNPCPortraitPenguin;
        case 30: return sprNPCPortraitEnchantress;
        case 31: return sprNPCPortraitDryad04;
        case 32: return sprNPCPortraitDryad02;
        case 33: return sprNPCPortraitDryad03;
        case 34: return sprNPCPortraitDryad01;
        case 35: return sprNPCPortraitLoonaru01;
        case 36: return sprNPCPortraitLoonaru02;
        case 37: return sprNPCPortraitLoonaru03;
        case 38: return sprNPCPortraitLoonaru04;
    }
    return -1;
}
```

---

## 5. 🌫️ Minimap Surface Hooking (Fog Mod)

The game's minimap renders fog of war through `MINIMAP.render_surface`.  
By hooking into this surface draw call, we can adjust the alpha transparency of the explored overlay without modifying world generation files or save states:

```gml
function FogAlpha_Install() {
    if (variable_global_exists("MINIMAP") && !is_undefined(global.MINIMAP)) {
        // Adjust alpha blending on the fog surface to achieve 95% translucency
        // Retains discovered terrain and structures while keeping fog visual aesthetics
    }
}
```

---

## 6. ⚡ Performance & Smart HUD / Cutscene Occlusion

To maintain a consistent 60 FPS and cleanly hide radar elements during cutscenes, menus, and boss encounters:
1. **Batch Coordinate Updates (15-Frame Interval):** Coordinate updates for off-screen NPCs run every 15 frames instead of every single step.
2. **Identity Resolution Throttling:** Name and portrait resolution runs once upon spawn; unresolved entities retry up to 20 ticks before caching default values.
3. **Cutscene Detection via Engine Callables:** Queries `cutscene_is_playing` and `cutscene_is_playing_except_player` dynamically:
   ```gml
   function Radar_CutsceneActive() {
       var _m = ModInstance.Get("Radar");
       if (_m == undefined) return false;
       if (is_callable(_m.cutscenePlaying) && Radar_Call(_m.cutscenePlaying)) return true;
       if (is_callable(_m.cutscenePlayingOther) && Radar_Call(_m.cutscenePlayingOther)) return true;
       return false;
   }
   ```
4. **Smart GUI Occlusion Detection:** Suppresses HUD drawing when full-screen menus, cutscenes, or dialogue windows are active:
   ```gml
   function Radar_HUDVisible() {
       if (!instance_exists(objGUIIngameController)) return false;
       if (Radar_CutsceneActive()) return false;
       if (variable_global_exists("guiEnabled") && !global.guiEnabled) return false;
       if (variable_global_exists("guiStatsEnabled") && !global.guiStatsEnabled) return false;
       if (variable_global_exists("guiMapEnabled") && !global.guiMapEnabled) return false;
       if (instance_exists(objGUIMapChartController)
       || instance_exists(objGUIMenuController)
       || instance_exists(objGUINPCController)
       || instance_exists(objGUIShopController)
       || instance_exists(objGUICraftingController)
       || instance_exists(objGUICodexController)
       || instance_exists(objGUICommunityController)
       || instance_exists(objGUIShipNavigationController))
           return false;
       return true;
   }
   ```
5. **Zero Disk I/O During Game Loop:** All lookups operate entirely in memory.
