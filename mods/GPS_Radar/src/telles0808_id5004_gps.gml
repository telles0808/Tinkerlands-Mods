/*
    ========================================================================
    TINKERLANDS - GPS Radar
    Author: Telles0808
    ID: 5004
    ========================================================================
*/

OnIslandArrive(function()
{
    var _m = ModInstance.Get("GPS");

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
        GPS_EnsureDefaults(_m);
        GPS_LoadPins(_m);
    }
});

OnIslandFirstArrive(function()
{
    var _m = ModInstance.Get("GPS");

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
        GPS_EnsureDefaults(_m);
        GPS_LoadPins(_m);
    }
});

OnMainIslandArrive(function()
{
    var _m = ModInstance.Get("GPS");

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
        GPS_EnsureDefaults(_m);
        GPS_LoadPins(_m);
    }
});

OnWorldGenerationEnd(function()
{
    var _m = ModInstance.Get("GPS");

    if(_m == undefined)
    {
        ModInstance.Create(
            "GPS",
            "GPS_Create",
            "GPS_Update",
            undefined,
            "GPS_Draw",
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
        _m.cutscenePlaying      = GPS_GetCallable("cutscene_is_playing");
        _m.cutscenePlayingOther = GPS_GetCallable("cutscene_is_playing_except_player");
        GPS_EnsureDefaults(_m);
        GPS_LoadPins(_m);
    }
});

OnNPCSpawn(function(_npc)
{
    GPS_NPCAdd(_npc);
});

OnModDrawGUIEnd(function()
{
    var _m = ModInstance.Get("GPS");

    if(_m != undefined)
    {
        if(_m.map_open && !GPS_PauseMenuOpen())
        {
            GPS_DrawMapOverlay(_m);
        }
        else if(GPS_HUDVisible() && !_m.radar_mode)
        {
            GPS_DrawMinimapRadar(_m);
        }

        GPS_DrawPlayerCoords();
    }
});

function GPS_SafeSprite(_name, _fallback)
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

function GPS_EnsureDefaults(_m)
{
    if(_m == undefined) return;
    if(!variable_instance_exists(_m, "radar_mode"))       _m.radar_mode       = true;
    if(!variable_instance_exists(_m, "track_npcs"))       _m.track_npcs       = true;
    if(!variable_instance_exists(_m, "track_chests"))     _m.track_chests     = true;
    if(!variable_instance_exists(_m, "track_mobs"))       _m.track_mobs       = true;
    if(!variable_instance_exists(_m, "auto_death_pin"))   _m.auto_death_pin   = true;
    if(!variable_instance_exists(_m, "player_was_alive")) _m.player_was_alive = true;
    if(!variable_instance_exists(_m, "npcs"))             _m.npcs             = [];
    if(!variable_instance_exists(_m, "mobs"))             _m.mobs             = [];
    if(!variable_instance_exists(_m, "chests"))           _m.chests           = [];
}

function GPS_Create()
{

    radar_mode           = true;
    track_npcs           = true;
    track_chests         = true;
    track_mobs           = true;
    auto_death_pin       = true;

    player_was_alive     = true;

    npcs                 = [];
    mobs                 = [];
    chests               = [];
    scan                 = true;
    tick                 = 0;
    mob_tick             = 0;
    chest_tick           = 0;
    last_region          = undefined;
    cutscenePlaying      = GPS_GetCallable("cutscene_is_playing");
    cutscenePlayingOther = GPS_GetCallable("cutscene_is_playing_except_player");

    map_open             = false;
    current_island       = "";
    pins                 = [];
    selected_pin         = -1;
    drag_active          = false;
    drag_type            = -1;
    drag_pin_idx         = -1;

    GPS_LoadPins(id);
}

function GPS_ScaleRatio()
{
    var _h = display_get_gui_height();
    return (_h > 0) ? (_h / 1080.0) : 1.0;
}

function GPS_GetCallable(_name)
{
    if(!variable_global_exists(_name))
        return undefined;

    var _callable = variable_global_get(_name);
    return is_callable(_callable) ? _callable : undefined;
}

function GPS_Call(_callable)
{
    if(is_method(_callable))
        return method_call(_callable, []);

    return script_execute(_callable);
}

function GPS_ValidName(_v)
{
    return is_string(_v)
        && _v != ""
        && _v != "Null"
        && _v != "undefined"
        && _v != "<undefined>";
}

function GPS_TutorialActive()
{
    if(variable_global_exists("WORLD_FLAGS"))
    {
        var _wf = variable_global_get("WORLD_FLAGS");
        if(is_struct(_wf) && variable_struct_exists(_wf, "tutorialCompleted"))
            return !_wf.tutorialCompleted;
    }
    return false;
}

function GPS_WorldMapOpen()
{
    return instance_exists(objGUIMapChartController)
        || instance_exists(objGUIShipNavigationController);
}

function GPS_CutsceneActive()
{
    var _m = ModInstance.Get("GPS");
    if(_m == undefined) return false;

    if(is_callable(_m.cutscenePlaying)      && GPS_Call(_m.cutscenePlaying))      return true;
    if(is_callable(_m.cutscenePlayingOther) && GPS_Call(_m.cutscenePlayingOther)) return true;
    return false;
}

function GPS_PauseMenuOpen()
{
    return instance_exists(objGUIMenuController);
}

function GPS_HUDVisible()
{
    if(!instance_exists(objGUIIngameController)) return false;
    if(GPS_TutorialActive())                  return false;
    if(GPS_WorldMapOpen())                    return false;
    if(GPS_CutsceneActive())                  return false;

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

function GPS_PinSprite(_type)
{
    switch(_type)
    {
        case 0: return sprGUIIngameIconPOI;
        case 1: return sprGUIIngameIconStorage;
        case 2: return sprGUIIngameIconQuestionMark;
        case 3: return sprGUIIngameIconBoss;
        case 4: return sprGUIIngameIconTeleport;
        case 5: return sprTombStone;
        case 6: return GPS_SafeSprite("sprGUIIngameCodexIconCompleted", sprGUIIngameIconPOI);
    }
    return sprGUIIngameIconPOI;
}

function GPS_GetMinimap()
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

function GPS_TrashGeometry()
{
    var _ratio = GPS_ScaleRatio();
    return {
        x: 48 * _ratio,
        y: 48 * _ratio,
        size: 46 * _ratio
    };
}

function GPS_PaletteGeometry(_index)
{
    var _ratio   = GPS_ScaleRatio();
    var _trash   = GPS_TrashGeometry();
    var _spacing = 48 * _ratio;
    var _start_x = _trash.x + 52 * _ratio;

    return {
        x: _start_x + _index * _spacing,
        y: _trash.y,
        size: 38 * _ratio
    };
}

function GPS_InProtectedHeaderZone(_mx, _my)
{
    var _ratio = GPS_ScaleRatio();
    var _gw    = display_get_gui_width();
    var _lp    = GPS_PaletteGeometry(6);

    if(_mx <= _lp.x + 36 * _ratio && _my <= 96 * _ratio)
        return true;

    if(_mx >= _gw * 0.5 - 200 * _ratio && _mx <= _gw * 0.5 + 200 * _ratio && _my <= 90 * _ratio)
        return true;

    return false;
}

function GPS_NPCAdd(_npc)
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

    var _m = ModInstance.Get("GPS");
    if(_m == undefined) return;

    for(var i = 0; i < array_length(_m.npcs); i++)
    {
        if(_m.npcs[i].inst == _npc) return;
    }

    var _id = GPS_NPCResolve(_npc);
    array_push(_m.npcs, {
        inst:   _npc,
        x:      _npc.x,
        y:      _npc.y,
        name:   _id.name,
        sprite: _id.sprite,
        tries:  0
    });
}

function GPS_NPCResolve(_npc)
{
    return {
        name:   GPS_GetNPCName(_npc),
        sprite: GPS_GetPortrait(_npc)
    };
}

function GPS_GetNPCName(_npc)
{
    var _candidates = ["npcName", "npc_name", "displayName", "display_name", "name", "entityName", "refNPC"];
    for(var c = 0; c < array_length(_candidates); c++)
    {
        if(variable_instance_exists(_npc, _candidates[c]))
        {
            var _v = variable_instance_get(_npc, _candidates[c]);
            if(GPS_ValidName(_v)) return string(_v);
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

function GPS_GetPortrait(_npc)
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

function GPS_GetMobName(_mob)
{
    if(variable_instance_exists(_mob, "name") && GPS_ValidName(_mob.name)) return string(_mob.name);
    if(variable_instance_exists(_mob, "mobName") && GPS_ValidName(_mob.mobName)) return string(_mob.mobName);
    if(variable_instance_exists(_mob, "refMob") && GPS_ValidName(_mob.refMob)) return string(_mob.refMob);

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

function GPS_GetPlayerName(_player)
{
    if(variable_instance_exists(_player, "playerName"))
    {
        var _n = variable_instance_get(_player, "playerName");
        if(GPS_ValidName(_n)) return string(_n);
    }
    if(variable_instance_exists(_player, "name"))
    {
        var _n2 = variable_instance_get(_player, "name");
        if(GPS_ValidName(_n2)) return string(_n2);
    }
    if(variable_instance_exists(_player, "username"))
    {
        var _n3 = variable_instance_get(_player, "username");
        if(GPS_ValidName(_n3)) return string(_n3);
    }
    return "Player";
}

function GPS_Update()
{
    var _m = ModInstance.Get("GPS");
    if(_m == undefined) return;

    if(!instance_exists(objPlayer) || is_undefined(MY_PLAYER)) return;

    GPS_EnsureDefaults(_m);

    var _is_alive = true;
    if(variable_instance_exists(MY_PLAYER, "hp") && MY_PLAYER.hp <= 0)
        _is_alive = false;

    if(_m.player_was_alive && !_is_alive)
    {
        _m.player_was_alive = false;

        if(_m.auto_death_pin)
        {
            var _tile = TILE_SIZE > 0 ? TILE_SIZE : 16;
            var _death_map_x = MY_PLAYER.x / _tile;
            var _death_map_y = MY_PLAYER.y / _tile;

            var _death_reg = (variable_instance_exists(MY_PLAYER, "netRegion") && !is_undefined(MY_PLAYER.netRegion)) ? MY_PLAYER.netRegion : 0;
            array_push(_m.pins, {
                map_x:  _death_map_x,
                map_y:  _death_map_y,
                type:   5,
                region: _death_reg
            });

            GPS_SavePins(_m);
        }
    }
    else if(!_m.player_was_alive && _is_alive)
    {

        _m.player_was_alive = true;
    }

    if(!_is_alive) return;

    var _curr_reg = variable_instance_exists(MY_PLAYER, "netRegion")
        ? variable_instance_get(MY_PLAYER, "netRegion")
        : undefined;

    var _active_island = GPS_GetIslandKey();
    if(_curr_reg != _m.last_region || _active_island != _m.current_island)
    {
        _m.last_region     = _curr_reg;
        _m.current_island  = _active_island;
        _m.npcs            = [];
        _m.mobs            = [];
        _m.chests          = [];
        _m.scan            = true;
        GPS_LoadPins(_m);
    }

    _m.tick++;
    if(_m.tick >= 10 || _m.scan)
    {
        _m.tick = 0;
        _m.scan = false;

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
                        GPS_NPCAdd(_ninst);
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
                var _id = GPS_NPCResolve(_n.inst);
                if(_id.name   != "") _n.name   = _id.name;
                if(_id.sprite != -1) _n.sprite = _id.sprite;
            }
        }
    }

    if(_m.track_mobs)
    {
        _m.mob_tick++;
        if(_m.mob_tick >= 10)
        {
            _m.mob_tick = 0;
            _m.mobs = [];

            var _has_p_reg = variable_instance_exists(MY_PLAYER, "netRegion");
            var _p_reg     = _has_p_reg ? variable_instance_get(MY_PLAYER, "netRegion") : undefined;
            var _def_gob   = GPS_SafeSprite("sprGUIIngameIconBiomeGoblin", sprGUIIngameIconBoss);

            var _mob_count = instance_number(objMob);
            for(var mi = 0; mi < _mob_count; mi++)
            {
                var _minst = instance_find(objMob, mi);
                if(!instance_exists(_minst)) continue;
                if(_minst == MY_PLAYER) continue;

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

                var _mname = GPS_GetMobName(_minst);
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

    if(GPS_HUDVisible() && !_m.map_open)
    {
        GPS_ButtonInput(_m);
    }

    if(GPS_PauseMenuOpen())
    {
        _m.map_open     = false;
        _m.drag_active  = false;
        _m.drag_pin_idx = -1;
        return;
    }

    var _gw    = display_get_gui_width();
    var _ratio = GPS_ScaleRatio();
    var _mx    = device_mouse_x_to_gui(0);
    var _my    = device_mouse_y_to_gui(0);

    var _map_pressed = false;

    if(keyboard_check_pressed(ord("M")) || keyboard_check_pressed(ord("m")))
        _map_pressed = true;

    if(variable_global_exists("K_MAP_PRESSED") && global.K_MAP_PRESSED)
        _map_pressed = true;

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

    if(keyboard_check_pressed(vk_escape) && _m.map_open)
    {
        _m.map_open     = false;
        _m.drag_active  = false;
        _m.drag_pin_idx = -1;
    }

    if(_m.map_open)
    {
        GPS_MapInput(_m);
    }
}

function GPS_ButtonGeometry()
{
    var _ratio = GPS_ScaleRatio();
    var _gw    = display_get_gui_width();
    var _gh    = display_get_gui_height();

    var _frameW           = max(sprite_get_width(sprGUIIngameMinimapContainer), _gw * 0.16);
    var _frameRightMargin = max(7, _gw * 0.008);
    var _frameLeft        = _gw - _frameW - _frameRightMargin;
    var _frameTop         = max(7, _gh * 0.015);

    var _base_x = _frameLeft - round(86 * _ratio);
    var _base_y = _frameTop + round(2 * _ratio);

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

function GPS_BadgeGeometry(_index)
{
    var _bg    = GPS_ButtonGeometry();
    var _ratio = _bg.ratio;

    var _bsize = round(22 * _ratio);
    var _bx    = _bg.base_x + round(64 * _ratio);

    var _by    = _bg.base_y + round(8 * _ratio);
    switch(_index)
    {
        case 0: _by = _bg.base_y + round(8 * _ratio);   break;
        case 1: _by = _bg.base_y + round(33 * _ratio);  break;
        case 2: _by = _bg.base_y + round(58 * _ratio);  break;
    }

    return {
        cx:   _bx,
        cy:   _by,
        size: _bsize
    };
}

function GPS_ButtonInput(_m)
{
    var _bg    = GPS_ButtonGeometry();
    var _mx    = device_mouse_x_to_gui(0);
    var _my    = device_mouse_y_to_gui(0);

    for(var b = 0; b < 3; b++)
    {
        var _badge = GPS_BadgeGeometry(b);
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

                GPS_SavePins(_m);
                mouse_clear(mb_left);
                return;
            }
        }
    }

    if(point_in_rectangle(_mx, _my, _bg.radar_x, _bg.radar_y, _bg.radar_x + _bg.radar_w, _bg.radar_y + _bg.radar_h))
    {
        with(objGUIIngameController) { craftMo = true; }
        Input.DisableMenuInputs(0.1);

        if(mouse_check_button_pressed(mb_left))
        {
            _m.radar_mode = !_m.radar_mode;
            GPS_SavePins(_m);
            mouse_clear(mb_left);
            return;
        }
    }
}

function GPS_DrawButton(_m)
{
    var _bg    = GPS_ButtonGeometry();
    var _ratio = _bg.ratio;
    var _mx    = device_mouse_x_to_gui(0);
    var _my    = device_mouse_y_to_gui(0);    var _spr_sonar = sprItemAccesorySonar;
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

    var _gob_spr = GPS_SafeSprite("sprGUIIngameIconBiomeGoblin", sprGUIIngameIconBoss);

    for(var b = 0; b < 3; b++)
    {
        var _badge    = GPS_BadgeGeometry(b);
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

function GPS_MapInput(_m)
{
    var _mx    = device_mouse_x_to_gui(0);
    var _my    = device_mouse_y_to_gui(0);
    var _ratio = GPS_ScaleRatio();

    with(objGUIIngameController)
    {
        craftMo = true;
    }

    var _palette_types = [0, 1, 2, 3, 4, 6];
    for(var i = 0; i < array_length(_palette_types); i++)
    {
        var _geom = GPS_PaletteGeometry(i);
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

    var _geom_tomb = GPS_PaletteGeometry(6);
    var _half_tomb = _geom_tomb.size * 0.5;
    if(point_in_rectangle(_mx, _my, _geom_tomb.x - _half_tomb, _geom_tomb.y - _half_tomb, _geom_tomb.x + _half_tomb, _geom_tomb.y + _half_tomb))
    {
        Input.DisableMenuInputs(0.1);

        if(mouse_check_button_pressed(mb_left))
        {
            _m.auto_death_pin = !_m.auto_death_pin;
            GPS_SavePins(_m);
            mouse_clear(mb_left);
            return;
        }
    }

    var _mini  = GPS_GetMinimap();
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

    if(_m.drag_active && mouse_check_button_released(mb_left))
    {
        _m.drag_active = false;

        var _trash = GPS_TrashGeometry();
        var _thalf = _trash.size * 0.75;

        if(point_in_rectangle(_mx, _my, _trash.x - _thalf, _trash.y - _thalf, _trash.x + _thalf, _trash.y + _thalf))
        {
            if(_m.drag_pin_idx >= 0 && _m.drag_pin_idx < array_length(_m.pins))
            {
                array_delete(_m.pins, _m.drag_pin_idx, 1);
                if(_m.selected_pin == _m.drag_pin_idx)      _m.selected_pin = -1;
                else if(_m.selected_pin > _m.drag_pin_idx)  _m.selected_pin--;
                GPS_SavePins(_m);
            }
            _m.drag_pin_idx = -1;
            return;
        }

        if(GPS_InProtectedHeaderZone(_mx, _my))
        {
            _m.drag_pin_idx = -1;
            return;
        }

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

        GPS_SavePins(_m);
        _m.drag_pin_idx = -1;
    }
}

function GPS_DrawMapOverlay(_m)
{
    var _ratio = GPS_ScaleRatio();
    var _mx    = device_mouse_x_to_gui(0);
    var _my    = device_mouse_y_to_gui(0);
    var _mini  = GPS_GetMinimap();
    var _left  = _mini.x;
    var _top   = _mini.y;
    var _scale = _mini.scale;
    var _tile  = TILE_SIZE > 0 ? TILE_SIZE : 16;
    var _has_p_reg = variable_instance_exists(MY_PLAYER, "netRegion");
    var _p_reg     = _has_p_reg ? variable_instance_get(MY_PLAYER, "netRegion") : 0;

    // 1. BaÃºs rastreados no Mapa Grande
    if(_m.track_chests)
    {
        for(var c = 0; c < array_length(_m.chests); c++)
        {
            var _chest = _m.chests[c];
            if(!instance_exists(_chest.inst)) continue;

            var _csx = _left + (_chest.x / _tile) * _scale;
            var _csy = _top  + (_chest.y / _tile) * _scale;
            var _cspr = (_chest.sprite != -1 && sprite_exists(_chest.sprite)) ? _chest.sprite : sprGUIIngameIconStorage;
            var _csize = 28 * _ratio;
            var _cscale = _csize / max(sprite_get_width(_cspr), sprite_get_height(_cspr));
            var _csox = (sprite_get_xoffset(_cspr) - sprite_get_width(_cspr) * 0.5) * _cscale;
            var _csoy = (sprite_get_yoffset(_cspr) - sprite_get_height(_cspr) * 0.5) * _cscale;

            Draw.Sprite(_cspr, 0, _csx + _csox, _csy + _csoy, _cscale * 1.15, _cscale * 1.15, 0, c_black, 0.7);
            Draw.Sprite(_cspr, 0, _csx + _csox, _csy + _csoy, _cscale,        _cscale,        0, c_yellow, 1.0);
        }
    }

    // 2. Mobs / Mini-bosses rastreados no Mapa Grande
    if(_m.track_mobs)
    {
        var _def_gob = GPS_SafeSprite("sprGUIIngameIconBiomeGoblin", sprGUIIngameIconBoss);
        for(var mb = 0; mb < array_length(_m.mobs); mb++)
        {
            var _mob = _m.mobs[mb];
            if(!instance_exists(_mob.inst)) continue;

            var _msx = _left + (_mob.x / _tile) * _scale;
            var _msy = _top  + (_mob.y / _tile) * _scale;
            var _mspr = (_mob.sprite != -1 && sprite_exists(_mob.sprite)) ? _mob.sprite : _def_gob;
            var _msize = 28 * _ratio;
            var _mscale = _msize / max(sprite_get_width(_mspr), sprite_get_height(_mspr));
            var _msox = (sprite_get_xoffset(_mspr) - sprite_get_width(_mspr) * 0.5) * _mscale;
            var _msoy = (sprite_get_yoffset(_mspr) - sprite_get_height(_mspr) * 0.5) * _mscale;

            Draw.Sprite(_mspr, 0, _msx + _msox, _msy + _msoy, _mscale * 1.15, _mscale * 1.15, 0, c_black, 0.7);
            Draw.Sprite(_mspr, 0, _msx + _msox, _msy + _msoy, _mscale,        _mscale,        0, c_white,  1.0);
        }
    }

    // 3. NPCs e outros Players rastreados no Mapa Grande
    if(_m.track_npcs)
    {
        for(var n = 0; n < array_length(_m.npcs); n++)
        {
            var _npc = _m.npcs[n];
            if(!instance_exists(_npc.inst)) continue;

            var _nsx = _left + (_npc.x / _tile) * _scale;
            var _nsy = _top  + (_npc.y / _tile) * _scale;
            var _nspr = (_npc.sprite != -1 && sprite_exists(_npc.sprite)) ? _npc.sprite : sprGUIIngameIconPOI;
            var _nsize = 28 * _ratio;
            var _nscale = _nsize / max(sprite_get_width(_nspr), sprite_get_height(_nspr));
            var _nsox = (sprite_get_xoffset(_nspr) - sprite_get_width(_nspr) * 0.5) * _nscale;
            var _nsoy = (sprite_get_yoffset(_nspr) - sprite_get_height(_nspr) * 0.5) * _nscale;

            Draw.Sprite(_nspr, 0, _nsx + _nsox, _nsy + _nsoy, _nscale * 1.15, _nscale * 1.15, 0, c_black, 0.7);
            Draw.Sprite(_nspr, 0, _nsx + _nsox, _nsy + _nsoy, _nscale,        _nscale,        0, c_white,  1.0);
        }
    }

    // 4. Custom Pins colocados pelo jogador
    for(var i = 0; i < array_length(_m.pins); i++)
    {
        if(_m.drag_active && _m.drag_pin_idx == i)
            continue;

        var _p = _m.pins[i];

        if(_has_p_reg && _p.region != _p_reg)
            continue;

        var _psx    = _left + _p.map_x * _scale;
        var _psy    = _top  + _p.map_y * _scale;
        var _spr    = GPS_PinSprite(_p.type);
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

    var _trash     = GPS_TrashGeometry();
    var _spr_trash = sprGUIIngameIconQuickTrash;
    var _tover     = point_in_rectangle(_mx, _my,
                        _trash.x - _trash.size * 0.5, _trash.y - _trash.size * 0.5,
                        _trash.x + _trash.size * 0.5, _trash.y + _trash.size * 0.5);
    var _tscale    = (_trash.size / max(sprite_get_width(_spr_trash), sprite_get_height(_spr_trash)))
                    * (_tover ? 1.25 : 1.0);

    Draw.Sprite(_spr_trash, 0, _trash.x, _trash.y, _tscale * 1.35, _tscale * 1.35, 0, c_white, _tover ? 0.85 : 0.45);
    Draw.Sprite(_spr_trash, 0, _trash.x, _trash.y, _tscale,         _tscale,         0, _tover ? c_red : c_white, 1.0);

    var _palette_types = [0, 1, 2, 3, 4, 6];
    for(var b = 0; b < array_length(_palette_types); b++)
    {
        var _ptype   = _palette_types[b];
        var _geom    = GPS_PaletteGeometry(b);
        var _spr_pal = GPS_PinSprite(_ptype);
        var _over    = point_in_rectangle(_mx, _my,
                            _geom.x - _geom.size * 0.5, _geom.y - _geom.size * 0.5,
                            _geom.x + _geom.size * 0.5, _geom.y + _geom.size * 0.5);
        var _pscale  = (_geom.size / max(sprite_get_width(_spr_pal), sprite_get_height(_spr_pal)))
                    * (_over ? 1.2 : 1.0);

        Draw.Sprite(_spr_pal, 0, _geom.x, _geom.y, _pscale, _pscale, 0,
                    _over ? c_yellow : c_white,
                    _over ? 1.0 : 0.85);
    }

    var _geom_tomb   = GPS_PaletteGeometry(6);
    var _spr_tomb    = sprTombStone;
    var _tover_tomb  = point_in_rectangle(_mx, _my,
                            _geom_tomb.x - _geom_tomb.size * 0.5, _geom_tomb.y - _geom_tomb.size * 0.5,
                            _geom_tomb.x + _geom_tomb.size * 0.5, _geom_tomb.y + _geom_tomb.size * 0.5);
    var _tscale_tomb = (_geom_tomb.size / max(sprite_get_width(_spr_tomb), sprite_get_height(_spr_tomb)))
                       * (_tover_tomb ? 1.2 : 1.0);

    Draw.Sprite(_spr_tomb, 0, _geom_tomb.x, _geom_tomb.y, _tscale_tomb, _tscale_tomb, 0,
                _m.auto_death_pin ? (_tover_tomb ? c_yellow : c_white) : c_gray,
                _m.auto_death_pin ? 1.0 : 0.45);

    if(_m.drag_active && _m.drag_type >= 0)
    {
        var _drag_spr   = GPS_PinSprite(_m.drag_type);
        var _drag_scale = 40 * _ratio / max(sprite_get_width(_drag_spr), sprite_get_height(_drag_spr));
        Draw.Sprite(_drag_spr, 0, _mx, _my, _drag_scale, _drag_scale, 0, c_yellow, 0.9);
    }
}

function GPS_DrawPlayerCoords()
{
    if(!instance_exists(objPlayer) || is_undefined(MY_PLAYER))
        return;

    if(variable_instance_exists(MY_PLAYER, "hp") && MY_PLAYER.hp <= 0)
        return;

    if(!instance_exists(objGUIIngameController))
        return;

    if(GPS_PauseMenuOpen())
        return;

    var _ratio = GPS_ScaleRatio();
    var _textScale = 3.0 * _ratio;

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

function GPS_DrawTarget(
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

    if(_dist_tiles <= 1.0)
        return;

    var _sx = (_x - _cam_x) * _s;
    var _sy = (_y - _cam_y) * _s;
    var _dist_str = string(round(_dist_tiles)) + "m";

    if(_sx >= _margin && _sx <= _w - _margin && _sy >= _margin && _sy <= _h - _margin)
    {
        if(_target_type == 0)
        {
            GUI.DrawText(_sx, _sy + 8 * _s, _name, 5, c_white, 1, _s * 0.55);
        }
        else if(_target_type == 1)
        {
            var _sw1   = sprite_get_width(_sprite);
            var _sh1   = sprite_get_height(_sprite);
            var _iscl1 = 18 * _s / max(_sw1, _sh1);
            var _sox1  = (sprite_get_xoffset(_sprite) - _sw1 * 0.5) * _iscl1;
            var _soy1  = (sprite_get_yoffset(_sprite) - _sh1 * 0.5) * _iscl1;

            Draw.Sprite(_sprite, 0, _sx + _sox1, _sy + _soy1, _iscl1, _iscl1, 0, c_white, 1);
            GUI.DrawText(_sx, _sy + 11 * _s, _dist_str, 5, c_yellow, 1, _s * 0.60);
        }
        else if(_target_type == 2)
        {
            GUI.DrawText(_sx + 8 * _s, _sy + 14 * _s, _dist_str, 5, c_yellow, 1, _s * 0.55);
        }
        else if(_target_type == 3)
        {
            var _m_lbl = (_name != "" && _name != "Monster" && _name != "Creature") ? (_name + " (" + _dist_str + ")") : _dist_str;
            GUI.DrawText(_sx, _sy + 12 * _s, _m_lbl, 5, c_white, 1, _s * 0.55);
        }
        return;
    }

    var _psx = (_px - _cam_x) * _s;
    var _psy = (_py - _cam_y) * _s;

    var _minX = _margin;
    var _maxX = _w - _margin;
    var _minY = _margin;
    var _maxY = _h - _margin;

    var _startX = clamp(_psx, _minX, _maxX);
    var _startY = clamp(_psy, _minY, _maxY);

    var _dirX = _sx - _startX;
    var _dirY = _sy - _startY;

    if(abs(_dirX) < 0.001 && abs(_dirY) < 0.001)
        return;

    var _t = 1000000;
    if(_dirX > 0.0001)       _t = min(_t, (_maxX - _startX) / _dirX);
    else if(_dirX < -0.0001) _t = min(_t, (_minX - _startX) / _dirX);

    if(_dirY > 0.0001)       _t = min(_t, (_maxY - _startY) / _dirY);
    else if(_dirY < -0.0001) _t = min(_t, (_minY - _startY) / _dirY);

    var _ex = _startX + _dirX * _t;
    var _ey = _startY + _dirY * _t;

    var _dir = point_direction(_startX, _startY, _sx, _sy);
    var _rad = degtorad(_dir);
    var _vx  = cos(_rad);
    var _vy  = -sin(_rad);

    Draw.Sprite(sprGUIIngameArrowRight, 0, _ex, _ey, 0.80 * _s, 0.80 * _s, _dir, c_white, 1);

    var _iconX = _ex - _vx * 16 * _s;
    var _iconY = _ey - _vy * 16 * _s;

    if(_sprite != -1 && _sprite >= 0 && sprite_exists(_sprite))
    {
        var _sw2   = sprite_get_width(_sprite);
        var _sh2   = sprite_get_height(_sprite);
        var _iscl2 = 20 * _s / max(_sw2, _sh2);
        var _sox2  = (sprite_get_xoffset(_sprite) - _sw2 * 0.5) * _iscl2;
        var _soy2  = (sprite_get_yoffset(_sprite) - _sh2 * 0.5) * _iscl2;

        Draw.Sprite(_sprite, 0, _iconX + _sox2, _iconY + _soy2, _iscl2, _iscl2, 0, c_white, 1);
    }

    if(_target_type == 2 || _target_type == 1)
    {
        GUI.DrawText(_iconX, _iconY + 14 * _s, _dist_str, 5, c_yellow, 1, _s * 0.55);
    }
    else
    {
        var _label = (_name != "" && _name != "Monster" && _name != "Creature") ? (_name + " (" + _dist_str + ")") : _dist_str;
        GUI.DrawText(_iconX, _iconY + 14 * _s, _label, 5, c_white, 1, _s * 0.55);
    }
}


function GPS_GetMinimapView(_ratio)
{
    if(!is_struct(MINIMAP) || !variable_struct_exists(MINIMAP, "scale") || MINIMAP.scale <= 0)
        return undefined;

    var _gw = display_get_gui_width();
    var _gh = display_get_gui_height();
    var _tile = TILE_SIZE > 0 ? TILE_SIZE : 16;
    var _scale = MINIMAP.scale;
    var _frameW = max(sprite_get_width(sprGUIIngameMinimapContainer), _gw * 0.16);
    var _frameH = max(sprite_get_height(sprGUIIngameMinimapContainer), _gh * 0.19);
    var _frameX = _gw - _frameW - max(7, _gw * 0.008);
    var _frameY = max(7, _gh * 0.015);
    var _insetX = max(11, _frameW * 0.043);
    var _left = _frameX + _insetX;
    var _top = _frameY + max(13, _frameH * 0.074);
    var _right = _frameX + _frameW - _insetX;
    var _bottom = _frameY + _frameH - max(4, _frameH * 0.025);
    var _centerX = (_left + _right) * 0.5;
    var _centerY = (_top + _bottom) * 0.5;
    var _playerX = MY_PLAYER.x / _tile;
    var _playerY = MY_PLAYER.y / _tile;
    var _halfX = (_right - _left) * 0.5 / _scale;
    var _halfY = (_bottom - _top) * 0.5 / _scale;
    var _mapW = 0;
    var _mapH = 0;
    var _surface = -1;

    // 1. API Oficial do ModExt: Region.GetCurrent() / GetWidth / GetHeight
    try
    {
        var _reg = Region.GetCurrent();
        if(!is_undefined(_reg))
        {
            var _rw = Region.GetWidth(_reg);
            var _rh = Region.GetHeight(_reg);
            if(is_numeric(_rw) && _rw > 0) _mapW = _rw;
            if(is_numeric(_rh) && _rh > 0) _mapH = _rh;
        }
    }
    catch(_e) {}

    // 2. Struct WORLD
    if(_mapW <= 0 || _mapH <= 0)
    {
        if(variable_global_exists("WORLD"))
        {
            var _wstruct = global.WORLD;
            if(is_struct(_wstruct))
            {
                if(variable_struct_exists(_wstruct, "width") && is_numeric(_wstruct.width) && _wstruct.width > 0)
                    _mapW = _wstruct.width;
                if(variable_struct_exists(_wstruct, "height") && is_numeric(_wstruct.height) && _wstruct.height > 0)
                    _mapH = _wstruct.height;
            }
        }
    }

    if(_mapW <= 0 || _mapH <= 0)
    {
        if(variable_struct_exists(MINIMAP, "surfaceWorld"))
            _surface = MINIMAP.surfaceWorld;
        else if(variable_struct_exists(MINIMAP, "surface"))
            _surface = MINIMAP.surface;

        if(surface_exists(_surface))
        {
            _mapW = surface_get_width(_surface);
            _mapH = surface_get_height(_surface);
        }
    }

    if(_mapW <= 0 || _mapH <= 0)
    {
        try
        {
            if(is_numeric(MAP_WIDTH)) _mapW = MAP_WIDTH;
            if(is_numeric(MAP_HEIGHT)) _mapH = MAP_HEIGHT;
        }
        catch(_e) {}
    }

    var _cameraX = _playerX;
    var _cameraY = _playerY;

    if(_mapW > 0)
        _cameraX = _mapW <= _halfX * 2 ? _mapW * 0.5 : clamp(_playerX, _halfX, _mapW - _halfX);
    if(_mapH > 0)
        _cameraY = _mapH <= _halfY * 2 ? _mapH * 0.5 : clamp(_playerY, _halfY, _mapH - _halfY);

    return {
        left: _left,
        top: _top,
        right: _right,
        bottom: _bottom,
        center_x: _centerX,
        center_y: _centerY,
        camera_x: _cameraX,
        camera_y: _cameraY,
        player_x: _centerX + (_playerX - _cameraX) * _scale,
        player_y: _centerY + (_playerY - _cameraY) * _scale,
        scale: _scale,
        tile: _tile,
        icon_size: round(16 * _ratio)
    };
}

function GPS_DrawMinimapTarget(_view, _world_x, _world_y, _sprite, _color, _only_edge)
{
    if(_sprite < 0 || !sprite_exists(_sprite)) return;

    var _targetX = _view.center_x + (_world_x / _view.tile - _view.camera_x) * _view.scale;
    var _targetY = _view.center_y + (_world_y / _view.tile - _view.camera_y) * _view.scale;
    var _iconHalf = _view.icon_size * 0.5;
    var _drawX = _targetX;
    var _drawY = _targetY;
    var _drawSize = _view.icon_size;
    var _shadowScale = 1.15;
    var _shadowAlpha = 0.7;

    if(_targetX >= _view.left + _iconHalf && _targetX <= _view.right - _iconHalf
    && _targetY >= _view.top  + _iconHalf && _targetY <= _view.bottom - _iconHalf)
    {
        if(_only_edge) return;
    }
    else
    {
        var _startX = clamp(_view.player_x, _view.left + _iconHalf, _view.right - _iconHalf);
        var _startY = clamp(_view.player_y, _view.top + _iconHalf, _view.bottom - _iconHalf);
        var _dirX = _targetX - _view.player_x;
        var _dirY = _targetY - _view.player_y;

        if(abs(_dirX) < 0.001 && abs(_dirY) < 0.001)
            return;

        var _tx = 1000000;
        var _ty = 1000000;

        if(_dirX > 0.001) _tx = (_view.right - _iconHalf - _startX) / _dirX;
        else if(_dirX < -0.001) _tx = (_view.left + _iconHalf - _startX) / _dirX;
        if(_dirY > 0.001) _ty = (_view.bottom - _iconHalf - _startY) / _dirY;
        else if(_dirY < -0.001) _ty = (_view.top + _iconHalf - _startY) / _dirY;

        var _edgeT = min(_tx, _ty);
        _drawX = _startX + _dirX * _edgeT;
        _drawY = _startY + _dirY * _edgeT;
        _drawSize *= 0.9;
        _shadowScale = 1.25;
        _shadowAlpha = 0.85;
    }

    var _sw = sprite_get_width(_sprite);
    var _sh = sprite_get_height(_sprite);
    var _scale = _drawSize / max(_sw, _sh);
    var _x = _drawX + (sprite_get_xoffset(_sprite) - _sw * 0.5) * _scale;
    var _y = _drawY + (sprite_get_yoffset(_sprite) - _sh * 0.5) * _scale;

    Draw.Sprite(_sprite, 0, _x, _y, _scale * _shadowScale, _scale * _shadowScale, 0, c_black, _shadowAlpha);
    Draw.Sprite(_sprite, 0, _x, _y, _scale, _scale, 0, _color, 1.0);
}

function GPS_DrawMinimapRadar(_m)
{
    if(!instance_exists(objPlayer) || is_undefined(MY_PLAYER)) return;
    if(variable_instance_exists(MY_PLAYER, "hp") && MY_PLAYER.hp <= 0) return;

    var _view = GPS_GetMinimapView(GPS_ScaleRatio());
    if(is_undefined(_view)) return;

    var _has_p_reg = variable_instance_exists(MY_PLAYER, "netRegion");
    var _p_reg     = _has_p_reg ? variable_instance_get(MY_PLAYER, "netRegion") : undefined;

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

            GPS_DrawMinimapTarget(_view, _n.x, _n.y, _n.sprite != -1 ? _n.sprite : sprGUIIngameIconPOI, c_white, true);
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

            GPS_DrawMinimapTarget(_view, _player.x, _player.y, sprGUIIngameIconPOI, c_aqua, true);
        }
    }

    if(_m.track_chests)
    {
        for(var i = 0; i < array_length(_m.pins); i++)
        {
            var _pin = _m.pins[i];

            if(_has_p_reg && _pin.region != _p_reg)
                continue;

            var _world_x = _pin.map_x * _view.tile;
            var _world_y = _pin.map_y * _view.tile;

            GPS_DrawMinimapTarget(_view, _world_x, _world_y, GPS_PinSprite(_pin.type), c_yellow, false);
        }

        for(var c = 0; c < array_length(_m.chests); c++)
        {
            var _chest = _m.chests[c];
            if(!instance_exists(_chest.inst)) continue;

            var _cspr = (_chest.sprite != -1 && sprite_exists(_chest.sprite)) ? _chest.sprite : sprGUIIngameIconStorage;
            GPS_DrawMinimapTarget(_view, _chest.x, _chest.y, _cspr, c_yellow, false);
        }
    }

    if(_m.track_mobs)
    {
        var _def_gob = GPS_SafeSprite("sprGUIIngameIconBiomeGoblin", sprGUIIngameIconBoss);
        for(var i = 0; i < array_length(_m.mobs); i++)
        {
            var _mob = _m.mobs[i];
            if(!instance_exists(_mob.inst)) continue;

            var _mspr = (_mob.sprite != -1 && sprite_exists(_mob.sprite)) ? _mob.sprite : _def_gob;
            GPS_DrawMinimapTarget(_view, _mob.x, _mob.y, _mspr, c_white, false);
        }
    }
}

function GPS_Draw()
{
    var _m = ModInstance.Get("GPS");
    if(_m == undefined) return;

    if(_m.map_open || !GPS_HUDVisible())
        return;

    if(!instance_exists(objPlayer) || is_undefined(MY_PLAYER)) return;
    if(variable_instance_exists(MY_PLAYER, "hp") && MY_PLAYER.hp <= 0) return;

    GPS_EnsureDefaults(_m);

    GPS_DrawButton(_m);

    var _w      = WINDOW.width;
    var _h      = WINDOW.height;
    var _s      = GUI_SCALE;
    var _ratio  = GPS_ScaleRatio();
    var _px     = MY_PLAYER.x;
    var _py     = MY_PLAYER.y;
    var _cam_x  = CAMERA_X;
    var _cam_y  = CAMERA_Y;
    var _tile   = TILE_SIZE > 0 ? TILE_SIZE : 16;

    var _has_p_reg = variable_instance_exists(MY_PLAYER, "netRegion");
    var _p_reg     = _has_p_reg ? variable_instance_get(MY_PLAYER, "netRegion") : undefined;

    if(_m.radar_mode)
    {
        var _margin_outer = 32 * _s;
        var _margin_inner = 48 * _s;

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

                GPS_DrawTarget(_n.x, _n.y, _n.name, _n.sprite, _w, _h, _s, _margin_inner, _px, _py, _cam_x, _cam_y, 0);
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

                GPS_DrawTarget(_player.x, _player.y, GPS_GetPlayerName(_player), -1, _w, _h, _s, _margin_inner, _px, _py, _cam_x, _cam_y, 0);
            }
        }

        if(_m.track_chests)
        {
            for(var i = 0; i < array_length(_m.pins); i++)
            {
                var _pin = _m.pins[i];

                if(_has_p_reg && _pin.region != _p_reg)
                    continue;

                if(_pin.type == 6)
                    continue;

                var _world_x = _pin.map_x * _tile;
                var _world_y = _pin.map_y * _tile;

                GPS_DrawTarget(_world_x, _world_y, "", GPS_PinSprite(_pin.type), _w, _h, _s, _margin_outer, _px, _py, _cam_x, _cam_y, 1);
            }

            for(var c = 0; c < array_length(_m.chests); c++)
            {
                var _chest = _m.chests[c];
                if(!instance_exists(_chest.inst)) continue;

                var _cspr = (_chest.sprite != -1 && sprite_exists(_chest.sprite)) ? _chest.sprite : sprGUIIngameIconStorage;
                GPS_DrawTarget(_chest.x, _chest.y, "", _cspr, _w, _h, _s, _margin_outer, _px, _py, _cam_x, _cam_y, 2);
            }
        }

        if(_m.track_mobs)
        {
            var _def_gob = GPS_SafeSprite("sprGUIIngameIconBiomeGoblin", sprGUIIngameIconBoss);

            for(var i = 0; i < array_length(_m.mobs); i++)
            {
                var _mob = _m.mobs[i];
                if(!instance_exists(_mob.inst)) continue;

                var _mspr = (_mob.sprite != -1 && sprite_exists(_mob.sprite)) ? _mob.sprite : _def_gob;
                GPS_DrawTarget(_mob.x, _mob.y, _mob.name, _mspr, _w, _h, _s, _margin_outer, _px, _py, _cam_x, _cam_y, 3);
            }
        }
    }
}

function GPS_GetWorldStruct()
{

    try
    {
        if(is_struct(WORLD))
            return WORLD;
    }
    catch(_e) {}

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

function GPS_GetIslandKey()
{
    var _m = ModInstance.Get("GPS");
    var _world = GPS_GetWorldStruct();

    if(is_struct(_world))
    {

        if(variable_struct_exists(_world, "name"))
        {
            var _wname = string(_world.name);
            if(string_pos("RandomIsland", _wname) == 1)
            {
                return _wname;
            }
        }

        var _is_rnd = false;
        if(variable_struct_exists(_world, "isRandomIsland") && _world.isRandomIsland)
        {
            _is_rnd = true;
        }

        if(_is_rnd)
        {

            if(variable_struct_exists(_world, "islandID"))
            {
                var _isid = _world.islandID;
                if(!is_undefined(_isid) && string(_isid) != "" && string(_isid) != "0")
                {
                    return "rnd_island_" + string(_isid);
                }
            }

            if(variable_struct_exists(_world, "seed"))
            {
                var _seed = _world.seed;
                if(!is_undefined(_seed) && string(_seed) != "" && string(_seed) != "0")
                {
                    return "rnd_seed_" + string(_seed);
                }
            }

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

    if(_m != undefined && variable_instance_exists(_m, "is_main_island") && !_m.is_main_island)
    {
        return "rnd_expedition";
    }

    return "island_main";
}

function GPS_SavePins(_m)
{
    if(_m == undefined) return;

    var _current_island = GPS_GetIslandKey();
    var _other_island_lines = [];

    var _filename = "gps_pins.cfg";
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
                    if(_p4 > 1)
                    {
                        var _line_island = string_copy(_rest_line, 1, _p4 - 1);
                        if(_line_island != _current_island)
                            array_push(_other_island_lines, _l);
                    }
                }
            }
            file_text_close(_rf);
        }
    }

    var _file = file_text_open_write(_filename);
    if(_file < 0) return;

    file_text_write_string(_file,
        "#CFG|" +
        string(_m.radar_mode ? 1 : 0) + "|" +
        string(_m.track_npcs ? 1 : 0) + "|" +
        string(_m.track_chests ? 1 : 0) + "|" +
        string(_m.track_mobs ? 1 : 0));
    file_text_writeln(_file);

    for(var i = 0; i < array_length(_m.pins); i++)
    {
        var _p = _m.pins[i];
        file_text_write_string(_file,
            string(_p.map_x) + "|" +
            string(_p.map_y) + "|" +
            string(_p.type) + "|" +
            _current_island + "|" +
            string(_p.region));
        file_text_writeln(_file);
    }

    for(var j = 0; j < array_length(_other_island_lines); j++)
    {
        file_text_write_string(_file, _other_island_lines[j]);
        file_text_writeln(_file);
    }

    file_text_close(_file);
}

function GPS_LoadPins(_m)
{
    if(_m == undefined) return;
    _m.pins = [];

    GPS_EnsureDefaults(_m);

    var _current_island = GPS_GetIslandKey();

    var _filename = "gps_pins.cfg";
    if(!file_exists(_filename)) return;

    var _file = file_text_open_read(_filename);
    if(_file < 0) return;

    while(!file_text_eof(_file))
    {
        var _line = file_text_read_string(_file);
        file_text_readln(_file);
        if(string_length(_line) <= 0) continue;

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
                        var _cr3     = string_delete(_cr2, 1, _cp3);
                        var _cp4     = string_pos("|", _cr3);
                        if(_cp4 > 0)
                        {
                            var _s_mob   = string_copy(_cr3, 1, _cp4 - 1);
                            var _s_death = string_delete(_cr3, 1, _cp4);
                            _m.auto_death_pin = (real(_s_death) == 1);
                        }
                        else
                        {
                            var _s_mob = _cr3;
                            _m.auto_death_pin = true;
                        }

                        _m.radar_mode   = (real(_s_mode) == 1);
                        _m.track_npcs   = (real(_s_npc) == 1);
                        _m.track_chests = (real(_s_chest) == 1);
                        _m.track_mobs   = (real(_s_mob) == 1);
                    }
                }
            }
            continue;
        }

        var _p1 = string_pos("|", _line);
        if(_p1 <= 1) continue;

        var _t1 = string_delete(_line, 1, _p1);
        var _p2 = string_pos("|", _t1);
        if(_p2 <= 1) continue;

        var _t2 = string_delete(_t1, 1, _p2);

        var _px_str = string_copy(_line, 1, _p1 - 1);
        var _py_str = string_copy(_t1,   1, _p2 - 1);

        var _p3 = string_pos("|", _t2);
        if(_p3 <= 1) continue;

        var _pt_str = string_copy(_t2, 1, _p3 - 1);
        var _rest   = string_delete(_t2, 1, _p3);

        var _p4 = string_pos("|", _rest);
        if(_p4 <= 1) continue;

        var _island_str = string_copy(_rest, 1, _p4 - 1);
        var _region_str = string_delete(_rest, 1, _p4);

        if(_island_str == _current_island)
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
