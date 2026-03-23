/// @param {Any} [camera=undefined] Optional specific camera to debug (defaults to all active cameras).
function stanncam_debug_create_overlay(_camera=undefined)
{
	var _config = StanncamConfig();
	stanncam_debug_destroy_overlay();
	_config.__dbgview_state = __stanncam_debug_capture_manager_state(_config);

	dbg_view("STANNcam Manager", true, 20, 20, 420, 360);
	dbg_section("Resolution & Display");
	dbg_slider_int(ref_create(_config, "display_res_w"), 320, 3840, "Display Width", 80);
	dbg_slider_int(ref_create(_config, "display_res_h"), 180, 2160, "Display Height", 45);
	dbg_watch(ref_create(_config, "game_w"), "Game Width");
	dbg_watch(ref_create(_config, "game_h"), "Game Height");
	dbg_watch(ref_create(_config, "gui_w"), "GUI Width");
	dbg_watch(ref_create(_config, "gui_h"), "GUI Height");
	dbg_watch(ref_create(_config, "res_w"), "Render Width");
	dbg_watch(ref_create(_config, "res_h"), "Render Height");
	
	dbg_text_separator("", 1);
	dbg_watch(ref_create(_config, "__display_scale_x"), "Display Scale X");
	dbg_watch(ref_create(_config, "__display_scale_y"), "Display Scale Y");
	dbg_watch(ref_create(_config, "__gui_x_scale"), "GUI Scale X");
	dbg_watch(ref_create(_config, "__gui_y_scale"), "GUI Scale Y");
	dbg_checkbox(ref_create(_config, "keep_aspect_ratio"), "Keep Aspect Ratio");
	dbg_checkbox(ref_create(_config, "gui_keep_aspect_ratio"), "GUI Keep Aspect");
	
	dbg_section("Window & Mode");
	dbg_watch(ref_create(_config, "window_mode"), "Window Mode");
	dbg_watch(ref_create(_config, "number_of_stanncams"), "Active Cameras");
	dbg_watch(ref_create(_config, "manager"), "Manager Instance");
	dbg_watch(ref_create(_config, "__switching_window_mode"), "Switching Window Mode");
	dbg_checkbox(ref_create(_config, "draw_zones"), "Draw Zones");
	
	if (__stanncam_debug_is_valid_camera(_camera))
	{
		__stanncam_debug_create_camera_view(_camera);
	}
	else
	{
		var i = 0;
		repeat (array_length(_config.stanncams))
		{
			var _cam = _config.stanncams[i++];
			if (__stanncam_debug_is_valid_camera(_cam))
			{
				__stanncam_debug_create_camera_view(_cam);
			}
		}
	}
}

/// @param {Any} camera
/// @returns {Bool}
/// @ignore
function __stanncam_debug_is_valid_camera(_camera)
{
	return _camera != undefined
		&& _camera != noone
		&& _camera != -1
		&& is_instanceof(_camera, Stanncam)
		&& !_camera.is_destroyed();
}

