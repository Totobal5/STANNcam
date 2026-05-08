/// @ignore
/// @param {String} message
function __stanncam_error(_msg)
{
    if (STANNCAM_ERROR) { show_debug_message("Stanncam::Error - " + string(_msg)); }
    if (STANNCAM_STRICT)
    {
        show_error("Stanncam::Fatal Error - " + string(_msg), true);
    }
}

/// @ignore
/// @param {String} message
function __stanncam_alert(_msg)
{
    if (STANNCAM_ALERT) { show_debug_message("Stanncam::Alert - " + string(_msg)); }
}

/// @ignore Singleton pattern for storing config values and references to cameras/manager
function StanncamConfig()
{
	static Config = {
		stanncams: [],
		number_of_stanncams: 0,
		
		manager: noone,
		draw_zones: false,
		
		game_w: 0,
		game_h: 0,
		
		gui_w: 0,
		__gui_res_w: 0,
		
		gui_h: 0,
		__gui_res_h: 0,
		
		display_res_w: 0,
		display_res_h: 0,
		
		res_w: 0,
		res_h: 0,
		
		window_mode: STANNCAM_WINDOW_MODE.WINDOWED,
		/// @ignore
		__switching_window_mode: false,
		/// @ignore
		__resize_width: 0,
		/// @ignore
		__resize_height: 0,
		
		keep_aspect_ratio: true,
		gui_keep_aspect_ratio: true,
		
		/// @ignore
		__display_scale_x: 1,
		/// @ignore
		__display_scale_y: 1,
		
		/// @ignore
		__gui_x_scale: 1,
		/// @ignore
		__gui_y_scale: 1,
		
		/// @ignore Check for the manager instance every frame and restart it if it doesn't exist, to prevent issues with it being deactivated or destroyed
		__time_source: time_source_create(time_source_global, 1, time_source_units_frames, function() {
			if (!instance_exists(__obj_stanncam_manager) ) 
			{
				instance_activate_object(__obj_stanncam_manager);
				if (instance_exists(__obj_stanncam_manager) )
				{
					__stanncam_error("__obj_stanncam_manager has been deactivated.\nMake sure that it is never deactivated.\nConsider using instance_activate_object(__obj_stanncam_manager)\nin the same step you deactivate other stuff.")
				}
			}
		}, [], -1),
		
		/// @description gets the scaled width of the display resolution
		/// @returns {Real}
		GetScaledW: function() { return (game_w * __display_scale_x); },
		
		/// @description gets the scaled height of the display resolution
		/// @returns {Real}
		GetScaledH: function() { return (game_h * __display_scale_y); },
		
		/// @description adds a stanncam to the stanncam array and returns it, returns -1 if there are already 8 stanncams in the room
		/// @param {Stanncam} _stanncam
		/// @returns {Stanncam|Real}
		Add: function(_stanncam)
		{
			if (array_length(stanncams) >= 8)
			{
				__stanncam_error($"Maximum number of stanncams (8) has been reached. Current count: {array_length(stanncams)}");
				return -1;
			}

			if (_stanncam == noone || _stanncam == undefined)
			{
				__stanncam_error("Add() received invalid stanncam reference (undefined/noone)");
				return -1;
			}

			array_push(stanncams, _stanncam);
			number_of_stanncams = array_length(stanncams);

			__stanncam_alert($"Added Stanncam (Total cameras: {number_of_stanncams})");
			return _stanncam;
		},
	};

	return Config;
}

