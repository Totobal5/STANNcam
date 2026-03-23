/// STANNcam tests powered by Crispy

/// @ignore
function Stanncam_Test_Case()
{
	var _runner = new CrispyRunner("stanncam_runner");
	var _suite = new CrispySuite("stanncam_suite");

	_suite.SetUp(function() {
		__stanncam_test_reset_runtime();
	});

	_suite.TearDown(function() {
		__stanncam_test_reset_runtime();
	});

	_runner.AddTestSuite(_suite);
	_runner.Discover(_suite, "test_stanncam_");
	__stanncam_add_async_cases(_suite);

	return _runner;
}

/// @ignore
function __stanncam_add_async_cases(_suite)
{
	var _move_case = new CrispyCaseAsync("stanncam_move_caseasync_duration_reaches_target_after_steps");
	_move_case.SetUp(function()
	{
		var _vars = crispy_vars();
		__stanncam_test_bootstrap();
		_vars.stanncam_async_move_phase = 0;
		_vars.stanncam_async_move_cam = new Stanncam(0, 0, 320, 180);
	});

	_move_case
		.WaitStep(function()
		{
			var _vars = crispy_vars();
			var _cam = _vars.stanncam_async_move_cam;

			if (_vars.stanncam_async_move_phase == 0)
			{
				_cam.move(100, 50, 2);
				_vars.stanncam_async_move_phase = 1;
				return false;
			}

			if (_vars.stanncam_async_move_phase == 1)
			{
				_cam.__step();
				_vars.stanncam_async_move_phase = 2;
				return false;
			}

			_cam.__step();
			var _position = _cam.get_position();
			AssertEqual(_position.x, 100, "CaseAsync move should reach target x after duration steps");
			AssertEqual(_position.y, 50, "CaseAsync move should reach target y after duration steps");
			return true;
		})
		.Timeout(60, "frames");

	_move_case.TearDown(function()
	{
		var _vars = crispy_vars();
		if (variable_struct_exists(_vars, "stanncam_async_move_cam"))
		{
			var _cam = _vars.stanncam_async_move_cam;
			if (is_instanceof(_cam, Stanncam) && !_cam.is_destroyed())
			{
				_cam.destroy();
			}
		}
		__stanncam_test_reset_runtime();
	});

	_suite.AddCase(_move_case);

	var _offset_case = new CrispyCaseAsync("stanncam_offset_caseasync_duration_reaches_target_after_steps");
	_offset_case.SetUp(function()
	{
		var _vars = crispy_vars();
		__stanncam_test_bootstrap();
		_vars.stanncam_async_offset_phase = 0;
		_vars.stanncam_async_offset_cam = new Stanncam(0, 0, 320, 180);
	});

	_offset_case
		.WaitStep(function()
		{
			var _vars = crispy_vars();
			var _cam = _vars.stanncam_async_offset_cam;

			if (_vars.stanncam_async_offset_phase == 0)
			{
				_cam.offset(30, -20, 2);
				_vars.stanncam_async_offset_phase = 1;
				return false;
			}

			if (_vars.stanncam_async_offset_phase == 1)
			{
				_cam.__step();
				_vars.stanncam_async_offset_phase = 2;
				return false;
			}

			_cam.__step();
			AssertEqual(_cam.__offset_x, 30, "CaseAsync offset should reach target x after duration steps");
			AssertEqual(_cam.__offset_y, -20, "CaseAsync offset should reach target y after duration steps");
			return true;
		})
		.Timeout(60, "frames");

	_offset_case.TearDown(function()
	{
		var _vars = crispy_vars();
		if (variable_struct_exists(_vars, "stanncam_async_offset_cam"))
		{
			var _cam = _vars.stanncam_async_offset_cam;
			if (is_instanceof(_cam, Stanncam) && !_cam.is_destroyed())
			{
				_cam.destroy();
			}
		}
		__stanncam_test_reset_runtime();
	});

	_suite.AddCase(_offset_case);
}

/// @ignore
function run_stanncam_tests()
{
	var _runner = Stanncam_Test_Case();
	_runner.Run();

	// Async cases require runner updates on later frames to complete and emit final logs.
	if (_runner.IsRunning())
	{
        var _context = {call: undefined, runner: _runner}
        _context.call = call_later(1, time_source_units_frames, method(_context, function() {
            runner.Update();
            if (!runner.IsRunning() ) 
            {
                call_cancel(call);
            }
        }), true);
	}

	return _runner;
}

