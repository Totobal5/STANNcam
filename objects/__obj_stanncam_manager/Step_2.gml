/// @description Steps all stanncams in the room and checks for window resizing and debug overlay toggling.
// Updates all stanncams in the room every step.
var _stanncams = __get_stanncams();
if (array_length(_stanncams) == 0)
{
    if (!__warned_no_cameras)
    {
        __stanncam_error($"Manager Step: No cameras registered in StanncamConfig().stanncams");
        __warned_no_cameras = true;
    }
}
else
{
    if (__warned_no_cameras)
    {
        __stanncam_alert($"Manager Step: Cameras detected again ({array_length(_stanncams)})");
        __warned_no_cameras = false;
    }
    array_foreach(_stanncams, __stanncams_step);
}

// Constantly checks if the window is being resized and changes the resolution to match
__check_window_resize();

// Toggles the debug overlay when the debug view key is pressed, and syncs the overlay if it's open
if (STANNCAM_DBGVIEW)
{
    if (keyboard_check_pressed(STANNCAM_DBGVIEW_KEY) )
    {
        if (is_debug_overlay_open() )
        {
			show_debug_overlay(false);
            stanncam_debug_destroy_overlay();
        }
        else
        {
			show_debug_overlay(true);
            stanncam_debug_create_overlay();
        }
    }
	
    if (dbg_view_exists("STANNcam Manager"))
    {
        stanncam_debug_sync_overlay();
    }
}