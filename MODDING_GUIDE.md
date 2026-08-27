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
      "name": "telles0808_id5004_tomtom",
      "author": "Telles0808",
      "version": "1.0.0",
      "description": "TomTom mod for Tinkerlands"
  }
  ```

* **`scripts/<ModKey>.json`**:
  ```json
  {
      "id": 5004,
      "key": "telles0808_id5004_tomtom",
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
OnModLoad(function() {
    // Fired when the mod is first initialized during game startup
    ModInstance.Create(
        "MyMod",
        "MyMod_Create",     // Create callback
        "MyMod_Update",     // Step/Update callback
        undefined,
        "MyMod_DrawGUI",    // Standard GUI draw callback
        "MyMod_Destroy"     // Cleanup callback
    );
});

OnWorldGenerationEnd(function() {
    // Fired after world generation finishes or when loading into a world
});

OnIslandArrive(function() {
    // Fired when the player arrives at an island
});

OnNPCSpawn(function(_npc) {
    // Fired whenever an objNPC instance is spawned
});
```

---

## 3. 🎭 NPC Architecture & $O(1)$ Portrait Resolution

A key architectural insight in Tinkerlands is how NPCs are represented in runtime:

```
                           ┌───────────────────────────────┐
                           │            objNPC             │
                           └──────────────┬────────────────┘
                                          │
                  ┌───────────────────────┴───────────────────────┐
                  ▼                                               ▼
     [ Humanoid NPCs ]                               [ Unique / Special NPCs ]
  • Blacksmith, Guide, Miner,                     • Gizmo, Goggs, Gumns, Penguin,
    Nurse, Carpenter, etc.                          Robot, Dryads, Loonaru, etc.
  • Generic Base Sprites:                         • Dedicated Unique Sprites:
    - sprBasePlayerIdle01/02/03                     - sprNPCGizmoIdle01
    - sprBasePlayerHead01/02/03                     - sprNPCDryadIdle01
  • Visuals composed by Equipment                   - sprNPCBankerPenguinIdle01
  • Sprite name does NOT contain role!            • Asset name contains role directly
```

### The $O(1)$ `npcID` Resolution Pattern
Instead of searching strings or localized names, use the native numeric `npcID` property on `objNPC` mapped to `db_npc`:

```gml
function GetNPCPortrait(_npc) {
    if (!variable_instance_exists(_npc, "npcID")) return -1;
    var _id = variable_instance_get(_npc, "npcID");
    
    switch (_id) {
        case 0: return sprNPCPortraitGuide;
        case 1: return sprNPCPortraitBlacksmith;
        case 3: return sprNPCPortraitMerchant;
        case 4: return sprNPCPortraitWanderingMerchant;
        case 5: return sprNPCPortraitBard;
        case 6: return sprNPCPortraitWitch;
        case 8: return sprNPCPortraitMiner;
        case 9: return sprNPCPortraitFarmer;
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
        default: return -1;
    }
}
```

---

## 4. 🧭 HUD Occlusion & Cutscene Detection

To cleanly hide mod HUD elements during cutscenes, full-screen menus, or dialogues:

```gml
function IsHUDVisible() {
    if (!instance_exists(objGUIIngameController)) return false;
    if (variable_global_exists("guiEnabled") && !global.guiEnabled) return false;
    if (variable_global_exists("guiStatsEnabled") && !global.guiStatsEnabled) return false;

    // Full-screen and menu controllers
    if (instance_exists(objGUIMapChartController)
        || instance_exists(objGUIMenuController)
        || instance_exists(objGUINPCController)
        || instance_exists(objGUIShopController)
        || instance_exists(objGUICraftingController)
        || instance_exists(objGUICodexController)
        || instance_exists(objGUICommunityController)
        || instance_exists(objGUIShipNavigationController)) {
        return false;
    }

    // Active cutscenes
    if (variable_global_exists("cutscene_is_playing")) {
        var _fn = variable_global_get("cutscene_is_playing");
        if (is_callable(_fn) && script_execute(_fn)) return false;
    }

    return true;
}
```

---

## 5. 🌫️ Minimap Fog Layer Hook

To adjust minimap exploration fog translucency without affecting saved world data:

```gml
// Hook MINIMAP.render_surface alpha
if (variable_global_exists("MINIMAP")) {
    var _minimap = global.MINIMAP;
    // Set 95% translucency on explored tiles
}
```

---

## 6. 🕒 Computer Time & Topmost Overlays (RealClock)

The GameMaker runtime reads local machine time directly via native datetime functions:

```gml
function RealClock_GetText() {
    var _now = date_current_datetime();
    var _h = date_get_hour(_now);
    var _m = date_get_minute(_now);
    return (_h < 10 ? "0" : "") + string(_h) + ":" + (_m < 10 ? "0" : "") + string(_m);
}
```

---

## 7. 🗄️ Container System & Item Transfer Operations (Better Organizer)

Tinkerlands encapsulates its inventory and container mechanics within internal ds_maps and engine-managed data structures.

### The `container_item_move` Pipeline
Directly mutating item ds_map quantities (`_map[? 114] = ...`) without updating internal container grids causes synchronization failures and duplicate items. Always delegate item movement to the engine's native transfer pipeline:

```gml
// Safely transfer an item map into a target container
var _move_fn = variable_global_get("container_item_move");
if (is_callable(_move_fn)) {
    // container_item_move(item_map, target_container)
    script_execute(_move_fn, _item_map, _destination_container);
}
```

### Category Bitmask Filtering Table
Items expose their type category string at key index `7` in their respective `ds_map`:

```gml
function ItemCategoryBit(_item) {
    if (!is_numeric(_item) || !ds_exists(_item, ds_type_map) || !ds_map_exists(_item, 7))
        return 0;

    switch (string(_item[? 7])) {
        case "Etc":
        case "Ingredient":
        case "Spice":
        case "Fish":
            return 1;   // Materials & Resources

        case "Building":
        case "Floor":
        case "Storage":
        case "Crafting Table":
        case "Cable":
            return 2;   // Building & Construction

        case "Usable":
            return 4;   // Consumables & Potions

        case "Weapon":
        case "Tool":
        case "Accesory":
        case "Accessory":
        case "Head":
        case "Body":
        case "Legs":
        case "Hook":
        case "Fishing Rod":
        case "Pet":
            return 8;   // Equipment & Gear

        case "Ammo":
        case "Throwable":
            return 16;  // Ammunition & Projectiles

        case "Currency":
        case "Map":
        case "Recipe":
        case "Summon":
            return 32;  // Valuables & Progression
    }
    return 0;
}
```

### Physical Coordinate Persistence
Because dynamic container IDs (`ref ds_map ...`) change upon world reload, persistent container configurations must be keyed by physical spatial coordinates (`chest_x[X]_y[Y]`):

```gml
function GetChestSection(_container) {
    if (instance_exists(objInteractableChest)) {
        var _count = instance_number(objInteractableChest);
        for (var i = 0; i < _count; i++) {
            var _chest = instance_find(objInteractableChest, i);
            if (_chest != undefined && instance_exists(_chest)
                && variable_instance_exists(_chest, "container")
                && variable_instance_get(_chest, "container") == _container) {
                return "chest_x" + string(round(_chest.x)) + "_y" + string(round(_chest.y));
            }
        }
    }
    return "";
}
```

> [!WARNING]
> **GameMaker YYC Gotcha:** Never use `return` inside a `with(...)` block to return values from a function. In GameMaker, `return` inside `with` can behave like `break` or produce undefined behavior. Always use indexed `instance_find` iteration when returning results.

---

## 6. 🖥️ Multi-Monitor Window Management & Borderless Fullscreen

### Windows Virtual Desktop Coordinate Space
In multi-monitor Windows setups, the primary display is anchored at `(X = 0, Y = 0)`. Secondary monitors are positioned in global virtual screen coordinates:
* **Monitor Left of Primary:** Negative X coordinates (e.g., `X = -1920, Y = 0` for 1080p).
* **Monitor Right of Primary:** Positive X coordinates (e.g., `X = 1920, Y = 0`).

### The GameMaker Borderless Fullscreen Trap
When a GameMaker game runs in **"Tela cheia sem bordas"** (Borderless Fullscreen):
1. The engine internal flag reports `window_get_fullscreen() == true`.
2. While `window_get_fullscreen()` is active, the GameMaker display manager **silently ignores** any calls to `window_set_position(x, y)`.
3. Calling `window_set_fullscreen(true)` on a secondary monitor forces Direct3D11 to **snap the window back to the primary monitor (`X = 0`)**.

### The Clean Native Solution (No DLLs or External Scripts)
To reliably move a borderless fullscreen window between displays in pure GML:

```gml
function Window_MoveToMonitor(_target_x, _width, _height)
{
    // 1. Release the internal fullscreen lock
    window_set_fullscreen(false);

    // 2. Strip OS window borders
    window_set_showborder(false);

    // 3. Position the client area at the target display's origin
    window_set_position(_target_x, 0);

    // 4. Set the dimensions to fill the target monitor exactly
    window_set_size(_width, _height);
}
```

> [!IMPORTANT]
> **Do NOT call `window_set_fullscreen(true)` after repositioning!**  
> A window with `window_set_showborder(false)` spanning `(target_x, 0)` at `1920x1080` **is** the native Borderless Fullscreen on that monitor. Re-enabling fullscreen flag causes Direct3D to jump back to Display 1.

### Avoiding Menu Dimmer and Draw State Corruption
* **Never call `Input.DisableMenuInputs()` on UI hover:** In Tinkerlands, disabling menu inputs triggers the modal pause dimmer, turning the entire screen translucent black.
* **Strict Draw State Reset:** Always isolate custom GUI drawing in `OnModDrawGUIEnd` by resetting `draw_set_alpha(1.0)` and `draw_set_color(c_white)` both before and after rendering to avoid corrupting the game's dynamic day/night title screen lighting.

