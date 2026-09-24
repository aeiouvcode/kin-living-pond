shader_type spatial;
render_mode cull_disabled, blend_mix, depth_draw_opaque, diffuse_burley, specular_schlick_ggx;
// Thin double-sided veil: rays, edges fading to clear, light passing
// through, a faint prismatic edge glint. UV.x root->tip, UV.y across.
uniform float kind = 0.0;
// pond only: the water lab's light net, sampled in screen space so the same
// dappled light that crosses the floor also slides over the fish
uniform sampler2D caus_tex : source_color, filter_linear, repeat_disable;
uniform float caus_amt = 0.0;
uniform float time_s = 0.0;
uniform float swim = 1.0;
uniform float bend = 0.0;
uniform float body_len = 1.0;
uniform float phase = 0.0;
uniform float flutter = 1.0;
uniform float opacity = 0.8;
uniform float alpha_min = 0.0;
uniform float alpha_fresnel = 0.0;
uniform float rim_glow = 1.0;
uniform float pleat = 1.0;
uniform float root_x = 0.0;
uniform float fork = 0.0;
uniform vec3 wave_axis = vec3(0.0, 0.0, 1.0);

float h21(vec2 p) { vec3 q = fract(vec3(p.xyx) * 0.1031); q += dot(q, q.yzx + 33.33); return fract((q.x + q.y) * q.z); }
float vn(vec2 p) { vec2 i = floor(p); vec2 f = fract(p); vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(h21(i), h21(i + vec2(1, 0)), u.x), mix(h21(i + vec2(0, 1)), h21(i + vec2(1, 1)), u.x), u.y); }
float spine_off(float x, float t) {
	float u = clamp((0.35 * body_len - x) / body_len, 0.0, 1.5);
	return (0.06 * u * u * sin(u * 3.2 - t * 3.0) * swim + bend * u * u * 0.6) * body_len;
}
vec3 hue(float t) { return clamp(abs(fract(t + vec3(0.0, 0.667, 0.333)) * 6.0 - 3.0) - 1.0, 0.0, 1.0); }

void vertex() {
	float u = UV.x;
	float t = time_s;
	// Follow the body wave at the root, then lag and ripple like cloth.
	float base = spine_off(root_x, t - u * 0.35);
	float cloth = sin(u * 5.5 - t * 3.2 + phase + UV.y * 2.0) * 0.07 * u * u * flutter
		+ sin(u * 9.0 - t * 4.1 + phase * 1.7 + UV.y * 5.0) * 0.025 * u * flutter;
	VERTEX.z += base * (1.0 + u * 0.8);
	VERTEX += wave_axis * cloth * body_len;
	// pleats: the veil folds along its rays, growing toward the tip
	VERTEX += NORMAL * sin(UV.y * 26.0 + phase) * 0.016 * u * pleat * body_len;
}

void fragment() {
	float u = UV.x;
	float v = UV.y;
	float rays = 0.9 + 0.1 * smoothstep(0.3, 0.9, abs(sin(v * 38.0 + vn(vec2(v * 6.0, u * 2.0)) * 2.0)));
	float rag = 0.86 + 0.1 * vn(vec2(v * 14.0, phase * 3.0)) - fork * exp(-pow((v - 0.5) / 0.14, 2.0));
	// rounded lobe tips
	rag -= 0.12 * pow(abs(v - 0.5) * 2.0, 3.0);
	float edge = smoothstep(1.0, rag, u) * smoothstep(0.0, 0.12, v) * smoothstep(1.0, 0.88, v);
	float a = opacity * edge * mix(1.0, 0.45, u) * rays;
	vec3 col;
	if (kind < 0.5) {
		col = mix(vec3(1.0, 0.82, 0.76), vec3(0.99, 0.98, 1.0), smoothstep(0.0, 0.35, u));
	} else {
		col = mix(vec3(0.02, 0.02, 0.03), vec3(0.05, 0.06, 0.12), u);
		a = min(0.97, a * 1.5);
	}
	float fr = pow(1.0 - abs(dot(NORMAL, VIEW)), 2.0);
	// debug-stage knobs (Hakozaki-style Alpha Intensity / Min / Fresnel)
	// fresnel only thickens the sheet near its rim, not across the middle
	float rim_band = edge * smoothstep(0.55, 0.95, u + abs(v - 0.5) * 0.9);
	a = clamp(max(a + fr * alpha_fresnel * rim_band, alpha_min * edge), 0.0, 1.0);
	// folds: the far side of each pleat reads darker, like stacked layers
	float fold = 0.5 + 0.5 * cos(v * 26.0 + phase);
	col *= mix(1.0, 0.78 + 0.22 * fold, pleat * smoothstep(0.1, 0.6, u));
	a = min(1.0, a * mix(1.0, 0.85 + 0.35 * (1.0 - fold), pleat * u));
	ALBEDO = col * rays;
	ALPHA = a;
	ROUGHNESS = 0.5;
	SPECULAR = 0.3;
	BACKLIGHT = kind < 0.5 ? vec3(0.9, 0.8, 0.78) : vec3(0.1, 0.12, 0.25);
	EMISSION = vec3(1.0, 0.9, 0.85) * fr * alpha_fresnel * rim_band * 0.25 * (kind < 0.5 ? 1.0 : 0.4) + (hue(u * 1.5 + v * 0.7 + fr) * fr * 0.12 * edge + (kind > 0.5 ? vec3(0.2, 0.26, 0.55) * fr * 0.4 : vec3(0.0))) * rim_glow;
	if (caus_amt > 0.0) {
		vec3 cl = texture(caus_tex, SCREEN_UV + NORMAL.xy * 0.01).rgb;
		float up = clamp(NORMAL.z, 0.0, 1.0);
		EMISSION += (ALBEDO * 0.7 + 0.3) * max(cl - 0.08, vec3(0.0)) * 1.6 * caus_amt * up;
	}
}
