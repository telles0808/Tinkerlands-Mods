/*
    ========================================================================
    TINKERLANDS - Godmod
    Author: Telles0808
    ID: 5006
    ========================================================================
*/

OnModLoad(function()
{
    ModInstance.Create(
        "Godmod",
        "Godmod_Create",
        "Godmod_Update",
        undefined,
        "Godmod_DrawGUI",
        undefined
    );
});

OnWorldGenerationEnd(function()
{
    var _t = ModInstance.Get("Godmod");
    if(_t != undefined && _t.god_mode)
    {
        Godmod_ShowToast("GOD MODE: ATIVADO");
    }
});

function Godmod_Create()
{
    god_mode = false;
    toast_timer = 0;
    toast_msg = "";
    f9_last = false;
}

function Godmod_ShowToast(_text)
{
    var _t = ModInstance.Get("Godmod");
    if(_t != undefined)
    {
        _t.toast_msg = _text;
        _t.toast_timer = 180;
    }
}

function Godmod_Update()
{
    var _t = ModInstance.Get("Godmod");
    if(_t == undefined) return;

    if(_t.toast_timer > 0)
    {
        _t.toast_timer--;
    }

    var _f9_press = keyboard_check(vk_f9);
    if(_f9_press && !_t.f9_last)
    {
        _t.god_mode = !_t.god_mode;
        Godmod_ShowToast(_t.god_mode ? "GOD MODE: ATIVADO" : "GOD MODE: DESATIVADO");
    }
    _t.f9_last = _f9_press;

    if(_t.god_mode)
    {
        Godmod_KeepImmortal();
    }
}

function Godmod_KeepImmortal()
{
    if(!instance_exists(objPlayer)) return;

    with(objPlayer)
    {
        var _max_hp = 585.0;
        if(variable_global_exists("calculate_max_hp"))
        {
            try
            {
                var _calc_hp_fn = variable_global_get("calculate_max_hp");
                if(is_callable(_calc_hp_fn))
                {
                    _max_hp = is_method(_calc_hp_fn) ? method_call(_calc_hp_fn, [self]) : script_execute(_calc_hp_fn, self);
                }
            }
            catch(_e_hp) {}
        }
        else if(variable_instance_exists(self, "hpMax") && is_numeric(hpMax))
        {
            _max_hp = hpMax;
        }

        hp = real(_max_hp);
        if(variable_global_exists("PLAYER") && !is_undefined(global.PLAYER))
        {
            global.PLAYER.hp = real(_max_hp);
        }

        var _max_mp = 200.0;
        if(variable_global_exists("calculate_max_mp"))
        {
            try
            {
                var _calc_mp_fn = variable_global_get("calculate_max_mp");
                if(is_callable(_calc_mp_fn))
                {
                    _max_mp = is_method(_calc_mp_fn) ? method_call(_calc_mp_fn, [self]) : script_execute(_calc_mp_fn, self);
                }
            }
            catch(_e_mp) {}
        }
        else if(variable_instance_exists(self, "mpMax") && is_numeric(mpMax))
        {
            _max_mp = mpMax;
        }

        mp = real(_max_mp);
        if(variable_global_exists("PLAYER") && !is_undefined(global.PLAYER))
        {
            global.PLAYER.mp = real(_max_mp);
        }

        var _current_max_dashes = 4;
        if(variable_instance_exists(self, "dashesMax") && is_numeric(dashesMax) && dashesMax > 0)
        {
            _current_max_dashes = dashesMax;
        }
        else if(variable_instance_exists(self, "maxDashes") && is_numeric(maxDashes) && maxDashes > 0)
        {
            _current_max_dashes = maxDashes;
        }
        else if(variable_instance_exists(self, "dashes_max") && is_numeric(dashes_max) && dashes_max > 0)
        {
            _current_max_dashes = dashes_max;
        }
        else if(variable_global_exists("calculate_max_energy"))
        {
            try
            {
                var _calc_en_fn = variable_global_get("calculate_max_energy");
                if(is_callable(_calc_en_fn))
                {
                    _current_max_dashes = is_method(_calc_en_fn) ? method_call(_calc_en_fn, []) : script_execute(_calc_en_fn);
                }
            }
            catch(_e_en) {}
        }

        dashes = _current_max_dashes;
        if(variable_instance_exists(self, "dash_amount")) dash_amount = _current_max_dashes;
        if(variable_instance_exists(self, "dashRegenTime")) dashRegenTime = 0;
        if(variable_instance_exists(self, "dashRegenDelay")) dashRegenDelay = 0;
        if(variable_instance_exists(self, "dashTimer")) dashTimer = 0;

        if(variable_instance_exists(self, "invulnerable")) invulnerable = true;
        if(variable_instance_exists(self, "invincible")) invincible = true;
        if(variable_instance_exists(self, "iFrames") && is_numeric(iFrames) && iFrames < 30) iFrames = 30;
        if(variable_instance_exists(self, "damageMultiplier")) damageMultiplier = 0;
        if(variable_instance_exists(self, "damagedTimer")) damagedTimer = 30;
    }
}

function Godmod_DrawGUI()
{
    var _t = ModInstance.Get("Godmod");
    if(_t == undefined) return;

    var _gui_w = display_get_gui_width();
    var _scale = variable_global_exists("GUI_SCALE") ? GUI_SCALE : ((display_get_gui_height() > 0) ? (display_get_gui_height() / 1080.0) : 1.0);

    if(_t.toast_timer > 0 && string_length(_t.toast_msg) > 0)
    {
        var _alpha = clamp(_t.toast_timer / 30.0, 0, 1);
        var _tx = _gui_w * 0.5;
        var _ty = 70 * _scale;

        GUI.DrawText(
            _tx,
            _ty,
            _t.toast_msg,
            5,
            c_yellow,
            _alpha,
            2.2 * _scale
        );
    }

    if(_t.god_mode)
    {
        var _gx = _gui_w * 0.5;
        var _gy = 16 * _scale;

        GUI.DrawText(
            _gx,
            _gy,
            "[F9] GOD MODE ON",
            5,
            c_lime,
            0.9,
            1.6 * _scale
        );
    }
}