/// @param {Any} camera Camera instance to debug.
/// @ignore
function __stanncam_debug_create_camera_view(_camera)
{
	_camera.__dbgview_state = __stanncam_debug_capture_camera_state(_camera);

	var _cam_id = _camera.cam_id;
	var _view_name = $"STANNcam Camera {_cam_id}";
	dbg_view(_view_name, true, 460, 20 + (_cam_id * 340), 420, 320);
	
	dbg_section("Position & Size");
	dbg_slider(ref_create(_camera, "__x"), -500, 5000, "X", 5);
	dbg_slider(ref_create(_camera, "__y"), -500, 5000, "Y", 5);
	dbg_slider_int(ref_create(_camera, "__width"), 160, 1280, "Width", 16);
	dbg_slider_int(ref_create(_camera, "__height"), 90, 720, "Height", 16);
	dbg_watch(ref_create(_camera, "cam_id"), "Camera ID");
	
	dbg_text_separator("Camera Offsets", 1);
	dbg_slider(ref_create(_camera, "__offset_x"), -200, 200, "Offset X", 5);
	dbg_slider(ref_create(_camera, "__offset_y"), -200, 200, "Offset Y", 5);
	
	dbg_section("Zoom & Motion");
	dbg_slider(ref_create(_camera, "__zoom_amount"), 0.1, 5, "Zoom", 0.1);
	dbg_slider(ref_create(_camera, "__spd"), 0, 20, "Speed", 0.5);
	dbg_slider(ref_create(_camera, "__constrain_spd"), 0, 1, "Constrain Speed", 0.05);
	
	dbg_text_separator("Follow Bounds", 1);
	dbg_slider(ref_create(_camera, "__bounds_w"), 0, 100, "Bounds Width", 1);
	dbg_slider(ref_create(_camera, "__bounds_h"), 0, 100, "Bounds Height", 1);
	dbg_watch(ref_create(_camera, "__bounds_dist_w"), "Bounds Dist W");
	dbg_watch(ref_create(_camera, "__bounds_dist_h"), "Bounds Dist H");
	
	dbg_section("Follow & State");
	dbg_watch(ref_create(_camera, "__follow"), "Follow Instance");
	dbg_checkbox(ref_create(_camera, "__paused"), "Paused");
	dbg_checkbox(ref_create(_camera, "__smooth_draw"), "Smooth Draw");
	dbg_checkbox(ref_create(_camera, "__room_constrain"), "Room Constrain");
	dbg_checkbox(ref_create(_camera, "__surface_extra_on"), "Surface Extra On");
	dbg_checkbox(ref_create(_camera, "__debug_draw_on"), "Debug Draw");
	
	dbg_section("Animation");
	dbg_checkbox(ref_create(_camera, "__moving"), "Is Moving");
	dbg_checkbox(ref_create(_camera, "__zooming"), "Is Zooming");
	dbg_checkbox(ref_create(_camera, "__size_change"), "Is Resizing");
	dbg_checkbox(ref_create(_camera, "__offset"), "Is Offsetting");
	dbg_watch(ref_create(_camera, "__t"), "Move T");
	dbg_watch(ref_create(_camera, "__dimen_t"), "Size T");
	dbg_watch(ref_create(_camera, "__offset_t"), "Offset T");
	dbg_watch(ref_create(_camera, "__t_zoom"), "Zoom T");
	
	dbg_section("Shake");
	dbg_text_separator("Real-time Shake Values", 1);
	dbg_slider(ref_create(_camera, "__shake_magnitude"), 0, 50, "Magnitude", 0.5);
	dbg_slider_int(ref_create(_camera, "__shake_length"), 0, 300, "Length", 5);
	dbg_slider_int(ref_create(_camera, "__shake_time"), 0, 300, "Time", 5);
	dbg_watch(ref_create(_camera, "__shake_x"), "Shake X");
	dbg_watch(ref_create(_camera, "__shake_y"), "Shake Y");
	
	dbg_section("Constraints & Advanced");
	dbg_watch(ref_create(_camera, "__x_frac"), "X Fractional");
	dbg_watch(ref_create(_camera, "__y_frac"), "Y Fractional");
	dbg_watch(ref_create(_camera, "__constrain_offset_x"), "Constrain Offset X");
	dbg_watch(ref_create(_camera, "__constrain_offset_y"), "Constrain Offset Y");
	dbg_watch(ref_create(_camera, "__constrain_frac_x"), "Constrain Frac X");
	dbg_watch(ref_create(_camera, "__constrain_frac_y"), "Constrain Frac Y");
	dbg_watch(ref_create(_camera, "__zone_lists"), "Zone Lists");
	dbg_watch(ref_create(_camera, "__zone_lists_strength"), "Zone Strengths");
}

function stanncam_debug_sync_overlay()
{
	var _config = StanncamConfig();
	if (!dbg_view_exists("STANNcam Manager")) { return; }

	__stanncam_debug_sync_manager(_config);

	var _len = array_length(_config.stanncams);
	for (var i = 0; i < _len; ++i)
	{
		var _camera = _config.stanncams[i];
		if (__stanncam_debug_is_valid_camera(_camera))
		{
			__stanncam_debug_sync_camera(_camera);
		}
	}
}

