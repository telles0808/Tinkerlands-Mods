/*
    ========================================================================
    TINKERLANDS - TomTom
    Author: Telles0808
    ID: 5004
    ========================================================================
*/

// ---------------------------------------------------------------------------
// LIFECYCLE
// ---------------------------------------------------------------------------

OnIslandArrive(function()
{
    var _m = ModInstance.Get("TomTom");

    if(_m != undefined)
    {
        _m.is_main_island = false;
        _m.npcs        = [];
        _m.mobs        = [];
        _m.chests      = [];
        _m.scan        = true;
        _m.last_region = undefined;
        _m.map_open    = false;
        _m.drag_active = false;
        TomTom_EnsureDefaults(_m);
        TomTom_LoadPins(_m);
    }
});

OnIslandFirstArrive(function()
{
    var _m = ModInstance.Get("TomTom");

    if(_m != undefined)
    {
        _m.is_main_island = false;
        _m.npcs        = [];
        _m.mobs        = [];
        _m.chests      = [];
        _m.scan        = true;
        _m.last_region = undefined;
        _m.map_open    = false;
        _m.drag_active = false;
        TomTom_EnsureDefaults(_m);
        TomTom_LoadPins(_m);
    }
});

OnMainIslandArrive(function()
{
    var _m = ModInstance.Get("TomTom");

    if(_m != undefined)
    {
        _m.is_main_island = true;
        _m.current_island = "island_main";
        _m.npcs        = [];
        _m.mobs        = [];
        _m.chests      = [];
        _m.scan        = true;
        _m.last_region = undefined;
        _m.map_open    = false;
        _m.drag_active = false;
        TomTom_EnsureDefaults(_m);
        TomTom_LoadPins(_m);
    }
});

OnWorldGenerationEnd(function()
{
    var _m = ModInstance.Get("TomTom");

    if(_m == undefined)
    {
        ModInstance.Create(
            "TomTom",
            "TomTom_Create",
            "TomTom_Update",
            undefined,
            "TomTom_Draw",
            undefined
        );
    }
    else
    {
        _m.npcs        = [];
        _m.mobs        = [];
        _m.chests      = [];
        _m.scan        = true;
        _m.last_region = undefined;
        _m.map_open    = false;
        _m.drag_active = false;
        _m.cutscenePlaying      = TomTom_GetCallable("cutscene_is_playing");
        _m.cutscenePlayingOther = TomTom_GetCallable("cutscene_is_playing_except_player");
        TomTom_EnsureDefaults(_m);
        TomTom_LoadPins(_m);
    }
});

OnNPCSpawn(function(_npc)
{
    TomTom_NPCAdd(_npc);
});

OnModDrawGUIEnd(function()
{
    var _m = ModInstance.Get("TomTom");

    if(_m != undefined)
    {
        if(_m.map_open && !TomTom_PauseMenuOpen())
        {
            TomTom_DrawMapOverlay(_m);
        }
        else if(TomTom_HUDVisible() && !_m.radar_mode)
        {
            // No Modo Minimapa (Cinza), desenha os alvos no topo do Minimapa
            TomTom_DrawMinimapRadar(_m);
        }

        TomTom_DrawPlayerCoords();
    }
});

// ---------------------------------------------------------------------------
// CREATE & DEFAULTS
// ---------------------------------------------------------------------------

function TomTom_SafeSprite(_name, _fallback)
{
    if(variable_global_exists(_name))
    {
        var _val = variable_global_get(_name);
        if(is_numeric(_val) && sprite_exists(_val))
            return _val;
    }
    var _idx = asset_get_index(_name);
    if(_idx >= 0 && sprite_exists(_idx))
        return _idx;

    return _fallback;
}

function TomTom_EnsureDefaults(_m)
{
    if(_m == undefined) return;
    if(!variable_instance_exists(_m, "radar_mode"))       _m.radar_mode       = true;
    if(!variable_instance_exists(_m, "track_npcs"))       _m.track_npcs       = true;
    if(!variable_instance_exists(_m, "track_chests"))     _m.track_chests     = true;
    if(!variable_instance_exists(_m, "track_mobs"))       _m.track_mobs       = true;
    if(!variable_instance_exists(_m, "player_was_alive")) _m.player_was_alive = true;
    if(!variable_instance_exists(_m, "npcs"))             _m.npcs             = [];
    if(!variable_instance_exists(_m, "mobs"))             _m.mobs             = [];
    if(!variable_instance_exists(_m, "chests"))           _m.chests           = [];
}

function TomTom_Create()
{
    // Sonar & Radar States
    radar_mode           = true;  // true = Screen Edge TomTom (Colorido), false = Minimap GPS (Cinza)
    track_npcs           = true;  // 👤 NPCs / Players
    track_chests         = true;  // 📦 Baús & Pins de Mapa
    track_mobs           = true;  // 👹 Mobs / Monstros / Bosses (Goblin)

    player_was_alive     = true;  // Monitora morte para gerar pin automático de lápide/caixão

    npcs                 = [];
    mobs                 = [];
    chests               = [];
    scan                 = true;
    tick                 = 0;
    mob_tick             = 0;
    chest_tick           = 0;
    last_region          = undefined;
    cutscenePlaying      = TomTom_GetCallable("cutscene_is_playing");
    cutscenePlayingOther = TomTom_GetCallable("cutscene_is_playing_except_player");

    // Map & Pins
    map_open             = false;
    current_island       = "";
    pins                 = [];
    selected_pin         = -1;
    drag_active          = false;
    drag_type            = -1;
    drag_pin_idx         = -1;

    TomTom_LoadPins(id);
}

// ---------------------------------------------------------------------------
// HELPERS & VISIBILITY
// ---------------------------------------------------------------------------

function TomTom_ScaleRatio()
{
    var _h = display_get_gui_height();
    return (_h > 0) ? (_h / 1080.0) : 1.0;
}

function TomTom_GetCallable(_name)
{
    if(!variable_global_exists(_name))
        return undefined;

    var _callable = variable_global_get(_name);
    return is_callable(_callable) ? _callable : undefined;
}

function TomTom_Call(_callable)
{
    if(is_method(_callable))
        return method_call(_callable, []);

    return script_execute(_callable);
}

function TomTom_ValidName(_v)
{
    return is_string(_v)
        && _v != ""
        && _v != "Null"
        && _v != "undefined"
        && _v != "<undefined>";
}

function TomTom_TutorialActive()
{
    if(variable_global_exists("WORLD_FLAGS"))
    {
        var _wf = variable_global_get("WORLD_FLAGS");
        if(is_struct(_wf) && variable_struct_exists(_wf, "tutorialCompleted"))
            return !_wf.tutorialCompleted;
    }
    return false;
}

function TomTom_WorldMapOpen()
{
    return instance_exists(objGUIMapChartController)
        || instance_exists(objGUIShipNavigationController);
}

function TomTom_CutsceneActive()
{
    var _m = ModInstance.Get("TomTom");
    if(_m == undefined) return false;

    if(is_callable(_m.cutscenePlaying)      && TomTom_Call(_m.cutscenePlaying))      return true;
    if(is_callable(_m.cutscenePlayingOther) && TomTom_Call(_m.cutscenePlayingOther)) return true;
    return false;
}

function TomTom_PauseMenuOpen()
{
    return instance_exists(objGUIMenuController);
}

function TomTom_HUDVisible()
{
    if(!instance_exists(objGUIIngameController)) return false;
    if(TomTom_TutorialActive())                  return false;
    if(TomTom_WorldMapOpen())                    return false;
    if(TomTom_CutsceneActive())                  return false;

    if(variable_global_exists("guiEnabled")      && !global.guiEnabled)      return false;
    if(variable_global_exists("guiStatsEnabled") && !global.guiStatsEnabled) return false;
    if(variable_global_exists("guiMapEnabled")   && !global.guiMapEnabled)   return false;

    if(instance_exists(objGUIMenuController)
    || instance_exists(objGUINPCController)
    || instance_exists(objGUINPCGiftController)
    || instance_exists(objGUINPCStorageController)
    || instance_exists(objGUIShopController)
    || instance_exists(objGUICraftingController)
    || instance_exists(objGUICodexController)
    || instance_exists(objGUICommunityController)
    || instance_exists(objGUIGuideController)
    || instance_exists(objGUIBank)
    || instance_exists(objGUIEnchant)
    || instance_exists(objGUIReforgeController)
    || instance_exists(objGUIRecyclerController))
    {
        return false;
    }

    return true;
}

// ---------------------------------------------------------------------------
// PIN SPRITES (0=POI, 1=Storage, 2=Question, 3=Boss, 4=Death/Lápide)
// ---------------------------------------------------------------------------

function TomTom_PinSprite(_type)
{
    switch(_type)
    {
        case 0: return sprGUIIngameIconPOI;           // 📍 Waypoint
        case 1: return sprGUIIngameIconStorage;       // 📦 Storage
        case 2: return sprGUIIngameIconQuestionMark;  // ❓ Question Mark
        case 3: return sprGUIIngameIconBoss;          // 💀 Boss
        case 4: return sprGUIIngameIconTeleport;      // 🌀 Portal Azul (Teleporte)
        case 5: return sprTombStone;                  // 🪦 Lápide (Death Pin)
        case 6: return TomTom_SafeSprite("sprGUIIngameCodexIconCompleted", sprGUIIngameIconPOI); // ✅ V de Certo Verde (Explorado / Visitado)
    }
    return sprGUIIngameIconPOI;
}

// ---------------------------------------------------------------------------
// MAP PANEL GEOMETRY
// ---------------------------------------------------------------------------

