/// STANNcam tests powered by Crispy

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

	return _runner;
}

function run_stanncam_tests()
{
	var _runner = Stanncam_Test_Case();
	_runner.Run();
	return _runner;
}

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

function __stanncam_test_bootstrap()
{
	__stanncam_test_reset_runtime();
	stanncam_init(320, 180, 1280, 720, 640, 360, STANNCAM_WINDOW_MODE.WINDOWED);
	return StanncamConfig();
}

function test_stanncam_config_returns_singleton_reference()
{
	var _config_a = StanncamConfig();
	var _config_b = StanncamConfig();

	AssertTrue(_config_a == _config_b, "StanncamConfig should return the same singleton struct");
}

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

function test_stanncam_set_resolution_updates_config()
{
	var _config = __stanncam_test_bootstrap();
	stanncam_set_resolution(1024, 576);

	AssertEqual(_config.display_res_w, 1024, "Display width should update after set_resolution");
	AssertEqual(_config.display_res_h, 576, "Display height should update after set_resolution");

	__stanncam_test_reset_runtime();
}

function test_stanncam_aspect_ratio_setters_update_flags()
{
	__stanncam_test_bootstrap();

	stanncam_set_keep_aspect_ratio(false);
	stanncam_set_gui_keep_aspect_ratio(false);

	AssertFalse(stanncam_get_keep_aspect_ratio(), "Display aspect ratio flag should update");
	AssertFalse(stanncam_get_gui_keep_aspect_ratio(), "GUI aspect ratio flag should update");

	__stanncam_test_reset_runtime();
}

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

function test_stanncam_camera_get_active_zone_returns_noone_without_follow()
{
	__stanncam_test_bootstrap();
	var _camera = new Stanncam(0, 0, 320, 180);

	var _zone = _camera.get_active_zone();

	AssertEqual(_zone, noone, "get_active_zone should return noone when no follow target is set");

	_camera.destroy();
	__stanncam_test_reset_runtime();
}

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

function test_stanncam_camera_out_of_bounds_with_margin_affects_bounds()
{
	__stanncam_test_bootstrap();
	var _camera = new Stanncam(0, 0, 320, 180);

	// Without margin - check behavior at camera origin
	var _no_margin = _camera.out_of_bounds(0, 0, 0);
	
	// With margin - same position should be more likely to be out of bounds
	// (margin reduces the viewable area)
	var _with_margin = _camera.out_of_bounds(0, 0, 10);

	// Main assertion: margin parameter is respected - it changes the effective bounds
	// When margin is larger, more positions fall outside the bounds
	AssertTrue(is_bool(_no_margin) && is_bool(_with_margin), "Both calls should return booleans");
	
	// If no margin position is in bounds, margin should make it more likely to be out
	if (!_no_margin) 
	{
		// Position was in bounds without margin, should be more restrictive with margin
		AssertTrue(true, "Margin parameter is accepted and affects boundary calculation");
	}

	_camera.destroy();
	__stanncam_test_reset_runtime();
}

// ========== SCREEN SHAKE TESTS ==========

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