/// @param {Struct} _config
/// @ignore
function __stanncam_debug_sync_manager(_config)
{
	var _state = variable_struct_exists(_config, "__dbgview_state")
		? _config.__dbgview_state
		: __stanncam_debug_capture_manager_state(_config);
	var _display_res_w = variable_struct_get(_config, "display_res_w");
	var _display_res_h = variable_struct_get(_config, "display_res_h");
	var _keep_aspect_ratio = variable_struct_get(_config, "keep_aspect_ratio");
	var _gui_keep_aspect_ratio = variable_struct_get(_config, "gui_keep_aspect_ratio");
	var _draw_zones = variable_struct_get(_config, "draw_zones");
	var _state_display_res_w = variable_struct_get(_state, "display_res_w");
	var _state_display_res_h = variable_struct_get(_state, "display_res_h");
	var _state_keep_aspect_ratio = variable_struct_get(_state, "keep_aspect_ratio");
	var _state_gui_keep_aspect_ratio = variable_struct_get(_state, "gui_keep_aspect_ratio");
	var _state_draw_zones = variable_struct_get(_state, "draw_zones");

	if (_display_res_w != _state_display_res_w || _display_res_h != _state_display_res_h)
	{
		stanncam_set_resolution(_display_res_w, _display_res_h);
	}

	if (_keep_aspect_ratio != _state_keep_aspect_ratio)
	{
		stanncam_set_keep_aspect_ratio(_keep_aspect_ratio);
	}

	if (_gui_keep_aspect_ratio != _state_gui_keep_aspect_ratio)
	{
		stanncam_set_gui_keep_aspect_ratio(_gui_keep_aspect_ratio);
	}

	if (_draw_zones != _state_draw_zones)
	{
		stanncam_debug_set_draw_zones(_draw_zones);
	}

	_config.__dbgview_state = __stanncam_debug_capture_manager_state(_config);
}

/// @param {Any} _camera
/// @ignore
function __stanncam_debug_sync_camera(_camera)
{
	var _state = variable_struct_exists(_camera, "__dbgview_state")
		? _camera.__dbgview_state
		: __stanncam_debug_capture_camera_state(_camera);
	var _state_x = variable_struct_get(_state, "x");
	var _state_y = variable_struct_get(_state, "y");
	var _state_width = variable_struct_get(_state, "width");
	var _state_height = variable_struct_get(_state, "height");
	var _state_offset_x = variable_struct_get(_state, "offset_x");
	var _state_offset_y = variable_struct_get(_state, "offset_y");
	var _state_zoom_amount = variable_struct_get(_state, "zoom_amount");
	var _state_spd = variable_struct_get(_state, "spd");
	var _state_bounds_w = variable_struct_get(_state, "bounds_w");
	var _state_bounds_h = variable_struct_get(_state, "bounds_h");
	var _state_paused = variable_struct_get(_state, "paused");
	var _state_smooth_draw = variable_struct_get(_state, "smooth_draw");
	var _state_room_constrain = variable_struct_get(_state, "room_constrain");
	var _state_surface_extra_on = variable_struct_get(_state, "surface_extra_on");
	var _state_debug_draw_on = variable_struct_get(_state, "debug_draw_on");

	if (_camera.__x != _state_x || _camera.__y != _state_y)
	{
		_camera.__update_view_pos();
	}

	if (_camera.__width != _state_width || _camera.__height != _state_height)
	{
		_camera.set_size(_camera.__width, _camera.__height, 0);
	}

	if (_camera.__offset_x != _state_offset_x || _camera.__offset_y != _state_offset_y)
	{
		_camera.offset(_camera.__offset_x, _camera.__offset_y, 0);
	}

	if (_camera.__zoom_amount != _state_zoom_amount)
	{
		_camera.zoom(_camera.__zoom_amount, 0);
		_camera.__update_view_pos();
	}

	if (_camera.__spd != _state_spd)
	{
		_camera.set_speed(_camera.__spd);
	}

	if (_camera.__bounds_w != _state_bounds_w || _camera.__bounds_h != _state_bounds_h)
	{
		_camera.set_bounds(_camera.__bounds_w, _camera.__bounds_h);
	}

	if (_camera.__paused != _state_paused)
	{
		_camera.set_paused(_camera.__paused);
	}

	if (_camera.__smooth_draw != _state_smooth_draw)
	{
		_camera.set_smooth_draw(_camera.__smooth_draw);
		_camera.__update_view_size();
		_camera.__update_view_pos();
	}

	if (_camera.__room_constrain != _state_room_constrain)
	{
		_camera.set_room_constrain(_camera.__room_constrain);
		_camera.__update_view_pos();
	}

	if (_camera.__surface_extra_on != _state_surface_extra_on)
	{
		_camera.__check_surface();
	}

	if (_camera.__debug_draw_on != _state_debug_draw_on)
	{
		_camera.set_debug_draw(_camera.__debug_draw_on);
	}

	_camera.__dbgview_state = __stanncam_debug_capture_camera_state(_camera);
}