/// @description set game dimensions, display resolution, and gui dimensions, it's the same as game scale by default
/// @param {Real} game_w
/// @param {Real} game_h
/// @param {Real} [resolution_w=_game_w]
/// @param {Real} [resolution_h=_game_h]
/// @param {Real} [gui_w=_game_w]
/// @param {Real} [gui_h=_game_h]
/// @param {Real} [window_mode=STANNCAM_WINDOW_MODE.WINDOWED]
function stanncam_init(_game_w, _game_h, _resolution_w=_game_w, _resolution_h=_game_h, _gui_w=_game_w, _gui_h=_game_h, _window_mode=STANNCAM_WINDOW_MODE.WINDOWED)
{
	with (StanncamConfig() )
	{
		// Re-initialize the manager every time stanncam_init is called, to ensure it exists and is running the correct configuration.
		if (manager == noone || !instance_exists(manager)) 
		{
			manager = instance_create_depth(0, 0, 0, __obj_stanncam_manager); 
			__stanncam_alert("stanncam_init: Created new __obj_stanncam_manager instance.");
		}

		// If STANNcam is re-initialized across rooms, purge previous camera structs before creating new ones.
		array_foreach(stanncams, function(_stanncam) {
			if (_stanncam != -1 && _stanncam != noone)
			{ 
				if (is_instanceof(_stanncam, Stanncam) && !_stanncam.is_destroyed() ) _stanncam.destroy(); 
			}
		});

		stanncams = [];
		number_of_stanncams = 0;
		
		game_w = _game_w;
		game_h = _game_h;
		
		gui_w = _gui_w;
		gui_h = _gui_h;
		__gui_res_w = _gui_w;
		__gui_res_h = _gui_h;
		
		display_res_w = _resolution_w;
		display_res_h = _resolution_h;
		res_w = _resolution_w;
		res_h = _resolution_h;
		__resize_width = window_get_width();
		__resize_height = window_get_height();
		window_mode = _window_mode;
		
		var i=0; repeat (array_length(view_camera) ) { camera_destroy(view_camera[i++]); }
		application_surface_draw_enable(false);
		
		stanncam_set_resolution(_resolution_w, _resolution_h);
		stanncam_set_window_mode(_window_mode);
		
		if (time_source_get_state(__time_source) == time_source_state_initial) 
		{ 
			time_source_start(__time_source); 
			__stanncam_alert("stanncam_init: Time source start");
		}
	}

	__stanncam_alert("STANNcam initialized successfully");
}

/// @ignore
/// @description resets runtime state for cameras/manager/config; used by destroy and tests
/// @param {Bool} [_restore_app_surface_draw=true]
function __stanncam_runtime_reset(_restore_app_surface_draw=true)
{
	var _config = StanncamConfig();

	if (_restore_app_surface_draw) { application_surface_draw_enable(true); }
	
	array_foreach(_config.stanncams, function(_stanncam) {
		if (_stanncam != -1 && _stanncam != noone)
		{
			if (is_instanceof(_stanncam, Stanncam) && !_stanncam.is_destroyed())
			{
				_stanncam.destroy();
			}
		}
	});

	if (instance_exists(__obj_stanncam_manager))
	{
		instance_destroy(__obj_stanncam_manager);
	}

	var i = 0; repeat (array_length(view_camera) )
	{
		view_camera[i] = -1;
		view_visible[i] = false;
		i++;
	}

	_config.stanncams = [];
	_config.number_of_stanncams = 0;
	_config.manager = noone;
	_config.draw_zones = false;
	_config.__switching_window_mode = false;
}

/// @description removes all stanncam references from the game, the opposite of stanncam_init
/// @param {Bool} [application_surface_draw_enable=true]
function stanncam_destroy(_application_surface_draw_enable=true)
{
	var _config = StanncamConfig();
	__stanncam_runtime_reset(_application_surface_draw_enable);
	time_source_destroy(_config.__time_source, true);
}

/// @description updates the camera resolution, has no visible effect when fullscreened
/// @param {Real} resolution_w
/// @param {Real} resolution_h
function stanncam_set_resolution(_resolution_w, _resolution_h)
{
	if (!is_real(_resolution_w) || !is_real(_resolution_h) || _resolution_w <= 0 || _resolution_h <= 0)
	{
		__stanncam_error($"stanncam_set_resolution received invalid size: ({_resolution_w}, {_resolution_h})");
		return;
	}

    with (StanncamConfig() )
    {
		display_res_w = _resolution_w;
		display_res_h = _resolution_h;
    }
    
	__stanncam_update_resolution();
}

