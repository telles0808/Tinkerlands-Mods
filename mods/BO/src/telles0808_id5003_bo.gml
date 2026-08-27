/*
    ========================================================================
    TINKERLANDS - Better Organizer (BO)
    Author: Telles0808
    ID: 5003
    ========================================================================
*/

OnModLoad(function()
{
    BO_LogImmediate("");
    BO_LogImmediate("========================================");
    BO_LogImmediate("[BO] Better Organizer TRACE");

    ModInstance.Create(
        "BO",
        "BO_Create",
        "BO_Update",
        undefined,
        "BO_DrawGUI",
        undefined
    );
});


OnWorldGenerationEnd(function()
{
    var _bo = ModInstance.Get("BO");

    if(_bo != undefined)
    {
        _bo.world_ready = true;
        _bo.busy = false;
        _bo.inventory_visible_last = false;
        _bo.inventory_opened_at = 0;
        _bo.button_ready = false;
        _bo.feedback_active = false;
        _bo.feedback_started_at = 0;
        _bo.chest_filters = [];
        _bo.loaded_filter_containers = [];
        _bo.persisted_filters = BO_LoadPersistedFilters();
        _bo.open_chest_container = undefined;
        _bo.open_chest_changed_at = 0;
        _bo.filter_feedback_index = -1;
        _bo.filter_feedback_started_at = 0;
        _bo.hovered_filter_index = -1;
        BO_LogImmediate("[BO] World ready. Loaded persisted filters: " + string(array_length(_bo.persisted_filters)));
    }
});


// ============================================================================
// STATE
// ============================================================================

function BO_Create()
{
    world_ready = false;
    busy = false;
    inventory_visible_last = false;
    inventory_opened_at = 0;
    button_ready = false;
    feedback_active = false;
    feedback_started_at = 0;
    chest_filters = [];
    loaded_filter_containers = [];
    persisted_filters = BO_LoadPersistedFilters();
    open_chest_container = undefined;
    open_chest_changed_at = 0;
    filter_feedback_index = -1;
    filter_feedback_started_at = 0;
    hovered_filter_index = -1;
}


function BO_Update()
{
    var _bo = ModInstance.Get("BO");

    if(_bo == undefined)
        return;

    var _visible = BO_InventoryVisible();

    if(!_visible)
    {
        _bo.inventory_visible_last = false;
        _bo.inventory_opened_at = 0;
        _bo.button_ready = false;
        _bo.feedback_active = false;
        _bo.open_chest_container = undefined;
        _bo.filter_feedback_index = -1;
        _bo.hovered_filter_index = -1;

        return;
    }

    if(!_bo.inventory_visible_last)
    {
        _bo.inventory_visible_last = true;
        _bo.inventory_opened_at = get_timer();
        _bo.button_ready = false;
        _bo.feedback_active = false;
    }

    BO_UpdateOpenChest(_bo);
    BO_PreloadNearbyFilters();

    if(BO_FilterButtonInput(_bo))
        return;

    if(!_bo.button_ready)
    {
        if(get_timer() - _bo.inventory_opened_at < 300000)
            return;

        _bo.button_ready = true;
    }

    if(_bo.busy)
        return;

    var _button = BO_ButtonGeometry();
    var _mx = device_mouse_x_to_gui(0);
    var _my = device_mouse_y_to_gui(0);
    var _half = _button.hit_size * 0.5;

    if(
        _mx >= _button.x - _half
        && _mx <= _button.x + _half
        && _my >= _button.y - _half
        && _my <= _button.y + _half
    )
    {
        // Prevents world attack / tool swing click-through
        with(objGUIIngameController)
        {
            craftMo = true;
        }

        Input.DisableMenuInputs(0.1);

        if(mouse_check_button_pressed(mb_left))
        {
            _bo.feedback_active = true;
            _bo.feedback_started_at = get_timer();
            mouse_clear(mb_left);
            BO_RunRepeatedDeposit();
        }
    }
}


// ============================================================================
// INVENTORY VISIBILITY
// ============================================================================

function BO_InventoryVisible()
{
    var _bo = ModInstance.Get("BO");

    if(_bo == undefined || !_bo.world_ready)
        return false;

    if(!Container.Exists(INVENTORY))
        return false;

    if(!variable_global_exists("container_get_open"))
        return false;

    var _get_open = variable_global_get("container_get_open");

    if(!is_callable(_get_open))
        return false;

    var _args = [INVENTORY];

    if(is_method(_get_open))
        return method_call(_get_open, _args);

    return script_execute_ext(_get_open, _args);
}


// ============================================================================
// B.O. BUTTON
// ============================================================================

function BO_DrawGUI()
{
    var _bo = ModInstance.Get("BO");

    if(
        _bo == undefined
        || !BO_InventoryVisible()
    )
    {
        return;
    }

    if(_bo.button_ready)
        BO_DrawMainButton(_bo);

    BO_DrawChestFilters(_bo);
}


function BO_DrawMainButton(_bo)
{
    var _button = BO_ButtonGeometry();
    var _icon = sprGUIIngameInventoryIconQuickChest;
    var _icon_scale = GUI_SCALE;
    var _visual_y = _button.y;
    var _press = 0;

    if(_bo.feedback_active)
    {
        var _feedback_elapsed = get_timer() - _bo.feedback_started_at;

        if(_feedback_elapsed >= 200000)
        {
            _bo.feedback_active = false;
        }
        else
        {
            var _phase = _feedback_elapsed / 200000.0;

            if(_phase < 0.5)
                _press = _phase * 2;
            else
                _press = (1 - _phase) * 2;

            _visual_y += 2.5 * GUI_SCALE * _press;
            _icon_scale *= 1 - 0.08 * _press;
        }
    }

    var _icon_offset_x =
        (
            sprite_get_xoffset(_icon)
            - sprite_get_width(_icon) * 0.5
        )
        * _icon_scale;

    var _icon_offset_y =
        (
            sprite_get_yoffset(_icon)
            - sprite_get_height(_icon) * 0.5
        )
        * _icon_scale;

    Draw.Sprite(
        _icon,
        0,
        _button.x + _icon_offset_x,
        _visual_y + _icon_offset_y,
        _icon_scale,
        _icon_scale,
        0,
        c_white,
        1
    );

    GUI.DrawText(
        _button.x,
        _visual_y - 8.5 * _icon_scale,
        "BO",
        5,
        c_yellow,
        1,
        0.52 * _icon_scale
    );
}


function BO_ButtonGeometry()
{
    return {
        x: display_get_gui_width() * 0.5 - 50.6667 * GUI_SCALE,
        y: display_get_gui_height() - 10 * GUI_SCALE,
        hit_size: 28 * GUI_SCALE
    };
}


// ============================================================================
// OPEN CHEST / FILTER BAR
// ============================================================================

