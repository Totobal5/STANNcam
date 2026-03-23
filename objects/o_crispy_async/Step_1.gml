/// @description Relay Begin Step to the attached async case.

if (is_struct(async_case) && struct_exists(async_case, "OnBeginStep"))
{
	var _on_begin_step = struct_get(async_case, "OnBeginStep");
	if (is_method(_on_begin_step))
	{
		_on_begin_step();
	}
	else
	{
		instance_destroy();
	}
}
else
{
	instance_destroy();
}
