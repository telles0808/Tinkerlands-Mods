/*
    ========================================================================
    TINKERLANDS - RealClock
    Author: Telles0808
    ID: 5002
    ========================================================================
*/

OnWorldGenerationEnd(function()
{
    var _clock = ModInstance.Get("RealClock");

    if(_clock == undefined)
    {
        ModInstance.Create(
            "RealClock",
            "RealClock_Create",
            "RealClock_Update",
            undefined,
            undefined,
            undefined
        );
    }
    else
    {
        _clock.cutscenePlaying = RealClock_GetCallable("cutscene_is_playing");
        _clock.cutscenePlayingOther = RealClock_GetCallable("cutscene_is_playing_except_player");
        RealClock_Refresh(_clock);
    }
});

// Draw after the native HUD so the minimap cannot cover the clock.
OnModDrawGUIEnd(function()
{
    RealClock_Draw();
});

function RealClock_Create()
{
    text = "--:--";
    tick = 0;

    cutscenePlaying = RealClock_GetCallable("cutscene_is_playing");
    cutscenePlayingOther = RealClock_GetCallable("cutscene_is_playing_except_player");

    RealClock_Refresh(id);
}

function RealClock_GetCallable(_name)
{
    if(!variable_global_exists(_name))
        return undefined;

    var _callable = variable_global_get(_name);

    return is_callable(_callable) ? _callable : undefined;
}

function RealClock_Call(_callable)
{
    if(is_method(_callable))
        return method_call(_callable, []);

    return script_execute(_callable);
}

function RealClock_CutsceneActive(_clock)
{
    if(is_callable(_clock.cutscenePlaying)
    && RealClock_Call(_clock.cutscenePlaying))
        return true;

    if(is_callable(_clock.cutscenePlayingOther)
    && RealClock_Call(_clock.cutscenePlayingOther))
        return true;

    return false;
}

function RealClock_HUDVisible(_clock)
{
    if(!instance_exists(objGUIIngameController))
        return false;

    if(RealClock_CutsceneActive(_clock))
        return false;

    if(variable_global_exists("guiEnabled") && !global.guiEnabled)
        return false;

    return true;
}

function RealClock_Pad2(_value)
{
    _value = floor(_value);

    return (_value < 10 ? "0" : "") + string(_value);
}

function RealClock_Refresh(_clock)
{
    var _now = date_current_datetime();
    var _hour = date_get_hour(_now);
    var _minute = date_get_minute(_now);

    _clock.text = RealClock_Pad2(_hour)
        + ":"
        + RealClock_Pad2(_minute);
}

function RealClock_Update()
{
    var _clock = ModInstance.Get("RealClock");

    if(_clock == undefined)
        return;

    _clock.tick++;

    if(_clock.tick >= 30)
    {
        _clock.tick = 0;
        RealClock_Refresh(_clock);
    }
}

function RealClock_ScaleRatio()
{
    var _height = display_get_gui_height();

    return (_height > 0)
        ? (_height / 1080.0)
        : 1.0;
}

function RealClock_Draw()
{
    var _clock = ModInstance.Get("RealClock");

    if(_clock == undefined || !RealClock_HUDVisible(_clock))
        return;

    var _ratio = RealClock_ScaleRatio();

    // 1920x1080 reference rectangle: x=1843, y=1, w=77, h=32.
    // Keep it attached to the right edge on every resolution.
    var _x = display_get_gui_width() - round(38.5 * _ratio);
    var _y = round(17 * _ratio);

    // The embedded pixel font is 25x8 at scale 1. At 3x it occupies
    // approximately 75x24 pixels and fits the 77x32 reference area.
    var _textScale = 3.0 * _ratio;

    GUI.DrawText(
        _x,
        _y,
        _clock.text,
        5,
        c_yellow,
        1,
        _textScale
    );
}