function BO_UpdateOpenChest(_bo)
{
    var _open = BO_GetOpenNearbyChestContainer(_bo);

    if(_open != _bo.open_chest_container)
    {
        BO_LogImmediate(
            "[BO][OPEN-CHEST] previous="
            + string(_bo.open_chest_container)
            + " current="
            + string(_open)
        );

        _bo.open_chest_container = _open;
        _bo.open_chest_changed_at = get_timer();
        _bo.filter_feedback_index = -1;
        _bo.hovered_filter_index = -1;

        if(!is_undefined(_open))
        {
            BO_EnsureChestFilterLoaded(_open);
        }
    }
}


function BO_GetOpenNearbyChestContainer(_bo)
{
    var _get_open = BO_GetCallable("container_get_open");

    if(is_undefined(_get_open))
        return undefined;

    var _nearby = BO_GetNearbyContainers();

    for(var i = 0; i < array_length(_nearby); i++)
    {
        var _container = _nearby[i];

        if(
            Container.Exists(_container)
            && BO_Call1(_get_open, _container)
        )
        {
            return _container;
        }
    }

    return undefined;
}


function BO_FilterButtonGeometry(_index)
{
    var _scale_x = display_get_gui_width() / 1920.0;
    var _scale_y = display_get_gui_height() / 1080.0;
    var _scale = min(_scale_x, _scale_y);
    var _left = 127 * _scale_x;
    var _spacing = 34 * _scale_x;

    return {
        x: _left + (17 + _index * 34) * _scale_x,
        bottom: 587 * _scale_y,
        hit_size: 40 * _scale,
        visual_size: 30 * _scale,
        spacing: _spacing
    };
}


function BO_FilterIcon(_index)
{
    switch(_index)
    {
        case 0: return sprItemWood;
        case 1: return sprItemWood;
        case 2: return sprItemWallStone;
        case 3: return sprPotionHP;
        case 4: return sprItemWoodenShield;
        case 5: return sprItemArrowWood;
        case 6: return sprItemCoinGold;
    }

    return sprGUIIngameInventoryIconQuickChest;
}


function BO_FilterBit(_index)
{
    switch(_index)
    {
        case 1: return 1;
        case 2: return 2;
        case 3: return 4;
        case 4: return 8;
        case 5: return 16;
        case 6: return 32;
    }

    return 0;
}


function BO_FilterButtonActive(_container, _index)
{
    var _filter = BO_GetChestFilter(_container);

    if(is_undefined(_filter))
        return false;

    if(_index == 0)
        return _filter.existing_only;

    var _bit = BO_FilterBit(_index);

    return (_filter.category_mask & _bit) != 0;
}


function BO_FilterButtonInput(_bo)
{
    if(
        is_undefined(_bo.open_chest_container)
        || !Container.Exists(_bo.open_chest_container)
    )
    {
        _bo.hovered_filter_index = -1;
        return false;
    }

    var _hovered = BO_HoveredFilterIndex();

    if(_hovered >= 0)
    {
        _bo.hovered_filter_index = _hovered;

        // Prevents world action / tool attack click-through
        with(objGUIIngameController)
        {
            craftMo = true;
        }

        Input.DisableMenuInputs(0.1);

        if(mouse_check_button_pressed(mb_left))
        {
            BO_ToggleChestFilter(
                _bo.open_chest_container,
                _hovered
            );
            _bo.filter_feedback_index = _hovered;
            _bo.filter_feedback_started_at = get_timer();
            mouse_clear(mb_left);

            BO_LogImmediate(
                "[BO][FILTER] button="
                + string(_hovered)
                + " open_container="
                + string(_bo.open_chest_container)
                + " state={"
                + BO_FilterTrace(_bo.open_chest_container)
                + "} "
                + BO_ContainerPhysicalTrace(
                    _bo.open_chest_container
                )
            );
        }

        return true;
    }

    _bo.hovered_filter_index = -1;
    return false;
}


function BO_HoveredFilterIndex()
{
    var _mx = device_mouse_x_to_gui(0);
    var _my = device_mouse_y_to_gui(0);
    var _scale_y = display_get_gui_height() / 1080.0;
    var _scale = (_scale_y > 0) ? _scale_y : 1.0;

    for(var i = 0; i < 7; i++)
    {
        var _button = BO_FilterButtonGeometry(i);
        var _half_w = max(18 * _scale, _button.hit_size * 0.5);
        var _y_top = _button.bottom - 46 * _scale;
        var _y_bottom = _button.bottom + 8 * _scale;

        if(
            _mx >= _button.x - _half_w
            && _mx <= _button.x + _half_w
            && _my >= _y_top
            && _my <= _y_bottom
        )
        {
            return i;
        }
    }

    return -1;
}


function BO_DrawChestFilters(_bo)
{
    if(
        is_undefined(_bo.open_chest_container)
        || !Container.Exists(_bo.open_chest_container)
    )
    {
        return;
    }

    var _feedback_elapsed = get_timer() - _bo.filter_feedback_started_at;

    if(
        _bo.filter_feedback_index >= 0
        && _feedback_elapsed >= 200000
    )
    {
        _bo.filter_feedback_index = -1;
    }

    for(var i = 0; i < 7; i++)
    {
        var _button = BO_FilterButtonGeometry(i);
        var _icon = BO_FilterIcon(i);
        var _size = _button.visual_size;
        var _rotation = (i == 5) ? -45 : 0;
        var _reference_scale = _button.visual_size / 34.0;
        var _press = 0;

        if(_bo.filter_feedback_index == i)
        {
            var _phase = _feedback_elapsed / 200000.0;

            if(_phase < 0.5)
                _press = _phase * 2;
            else
                _press = (1 - _phase) * 2;

            _size *= 1 - 0.08 * _press;
        }

        if(i == 0)
            _size *= 0.79;

        var _icon_scale =
            _size
            / max(
                sprite_get_width(_icon),
                sprite_get_height(_icon)
            );

        var _center_y =
            _button.bottom
            - _size * 0.5
            + 2.5 * _reference_scale * _press;

        var _offset_x =
            (
                sprite_get_xoffset(_icon)
                - sprite_get_width(_icon) * 0.5
            )
            * _icon_scale;

        var _offset_y =
            (
                sprite_get_yoffset(_icon)
                - sprite_get_height(_icon) * 0.5
            )
            * _icon_scale;

        var _active = BO_FilterButtonActive(
            _bo.open_chest_container,
            i
        );

        var _draw_x = _button.x;

        if(i == 0)
            _draw_x -= 5 * _reference_scale;

        Draw.Sprite(
            _icon,
            0,
            _draw_x + _offset_x,
            _center_y + _offset_y,
            _icon_scale,
            _icon_scale,
            _rotation,
            _active ? c_white : c_gray,
            _active ? 1 : 0.55
        );

        if(i == 0)
        {
            Draw.Sprite(
                _icon,
                0,
                _draw_x + 10 * _reference_scale + _offset_x,
                _center_y + _offset_y,
                _icon_scale,
                _icon_scale,
                0,
                _active ? c_white : c_gray,
                _active ? 1 : 0.55
            );
        }
    }
}


