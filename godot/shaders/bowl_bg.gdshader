shader_type canvas_item;
render_mode unshaded;
#include "res://shaders/bowl_common.gdshaderinc"

uniform vec2 res = vec2(390.0, 844.0);
uniform vec2 center = vec2(195.0, 422.0);
uniform float radius = 200.0;
uniform float time = 0.0;
uniform float warmth = 0.0;
uniform sampler2D sim : filter_nearest, repeat_disable;
uniform vec2 grid = vec2(90.0, 195.0);

// Caustics after Clearwater (MIT, github.com/Aureliengmz/clearwater) and Evan
// Wallace's WebGL Water: light refracted by the surface lands at a shifted
// point, and its brightness is the ratio of the original to the refracted
// area, measured with screen-space derivatives. Each colour channel refracts
// a little differently, which splits the bright lines into soft rainbow edges.
// KIN keeps it pale and calm: a slow living web on the bowl floor, plus rings
// from the ripple sim when you touch the water.
float sdec(vec2 rg) {
	float q = floor(rg.x * 255.0 + 0.5) * 256.0 + floor(rg.y * 255.0 + 0.5);
	return q / 65535.0 * 2.0 - 1.0;
}
float simh(vec2 uv) {
	vec2 g = uv * grid - 0.5;
	vec2 i = floor(g); vec2 f = fract(g); vec2 inv = 1.0 / grid;
	float a = sdec(texture(sim, (i + vec2(0.5, 0.5)) * inv).rg);
	float b = sdec(texture(sim, (i + vec2(1.5, 0.5)) * inv).rg);
	float c = sdec(texture(sim, (i + vec2(0.5, 1.5)) * inv).rg);
	float d = sdec(texture(sim, (i + vec2(1.5, 1.5)) * inv).rg);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}
// Gradient of a gentle sum of travelling waves (curvature-normalised).
vec2 wave_grad(vec2 p, float t) {
	vec2 g = vec2(0.0);
	const int NW = 5;
	vec2 dirs[NW] = vec2[](vec2(0.94, 0.34), vec2(-0.5, 0.87), vec2(0.2, -0.98), vec2(-0.9, -0.44), vec2(0.64, 0.77));
	float fr[NW] = float[](17.0, 23.0, 29.0, 37.0, 46.0);
	float sp[NW] = float[](0.55, 0.7, 0.8, 1.0, 1.15);
	float cu[NW] = float[](0.46, 0.4, 0.34, 0.28, 0.22);
	for (int i = 0; i < NW; i++) {
		float ph = dot(dirs[i], p) * fr[i] + t * sp[i] + float(i) * 1.7;
		g += dirs[i] * cos(ph) * cu[i] / fr[i];
	}
	return g;
}
vec3 caustics(vec2 d, vec2 uv, float t) {
	vec2 g = wave_grad(d, t);
	vec2 e = 1.0 / grid;
	float sx = simh(uv + vec2(e.x, 0.0)) - simh(uv - vec2(e.x, 0.0));
	float sy = simh(uv + vec2(0.0, e.y)) - simh(uv - vec2(0.0, e.y));
	g += vec2(sx, sy) * 0.9;
	vec3 outc;
	float a0 = abs(dFdx(d).x * dFdy(d).y - dFdx(d).y * dFdy(d).x) + 1e-9;
	for (int c = 0; c < 3; c++) {
		float k = 1.0 + (float(c) - 1.0) * 0.07;
		vec2 p = d + g * k;
		vec2 px = dFdx(p); vec2 py = dFdy(p);
		float a1 = abs(px.x * py.y - px.y * py.x) + 1e-9;
		outc[c] = clamp(a0 / a1, 0.0, 3.0);
	}
	return outc;
}

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
	// Caustic light web on the floor, strongest toward the light, fading at the rim.
	vec3 cs = caustics(d, UV, time * 0.9);
	float cmask = (1.0 - smoothstep(0.78, 0.98, r)) * (0.75 + 0.35 * clamp(d.x - d.y, -1.0, 1.0) * 0.5);
	col += vec3(1.0, 0.98, 0.96) * max(cs - 1.0, vec3(0.0)) * 0.085 * cmask;
	col *= 1.0 - 0.025 * cmask * clamp(1.0 - (cs.r + cs.g + cs.b) / 3.0, 0.0, 1.0);
	// Bowl floor curvature: a pale band inside the rim and a shaded lip.
	float band = exp(-pow((r - 0.9) / 0.06, 2.0));
	col += vec3(0.08, 0.08, 0.1) * band;
	col *= 1.0 - 0.1 * smoothstep(0.93, 1.0, r) * step(r, 1.0);
	// Outside the bowl: the same pastel, a touch deeper and flatter.
	vec3 outside = mix(vec3(0.66, 0.67, 0.9), vec3(0.78, 0.79, 0.97), clamp(1.2 - r * 0.4, 0.0, 1.0));
	col = mix(col, outside, smoothstep(1.0, 1.01, r));
	COLOR = vec4(col, 1.0);
}
