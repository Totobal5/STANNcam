/// @description Relay End Step to the attached async case.

if (is_struct(async_case) && struct_exists(async_case, "OnEndStep"))
{
	var _on_end_step = struct_get(async_case, "OnEndStep");
	if (is_method(_on_end_step))
	{
		_on_end_step();
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
