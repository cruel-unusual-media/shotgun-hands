shader_type canvas_item;

void fragment() {
	COLOR.a = ((sin(TIME * 15.0) + 1.0) / 3.0 + 0.3333) * COLOR.a;
}
