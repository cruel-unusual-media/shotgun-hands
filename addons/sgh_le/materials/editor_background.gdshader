shader_type canvas_item;

uniform sampler2D grid_texture : filter_nearest, repeat_enable;
uniform vec2 camera_position;
uniform float camera_zoom = 1.0;

void vertex() {
	// Called for every vertex the material is visible on.
	
}

void fragment() {
	// Called for every pixel the material is visible on.
	//COLOR.r = UV.x * 2.0;
	//COLOR.gb = vec2(0.0);
	vec2 screen_res = 1.0 / SCREEN_PIXEL_SIZE;
	COLOR = texture(grid_texture, ((FRAGCOORD.xy - (screen_res) + camera_position) * 0.02) / camera_zoom);
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
