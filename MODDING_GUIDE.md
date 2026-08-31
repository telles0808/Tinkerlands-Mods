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
    └── <ModKey>.json
```

* **`info.json`**:
  ```json
  {
      "name": "telles0808_id5004_tomtom",
      "author": "Telles0808",
      "version": "1.0.0",
      "description": "TomTom navigation mod for Tinkerlands"
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

### Mod Identification (`id`)
Each mod must be assigned a unique numeric identifier in its script JSON to prevent collisions within the engine's internal mod loader registry:
* `Fog = 5001`
* `RealClock = 5002`
* `BO (Better Organizer) = 5003`
* `TomTom = 5004`
* `Monitor = 5005`

### Cache & Hot-Reload Behavior
* **Mod Installation Path:** `%SteamLibrary%\steamapps\common\Tinkerlands\mods\<ModFileName>.mod`
* **Local AppData Cache:** `%LOCALAPPDATA%\Tinkerlands\temp`
* **Pack Version Increment:** `%LOCALAPPDATA%\Tinkerlands\packver` (incrementing this integer forces the engine to discard cached scripts and unpack the latest `.mod` files on next launch).

---

## 2. ⏱️ Lifecycle Events & Mod Instances

The Apollo modding interface exposes clean lifecycle hooks:

```gml
OnModLoad(function() {
    // Initial mod loading phase during game boot
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

> [!CAUTION]
> **Initialization Safety:** Never perform heavy disk I/O, window manipulation, or UI state changes inside `OnModLoad`. At this stage, the DirectX rendering context is still initializing, and blocking it can cause a permanent white-screen freeze. Always defer mod state initialization to `OnWorldGenerationEnd`.

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

## 4. 🧭 HUD Occlusion, Tutorial & Cutscene Detection

To cleanly hide mod HUD elements during cutscenes, full-screen menus, or dialogues:

```gml
function IsHUDVisible() {
    if (!instance_exists(objGUIIngameController)) return false;
    if (variable_global_exists("guiEnabled") && !global.guiEnabled) return false;
    if (variable_global_exists("guiStatsEnabled") && !global.guiStatsEnabled) return false;

    // Active tutorial check
    if (variable_global_exists("WORLD_FLAGS")) {
        var _wf = variable_global_get("WORLD_FLAGS");
        if (is_struct(_wf) && variable_struct_exists(_wf, "tutorialCompleted") && !_wf.tutorialCompleted) {
            return false;
        }
    }

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

### UI Click-Through Prevention (`craftMo`)
When drawing clickable GUI controls, prevent the click from registering as an in-world weapon or tool swing:

```gml
with (objGUIIngameController) {
    craftMo = true;
}
Input.DisableMenuInputs(0.1);
```

---

## 5. 🗺️ Minimap & Mapping Architecture (TomTom)

### Minimap Edge Clamping & Surface Bounds
In the HUD, the native minimap viewport is clamped to the world's physical boundaries (`0` to `MAP_WIDTH` and `MAP_HEIGHT`). When the player approaches the outer edge of an island, the camera stops scrolling and the player moves out of the center toward the border.

A naive relative calculation (`target - player`) assumes the player remains in the center, causing pins to drift on the minimap near borders.

**Clean Clamped Camera Solution:**
1. Extract dynamic world dimensions in tiles from `MINIMAP.surfaceWorld` via `surface_get_width` / `surface_get_height` (or global `MAP_WIDTH` / `MAP_HEIGHT`).
2. Calculate the half-view radius in tiles:
   ```gml
   var _halfViewX = ((_miniRight - _miniLeft) * 0.5) / _miniScale;
   var _halfViewY = ((_miniBottom - _miniTop) * 0.5) / _miniScale;
   ```
3. Clamp the virtual minimap camera:
   ```gml
   var _camX = (_mapW <= _halfViewX * 2) ? (_mapW * 0.5) : clamp(_playerMapX, _halfViewX, _mapW - _halfViewX);
   var _camY = (_mapH <= _halfViewY * 2) ? (_mapH * 0.5) : clamp(_playerMapY, _halfViewY, _mapH - _halfViewY);
   ```
4. Project target coordinates using the clamped camera:
   ```gml
   var _targetMiniX = _miniCenterX + (_targetMapX - _camX) * _miniScale;
   var _targetMiniY = _miniCenterY + (_targetMapY - _camY) * _miniScale;
   ```

### Expedition Island Isolation (`WORLD` Struct)
Procedural expedition islands on the ship's navigation matrix are saved under canonical file patterns: `RandomIsland<col>x<row>.sav` (e.g., `RandomIsland2x0`).

* **GameMaker VM Scope:** The native `WORLD` struct is declared as a `globalvar`. The expression `variable_global_exists("WORLD")` checks the dictionary of `global` and can return `false`. Always access `WORLD` safely using `try / catch`:
  ```gml
  function GetWorldStruct() {
      try { if (is_struct(WORLD)) return WORLD; } catch(_e) {}
      try { if (variable_global_exists("WORLD")) { var _gw = variable_global_get("WORLD"); if (is_struct(_gw)) return _gw; } } catch(_e2) {}
      return undefined;
  }
  ```
* **Island Key Hierarchy:**
  1. `WORLD.name`: Returns canonical name (e.g., `"RandomIsland2x0"`). On the home island, returns `"main"` or `"undefined"`.
  2. `WORLD.islandID`: Unique session island index.
  3. `WORLD.seed`: Procedural generation seed.
  4. `WORLD.mapgenID`: Biome generator ID (e.g., `52` for volcanic). Note that multiple islands of the same biome share the same `mapgenID`, so `name` or `seed` must be prioritized.

### Native UI Sprites
* **Explored / Visited Pin:** The engine's native green checkmark sprite is `sprGUIIngameCodexIconCompleted` (from the Codex interface). Note that `sprGUIIngameIconCheck` is natively red.

---

## 6. 🗄️ Container System & High-Performance Optimization (Better Organizer)

### Item Movement Pipeline
Never modify item `ds_map` quantities directly without routing through the engine's container manager. Always use `container_item_move`:

```gml
var _move_fn = variable_global_get("container_item_move");
if (is_callable(_move_fn)) {
    script_execute(_move_fn, _item_map, _destination_container);
}
```

### Checking Favorite / Locked Items
Use the official native engine API call to check whether an item is locked or marked as favorite:

```gml
if (Item.GetProperty(itemMap, E_ITEM_DATA.favorite)) {
    // Item is marked as favorite - skip automated moves/deposit
}
```

### Category Bitmask Filtering
Items store their category identifier at key index `7` in their `ds_map`:

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

### High-Performance Modding Rules

1. **Avoid Quadratic ($O(N^2)$) Instance Lookups:**
   * Calling `instance_find(obj, i)` inside a `for (var i = 0; i < count; i++)` loop forces GameMaker to traverse the object list from index 0 on every iteration, leading to $O(N^2)$ execution.
   * **Best Practice:** Use `with(obj)` with a local variable and `break` once a match is found. This executes as a native linear $O(N)$ traversal:
     ```gml
     function GetChestSection(_container) {
         var _section = "";
         if (instance_exists(objInteractableChest)) {
             with (objInteractableChest) {
                 if (variable_instance_exists(id, "container") && id.container == _container) {
                     _section = "chest_x" + string(round(x)) + "_y" + string(round(y));
                     break;
                 }
             }
         }
         return _section;
     }
     ```

2. **Eliminate Synchronous File I/O During Gameplay:**
   * Opening, writing, and closing files (e.g., `file_text_open_append`) during `Step` or `Draw` causes synchronous OS disk locks that freeze the main thread and induce micro-stuttering. Reserve file writing strictly for explicit save events.

3. **Throttle Step Polling:**
   * Heavy operations—such as querying nearby containers or resolving spatial hashes—do not need to execute at 60 FPS. Execute them once when an interface opens, and throttle background state polling to intervals of 10–15 frames (~4–6 times per second).

---

## 7. 🕒 Computer Time & Topmost Overlays (RealClock)

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

## 8. 🖥️ Multi-Monitor Window Management & Borderless Fullscreen

### Windows Virtual Desktop Coordinate Space
In multi-monitor Windows setups, the primary display is anchored at `(X = 0, Y = 0)`. Secondary monitors are positioned in global virtual screen coordinates:
* **Monitor Left of Primary:** Negative X coordinates (e.g., `X = -1920, Y = 0` for 1080p).
* **Monitor Right of Primary:** Positive X coordinates (e.g., `X = 1920, Y = 0`).

### The Clean Native Solution
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
> A window with `window_set_showborder(false)` spanning `(target_x, 0)` at `1920x1080` **is** the native Borderless Fullscreen on that monitor. Re-enabling the fullscreen flag causes Direct3D to jump back to Display 1.
