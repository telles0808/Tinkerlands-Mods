/*
    ========================================================================
    TINKERLANDS - TomTom
    Author: Telles0808
    ID: 5004

    Integrated Sonar Radar (NPCs & Players) + Interactive Map Waypoints & HUD.
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
        _m.npcs        = [];
        _m.scan        = true;
        _m.last_region = undefined;
        _m.map_open    = false;
        _m.drag_active = false;
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
        _m.scan        = true;
        _m.last_region = undefined;
        _m.map_open    = false;
        _m.drag_active = false;
        _m.cutscenePlaying      = TomTom_GetCallable("cutscene_is_playing");
        _m.cutscenePlayingOther = TomTom_GetCallable("cutscene_is_playing_except_player");
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

        TomTom_DrawPlayerCoords();
    }
});

// ---------------------------------------------------------------------------
// CREATE
// ---------------------------------------------------------------------------

function TomTom_Create()
{
    // Sonar & Radar
    npcs                 = [];
    scan                 = true;
    enabled              = true;
    tick                 = 0;
    last_region          = undefined;
    cutscenePlaying      = TomTom_GetCallable("cutscene_is_playing");
    cutscenePlayingOther = TomTom_GetCallable("cutscene_is_playing_except_player");

    // Map & Pins
    map_open             = false;
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
// PIN SPRITES (0=POI 1=Storage 2=Question 3=Boss)
// ---------------------------------------------------------------------------

function TomTom_PinSprite(_type)
{
    switch(_type)
    {
        case 0: return sprGUIIngameIconPOI;           // 📍 Waypoint
        case 1: return sprGUIIngameIconStorage;       // 📦 Storage
        case 2: return sprGUIIngameIconQuestionMark;  // ❓ Question Mark
        case 3: return sprGUIIngameIconBoss;          // 💀 Boss
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
    var _lp    = TomTom_PaletteGeometry(3); // 4 pins: index 0, 1, 2, 3

    if(_mx <= _lp.x + 36 * _ratio && _my <= 96 * _ratio)
        return true;

    if(_mx >= _gw * 0.5 - 200 * _ratio && _mx <= _gw * 0.5 + 200 * _ratio && _my <= 90 * _ratio)
        return true;

    return false;
}

// ---------------------------------------------------------------------------
// NPC RADAR
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

    if(variable_instance_exists(_npc, "visible") && !_npc.visible)
        return;

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
    if(variable_instance_exists(_npc, "npcName"))
    {
        var _v = variable_instance_get(_npc, "npcName");
        if(TomTom_ValidName(_v)) return string(_v);
    }
    if(variable_instance_exists(_npc, "name"))
    {
        var _v2 = variable_instance_get(_npc, "name");
        if(TomTom_ValidName(_v2)) return string(_v2);
    }
    return "";
}

function TomTom_GetPortrait(_npc)
{
    if(!variable_instance_exists(_npc, "npcID")) return -1;
    var _id = variable_instance_get(_npc, "npcID");
    if(!is_numeric(_id)) return -1;

    switch(_id)
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
    return -1;
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
    if(variable_instance_exists(MY_PLAYER, "hp") && MY_PLAYER.hp <= 0) return;

    // 1. NPC Scanning / Cleanup
    var _curr_reg = variable_instance_exists(MY_PLAYER, "netRegion")
        ? variable_instance_get(MY_PLAYER, "netRegion")
        : undefined;

    if(_curr_reg != _m.last_region)
    {
        _m.last_region = _curr_reg;
        _m.npcs        = [];
        _m.scan        = true;
    }

    if(_m.scan)
    {
        _m.scan = false;
        with(objNPC) { TomTom_NPCAdd(id); }
    }

    _m.tick++;
    if(_m.tick >= 15)
    {
        _m.tick = 0;
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

            if(variable_instance_exists(_n.inst, "visible") && !_n.inst.visible)
            {
                array_delete(_m.npcs, i, 1);
                continue;
            }

            _n.x = _n.inst.x;
            _n.y = _n.inst.y;

            if((_n.name == "" || _n.sprite == -1) && _n.tries < 20)
            {
                _n.tries++;
                var _id = TomTom_NPCResolve(_n.inst);
                if(_id.name   != "") _n.name   = _id.name;
                if(_id.sprite != -1) _n.sprite = _id.sprite;
            }
        }
    }

    // 2. Sonar Button (only when HUD is visible and map is not open)
    if(TomTom_HUDVisible() && !_m.map_open)
    {
        TomTom_ButtonInput(_m);
    }

    // 3. Map toggle logic
    // Se o menu geral de pausa (ESC) estiver aberto, fecha o mapa e cancela ações
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

    // Click no botão de mapa do HUD (canto superior direito sob o minimapa)
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

    // 4. Interações no painel do mapa
    if(_m.map_open)
    {
        TomTom_MapInput(_m);
    }
}

// ---------------------------------------------------------------------------
// SONAR BUTTON
// ---------------------------------------------------------------------------

function TomTom_ButtonX()
{
    return display_get_gui_width() - round(51 * TomTom_ScaleRatio());
}

function TomTom_ButtonY()
{
    return round(display_get_gui_height() * 0.237) + round(80 * TomTom_ScaleRatio());
}

function TomTom_ButtonInput(_m)
{
    var _x  = TomTom_ButtonX();
    var _y  = TomTom_ButtonY();
    var _r  = round(28 * TomTom_ScaleRatio());
    var _mx = device_mouse_x_to_gui(0);
    var _my = device_mouse_y_to_gui(0);

    if(point_in_rectangle(_mx, _my, _x - _r, _y - _r, _x + _r, _y + _r))
    {
        with(objGUIIngameController) { craftMo = true; }
        Input.DisableMenuInputs(0.1);

        if(mouse_check_button_pressed(mb_left))
        {
            _m.enabled = !_m.enabled;
            mouse_clear(mb_left);
        }
    }
}

function TomTom_DrawButton(_m)
{
    var _ratio = TomTom_ScaleRatio();
    var _x     = TomTom_ButtonX();
    var _y     = TomTom_ButtonY();
    var _spr   = sprItemAccesorySonar;
    var _size  = 53 * _ratio;
    var _scale = _size / max(sprite_get_width(_spr), sprite_get_height(_spr));
    var _ox    = (sprite_get_xoffset(_spr) - sprite_get_width(_spr)  * 0.5) * _scale;
    var _oy    = (sprite_get_yoffset(_spr) - sprite_get_height(_spr) * 0.5) * _scale;

    Draw.Sprite(
        _spr, 0,
        _x + _ox, _y + _oy,
        _scale, _scale,
        0,
        _m.enabled ? c_white : c_gray,
        _m.enabled ? 1 : 0.5
    );
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
    for(var i = 0; i < 4; i++)
    {
        var _geom = TomTom_PaletteGeometry(i);
        var _half = _geom.size * 0.5;

        if(point_in_rectangle(_mx, _my, _geom.x - _half, _geom.y - _half, _geom.x + _half, _geom.y + _half))
        {
            Input.DisableMenuInputs(0.1);

            if(mouse_check_button_pressed(mb_left))
            {
                _m.drag_active  = true;
                _m.drag_type    = i;
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

        if(_m.drag_pin_idx >= 0 && _m.drag_pin_idx < array_length(_m.pins))
        {
            var _ep = _m.pins[_m.drag_pin_idx];
            _ep.map_x = _map_x;
            _ep.map_y = _map_y;
        }
        else
        {
            array_push(_m.pins, {
                map_x: _map_x,
                map_y: _map_y,
                type:  _m.drag_type
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

    // 1. Marcadores no canvas do mapa
    for(var i = 0; i < array_length(_m.pins); i++)
    {
        // Se este marcador está sendo arrastado pelo mouse, oculta ele do mapa enquanto estiver no cursor
        if(_m.drag_active && _m.drag_pin_idx == i)
            continue;

        var _p      = _m.pins[i];
        var _psx    = _left + _p.map_x * _scale;
        var _psy    = _top  + _p.map_y * _scale;
        var _spr    = TomTom_PinSprite(_p.type);
        var _size   = 36 * _ratio;
        var _is_sel = (_m.selected_pin == i);
        var _iscale = _size / max(sprite_get_width(_spr), sprite_get_height(_spr));

        Draw.Sprite(
            _spr,
            0,
            _psx,
            _psy,
            _iscale,
            _iscale,
            0,
            _is_sel ? c_yellow : c_white,
            1
        );

        // Exibe coordenadas (X, Y) abaixo do marcador
        var _tx = round(_p.map_x);
        var _ty = round(_p.map_y);
        var _coord_str = string(_tx) + ", " + string(_ty);

        GUI.DrawText(
            _psx,
            _psy + 22 * _ratio,
            _coord_str,
            5,
            _is_sel ? c_yellow : c_white,
            1,
            1.1 * _ratio
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

    // 3. Paleta com os 4 botões de marcadores
    for(var b = 0; b < 4; b++)
    {
        var _geom    = TomTom_PaletteGeometry(b);
        var _spr_pal = TomTom_PinSprite(b);
        var _psize   = _geom.size;
        var _over    = point_in_rectangle(_mx, _my,
                            _geom.x - _psize * 0.5, _geom.y - _psize * 0.5,
                            _geom.x + _psize * 0.5, _geom.y + _psize * 0.5);
        var _pscale  = (_psize / max(sprite_get_width(_spr_pal), sprite_get_height(_spr_pal)))
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
// PLAYER COORDS (canto inferior direito)
// ---------------------------------------------------------------------------

function TomTom_DrawPlayerCoords()
{
    if(!instance_exists(objPlayer) || is_undefined(MY_PLAYER)) return;
    if(variable_instance_exists(MY_PLAYER, "hp") && MY_PLAYER.hp <= 0) return;
    if(!instance_exists(objGUIIngameController)) return;
    if(TomTom_PauseMenuOpen()) return;

    var _ratio = TomTom_ScaleRatio();
    var _tile  = TILE_SIZE > 0 ? TILE_SIZE : 16;

    GUI.DrawText(
        display_get_gui_width()  - round(60 * _ratio),
        display_get_gui_height() - round(50 * _ratio),
        string(round(MY_PLAYER.x / _tile)) + ", " + string(round(MY_PLAYER.y / _tile)),
        5, c_yellow, 1, 3.0 * _ratio
    );
}

// ---------------------------------------------------------------------------
// UNIFIED TOMTOM TARGET DRAW (NPCs, Jogadores e Marcadores de Mapa)
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
    _is_pin
)
{
    var _tile       = TILE_SIZE > 0 ? TILE_SIZE : 16;
    var _dx         = _x - _px;
    var _dy         = _y - _py;
    var _dist_tiles = point_distance(_px, _py, _x, _y) / _tile;

    // Distância mínima para exibição
    if(_dist_tiles <= (_is_pin ? 2 : 3))
        return;

    var _sx       = (_x - _cam_x) * _s;
    var _sy       = (_y - _cam_y) * _s;
    var _dist_str = string(round(_dist_tiles)) + "m";

    // Alvo visível dentro da tela
    if(_sx >= _margin && _sx <= _w - _margin && _sy >= _margin && _sy <= _h - _margin)
    {
        if(_is_pin)
        {
            var _icon_size  = 18 * _s;
            var _icon_scale = _icon_size / max(sprite_get_width(_sprite), sprite_get_height(_sprite));
            Draw.Sprite(_sprite, 0, _sx, _sy, _icon_scale, _icon_scale, 0, c_white, 1);
            GUI.DrawText(_sx, _sy + 14 * _s, _dist_str, 5, c_yellow, 1, _s * 0.60);
        }
        else
        {
            var _iy = _sy + 18 * _s;
            if(_sprite != -1)
                Draw.Sprite(_sprite, 0, _sx, _iy, 0.42 * _s, 0.42 * _s, 0, c_white, 1);

            GUI.DrawText(_sx, _iy + 10 * _s, _name, 5, c_white, 1, _s * 0.55);
        }
        return;
    }

    // Alvo fora da tela -> projeta seta na borda
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

    if(_is_pin)
    {
        var _icon_size  = 18 * _s;
        var _icon_scale = _icon_size / max(sprite_get_width(_sprite), sprite_get_height(_sprite));

        Draw.Sprite(sprGUIIngameArrowRight, 0, _ex + _vx * 14 * _s, _ey + _vy * 14 * _s, 0.70 * _s, 0.70 * _s, _dir, c_white, 1);
        Draw.Sprite(_sprite, 0, _ex, _ey, _icon_scale, _icon_scale, 0, c_white, 1);
        GUI.DrawText(_ex, _ey + 14 * _s, _dist_str, 5, c_yellow, 1, _s * 0.60);
    }
    else
    {
        Draw.Sprite(sprGUIIngameArrowRight, 0, _ex + _vx * 18 * _s, _ey + _vy * 18 * _s, 0.80 * _s, 0.80 * _s, _dir, c_white, 1);

        if(_sprite != -1)
            Draw.Sprite(_sprite, 0, _ex, _ey, 0.45 * _s, 0.45 * _s, 0, c_white, 1);

        var _label = _name + " (" + _dist_str + ")";
        GUI.DrawText(_ex, _ey + 11 * _s, _label, 5, c_white, 1, _s * 0.55);
    }
}

// ---------------------------------------------------------------------------
// DRAW
// ---------------------------------------------------------------------------

function TomTom_Draw()
{
    var _m = ModInstance.Get("TomTom");
    if(_m == undefined) return;

    // Se o mapa está aberto ou o HUD não está visível, não desenha o radar no jogo
    if(_m.map_open || !TomTom_HUDVisible())
        return;

    if(!instance_exists(objPlayer) || is_undefined(MY_PLAYER)) return;
    if(variable_instance_exists(MY_PLAYER, "hp") && MY_PLAYER.hp <= 0) return;

    TomTom_DrawButton(_m);
    TomTom_DrawPlayerCoords();

    if(!_m.enabled)
        return;

    var _w      = WINDOW.width;
    var _h      = WINDOW.height;
    var _s      = GUI_SCALE;
    var _px     = MY_PLAYER.x;
    var _py     = MY_PLAYER.y;
    var _cam_x  = CAMERA_X;
    var _cam_y  = CAMERA_Y;
    var _tile   = TILE_SIZE > 0 ? TILE_SIZE : 16;

    var _has_p_reg = variable_instance_exists(MY_PLAYER, "netRegion");
    var _p_reg     = _has_p_reg ? variable_instance_get(MY_PLAYER, "netRegion") : undefined;

    // 1. Radar de NPCs
    var _margin_npc = 44 * _s;
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

        TomTom_DrawTarget(_n.x, _n.y, _n.name, _n.sprite, _w, _h, _s, _margin_npc, _px, _py, _cam_x, _cam_y, false);
    }

    // 2. Radar de Outros Jogadores
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

        TomTom_DrawTarget(_player.x, _player.y, TomTom_GetPlayerName(_player), -1, _w, _h, _s, _margin_npc, _px, _py, _cam_x, _cam_y, false);
    }

    // 3. Radar de Marcadores de Mapa (Setas TomTom)
    var _margin_pin = 16 * _s;
    for(var i = 0; i < array_length(_m.pins); i++)
    {
        var _pin     = _m.pins[i];
        var _world_x = _pin.map_x * _tile;
        var _world_y = _pin.map_y * _tile;

        TomTom_DrawTarget(_world_x, _world_y, "", TomTom_PinSprite(_pin.type), _w, _h, _s, _margin_pin, _px, _py, _cam_x, _cam_y, true);
    }
}

// ---------------------------------------------------------------------------
// PIN PERSISTENCE (tomtom_pins.cfg)
// ---------------------------------------------------------------------------

function TomTom_SavePins(_m)
{
    if(_m == undefined) return;

    var _file = file_text_open_write("tomtom_pins.cfg");
    if(_file < 0) return;

    for(var i = 0; i < array_length(_m.pins); i++)
    {
        var _p = _m.pins[i];
        file_text_write_string(_file,
            string(_p.map_x) + "|" +
            string(_p.map_y) + "|" +
            string(_p.type));
        file_text_writeln(_file);
    }

    file_text_close(_file);
}

function TomTom_LoadPins(_m)
{
    if(_m == undefined) return;
    _m.pins = [];

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

        var _p1 = string_pos("|", _line);
        if(_p1 <= 1) continue;

        var _t1 = string_delete(_line, 1, _p1);
        var _p2 = string_pos("|", _t1);
        if(_p2 <= 1) continue;

        var _t2 = string_delete(_t1, 1, _p2);

        var _px_str = string_copy(_line, 1, _p1 - 1);
        var _py_str = string_copy(_t1,   1, _p2 - 1);

        // Se houver 3º pipe (legados com label), isola o tipo
        var _p3 = string_pos("|", _t2);
        var _pt_str = (_p3 > 1) ? string_copy(_t2, 1, _p3 - 1) : _t2;

        array_push(_m.pins, {
            map_x: real(_px_str),
            map_y: real(_py_str),
            type:  real(_pt_str)
        });
    }

    file_text_close(_file);
}