/// @ignore
function __stanncam_test_reset_runtime()
{
	var _config = StanncamConfig();
	var _len = array_length(_config.stanncams);
	for (var i = 0; i < _len; ++i)
	{
		var _camera = _config.stanncams[i];
		if (_camera != -1 && _camera != noone && is_instanceof(_camera, Stanncam) && !_camera.is_destroyed())
		{
			_camera.destroy();
		}
	}

	if (instance_exists(_config.manager))
	{
		with (_config.manager) instance_destroy();
	}

	_config.stanncams = [];
	_config.number_of_stanncams = 0;
	_config.manager = noone;
	_config.draw_zones = false;
}

/// @ignore
function __stanncam_test_bootstrap()
{
	__stanncam_test_reset_runtime();
	stanncam_init(320, 180, 1280, 720, 640, 360, STANNCAM_WINDOW_MODE.WINDOWED);
	return StanncamConfig();
}

/// @ignore
function test_stanncam_config_returns_singleton_reference()
{
	var _config_a = StanncamConfig();
	var _config_b = StanncamConfig();

	AssertTrue(_config_a == _config_b, "StanncamConfig should return the same singleton struct");
}

/// @ignore
function test_stanncam_init_sets_core_config_values()
{
	var _config = __stanncam_test_bootstrap();

	AssertEqual(_config.game_w, 320, "Game width should match init");
	AssertEqual(_config.game_h, 180, "Game height should match init");
	AssertEqual(_config.gui_w, 640, "GUI width should match init");
	AssertEqual(_config.gui_h, 360, "GUI height should match init");
	AssertEqual(_config.display_res_w, 1280, "Display width should match init");
	AssertEqual(_config.display_res_h, 720, "Display height should match init");
	AssertEqual(_config.window_mode, STANNCAM_WINDOW_MODE.WINDOWED, "Window mode should match init");
	AssertTrue(instance_exists(_config.manager), "Init should create the manager instance");

	__stanncam_test_reset_runtime();
}

/// @ignore
function test_stanncam_set_resolution_updates_config()
{
	var _config = __stanncam_test_bootstrap();
	stanncam_set_resolution(1024, 576);

	AssertEqual(_config.display_res_w, 1024, "Display width should update after set_resolution");
	AssertEqual(_config.display_res_h, 576, "Display height should update after set_resolution");

	__stanncam_test_reset_runtime();
}

/// @ignore
function test_stanncam_aspect_ratio_setters_update_flags()
{
	__stanncam_test_bootstrap();

	stanncam_set_keep_aspect_ratio(false);
	stanncam_set_gui_keep_aspect_ratio(false);

	AssertFalse(stanncam_get_keep_aspect_ratio(), "Display aspect ratio flag should update");
	AssertFalse(stanncam_get_gui_keep_aspect_ratio(), "GUI aspect ratio flag should update");

	__stanncam_test_reset_runtime();
}

/// @ignore
function test_stanncam_camera_constructor_registers_camera()
{
	var _config = __stanncam_test_bootstrap();
	var _camera = new Stanncam(100, 200, 320, 180);
	var _position = _camera.get_position();
	var _dimensions = _camera.get_dimensions();

	AssertEqual(_config.number_of_stanncams, 1, "Constructing a camera should register it");
	AssertEqual(_camera.cam_id, 0, "First camera should use cam_id 0");
	AssertEqual(_config.stanncams[0], _camera, "Config should store the created camera");
	AssertEqual(_position.x, 100, "Camera position x should match constructor");
	AssertEqual(_position.y, 200, "Camera position y should match constructor");
	AssertEqual(_dimensions.width, 320, "Camera width should match constructor");
	AssertEqual(_dimensions.height, 180, "Camera height should match constructor");

	_camera.destroy();
	__stanncam_test_reset_runtime();
}

