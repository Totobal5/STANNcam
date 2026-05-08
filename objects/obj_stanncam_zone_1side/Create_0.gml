/// @description determines which sides of the camera are constrained by this zone, based on its image_angle
event_inherited();

left =		false;
top =		false;
right =		false;
bottom =	false;

switch (image_angle)
{
	case 0:		right =		true; break;
	case 90:	top =		true; break;
	case 180:	left =		true; break;
	case 270:	bottom =	true; break;
}