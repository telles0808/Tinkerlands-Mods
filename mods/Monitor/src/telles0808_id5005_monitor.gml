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

OnModDrawGUIEnd(function()
{
    Monitor_Draw();
});

// ---------------------------------------------------------------------------
// STATE (100% STATELESS / ZERO .CFG DEPENDENCY)
// ---------------------------------------------------------------------------

function Monitor_GetState()
{
    if(!variable_global_exists("MONITOR_STATE"))
    {
        global.MONITOR_STATE = {
            active_index: 1, // Sempre inicia seguro no Monitor 1 (Principal)
            monitors: [
                { label: "2", x: -1920, y: 0, w: 1920, h: 1080 },
                { label: "1", x: 0,     y: 0, w: 1920, h: 1080 }
            ]
        };
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

// ---------------------------------------------------------------------------
// TROCA DE MONITOR (100% NATIVO GAMEMAKER)
// ---------------------------------------------------------------------------

function Monitor_SwitchTo(_state, _target_index)
{
    if(_target_index < 0 || _target_index >= array_length(_state.monitors))
        return;

    _state.active_index = _target_index;
    var _mon = _state.monitors[_target_index];

    // Transição nativa: janela sem bordas posicionada no monitor desejado
    window_set_fullscreen(false);
    window_set_showborder(false);
    window_set_position(_mon.x, 0);
    window_set_size(1920, 1080);
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
        var _colStand  = _active_stand(_is_active, _hover);
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

function _active_stand(_is_active, _hover)
{
    if(_is_active)
        return make_color_rgb(205, 155, 35);

    if(_hover)
        return make_color_rgb(150, 155, 165);

    return make_color_rgb(125, 130, 140);
}