/// @ignore
function test_stanncam_camera_public_setters_update_state()
{
	__stanncam_test_bootstrap();
	var _camera = new Stanncam(0, 0, 320, 180);
	var _manager = StanncamConfig().manager;

	AssertEqual(_camera.set_follow(_manager), _camera, "set_follow should be chainable");
	AssertEqual(_camera.set_speed(0.5), _camera, "set_speed should be chainable");
	AssertEqual(_camera.set_bounds(16, 24), _camera, "set_bounds should be chainable");
	AssertEqual(_camera.set_room_constrain(true), _camera, "set_room_constrain should be chainable");
	AssertEqual(_camera.set_paused(true), _camera, "set_paused should be chainable");
	AssertEqual(_camera.set_smooth_draw(false), _camera, "set_smooth_draw should be chainable");
	AssertEqual(_camera.set_zoom_amount(2), _camera, "set_zoom_amount should be chainable");
	AssertEqual(_camera.set_debug_draw(true), _camera, "set_debug_draw should be chainable");

	AssertEqual(_camera.get_follow(), _manager, "Follow target should update");
	AssertEqual(_camera.get_speed(), 0.5, "Speed should update");
	AssertEqual(_camera.get_bounds_width(), 16, "Bounds width should update");
	AssertEqual(_camera.get_bounds_height(), 24, "Bounds height should update");
	AssertTrue(_camera.get_room_constrain(), "Room constrain should update");
	AssertTrue(_camera.get_paused(), "Paused state should update");
	AssertFalse(_camera.get_smooth_draw(), "Smooth draw should update");
	AssertEqual(_camera.get_zoom_amount(), 2, "Zoom amount should update");
	AssertTrue(_camera.get_debug_draw(), "Debug draw should update");

	_camera.destroy();
	__stanncam_test_reset_runtime();
}

/// @ignore
function test_stanncam_camera_move_updates_position_when_not_following()
{
	__stanncam_test_bootstrap();
	var _camera = new Stanncam(0, 0, 320, 180);

	_camera.move(64, 96, 0);
	var _position = _camera.get_position();

	AssertEqual(_position.x, 64, "Move should update x immediately when not following");
	AssertEqual(_position.y, 96, "Move should update y immediately when not following");

	_camera.destroy();
	__stanncam_test_reset_runtime();
}

/// @ignore
function test_stanncam_camera_move_with_duration_reaches_target_after_steps()
{
	__stanncam_test_bootstrap();
	var _camera = new Stanncam(0, 0, 320, 180);

	_camera.move(100, 50, 2);
	_camera.__step();
	_camera.__step();

	var _position = _camera.get_position();
	AssertEqual(_position.x, 100, "Move with duration should reach target x after duration steps");
	AssertEqual(_position.y, 50, "Move with duration should reach target y after duration steps");

	_camera.destroy();
	__stanncam_test_reset_runtime();
}

/// @ignore
function test_stanncam_camera_offset_with_duration_reaches_target_after_steps()
{
	__stanncam_test_bootstrap();
	var _camera = new Stanncam(0, 0, 320, 180);

	_camera.offset(30, -20, 2);
	_camera.__step();
	_camera.__step();

	AssertEqual(_camera.__offset_x, 30, "Offset with duration should reach target x after duration steps");
	AssertEqual(_camera.__offset_y, -20, "Offset with duration should reach target y after duration steps");

	_camera.destroy();
	__stanncam_test_reset_runtime();
}

/// @ignore
function test_stanncam_camera_clone_copies_public_state()
{
	__stanncam_test_bootstrap();
	var _camera = new Stanncam(32, 48, 320, 180, true, false);
	var _manager = StanncamConfig().manager;

	_camera
		.set_follow(_manager)
		.set_speed(0.25)
		.set_bounds(12, 20)
		.set_room_constrain(true)
		.set_paused(true)
		.set_debug_draw(true);
	_camera.offset(5, -3, 0);
	_camera.zoom(1.5, 0);

	var _clone = _camera.clone();
	var _clone_pos = _clone.get_position();
	var _clone_dim = _clone.get_dimensions();

	AssertEqual(StanncamConfig().number_of_stanncams, 2, "Clone should register a second camera");
	AssertNotEqual(_clone.cam_id, _camera.cam_id, "Clone should receive a different cam_id");
	AssertEqual(_clone_pos.x, 32, "Clone should copy x position");
	AssertEqual(_clone_pos.y, 48, "Clone should copy y position");
	AssertEqual(_clone_dim.width, 320, "Clone should copy width");
	AssertEqual(_clone_dim.height, 180, "Clone should copy height");
	AssertEqual(_clone.get_follow(), _manager, "Clone should copy follow target");
	AssertEqual(_clone.get_speed(), 0.25, "Clone should copy speed");
	AssertEqual(_clone.get_bounds_width(), 12, "Clone should copy bounds width");
	AssertEqual(_clone.get_bounds_height(), 20, "Clone should copy bounds height");
	AssertTrue(_clone.get_room_constrain(), "Clone should copy room constrain");
	AssertTrue(_clone.get_paused(), "Clone should copy paused state");
	AssertFalse(_clone.get_smooth_draw(), "Clone should copy smooth draw state");
	AssertEqual(_clone.get_zoom_amount(), 1.5, "Clone should copy zoom amount");
	AssertTrue(_clone.get_debug_draw(), "Clone should copy debug draw state");
	AssertEqual(_clone.__offset_x, 5, "Clone should copy offset x");
	AssertEqual(_clone.__offset_y, -3, "Clone should copy offset y");
	AssertTrue(_clone.__surface_extra_on, "Clone should copy surface_extra flag");

	_clone.destroy();
	_camera.destroy();
	__stanncam_test_reset_runtime();
}

