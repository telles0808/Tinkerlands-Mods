/*
    ========================================================================
    TINKERLANDS - Monitor
    Author: Telles0808
    ID: 5005
    ========================================================================
*/

// ---------------------------------------------------------------------------
// LIFECYCLE HOOKS
// ---------------------------------------------------------------------------

OnModUpdate(function()
{
    Monitor_Update();
});

OnModDrawGUIEnd(function()
{
    Monitor_Draw();
});

// ---------------------------------------------------------------------------
// STATE & CONFIGURATION
// ---------------------------------------------------------------------------

function Monitor_GetState()
{
    if(!variable_global_exists("MONITOR_STATE"))
    {
        global.MONITOR_STATE = {
            applied_startup: false,
            frame_counter: 0,
            active_index: 1,
            monitors: []
        };

        Monitor_LoadConfig(global.MONITOR_STATE);
    }

    return global.MONITOR_STATE;
}

function Monitor_ScaleRatio()
{
    var _height = display_get_gui_height();

    return (_height > 0)
        ? (_height / 1080.0)
        : 1.0;
}

function Monitor_IsTitleScreen()
{
    return instance_exists(objMenuMain);
}

function Monitor_SetupDefaults(_state)
{
    _state.monitors = [];

    // Sequência do sistema: Monitor 2 na esquerda (X = -1920), Monitor 1 na direita (X = 0)
    var _m_left = {
        label: "2",
        x: -1920,
        y: 0,
        w: 1920,
        h: 1080
    };

    var _m_right = {
        label: "1",
        x: 0,
        y: 0,
        w: 1920,
        h: 1080
    };

    array_push(_state.monitors, _m_left);
    array_push(_state.monitors, _m_right);

    var _cur_x = window_get_x();
    _state.active_index = (_cur_x < -400) ? 0 : 1;
}

function Monitor_LoadConfig(_state)
{
    Monitor_SetupDefaults(_state);

    if(file_exists("monitor.cfg"))
    {
        var _file = file_text_open_read("monitor.cfg");
        if(_file >= 0)
        {
            var _str = file_text_read_string(_file);
            file_text_close(_file);
            var _digits = string_digits(_str);
            if(string_length(_digits) > 0)
            {
                var _val = real(_digits);
                _state.active_index = clamp(_val, 0, 1);
            }
        }
    }
}

function Monitor_SaveConfig(_state)
{
    var _file = file_text_open_write("monitor.cfg");
    if(_file >= 0)
    {
        file_text_write_string(_file, "active=" + string(_state.active_index));
        file_text_close(_file);
    }
}

// ---------------------------------------------------------------------------
// TROCA DE MONITOR (100% NATIVO GAMEMAKER)
// ---------------------------------------------------------------------------

function Monitor_SwitchTo(_state, _target_index)
{
    if(_target_index < 0 || _target_index >= array_length(_state.monitors))
        return;

    _state.active_index = _target_index;
    var _mon = _state.monitors[_target_index];

    // Transição nativa que move a janela sem bordas para o monitor correto
    window_set_fullscreen(false);
    window_set_showborder(false);
    window_set_position(_mon.x, 0);
    window_set_size(1920, 1080);

    Monitor_SaveConfig(_state);
}

// ---------------------------------------------------------------------------
// ATUALIZAÇÃO
// ---------------------------------------------------------------------------

function Monitor_Update()
{
    var _state = Monitor_GetState();

    if(!_state.applied_startup)
    {
        _state.frame_counter++;
        if(_state.frame_counter >= 30)
        {
            _state.applied_startup = true;
            // Se o monitor salvo for o 2 (esquerda, índice 0) e a janela estiver na direita, move
            if(_state.active_index == 0 && window_get_x() >= -400)
            {
                Monitor_SwitchTo(_state, 0);
            }
        }
        return;
    }
}

// ---------------------------------------------------------------------------
// RENDERIZAÇÃO DOS BOTÕES
// ---------------------------------------------------------------------------

function Monitor_Draw()
{
    if(!Monitor_IsTitleScreen())
        return;

    var _state = Monitor_GetState();
    var _mon_count = array_length(_state.monitors);
    if(_mon_count <= 0)
        return;

    // Reset estrito antes de desenhar qualquer elemento
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

    for(var _i = 0; _i < _mon_count; _i++)
    {
        var _mon = _state.monitors[_i];
        var _bx = _startX + _i * (_btnW + _gap);
        var _by = _startY;

        var _hover = (_mx >= _bx && _mx < _bx + _btnW && _my >= _by && _my < _by + _btnH);
        var _is_active = (_i == _state.active_index);

        if(_hover && mouse_check_button_pressed(mb_left))
        {
            mouse_clear(mb_left);
            Monitor_SwitchTo(_state, _i);
        }

        var _is_pressed = (_hover && mouse_check_button(mb_left));
        var _pressOffsetY = _is_pressed ? round(2 * _ratio) : 0;
        var _drawY = _by + _pressOffsetY;

        // Paleta de alto contraste, 100% opaca
        // Ativo: Dourado vivo + tela azul ciano + texto amarelo
        // Inativo: Moldura prata claro + tela cinza ardósia + texto branco nítido
        var _colBezel  = _is_active ? make_color_rgb(255, 205, 50)  : (_hover ? make_color_rgb(220, 225, 235) : make_color_rgb(175, 180, 190));
        var _colScreen = _is_active ? make_color_rgb(25, 100, 190)  : (_hover ? make_color_rgb(115, 120, 135) : make_color_rgb(85, 90, 100));
        var _colStand  = _is_active ? make_color_rgb(205, 155, 35)  : (_hover ? make_color_rgb(150, 155, 165) : make_color_rgb(125, 130, 140));
        var _colText   = _is_active ? make_color_rgb(255, 245, 140) : c_white;

        var _screenH    = _btnH - round(10 * _ratio);
        var _standW     = round(10 * _ratio);
        var _standFootW = round(20 * _ratio);
        var _cx         = _bx + (_btnW * 0.5);

        // 1. Suporte e base
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

        // 2. Moldura externa
        draw_set_color(_colBezel);
        draw_rectangle(_bx, _drawY, _bx + _btnW, _drawY + _screenH, false);

        // 3. Tela interna
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

        // 4. Número central
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

    // Reset estrito ao final
    draw_set_alpha(1.0);
    draw_set_color(c_white);
}
