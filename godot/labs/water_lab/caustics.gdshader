shader_type canvas_item;
render_mode blend_add, unshaded;
// Caustics ray grid (the Clearwater / Evan Wallace method, our own code): each
// grid vertex is a sun ray through the water surface, moved to where it lands
// on the floor. The fragment compares the grid's original area with its
// landed area: where rays bunch up the floor gets brighter. Drawn once per
// colour channel with a slightly different refraction strength (dispersion).
#include "res://labs/water_lab/water_common.gdshaderinc"
uniform vec3 mask = vec3(1.0, 0.0, 0.0);
uniform float ior_k = 1.0;
uniform vec2 vp_size = vec2(195.0, 422.0);
uniform float gain = 0.5;
uniform float focus = 1.0;
varying vec2 src;

void vertex() {
	src = VERTEX;
	vec2 uv = VERTEX / vp_size;
	vec2 g = surf_grad(clamp(uv, 0.0, 1.0), uv_to_p(uv));
	vec2 off = p_to_uv_delta(-g * focus * depth * ior_k);
	VERTEX = (uv + off) * vp_size;
}

void fragment() {
	vec2 a = dFdx(src);
	vec2 b = dFdy(src);
	float area = abs(a.x * b.y - a.y * b.x);
	float I = min(area, 4.0) * gain;
	COLOR = vec4(mask * I, 1.0);
}
