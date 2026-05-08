/// @desc Draws the zone if debug mode is on and the camera is set to draw zones.
if (STANNCAM_DRAW_DEBUG)
{
	if (StanncamConfig().draw_zones)
	{
		draw_self();
	}
}