function TomTom_GetMinimap()
{
    try
    {
        if(is_struct(MINIMAP))
        {
            var _mx = variable_struct_exists(MINIMAP, "x") ? MINIMAP.x : 0;
            var _my = variable_struct_exists(MINIMAP, "y") ? MINIMAP.y : 0;
            var _ms = (variable_struct_exists(MINIMAP, "scale") && MINIMAP.scale > 0) ? MINIMAP.scale : 1.0;

            return {
                x: _mx,
                y: _my,
                scale: _ms
            };
        }
    }
    catch(_e) {}

    return { x: 0, y: 0, scale: 1.0 };
}

function TomTom_TrashGeometry()
{
    var _ratio = TomTom_ScaleRatio();
    return {
        x: 48 * _ratio,
        y: 48 * _ratio,
        size: 46 * _ratio
    };
}

function TomTom_PaletteGeometry(_index)
{
    var _ratio   = TomTom_ScaleRatio();
    var _trash   = TomTom_TrashGeometry();
    var _spacing = 48 * _ratio;
    var _start_x = _trash.x + 52 * _ratio;

    return {
        x: _start_x + _index * _spacing,
        y: _trash.y,
        size: 38 * _ratio
    };
}

function TomTom_InProtectedHeaderZone(_mx, _my)
{
    var _ratio = TomTom_ScaleRatio();
    var _gw    = display_get_gui_width();
    var _lp    = TomTom_PaletteGeometry(5); // 6 pins: index 0, 1, 2, 3, 4, 5

    if(_mx <= _lp.x + 36 * _ratio && _my <= 96 * _ratio)
        return true;

    if(_mx >= _gw * 0.5 - 200 * _ratio && _mx <= _gw * 0.5 + 200 * _ratio && _my <= 90 * _ratio)
        return true;

    return false;
}

// ---------------------------------------------------------------------------
// NPC & MOB RESOLUTION
// ---------------------------------------------------------------------------

function TomTom_NPCAdd(_npc)
{
    if(_npc == undefined || !instance_exists(_npc))
        return;

    if(instance_exists(objPlayer) && !is_undefined(MY_PLAYER))
    {
        if(variable_instance_exists(MY_PLAYER, "netRegion") && variable_instance_exists(_npc, "netRegion"))
        {
            if(_npc.netRegion != MY_PLAYER.netRegion)
                return;
        }
    }

    var _m = ModInstance.Get("TomTom");
    if(_m == undefined) return;

    for(var i = 0; i < array_length(_m.npcs); i++)
    {
        if(_m.npcs[i].inst == _npc) return;
    }

    var _id = TomTom_NPCResolve(_npc);
    array_push(_m.npcs, {
        inst:   _npc,
        x:      _npc.x,
        y:      _npc.y,
        name:   _id.name,
        sprite: _id.sprite,
        tries:  0
    });
}

function TomTom_NPCResolve(_npc)
{
    return {
        name:   TomTom_GetNPCName(_npc),
        sprite: TomTom_GetPortrait(_npc)
    };
}

function TomTom_GetNPCName(_npc)
{
    var _candidates = ["npcName", "npc_name", "displayName", "display_name", "name", "entityName", "refNPC"];
    for(var c = 0; c < array_length(_candidates); c++)
    {
        if(variable_instance_exists(_npc, _candidates[c]))
        {
            var _v = variable_instance_get(_npc, _candidates[c]);
            if(TomTom_ValidName(_v)) return string(_v);
        }
    }

    if(variable_instance_exists(_npc, "npcID") && is_numeric(_npc.npcID))
    {
        switch(round(_npc.npcID))
        {
            case 0:  return "Guia";
            case 1:  return "Ferreiro";
            case 3:  return "Mercador";
            case 4:  return "Vendedor Ambulante";
            case 5:  return "Bardo";
            case 6:  return "Bruxa";
            case 8:  return "Minerador";
            case 9:  return "Fazendeiro";
            case 10: return "Carpinteiro";
            case 11: return "Esqueleto";
            case 12: return "Chef";
            case 13: return "Pescador";
            case 14: return "Invocador";
            case 15: return "Eletricista";
            case 18: return "Estilista";
            case 19: return "Fantasma";
            case 21: return "Cartografo";
            case 22: return "Michael";
            case 23: return "Gizmo";
            case 24: return "Goggs";
            case 25: return "Gumns";
            case 26: return "Enfermeira";
            case 27: return "Bibliotecario";
            case 28: return "Robo";
            case 29: return "Pinguim";
            case 30: return "Encantadora";
        }
    }

    return "NPC";
}