/// @ignore
function test_stanncam_toggle_cameras_paused_updates_all_cameras()
{
	__stanncam_test_bootstrap();
	var _camera_a = new Stanncam();
	var _camera_b = new Stanncam();

	stanncam_set_cameras_paused(true);
	AssertTrue(_camera_a.get_paused(), "set_cameras_paused should pause the first camera");
	AssertTrue(_camera_b.get_paused(), "set_cameras_paused should pause the second camera");

	stanncam_toggle_cameras_paused();
	AssertFalse(_camera_a.get_paused(), "toggle_cameras_paused should toggle the first camera");
	AssertFalse(_camera_b.get_paused(), "toggle_cameras_paused should toggle the second camera");

	_camera_b.destroy();
	_camera_a.destroy();
	__stanncam_test_reset_runtime();
}

/// @ignore
function test_stanncam_camera_destroy_unregisters_camera()
{
	var _config = __stanncam_test_bootstrap();
	var _camera = new Stanncam();
	var _cam_id = _camera.cam_id;

	_camera.destroy();

	AssertTrue(_camera.is_destroyed(), "Destroyed camera should report destroyed state");
	AssertEqual(_config.stanncams[_cam_id], -1, "Destroyed camera should unregister from config");
	AssertEqual(_config.number_of_stanncams, 0, "Destroying the only camera should decrement the count");

	__stanncam_test_reset_runtime();
}

// ========== COORDINATE CONVERSION TESTS ==========

/// @ignore
function test_stanncam_camera_room_to_gui_xy_returns_valid_coordinates()
{
	__stanncam_test_bootstrap();
	var _camera = new Stanncam(0, 0, 320, 180);

	var _gui_x = _camera.room_to_gui_x(160);
	var _gui_y = _camera.room_to_gui_y(90);

	AssertTrue(is_real(_gui_x) && _gui_x != undefined, "room_to_gui_x should return a real number");
	AssertTrue(is_real(_gui_y) && _gui_y != undefined, "room_to_gui_y should return a real number");

	_camera.destroy();
	__stanncam_test_reset_runtime();
}

/// @ignore
function test_stanncam_camera_room_to_gui_xy_with_zoom()
{
	__stanncam_test_bootstrap();
	var _camera = new Stanncam(0, 0, 320, 180);
	_camera.zoom(2.0, 0);

	var _gui_x_zoomed = _camera.room_to_gui_x(160);
	var _gui_y_zoomed = _camera.room_to_gui_y(90);

	AssertTrue(is_real(_gui_x_zoomed) && _gui_x_zoomed != undefined, "room_to_gui_x with zoom should return a real number");
	AssertTrue(is_real(_gui_y_zoomed) && _gui_y_zoomed != undefined, "room_to_gui_y with zoom should return a real number");

	_camera.destroy();
	__stanncam_test_reset_runtime();
}

/// @ignore
function test_stanncam_camera_room_to_display_xy_returns_valid_coordinates()
{
	__stanncam_test_bootstrap();
	var _camera = new Stanncam(0, 0, 320, 180);

	var _display_x = _camera.room_to_display_x(160);
	var _display_y = _camera.room_to_display_y(90);

	AssertTrue(is_real(_display_x) && _display_x != undefined, "room_to_display_x should return a real number");
	AssertTrue(is_real(_display_y) && _display_y != undefined, "room_to_display_y should return a real number");

	_camera.destroy();
	__stanncam_test_reset_runtime();
}

/// @ignore
function test_stanncam_camera_room_to_display_xy_with_offset()
{
	__stanncam_test_bootstrap();
	var _camera = new Stanncam(0, 0, 320, 180);
	_camera.offset(10, 20, 0);

	var _display_x = _camera.room_to_display_x(160);
	var _display_y = _camera.room_to_display_y(90);

	AssertTrue(is_real(_display_x) && _display_x != undefined, "room_to_display_x with offset should return a real number");
	AssertTrue(is_real(_display_y) && _display_y != undefined, "room_to_display_y with offset should return a real number");

	_camera.destroy();
	__stanncam_test_reset_runtime();
}

