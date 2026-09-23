shader_type canvas_item;
render_mode unshaded;
#include "res://shaders/bowl_common.gdshaderinc"

uniform vec2 res = vec2(390.0, 844.0);
uniform vec2 center = vec2(195.0, 422.0);
uniform float radius = 200.0;
uniform float time = 0.0;
uniform float warmth = 0.0;

void fragment() {
	vec2 px = UV * res;
	vec2 d = (px - center) / radius;
	float r = length(d);
	// Pastel periwinkle water, brighter toward the light (upper right) and the centre.
	vec3 deep = vec3(0.63, 0.64, 0.9);
	vec3 lite = vec3(0.84, 0.85, 0.99);
	float g = clamp(1.0 - r * 0.55 + 0.18 * (d.x - d.y) * 0.5, 0.0, 1.0);
	vec3 col = mix(deep, lite, g);
	col = mix(col, vec3(0.9, 0.84, 0.95), warmth * 0.25 * g);
	// Soft drifting light through the glass.
	float l1 = bfbm(d * 1.6 + vec2(time * 0.02, -time * 0.015));
	float l2 = bfbm(d * 3.2 - vec2(time * 0.03, time * 0.01) + 4.0);
	col *= 0.94 + 0.1 * smoothstep(0.35, 0.8, l1) + 0.05 * smoothstep(0.5, 0.9, l2);
	// Bowl floor curvature: a pale band inside the rim and a shaded lip.
	float band = exp(-pow((r - 0.9) / 0.06, 2.0));
	col += vec3(0.08, 0.08, 0.1) * band;
	col *= 1.0 - 0.1 * smoothstep(0.93, 1.0, r) * step(r, 1.0);
	// Outside the bowl: the same pastel, a touch deeper and flatter.
	vec3 outside = mix(vec3(0.66, 0.67, 0.9), vec3(0.78, 0.79, 0.97), clamp(1.2 - r * 0.4, 0.0, 1.0));
	col = mix(col, outside, smoothstep(1.0, 1.01, r));
	COLOR = vec4(col, 1.0);
}