/// @param {Real} window_mode
/// @description set game to be windowed/fullscreen/borderless
function stanncam_set_window_mode(_window_mode)
{
	static __k = function() { StanncamConfig().__switching_window_mode = false; __stanncam_update_resolution(); };
	var _is_valid_mode =
		(_window_mode == STANNCAM_WINDOW_MODE.WINDOWED) ||
		(_window_mode == STANNCAM_WINDOW_MODE.FULLSCREEN) ||
		(_window_mode == STANNCAM_WINDOW_MODE.BORDERLESS);

	if (!_is_valid_mode)
	{
		__stanncam_error($"stanncam_set_window_mode received invalid mode: {_window_mode}");
		return;
	}

	var _config = StanncamConfig();
	_config.window_mode = _window_mode;
	_config.__switching_window_mode = true;
    
	switch (_window_mode) 
    {
		case STANNCAM_WINDOW_MODE.WINDOWED:
			window_set_fullscreen(false);
			window_set_showborder(true);
			__stanncam_center(20, 20);
        break;
    
		case STANNCAM_WINDOW_MODE.FULLSCREEN:
			window_set_fullscreen(true);
			window_set_showborder(false);
        break;
    
		case STANNCAM_WINDOW_MODE.BORDERLESS:
			window_set_fullscreen(false);
			window_set_showborder(false);
        break;
	}
    
	call_later(8, time_source_units_frames, __k);
}

/// @description set windowed
function stanncam_set_windowed()
{
	stanncam_set_window_mode(STANNCAM_WINDOW_MODE.WINDOWED);
}

/// @description set fullscreen
function stanncam_set_fullscreen()
{
	stanncam_set_window_mode(STANNCAM_WINDOW_MODE.FULLSCREEN);
}

/// @description set borderless
function stanncam_set_borderless()
{
	stanncam_set_window_mode(STANNCAM_WINDOW_MODE.BORDERLESS);
}

/// @description set display keep_aspect_ratio
/// @param {Bool} on_off
function stanncam_set_keep_aspect_ratio(_on_off)
{
	var _config = StanncamConfig();
	_config.keep_aspect_ratio = _on_off;
	__stanncam_update_resolution();
}

/// @param {Bool} on_off
function stanncam_set_gui_keep_aspect_ratio(_on_off)
{
	var _config = StanncamConfig();
	_config.gui_keep_aspect_ratio = _on_off;
	__stanncam_update_resolution();
}

/// @description get whether the display has keep_aspect_ratio on
/// @returns {Bool}
function stanncam_get_keep_aspect_ratio()
{
	var _config = StanncamConfig();
	return _config.keep_aspect_ratio;
}

/// @description get whether the display has gui_keep_aspect_ratio on
/// @returns {Bool}
function stanncam_get_gui_keep_aspect_ratio()
{
	var _config = StanncamConfig();
	return _config.gui_keep_aspect_ratio;
}

/// @description if keep_aspect_ratio is on it offsets the x value so the render is in the middle
/// @returns {Real}
function stanncam_ratio_compensate_x()
{
	var _config = StanncamConfig();
	if (_config.keep_aspect_ratio)
    {
		return (window_get_width() - _config.GetScaledW()) / 2;
	}
    
	return 0;
}

/// @description if keep_aspect_ratio is on it offsets the y value so the render is in the middle
/// @returns {Real}
function stanncam_ratio_compensate_y()
{
	var _config = StanncamConfig();
	if (_config.keep_aspect_ratio)
    {
		return (window_get_height() - _config.GetScaledH()) / 2;
	}
    
	return 0;
}

/// @description set the gui resolution
/// @param {Real} gui_w
/// @param {Real} gui_h
function stanncam_set_gui_resolution(_gui_w, _gui_h)
{
	if (!is_real(_gui_w) || !is_real(_gui_h) || _gui_w <= 0 || _gui_h <= 0)
	{
		__stanncam_error($"stanncam_set_gui_resolution received invalid size: ({_gui_w}, {_gui_h})");
		return;
	}

    with (StanncamConfig() )
    {
		__gui_res_w = _gui_w;
		__gui_res_h = _gui_h;
    }
    
	__stanncam_update_resolution();
}

/// @function stanncam_get_gui_scale_x
/// @description gets how much bigger gui is from game
/// @returns {Real}
function stanncam_get_gui_scale_x()
{
    with (StanncamConfig() )
    {
        return (gui_w / game_w);
    }
}

/// @description gets how much bigger gui is from game
/// @returns {Real}
function stanncam_get_gui_scale_y()
{
    with (StanncamConfig() )
    {
        return (gui_h / game_h);
    }
}

/// @description gets how much bigger res is from game
/// @returns {Real}
function stanncam_get_res_scale_x()
{
    with (StanncamConfig() )
    {
        return (res_w / game_w);
    }
}

