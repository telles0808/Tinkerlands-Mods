/*
    ========================================================================
    TINKERLANDS - Fog
    Author: Telles0808
    ID: 5001

    Minimap fog translucency layer (95% visibility across explored areas).
    ========================================================================
*/

OnWorldGenerationStart(function()
{
    FogAlpha_Install();
});

OnWorldGenerationEnd(function()
{
    FogAlpha_Install();
});

function FogAlpha_Install()
{
    if(!is_struct(MINIMAP))
        return;

    if(variable_struct_exists(MINIMAP, "__fog95_original"))
        return;

    if(!variable_struct_exists(MINIMAP, "render_surface"))
        return;

    var _original =
        variable_struct_get(
            MINIMAP,
            "render_surface"
        );

    if(!is_callable(_original))
        return;

    variable_struct_set(
        MINIMAP,
        "__fog95_original",
        _original
    );

    variable_struct_set(
        MINIMAP,
        "render_surface",
        function()
        {
            var _args =
                array_create(argument_count);

            for(var i = 0; i < argument_count; i++)
                _args[i] = argument[i];

            var _original =
                variable_struct_get(
                    MINIMAP,
                    "__fog95_original"
                );

            var _result;

            if(is_method(_original))
            {
                _result =
                    method_call(
                        _original,
                        _args
                    );
            }
            else
            {
                _result =
                    script_execute_ext(
                        _original,
                        _args
                    );
            }

            if(
                variable_struct_exists(MINIMAP, "surface")
                && variable_struct_exists(MINIMAP, "surfaceWorld")
                && variable_struct_exists(MINIMAP, "surfaceExplored")
            )
            {
                var _surface =
                    MINIMAP.surface;

                var _world =
                    MINIMAP.surfaceWorld;

                var _fog =
                    MINIMAP.surfaceExplored;

                if(
                    surface_exists(_surface)
                    && surface_exists(_world)
                    && surface_exists(_fog)
                )
                {
                    surface_set_target(_surface);

                    draw_clear_alpha(
                        c_black,
                        0
                    );

                    draw_surface_ext(
                        _world,
                        0,
                        0,
                        1,
                        1,
                        0,
                        c_white,
                        1
                    );

                    draw_surface_ext(
                        _fog,
                        0,
                        0,
                        1,
                        1,
                        0,
                        c_white,
                        0.95
                    );

                    surface_reset_target();
                }
            }

            return _result;
        }
    );
}
