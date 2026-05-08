/// @description Initializes all stanncams in the room.
view_enabled = true;
var _stanncams = __get_stanncams();
__stanncam_alert($"Room Start: Initializing {array_length(_stanncams)} camera(s)");
array_foreach(_stanncams, __stanncams_roomstart);

__stanncam_update_resolution();