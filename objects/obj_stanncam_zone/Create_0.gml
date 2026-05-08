/// @description which sides to constrain
left =		true;
top =		true;
right =		true;
bottom =	true;
// The actual sides to constrain will be determined by the child objects based on image_angle.
image_angle = (image_angle mod 360 + 360) mod 360;

if (image_angle mod 90 != 0)
{
	__stanncam_error($"{object_get_name(object_index)} image_angle must be a multiple of 90 degrees, got {image_angle}.");
}

// included zones are used to activate other zones when this zone is active.
included_zones = [];

// Add included zones to the list of included zones, if they exist.
var _included_refs = [included_zone1, included_zone2, included_zone3, included_zone4];
array_foreach(_included_refs, function(_zone_ref, _index) {
	if (instance_exists(_zone_ref))
	{
		if (!array_contains(included_zones, _zone_ref) )
		{
			array_push(included_zones, _zone_ref);
		}
	}
});