// ========== ZONE TESTS ==========

/// @ignore
function test_stanncam_camera_get_active_zone_returns_noone_without_follow()
{
	__stanncam_test_bootstrap();
	var _camera = new Stanncam(0, 0, 320, 180);

	var _zone = _camera.get_active_zone();

	AssertEqual(_zone, noone, "get_active_zone should return noone when no follow target is set");

	_camera.destroy();
	__stanncam_test_reset_runtime();
}

/// @ignore
function test_stanncam_camera_get_active_zone_returns_value_type()
{
	__stanncam_test_bootstrap();
	var _camera = new Stanncam(0, 0, 320, 180);
	var _dummy = instance_create_depth(0, 0, 0, obj_ball);

	_camera.set_follow(_dummy);
	var _zone = _camera.get_active_zone();

	// Zone can be noone or a ds_list depending on zone setup
	AssertTrue(_zone == noone || is_numeric(_zone), "get_active_zone should return a ds_list ID or noone");

	instance_destroy(_dummy);
	_camera.destroy();
	__stanncam_test_reset_runtime();
}

// ========== OUT OF BOUNDS TESTS ==========

/// @ignore
function test_stanncam_camera_out_of_bounds_returns_bool()
{
	__stanncam_test_bootstrap();
	var _camera = new Stanncam(0, 0, 320, 180);

	// Test that out_of_bounds returns booleans
	var _result_1 = _camera.out_of_bounds(0, 0, 0);
	var _result_2 = _camera.out_of_bounds(100, 100, 0);

	AssertTrue(is_bool(_result_1), "out_of_bounds should return a boolean");
	AssertTrue(is_bool(_result_2), "out_of_bounds should return a boolean for any position");

	_camera.destroy();
	__stanncam_test_reset_runtime();
}

/// @ignore
function test_stanncam_camera_out_of_bounds_with_margin_affects_bounds()
{
	__stanncam_test_bootstrap();
	var _camera = new Stanncam(0, 0, 320, 180);

	// Camera center is a stable reference point for bounds checks.
	var _center = _camera.get_position();
	var _no_margin = _camera.out_of_bounds(_center.x, _center.y, 0);
	var _very_large_margin = _camera.out_of_bounds(_center.x, _center.y, 200);

	AssertFalse(_no_margin, "Camera center should be in bounds with 0 margin");
	AssertTrue(_very_large_margin, "A very large margin should push center out of bounds");

	_camera.destroy();
	__stanncam_test_reset_runtime();
}

// ========== SCREEN SHAKE TESTS ==========

/// @ignore
function test_stanncam_camera_shake_screen_initializes_shake_state()
{
	__stanncam_test_bootstrap();
	var _camera = new Stanncam(0, 0, 320, 180);

	_camera.shake_screen(5, 10);

	AssertEqual(_camera.__shake_magnitude, 5, "shake_screen should set magnitude");
	AssertEqual(_camera.__shake_length, 10, "shake_screen should set duration");
	AssertEqual(_camera.__shake_time, 0, "shake_screen should initialize time to 0");

	_camera.destroy();
	__stanncam_test_reset_runtime();
}

/// @ignore
function test_stanncam_camera_shake_screen_with_zero_duration()
{
	__stanncam_test_bootstrap();
	var _camera = new Stanncam(0, 0, 320, 180);

	_camera.shake_screen(10, 0);

	AssertEqual(_camera.__shake_magnitude, 10, "shake_screen should accept any magnitude");
	AssertEqual(_camera.__shake_length, 0, "shake_screen should accept 0 duration");

	_camera.destroy();
	__stanncam_test_reset_runtime();
}

// ========== EDGE CASES ==========

/// @ignore
function test_stanncam_camera_destroy_twice_safe()
{
	__stanncam_test_bootstrap();
	var _camera = new Stanncam(0, 0, 320, 180);

	_camera.destroy();
	var _destroyed_once = _camera.is_destroyed();

	_camera.destroy();
	var _destroyed_twice = _camera.is_destroyed();

	AssertTrue(_destroyed_once, "First destroy should mark camera as destroyed");
	AssertTrue(_destroyed_twice, "Second destroy should not change state");

	__stanncam_test_reset_runtime();
}

