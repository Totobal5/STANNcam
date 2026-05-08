/// @ignore [MAJOR.MINOR.PATH]
#macro STANNCAM_VERSION "2.5.4"
/// @ignore
#macro STANNCAM_ALERT true
/// @ignore
#macro STANNCAM_DRAW_DEBUG true
/// @ignore 
#macro STANNCAM_ERROR true
/// @ignore
#macro STANNCAM_STRICT true

/// Config

/// @ignore Let the camera manager open the debug overlay.
#macro STANNCAM_DBGVIEW true
/// @ignore The key need to open the debug overlay. Default is F12.
#macro STANNCAM_DBGVIEW_KEY vk_f12

/// @ignore If a followed object is active at the start of a room, should the camera be snapped to it?
#macro STANNCAM_CONFIG_SNAP_TO_FOLLOW_ON_ROOM_START true
/// @ignore If a followed object is within a constrain zone at start of room, should thee camera be snapped to it?
#macro STANNCAM_CONFIG_SNAP_TO_ZONE_ON_ROOM_START   true


enum STANNCAM_WINDOW_MODE
{
	WINDOWED,
	FULLSCREEN,
	BORDERLESS,
	__SIZE
}

__stanncam_alert("Using STANNcam version " + STANNCAM_VERSION);