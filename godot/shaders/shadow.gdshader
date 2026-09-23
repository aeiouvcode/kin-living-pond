shader_type canvas_item;
render_mode unshaded;

uniform float strength = 0.4;

void fragment() {
	float part = COLOR.r;
	float edge;
	float a;
	if (part < 0.5) {
		edge = 1.0 - abs(UV.y * 2.0 - 1.0);
		a = smoothstep(0.0, 0.85, edge);
	} else {
		edge = smoothstep(0.0, 0.4, UV.y) * smoothstep(1.0, 0.6, UV.y);
		a = edge * COLOR.g * 0.6 * smoothstep(1.0, 0.3, UV.x);
	}
	COLOR = vec4(0.0, 0.015, 0.02, a * strength);
}