// ============================================================================
// FILTERED DEPOSIT CORE
// ============================================================================

function BO_RunRepeatedDeposit()
{
    var _bo = ModInstance.Get("BO");

    BO_LogImmediate("");
    BO_LogImmediate("[BO][RUN] ===== B.O. click trace begin =====");

    if(
        _bo == undefined
        || !_bo.world_ready
        || _bo.busy
    )
    {
        BO_LogImmediate("[BO][RUN] cancelled: state unavailable or busy");
        return;
    }

    if(!Container.Exists(INVENTORY))
    {
        BO_LogImmediate("[BO][RUN] cancelled: INVENTORY unavailable");
        return;
    }

    var _contains = BO_GetCallable("container_contains_item");
    var _move_item = BO_GetCallable("container_item_move");

    if(is_undefined(_contains) || is_undefined(_move_item))
    {
        BO_LogImmediate(
            "[BO][RUN] cancelled: contains="
            + string(!is_undefined(_contains))
            + " move_item="
            + string(!is_undefined(_move_item))
        );
        return;
    }

    _bo.busy = true;

    var _all_nearby = BO_GetNearbyContainersByDistance();
    var _nearby = [];

    for(var candidate_index = 0; candidate_index < array_length(_all_nearby); candidate_index++)
    {
        var _candidate = _all_nearby[candidate_index];

        if(!is_undefined(BO_GetChestFilter(_candidate)))
        {
            array_push(_nearby, _candidate);
        }
        else
        {
            BO_LogImmediate(
                "[BO][NEARBY-EXCLUDED] container="
                + string(_candidate)
                + " reason=no active filter "
                + BO_ContainerPhysicalTrace(_candidate)
            );
        }
    }

    if(array_length(_nearby) == 0)
    {
        _bo.busy = false;
        BO_LogImmediate("[BO][RUN] cancelled: no filtered nearby chest");
        return;
    }

    var _items = BO_SnapshotMovableInventoryCells();

    BO_LogImmediate(
        "[BO][RUN] filtered_nearby="
        + string(array_length(_nearby))
        + " inventory_sources="
        + string(array_length(_items))
    );

    for(var i = 0; i < array_length(_items); i++)
    {
        var _source = _items[i];
        var _item = Container.GetItem(INVENTORY, _source.x, _source.y);

        if(is_undefined(_item) || !BO_ItemIsMovable(_item, INVENTORY, _source.x, _source.y))
            continue;

        var _item_id = BO_ItemID(_item);

        if(is_undefined(_item_id))
            continue;

        // Priority 0: Chests that already contain this item (existing piles first)
        // Priority 1: Other compatible filtered chests
        for(var _priority = 0; _priority <= 1; _priority++)
        {
            for(var c = 0; c < array_length(_nearby); c++)
            {
                var _destination = _nearby[c];

                if(!Container.Exists(_destination))
                    continue;

                var _current = Container.GetItem(
                    INVENTORY,
                    _source.x,
                    _source.y
                );

                if(
                    is_undefined(_current)
                    || !BO_ItemIsMovable(_current, INVENTORY, _source.x, _source.y)
                    || BO_ItemID(_current) != _item_id
                )
                {
                    break;
                }

                if(
                    BO_DestinationPriority(
                        _destination,
                        _current,
                        _contains
                    ) != _priority
                )
                {
                    continue;
                }

                BO_LogImmediate(
                    "[BO][MOVE] item_id="
                    + string(_item_id)
                    + " from=("
                    + string(_source.x)
                    + ","
                    + string(_source.y)
                    + ") to_container="
                    + string(_destination)
                    + " priority="
                    + string(_priority)
                );

                BO_Call2(_move_item, _current, _destination);
            }

            var _after = Container.GetItem(
                INVENTORY,
                _source.x,
                _source.y
            );

            if(
                is_undefined(_after)
                || !BO_ItemIsMovable(_after, INVENTORY, _source.x, _source.y)
                || BO_ItemID(_after) != _item_id
            )
            {
                break;
            }
        }
    }

    _bo.busy = false;
    BO_LogImmediate("[BO][RUN] ===== B.O. click trace end =====");
}


function BO_SnapshotMovableInventoryCells()
{
    var _items = [];

    if(!Container.Exists(INVENTORY))
        return _items;

    var _width = Container.GetWidth(INVENTORY);
    var _height = Container.GetHeight(INVENTORY);

    // Protect row 0 (hotbar action slots)
    for(var y = 1; y < _height; y++)
    {
        for(var x = 0; x < _width; x++)
        {
            var _item = Container.GetItem(INVENTORY, x, y);

            if(!is_undefined(_item) && BO_ItemIsMovable(_item, INVENTORY, x, y))
            {
                array_push(
                    _items,
                    {
                        x: x,
                        y: y
                    }
                );
            }
        }
    }

    return _items;
}


// ============================================================================
// DESTINATION FILTER / PRIORITY
// ============================================================================

function BO_LoadPersistedFilters()
{
    var _entries = [];

    if(!file_exists("BO_filters.cfg"))
    {
        BO_LogImmediate("[BO][PERSIST] BO_filters.cfg not found on disk.");
        return _entries;
    }

    var _file = file_text_open_read("BO_filters.cfg");

    if(_file < 0)
    {
        BO_LogImmediate("[BO][PERSIST] failed to open BO_filters.cfg for read.");
        return _entries;
    }

    while(!file_text_eof(_file))
    {
        var _line = file_text_read_string(_file);
        file_text_readln(_file);

        var _first = string_pos("|", _line);

        if(_first <= 1)
            continue;

        var _tail = string_delete(_line, 1, _first);
        var _second = string_pos("|", _tail);

        if(_second <= 1)
            continue;

        var _key = string_copy(_line, 1, _first - 1);
        var _existing_text = string_copy(
            _tail,
            1,
            _second - 1
        );
        var _mask_text = string_delete(_tail, 1, _second);

        array_push(
            _entries,
            {
                key: _key,
                existing_only: real(_existing_text) != 0,
                category_mask: clamp(
                    floor(real(_mask_text)),
                    0,
                    63
                )
            }
        );
    }

    file_text_close(_file);
    BO_LogImmediate("[BO][PERSIST] loaded " + string(array_length(_entries)) + " filter entries.");
    return _entries;
}


