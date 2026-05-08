/// @description constrains opposite sides based on image_angle
event_inherited();

left =      false;
top =       false;
right =     false;
bottom =	false;

switch (image_angle)
{
	case 0:
	case 180:
		left = true;
		right = true;
	break;

	case 90:
	case 270:
		top = true;
		bottom = true;
	break;
}