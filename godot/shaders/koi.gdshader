shader_type canvas_item;
render_mode unshaded;

// Vertex COLOR: r = part (0 body, 1 fin), g = fin opacity, b = eye mask helper.
uniform float seed = 0.0;
uniform vec3 base_col : source_color = vec3(0.94, 0.91, 0.85);
uniform vec3 patch_col : source_color = vec3(0.84, 0.2, 0.08);
uniform vec3 ink_col : source_color = vec3(0.05, 0.05, 0.06);
uniform float patch_amt = 0.5;
uniform float ink_amt = 0.0;
uniform float metallic = 0.0;
uniform float depth = 0.3;
uniform float heading = 0.0;
uniform float fin_tint = 0.0;
uniform vec3 water_col : source_color = vec3(0.04, 0.1, 0.1);
uniform float glow = 0.0;
uniform float tancho = 0.0;

float hh(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}
float vn(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hh(i), hh(i + vec2(1, 0)), u.x), mix(hh(i + vec2(0, 1)), hh(i + vec2(1, 1)), u.x), u.y);
}

void fragment() {
	float part = COLOR.r;
	vec2 uv = UV;
	vec3 col;
	float a;
	vec2 L2 = vec2(cos(heading), sin(heading));
	if (part < 0.5) {
		float x = uv.y * 2.0 - 1.0;
		float edge = 1.0 - abs(x);
		float nz = sqrt(max(0.0, 1.0 - x * x));
		// Body pattern in body space: blotches stretched along the length.
		vec2 bp = vec2(uv.x * 5.0, x * 1.6) + seed * 17.0;
		float n = vn(bp) * 0.65 + vn(bp * 2.3 + 5.0) * 0.35;
		float head_cap = smoothstep(0.2, 0.05, uv.x) * step(0.5, fract(seed * 7.3));
		float warp = (vn(bp * 6.0 + 11.0) - 0.5) * 0.07;
		float pm = smoothstep(1.0 - patch_amt - 0.025, 1.0 - patch_amt + 0.025, n + warp + head_cap * 0.35 - abs(x) * 0.18);
		pm *= smoothstep(0.02, 0.07, uv.x) * smoothstep(0.98, 0.86, uv.x);
		float n2 = vn(bp * 1.7 + 31.0);
		float im = smoothstep(1.0 - ink_amt - 0.05, 1.0 - ink_amt + 0.05, n2) * smoothstep(0.04, 0.12, uv.x);
		col = mix(base_col, patch_col, pm);
		col = mix(col, ink_col, im * 0.92);
		float tc = smoothstep(0.34, 0.28, length(vec2((uv.x - 0.13) * 5.5, x * 0.9)));
		col = mix(col, patch_col, tc * tancho);
		// Belly edges read lighter, spine slightly darker and saturated.
		col *= 0.8 + 0.28 * nz;
		// Scales: offset rows along the body, visible mostly on the lit back.
		vec2 sc = vec2(uv.x * 34.0, x * 6.0);
		sc.y += step(1.0, mod(floor(sc.x), 2.0)) * 0.5;
		vec2 sf = fract(sc) - 0.5;
		float scale = smoothstep(0.5, 0.2, length(sf * vec2(1.3, 1.0)));
		float lit = clamp(0.55 + 0.45 * nz - 0.25 * x * dot(L2, vec2(0.0, 1.0)), 0.0, 1.2);
		col *= mix(0.975, 1.03, scale * (0.25 + 0.35 * metallic));
		col *= lit;
		// Dorsal sheen and metallic flash.
		float sheen = exp(-x * x * 18.0) * smoothstep(0.1, 0.3, uv.x) * smoothstep(0.9, 0.6, uv.x);
		col += vec3(1.0, 0.97, 0.9) * sheen * (0.09 + 0.3 * metallic);
		// Eyes, set wide on the head.
		vec2 e1 = vec2((uv.x - 0.085) * 7.0, (x - 0.62) * 1.0);
		vec2 e2 = vec2((uv.x - 0.085) * 7.0, (x + 0.62) * 1.0);
		float eye = smoothstep(0.16, 0.1, min(length(e1), length(e2)));
		col = mix(col, vec3(0.03, 0.03, 0.035), eye * 0.85);
		// Subsurface: thin edges glow warm where light passes through.
		float thin = 1.0 - smoothstep(0.0, 0.35, edge);
		col += col * vec3(0.35, 0.2, 0.1) * thin * 0.55;
		// Rim darkening sells the round body; soft alpha edge.
		col *= 0.8 + 0.2 * smoothstep(0.0, 0.45, edge);
		a = smoothstep(0.0, 0.16, edge);
	} else {
		// Fins: translucent membrane with rays, tinted by the body colour.
		float rays = 0.9 + 0.1 * sin(uv.y * 60.0 + uv.x * 3.0);
		float edge = smoothstep(0.0, 0.25, uv.y) * smoothstep(1.0, 0.75, uv.y);
		float tipfade = smoothstep(1.02, 0.55, uv.x);
		vec3 fc = mix(vec3(0.95, 0.93, 0.9), mix(base_col, patch_col, fin_tint), 0.55);
		col = fc * (0.75 + 0.35 * rays);
		col += vec3(1.0) * pow(1.0 - uv.x, 3.0) * 0.08;
		col = mix(col, vec3(0.98, 0.97, 0.94), smoothstep(0.7, 1.0, uv.x) * 0.35);
		a = COLOR.g * edge * (0.3 + 0.7 * tipfade) * mix(0.85, 1.0, rays);
	}
	// Depth: deeper fish sink into the water colour.
	float fog = clamp(depth * 0.62, 0.0, 0.7);
	col = mix(col, water_col, fog);
	col += vec3(1.0, 0.85, 0.55) * glow * 0.12;
	COLOR = vec4(col, a);
}