function BO_WritePersistedFilters()
{
    var _bo = ModInstance.Get("BO");

    if(_bo == undefined)
        return;

    var _file = file_text_open_write("BO_filters.cfg");

    if(_file < 0)
    {
        BO_LogImmediate("[BO][PERSIST] failed to open BO_filters.cfg for write!");
        return;
    }

    for(var i = 0; i < array_length(_bo.persisted_filters); i++)
    {
        var _entry = _bo.persisted_filters[i];

        file_text_write_string(
            _file,
            _entry.key
            + "|"
            + string(_entry.existing_only ? 1 : 0)
            + "|"
            + string(_entry.category_mask)
        );
        file_text_writeln(_file);
    }

    file_text_close(_file);
    BO_LogImmediate("[BO][PERSIST] saved " + string(array_length(_bo.persisted_filters)) + " filter entries.");
}


function BO_PersistedFilterIndex(_key)
{
    var _bo = ModInstance.Get("BO");

    if(_bo == undefined)
        return -1;

    for(var i = 0; i < array_length(_bo.persisted_filters); i++)
    {
        if(_bo.persisted_filters[i].key == _key)
            return i;
    }

    return -1;
}


function BO_SetPersistedFilter(
    _key,
    _existing_only,
    _category_mask
)
{
    var _bo = ModInstance.Get("BO");

    if(_bo == undefined)
        return;

    var _index = BO_PersistedFilterIndex(_key);

    if(!_existing_only && _category_mask == 0)
    {
        if(_index >= 0)
            array_delete(_bo.persisted_filters, _index, 1);
    }
    else
    {
        var _entry = {
            key: _key,
            existing_only: _existing_only,
            category_mask: _category_mask
        };

        if(_index >= 0)
            _bo.persisted_filters[_index] = _entry;
        else
            array_push(_bo.persisted_filters, _entry);
    }

    BO_WritePersistedFilters();
}


function BO_PreloadNearbyFilters()
{
    var _nearby = BO_GetNearbyContainers();

    for(var i = 0; i < array_length(_nearby); i++)
        BO_EnsureChestFilterLoaded(_nearby[i]);
}


function BO_EnsureChestFilterLoaded(_container)
{
    var _bo = ModInstance.Get("BO");

    if(
        _bo == undefined
        || !Container.Exists(_container)
    )
    {
        return;
    }

    for(var i = 0;
        i < array_length(_bo.loaded_filter_containers);
        i++)
    {
        if(_bo.loaded_filter_containers[i] == _container)
            return;
    }

    array_push(_bo.loaded_filter_containers, _container);

    var _section = BO_FilterStorageSection(_container);

    if(string_length(_section) <= 0)
        return;

    var _persisted_index = BO_PersistedFilterIndex(_section);
    var _existing_only = false;
    var _category_mask = 0;

    if(_persisted_index >= 0)
    {
        var _persisted = _bo.persisted_filters[_persisted_index];
        _existing_only = _persisted.existing_only;
        _category_mask = _persisted.category_mask;
    }

    if(_existing_only || _category_mask != 0)
    {
        var _cf_idx = BO_GetChestFilterIndex(_container);

        if(_cf_idx < 0)
        {
            array_push(
                _bo.chest_filters,
                {
                    container: _container,
                    existing_only: _existing_only,
                    category_mask: _category_mask
                }
            );
        }
        else
        {
            _bo.chest_filters[_cf_idx].existing_only = _existing_only;
            _bo.chest_filters[_cf_idx].category_mask = _category_mask;
        }
    }

    BO_LogImmediate(
        "[BO][FILTER-LOAD] key="
        + _section
        + " container="
        + string(_container)
        + " existing_only="
        + string(_existing_only)
        + " mask="
        + string(_category_mask)
    );
}


function BO_SaveChestFilter(_container, _filter)
{
    var _section = BO_FilterStorageSection(_container);

    if(string_length(_section) <= 0)
        return;

    var _existing_only = _filter.existing_only ? 1 : 0;
    var _category_mask = clamp(
        floor(_filter.category_mask),
        0,
        63
    );

    BO_SetPersistedFilter(
        _section,
        _existing_only != 0,
        _category_mask
    );

    BO_LogImmediate(
        "[BO][FILTER-SAVE] key="
        + _section
        + " existing_only="
        + string(_existing_only)
        + " mask="
        + string(_category_mask)
    );
}


function BO_FilterStorageSection(_container)
{
    var _result = "";

    if(instance_exists(objInteractableChest))
    {
        var _count = instance_number(objInteractableChest);

        for(var i = 0; i < _count; i++)
        {
            var _chest = instance_find(objInteractableChest, i);

            if(
                _chest != undefined
                && instance_exists(_chest)
                && variable_instance_exists(_chest, "container")
                && variable_instance_get(_chest, "container") == _container
            )
            {
                _result = "chest_x"
                    + string(round(_chest.x))
                    + "_y"
                    + string(round(_chest.y));
                return _result;
            }
        }
    }

    if(instance_exists(objInteractableChestAstral))
    {
        var _count_astral = instance_number(objInteractableChestAstral);

        for(var a = 0; a < _count_astral; a++)
        {
            var _chest_a = instance_find(objInteractableChestAstral, a);

            if(
                _chest_a != undefined
                && instance_exists(_chest_a)
                && variable_instance_exists(_chest_a, "container")
                && variable_instance_get(_chest_a, "container") == _container
            )
            {
                _result = "astral_x"
                    + string(round(_chest_a.x))
                    + "_y"
                    + string(round(_chest_a.y));
                return _result;
            }
        }
    }

    return _result;
}


function BO_DestinationPriority(_container, _item, _contains)
{
    if(!BO_FilterAllowsItem(_container, _item))
        return -1;

    var _item_id = BO_ItemID(_item);
    var _filter = BO_GetChestFilter(_container);
    var _contains_item =
        !is_undefined(_item_id)
        && BO_Call2(_contains, _item_id, _container);

    if(!is_undefined(_filter) && _contains_item)
        return 0;

    if(!is_undefined(_filter))
        return 1;

    return -1;
}


function BO_GetChestFilter(_container)
{
    var _bo = ModInstance.Get("BO");

    if(_bo == undefined)
        return undefined;

    for(var i = 0; i < array_length(_bo.chest_filters); i++)
    {
        var _filter = _bo.chest_filters[i];

        if(_filter.container == _container)
            return _filter;
    }

    return undefined;
}


function BO_GetChestFilterIndex(_container)
{
    var _bo = ModInstance.Get("BO");

    if(_bo == undefined)
        return -1;

    for(var i = 0; i < array_length(_bo.chest_filters); i++)
    {
        if(_bo.chest_filters[i].container == _container)
            return i;
    }

    return -1;
}


