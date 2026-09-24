shader_type canvas_item;
render_mode unshaded, blend_disabled;
// GPU ripple sim (replaces the GDScript loop, which cost ~200 ms a frame).
// State texture: R = height now, G = height one step ago. Two steps per frame
// of the discrete wave equation, same update as before:
//   next = (sum of 4 neighbours * 0.5 - prev) * damp
uniform sampler2D state : filter_nearest, repeat_disable;
uniform vec2 grid = vec2(96.0, 208.0);
uniform float damp = 0.985;
uniform vec4 drops[8]; // xy: uv, z: amount, w: radius in cells
uniform int n_drops = 0;

float h0(vec2 c) { return texture(state, (c + 0.5) / grid).r; }
float hp(vec2 c) { return texture(state, (c + 0.5) / grid).g; }
bool edge(vec2 c) { return c.x < 1.0 || c.y < 1.0 || c.x > grid.x - 2.0 || c.y > grid.y - 2.0; }

// first step at cell c (with drops), zero at the rim
float step1(vec2 c) {
	if (edge(c)) { return 0.0; }
	float sum = h0(c + vec2(1.0, 0.0)) + h0(c - vec2(1.0, 0.0)) + h0(c + vec2(0.0, 1.0)) + h0(c - vec2(0.0, 1.0));
	float n = (sum * 0.5 - hp(c)) * damp;
	for (int i = 0; i < 8; i++) {
		if (i >= n_drops) { break; }
		vec2 d = (c + 0.5) - drops[i].xy * grid;
		n -= drops[i].z * exp(-dot(d, d) / (drops[i].w * drops[i].w));
	}
	return n;
}

// two steps per frame, like the old CPU path, in one pass (5x5 stencil)
void fragment() {
	vec2 cell = floor(UV * grid);
	float a = step1(cell);
	float sum = step1(cell + vec2(1.0, 0.0)) + step1(cell - vec2(1.0, 0.0)) + step1(cell + vec2(0.0, 1.0)) + step1(cell - vec2(0.0, 1.0));
	float b = (sum * 0.5 - h0(cell)) * damp;
	if (edge(cell)) { b = 0.0; a = 0.0; }
	COLOR = vec4(b, a, 0.0, 1.0);
}