/// @description gets how much bigger res is from game
/// @returns {Real}
function stanncam_get_res_scale_y()
{
    with (StanncamConfig() )
    {
        return (res_h / game_h);
    }
}

/// @ignore
/// @description updates the camera resolution
function __stanncam_update_resolution()
{
	with (StanncamConfig() )
	{
		switch (window_mode)
		{
			// Fullscreen
			case STANNCAM_WINDOW_MODE.FULLSCREEN:
			// Borderless windowed
			case STANNCAM_WINDOW_MODE.BORDERLESS:
				if (keep_aspect_ratio)
				{
					var _ratio = game_w / game_h;
					res_w = display_get_height() * _ratio;
					res_h = display_get_height();
				}
				else
				{
					res_w = display_get_width();
					res_h = display_get_height();
				}

				window_set_size(display_get_width(), display_get_height());
				__stanncam_center();
			break;

			// Windowed
			case STANNCAM_WINDOW_MODE.WINDOWED:
				if (keep_aspect_ratio)
				{
					var _res_ratio = (display_res_w / display_res_h) / (game_w / game_h);
					var _game_ratio = game_w / game_h;
					if (_res_ratio >= 1)
					{
						res_w = display_res_h * _game_ratio;
						res_h = display_res_h;
					}
					else
					{
						res_w = display_res_w;
						res_h = display_res_w / _game_ratio;
					}
				}
				else
				{
					res_w = display_res_w;
					res_h = display_res_h;
				}

				window_set_size(display_res_w, display_res_h);
				__stanncam_center();
			break;
		}

		__gui_x_scale = res_w / __gui_res_w;
		__gui_y_scale = res_h / __gui_res_h;

		gui_w = __gui_res_w;
		gui_h = __gui_res_h;

		if (keep_aspect_ratio)
		{
			var _ratio_display = (res_w / res_h) / (game_w / game_h);
			if (_ratio_display > 1)
			{
				__display_scale_x = stanncam_get_res_scale_y();
				__display_scale_y = __display_scale_x;
			}
			else
			{
				__display_scale_x = stanncam_get_res_scale_x();
				__display_scale_y = __display_scale_x;
			}
		}
		else
		{
			__display_scale_x = stanncam_get_res_scale_x();
			__display_scale_y = stanncam_get_res_scale_y();

			if (gui_keep_aspect_ratio)
			{
				gui_w *= (__gui_x_scale / __gui_y_scale);
				__gui_x_scale = __gui_y_scale;
			}
		}

		display_set_gui_maximize(__gui_x_scale, __gui_y_scale, stanncam_ratio_compensate_x(), stanncam_ratio_compensate_y());
	}
}

/// @ignore
/// @description moves the window to the center of whichever window it's within
/// @param {Real} [x=0] x offset
/// @param {Real} [y=0] y offset
function __stanncam_center(_x=0, _y=0)
{
	var _wx = window_get_x();
	var _wy = window_get_y();
	var _ww = window_get_width();
	var _wh = window_get_height();
	var _display_data = window_get_visible_rects(_wx, _wy, _wx + _ww, _wy + _wh);
	var _display_num = floor(array_length(_display_data) / 8);
	if (_display_num <= 0) { return; }

	var _best_index = 0;
	var _best_overlap = -1;
	var _window_center_x = _wx + (_ww * 0.5);
	var _window_center_y = _wy + (_wh * 0.5);
	var _best_dist = infinity;

	for (var i = 0; i < _display_num; ++i)
    {
		var _base = i * 8;
		// window_get_visible_rects returns [overlap rect][display rect] for each monitor.
		var _ox1 = _display_data[_base + 0];
		var _oy1 = _display_data[_base + 1];
		var _ox2 = _display_data[_base + 2];
		var _oy2 = _display_data[_base + 3];

		var _dx1 = _display_data[_base + 4];
		var _dy1 = _display_data[_base + 5];
		var _dx2 = _display_data[_base + 6];
		var _dy2 = _display_data[_base + 7];

		var _overlap_w = max(0, _ox2 - _ox1);
		var _overlap_h = max(0, _oy2 - _oy1);
		var _overlap_area = _overlap_w * _overlap_h;

		if (_overlap_area > _best_overlap)
		{
			_best_overlap = _overlap_area;
			_best_index = i;
			var _display_center_x = (_dx1 + _dx2) * 0.5;
			var _display_center_y = (_dy1 + _dy2) * 0.5;
			_best_dist = point_distance(_window_center_x, _window_center_y, _display_center_x, _display_center_y);
		}
		else if (_overlap_area == _best_overlap)
		{
			// Tie-breaker: use nearest display center to current window center.
			var _center_x = (_dx1 + _dx2) * 0.5;
			var _center_y = (_dy1 + _dy2) * 0.5;
			var _dist = point_distance(_window_center_x, _window_center_y, _center_x, _center_y);
			if (_dist < _best_dist)
			{
				_best_dist = _dist;
				_best_index = i;
			}
		}
	}

	var _best_base = _best_index * 8;
	var _x1 = _display_data[_best_base + 4];
	var _y1 = _display_data[_best_base + 5];
	var _x2 = _display_data[_best_base + 6];
	var _y2 = _display_data[_best_base + 7];

	var _display_w = _x2 - _x1;
	var _display_h = _y2 - _y1;
	var _target_x = floor(_x1 + ((_display_w - _ww) * 0.5) + _x);
	var _target_y = floor(_y1 + ((_display_h - _wh) * 0.5) + _y);

	window_set_position(_target_x, _target_y);
}