function BO_ToggleChestFilter(_container, _button_index)
{
    var _bo = ModInstance.Get("BO");

    if(_bo == undefined || !Container.Exists(_container))
        return;

    BO_EnsureChestFilterLoaded(_container);

    var _index = BO_GetChestFilterIndex(_container);

    if(_index < 0)
    {
        array_push(
            _bo.chest_filters,
            {
                container: _container,
                existing_only: false,
                category_mask: 0
            }
        );

        _index = array_length(_bo.chest_filters) - 1;
    }

    var _filter = _bo.chest_filters[_index];

    if(_button_index == 0)
    {
        _filter.existing_only = !_filter.existing_only;
    }
    else
    {
        var _bit = BO_FilterBit(_button_index);

        if((_filter.category_mask & _bit) != 0)
            _filter.category_mask -= _bit;
        else
            _filter.category_mask += _bit;
    }

    _bo.chest_filters[_index] = _filter;
    BO_SaveChestFilter(_container, _filter);

    if(!_filter.existing_only && _filter.category_mask == 0)
        array_delete(_bo.chest_filters, _index, 1);
}


function BO_FilterAllowsItem(_container, _item)
{
    var _filter = BO_GetChestFilter(_container);

    if(is_undefined(_filter))
        return false;

    if(
        variable_struct_exists(_filter, "existing_only")
        && _filter.existing_only
    )
    {
        var _contains = BO_GetCallable("container_contains_item");
        var _item_id = BO_ItemID(_item);

        if(
            is_undefined(_contains)
            || is_undefined(_item_id)
            || !BO_Call2(_contains, _item_id, _container)
        )
        {
            return false;
        }
    }

    if(_filter.category_mask != 0)
    {
        var _category = BO_ItemCategoryBit(_item);

        if((_filter.category_mask & _category) == 0)
            return false;
    }

    return true;
}


