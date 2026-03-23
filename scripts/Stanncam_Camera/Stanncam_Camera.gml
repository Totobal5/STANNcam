/// @description creates a new stanncam
/// @param {Real} [x=0] - X position
/// @param {Real} [y=0] - Y position
/// @param {Real} [width=StanncamConfig().game_w]
/// @param {Real} [height=StanncamConfig().game_h]
/// @param {Bool} [surface_extra_on=false] - use surface_extra in regular draw events
/// @param {Bool} [smooth_draw=true] - use fractional camera position when drawing
function Stanncam(_x=0, _y=0, _width=StanncamConfig().game_w, _height=StanncamConfig().game_h, _surface_extra_on=false, _smooth_draw=true) constructor
{
	#region Init
	
	// Whenever a new cam is created number_of_cams gets incremented
	with (StanncamConfig() )
	{
		other.cam_id = number_of_stanncams;
		stanncams[other.cam_id] = other;
		++number_of_stanncams;
	}
	
	// Checks if there are already 8 cameras.
	if (cam_id == 8)
	{
		__stanncam_error("There can only be a maximum of 8 cameras.");
	}
	
	/// @ignore Game Maker camera
	__camera = camera_create();
	view_camera[cam_id] = __camera;

	#endregion

	#region Variables
	
	/// @ignore
	// The first camera uses the application surface
	__use_app_surface = (cam_id == 0);
	
	/// @ignore
	__x = _x;
	/// @ignore
	__y = _y;
	
	/// @ignore
	__width = _width;
	/// @ignore
	__height = _height;
	
	/// @ignore
	// Offset the camera from whatever it's looking at.
	__offset_x = 0;
	/// @ignore
	__offset_y = 0;
	
	/// @ignore
	__follow = noone;
	
	// The extra surface is only necessary if you are drawing the camera recursively in the room.
	// Like a TV screen, where it can capture itself.
	/// @ignore
	__surface_extra_on = _surface_extra_on;
	
	// How fast the camera follows an instance from 0-1
	/// @ignore
	__spd = 1;
	
	// If camera should be constrained to the room size.
	/// @ignore
	__room_constrain = false;
	
	// The camera bounding box that the followed instance can move within before the camera starts moving.
	/// @ignore
	__bounds_w = 20;
	/// @ignore
	__bounds_h = 20;
	/// @ignore
	__bounds_dist_w = 0;
	/// @ignore
	__bounds_dist_h = 0;
	
	// Whether to use fractional camera position when drawing camera contents.
	// Otherwise it will be snapped to the nearest integer.
	/// @ignore
	__smooth_draw = _smooth_draw;
	/// @ignore
	__x_frac = 0;
	/// @ignore
	__y_frac = 0;
	
	// Which animation curves to use for movement/zoom/size/offset animations.
	/// @ignore
	__anim_curve_move = stanncam_ac_ease;
	/// @ignore
	__anim_curve_zoom = stanncam_ac_ease;
	/// @ignore
	__anim_curve_size = stanncam_ac_ease;
	/// @ignore
	__anim_curve_offset = stanncam_ac_ease;
	
	/// @ignore
	__surface = -1;
	/// @ignore
	__surface_extra = -1;
	/// @ignore
	__surface_special = -1;
	
	/// @ignore
	__debug_draw_on = false;
	
	/// @ignore
	__destroyed = false;
	
	
	// Zone constrain.
	// Last list added to array is the active list of zones.
	/// @ignore
	__zone_lists_max = 4;
	/// @ignore
	__zone_lists = [noone]; // noone means no list of zones, i.e. not constrained.
	
	// How much strength each list of zones has.
	// Previous ones gradually fall to 0 and then get removed.
	/// @ignore
	__zone_lists_strength = [1];
	
	/// @ignore
	__constrain_offset_x = 0;
	/// @ignore
	__constrain_offset_y = 0;
	
	/// @ignore
	__constrain_frac_x = 0;
	/// @ignore
	__constrain_frac_y = 0;
	
	/// @ignore
	__constrain_spd = 0.1;
	
	/// @ignore
	__paused = false;
	
	#region Animation variables
	
	// Moving.
	/// @ignore
	__moving = false;
	/// @ignore
	__xStart = __x;
	/// @ignore
	__yStart = __y;
	/// @ignore
	__xTo = __x;
	/// @ignore
	__yTo = __y;
	/// @ignore
	__duration = 0;
	/// @ignore
	__t = 0;
	
	// Width & height.
	/// @ignore
	__size_change = false;
	/// @ignore
	__wStart = __width;
	/// @ignore
	__hStart = __height;
	/// @ignore
	__wTo = __width;
	/// @ignore
	__hTo = __height;
	/// @ignore
	__dimen_duration = 0;
	/// @ignore
	__dimen_t = 0;
	
	// Offset.
	/// @ignore
	__offset = false;
	/// @ignore
	__offset_xStart = 0;
	/// @ignore
	__offset_yStart = 0;
	/// @ignore
	__offset_xTo = 0;
	/// @ignore
	__offset_yTo = 0;
	/// @ignore
	__offset_duration = 0;
	/// @ignore
	__offset_t = 0;
	
	// Zoom.
	/// @ignore
	__zoom_amount = 1;
	
	/// @ignore
	__zooming = false;
	/// @ignore
	__t_zoom = 0;
	/// @ignore
	__zoomStart = 0;
	/// @ignore
	__zoomTo = 0;
	/// @ignore
	__zoom_duration = 0;
	
	// Screen shake.
	/// @ignore
	__shake_length = 0;
	/// @ignore
	__shake_magnitude = 0;
	/// @ignore
	__shake_time = 0;
	/// @ignore
	__shake_x = 0;
	/// @ignore
	__shake_y = 0;
	
	__check_surface();
	__check_viewports();
	set_size(__width, __height);
	
	#endregion
	
	#endregion

	#region Methods
	
	/// @description gets called every step
	/// @ignore
	static __step = function()
	{	
		// Camera doesn't update if paused
		if (get_paused()) { exit; }
		
		#region Moving
		if (instance_exists(__follow))
		{
			// Update destination.
			__xTo = __follow.x;
			__yTo = __follow.y;
			
			var _x_dist = __xTo - __x;
			var _y_dist = __yTo - __y;
			
			__bounds_dist_w = (max(__bounds_w, abs(_x_dist)) - __bounds_w) * sign(_x_dist);
			__bounds_dist_h = (max(__bounds_h, abs(_y_dist)) - __bounds_h) * sign(_y_dist);
			
			__bounds_dist_w = floor((__bounds_dist_w / 0.01) + 0.99) * 0.01;
			__bounds_dist_h = floor((__bounds_dist_h / 0.01) + 0.99) * 0.01;
			
			// Update camera position.
			__x += __bounds_dist_w * __spd;
			__y += __bounds_dist_h * __spd;
		
		}
		else if (__moving)
		{
			// Gradually moves camera into position based on duration.
			__x = __anim_curve(__t, __xStart, __xTo, __duration, __anim_curve_move);
			__y = __anim_curve(__t, __yStart, __yTo, __duration, __anim_curve_move);

			__t = min(__t + 1, __duration);
			
			if (__t >= __duration)
			{
				__moving = false;
				__x = __xTo;
				__y = __yTo;
			}
		}
		
		if (!__smooth_draw)
		{
			__x = round(__x);
			__y = round(__y);
		}
		
		#endregion
		
		#region Zone Constrain
		if (instance_exists(__follow))
		{
			var _zone_list = ds_list_create();
			var _zone_count = instance_position_list(__follow.x, __follow.y, obj_stanncam_zone, _zone_list, false);
			if (_zone_count != 0)
			{
				
				// Adds included zones to list.
				for (var j = 0; j < _zone_count; j++)
				{
					var _zone = _zone_list[| j];
					var _included_zones_count = array_length(_zone.included_zones);
					if (_included_zones_count > 0)
					{
						
						for (var i = 0; i < _included_zones_count; i++)
						{
							var _included_zone = _zone.included_zones[i];
							
							// Included zones are added, unless they're already within the list.
							if (ds_list_find_index(_zone_list, _included_zone) == -1)
							{
								ds_list_add(_zone_list, _included_zone);
							}
						}
					}
				}
			}
			else
			{
				ds_list_destroy(_zone_list);
				_zone_list = noone;
			}
			
			var _active_list = array_last(__zone_lists);
			
			var _active_list_compare = noone;
			if (ds_exists(_active_list, ds_type_list))
			{
				_active_list_compare = ds_list_write(_active_list);
			}
			
			var _zone_list_compare = noone;
			if (ds_exists(_zone_list, ds_type_list))
			{
				_zone_list_compare = ds_list_write(_zone_list);
			}
			
			// If entering a new list of zones, it gets added to zone_lists and previous ones fade out over time.
			if (_active_list_compare != _zone_list_compare)
			{
				array_push(__zone_lists_strength, 0);
				array_push(__zone_lists, _zone_list);

				// Ensures that zone list arrays have a max size.
				if (array_length(__zone_lists) > __zone_lists_max)
				{
					array_shift(__zone_lists_strength);
					
					// If the index being removed is a DS list, destroy it to prevent leaks.
					if (ds_exists(__zone_lists[0], ds_type_list))
					{
						ds_list_destroy(__zone_lists[0]);
					}
					array_shift(__zone_lists);
				}
			}
			
			var _len = array_length(__zone_lists_strength) - 1;
			for (var k = 0; k <= _len; k++)
			{
				if (k != _len)
				{
					__zone_lists_strength[k] = lerp(__zone_lists_strength[k], 0, __constrain_spd);
				}
				else
				{
					__zone_lists_strength[k] = lerp(__zone_lists_strength[k], 1, __constrain_spd);
				}
				
				if (__zone_lists_strength[k] == 0)
				{
					array_delete(__zone_lists_strength, k, 1);
					
					// If the index being removed is a DS list, destroy it to prevent leaks.
					if (ds_exists(__zone_lists[k], ds_type_list))
					{
						ds_list_destroy(__zone_lists[k]);
					}
					array_delete(__zone_lists, k, 1);
					
					_len = array_length(__zone_lists_strength) - 1;
					k--;
				}
			}
		}
		
		#endregion
		
		#region Offset
		if (__offset)
		{
			// Gradually offsets camera based on duration.
			__offset_x = __anim_curve(__offset_t, __offset_xStart, __offset_xTo, __offset_duration, __anim_curve_offset);
			__offset_y = __anim_curve(__offset_t, __offset_yStart, __offset_yTo, __offset_duration, __anim_curve_offset);
			
			__offset_t = min(__offset_t + 1, __offset_duration);

			if (__offset_t >= __offset_duration)
			{
				__offset = false;
				__offset_x = __offset_xTo;
				__offset_y = __offset_yTo;
			}
		}
		#endregion
		
		#region Screen-Shake
		var _shake_x = __shake(__shake_time, __shake_magnitude, __shake_length);
		var _shake_y = __shake(__shake_time, __shake_magnitude, __shake_length);
		__shake_x = _shake_x;
		__shake_y = _shake_y;
		__shake_time++;
		#endregion
		
		#region Zooming
		if (__zooming || __size_change)
		{
			if (__size_change)
			{
				// Gradually resizes camera.
				__width = __anim_curve(__dimen_t, __wStart, __wTo, __dimen_duration, __anim_curve_size);
				__height = __anim_curve(__dimen_t, __hStart, __hTo, __dimen_duration, __anim_curve_size);
				
				__dimen_t = min(__dimen_t + 1, __dimen_duration);

				if (__dimen_t >= __dimen_duration)
				{
					__size_change = false;
					__width = __wTo;
					__height = __hTo;
				}
			}
			
			if (__zooming)
			{
				// Gradually zooms camera.
				__zoom_amount = __anim_curve(__t_zoom, __zoomStart, __zoomTo, __zoom_duration, __anim_curve_zoom);
				
				__t_zoom = min(__t_zoom + 1, __zoom_duration);

				if(__t_zoom >= __zoom_duration) {
					__zooming = false;
					__zoom_amount = __zoomTo;
				}
			}
		}
		#endregion
		
		__update_view_pos();
		__update_view_size();
	}

	#region Dynamic functions
	
	/// @description returns a clone of the stanncam
	/// @returns {Struct.stanncam}
	static clone = function()
	{
		var _clone = new Stanncam(__x, __y, __width, __height);
		_clone.__offset_x = __offset_x;
		_clone.__offset_y = __offset_y;
		_clone.__follow = __follow;
		_clone.__surface_extra_on = __surface_extra_on;
		_clone.__spd = __spd;
		_clone.__room_constrain = __room_constrain;
		_clone.__bounds_w = __bounds_w;
		_clone.__bounds_h = __bounds_h;
		_clone.__smooth_draw = __smooth_draw;
		_clone.__anim_curve_move = __anim_curve_move;
		_clone.__anim_curve_zoom = __anim_curve_zoom;
		_clone.__anim_curve_size = __anim_curve_size;
		_clone.__anim_curve_offset = __anim_curve_offset;
		_clone.__debug_draw_on = __debug_draw_on;
		_clone.__paused = __paused;
		
		_clone.__moving = __moving;
		_clone.__xStart = __xStart;
		_clone.__yStart = __yStart;
		_clone.__xTo = __xTo;
		_clone.__yTo = __yTo;
		_clone.__duration = __duration;
		_clone.__t = __t;
		
		_clone.__size_change = __size_change;
		_clone.__wStart = __wStart;
		_clone.__hStart = __hStart;
		_clone.__wTo = __wTo;
		_clone.__hTo = __hTo;
		_clone.__dimen_duration = __dimen_duration;
		_clone.__dimen_t = __dimen_t;
		
		_clone.__offset = __offset;
		_clone.__offset_xStart = __offset_xStart;
		_clone.__offset_yStart = __offset_yStart;
		_clone.__offset_xTo = __offset_xTo;
		_clone.__offset_yTo = __offset_yTo;
		_clone.__offset_duration = __offset_duration;
		_clone.__offset_t = __offset_t;
		
		_clone.__zoom_amount = __zoom_amount;
		
		_clone.__zooming = __zooming;
		_clone.__t_zoom = __t_zoom;
		_clone.__zoomStart = __zoomStart;
		_clone.__zoomTo = __zoomTo;
		_clone.__zoom_duration = __zoom_duration;
		
		return _clone;
	}
	
	/// @description moves the camera to a position over a duration
	/// @param {Real} x
	/// @param {Real} y
	/// @param {Real} [duration=0]
	static move = function(_x, _y, _duration=0)
	{
		if (_duration == 0 && __follow == noone)
		{
			//view position is updated immediately
			__x = _x;
			__y = _y;
            __moving = false;
			__update_view_pos();
		}
		else
		{
			__moving = true;
			__t = 0;
			__xStart = __x;
			__yStart = __y;
			
			__xTo = _x;
			__yTo = _y;
			__duration = _duration;
		}
	}
	
	/// @description sets the camera dimensions
	/// @param {Real} _width
	/// @param {Real} _height
	/// @param {Real} [_duration=0]
	static set_size = function(_width, _height, _duration=0)
	{
		// If duration is 0 the view is updated immediately
		if (_duration == 0)
		{
			__width = _width;
			__height = _height;
			__update_view_size();
		} 
		else
		{
			__size_change = true;
			__dimen_t = 0;
			__wStart = __width;
			__hStart = __height;
			
			__wTo = _width;
			__hTo = _height;
			__dimen_duration = _duration;
		}
	}
	
	/// @description offsets the camera over a duration
	/// @param {Real} offset_x
	/// @param {Real} offset_y
	/// @param {Real} [duration=0]
	static offset = function(_offset_x, _offset_y, _duration=0)
	{
		// If duration is 0 the view is updated immediately.
		if (_duration == 0)
		{
			__offset_x = _offset_x;
			__offset_y = _offset_y;
			__update_view_pos();
		}
		else 
		{
			__offset = true;
			__offset_t = 0;
			__offset_xStart = __offset_x;
			__offset_yStart = __offset_y;
			
			__offset_xTo = _offset_x;
			__offset_yTo = _offset_y;
			__offset_duration = _duration;
		}
	}
	
	/// @description zooms the camera over a duration
	/// @param {Real} zoom
	/// @param {Real} [duration=0]
	static zoom = function(_zoom, _duration=0)
	{
		// If duration is 0 the view is updated immediately.
		if (_duration == 0)
		{
			__zoom_amount = _zoom;
			
			if (!get_paused()) { __update_view_size(); }
		}
		else 
		{
			__zooming = true;
			__t_zoom = 0;
			__zoomStart = __zoom_amount;
			__zoomTo = _zoom;
			__zoom_duration = _duration;
		}
	}

	/// @description sets follow target
	/// @param {Id.Instance|Noone} _follow
	static set_follow = function(_follow)
	{
		__follow = _follow;
		return self;
	}

	/// @description gets follow target
	/// @returns {Id.Instance|Noone}
	static get_follow = function()
	{
		return __follow;
	}
	
	/// @description makes the camera shake
	/// @param {Real} magnitude
	/// @param {Real} duration - duration in frames
	static shake_screen = function(_magnitude, _duration)
	{
		__shake_magnitude = _magnitude;
		__shake_length = _duration;
		__shake_time = 0;
	}
	
	/// @description changes the speed of the camera
	/// @param {Real} speed - how fast the camera follows from 0-1
	static set_speed = function(_spd)
	{
		__spd = _spd;
		return self;
	}

	/// @description gets camera follow speed
	/// @returns {Real}
	static get_speed = function()
	{
		return __spd;
	}

	/// @description sets follow bounds size
	/// @param {Real} _bounds_w
	/// @param {Real} _bounds_h
	static set_bounds = function(_bounds_w, _bounds_h)
	{
		__bounds_w = _bounds_w;
		__bounds_h = _bounds_h;
		return self;
	}

	/// @returns {Real}
	static get_bounds_width = function()
	{
		return __bounds_w;
	}

	/// @returns {Real}
	static get_bounds_height = function()
	{
		return __bounds_h;
	}

	/// @returns {Real}
	static get_bounds_dist_w = function()
	{
		return __bounds_dist_w;
	}

	/// @returns {Real}
	static get_bounds_dist_h = function()
	{
		return __bounds_dist_h;
	}

	/// @description sets room constrain state
	/// @param {Bool} _room_constrain
	static set_room_constrain = function(_room_constrain)
	{
		__room_constrain = _room_constrain;
		return self;
	}

	/// @returns {Bool}
	static get_room_constrain = function()
	{
		return __room_constrain;
	}

	/// @returns {Struct.stanncam}
	static toggle_room_constrain = function()
	{
		return set_room_constrain(!__room_constrain);
	}
	
	/// @description sets camera paused state
	/// @param {Bool} _paused
	static set_paused = function(_paused)
	{
		__paused = _paused;
		return self;
	}
	
	/// @description gets camera's paused state
	/// @returns {Bool}
	static get_paused = function()
	{
		return __paused;
	}
	
	/// @description toggles the camera's paused state
	static toggle_paused = function()
	{
		return set_paused(!get_paused() );
	}
	
	/// @description get camera corner x position
	/// @returns {Real}
	static get_x = function()
	{
		var _x = camera_get_view_x(__camera);
		return _x + (__width / 2) * ceil(__zoom_amount - 1);
	}
	
	/// @description get camera corner y position
	/// @returns {Real}
	static get_y = function()
	{
		var _y = camera_get_view_y(__camera);
		return _y + (__height / 2) * ceil(__zoom_amount - 1);
	}

	/// @returns {Struct}
	static get_position = function()
	{
		return { x : __x, y : __y };
	}

	/// @returns {Struct}
	static get_dimensions = function()
	{
		return { width : __width, height : __height };
	}

	/// @returns {Real}
	static get_width = function()
	{
		return __width;
	}

	/// @returns {Real}
	static get_height = function()
	{
		return __height;
	}

	/// @returns {Id.Surface}
	static get_surface_extra = function()
	{
		return __surface_extra;
	}

	/// @returns {Bool}
	static get_smooth_draw = function()
	{
		return __smooth_draw;
	}

	/// @param {Bool} _smooth_draw
	static set_smooth_draw = function(_smooth_draw)
	{
		__smooth_draw = _smooth_draw;
		return self;
	}

	/// @returns {Struct.stanncam}
	static toggle_smooth_draw = function()
	{
		return set_smooth_draw(!__smooth_draw);
	}

	/// @returns {Real}
	static get_zoom_amount = function()
	{
		return __zoom_amount;
	}

	/// @param {Real} _zoom_amount
	static set_zoom_amount = function(_zoom_amount)
	{
		__zoom_amount = _zoom_amount;
		return self;
	}

	/// @returns {Bool}
	static get_debug_draw = function()
	{
		return __debug_draw_on;
	}

	/// @param {Bool} _debug_draw
	static set_debug_draw = function(_debug_draw)
	{
		__debug_draw_on = _debug_draw;
		return self;
	}

	/// @returns {Struct.stanncam}
	static toggle_debug_draw = function()
	{
		return set_debug_draw(!__debug_draw_on);
	}

	/// @returns {Real}
	static get_x_frac = function()
	{
		return __x_frac;
	}

	/// @returns {Real}
	static get_y_frac = function()
	{
		return __y_frac;
	}
	
	/// @description gets the mouse x position within room relative to the camera
	/// @returns {Real}
	static get_mouse_x = function()
	{
		var _mouse_x = view_to_room_x((window_mouse_get_x() - stanncam_ratio_compensate_x()) / stanncam_get_res_scale_x());
		_mouse_x += __constrain_frac_x + __constrain_offset_x;
		
		return _mouse_x;
	}
	
	/// @description gets the mouse y position within room relative to the camera
	/// @returns {Real}
	static get_mouse_y = function()
	{
		var _mouse_y = view_to_room_y((window_mouse_get_y() - stanncam_ratio_compensate_y()) / stanncam_get_res_scale_y());
		_mouse_y += __constrain_frac_y + __constrain_offset_y;
		
		return _mouse_y;
	}
	
	/// @description returns the room x position as the position on the gui relative to camera
	/// @param {Real} x
	/// @returns {Real}
	static room_to_gui_x = function(_x)
	{
		var _gui_x = _x - __constrain_offset_x - __constrain_frac_x;
		_gui_x = room_to_view_x(_gui_x) * stanncam_get_gui_scale_x() - 1;

		return _gui_x;
	}
	
	/// @description returns the room y position as the position on the gui relative to camera
	/// @param {Real} y
	/// @returns {Real}
	static room_to_gui_y = function(_y)
	{
		var _gui_y = _y - __constrain_offset_y - __constrain_frac_y;
		_gui_y = room_to_view_y(_gui_y) * stanncam_get_gui_scale_y() - 1;

		return _gui_y;
	}

	/// @description returns list of active zones the followed instance is within, noone if outside, or no instance is followed
	/// @returns {Id.Instance|Noone}
	static get_active_zone = function()
	{
		if (__follow == noone) return noone;
		
		var _active_zones = array_last(__zone_lists);
		
		if (_active_zones != noone) { return _active_zones; }

		return noone;
	}
	
	/// @description returns the room x position as the position on the display relative to camera
	/// @param {Real} x
	/// @returns {Real}
	function room_to_display_x(_x)
	{
		var _display_x = _x - __constrain_offset_x - __constrain_frac_x;
		return room_to_view_x(_display_x) * stanncam_get_res_scale_x() + stanncam_ratio_compensate_x() - 1;
	}

	/// @description returns the room y position as the position on the display relative to camera
	/// @param {Real} y
	/// @returns {Real}
	function room_to_display_y(_y)
	{
		var _display_y = _y - __constrain_offset_y - __constrain_frac_y;
		return room_to_view_y(_display_y) * stanncam_get_res_scale_y() + stanncam_ratio_compensate_y() - 1;
	}
	
	/// @description returns if the position is outside of camera bounds
	/// @param {Real} x
	/// @param {Real} y
	/// @param {Real} [margin=0]
	/// @returns {Bool}
	static out_of_bounds = function(_x, _y, _margin=0)
	{
		_x = room_to_view_x(_x);
		_y = room_to_view_y(_y);
		
		// Uses camera view bounding box.
		var _col =
			(_x < (_margin)) ||
			(_y < (_margin)) ||
			(_x > (__width - _margin)) ||
			(_y > (__height - _margin)
		);
		
		return _col;
	}
	
	/// @description marks the stanncam as destroyed
	static destroy = function()
	{
		camera_destroy(__camera);
		with (StanncamConfig() )
		{
			stanncams[other.cam_id] = -1;
			--number_of_stanncams;
		}

		view_camera[cam_id] = -1;
		view_visible[cam_id] = false;
		__follow = noone;

		if (surface_exists(__surface)) surface_free(__surface);
		if (surface_exists(__surface_extra)) surface_free(__surface_extra);
		if (surface_exists(__surface_special)) surface_free(__surface_special);
		__destroyed = true;
	}
	
	/// @returns {Bool}
	static is_destroyed = function()
	{
		return __destroyed;
	}

	/// @description room position to camera view
	/// @param {Real} [x]
	static room_to_view_x = function(_x)
	{
		var _zoom = __get_zoom();
		var _zoom_offset = (__width * (1 - _zoom)) / 2;
		
		_x -= _zoom_offset + (__x - __width / 2) - 1;
		_x /= _zoom;
		
		return _x;
	}
	
	/// @description camera view to room position
	/// @param {Real} [x]
	static view_to_room_x = function(_x)
	{
		var _zoom = __get_zoom();
		var _zoom_offset = (__width * (1 - _zoom)) / 2;
		
		_x *= _zoom;
		_x += _zoom_offset + (__x - __width / 2) - 1;
		
		return _x;
	}
	
	/// @description room position to camera view
	/// @param {Real} [y]
	static room_to_view_y = function(_y)
	{
		var _zoom = __get_zoom();
		var _zoom_offset = (__height * (1 - _zoom)) / 2;
		
		_y -= _zoom_offset + (__y - __height / 2) - 1;
		_y /= _zoom;
		
		return _y;
	}
	
	/// @description camera view to room position
	/// @param {Real} [y]
	static view_to_room_y = function(_y)
	{
		var _zoom = __get_zoom();
		var _zoom_offset = (__height * (1 - _zoom)) / 2;
		
		_y *= _zoom;
		_y += _zoom_offset + (__y - __height / 2) - 1;
		
		return _y;
	}
	#endregion
	
	#region Internal functions

	/// @ignore
	/// @param {Real} _time
	/// @param {Real} _magnitude
	/// @param {Real} _duration
	/// @returns {Real}
	static __shake = function(_time, _magnitude, _duration)
	{
		var _amount = max(0, (_duration - _time) / _duration);
		return random_range(-_magnitude, _magnitude) * _amount;
	}

	/// @ignore
	/// @param {Real} _t
	/// @param {Real} _start
	/// @param {Real} _finish
	/// @param {Real} _dur
	/// @param {Asset.GMAnimCurve} [_anim_curve=stanncam_ac_ease]
	/// @returns {Real}
	static __anim_curve = function(_t, _start, _finish, _dur, _anim_curve=stanncam_ac_ease)
	{
		if (_dur == 0) { return _finish; }

		var _channel = animcurve_get_channel(_anim_curve, 0);
		var _val = animcurve_channel_evaluate(_channel, (_t / _dur));
		return lerp(_start, _finish, _val);
	}
	
	/// @ignore
	/// @description gets zoom value, snapped if smooth draw is off
	static __get_zoom = function()
	{
		if (__smooth_draw) return __zoom_amount;
		else return floor((__zoom_amount / 0.02) + 0.999) * 0.02;
	}
	
	/// @ignore
	/// @description enables viewports and sets viewports size
	static __check_viewports = function()
	{
		view_visible[cam_id] = true;
		view_camera[cam_id] = __camera;
		__check_surface();
		__update_view_size(true);
	}
	
	/// @ignore
	/// @description checks if surface & surface_extra exists and else creates it
	static __check_surface = function()
	{
		if (__use_app_surface)
		{
			__surface = application_surface;
		} 
		else 
		{
			if (!surface_exists(__surface)) { __surface = surface_create(__width, __height); }
		}
		
		if (__surface_extra_on && !surface_exists(__surface_extra))
		{
			__surface_extra = surface_create(__width, __height);
		}
	}
	
	/// @ignore
	/// @description clears the surface
	static __predraw = function()
	{
		__check_surface();

		surface_set_target(__surface);
		draw_clear_alpha(c_black, 0);
		surface_reset_target();
		view_set_surface_id(cam_id, __surface);
	}
	
	/// @ignore
	/// @description postdraw drawing
	static __postdraw = function()
	{
		if (__surface_extra_on)
		{
			var _left = 0;
			var _top = 0;
			
			var _zoom_whole = ceil(__zoom_amount - 1);
			_left -= (__width / 2) * _zoom_whole;
			_top -= (__height / 2) * _zoom_whole;
			
			surface_copy(__surface_extra, _left, _left, __surface);
		}
	}
	
	/// @ignore
	/// @description updates the view size
	/// @param {Bool} [force=false]
	static __update_view_size = function(_force=false)
	{
		// If zooming out the surface is scaled up
		var _zoom = ceil(__zoom_amount);
		var _new_width = __width * _zoom;
		var _new_height = __height * _zoom;
		
		// Smooth drawing needs the surface to be 1 pixel wider and taller to remove edge warping
		if (__smooth_draw)
		{
			_new_width += 1;
			_new_height += 1;
		}
		
		// Only runs if the size has changed (unless forced, used by __check_viewports to initialize)
		if (_force || surface_get_width(__surface) != _new_width || surface_get_height(__surface) != _new_height)
		{
			__check_surface();
			surface_resize(__surface,	_new_width, _new_height);
			camera_set_view_size(__camera, _new_width, _new_height);
		}
	}
	
	/// @ignore
	/// @description updates the view position
	static __update_view_pos = function()
	{	
		var _cam_x = __x;
		var _cam_y = __y;
		var _cam_width = __width;
		var _cam_height = __height;
		var _smooth_draw = __smooth_draw;
		var _zoom_amount = __zoom_amount;
		var _half_width = _cam_width * 0.5;
		var _half_height = _cam_height * 0.5;

		// Offsetting is whole numbers with smooth_draw off.
		var _offset_x = _smooth_draw ? __offset_x : round(__offset_x);
		var _offset_y = _smooth_draw ? __offset_y : round(__offset_y);
		
		// Update camera view
		var _new_x = _cam_x + _offset_x - _half_width + __shake_x;
		var _new_y = _cam_y + _offset_y - _half_height + __shake_y;
		
		var _zoom_whole = ceil(_zoom_amount - 1);
		_new_x -= _half_width * _zoom_whole;
		_new_y -= _half_height * _zoom_whole;
		
		// Round to nearest 0.01 decimal
		_new_x = floor(_new_x / 0.01 + 0.99) * 0.01;
		_new_y = floor(_new_y / 0.01 + 0.99) * 0.01;
		
		__x_frac = frac(_new_x);
		__y_frac = frac(_new_y);

		if (__x_frac < 0) { __x_frac++; }
		if (__y_frac < 0) { __y_frac++; }
		
		_new_x = floor(_new_x);
		_new_y = floor(_new_y);
		
		#region Constraining
		
		var _constrain_offset_x = array_create(array_length(__zone_lists), 0);
		var _constrain_offset_y = array_create(array_length(__zone_lists), 0);
		
		var _view_left    = view_to_room_x(0) + 1;
		var _view_right   = view_to_room_x(_cam_width) + 1;
		var _view_top     = view_to_room_y(0) + 1;
		var _view_bottom  = view_to_room_y(_cam_height) + 1;
		
		_view_left += _offset_x;
		_view_right += _offset_x;
		_view_top += _offset_y;
		_view_bottom += _offset_y;
		
		// Zone constraining.
		var _zone_len = array_length(__zone_lists);
		for (var l = 0; l < _zone_len; l++)
		{
			if (__zone_lists[l] != noone)
			{	
				var _zone_left   = undefined;
				var _zone_right  = undefined;
				var _zone_top    = undefined;
				var _zone_bottom = undefined;
				
				// Loop through every zone to find the narrowest constraint edges relative to camera position.
				for (var z = 0; z < ds_list_size(__zone_lists[l]); z++)
				{
					var _zone = __zone_lists[l][| z];

					// Room transitions can leave stale IDs in cached zone lists; prune them before access.
					if (_zone == noone || !instance_exists(_zone) )
					{
						ds_list_delete(__zone_lists[l], z);
						z--;

						continue;
					}

					// If distance from this zone edge to center is shorter than previous, it takes over.
					if (_zone.left )
					{ 
						if (_zone_left == undefined || _zone.bbox_left < _zone_left)
						{
							_zone_left = _zone.bbox_left;
						}
					}
					
					if (_zone.right)
					{
						if (_zone_right == undefined || _zone.bbox_right > _zone_right)
						{
							_zone_right = _zone.bbox_right;
						}
					}

					if (_zone.top)
					{
						if (_zone_top == undefined || _zone.bbox_top < _zone_top)
						{
							_zone_top = _zone.bbox_top;
						}
					}

					if (_zone.bottom)
					{
						if (_zone_bottom == undefined || _zone.bbox_bottom > _zone_bottom)
						{
							_zone_bottom = _zone.bbox_bottom;
						}
					}
				}
				
				// Constrains camera to zones/room bounds
				
				#region Horizontal constraint

				var _zone_center_h = false;
				if (_zone_left != undefined && _zone_right != undefined)
				{
					// If width of zone is narrower than width of camera, constrain to center
					var _zone_width = (_zone_right - _zone_left);
					if ((_view_right - _view_left) > _zone_width)
					{
						var _middle = ((_zone_left + _zone_right) / 2) - 1;
						_constrain_offset_x[l] = _middle - _cam_x - _offset_x;
						_zone_center_h = true;
					}
				}
				
				if (!_zone_center_h && (_zone_left != undefined || _zone_right != undefined))
				{
					// Left zone
					if (_zone_left != undefined) { _constrain_offset_x[l] -= min(_view_left - _zone_left, 0); }
					// Right zone
					if (_zone_right != undefined) { _constrain_offset_x[l] -= max(_view_right - _zone_right, 0); }
				}
				
				#endregion
				
				#region Vertical constraint

				var _zone_center_v = false;
				if (_zone_top != undefined && _zone_bottom != undefined)
				{
					// If height of zone is narrower than height of camera, constrain to center
					var _zone_height = (_zone_bottom - _zone_top);
					if ((_view_bottom - _view_top) > _zone_height)
					{
						var _middle = ((_zone_top + _zone_bottom) / 2) - 1;
						_constrain_offset_y[l] = _middle - _cam_y - _offset_y;
						_zone_center_v = true;
					}
				}
				
				if (!_zone_center_v && (_zone_top != undefined || _zone_bottom != undefined))
				{
					// Top zone
					if (_zone_top != undefined){ _constrain_offset_y[l] -= min(_view_top - _zone_top, 0); }
					// Bottom zone
					if (_zone_bottom != undefined) { _constrain_offset_y[l] -= max(_view_bottom - _zone_bottom , 0); }
				}

				#endregion
			}
		}
		
		__constrain_offset_x = 0;
		__constrain_offset_y = 0;
		
		for (var i = 0; i < array_length(__zone_lists_strength); i++)
		{
			var _strength = __zone_lists_strength[i];
			
			// With smooth draw off, it rounds the constraint transition
			if (!_smooth_draw) { _strength = floor(_strength / 0.01 + 0.99) * 0.01; }
			
			var _offset_x = _constrain_offset_x[i] * _strength;
			var _offset_y = _constrain_offset_y[i] * _strength;

			// When strength is 1, constraint fractions are present regardless of smooth_draw.
			// This keeps constraints correct at all zoom levels.
			if (!_smooth_draw && _strength != 1)
			{
				_offset_x = round(_offset_x);
				_offset_y = round(_offset_y);
			}

			__constrain_offset_x += _offset_x;
			__constrain_offset_y += _offset_y;
		}
		
		if (__room_constrain)
		{
			// Horizontal
			if ((_view_right - _view_left) < room_width)
			{
				__constrain_offset_x = clamp(__constrain_offset_x, -_view_left, room_width - 1 - _view_right);
			} 
			else 
			{
				__constrain_offset_x = (room_width - (_view_right + _view_left)) / 2;
			}
			
			// Vertical
			if ((_view_bottom - _view_top) < room_height)
			{
				__constrain_offset_y = clamp(__constrain_offset_y, -_view_top, room_height - 1 - _view_bottom);
			} 
			else 
			{
				__constrain_offset_y = (room_height - (_view_bottom + _view_top)) / 2;
			}
		}
		
		#region Fractional constraint
		
		__constrain_frac_x = frac(__constrain_offset_x);
		if (__constrain_offset_x > 0)
		{
			__constrain_offset_x = floor(__constrain_offset_x);
		}
		else if (__constrain_offset_x < 0) 
		{
			__constrain_offset_x = ceil(__constrain_offset_x);
		}
		
		__constrain_frac_y = frac(__constrain_offset_y);
		if (__constrain_offset_y > 0)
		{
			__constrain_offset_y = floor(__constrain_offset_y);
		}
		else if (__constrain_offset_y < 0)
		{
			__constrain_offset_y = ceil(__constrain_offset_y);
		}
		
		#endregion
		
		_new_x += __constrain_offset_x;
		_new_y += __constrain_offset_y;
		
		#endregion
		
		camera_set_view_pos(__camera, _new_x, _new_y);
	}
	#endregion

	#region Drawing functions

	/// @description draws debug information
	/// @ignore
	static __debug_draw = function()
	{
		if (__debug_draw_on)
		{
			// Draws camera bounding box
			if (instance_exists(__follow))
			{
				surface_set_target(__surface);
				
				var _pre_color = draw_get_color();
				
				var _x_offset = __smooth_draw ? -__offset_x : -round(__offset_x);
				var _y_offset = __smooth_draw ? -__offset_y : -round(__offset_y);
				
				_x_offset -= __constrain_offset_x;
				_y_offset -= __constrain_offset_y;
				
				var _zoom_whole = ceil(__zoom_amount - 1);
				_x_offset += (__width / 2) * _zoom_whole;
				_y_offset += (__height / 2) * _zoom_whole;
				
				var _x1 = (__width / 2) - __bounds_w + _x_offset;
				var _x2 = (__width / 2) + __bounds_w + _x_offset;
				var _y1 = (__height / 2) - __bounds_h + _y_offset;
				var _y2 = (__height / 2) + __bounds_h + _y_offset;
				draw_set_color(c_white);
				draw_rectangle(_x1, _y1, _x2, _y2, true);
				
				draw_set_color(c_red);
				
				// Top
				if (__bounds_dist_h != 0)
				{
					// Bottom
					if (__bounds_dist_h < 0)
					{
						draw_line(_x1, _y1, _x2, _y1);
					}
					else 
					{
						draw_line(_x1, _y2, _x2, _y2);
					}
				}
				
				// Left
				if (__bounds_dist_w != 0)
				{
					// Right
					if (__bounds_dist_w < 0)
					{
						draw_line(_x1, _y1, _x1, _y2);
					}
					else
					{
						draw_line(_x2, _y1, _x2, _y2);
					}
				}
				
				draw_set_color(_pre_color);
				surface_reset_target();
			}
		}
	}
	
	/// @description draws stanncam
	/// @param {Real} x
	/// @param {Real} y
	/// @param {Real} [scale_x=1]
	/// @param {Real} [scale_y=1]
	static draw = function(_x, _y, _scale_x=1, _scale_y=1)
	{
		__check_surface();
		__debug_draw();

		draw_surf(__surface, _x, _y, _scale_x, _scale_y, 0, 0, __width, __height);
	}
	
	/// @description draws stanncam but without being offset by stanncam_ratio_compensate
	/// @param {Real} x
	/// @param {Real} y
	/// @param {Real} [scale_x=1]
	/// @param {Real} [scale_y=1]
	static draw_no_compensate = function(_x, _y, _scale_x=1, _scale_y=1)
	{
		__check_surface();
		__debug_draw();

		draw_surf(__surface, _x, _y, _scale_x, _scale_y, 0, 0, __width, __height, false);
	}
	
	/// @description draws part of stanncam camera view
	/// @param {Real} x
	/// @param {Real} y
	/// @param {Real} left
	/// @param {Real} top
	/// @param {Real} width
	/// @param {Real} height
	/// @param {Real} [scale_x=1]
	/// @param {Real} [scale_y=1]
	static draw_part = function(_x, _y, _left, _top, _width, _height, _scale_x=1, _scale_y=1)
	{
		__check_surface();
		__debug_draw();

		draw_surf(__surface, _x, _y, _scale_x, _scale_y, _left, _top, _width, _height);
	}
	
	/// @description pass in draw commands, and have them be scaled to match the stanncam
	/// @param {Function} draw_func
	/// @param {Real} x
	/// @param {Real} y
	/// @param {Real} [scale_x=1]
	/// @param {Real} [scale_y=1]
	/// @param {Real} [surf_width=width]
	/// @param {Real} [surf_height=height]
	static draw_special = function(_draw_func, _x, _y, _scale_x=1, _scale_y=1, _surf_width=__width, _surf_height=__height)
	{	
		var _zoom = ceil(__zoom_amount);
		var _surf_width_scaled = _surf_width * _zoom;
		var _surf_height_scaled = _surf_height * _zoom;
		
		if (surface_exists(__surface_special))
		{
			if ((surface_get_width(__surface_special) != _surf_width_scaled) || (surface_get_height(__surface_special) != _surf_height_scaled))
			{
				surface_free(__surface_special);
			}
		}
		
		if (!surface_exists(__surface_special))
		{
			__surface_special = surface_create(_surf_width_scaled, _surf_height_scaled);
		}
		
		surface_set_target(__surface_special);
		draw_clear_alpha(c_black, 0);
		
		var _zoom_whole = ceil(__get_zoom() - 1);
		var _draw_offset_x = (_surf_width / 2) * _zoom_whole;
		var _draw_offset_y = (_surf_height / 2) * _zoom_whole;
		
		// Offsets drawing
		var _prev_matrix = matrix_get(matrix_world);
		var _offset_matrix = matrix_build(_draw_offset_x, _draw_offset_y, 0, 0, 0, 0, 1, 1, 1);
		matrix_set(matrix_world, matrix_multiply(_prev_matrix, _offset_matrix));
		_draw_func();
		// Reset world matrix
		matrix_set(matrix_world, _prev_matrix);
		
		surface_reset_target();
		
		var _x_frac = __constrain_frac_x;
		var _y_frac = __constrain_frac_y;
		
		if (__smooth_draw)
		{
			_x_frac += __x_frac;
			_y_frac += __y_frac;
		}
		
		draw_surf(__surface_special, _x, _y, _scale_x, _scale_y, -_x_frac, -_y_frac, _surf_width, _surf_height);
	}
	
	/// @description draws the supplied surface with the proper size and scaling
	/// @param {Id.Surface} surface
	/// @param {Real} x
	/// @param {Real} y
	/// @param {Real} [scale_x=1]
	/// @param {Real} [scale_y=1]
	/// @param {Real} [left=0]
	/// @param {Real} [top=0]
	/// @param {Real} [width=width]
	/// @param {Real} [height=height]
	/// @param {Bool} [ratio_compensate=true]
	static draw_surf = function(_surface, _x, _y, _scale_x=1, _scale_y=1, _left=0, _top=0, _width=__width, _height=__height, _ratio_compensate=true)
	{
		if (!surface_exists(_surface)) { exit; }
		
		// Offsets position to match display resolution.
		_x *= stanncam_get_res_scale_x();
		_y *= stanncam_get_res_scale_y();
		
		if (_ratio_compensate)
		{
			_x += stanncam_ratio_compensate_x();
			_y += stanncam_ratio_compensate_y();
		}
		
		var _stanncam_config = StanncamConfig();
		var _display_scale_x = _stanncam_config.__display_scale_x;
		var _display_scale_y = _stanncam_config.__display_scale_y;
		
		var _x_frac = __constrain_frac_x;
		var _y_frac = __constrain_frac_y;
		
		if (__smooth_draw)
		{
			_x_frac += __x_frac;
			_y_frac += __y_frac;
		}
		
		var _zoom = __get_zoom();
		_left += (_width * (1 - _zoom)) / 2;
		_top += (_height * (1 - _zoom)) / 2;
		
		var _zoom_whole = ceil(_zoom - 1);
		_left += (_width / 2) * _zoom_whole;
		_top += (_height / 2) * _zoom_whole;
		
		_width *= _zoom;
		_height *= _zoom;
		_scale_x /= _zoom;
		_scale_y /= _zoom;
		
		draw_surface_part_ext(_surface, _left + _x_frac, _top + _y_frac, _width, _height, _x, _y, _display_scale_x * _scale_x, _display_scale_y * _scale_y, -1, 1);
	}
	#endregion

	/// @returns {String}
	static toString = function()
	{
		return $"<Stanncam[{string(cam_id)}] ({string(__width)}, {string(__height)})>";
	}

}
