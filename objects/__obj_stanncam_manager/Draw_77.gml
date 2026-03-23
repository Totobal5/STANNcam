/// @description
var _stanncams = StanncamConfig().stanncams;
var _len = array_length(_stanncams);
for (var i = 0; i < _len; ++i)
{
	if (_stanncams[i] == -1) continue;
	_stanncams[i].__postdraw();
}