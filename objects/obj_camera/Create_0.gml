/// @description Demo 1
var _config = StanncamConfig();

__stanncam_alert($"Demo1 Create: game=({_config.game_w}, {_config.game_h}) room=({room_width}, {room_height})");
if (!instance_exists(obj_player))
{
	__stanncam_error($"Demo1 Create: obj_player does not exist before camera creation");
}

cam1 = new Stanncam(obj_player.x, obj_player.y, _config.game_w, _config.game_h, 0, 0);
__stanncam_alert($"Demo1 Create: cam1 created with id={cam1.cam_id}");
cam1.set_follow(obj_player);
cam1.set_bounds(10, 10);
__stanncam_alert($"Demo1 Create: cam1 follow configured");

// Test 2 cameras (Player 1 & Player 2)
cam2 = undefined;

split_screen = false;

// Pointer
pointer = false;
pointer_x = 0;
pointer_y = 0;

zoom_mode = 0;
zoom_text = cam1.get_zoom_amount();

speed_mode = 1;

game_res = 2;
gui_hires = false;
gui_res = 1;
gui_hires_scale = 6; //how much bigger the hires font is than the pixel one

resolutions = [
	{w:400, h:400}, //1:1
	{w:500, h:250}, //2:1
	{w:320, h:180}, //16:9
	{w:640, h:360},
	{w:1280, h:720},
	{w:1920, h:1080},
	{w:2560, h:1440},
];

gui_resolutions = [
	{w:320, h:180}, //16:9
	{w:640, h:360},
	{w:1280, h:720},
];

stanncam_debug_set_draw_zones(true);