/// @param {Struct} _config
/// @returns {Struct}
/// @ignore
function __stanncam_debug_capture_manager_state(_config)
{
	var _display_res_w = variable_struct_get(_config, "display_res_w");
	var _display_res_h = variable_struct_get(_config, "display_res_h");
	var _keep_aspect_ratio = variable_struct_get(_config, "keep_aspect_ratio");
	var _gui_keep_aspect_ratio = variable_struct_get(_config, "gui_keep_aspect_ratio");
	var _draw_zones = variable_struct_get(_config, "draw_zones");

	return {
		display_res_w: _display_res_w,
		display_res_h: _display_res_h,
		keep_aspect_ratio: _keep_aspect_ratio,
		gui_keep_aspect_ratio: _gui_keep_aspect_ratio,
		draw_zones: _draw_zones
	};
}

/// @param {Any} _camera
/// @returns {Struct}
/// @ignore
function __stanncam_debug_capture_camera_state(_camera)
{
	return {
		x: _camera.__x,
		y: _camera.__y,
		width: _camera.__width,
		height: _camera.__height,
		offset_x: _camera.__offset_x,
		offset_y: _camera.__offset_y,
		zoom_amount: _camera.__zoom_amount,
		spd: _camera.__spd,
		bounds_w: _camera.__bounds_w,
		bounds_h: _camera.__bounds_h,
		paused: _camera.__paused,
		smooth_draw: _camera.__smooth_draw,
		room_constrain: _camera.__room_constrain,
		surface_extra_on: _camera.__surface_extra_on,
		debug_draw_on: _camera.__debug_draw_on
	};
}

function stanncam_debug_create_coord_test()
{
	dbg_view("STANNcam Coordinates", true, 900, 20, 420, 250);
	
	dbg_section("Mouse & Conversions");
	dbg_text("Validates coordinate projections.");
	dbg_text("Mouse coordinates and conversions update in real-time.");
	dbg_text_separator("Available Functions", 1);
	
	dbg_text("Open the Output window or use the console:");
	dbg_text("");
	dbg_text("  cam.get_mouse_x() / cam.get_mouse_y()");
	dbg_text("  cam.room_to_gui_x(x) / cam.room_to_gui_y(y)");
	dbg_text("  cam.room_to_display_x(x) / cam.room_to_display_y(y)");
	dbg_text("");
	dbg_text("Tip: Use CTRL+click on sliders for direct input");
}

function stanncam_debug_destroy_overlay()
{
	if (dbg_view_exists("STANNcam Manager") )
    {
		dbg_view_delete("STANNcam Manager");
	}
	
	var i = 0; repeat (8) 
    {
		var _legacy_view_name = $"Camera {i}";
		var _camera_view_name = $"STANNcam Camera {i}";
		if (dbg_view_exists(_legacy_view_name)) { dbg_view_delete(_legacy_view_name); }
		if (dbg_view_exists(_camera_view_name)) { dbg_view_delete(_camera_view_name); }
		i++;
	}
	
	if (dbg_view_exists("STANNcam Coordinates")) 
    {
		dbg_view_delete("STANNcam Coordinates");
	}
}