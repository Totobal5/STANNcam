/// @description gets created by stanncam_init(), orchestrates camera processing events
var _config = StanncamConfig();

// Set the manager instance in the config so stanncams can reference it
_config.manager = id;

/// @ignore Returns the current stanncam array from config.
__get_stanncams = function() {
	return StanncamConfig().stanncams;
}

/// @ignore Used to avoid spamming no-camera alerts.
__warned_no_cameras = false;

/// @ignore Pre-draws all stanncams in the room.
/// @param {Struct.Stanncam} stanncam The stanncam to initialize.
/// @param {Real} index The index of the stanncam in the room.
__stanncams_predraw = function(_stanncam, _index) {
	if (_stanncam != -1) _stanncam.__predraw();
}

/// @ignore Post-draws all stanncams in the room.
/// @param {Struct.Stanncam} stanncam The stanncam to initialize.
/// @param {Real} index The index of the stanncam in the room.
__stanncams_postdraw = function(_stanncam, _index) {
	if (_stanncam != -1) _stanncam.__postdraw();
}

/// @ignore Initializes all stanncams in the room.
/// @param {Struct.Stanncam} stanncam The stanncam to initialize.
/// @param {Real} index The index of the stanncam in the room.
__stanncams_roomstart = function(_stanncam, _index) {
	if(_stanncam != -1)
	{
		__stanncam_alert($"Room start: Initializing camera {_stanncam.cam_id}");
		_stanncam.__check_viewports();
		_stanncam.__step();
		
		// If following something, snap the camera to it on room start
		var _inst = _stanncam.get_follow();
		if (STANNCAM_CONFIG_SNAP_TO_FOLLOW_ON_ROOM_START && instance_exists(_inst))
		{
			__stanncam_alert($"Snapping camera {_stanncam.cam_id} to follow target at ({_inst.x}, {_inst.y})");
			_stanncam.move(_inst.x, _inst.y, 0);
			
			if (STANNCAM_CONFIG_SNAP_TO_ZONE_ON_ROOM_START)
			{
				var _zone_state_length = array_length(_stanncam.__zone_states);
				if (_zone_state_length > 0)
				{
					_stanncam.__zone_states[_zone_state_length - 1].strength = 1;
				}
			}
		}
	}
}

/// @ignore Updates all stanncams in the room every step.
/// @param {Struct.Stanncam} stanncam The stanncam to initialize.
/// @param {Real} index The index of the stanncam in the array.
__stanncams_step = function(_stanncam, _index) {
	if (_stanncam != -1) _stanncam.__step();
}

/// @ignore Constantly checks if the window is being resized and changes the resolution to match
__check_window_resize = method(StanncamConfig(), function() {
	var _is_windowed = (window_mode == STANNCAM_WINDOW_MODE.WINDOWED);
	var _window_width = window_get_width();
	var _window_height = window_get_height();

	if ( _is_windowed && !__switching_window_mode && (__resize_width != _window_width || __resize_height != _window_height) )
	{
		__resize_width = _window_width;
		__resize_height = _window_height;

		if (__resize_width != 0 && __resize_height != 0) { stanncam_set_resolution(__resize_width, __resize_height); }
	}
});