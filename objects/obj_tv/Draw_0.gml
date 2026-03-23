draw_self();
shader_set(sh_tv);
var _surface_extra = tv.get_surface_extra();
if (surface_exists(_surface_extra)) { draw_surface(_surface_extra, x + 4, y + 4); }
shader_reset();