/// @description gets a resolution preset
/// @param {Real} preset_index
/// @returns {Struct}
function stanncam_get_preset_resolution(_preset_index)
{
	if (!variable_global_exists("stanncam_res_presets"))
	{
		__stanncam_error("stanncam_res_presets is not defined");
		return undefined;
	}

	if (!is_real(_preset_index))
	{
		__stanncam_error($"stanncam_get_preset_resolution received invalid index: {_preset_index}");
		return undefined;
	}

	if (_preset_index < 0 || _preset_index >= array_length(global.stanncam_res_presets))
	{
		__stanncam_error($"stanncam_get_preset_resolution index out of range: {_preset_index}");
		return undefined;
	}

	return global.stanncam_res_presets[@ _preset_index];
}

/// @description returns an array of preset resolutions using a starting index and an end index
/// @param {Real} [start_i=0]
/// @param {Real} [end_i=array_length(global.stanncam_res_presets)-1]
/// @returns {Array<Struct>}
function stanncam_get_preset_resolution_range(_start_i=0, _end_i=array_length(global.stanncam_res_presets)-1)
{
	if (!variable_global_exists("stanncam_res_presets"))
	{
		__stanncam_error("stanncam_res_presets is not defined");
		return [];
	}

	var _start = min(_start_i, _end_i);
	var _end = max(_start_i, _end_i);
	var _max_i = array_length(global.stanncam_res_presets) - 1;

	_start = clamp(_start, 0, _max_i);
	_end = clamp(_end, 0, _max_i);

	if (_start > _end)
	{
		__stanncam_error($"stanncam_get_preset_resolution_range received invalid range: ({_start_i}, {_end_i})");
		return [];
	}
	
	return array_map(global.stanncam_res_presets, function(_i) { return stanncam_get_preset_resolution(_i); }, _start, _end);
}

/// @description sets whether or not zones should be drawn in the room, for debugging
/// @param {Bool} should_draw
function stanncam_debug_set_draw_zones(_should_draw)
{
	var _config = StanncamConfig();
	_config.draw_zones = _should_draw;
}

/// @function stanncam_toggle_cameras_paused
/// @description toggles camera's paused state
function stanncam_toggle_cameras_paused()
{
	var _config = StanncamConfig();
	array_foreach(_config.stanncams, function(_stanncam) {
		if (_stanncam != -1) { _stanncam.toggle_paused(); } 
	});
}

/// @description sets all cameras to paused state
/// @param {Bool} paused
function stanncam_set_cameras_paused(_paused)
{
	var _config = StanncamConfig();
	var _len = array_length(_config.stanncams);
	for (var i = 0; i < _len; i++)
	{
		var _stanncam = _config.stanncams[i];
		if (_stanncam != -1)
		{
			_stanncam.set_paused(_paused);
		}
	}
}

/// @description sets all cameras to paused state
function stanncam_cameras_pause()
{
	return stanncam_set_cameras_paused(true);
}

/// @description sets all cameras to an unpaused state
function stanncam_cameras_unpause()
{
	return stanncam_set_cameras_paused(false);
}