function BO_ItemCategoryBit(_item)
{
    if(
        !is_numeric(_item)
        || !ds_exists(_item, ds_type_map)
    )
    {
        return 0;
    }

    var _type = ds_map_exists(_item, 7) ? string(_item[? 7]) : "";
    var _subtype = ds_map_exists(_item, 8) ? string(_item[? 8]) : "";
    var _id_str = ds_map_exists(_item, 0) ? string_lower(string(_item[? 0])) : "";
    var _name_str = ds_map_exists(_item, 1) ? string_lower(string(_item[? 1])) : "";
    var _desc_str = ds_map_exists(_item, 2) ? string_lower(string(_item[? 2])) : "";
    var _combined = _id_str + " " + _name_str + " " + string_lower(_type) + " " + string_lower(_subtype) + " " + _desc_str;

    // 1. Prioridade Absoluta por Tipo/Subtipo: Equipamentos, Acessórios, Mascotes e Armas
    // (Garante que "Material > Acessório" ou Mascotes sejam categorizados como Equipamento e não como Minério)
    var _type_lower = string_lower(_type);
    var _subtype_lower = string_lower(_subtype);

    if(
        _type_lower == "weapon" || _subtype_lower == "weapon"
        || _type_lower == "tool" || _subtype_lower == "tool"
        || _type_lower == "accesory" || _subtype_lower == "accesory"
        || _type_lower == "accessory" || _subtype_lower == "accessory"
        || _type_lower == "head" || _subtype_lower == "head"
        || _type_lower == "body" || _subtype_lower == "body"
        || _type_lower == "legs" || _subtype_lower == "legs"
        || _type_lower == "hook" || _subtype_lower == "hook"
        || _type_lower == "fishing rod" || _subtype_lower == "fishing rod"
        || _type_lower == "pet" || _subtype_lower == "pet"
        || _type_lower == "mount" || _subtype_lower == "mount"
    )
    {
        return 8; // Equipamentos / Acessórios / Mascotes
    }

    // 2. Outros Tipos Nativos Explícitos
    if(_type_lower == "usable" || _subtype_lower == "usable")
    {
        return 4; // Poções / Consumíveis
    }

    if(_type_lower == "ammo" || _subtype_lower == "ammo" || _type_lower == "throwable" || _subtype_lower == "throwable")
    {
        return 16; // Munições / Arremessáveis
    }

    // 3. Currency / Coins / Money (Bit 32 - Botão da Moeda de Ouro)
    // Puxa estritamente moedas e dinheiro
    if(
        _type_lower == "currency" || _subtype_lower == "currency"
        || string_pos("coin", _combined) > 0
        || string_pos("moeda", _combined) > 0
        || string_pos("money", _combined) > 0
        || string_pos("dinheiro", _combined) > 0
        || string_pos("gold_coin", _id_str) > 0
        || string_pos("silver_coin", _id_str) > 0
        || string_pos("copper_coin", _id_str) > 0
        || string_pos("platinum_coin", _id_str) > 0
        || string_pos("dobloon", _id_str) > 0
    )
    {
        return 32; // Moedas / Dinheiro
    }

    // 4. Equipment / Weapons / Tools / Accessories / Pets / Mounts (Bit 8 - Botão do Escudo)
    // Palavras-chave prioritárias: Acessórios e Mascotes têm precedência sobre materiais
    if(
        string_pos("accesory", _combined) > 0
        || string_pos("accessory", _combined) > 0
        || string_pos("acessorio", _combined) > 0
        || string_pos("pet", _combined) > 0
        || string_pos("mascote", _combined) > 0
        || string_pos("mount", _combined) > 0
        || string_pos("montaria", _combined) > 0
        || string_pos("trinket", _combined) > 0
        || string_pos("necklace", _combined) > 0
        || string_pos("colar", _combined) > 0
        || string_pos("ring", _combined) > 0
        || string_pos("anel", _combined) > 0
        || string_pos("amulet", _combined) > 0
        || string_pos("amuleto", _combined) > 0
        || string_pos("pin", _combined) > 0
        || string_pos("bracelet", _combined) > 0
        || string_pos("cufflinks", _combined) > 0
        || string_pos("sword", _combined) > 0
        || string_pos("espada", _combined) > 0
        || string_pos("pickaxe", _combined) > 0
        || string_pos("picareta", _combined) > 0
        || string_pos("axe", _combined) > 0
        || string_pos("machado", _combined) > 0
        || string_pos("hammer", _combined) > 0
        || string_pos("martelo", _combined) > 0
        || string_pos("shovel", _combined) > 0
        || string_pos("pa", _combined) > 0
        || string_pos("bow", _combined) > 0
        || string_pos("arco", _combined) > 0
        || string_pos("staff", _combined) > 0
        || string_pos("cajado", _combined) > 0
        || string_pos("wand", _combined) > 0
        || string_pos("varinha", _combined) > 0
        || string_pos("shield", _combined) > 0
        || string_pos("escudo", _combined) > 0
        || string_pos("helmet", _combined) > 0
        || string_pos("capacete", _combined) > 0
        || string_pos("armor", _combined) > 0
        || string_pos("armadura", _combined) > 0
        || string_pos("boots", _combined) > 0
        || string_pos("bota", _combined) > 0
        || string_pos("pants", _combined) > 0
        || string_pos("calca", _combined) > 0
        || string_pos("compass", _combined) > 0
        || string_pos("bussola", _combined) > 0
        || string_pos("sonar", _combined) > 0
        || string_pos("saddle", _combined) > 0
        || string_pos("sela", _combined) > 0
        || string_pos("pouch", _combined) > 0
        || string_pos("bolsa", _combined) > 0
        || string_pos("fishing", _combined) > 0
        || string_pos("pesca", _combined) > 0
        || string_pos("goggles", _combined) > 0
        || string_pos("scarf", _combined) > 0
        || string_pos("monocle", _combined) > 0
        || string_pos("talisman", _combined) > 0
        || string_pos("rosary", _combined) > 0
    )
    {
        return 8;
    }

    // 5. Consumables / Potions / Food / Drinks / Flasks (Bit 4 - Botão da Poção)
    if(
        string_pos("potion", _combined) > 0
        || string_pos("pocao", _combined) > 0
        || string_pos("flask", _combined) > 0
        || string_pos("frasco", _combined) > 0
        || string_pos("bottle", _combined) > 0
        || string_pos("garrafa", _combined) > 0
        || string_pos("food", _combined) > 0
        || string_pos("comida", _combined) > 0
        || string_pos("stew", _combined) > 0
        || string_pos("ensopado", _combined) > 0
        || string_pos("soup", _combined) > 0
        || string_pos("sopa", _combined) > 0
        || string_pos("bread", _combined) > 0
        || string_pos("pao", _combined) > 0
        || string_pos("pie", _combined) > 0
        || string_pos("torta", _combined) > 0
        || string_pos("berry", _combined) > 0
        || string_pos("baga", _combined) > 0
        || string_pos("fruit", _combined) > 0
        || string_pos("fruta", _combined) > 0
        || string_pos("drink", _combined) > 0
        || string_pos("bebida", _combined) > 0
        || string_pos("tea", _combined) > 0
        || string_pos("cha", _combined) > 0
    )
    {
        return 4;
    }

    // 6. Ammo / Throwables (Bit 16 - Botão da Flecha)
    if(
        string_pos("arrow", _combined) > 0
        || string_pos("flecha", _combined) > 0
        || string_pos("bullet", _combined) > 0
        || string_pos("bala", _combined) > 0
        || string_pos("dart", _combined) > 0
        || string_pos("dardo", _combined) > 0
        || string_pos("bomb", _combined) > 0
        || string_pos("bomba", _combined) > 0
        || string_pos("dynamite", _combined) > 0
        || string_pos("dinamite", _combined) > 0
        || string_pos("shuriken", _combined) > 0
        || string_pos("grenade", _combined) > 0
        || string_pos("granada", _combined) > 0
    )
    {
        return 16;
    }

    // 7. Building / Furniture / Construction (Bit 2 - Botão da Parede de Pedra)
    if(
        string_pos("wall", _combined) > 0
        || string_pos("parede", _combined) > 0
        || string_pos("floor", _combined) > 0
        || string_pos("chao", _combined) > 0
        || string_pos("piso", _combined) > 0
        || string_pos("door", _combined) > 0
        || string_pos("porta", _combined) > 0
        || string_pos("chest", _combined) > 0
        || string_pos("bau", _combined) > 0
        || string_pos("table", _combined) > 0
        || string_pos("mesa", _combined) > 0
        || string_pos("chair", _combined) > 0
        || string_pos("cadeira", _combined) > 0
        || string_pos("torch", _combined) > 0
        || string_pos("tocha", _combined) > 0
        || string_pos("furnace", _combined) > 0
        || string_pos("fornalha", _combined) > 0
        || string_pos("anvil", _combined) > 0
        || string_pos("bigorna", _combined) > 0
        || string_pos("platform", _combined) > 0
        || string_pos("plataforma", _combined) > 0
        || string_pos("cable", _combined) > 0
        || string_pos("cabo", _combined) > 0
        || string_pos("wire", _combined) > 0
        || string_pos("fio", _combined) > 0
        || string_pos("brick", _combined) > 0
        || string_pos("tijolo", _combined) > 0
        || string_pos("bed", _combined) > 0
        || string_pos("cama", _combined) > 0
    )
    {
        return 2;
    }

    // 8. True Raw Resources / Materials (Bit 1 - Botão da Madeira)
    // Se o tipo primário for Material ou contiver palavras-chave de recurso
    if(
        _type_lower == "material" || _subtype_lower == "material"
        || string_pos("wood", _combined) > 0
        || string_pos("madeira", _combined) > 0
        || string_pos("log", _combined) > 0
        || string_pos("tora", _combined) > 0
        || string_pos("ore", _combined) > 0
        || string_pos("minerio", _combined) > 0
        || string_pos("stone", _combined) > 0
        || string_pos("pedra", _combined) > 0
        || string_pos("rock", _combined) > 0
        || string_pos("rocha", _combined) > 0
        || string_pos("ingot", _combined) > 0
        || string_pos("lingote", _combined) > 0
        || string_pos("bar", _combined) > 0
        || string_pos("barra", _combined) > 0
        || string_pos("fiber", _combined) > 0
        || string_pos("fibra", _combined) > 0
        || string_pos("crystal", _combined) > 0
        || string_pos("cristal", _combined) > 0
        || string_pos("obsidian", _combined) > 0
        || string_pos("obsidiana", _combined) > 0
        || string_pos("coal", _combined) > 0
        || string_pos("carvao", _combined) > 0
        || string_pos("slime", _combined) > 0
        || string_pos("leather", _combined) > 0
        || string_pos("couro", _combined) > 0
        || string_pos("bone", _combined) > 0
        || string_pos("osso", _combined) > 0
        || string_pos("feather", _combined) > 0
        || string_pos("pena", _combined) > 0
        || string_pos("silk", _combined) > 0
        || string_pos("seda", _combined) > 0
        || string_pos("leaf", _combined) > 0
        || string_pos("folha", _combined) > 0
        || string_pos("leaves", _combined) > 0
        || string_pos("herb", _combined) > 0
        || string_pos("erva", _combined) > 0
        || string_pos("shroom", _combined) > 0
        || string_pos("cogumelo", _combined) > 0
        || string_pos("mushroom", _combined) > 0
        || string_pos("seed", _combined) > 0
        || string_pos("semente", _combined) > 0
        || string_pos("gem", _combined) > 0
        || string_pos("gema", _combined) > 0
        || string_pos("amethyst", _combined) > 0
        || string_pos("ametista", _combined) > 0
        || string_pos("ruby", _combined) > 0
        || string_pos("rubi", _combined) > 0
        || string_pos("sapphire", _combined) > 0
        || string_pos("safira", _combined) > 0
        || string_pos("diamond", _combined) > 0
        || string_pos("diamante", _combined) > 0
        || string_pos("emerald", _combined) > 0
        || string_pos("esmeralda", _combined) > 0
        || string_pos("amber", _combined) > 0
        || string_pos("ambar", _combined) > 0
        || string_pos("clay", _combined) > 0
        || string_pos("argila", _combined) > 0
        || string_pos("sand", _combined) > 0
        || string_pos("areia", _combined) > 0
        || string_pos("dirt", _combined) > 0
        || string_pos("terra", _combined) > 0
        || string_pos("resin", _combined) > 0
        || string_pos("resina", _combined) > 0
        || string_pos("chitin", _combined) > 0
        || string_pos("quitina", _combined) > 0
        || string_pos("scale", _combined) > 0
        || string_pos("escama", _combined) > 0
        || string_pos("hide", _combined) > 0
        || string_pos("pele", _combined) > 0
        || string_pos("meat", _combined) > 0
        || string_pos("carne", _combined) > 0
        || string_pos("powder", _combined) > 0
        || string_pos("po", _combined) > 0
        || string_pos("scrap", _combined) > 0
        || string_pos("sucata", _combined) > 0
        || string_pos("copper", _combined) > 0
        || string_pos("cobre", _combined) > 0
        || string_pos("iron", _combined) > 0
        || string_pos("ferro", _combined) > 0
        || string_pos("gold", _combined) > 0
        || string_pos("ouro", _combined) > 0
        || string_pos("silver", _combined) > 0
        || string_pos("prata", _combined) > 0
        || string_pos("titanium", _combined) > 0
        || string_pos("titanio", _combined) > 0
        || string_pos("branch", _combined) > 0
        || string_pos("galho", _combined) > 0
        || string_pos("twig", _combined) > 0
        || string_pos("petal", _combined) > 0
        || string_pos("petala", _combined) > 0
        || string_pos("pollen", _combined) > 0
        || string_pos("polen", _combined) > 0
    )
    {
        return 1; // Recursos / Materiais
    }

    // 9. Miscelânea restante (Pergaminhos, Chaves, Mapas, Etc genérico)
    if(
        string_pos("key", _combined) > 0
        || string_pos("chave", _combined) > 0
        || string_pos("ticket", _combined) > 0
        || string_pos("scroll", _combined) > 0
        || string_pos("pergaminho", _combined) > 0
        || string_pos("recipe", _combined) > 0
        || string_pos("receita", _combined) > 0
        || string_pos("blueprint", _combined) > 0
        || string_pos("map", _combined) > 0
        || string_pos("mapa", _combined) > 0
        || string_pos("token", _combined) > 0
        || string_pos("relic", _combined) > 0
        || string_pos("reliquia", _combined) > 0
        || string_pos("trophy", _combined) > 0
        || string_pos("badge", _combined) > 0
        || string_pos("document", _combined) > 0
        || string_pos("letter", _combined) > 0
        || string_pos("wallet", _combined) > 0
    )
    {
        return 32;
    }

    // Default para itens sem categoria específica: retorna 1 se parecer material, ou 0 para não puxar aleatoriamente
    return 0;
}


