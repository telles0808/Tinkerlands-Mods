/*
    ========================================================================
    TINKERLANDS - Monitor
    Author: Telles0808
    ID: 5005
    ========================================================================
*/

OnModUpdate(function()
{
    Monitor_Update();
});

OnModDrawGUIEnd(function()
{
    Monitor_Draw();
});

function Monitor_GetState()
{
    if(!variable_global_exists("MONITOR_STATE"))
    {
        global.MONITOR_STATE = {
            monitors: []
        };

        Monitor_SetupDefaults(global.MONITOR_STATE);
    }

    return global.MONITOR_STATE;
}

function Monitor_ScaleRatio()
{
    var _height = display_get_gui_height();

    return (_height > 0) ? (_height / 1080.0) : 1.0;
}

function Monitor_IsTitleScreen()
{
    return instance_exists(objMenuMain);
}

function Monitor_SplitPipes(_str)
{
    var _arr = [];
    var _cur = _str;
    while(true)
    {
        var _p = string_pos("|", _cur);
        if(_p <= 0)
        {
            if(string_length(_cur) > 0)
                array_push(_arr, _cur);
            break;
        }
        array_push(_arr, string_copy(_cur, 1, _p - 1));
        _cur = string_delete(_cur, 1, _p);
    }
    return _arr;
}

function Monitor_DetectMonitors()
{
    var _monitors = [];

    // 1. Try native GameMaker window_get_visible_rects()
    try
    {
        var _fn_rects = undefined;
        if(variable_global_exists("window_get_visible_rects"))
            _fn_rects = variable_global_get("window_get_visible_rects");
        else
        {
            var _asset_idx = asset_get_index("window_get_visible_rects");
            if(_asset_idx >= 0) _fn_rects = _asset_idx;
        }

        if(!is_undefined(_fn_rects))
        {
            var _rects = is_callable(_fn_rects) ? (is_method(_fn_rects) ? method_call(_fn_rects, []) : script_execute(_fn_rects)) : undefined;

            if(is_array(_rects) && array_length(_rects) > 0)
            {
                if(is_array(_rects[0]))
                {
                    for(var i = 0; i < array_length(_rects); i++)
                    {
                        var _r = _rects[i];
                        if(is_array(_r) && array_length(_r) >= 4)
                        {
                            array_push(_monitors, {
                                x: real(_r[0]),
                                y: real(_r[1]),
                                w: real(_r[2]),
                                h: real(_r[3])
                            });
                        }
                    }
                }
                else if(array_length(_rects) % 4 == 0)
                {
                    for(var i = 0; i < array_length(_rects); i += 4)
                    {
                        array_push(_monitors, {
                            x: real(_rects[i]),
                            y: real(_rects[i + 1]),
                            w: real(_rects[i + 2]),
                            h: real(_rects[i + 3])
                        });
                    }
                }
            }
        }
    }
    catch(_e_detect) {}

    // 2. Fallback: probe current window / primary display if detection returned empty
    if(array_length(_monitors) <= 0)
    {
        var _dw = display_get_width();
        var _dh = display_get_height();

        if(_dw <= 0) _dw = 1920;
        if(_dh <= 0) _dh = 1080;

        // Primary display at (0,0)
        array_push(_monitors, { x: 0, y: 0, w: _dw, h: _dh });

        // Probe window position if window is currently on a secondary screen
        var _wx = window_get_x();
        if(_wx < -200)
        {
            var _left_x = -_dw;
            if(abs(_wx) > 1000) _left_x = round(_wx);
            array_push(_monitors, { x: _left_x, y: 0, w: _dw, h: _dh });
        }
        else if(_wx > _dw - 200)
        {
            array_push(_monitors, { x: _dw, y: 0, w: _dw, h: _dh });
        }
    }

    return _monitors;
}

function Monitor_SetupDefaults(_state)
{
    _state.monitors = [];

    // Read custom monitor.cfg if provided by user
    if(file_exists("monitor.cfg"))
    {
        var _file = file_text_open_read("monitor.cfg");
        if(_file >= 0)
        {
            while(!file_text_eof(_file))
            {
                var _line = file_text_read_string(_file);
                file_text_readln(_file);

                var _parts = Monitor_SplitPipes(_line);
                if(array_length(_parts) >= 5)
                {
                    var _lbl = _parts[0];
                    var _x_val = real(_parts[1]);
                    var _y_val = real(_parts[2]);
                    var _w_val = real(_parts[3]);
                    var _h_val = real(_parts[4]);

                    array_push(_state.monitors, {
                        label: _lbl,
                        x: _x_val,
                        y: _y_val,
                        w: _w_val,
                        h: _h_val
                    });
                }
            }
            file_text_close(_file);
        }
    }

    // Auto-detect connected monitors if monitor.cfg is not found or empty
    if(array_length(_state.monitors) <= 0)
    {
        _state.monitors = Monitor_DetectMonitors();
    }

    // Sort monitors by physical X coordinate ascending (left-to-right spatial order)
    for(var left = 0; left < array_length(_state.monitors) - 1; left++)
    {
        var _best = left;
        for(var right = left + 1; right < array_length(_state.monitors); right++)
        {
            if(_state.monitors[right].x < _state.monitors[_best].x)
                _best = right;
        }
        if(_best != left)
        {
            var _swap = _state.monitors[left];
            _state.monitors[left] = _state.monitors[_best];
            _state.monitors[_best] = _swap;
        }
    }

    // Assign left-to-right sequential labels 1, 2, 3...
    for(var m = 0; m < array_length(_state.monitors); m++)
    {
        _state.monitors[m].label = string(m + 1);
    }
}

