// Constantly checks if the window is being resized and changes the resolution to match
with (StanncamConfig() )
{
	array_foreach(stanncams, function(_cam) {
		if (_cam != -1) _cam.__step(); 
	} );

    if (window_mode == STANNCAM_WINDOW_MODE.WINDOWED && !__switching_window_mode && (__resize_width != window_get_width() || __resize_height != window_get_height()) )
    {
        __resize_width = window_get_width();
        __resize_height = window_get_height();

        if (__resize_width != 0 && __resize_height != 0) { stanncam_set_resolution(__resize_width, __resize_height); }
    }
}

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