function BO_ItemID(_item)
{
    if(
        is_numeric(_item)
        && ds_exists(_item, ds_type_map)
        && ds_map_exists(_item, 0)
    )
    {
        return _item[? 0];
    }

    return undefined;
}


function BO_ItemIsMovable(_item, _container = undefined, _slot_x = undefined, _slot_y = undefined)
{
    if(!is_numeric(_item) || !ds_exists(_item, ds_type_map))
        return false;

    if(!ds_map_exists(_item, 6) || !is_numeric(_item[? 6]) || _item[? 6] < 1)
        return false;

    // 1. Check direct keys on item ds_map
    if(ds_map_exists(_item, "locked") && (_item[? "locked"] == 1 || _item[? "locked"] == true || _item[? "locked"] == "1"))
        return false;

    if(ds_map_exists(_item, "is_locked") && (_item[? "is_locked"] == 1 || _item[? "is_locked"] == true || _item[? "is_locked"] == "1"))
        return false;

    if(ds_map_exists(_item, "IsLocked") && (_item[? "IsLocked"] == 1 || _item[? "IsLocked"] == true || _item[? "IsLocked"] == "1"))
        return false;

    if(ds_map_exists(_item, "favorite") && (_item[? "favorite"] == 1 || _item[? "favorite"] == true || _item[? "favorite"] == "1"))
        return false;

    if(ds_map_exists(_item, "favoriteItem") && (_item[? "favoriteItem"] == 1 || _item[? "favoriteItem"] == true || _item[? "favoriteItem"] == "1"))
        return false;

    if(ds_map_exists(_item, "is_favorite") && (_item[? "is_favorite"] == 1 || _item[? "is_favorite"] == true || _item[? "is_favorite"] == "1"))
        return false;

    if(ds_map_exists(_item, "favorite_item") && (_item[? "favorite_item"] == 1 || _item[? "favorite_item"] == true || _item[? "favorite_item"] == "1"))
        return false;

    // 2. Iterate all keys in item ds_map for lock / fav markers
    var _k = ds_map_find_first(_item);
    while(!is_undefined(_k))
    {
        var _k_str = string_lower(string(_k));

        if(
            _k_str == "locked"
            || _k_str == "is_locked"
            || _k_str == "islocked"
            || _k_str == "favorite"
            || _k_str == "is_favorite"
            || _k_str == "favoriteitem"
            || _k_str == "favorite_item"
            || _k_str == "padlock"
            || _k_str == "pinned"
        )
        {
            var _v = _item[? _k];
            if(_v == 1 || _v == true || _v == "1" || _v == "true")
                return false;
        }

        _k = ds_map_find_next(_item, _k);
    }

    // 3. Check container / slot locked state if slot coordinates are provided
    if(!is_undefined(_container) && !is_undefined(_slot_x) && !is_undefined(_slot_y))
    {
        // Engine native functions check
        var _fn_slot_locked = BO_GetCallable("container_slot_is_locked");
        if(!is_undefined(_fn_slot_locked))
        {
            if(script_execute_ext(_fn_slot_locked, [_container, _slot_x, _slot_y]))
                return false;
        }

        var _fn_item_locked = BO_GetCallable("container_item_is_locked");
        if(!is_undefined(_fn_item_locked))
        {
            if(script_execute_ext(_fn_item_locked, [_container, _slot_x, _slot_y]))
                return false;
        }

        var _fn_is_fav = BO_GetCallable("container_slot_is_favorite");
        if(!is_undefined(_fn_is_fav))
        {
            if(script_execute_ext(_fn_is_fav, [_container, _slot_x, _slot_y]))
                return false;
        }

        // If container ds_map holds slot locked grid / map
        if(is_numeric(_container) && ds_exists(_container, ds_type_map))
        {
            if(ds_map_exists(_container, "locked"))
            {
                var _lgrid = _container[? "locked"];
                if(is_numeric(_lgrid) && ds_exists(_lgrid, ds_type_grid))
                {
                    if(ds_grid_get(_lgrid, _slot_x, _slot_y) != 0)
                        return false;
                }
            }

            if(ds_map_exists(_container, "favorites"))
            {
                var _fgrid = _container[? "favorites"];
                if(is_numeric(_fgrid) && ds_exists(_fgrid, ds_type_grid))
                {
                    if(ds_grid_get(_fgrid, _slot_x, _slot_y) != 0)
                        return false;
                }
            }
        }
    }

    // 4. Check player or GUI controller locked slots arrays/grids
    if(instance_exists(objGUIIngameController))
    {
        with(objGUIIngameController)
        {
            if(variable_instance_exists(id, "lockedSlots") && !is_undefined(_slot_x) && !is_undefined(_slot_y))
            {
                var _ls = variable_instance_get(id, "lockedSlots");
                if(is_array(_ls) && _slot_y < array_length(_ls))
                {
                    var _row = _ls[_slot_y];
                    if(is_array(_row) && _slot_x < array_length(_row) && (_row[_slot_x] == 1 || _row[_slot_x] == true))
                        return false;
                }
            }

            if(variable_instance_exists(id, "favoriteSlots") && !is_undefined(_slot_x) && !is_undefined(_slot_y))
            {
                var _fs = variable_instance_get(id, "favoriteSlots");
                if(is_array(_fs) && _slot_y < array_length(_fs))
                {
                    var _frow = _fs[_slot_y];
                    if(is_array(_frow) && _slot_x < array_length(_frow) && (_frow[_slot_x] == 1 || _frow[_slot_x] == true))
                        return false;
                }
            }
        }
    }

    return true;
}


