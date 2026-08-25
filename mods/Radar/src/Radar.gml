/*
NPCRadar
Tinkerlands Mod
Author: Telles0808 V1.4
*/

OnIslandArrive(function()
{
    var _m = ModInstance.Get("Radar");

    if(_m != undefined)
    {
        _m.npcs = [];
        _m.scan = true;
    }
});

OnWorldGenerationEnd(function()
{
    var _m = ModInstance.Get("Radar");

    if(_m == undefined)
    {
        ModInstance.Create(
            "Radar",
            "Radar_Create",
            "Radar_Update",
            undefined,
            "Radar_Draw",
            undefined
        );
    }
    else
    {
        _m.npcs = [];
        _m.scan = true;
        _m.cutscenePlaying = Radar_GetCallable("cutscene_is_playing");
        _m.cutscenePlayingOther = Radar_GetCallable("cutscene_is_playing_except_player");
    }
});

OnNPCSpawn(function(_npc)
{
    Radar_Add(_npc);
});

function Radar_Create()
{
    npcs = [];
    scan = true;
    enabled = true;
    tick = 0;

    cutscenePlaying = Radar_GetCallable("cutscene_is_playing");
    cutscenePlayingOther = Radar_GetCallable("cutscene_is_playing_except_player");
}

function Radar_GetCallable(_name)
{
    if(!variable_global_exists(_name))
        return undefined;

    var _callable = variable_global_get(_name);

    return is_callable(_callable) ? _callable : undefined;
}

function Radar_CutsceneActive()
{
    var _m = ModInstance.Get("Radar");

    if(_m == undefined)
        return false;

    if(is_callable(_m.cutscenePlaying)
    && Radar_Call(_m.cutscenePlaying))
        return true;

    if(is_callable(_m.cutscenePlayingOther)
    && Radar_Call(_m.cutscenePlayingOther))
        return true;

    return false;
}

function Radar_Call(_callable)
{
    if(is_method(_callable))
        return method_call(_callable, []);

    return script_execute(_callable);
}

function Radar_TutorialActive()
{
    if(variable_global_exists("WORLD_FLAGS"))
    {
        var _wf = variable_global_get("WORLD_FLAGS");

        if(is_struct(_wf) && variable_struct_exists(_wf, "tutorialCompleted"))
        {
            return !_wf.tutorialCompleted;
        }
    }

    return false;
}

function Radar_WorldMapOpen()
{
    if(instance_exists(objGUIMapChartController)
    || instance_exists(objGUIShipNavigationController))
    {
        return true;
    }

    return false;
}

function Radar_HUDVisible()
{
    if(!instance_exists(objGUIIngameController))
        return false;

    if(Radar_TutorialActive())
        return false;

    if(Radar_WorldMapOpen())
        return false;

    if(Radar_CutsceneActive())
        return false;

    if(variable_global_exists("guiEnabled") && !global.guiEnabled)
        return false;

    if(variable_global_exists("guiStatsEnabled") && !global.guiStatsEnabled)
        return false;

    if(variable_global_exists("guiMapEnabled") && !global.guiMapEnabled)
        return false;

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

function Radar_Add(_npc)
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

    var _m = ModInstance.Get("Radar");

    if(_m == undefined)
        return;

    for(var i = 0; i < array_length(_m.npcs); i++)
    {
        if(_m.npcs[i].inst == _npc)
            return;
    }

    var _id = Radar_Resolve(_npc);

    array_push(
        _m.npcs,
        {
            inst: _npc,
            x: _npc.x,
            y: _npc.y,
            name: _id.name,
            sprite: _id.sprite,
            tries: 0
        }
    );
}

function Radar_Update()
{
    var _m = ModInstance.Get("Radar");

    if(_m == undefined)
        return;

    if(!instance_exists(objPlayer) || is_undefined(MY_PLAYER))
        return;

    if(variable_instance_exists(MY_PLAYER, "hp") && MY_PLAYER.hp <= 0)
        return;

    if(_m.scan)
    {
        _m.scan = false;

        with(objNPC)
        {
            Radar_Add(id);
        }
    }

    _m.tick++;

    if(_m.tick >= 15)
    {
        _m.tick = 0;

        var _has_p_reg = variable_instance_exists(MY_PLAYER, "netRegion");
        var _p_reg = _has_p_reg ? variable_instance_get(MY_PLAYER, "netRegion") : undefined;

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

                var _id = Radar_Resolve(_n.inst);

                if(_id.name != "")
                    _n.name = _id.name;

                if(_id.sprite != -1)
                    _n.sprite = _id.sprite;
            }
        }
    }

    if(Radar_HUDVisible())
        Radar_ButtonInput(_m);
}