function Monitor_GetActiveIndex(_state)
{
    var _wx = window_get_x();
    var _wy = window_get_y();
    var _count = array_length(_state.monitors);
    if(_count <= 0)
        return 0;

    var _best_idx = 0;
    var _min_dist = 999999999;

    for(var _m = 0; _m < _count; _m++)
    {
        var _mon = _state.monitors[_m];
        var _dist_x = max(0, _mon.x - _wx, _wx - (_mon.x + _mon.w - 1));
        var _dist_y = max(0, _mon.y - _wy, _wy - (_mon.y + _mon.h - 1));
        var _dist = _dist_x + _dist_y;

        if(_dist < _min_dist)
        {
            _min_dist = _dist;
            _best_idx = _m;
        }
    }

    return _best_idx;
}

function Monitor_SwitchTo(_state, _target_index)
{
    if(_target_index < 0 || _target_index >= array_length(_state.monitors))
        return;

    var _mon = _state.monitors[_target_index];

    window_set_fullscreen(false);
    window_set_showborder(false);
    window_set_position(_mon.x, _mon.y);
    window_set_size(_mon.w, _mon.h);
}

function Monitor_Update()
{
}

function Monitor_Draw()
{
    if(!Monitor_IsTitleScreen())
        return;

    var _state = Monitor_GetState();
    var _mon_count = array_length(_state.monitors);
    if(_mon_count <= 0)
        return;

    draw_set_alpha(1.0);
    draw_set_color(c_white);

    var _ratio = Monitor_ScaleRatio();

    var _startX = round(28 * _ratio);
    var _startY = round(24 * _ratio);
    var _btnW   = round(46 * _ratio);
    var _btnH   = round(40 * _ratio);
    var _gap    = round(10 * _ratio);

    var _mx = device_mouse_x_to_gui(0);
    var _my = device_mouse_y_to_gui(0);

    var _active_idx = Monitor_GetActiveIndex(_state);

    for(var _i = 0; _i < _mon_count; _i++)
    {
        var _mon = _state.monitors[_i];
        var _bx = _startX + _i * (_btnW + _gap);
        var _by = _startY;

        var _hover = (_mx >= _bx && _mx < _bx + _btnW && _my >= _by && _my < _by + _btnH);

        if(_hover && mouse_check_button_pressed(mb_left))
        {
            mouse_clear(mb_left);
            Monitor_SwitchTo(_state, _i);
            _active_idx = _i;
        }

        var _is_active = (_i == _active_idx);
        var _is_pressed = (_hover && mouse_check_button(mb_left));
        var _pressOffsetY = _is_pressed ? round(2 * _ratio) : 0;
        var _drawY = _by + _pressOffsetY;

        var _colBezel  = _is_active ? make_color_rgb(255, 205, 50)  : (_hover ? make_color_rgb(220, 225, 235) : make_color_rgb(175, 180, 190));
        var _colScreen = _is_active ? make_color_rgb(25, 100, 190)  : (_hover ? make_color_rgb(115, 120, 135) : make_color_rgb(85, 90, 100));
        var _colStand  = _is_active ? make_color_rgb(205, 155, 35)  : (_hover ? make_color_rgb(150, 155, 165) : make_color_rgb(125, 130, 140));
        var _colText   = _is_active ? make_color_rgb(255, 245, 140) : c_white;

        var _screenH    = _btnH - round(10 * _ratio);
        var _standW     = round(10 * _ratio);
        var _standFootW = round(20 * _ratio);
        var _cx         = _bx + (_btnW * 0.5);

        draw_set_color(_colStand);
        draw_rectangle(
            round(_cx - _standW * 0.5),
            round(_drawY + _screenH - 1),
            round(_cx + _standW * 0.5),
            round(_drawY + _btnH - 3 * _ratio),
            false
        );

        draw_rectangle(
            round(_cx - _standFootW * 0.5),
            round(_drawY + _btnH - 3 * _ratio),
            round(_cx + _standFootW * 0.5),
            round(_drawY + _btnH),
            false
        );

        draw_set_color(_colBezel);
        draw_rectangle(_bx, _drawY, _bx + _btnW, _drawY + _screenH, false);

        var _pad = round(3 * _ratio);
        draw_set_color(_colScreen);
        draw_rectangle(
            _bx + _pad,
            _drawY + _pad,
            _bx + _btnW - _pad,
            _drawY + _screenH - _pad,
            false
        );

        if(_is_active)
        {
            draw_set_color(make_color_rgb(90, 180, 255));
            draw_line(
                _bx + _pad + 1,
                _drawY + _pad + 1,
                _bx + _btnW - _pad - 1,
                _drawY + _pad + 1
            );
        }

        var _num_str = string(_mon.label);
        var _text_x = round(_cx);
        var _text_y = round(_drawY + (_screenH * 0.5));
        var _textScale = 2.2 * _ratio;

        GUI.DrawText(
            _text_x,
            _text_y,
            _num_str,
            5,
            _colText,
            1.0,
            _textScale
        );
    }

    draw_set_alpha(1.0);
    draw_set_color(c_white);
}
