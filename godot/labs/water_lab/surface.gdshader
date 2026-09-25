shader_type canvas_item;
// Pond Next surface pass: drawn OVER the 3D fish so they sit under the water.
// Same heightfield and swell as water.gdshader; outputs only what the surface
// adds on top: sun glints, the wobbling sky/blossom reflection, and a faint
// water veil. (The floor pass turns its own glints/reflection off when embedded.)
#include "res://labs/water_lab/water_common.gdshaderinc"
uniform float glint = 1.0;
uniform float refl = 1.0;
uniform float veil = 0.06;

vec2 hash2(vec2 p) {
	p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
	return fract(sin(p) * 43758.5453);
}
float vnz(vec2 p) { vec2 i = floor(p); vec2 f = fract(p); vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash2(i).x, hash2(i + vec2(1, 0)).x, u.x), mix(hash2(i + vec2(0, 1)).x, hash2(i + vec2(1, 1)).x, u.x), u.y); }

void fragment() {
	vec2 uv = UV;
	float aspect = grid.y / grid.x;
	float sc = grid.x / 96.0;
	vec2 p = vec2(uv.x, uv.y * aspect) * 0.5 * sc;
	vec2 grad = surf_grad(uv, p);
	vec3 n = normalize(vec3(-grad, 1.0));
	vec3 L = normalize(vec3(-0.35, -0.55, 0.76));
	vec3 Hh = normalize(L + vec3(0.0, 0.0, 1.0));
	float spread = clamp((fwidth(n.x) + fwidth(n.y)) * 6.0, 0.0, 1.0);
	float shin = mix(900.0, 120.0, spread);
	float sp = pow(max(dot(n, Hh), 0.0), shin) * sqrt(shin / 900.0) * 2.0 * glint;
	vec3 R = reflect(vec3(0.0, 0.0, -1.0), n);
	vec2 rp = uv * vec2(1.0, aspect) + R.xy * 0.9;
	vec3 sky; float cmask; float bough;
	canopy_sky(rp, sky, cmask, bough);
	float fres = min(0.02 + 0.98 * pow(1.0 - n.z, 5.0), 0.3);
	// Over the fish, preserve a hint of the bough without painting the black
	// demekin mauve; the floor keeps the full reflected tree.
	float ra = clamp(fres + 0.04 + 0.26 * cmask + 0.13 * bough, 0.0, 1.0) * refl;
	vec3 veil_col = vec3(0.55, 0.78, 0.8);
	// composite: veil, then reflection, then additive glint folded into alpha
	float a = veil + ra * (1.0 - veil);
	vec3 c = (veil_col * veil * (1.0 - ra) + sky * ra) / max(a, 1e-4);
	float g = clamp(sp, 0.0, 1.0);
	c = mix(c, vec3(1.0, 0.97, 0.9), g);
	a = a + g * (1.0 - a);
	COLOR = vec4(c, a);
}