function Radar_Resolve(_npc)
{
    return
    {
        name: Radar_GetName(_npc),
        sprite: Radar_GetPortrait(_npc)
    };
}

function Radar_GetName(_npc)
{
    if(variable_instance_exists(_npc, "npcName"))
    {
        var _v = variable_instance_get(_npc, "npcName");

        if(Radar_ValidName(_v))
            return string(_v);
    }

    if(variable_instance_exists(_npc, "name"))
    {
        var _v2 = variable_instance_get(_npc, "name");

        if(Radar_ValidName(_v2))
            return string(_v2);
    }

    return "";
}

function Radar_ValidName(_v)
{
    return is_string(_v)
        && _v != ""
        && _v != "Null"
        && _v != "undefined"
        && _v != "<undefined>";
}

function Radar_GetPortrait(_npc)
{
    if(!variable_instance_exists(_npc, "npcID"))
        return -1;

    var _id = variable_instance_get(_npc, "npcID");

    if(!is_numeric(_id))
        return -1;

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

function Radar_ScaleRatio()
{
    var _h = display_get_gui_height();

    return (_h > 0)
        ? (_h / 1080.0)
        : 1.0;
}

function Radar_ButtonX()
{
    return display_get_gui_width()
        - round(51 * Radar_ScaleRatio());
}

function Radar_ButtonY()
{
    return round(display_get_gui_height() * 0.237)
        + round(80 * Radar_ScaleRatio());
}

function Radar_ButtonInput(_m)
{
    var _x = Radar_ButtonX();
    var _y = Radar_ButtonY();
    var _r = round(28 * Radar_ScaleRatio());

    var _mx = device_mouse_x_to_gui(0);
    var _my = device_mouse_y_to_gui(0);

    if(point_in_rectangle(
        _mx,
        _my,
        _x - _r,
        _y - _r,
        _x + _r,
        _y + _r
    ))
    {
        // Prevents world action / attack click-through
        with(objGUIIngameController)
        {
            craftMo = true;
        }

        Input.DisableMenuInputs(0.1);

        if(mouse_check_button_pressed(mb_left))
        {
            _m.enabled = !_m.enabled;
            mouse_clear(mb_left);
        }
    }
}

function Radar_DrawButton(_m)
{
    var _ratio = Radar_ScaleRatio();

    var _x = Radar_ButtonX();
    var _y = Radar_ButtonY();

    var _spr = sprItemAccesorySonar;
    var _size = 53 * _ratio;

    var _scale =
        _size
        / max(
            sprite_get_width(_spr),
            sprite_get_height(_spr)
        );

    var _ox =
        (
            sprite_get_xoffset(_spr)
            - sprite_get_width(_spr) * 0.5
        )
        * _scale;

    var _oy =
        (
            sprite_get_yoffset(_spr)
            - sprite_get_height(_spr) * 0.5
        )
        * _scale;

    Draw.Sprite(
        _spr,
        0,
        _x + _ox,
        _y + _oy,
        _scale,
        _scale,
        0,
        _m.enabled ? c_white : c_gray,
        _m.enabled ? 1 : 0.5
    );
}

function Radar_GetPlayerName(_player)
{
    if(variable_instance_exists(_player, "playerName"))
    {
        var _player_name = variable_instance_get(_player, "playerName");

        if(Radar_ValidName(_player_name))
            return string(_player_name);
    }

    if(variable_instance_exists(_player, "name"))
    {
        var _name = variable_instance_get(_player, "name");

        if(Radar_ValidName(_name))
            return string(_name);
    }

    if(variable_instance_exists(_player, "username"))
    {
        var _username = variable_instance_get(_player, "username");

        if(Radar_ValidName(_username))
            return string(_username);
    }

    return "Player";
}

function Radar_DrawPlayers(
    _w,
    _h,
    _s,
    _margin,
    _px,
    _py,
    _cam_x,
    _cam_y
)
{
    var _has_region = variable_instance_exists(MY_PLAYER, "netRegion");
    var _region = _has_region
        ? variable_instance_get(MY_PLAYER, "netRegion")
        : undefined;

    var _count = instance_number(objPlayer);

    for(var i = 0; i < _count; i++)
    {
        var _player = instance_find(objPlayer, i);

        if(_player == MY_PLAYER || !instance_exists(_player))
            continue;

        if(_has_region)
        {
            if(!variable_instance_exists(_player, "netRegion")
            || variable_instance_get(_player, "netRegion") != _region)
                continue;
        }

        Radar_DrawTarget(
            _player.x,
            _player.y,
            Radar_GetPlayerName(_player),
            -1,
            _w,
            _h,
            _s,
            _margin,
            _px,
            _py,
            _cam_x,
            _cam_y
        );
    }
}

function Radar_DrawTarget(
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
    _cam_y
)
{
    var _dx = _x - _px;
    var _dy = _y - _py;

    var _dist_tiles =
        point_distance(
            _px,
            _py,
            _x,
            _y
        )
        / TILE_SIZE;

    if(_dist_tiles <= 3)
        return;

    var _sx =
        (_x - _cam_x)
        * _s;

    var _sy =
        (_y - _cam_y)
        * _s;

    if(
        _sx >= _margin
        && _sx <= _w - _margin
        && _sy >= _margin
        && _sy <= _h - _margin
    )
    {
        var _iy =
            _sy
            + 18 * _s;

        if(_sprite != -1)
        {
            Draw.Sprite(
                _sprite,
                0,
                _sx,
                _iy,
                0.42 * _s,
                0.42 * _s,
                0,
                c_white,
                1
            );
        }

        GUI.DrawText(
            _sx,
            _iy + 10 * _s,
            _name,
            5,
            c_white,
            1,
            _s * 0.55
        );

        return;
    }

    var _dir =
        point_direction(
            0,
            0,
            _dx,
            _dy
        );

    var _rad =
        degtorad(_dir);

    var _vx =
        cos(_rad);

    var _vy =
        -sin(_rad);

    var _hw = _w * 0.5 - _margin;
    var _hh = _h * 0.5 - _margin;

    var _scale_x =
        abs(_vx) > 0.0001
        ? _hw / abs(_vx)
        : 99999;

    var _scale_y =
        abs(_vy) > 0.0001
        ? _hh / abs(_vy)
        : 99999;

    var _min_s =
        min(
            _scale_x,
            _scale_y
        );

    var _ex =
        _w * 0.5
        + _vx * _min_s;

    var _ey =
        _h * 0.5
        + _vy * _min_s;

    Draw.Sprite(
        sprGUIIngameArrowRight,
        0,
        _ex + _vx * 18 * _s,
        _ey + _vy * 18 * _s,
        0.8 * _s,
        0.8 * _s,
        _dir,
        c_white,
        1
    );

    if(_sprite != -1)
    {
        Draw.Sprite(
            _sprite,
            0,
            _ex,
            _ey,
            0.45 * _s,
            0.45 * _s,
            0,
            c_white,
            1
        );
    }

    var _label =
        _name
        + " ("
        + string(round(_dist_tiles))
        + "m)";

    GUI.DrawText(
        _ex,
        _ey + 11 * _s,
        _label,
        5,
        c_white,
        1,
        _s * 0.55
    );
}

function Radar_Draw()
{
    if(!Radar_HUDVisible())
        return;

    var _m = ModInstance.Get("Radar");

    if(_m == undefined)
        return;

    if(!instance_exists(objPlayer) || is_undefined(MY_PLAYER))
        return;

    if(variable_instance_exists(MY_PLAYER, "hp") && MY_PLAYER.hp <= 0)
        return;

    Radar_DrawButton(_m);

    if(!_m.enabled)
        return;

    var _w = WINDOW.width;
    var _h = WINDOW.height;
    var _s = GUI_SCALE;

    var _margin = 44 * _s;

    var _px = MY_PLAYER.x;
    var _py = MY_PLAYER.y;

    var _cam_x = CAMERA_X;
    var _cam_y = CAMERA_Y;

    var _has_player_region = variable_instance_exists(MY_PLAYER, "netRegion");
    var _player_region = _has_player_region ? variable_instance_get(MY_PLAYER, "netRegion") : undefined;

    for(var i = 0; i < array_length(_m.npcs); i++)
    {
        var _n = _m.npcs[i];

        if(_n.name == "" || !instance_exists(_n.inst))
            continue;

        if(_has_player_region && variable_instance_exists(_n.inst, "netRegion"))
        {
            if(variable_instance_get(_n.inst, "netRegion") != _player_region)
                continue;
        }

        if(variable_instance_exists(_n.inst, "visible") && !_n.inst.visible)
            continue;

        Radar_DrawTarget(
            _n.x,
            _n.y,
            _n.name,
            _n.sprite,
            _w,
            _h,
            _s,
            _margin,
            _px,
            _py,
            _cam_x,
            _cam_y
        );
    }

    Radar_DrawPlayers(
        _w,
        _h,
        _s,
        _margin,
        _px,
        _py,
        _cam_x,
        _cam_y
    );
}