function BO_GetCallable(_name)
{
    if(!variable_global_exists(_name))
        return undefined;

    var _callable = variable_global_get(_name);

    return is_callable(_callable) ? _callable : undefined;
}


function BO_Call1(_callable, _a)
{
    if(is_method(_callable))
        return method_call(_callable, [_a]);

    return script_execute_ext(_callable, [_a]);
}


function BO_Call2(_callable, _a, _b)
{
    if(is_method(_callable))
        return method_call(_callable, [_a, _b]);

    return script_execute_ext(_callable, [_a, _b]);
}


function BO_Call3(_callable, _a, _b, _c)
{
    if(is_method(_callable))
        return method_call(_callable, [_a, _b, _c]);

    return script_execute_ext(_callable, [_a, _b, _c]);
}


function BO_Call4(_callable, _a, _b, _c, _d)
{
    if(is_method(_callable))
        return method_call(_callable, [_a, _b, _c, _d]);

    return script_execute_ext(_callable, [_a, _b, _c, _d]);
}


// ============================================================================
// NATIVE NEARBY CONTAINERS
// ============================================================================

function BO_GetNearbyContainersByDistance()
{
    var _max_distance = 300;
    var _containers = BO_GetNearbyContainers();
    var _entries = [];

    for(var i = 0; i < array_length(_containers); i++)
    {
        array_push(
            _entries,
            {
                container: _containers[i],
                distance: 1000000000 + i
            }
        );
    }

    if(
        instance_exists(objPlayer)
        && !is_undefined(MY_PLAYER)
        && instance_exists(objInteractableChest)
    )
    {
        var _count = instance_number(objInteractableChest);

        for(var c = 0; c < _count; c++)
        {
            var _chest = instance_find(objInteractableChest, c);

            if(
                _chest != undefined
                && instance_exists(_chest)
                && variable_instance_exists(_chest, "container")
            )
            {
                var _chest_container = variable_instance_get(_chest, "container");

                for(var e = 0; e < array_length(_entries); e++)
                {
                    if(_entries[e].container == _chest_container)
                    {
                        _entries[e].distance = point_distance(
                            MY_PLAYER.x,
                            MY_PLAYER.y,
                            _chest.x,
                            _chest.y
                        );
                        break;
                    }
                }
            }
        }
    }

    for(var left = 0; left < array_length(_entries) - 1; left++)
    {
        var _best = left;

        for(var right = left + 1; right < array_length(_entries); right++)
        {
            if(_entries[right].distance < _entries[_best].distance)
                _best = right;
        }

        if(_best != left)
        {
            var _swap = _entries[left];
            _entries[left] = _entries[_best];
            _entries[_best] = _swap;
        }
    }

    var _sorted = [];

    for(var s = 0; s < array_length(_entries); s++)
    {
        if(_entries[s].distance <= _max_distance)
        {
            array_push(_sorted, _entries[s].container);
        }
        else
        {
            BO_LogImmediate(
                "[BO][NEARBY-EXCLUDED] container="
                + string(_entries[s].container)
                + " reason=distance distance_px="
                + string(_entries[s].distance)
                + " max_px="
                + string(_max_distance)
            );
        }
    }

    return _sorted;
}


function BO_GetNearbyContainers()
{
    if(!variable_global_exists("get_nearby_chest_containers"))
        return [];

    var _get_nearby = variable_global_get("get_nearby_chest_containers");

    if(!is_callable(_get_nearby))
        return [];

    var _result;

    if(is_method(_get_nearby))
        _result = method_call(_get_nearby, []);
    else
        _result = script_execute(_get_nearby);

    if(is_array(_result))
        return _result;

    if(is_numeric(_result) && ds_exists(_result, ds_type_list))
    {
        var _array = [];

        for(var i = 0; i < ds_list_size(_result); i++)
            array_push(_array, _result[| i]);

        return _array;
    }

    return [];
}


// ============================================================================
// IMMEDIATE LOGGING
// ============================================================================

function BO_LogImmediate(_line)
{
    var _file = file_text_open_append("BO.log");

    if(_file < 0)
        return;

    file_text_write_string(_file, string(_line));
    file_text_writeln(_file);
    file_text_close(_file);
}


function BO_FilterTrace(_container)
{
    var _filter = BO_GetChestFilter(_container);

    if(is_undefined(_filter))
        return "none";

    return "existing_only="
        + string(_filter.existing_only)
        + " mask="
        + string(_filter.category_mask);
}


function BO_ContainerPhysicalTrace(_container)
{
    if(instance_exists(objInteractableChest))
    {
        var _count = instance_number(objInteractableChest);

        for(var i = 0; i < _count; i++)
        {
            var _chest = instance_find(objInteractableChest, i);

            if(
                _chest != undefined
                && instance_exists(_chest)
                && variable_instance_exists(_chest, "container")
                && variable_instance_get(_chest, "container") == _container
            )
            {
                var _distance = -1;

                if(instance_exists(objPlayer) && !is_undefined(MY_PLAYER))
                {
                    _distance = point_distance(
                        MY_PLAYER.x,
                        MY_PLAYER.y,
                        _chest.x,
                        _chest.y
                    );
                }

                return "physical_instance="
                    + string(_chest)
                    + " pos=("
                    + string(_chest.x)
                    + ","
                    + string(_chest.y)
                    + ") distance="
                    + string(_distance);
            }
        }
    }

    return "physical=none";
}
