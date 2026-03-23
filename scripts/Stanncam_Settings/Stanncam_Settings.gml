/// @ignore [MAJOR.MINOR.PATH]
#macro STANNCAM_VERSION "2.5.1-toto"
/// @ignore
#macro STANNCAM_ALERT false
/// @ignore 
#macro STANNCAM_ERROR false
/// @ignore
#macro STANNCAM_STRICT false

/// Config

/// @ignore Let the camera manager open the debug overlay.
#macro STANNCAM_DBGVIEW false
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