/// @ignore
function test_stanncam_camera_methods_after_destroyed_returns_expected_states()
{
	__stanncam_test_bootstrap();
	var _camera = new Stanncam(0, 0, 320, 180);
	_camera.destroy();

	// Even after destroy, the camera struct still exists but is marked destroyed
	AssertTrue(_camera.is_destroyed(), "is_destroyed should remain true after multiple checks");
	
	// Accessing position after destroy should still work (struct persists)
	var _pos = _camera.get_position();
	AssertTrue(is_struct(_pos), "get_position should return a struct even after destroy");

	__stanncam_test_reset_runtime();
}

// ========== LEGACY COVERAGE TESTS ==========

/// @ignore
function test_stanncam_constructor_check_default_values()
{
	var _config = __stanncam_test_bootstrap();
	var _camera = new Stanncam();
	var _position = _camera.get_position();
	var _dimensions = _camera.get_dimensions();

	AssertEqual(_position.x, 0, "Default x should be 0");
	AssertEqual(_position.y, 0, "Default y should be 0");
	AssertEqual(_dimensions.width, _config.game_w, "Default width should use game width");
	AssertEqual(_dimensions.height, _config.game_h, "Default height should use game height");
	AssertFalse(_camera.__surface_extra_on, "surface_extra_on should default to false");
	AssertTrue(_camera.get_smooth_draw(), "smooth_draw should default to true");

	_camera.destroy();
	__stanncam_test_reset_runtime();
}

/// @ignore
function test_stanncam_constructor_create_with_specified_values()
{
	__stanncam_test_bootstrap();
	var _camera = new Stanncam(100, 100, 800, 600, true, false);
	var _position = _camera.get_position();
	var _dimensions = _camera.get_dimensions();

	AssertEqual(_position.x, 100, "Constructor x should match input");
	AssertEqual(_position.y, 100, "Constructor y should match input");
	AssertEqual(_dimensions.width, 800, "Constructor width should match input");
	AssertEqual(_dimensions.height, 600, "Constructor height should match input");
	AssertTrue(_camera.__surface_extra_on, "Constructor should set surface_extra_on");
	AssertFalse(_camera.get_smooth_draw(), "Constructor should set smooth_draw");

	_camera.destroy();
	__stanncam_test_reset_runtime();
}

/// @ignore
function test_stanncam_to_string_should_return_string()
{
	__stanncam_test_bootstrap();
	var _camera = new Stanncam();
	AssertEqual(typeof(_camera.toString()), "string", "toString should return a string");

	_camera.destroy();
	__stanncam_test_reset_runtime();
}

/// @ignore
function test_stanncam_surface_exists_after_update_view_size_for_non_app_surface()
{
	__stanncam_test_bootstrap();
	var _camera0 = new Stanncam();
	var _camera1 = new Stanncam();

	_camera1.__update_view_size(true);
	AssertTrue(surface_exists(_camera1.__surface), "Non-app-surface camera should have a valid surface after update_view_size");

	_camera1.destroy();
	_camera0.destroy();
	__stanncam_test_reset_runtime();
}

/// @ignore
function test_stanncam_surface_freed_after_destroy_non_app_surface()
{
	__stanncam_test_bootstrap();
	var _camera0 = new Stanncam();
	var _camera1 = new Stanncam();

	_camera1.__update_view_size(true);
	var _surface = _camera1.__surface;
	AssertTrue(surface_exists(_surface), "Surface should exist before destroy");

	_camera1.destroy();
	AssertFalse(surface_exists(_surface), "Surface should be freed after destroy");

	_camera0.destroy();
	__stanncam_test_reset_runtime();
}

/// @ignore
function test_stanncam_zone_image_angle_of_360_wraps_to_0()
{
	__stanncam_test_bootstrap();
	var _zone = instance_create_depth(0, 0, 0, obj_stanncam_zone);
	_zone.image_angle = 360;
	with (_zone) event_perform(ev_create, 0);

	AssertEqual(_zone.image_angle, 0, "Zone image_angle 360 should wrap to 0");

	with (_zone) instance_destroy();
	__stanncam_test_reset_runtime();
}

/// @ignore
function test_stanncam_zone_image_angle_of_negative_360_wraps_to_0()
{
	__stanncam_test_bootstrap();
	var _zone = instance_create_depth(0, 0, 0, obj_stanncam_zone);
	_zone.image_angle = -360;
	with (_zone) event_perform(ev_create, 0);

	AssertEqual(_zone.image_angle, 0, "Zone image_angle -360 should wrap to 0");

	with (_zone) instance_destroy();
	__stanncam_test_reset_runtime();
}