function TomTom_GetPortrait(_npc)
{
    if(variable_instance_exists(_npc, "npcID"))
    {
        var _id = variable_instance_get(_npc, "npcID");
        if(is_numeric(_id))
        {
            switch(round(_id))
            {
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
        }
    }

    if(variable_instance_exists(_npc, "sprite_index") && sprite_exists(_npc.sprite_index))
        return _npc.sprite_index;

    return sprNPCPortraitGuide;
}

function TomTom_GetMobName(_mob)
{
    if(variable_instance_exists(_mob, "name") && TomTom_ValidName(_mob.name)) return string(_mob.name);
    if(variable_instance_exists(_mob, "mobName") && TomTom_ValidName(_mob.mobName)) return string(_mob.mobName);
    if(variable_instance_exists(_mob, "refMob") && TomTom_ValidName(_mob.refMob)) return string(_mob.refMob);

    if(variable_instance_exists(_mob, "mobID"))
    {
        var _mid = _mob.mobID;
        switch(_mid)
        {
            case 1:   return "Purple Toad";
            case 2:   return "Swamp Thing";
            case 3:   return "Flying Eye";
            case 7:   return "Butterfly";
            case 8:   return "Butterfly";
            case 9:   return "Butterfly";
            case 10:  return "Butterfly";
            case 11:  return "Butterfly";
            case 12:  return "Butterfly";
            case 13:  return "Mineral Spider";
            case 14:  return "Crystal Slime";
            case 19:  return "Shooting Flower";
            case 22:  return "Mini Spider";
            case 24:  return "Green Slime";
            case 25:  return "Blue Slime";
            case 26:  return "Red Slime";
            case 28:  return "Yellow Slime";
            case 37:  return "Angry Cactus";
            case 38:  return "Corsair Skeleton";
            case 39:  return "Pirate Skeleton";
            case 43:  return "Mummy";
            case 47:  return "Firefly";
            case 49:  return "Orc";
            case 50:  return "Red Crab";
            case 54:  return "Scorpion";
            case 55:  return "Winter Wolf";
            case 56:  return "Frog Prince";
            case 60:  return "Leech";
            case 61:  return "Golem";
            case 62:  return "Yeti";
            case 63:  return "Bat";
            case 66:  return "Slime King";
            case 67:  return "Monkey";
            case 70:  return "Rat";
            case 74:  return "Crotalus";
            case 75:  return "Quetzalcoatl";
            case 76:  return "Crocodile";
            case 78:  return "Dragonfly";
            case 80:  return "Maneater";
            case 84:  return "Necromancer";
            case 87:  return "Vampire";
            case 144: return "Bee";
            case 145: return "Rabbit";
            case 182: return "Goblin";
            case 187: return "Blue Crab";
        }
    }
    return "Monster";
}

function TomTom_GetPlayerName(_player)
{
    if(variable_instance_exists(_player, "playerName"))
    {
        var _n = variable_instance_get(_player, "playerName");
        if(TomTom_ValidName(_n)) return string(_n);
    }
    if(variable_instance_exists(_player, "name"))
    {
        var _n2 = variable_instance_get(_player, "name");
        if(TomTom_ValidName(_n2)) return string(_n2);
    }
    if(variable_instance_exists(_player, "username"))
    {
        var _n3 = variable_instance_get(_player, "username");
        if(TomTom_ValidName(_n3)) return string(_n3);
    }
    return "Player";
}

// ---------------------------------------------------------------------------
// UPDATE
// ---------------------------------------------------------------------------

function TomTom_Update()
{
    var _m = ModInstance.Get("TomTom");
    if(_m == undefined) return;

    if(!instance_exists(objPlayer) || is_undefined(MY_PLAYER)) return;

    TomTom_EnsureDefaults(_m);

    // 0. Detecção de Morte do Jogador (Gera Pin de Morte automático no local)
    var _is_alive = true;
    if(variable_instance_exists(MY_PLAYER, "hp") && MY_PLAYER.hp <= 0)
        _is_alive = false;

    if(_m.player_was_alive && !_is_alive)
    {
        _m.player_was_alive = false;

        var _tile = TILE_SIZE > 0 ? TILE_SIZE : 16;
        var _death_map_x = MY_PLAYER.x / _tile;
        var _death_map_y = MY_PLAYER.y / _tile;

        // Auto-cria o Pin de Morte (Tipo 5 = Lápide / Caixão) no ponto exato da morte
        var _death_reg = (variable_instance_exists(MY_PLAYER, "netRegion") && !is_undefined(MY_PLAYER.netRegion)) ? MY_PLAYER.netRegion : 0;
        array_push(_m.pins, {
            map_x:  _death_map_x,
            map_y:  _death_map_y,
            type:   5,
            region: _death_reg
        });

        TomTom_SavePins(_m);
    }
    else if(!_m.player_was_alive && _is_alive)
    {
        // Jogador renasceu / respawnou
        _m.player_was_alive = true;
    }

    if(!_is_alive) return;

    // 1. NPC Scanning / Cleanup
    var _curr_reg = variable_instance_exists(MY_PLAYER, "netRegion")
        ? variable_instance_get(MY_PLAYER, "netRegion")
        : undefined;

    var _active_island = TomTom_GetIslandKey();
    if(_curr_reg != _m.last_region || _active_island != _m.current_island)
    {
        _m.last_region     = _curr_reg;
        _m.current_island  = _active_island;
        _m.npcs            = [];
        _m.mobs            = [];
        _m.chests          = [];
        _m.scan            = true;
        TomTom_LoadPins(_m);
    }

    _m.tick++;
    if(_m.tick >= 10 || _m.scan)
    {
        _m.tick = 0;
        _m.scan = false;

        // Escaneia todas as instâncias ativas de NPCs no mundo
        var _npc_classes = ["objNPC", "objInteractableNPC", "objNPCMerchant", "objWanderingMerchant"];
        for(var nc = 0; nc < array_length(_npc_classes); nc++)
        {
            var _casset = asset_get_index(_npc_classes[nc]);
            if(_casset >= 0)
            {
                var _ncount = instance_number(_casset);
                for(var ni = 0; ni < _ncount; ni++)
                {
                    var _ninst = instance_find(_casset, ni);
                    if(instance_exists(_ninst))
                    {
                        TomTom_NPCAdd(_ninst);
                    }
                }
            }
        }

        var _has_p_reg = variable_instance_exists(MY_PLAYER, "netRegion");
        var _p_reg     = _has_p_reg ? variable_instance_get(MY_PLAYER, "netRegion") : undefined;

        for(var i = array_length(_m.npcs) - 1; i >= 0; i--)
        {
            var _n = _m.npcs[i];
            if(_n.inst == undefined || !instance_exists(_n.inst))
            {
                array_delete(_m.npcs, i, 1);
                continue;
            }

            if(_has_p_reg && variable_instance_exists(_n.inst, "netRegion"))
            {
                if(variable_instance_get(_n.inst, "netRegion") != _p_reg)
                {
                    array_delete(_m.npcs, i, 1);
                    continue;
                }
            }

            _n.x = _n.inst.x;
            _n.y = _n.inst.y;

            if((_n.name == "" || _n.name == "NPC" || _n.sprite == -1) && _n.tries < 20)
            {
                _n.tries++;
                var _id = TomTom_NPCResolve(_n.inst);
                if(_id.name   != "") _n.name   = _id.name;
                if(_id.sprite != -1) _n.sprite = _id.sprite;
            }
        }
    }

    // 2. Mob & Animal Scanning
    if(_m.track_mobs)
    {
        _m.mob_tick++;
        if(_m.mob_tick >= 10)
        {
            _m.mob_tick = 0;
            _m.mobs = [];

            var _has_p_reg = variable_instance_exists(MY_PLAYER, "netRegion");
            var _p_reg     = _has_p_reg ? variable_instance_get(MY_PLAYER, "netRegion") : undefined;
            var _def_gob   = TomTom_SafeSprite("sprGUIIngameIconBiomeGoblin", sprGUIIngameIconBoss);

            var _mob_count = instance_number(objMob);
            for(var mi = 0; mi < _mob_count; mi++)
            {
                var _minst = instance_find(objMob, mi);
                if(!instance_exists(_minst)) continue;
                if(_minst == MY_PLAYER) continue;

                // Não duplica NPCs que herdam de objMob
                if(variable_instance_exists(_minst, "npcID") && is_numeric(_minst.npcID) && _minst.npcID >= 0)
                    continue;
                if(variable_instance_exists(_minst, "refNPC"))
                    continue;
                if(variable_instance_exists(_minst, "mobID") && _minst.mobID == 18)
                    continue;

                if(_has_p_reg && variable_instance_exists(_minst, "netRegion"))
                {
                    if(variable_instance_get(_minst, "netRegion") != _p_reg)
                        continue;
                }

                if(variable_instance_exists(_minst, "visible") && !_minst.visible)
                    continue;

                var _mname = TomTom_GetMobName(_minst);
                var _mspr  = (variable_instance_exists(_minst, "sprite_index") && sprite_exists(_minst.sprite_index))
                             ? _minst.sprite_index
                             : _def_gob;

                array_push(_m.mobs, {
                    inst:   _minst,
                    x:      _minst.x,
                    y:      _minst.y,
                    sprite: _mspr,
                    name:   _mname
                });
            }
        }
    }

    // 3. Chest / Baú Scanning no Mundo
    if(_m.track_chests)
    {
        _m.chest_tick++;
        if(_m.chest_tick >= 20)
        {
            _m.chest_tick = 0;
            _m.chests = [];

            var _has_p_reg = variable_instance_exists(MY_PLAYER, "netRegion");
            var _p_reg     = _has_p_reg ? variable_instance_get(MY_PLAYER, "netRegion") : undefined;

            var _chest_names = ["objInteractableChest", "objChest", "objContainer", "objInteractableStorage"];
            for(var cn = 0; cn < array_length(_chest_names); cn++)
            {
                var _casset = asset_get_index(_chest_names[cn]);
                if(_casset >= 0)
                {
                    var _ccount = instance_number(_casset);
                    for(var c = 0; c < _ccount; c++)
                    {
                        var _cinst = instance_find(_casset, c);
                        if(!instance_exists(_cinst)) continue;

                        if(_has_p_reg && variable_instance_exists(_cinst, "netRegion"))
                        {
                            if(variable_instance_get(_cinst, "netRegion") != _p_reg)
                                continue;
                        }

                        if(variable_instance_exists(_cinst, "visible") && !_cinst.visible)
                            continue;

                        var _cspr = variable_instance_exists(_cinst, "sprite_index") ? _cinst.sprite_index : sprGUIIngameIconStorage;

                        array_push(_m.chests, {
                            inst:   _cinst,
                            x:      _cinst.x,
                            y:      _cinst.y,
                            sprite: _cspr
                        });
                    }
                }
            }
        }
    }

    // 4. Radar HUD Button & Mini Badges Input (apenas quando HUD visível e mapa fechado)
    if(TomTom_HUDVisible() && !_m.map_open)
    {
        TomTom_ButtonInput(_m);
    }

    // 5. Map toggle logic
    if(TomTom_PauseMenuOpen())
    {
        _m.map_open     = false;
        _m.drag_active  = false;
        _m.drag_pin_idx = -1;
        return;
    }

    var _gw    = display_get_gui_width();
    var _ratio = TomTom_ScaleRatio();
    var _mx    = device_mouse_x_to_gui(0);
    var _my    = device_mouse_y_to_gui(0);

    var _map_pressed = false;

    if(keyboard_check_pressed(ord("M")) || keyboard_check_pressed(ord("m")))
        _map_pressed = true;

    if(variable_global_exists("K_MAP_PRESSED") && global.K_MAP_PRESSED)
        _map_pressed = true;

    // Click no botão de mapa do HUD
    if(!_m.map_open && mouse_check_button_pressed(mb_left))
    {
        if(_mx >= _gw - 65 * _ratio && _mx <= _gw - 5 * _ratio
        && _my >= 220 * _ratio       && _my <= 275 * _ratio)
        {
            _map_pressed = true;
        }
    }

    if(_map_pressed)
    {
        _m.map_open = !_m.map_open;
        if(!_m.map_open)
        {
            _m.drag_active  = false;
            _m.drag_pin_idx = -1;
        }
    }

    // ESC fecha o mapa
    if(keyboard_check_pressed(vk_escape) && _m.map_open)
    {
        _m.map_open     = false;
        _m.drag_active  = false;
        _m.drag_pin_idx = -1;
    }

    // 6. Interações no painel do mapa
    if(_m.map_open)
    {
        TomTom_MapInput(_m);
    }
}

// ---------------------------------------------------------------------------
// RADAR HUD BUTTON & 3 SUB-BADGES GEOMETRY
// (Sonar Button 51px V e H)
// ---------------------------------------------------------------------------

function TomTom_ButtonGeometry()
{
    var _ratio = TomTom_ScaleRatio();
    var _gw    = display_get_gui_width();
    var _gh    = display_get_gui_height();

    var _frameW           = max(sprite_get_width(sprGUIIngameMinimapContainer), _gw * 0.16);
    var _frameRightMargin = max(7, _gw * 0.008);
    var _frameLeft        = _gw - _frameW - _frameRightMargin;
    var _frameTop         = max(7, _gh * 0.015);

    // Posicionado exatamente à esquerda do topo do minimapa (X: 1513, Y: 18 em 1920x1080)
    var _base_x = _frameLeft - round(86 * _ratio);
    var _base_y = _frameTop + round(2 * _ratio);

    // Sonar Button ampliado para 56px (+5px V e H)
    var _sonar_size = round(56 * _ratio);
    var _sonar_x    = _base_x;
    var _sonar_y    = _base_y + round(5 * _ratio);

    return {
        base_x:   _base_x,
        base_y:   _base_y,
        radar_x:  _sonar_x,
        radar_y:  _sonar_y,
        radar_w:  _sonar_size,
        radar_h:  _sonar_size,
        radar_cx: _sonar_x + _sonar_size * 0.5,
        radar_cy: _sonar_y + _sonar_size * 0.5,
        ratio:    _ratio
    };
}

function TomTom_BadgeGeometry(_index)
{
    var _bg    = TomTom_ButtonGeometry();
    var _ratio = _bg.ratio;

    // Mini-ícones (22px de tamanho)
    var _bsize = round(22 * _ratio);
    var _bx    = _bg.base_x + round(64 * _ratio);

    var _by    = _bg.base_y + round(8 * _ratio);
    switch(_index)
    {
        case 0: _by = _bg.base_y + round(8 * _ratio);   break; // Topo: 👤 NPCs (Guia)
        case 1: _by = _bg.base_y + round(33 * _ratio);  break; // Centro: 📦 Baús (Storage)
        case 2: _by = _bg.base_y + round(58 * _ratio);  break; // Base: 👹 Mobs (Goblin)
    }

    return {
        cx:   _bx,
        cy:   _by,
        size: _bsize
    };
}

function TomTom_ButtonInput(_m)
{
    var _bg    = TomTom_ButtonGeometry();
    var _mx    = device_mouse_x_to_gui(0);
    var _my    = device_mouse_y_to_gui(0);

    // 1. Clique nos 3 Mini-Badges (Sub-Toggles à direita)
    for(var b = 0; b < 3; b++)
    {
        var _badge = TomTom_BadgeGeometry(b);
        var _bhalf = _badge.size * 0.65;

        if(point_in_rectangle(_mx, _my, _badge.cx - _bhalf, _badge.cy - _bhalf, _badge.cx + _bhalf, _badge.cy + _bhalf))
        {
            with(objGUIIngameController) { craftMo = true; }
            Input.DisableMenuInputs(0.1);

            if(mouse_check_button_pressed(mb_left))
            {
                if(b == 0)      _m.track_npcs   = !_m.track_npcs;
                else if(b == 1) _m.track_chests = !_m.track_chests;
                else if(b == 2) _m.track_mobs   = !_m.track_mobs;

                TomTom_SavePins(_m);
                mouse_clear(mb_left);
                return;
            }
        }
    }

    // 2. Clique no Botão Principal do Sonar / Radar (à esquerda)
    if(point_in_rectangle(_mx, _my, _bg.radar_x, _bg.radar_y, _bg.radar_x + _bg.radar_w, _bg.radar_y + _bg.radar_h))
    {
        with(objGUIIngameController) { craftMo = true; }
        Input.DisableMenuInputs(0.1);

        if(mouse_check_button_pressed(mb_left))
        {
            _m.radar_mode = !_m.radar_mode;
            TomTom_SavePins(_m);
            mouse_clear(mb_left);
            return;
        }
    }
}

function TomTom_DrawButton(_m)
{
    var _bg    = TomTom_ButtonGeometry();
    var _ratio = _bg.ratio;
    var _mx    = device_mouse_x_to_gui(0);
    var _my    = device_mouse_y_to_gui(0);

    // 1. Desenho do Botão Principal (Sonar)
    var _spr_sonar = sprItemAccesorySonar;
    var _sover     = point_in_rectangle(_mx, _my, _bg.radar_x, _bg.radar_y, _bg.radar_x + _bg.radar_w, _bg.radar_y + _bg.radar_h);
    var _sscale    = (_bg.radar_w / max(sprite_get_width(_spr_sonar), sprite_get_height(_spr_sonar)))
                     * (_sover ? 1.15 : 1.0);
    var _sox       = (sprite_get_xoffset(_spr_sonar) - sprite_get_width(_spr_sonar) * 0.5) * _sscale;
    var _soy       = (sprite_get_yoffset(_spr_sonar) - sprite_get_height(_spr_sonar) * 0.5) * _sscale;

    Draw.Sprite(
        _spr_sonar, 0,
        _bg.radar_cx + _sox, _bg.radar_cy + _soy,
        _sscale, _sscale,
        0,
        _m.radar_mode ? c_white : c_gray,
        _m.radar_mode ? 1.0 : 0.45
    );

    // 2. Desenho dos 3 Mini-Badges (👤 Guia, 📦 Baú, 👹 Goblin)
    var _gob_spr = TomTom_SafeSprite("sprGUIIngameIconBiomeGoblin", sprGUIIngameIconBoss);

    for(var b = 0; b < 3; b++)
    {
        var _badge    = TomTom_BadgeGeometry(b);
        var _bactive  = (b == 0) ? _m.track_npcs : ((b == 1) ? _m.track_chests : _m.track_mobs);
        var _bover    = point_in_rectangle(_mx, _my,
                            _badge.cx - _badge.size * 0.5, _badge.cy - _badge.size * 0.5,
                            _badge.cx + _badge.size * 0.5, _badge.cy + _badge.size * 0.5);

        var _spr_badge = sprNPCPortraitGuide;
        if(b == 1)      _spr_badge = sprGUIIngameIconStorage;
        else if(b == 2) _spr_badge = _gob_spr;

        if(_spr_badge < 0 || !sprite_exists(_spr_badge))
            continue;

        var _bscale = (_badge.size / max(sprite_get_width(_spr_badge), sprite_get_height(_spr_badge)))
                      * (_bover ? 1.2 : 1.0);
        var _box    = (sprite_get_xoffset(_spr_badge) - sprite_get_width(_spr_badge) * 0.5) * _bscale;
        var _boy    = (sprite_get_yoffset(_spr_badge) - sprite_get_height(_spr_badge) * 0.5) * _bscale;

        // Moldura escura pixel-art atrás de cada mini-ícone
        draw_set_color(c_black);
        draw_rectangle(_badge.cx - _badge.size * 0.5 - 1, _badge.cy - _badge.size * 0.5 - 1,
                       _badge.cx + _badge.size * 0.5 + 1, _badge.cy + _badge.size * 0.5 + 1, false);

        Draw.Sprite(
            _spr_badge, 0,
            _badge.cx + _box, _badge.cy + _boy,
            _bscale, _bscale,
            0,
            _bactive ? (_bover ? c_yellow : c_white) : c_gray,
            _bactive ? 1.0 : 0.45
        );
    }
}

// ---------------------------------------------------------------------------
// MAP PIN INPUT & DRAG
// ---------------------------------------------------------------------------

function TomTom_MapInput(_m)
{
    var _mx    = device_mouse_x_to_gui(0);
    var _my    = device_mouse_y_to_gui(0);
    var _ratio = TomTom_ScaleRatio();

    with(objGUIIngameController)
    {
        craftMo = true;
    }

    // 1. Clicar em ícone da paleta para iniciar arrasto
    var _palette_types = [0, 1, 2, 3, 4, 6];
    for(var i = 0; i < array_length(_palette_types); i++)
    {
        var _geom = TomTom_PaletteGeometry(i);
        var _half = _geom.size * 0.5;

        if(point_in_rectangle(_mx, _my, _geom.x - _half, _geom.y - _half, _geom.x + _half, _geom.y + _half))
        {
            Input.DisableMenuInputs(0.1);

            if(mouse_check_button_pressed(mb_left))
            {
                _m.drag_active  = true;
                _m.drag_type    = _palette_types[i];
                _m.drag_pin_idx = -1;
                mouse_clear(mb_left);
                return;
            }
        }
    }

    // 2. Clicar em marcador existente no mapa (seleção / arrastar)
    var _mini  = TomTom_GetMinimap();
    var _left  = _mini.x;
    var _top   = _mini.y;
    var _scale = _mini.scale;

    for(var p = array_length(_m.pins) - 1; p >= 0; p--)
    {
        var _p   = _m.pins[p];
        var _psx = _left + _p.map_x * _scale;
        var _psy = _top  + _p.map_y * _scale;
        var _pr  = 32 * _ratio;

        if(point_in_rectangle(_mx, _my, _psx - _pr, _psy - _pr, _psx + _pr, _psy + _pr))
        {
            Input.DisableMenuInputs(0.1);

            if(mouse_check_button_pressed(mb_left))
            {
                _m.selected_pin = p;
                _m.drag_active  = true;
                _m.drag_type    = _p.type;
                _m.drag_pin_idx = p;
                mouse_clear(mb_left);
                return;
            }
            else if(mouse_check_button_pressed(mb_right))
            {
                _m.selected_pin = p;
                mouse_clear(mb_right);
                return;
            }
        }
    }

    // 3. Soltar arrasto -> criar/mover no mapa ou excluir na lixeira
    if(_m.drag_active && mouse_check_button_released(mb_left))
    {
        _m.drag_active = false;

        var _trash = TomTom_TrashGeometry();
        var _thalf = _trash.size * 0.75;

        // Soltou na lixeira -> exclui
        if(point_in_rectangle(_mx, _my, _trash.x - _thalf, _trash.y - _thalf, _trash.x + _thalf, _trash.y + _thalf))
        {
            if(_m.drag_pin_idx >= 0 && _m.drag_pin_idx < array_length(_m.pins))
            {
                array_delete(_m.pins, _m.drag_pin_idx, 1);
                if(_m.selected_pin == _m.drag_pin_idx)      _m.selected_pin = -1;
                else if(_m.selected_pin > _m.drag_pin_idx)  _m.selected_pin--;
                TomTom_SavePins(_m);
            }
            _m.drag_pin_idx = -1;
            return;
        }

        // Soltou na área protegida da barra superior -> cancela
        if(TomTom_InProtectedHeaderZone(_mx, _my))
        {
            _m.drag_pin_idx = -1;
            return;
        }

        // Coordenadas exatas do terreno do mapa
        var _map_x = (_mx - _left) / _scale;
        var _map_y = (_my - _top)  / _scale;
        var _cur_reg = (variable_instance_exists(MY_PLAYER, "netRegion") && !is_undefined(MY_PLAYER.netRegion)) ? MY_PLAYER.netRegion : 0;

        if(_m.drag_pin_idx >= 0 && _m.drag_pin_idx < array_length(_m.pins))
        {
            var _ep = _m.pins[_m.drag_pin_idx];
            _ep.map_x = _map_x;
            _ep.map_y = _map_y;
            _ep.region = _cur_reg;
        }
        else
        {
            array_push(_m.pins, {
                map_x:  _map_x,
                map_y:  _map_y,
                type:   _m.drag_type,
                region: _cur_reg
            });
            _m.selected_pin = array_length(_m.pins) - 1;
        }

        TomTom_SavePins(_m);
        _m.drag_pin_idx = -1;
    }
}

// ---------------------------------------------------------------------------
// DRAW MAP OVERLAY (quando o mapa grande está aberto)
// ---------------------------------------------------------------------------

function TomTom_DrawMapOverlay(_m)
{
    var _ratio = TomTom_ScaleRatio();
    var _mx    = device_mouse_x_to_gui(0);
    var _my    = device_mouse_y_to_gui(0);
    var _mini  = TomTom_GetMinimap();
    var _left  = _mini.x;
    var _top   = _mini.y;
    var _scale = _mini.scale;
    var _has_p_reg = variable_instance_exists(MY_PLAYER, "netRegion");
    var _p_reg     = _has_p_reg ? variable_instance_get(MY_PLAYER, "netRegion") : 0;

    // 1. Marcadores no canvas do mapa
    for(var i = 0; i < array_length(_m.pins); i++)
    {
        if(_m.drag_active && _m.drag_pin_idx == i)
            continue;

        var _p = _m.pins[i];

        // Isola caverna de superfície: pin da caverna só aparece na caverna, e vice-versa
        var _pin_reg = variable_struct_exists(_p, "region") ? _p.region : 0;
        if(_has_p_reg && _pin_reg != _p_reg)
            continue;

        var _psx    = _left + _p.map_x * _scale;
        var _psy    = _top  + _p.map_y * _scale;
        var _spr    = TomTom_PinSprite(_p.type);
        var _size   = 36 * _ratio;
        var _is_sel = (_m.selected_pin == i);
        var _iscale = _size / max(sprite_get_width(_spr), sprite_get_height(_spr));

        Draw.Sprite(
            _spr, 0,
            _psx, _psy,
            _iscale, _iscale,
            0,
            _is_sel ? c_yellow : c_white,
            1.0
        );

        // Exibe coordenadas (X, Y) abaixo do marcador (+50% de escala: 1.65)
        var _tx = round(_p.map_x);
        var _ty = round(_p.map_y);
        var _coord_str = string(_tx) + ", " + string(_ty);

        GUI.DrawText(
            _psx,
            _psy + 24 * _ratio,
            _coord_str,
            5,
            _is_sel ? c_yellow : c_white,
            1,
            1.65 * _ratio
        );
    }

    // 2. Lixeira iluminada com aura
    var _trash     = TomTom_TrashGeometry();
    var _spr_trash = sprGUIIngameIconQuickTrash;
    var _tover     = point_in_rectangle(_mx, _my,
                        _trash.x - _trash.size * 0.5, _trash.y - _trash.size * 0.5,
                        _trash.x + _trash.size * 0.5, _trash.y + _trash.size * 0.5);
    var _tscale    = (_trash.size / max(sprite_get_width(_spr_trash), sprite_get_height(_spr_trash)))
                    * (_tover ? 1.25 : 1.0);

    Draw.Sprite(_spr_trash, 0, _trash.x, _trash.y, _tscale * 1.35, _tscale * 1.35, 0, c_white, _tover ? 0.85 : 0.45);
    Draw.Sprite(_spr_trash, 0, _trash.x, _trash.y, _tscale,         _tscale,         0, _tover ? c_red : c_white, 1.0);

    // 3. Paleta com os botões de marcadores (📍 📦 ❓ 💀 🌀 ✅)
    var _palette_types = [0, 1, 2, 3, 4, 6];
    for(var b = 0; b < array_length(_palette_types); b++)
    {
        var _ptype   = _palette_types[b];
        var _geom    = TomTom_PaletteGeometry(b);
        var _spr_pal = TomTom_PinSprite(_ptype);
        var _over    = point_in_rectangle(_mx, _my,
                            _geom.x - _geom.size * 0.5, _geom.y - _geom.size * 0.5,
                            _geom.x + _geom.size * 0.5, _geom.y + _geom.size * 0.5);
        var _pscale  = (_geom.size / max(sprite_get_width(_spr_pal), sprite_get_height(_spr_pal)))
                    * (_over ? 1.2 : 1.0);

        Draw.Sprite(_spr_pal, 0, _geom.x, _geom.y, _pscale, _pscale, 0,
                    _over ? c_yellow : c_white,
                    _over ? 1.0 : 0.85);
    }

    // 4. Pré-visualização ao arrastar (ícone sob o cursor do mouse)
    if(_m.drag_active && _m.drag_type >= 0)
    {
        var _drag_spr   = TomTom_PinSprite(_m.drag_type);
        var _drag_scale = 40 * _ratio / max(sprite_get_width(_drag_spr), sprite_get_height(_drag_spr));
        Draw.Sprite(_drag_spr, 0, _mx, _my, _drag_scale, _drag_scale, 0, c_yellow, 0.9);
    }
}

// ---------------------------------------------------------------------------
// PLAYER COORDS (canto inferior direito - estilo MapRadar / RealClock)
// ---------------------------------------------------------------------------

function TomTom_DrawPlayerCoords()
{
    if(!instance_exists(objPlayer) || is_undefined(MY_PLAYER))
        return;

    if(variable_instance_exists(MY_PLAYER, "hp") && MY_PLAYER.hp <= 0)
        return;

    if(!instance_exists(objGUIIngameController))
        return;

    if(TomTom_PauseMenuOpen())
        return;

    var _ratio = TomTom_ScaleRatio();
    var _textScale = 3.0 * _ratio; // Padrão RealClock

    var _tile = TILE_SIZE;
    if(_tile <= 0) _tile = 16;

    var _px = round(MY_PLAYER.x / _tile);
    var _py = round(MY_PLAYER.y / _tile);
    var _coord_str = string(_px) + ", " + string(_py);

    var _x = display_get_gui_width() - round(60 * _ratio);
    var _y = display_get_gui_height() - round(50 * _ratio);

    GUI.DrawText(
        _x,
        _y,
        _coord_str,
        5,
        c_yellow,
        1,
        _textScale
    );
}

// ---------------------------------------------------------------------------
// UNIFIED SCREEN TARGET DRAW
// (NPCs na tela: Oculta portrait, exibe apenas o nome centralizado embaixo)
// ---------------------------------------------------------------------------

function TomTom_DrawTarget(
    _x,
    _y,
    _name,
    _sprite,
    _w,
    _h,
    _s,
    _margin,
    _px,
    _py,
    _cam_x,
    _cam_y,
    _target_type
)
{
    var _tile       = TILE_SIZE > 0 ? TILE_SIZE : 16;
    var _dx         = _x - _px;
    var _dy         = _y - _py;
    var _dist_tiles = point_distance(_px, _py, _x, _y) / _tile;

    // Distância mínima para exibição
    if(_dist_tiles <= 1.0)
        return;

    var _sx = (_x - _cam_x) * _s;
    var _sy = (_y - _cam_y) * _s;
    var _dist_str = string(round(_dist_tiles)) + "m";

    // 1. Alvo está DENTRO da tela visível (On-Screen)
    if(_sx >= _margin && _sx <= _w - _margin && _sy >= _margin && _sy <= _h - _margin)
    {
        if(_target_type == 0) // NPC na tela -> Oculta o portrait, desenha o nome elevado e centralizado sob os pés do NPC
        {
            GUI.DrawText(_sx, _sy + 8 * _s, _name, 5, c_white, 1, _s * 0.55);
        }
        else if(_target_type == 1) // Pin do Mapa -> mostra ícone do pin + metragem
        {
            var _sw1   = sprite_get_width(_sprite);
            var _sh1   = sprite_get_height(_sprite);
            var _iscl1 = 18 * _s / max(_sw1, _sh1);
            var _sox1  = (sprite_get_xoffset(_sprite) - _sw1 * 0.5) * _iscl1;
            var _soy1  = (sprite_get_yoffset(_sprite) - _sh1 * 0.5) * _iscl1;

            Draw.Sprite(_sprite, 0, _sx + _sox1, _sy + _soy1, _iscl1, _iscl1, 0, c_white, 1);
            GUI.DrawText(_sx, _sy + 11 * _s, _dist_str, 5, c_yellow, 1, _s * 0.60);
        }
        else if(_target_type == 2) // Baú -> centralizado perfeitamente embaixo do baú
        {
            GUI.DrawText(_sx + 8 * _s, _sy + 14 * _s, _dist_str, 5, c_yellow, 1, _s * 0.55);
        }
        else if(_target_type == 3) // Mob -> centralizado embaixo do mob
        {
            var _m_lbl = (_name != "" && _name != "Monster" && _name != "Creature") ? (_name + " (" + _dist_str + ")") : _dist_str;
            GUI.DrawText(_sx, _sy + 12 * _s, _m_lbl, 5, c_white, 1, _s * 0.55);
        }
        return;
    }

    // 2. Alvo está FORA da tela -> Projeção na borda
    var _dir   = point_direction(0, 0, _dx, _dy);
    var _rad   = degtorad(_dir);
    var _vx    = cos(_rad);
    var _vy    = -sin(_rad);
    var _hw    = _w * 0.5 - _margin;
    var _hh    = _h * 0.5 - _margin;
    var _scx   = abs(_vx) > 0.0001 ? _hw / abs(_vx) : 99999;
    var _scy   = abs(_vy) > 0.0001 ? _hh / abs(_vy) : 99999;
    var _min_s = min(_scx, _scy);
    var _ex    = _w * 0.5 + _vx * _min_s;
    var _ey    = _h * 0.5 + _vy * _min_s;

    // Seta direcional projetada na margem externa
    Draw.Sprite(sprGUIIngameArrowRight, 0, _ex + _vx * 18 * _s, _ey + _vy * 18 * _s, 0.80 * _s, 0.80 * _s, _dir, c_white, 1);

    // Ícone representativo com centralização geométrica
    if(_sprite != -1 && _sprite >= 0 && sprite_exists(_sprite))
    {
        var _sw2   = sprite_get_width(_sprite);
        var _sh2   = sprite_get_height(_sprite);
        var _iscl2 = 20 * _s / max(_sw2, _sh2);
        var _sox2  = (sprite_get_xoffset(_sprite) - _sw2 * 0.5) * _iscl2;
        var _soy2  = (sprite_get_yoffset(_sprite) - _sh2 * 0.5) * _iscl2;

        Draw.Sprite(_sprite, 0, _ex + _sox2, _ey + _soy2, _iscl2, _iscl2, 0, c_white, 1);
    }

    // Texto posicionado com separação confortável (+3px) abaixo do ícone
    if(_target_type == 2 || _target_type == 1)
    {
        GUI.DrawText(_ex, _ey + 15 * _s, _dist_str, 5, c_yellow, 1, _s * 0.55);
    }
    else
    {
        var _label = (_name != "" && _name != "Monster" && _name != "Creature") ? (_name + " (" + _dist_str + ")") : _dist_str;
        GUI.DrawText(_ex, _ey + 15 * _s, _label, 5, c_white, 1, _s * 0.55);
    }
}

// ---------------------------------------------------------------------------
// MINIMAP CAMERA CENTER (Compensa o travamento nas bordas do mapa)
// ---------------------------------------------------------------------------

function TomTom_GetMinimapCameraCenter(_playerMapX, _playerMapY, _halfViewTilesX, _halfViewTilesY)
{
    var _mapW = 0;
    var _mapH = 0;

    // 1. Dimensões exatas em tiles a partir da superfície nativa do minimapa
    if(is_struct(MINIMAP))
    {
        if(variable_struct_exists(MINIMAP, "surfaceWorld"))
        {
            var _sw = MINIMAP.surfaceWorld;
            if(surface_exists(_sw))
            {
                _mapW = surface_get_width(_sw);
                _mapH = surface_get_height(_sw);
            }
        }
        else if(variable_struct_exists(MINIMAP, "surface"))
        {
            var _s = MINIMAP.surface;
            if(surface_exists(_s))
            {
                _mapW = surface_get_width(_s);
                _mapH = surface_get_height(_s);
            }
        }
    }

    // 2. Fallbacks pelas variáveis globais da engine
    if(_mapW <= 0 || _mapH <= 0)
    {
        if(variable_global_exists("MAP_WIDTH") && is_numeric(variable_global_get("MAP_WIDTH")))
            _mapW = variable_global_get("MAP_WIDTH");
        else if(variable_global_exists("WORLD_WIDTH") && is_numeric(variable_global_get("WORLD_WIDTH")))
            _mapW = variable_global_get("WORLD_WIDTH");
        else if(variable_global_exists("__MAP_WIDTH") && is_numeric(variable_global_get("__MAP_WIDTH")))
            _mapW = variable_global_get("__MAP_WIDTH");

        if(variable_global_exists("MAP_HEIGHT") && is_numeric(variable_global_get("MAP_HEIGHT")))
            _mapH = variable_global_get("MAP_HEIGHT");
        else if(variable_global_exists("WORLD_HEIGHT") && is_numeric(variable_global_get("WORLD_HEIGHT")))
            _mapH = variable_global_get("WORLD_HEIGHT");
        else if(variable_global_exists("__MAP_HEIGHT") && is_numeric(variable_global_get("__MAP_HEIGHT")))
            _mapH = variable_global_get("__MAP_HEIGHT");
    }

    // 3. Clamping oficial de borda
    if(_mapW > 0 && _mapH > 0)
    {
        var _minX = _halfViewTilesX;
        var _maxX = max(_minX, _mapW - _halfViewTilesX);
        var _minY = _halfViewTilesY;
        var _maxY = max(_minY, _mapH - _halfViewTilesY);

        return {
            x: clamp(_playerMapX, _minX, _maxX),
            y: clamp(_playerMapY, _minY, _maxY)
        };
    }

    return {
        x: _playerMapX,
        y: _playerMapY
    };
}

function TomTom_DrawMinimapTarget(_world_x, _world_y, _sprite, _color, _ratio, _only_edge)
{
    var _miniGw = display_get_gui_width();
    var _miniGh = display_get_gui_height();

    var _frameW = max(sprite_get_width(sprGUIIngameMinimapContainer), _miniGw * 0.16);
    var _frameH = max(sprite_get_height(sprGUIIngameMinimapContainer), _miniGh * 0.19);
    var _miniScale = is_struct(MINIMAP) && variable_struct_exists(MINIMAP, "scale") ? MINIMAP.scale : 1.0;
    if(_miniScale <= 0) return;

    var _frameRightMargin = max(7, _miniGw * 0.008);
    var _frameLeft        = _miniGw - _frameW - _frameRightMargin;
    var _frameTop         = max(7, _miniGh * 0.015);

    var _innerInsetX      = max(11, _frameW * 0.043);
    var _innerInsetTop    = max(13, _frameH * 0.074);
    var _innerInsetBottom = max(4, _frameH * 0.025);

    var _miniLeft   = _frameLeft + _innerInsetX;
    var _miniTop    = _frameTop + _innerInsetTop;
    var _miniRight  = _frameLeft + _frameW - _innerInsetX;
    var _miniBottom = _frameTop + _frameH - _innerInsetBottom;

    var _miniCenterX = (_miniLeft + _miniRight) * 0.5;
    var _miniCenterY = (_miniTop + _miniBottom) * 0.5;

    var _miniTile = TILE_SIZE > 0 ? TILE_SIZE : 16;
    var _playerMapX = MY_PLAYER.x / _miniTile;
    var _playerMapY = MY_PLAYER.y / _miniTile;

    var _targetMapX = _world_x / _miniTile;
    var _targetMapY = _world_y / _miniTile;

    var _halfViewTilesX = ((_miniRight - _miniLeft) * 0.5) / _miniScale;
    var _halfViewTilesY = ((_miniBottom - _miniTop) * 0.5) / _miniScale;

    var _cam = TomTom_GetMinimapCameraCenter(_playerMapX, _playerMapY, _halfViewTilesX, _halfViewTilesY);

    var _targetMiniX = _miniCenterX + (_targetMapX - _cam.x) * _miniScale;
    var _targetMiniY = _miniCenterY + (_targetMapY - _cam.y) * _miniScale;

    // Ícones no Minimapa ampliados para 16px (+2px)
    var _iconSize = round(16 * _ratio);
    var _iconHalf = _iconSize * 0.5;

    // Se o alvo está dentro da tela do minimapa
    if(_targetMiniX >= _miniLeft + _iconHalf && _targetMiniX <= _miniRight - _iconHalf
    && _targetMiniY >= _miniTop  + _iconHalf && _targetMiniY <= _miniBottom - _iconHalf)
    {
        // Se for _only_edge (NPCs/Players que o jogo já renderiza dentro da viewport), não desenha duplicado
        if(_only_edge) return;

        if(_sprite != -1 && _sprite >= 0 && sprite_exists(_sprite))
        {
            var _sw   = sprite_get_width(_sprite);
            var _sh   = sprite_get_height(_sprite);
            var _scale = _iconSize / max(_sw, _sh);
            var _sox  = (sprite_get_xoffset(_sprite) - _sw * 0.5) * _scale;
            var _soy  = (sprite_get_yoffset(_sprite) - _sh * 0.5) * _scale;

            Draw.Sprite(_sprite, 0, _targetMiniX + _sox, _targetMiniY + _soy, _scale * 1.15, _scale * 1.15, 0, c_black, 0.7);
            Draw.Sprite(_sprite, 0, _targetMiniX + _sox, _targetMiniY + _soy, _scale,        _scale,        0, _color,  1.0);
        }
    }
    else
    {
        // Se o alvo está fora do minimapa -> projeta na margem da moldura
        var _dirX = _targetMiniX - _miniCenterX;
        var _dirY = _targetMiniY - _miniCenterY;

        if(abs(_dirX) < 0.001 && abs(_dirY) < 0.001)
            return;

        var _halfW = (_miniRight - _miniLeft) * 0.5 - _iconHalf;
        var _halfH = (_miniBottom - _miniTop) * 0.5 - _iconHalf;

        var _tx = (abs(_dirX) > 0.001) ? _halfW / abs(_dirX) : 1000000;
        var _ty = (abs(_dirY) > 0.001) ? _halfH / abs(_dirY) : 1000000;
        var _edgeT = min(_tx, _ty);

        var _edgeX = _miniCenterX + _dirX * _edgeT;
        var _edgeY = _miniCenterY + _dirY * _edgeT;

        if(_sprite != -1 && _sprite >= 0 && sprite_exists(_sprite))
        {
            var _sw2   = sprite_get_width(_sprite);
            var _sh2   = sprite_get_height(_sprite);
            var _scale = (_iconSize * 0.9) / max(_sw2, _sh2);
            var _sox2  = (sprite_get_xoffset(_sprite) - _sw2 * 0.5) * _scale;
            var _soy2  = (sprite_get_yoffset(_sprite) - _sh2 * 0.5) * _scale;

            Draw.Sprite(_sprite, 0, _edgeX + _sox2, _edgeY + _soy2, _scale * 1.25, _scale * 1.25, 0, c_black, 0.85);
            Draw.Sprite(_sprite, 0, _edgeX + _sox2, _edgeY + _soy2, _scale,        _scale,        0, _color,  1.0);
        }
    }
}

function TomTom_DrawMinimapRadar(_m)
{
    if(!instance_exists(objPlayer) || is_undefined(MY_PLAYER)) return;
    if(variable_instance_exists(MY_PLAYER, "hp") && MY_PLAYER.hp <= 0) return;

    var _ratio = TomTom_ScaleRatio();
    var _tile  = TILE_SIZE > 0 ? TILE_SIZE : 16;
    var _has_p_reg = variable_instance_exists(MY_PLAYER, "netRegion");
    var _p_reg     = _has_p_reg ? variable_instance_get(MY_PLAYER, "netRegion") : undefined;

    // 1. NPCs & Players no Minimapa (só desenha na borda quando fora do minimapa!)
    if(_m.track_npcs)
    {
        for(var i = 0; i < array_length(_m.npcs); i++)
        {
            var _n = _m.npcs[i];
            if(!instance_exists(_n.inst)) continue;

            if(_has_p_reg && variable_instance_exists(_n.inst, "netRegion"))
            {
                if(variable_instance_get(_n.inst, "netRegion") != _p_reg)
                    continue;
            }

            TomTom_DrawMinimapTarget(_n.x, _n.y, _n.sprite != -1 ? _n.sprite : sprGUIIngameIconPOI, c_white, _ratio, true);
        }

        var _count = instance_number(objPlayer);
        for(var i = 0; i < _count; i++)
        {
            var _player = instance_find(objPlayer, i);
            if(_player == MY_PLAYER || !instance_exists(_player)) continue;

            if(_has_p_reg)
            {
                if(!variable_instance_exists(_player, "netRegion")
                || variable_instance_get(_player, "netRegion") != _p_reg)
                    continue;
            }

            TomTom_DrawMinimapTarget(_player.x, _player.y, sprGUIIngameIconPOI, c_aqua, _ratio, true);
        }
    }

    // 2. Pins & Baús no Minimapa
    if(_m.track_chests)
    {
        for(var i = 0; i < array_length(_m.pins); i++)
        {
            var _pin = _m.pins[i];

            // Isola caverna de superfície: pin da caverna só aparece no minimapa da caverna
            var _pin_reg = variable_struct_exists(_pin, "region") ? _pin.region : 0;
            if(_has_p_reg && _pin_reg != _p_reg)
                continue;

            var _world_x = _pin.map_x * _tile;
            var _world_y = _pin.map_y * _tile;

            TomTom_DrawMinimapTarget(_world_x, _world_y, TomTom_PinSprite(_pin.type), c_yellow, _ratio, false);
        }

        for(var c = 0; c < array_length(_m.chests); c++)
        {
            var _chest = _m.chests[c];
            if(!instance_exists(_chest.inst)) continue;

            var _cspr = (_chest.sprite != -1 && sprite_exists(_chest.sprite)) ? _chest.sprite : sprGUIIngameIconStorage;
            TomTom_DrawMinimapTarget(_chest.x, _chest.y, _cspr, c_yellow, _ratio, false);
        }
    }

    // 3. Mobs no Minimapa (Ícones 16px com sprite representativo)
    if(_m.track_mobs)
    {
        var _def_gob = TomTom_SafeSprite("sprGUIIngameIconBiomeGoblin", sprGUIIngameIconBoss);
        for(var i = 0; i < array_length(_m.mobs); i++)
        {
            var _mob = _m.mobs[i];
            if(!instance_exists(_mob.inst)) continue;

            var _mspr = (_mob.sprite != -1 && sprite_exists(_mob.sprite)) ? _mob.sprite : _def_gob;
            TomTom_DrawMinimapTarget(_mob.x, _mob.y, _mspr, c_white, _ratio, false);
        }
    }
}

// ---------------------------------------------------------------------------
// DRAW (Navegação em Jogo com Camadas Separadas para Mobs/Baús e NPCs)
// ---------------------------------------------------------------------------

function TomTom_Draw()
{
    var _m = ModInstance.Get("TomTom");
    if(_m == undefined) return;

    if(_m.map_open || !TomTom_HUDVisible())
        return;

    if(!instance_exists(objPlayer) || is_undefined(MY_PLAYER)) return;
    if(variable_instance_exists(MY_PLAYER, "hp") && MY_PLAYER.hp <= 0) return;

    TomTom_EnsureDefaults(_m);

    // Desenha o botão Sonar e os 3 mini-badges no HUD
    TomTom_DrawButton(_m);

    var _w      = WINDOW.width;
    var _h      = WINDOW.height;
    var _s      = GUI_SCALE;
    var _ratio  = TomTom_ScaleRatio();
    var _px     = MY_PLAYER.x;
    var _py     = MY_PLAYER.y;
    var _cam_x  = CAMERA_X;
    var _cam_y  = CAMERA_Y;
    var _tile   = TILE_SIZE > 0 ? TILE_SIZE : 16;

    var _has_p_reg = variable_instance_exists(MY_PLAYER, "netRegion");
    var _p_reg     = _has_p_reg ? variable_instance_get(MY_PLAYER, "netRegion") : undefined;

    // =======================================================================
    // MODO 1: RADAR NA TELA (TomTom Screen Edge Navigation)
    // =======================================================================
    if(_m.radar_mode)
    {
        var _margin_outer = 18 * _s; // Camada Externa (Mobs, Baús e Pins colados na borda da tela)
        var _margin_inner = 48 * _s; // Camada Interna (NPCs e Jogadores afastados da borda)

        // 1. Rastreio de NPCs (se ativo) -> Camada Interna (_margin_inner = 48)
        if(_m.track_npcs)
        {
            for(var i = 0; i < array_length(_m.npcs); i++)
            {
                var _n = _m.npcs[i];
                if(_n.name == "" || !instance_exists(_n.inst)) continue;

                if(_has_p_reg && variable_instance_exists(_n.inst, "netRegion"))
                {
                    if(variable_instance_get(_n.inst, "netRegion") != _p_reg)
                        continue;
                }

                if(variable_instance_exists(_n.inst, "visible") && !_n.inst.visible)
                    continue;

                TomTom_DrawTarget(_n.x, _n.y, _n.name, _n.sprite, _w, _h, _s, _margin_inner, _px, _py, _cam_x, _cam_y, 0);
            }

            // Jogadores Multiplayer -> Camada Interna
            var _count = instance_number(objPlayer);
            for(var i = 0; i < _count; i++)
            {
                var _player = instance_find(objPlayer, i);
                if(_player == MY_PLAYER || !instance_exists(_player)) continue;

                if(_has_p_reg)
                {
                    if(!variable_instance_exists(_player, "netRegion")
                    || variable_instance_get(_player, "netRegion") != _p_reg)
                        continue;
                }

                TomTom_DrawTarget(_player.x, _player.y, TomTom_GetPlayerName(_player), -1, _w, _h, _s, _margin_inner, _px, _py, _cam_x, _cam_y, 0);
            }
        }

        // 2. Rastreio de Marcadores de Mapa & Baús (se ativo) -> Camada Externa (_margin_outer = 18)
        if(_m.track_chests)
        {
            // Pins de Mapa (0=POI, 1=Storage, 2=Question, 3=Boss, 4=Death) -> Tipo 1
            for(var i = 0; i < array_length(_m.pins); i++)
            {
                var _pin = _m.pins[i];

                // Isola caverna de superfície: TomTom só aponta para pins na mesma dimensão/região
                var _pin_reg = variable_struct_exists(_pin, "region") ? _pin.region : 0;
                if(_has_p_reg && _pin_reg != _p_reg)
                    continue;

                // Locais já explorados/visitados (Tipo 6) não poluem o radar direcional da borda da tela
                if(_pin.type == 6)
                    continue;

                var _world_x = _pin.map_x * _tile;
                var _world_y = _pin.map_y * _tile;

                TomTom_DrawTarget(_world_x, _world_y, "", TomTom_PinSprite(_pin.type), _w, _h, _s, _margin_outer, _px, _py, _cam_x, _cam_y, 1);
            }

            // Baús do Mundo -> Tipo 2
            for(var c = 0; c < array_length(_m.chests); c++)
            {
                var _chest = _m.chests[c];
                if(!instance_exists(_chest.inst)) continue;

                var _cspr = (_chest.sprite != -1 && sprite_exists(_chest.sprite)) ? _chest.sprite : sprGUIIngameIconStorage;
                TomTom_DrawTarget(_chest.x, _chest.y, "", _cspr, _w, _h, _s, _margin_outer, _px, _py, _cam_x, _cam_y, 2);
            }
        }

        // 3. Rastreio de Mobs & Monstros (se ativo) -> Camada Externa (_margin_outer = 18)
        if(_m.track_mobs)
        {
            var _def_gob = TomTom_SafeSprite("sprGUIIngameIconBiomeGoblin", sprGUIIngameIconBoss);

            for(var i = 0; i < array_length(_m.mobs); i++)
            {
                var _mob = _m.mobs[i];
                if(!instance_exists(_mob.inst)) continue;

                var _mspr = (_mob.sprite != -1 && sprite_exists(_mob.sprite)) ? _mob.sprite : _def_gob;
                TomTom_DrawTarget(_mob.x, _mob.y, _mob.name, _mspr, _w, _h, _s, _margin_outer, _px, _py, _cam_x, _cam_y, 3);
            }
        }
    }
}

// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// PERSISTENCE (tomtom_pins.cfg - Isolado por Ilha)
// ---------------------------------------------------------------------------

function TomTom_GetWorldStruct()
{
    // 1. Acesso direto ao globalvar nativo WORLD
    try
    {
        if(is_struct(WORLD))
            return WORLD;
    }
    catch(_e) {}

    // 2. Fallback via global.WORLD
    try
    {
        if(variable_global_exists("WORLD"))
        {
            var _gw = variable_global_get("WORLD");
            if(is_struct(_gw)) return _gw;
        }
    }
    catch(_e2) {}

    return undefined;
}

function TomTom_GetIslandKey()
{
    var _m = ModInstance.Get("TomTom");
    var _world = TomTom_GetWorldStruct();

    if(is_struct(_world))
    {
        // 1. Nome canônico da ilha na matriz de navegação (ex: "RandomIsland2x0", "RandomIsland3x0", "RandomIsland4x4")
        if(variable_struct_exists(_world, "name"))
        {
            var _wname = string(_world.name);
            if(string_pos("RandomIsland", _wname) == 1)
            {
                return _wname;
            }
        }

        // 2. Se for ilha procedural/expedição:
        var _is_rnd = false;
        if(variable_struct_exists(_world, "isRandomIsland") && _world.isRandomIsland)
        {
            _is_rnd = true;
        }

        if(_is_rnd)
        {
            // islandID é o índice único da ilha nesta sessão / matriz de navegação
            if(variable_struct_exists(_world, "islandID"))
            {
                var _isid = _world.islandID;
                if(!is_undefined(_isid) && string(_isid) != "" && string(_isid) != "0")
                {
                    return "rnd_island_" + string(_isid);
                }
            }

            // seed é única por geração de terreno daquela ilha
            if(variable_struct_exists(_world, "seed"))
            {
                var _seed = _world.seed;
                if(!is_undefined(_seed) && string(_seed) != "" && string(_seed) != "0")
                {
                    return "rnd_seed_" + string(_seed);
                }
            }

            // mapgenID como fallback adicional
            if(variable_struct_exists(_world, "mapgenID"))
            {
                var _mgid = _world.mapgenID;
                if(!is_undefined(_mgid) && string(_mgid) != "" && string(_mgid) != "undefined")
                {
                    return "rnd_mapgen_" + string(_mgid);
                }
            }
        }
    }

    // 3. Fallback caso objWorldController tenha a identificação
    if(instance_exists(objWorldController))
    {
        var _wc = instance_find(objWorldController, 0);
        if(variable_instance_exists(_wc, "name"))
        {
            var _wcname = string(_wc.name);
            if(string_pos("RandomIsland", _wcname) == 1)
            {
                return _wcname;
            }
        }
        if(variable_instance_exists(_wc, "islandID"))
        {
            var _wcisid = _wc.islandID;
            if(!is_undefined(_wcisid) && string(_wcisid) != "" && string(_wcisid) != "0")
            {
                return "rnd_island_" + string(_wcisid);
            }
        }
        if(variable_instance_exists(_wc, "seed"))
        {
            var _wcseed = _wc.seed;
            if(!is_undefined(_wcseed) && string(_wcseed) != "" && string(_wcseed) != "0")
            {
                return "rnd_seed_" + string(_wcseed);
            }
        }
        if(variable_instance_exists(_wc, "mapgenID"))
        {
            var _wcmgid = _wc.mapgenID;
            if(!is_undefined(_wcmgid) && string(_wcmgid) != "" && string(_wcmgid) != "undefined")
            {
                return "rnd_mapgen_" + string(_wcmgid);
            }
        }
    }

    // 3. Fallback se estiver marcado como ilha não-principal pelo lifecycle
    if(_m != undefined && variable_instance_exists(_m, "is_main_island") && !_m.is_main_island)
    {
        return "rnd_expedition";
    }

    return "island_main";
}

function TomTom_SavePins(_m)
{
    if(_m == undefined) return;

    var _current_island = TomTom_GetIslandKey();
    var _other_island_lines = [];

    // Lê linhas de outras ilhas para preservá-las no arquivo
    var _filename = "tomtom_pins.cfg";
    if(file_exists(_filename))
    {
        var _rf = file_text_open_read(_filename);
        if(_rf >= 0)
        {
            while(!file_text_eof(_rf))
            {
                var _l = file_text_read_string(_rf);
                file_text_readln(_rf);
                if(string_length(_l) <= 0) continue;

                // Ignora CFG antigo e linhas da ilha atual (serão reescritos)
                if(string_pos("#CFG|", _l) == 1) continue;

                var _p1 = string_pos("|", _l);
                var _t1 = (_p1 > 1) ? string_delete(_l, 1, _p1) : "";
                var _p2 = string_pos("|", _t1);
                var _t2 = (_p2 > 1) ? string_delete(_t1, 1, _p2) : "";
                var _p3 = string_pos("|", _t2);

                if(_p3 > 1)
                {
                    var _rest_line = string_delete(_t2, 1, _p3);
                    var _p4 = string_pos("|", _rest_line);
                    var _line_island = (_p4 > 1) ? string_copy(_rest_line, 1, _p4 - 1) : _rest_line;

                    var _line_is_main = (_line_island == "island_0" || _line_island == "main" || _line_island == "island_main");
                    var _curr_is_main = (_current_island == "island_0" || _current_island == "main" || _current_island == "island_main");

                    if(_line_island != _current_island && !(_line_is_main && _curr_is_main))
                    {
                        array_push(_other_island_lines, _l);
                    }
                }
            }
            file_text_close(_rf);
        }
    }

    var _file = file_text_open_write(_filename);
    if(_file < 0) return;

    // 1ª Linha: Configurações de estado (radar_mode, track_npcs, track_chests, track_mobs)
    file_text_write_string(_file,
        "#CFG|" +
        string(_m.radar_mode ? 1 : 0) + "|" +
        string(_m.track_npcs ? 1 : 0) + "|" +
        string(_m.track_chests ? 1 : 0) + "|" +
        string(_m.track_mobs ? 1 : 0));
    file_text_writeln(_file);

    // Linhas dos marcadores da ilha atual: X|Y|TYPE|ISLAND_KEY|REGION
    for(var i = 0; i < array_length(_m.pins); i++)
    {
        var _p = _m.pins[i];
        var _preg = variable_struct_exists(_p, "region") ? string(_p.region) : "0";
        file_text_write_string(_file,
            string(_p.map_x) + "|" +
            string(_p.map_y) + "|" +
            string(_p.type) + "|" +
            _current_island + "|" +
            _preg);
        file_text_writeln(_file);
    }

    // Linhas de marcadores de outras ilhas salvas
    for(var j = 0; j < array_length(_other_island_lines); j++)
    {
        file_text_write_string(_file, _other_island_lines[j]);
        file_text_writeln(_file);
    }

    file_text_close(_file);
}

function TomTom_LoadPins(_m)
{
    if(_m == undefined) return;
    _m.pins = [];

    TomTom_EnsureDefaults(_m);

    var _current_island = TomTom_GetIslandKey();

    var _filename = "";
    if(file_exists("tomtom_pins.cfg"))
        _filename = "tomtom_pins.cfg";
    else if(file_exists("mapradar_pins.cfg"))
        _filename = "mapradar_pins.cfg";

    if(_filename == "") return;

    var _file = file_text_open_read(_filename);
    if(_file < 0) return;

    while(!file_text_eof(_file))
    {
        var _line = file_text_read_string(_file);
        file_text_readln(_file);
        if(string_length(_line) <= 0) continue;

        // Linha de Configuração
        if(string_pos("#CFG|", _line) == 1)
        {
            var _cfg_data = string_delete(_line, 1, 5);
            var _cp1 = string_pos("|", _cfg_data);
            if(_cp1 > 0)
            {
                var _s_mode = string_copy(_cfg_data, 1, _cp1 - 1);
                var _cr1    = string_delete(_cfg_data, 1, _cp1);
                var _cp2    = string_pos("|", _cr1);
                if(_cp2 > 0)
                {
                    var _s_npc = string_copy(_cr1, 1, _cp2 - 1);
                    var _cr2   = string_delete(_cr1, 1, _cp2);
                    var _cp3   = string_pos("|", _cr2);
                    if(_cp3 > 0)
                    {
                        var _s_chest = string_copy(_cr2, 1, _cp3 - 1);
                        var _s_mob   = string_delete(_cr2, 1, _cp3);

                        _m.radar_mode   = (real(_s_mode) == 1);
                        _m.track_npcs   = (real(_s_npc) == 1);
                        _m.track_chests = (real(_s_chest) == 1);
                        _m.track_mobs   = (real(_s_mob) == 1);
                    }
                }
            }
            continue;
        }

        // Linha de Marcador: X|Y|TYPE ou X|Y|TYPE|ISLAND_KEY ou X|Y|TYPE|ISLAND_KEY|REGION
        var _p1 = string_pos("|", _line);
        if(_p1 <= 1) continue;

        var _t1 = string_delete(_line, 1, _p1);
        var _p2 = string_pos("|", _t1);
        if(_p2 <= 1) continue;

        var _t2 = string_delete(_t1, 1, _p2);

        var _px_str = string_copy(_line, 1, _p1 - 1);
        var _py_str = string_copy(_t1,   1, _p2 - 1);

        var _p3 = string_pos("|", _t2);
        var _pt_str = (_p3 > 1) ? string_copy(_t2, 1, _p3 - 1) : _t2;
        var _rest   = (_p3 > 1) ? string_delete(_t2, 1, _p3) : "island_main";

        var _p4 = string_pos("|", _rest);
        var _island_str = (_p4 > 1) ? string_copy(_rest, 1, _p4 - 1) : _rest;
        var _region_str = (_p4 > 1) ? string_delete(_rest, 1, _p4) : "0";

        // Se o pin pertence a esta ilha (ou é legado sem tag ou tag 'main'/'island_0' e estamos na ilha principal)
        var _is_main_pin = (_island_str == "island_0" || _island_str == "main" || _island_str == "island_main" || _p3 <= 1);
        var _is_main_now = (_current_island == "island_0" || _current_island == "main" || _current_island == "island_main");

        if(_island_str == _current_island || (_is_main_pin && _is_main_now))
        {
            array_push(_m.pins, {
                map_x:  real(_px_str),
                map_y:  real(_py_str),
                type:   real(_pt_str),
                region: real(_region_str)
            });
        }
    }

    file_text_close(_file);
}
