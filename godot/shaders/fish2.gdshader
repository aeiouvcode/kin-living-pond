shader_type canvas_item;
render_mode unshaded;

// COLOR.r: < 0.25 body, < 0.75 fin, else eye. COLOR.g: fin opacity.
uniform float kind = 0.0; // 0 ryukin (white-peach), 1 demekin (black)
uniform float depth = 0.3;
uniform float glow = 0.0;
uniform float seed = 0.0;
uniform vec3 water_col : source_color = vec3(0.74, 0.76, 0.96);

float hh(vec2 p) { vec3 p3 = fract(vec3(p.xyx) * 0.1031); p3 += dot(p3, p3.yzx + 33.33); return fract((p3.x + p3.y) * p3.z); }
float vn(vec2 p) { vec2 i = floor(p); vec2 f = fract(p); vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hh(i), hh(i + vec2(1, 0)), u.x), mix(hh(i + vec2(0, 1)), hh(i + vec2(1, 1)), u.x), u.y); }

vec4 eye(vec2 q, float bulge) {
	float r = length(q);
	float a = smoothstep(1.0, 0.9, r);
	vec3 c = mix(vec3(0.02, 0.02, 0.05), vec3(0.08, 0.1, 0.22), smoothstep(0.2, 0.9, r) * 0.6);
	// Highlight ring and a sharp catch-light.
	c += vec3(0.6, 0.7, 0.9) * exp(-pow((r - 0.72) / 0.07, 2.0)) * 0.55;
	c += vec3(1.0) * smoothstep(0.26, 0.14, length(q - vec2(-0.3, -0.35)));
	c += vec3(1.0) * smoothstep(0.12, 0.05, length(q - vec2(0.3, 0.3))) * 0.6;
	// Demekin: thin orange rim.
	c = mix(c, vec3(0.9, 0.45, 0.15), exp(-pow((r - 0.93) / 0.05, 2.0)) * bulge * 0.8);
	c = mix(c, vec3(0.95, 0.85, 0.82), smoothstep(0.88, 1.0, r) * (1.0 - bulge));
	return vec4(c, a);
}

void fragment() {
	float part = COLOR.r;
	vec2 uv = UV;
	vec3 col;
	float a;
	if (part < 0.25) {
		float x = uv.y * 2.0 - 1.0;
		float nz = sqrt(max(0.0, 1.0 - x * x));
		float edge = 1.0 - abs(x);
		if (kind < 0.5) {
			vec3 base = vec3(0.99, 0.94, 0.9);
			vec3 peach = vec3(0.99, 0.78, 0.7);
			vec3 blush = vec3(0.97, 0.62, 0.66);
			col = mix(base, peach, smoothstep(0.7, 0.2, abs(x)) * 0.55);
			float b = smoothstep(0.42, 0.05, uv.x) * smoothstep(1.0, 0.3, abs(x));
			b += smoothstep(0.55, 0.0, abs(x)) * smoothstep(0.1, 0.35, uv.x) * smoothstep(0.8, 0.4, uv.x) * 0.5 * vn(vec2(uv.x * 6.0, x * 2.0) + seed);
			col = mix(col, blush, clamp(b, 0.0, 1.0) * 0.55);
			col *= 0.84 + 0.2 * nz;
			float thin = 1.0 - smoothstep(0.0, 0.4, edge);
			col += vec3(0.25, 0.15, 0.12) * thin;
			col += vec3(1.0) * exp(-x * x * 14.0) * smoothstep(0.08, 0.3, uv.x) * smoothstep(0.85, 0.5, uv.x) * 0.12;
			// Scales catch the light faintly.
			vec2 sc = vec2(uv.x * 26.0, x * 5.0);
			sc.y += step(1.0, mod(floor(sc.x), 2.0)) * 0.5;
			col *= 0.97 + 0.05 * smoothstep(0.5, 0.2, length(fract(sc) - 0.5));
			vec2 e1 = vec2((uv.x - 0.1) * 11.0, (x - 0.62) * 4.2);
			vec2 e2 = vec2((uv.x - 0.1) * 11.0, (x + 0.62) * 4.2);
			vec4 ea = eye(e1 / 1.0, 0.0);
			vec4 eb = eye(e2 / 1.0, 0.0);
			col = mix(col, ea.rgb, ea.a);
			col = mix(col, eb.rgb, eb.a);
		} else {
			col = vec3(0.035, 0.035, 0.05);
			float velvet = vn(vec2(uv.x * 40.0, x * 8.0) + seed) * 0.03;
			col += velvet;
			col += vec3(0.12, 0.18, 0.42) * pow(1.0 - nz, 2.0) * 0.8;
			col += vec3(0.25, 0.3, 0.55) * exp(-x * x * 10.0) * smoothstep(0.1, 0.3, uv.x) * smoothstep(0.8, 0.5, uv.x) * 0.25;
		}
		a = smoothstep(0.0, 0.14, edge);
	} else if (part < 0.75) {
		float streak = 0.88 + 0.12 * sin(uv.y * 40.0 + uv.x * 5.0 + vn(uv * vec2(3.0, 12.0) + seed) * 3.0);
		float side = smoothstep(0.0, 0.12, uv.y) * smoothstep(1.0, 0.88, uv.y);
		// Ragged, soft trailing edge so the veil never reads as a polygon.
		float rag = 0.72 + 0.22 * vn(vec2(uv.y * 9.0, seed));
		float tip = smoothstep(1.0, rag, uv.x) * (1.0 - uv.x * 0.35);
		float root = 1.0 + 0.6 * smoothstep(0.3, 0.0, uv.x);
		if (kind < 0.5) {
			col = mix(vec3(1.0, 0.86, 0.82), vec3(0.99, 0.98, 1.0), smoothstep(0.0, 0.45, uv.x));
			col *= streak;
			a = COLOR.g * tip * root * mix(0.7, 1.0, streak) * (0.35 + 0.65 * side) * 0.9;
		} else {
			col = mix(vec3(0.03, 0.03, 0.05), vec3(0.1, 0.12, 0.26), smoothstep(0.2, 1.0, uv.x));
			col *= 0.8 + 0.4 * streak;
			a = clamp(COLOR.g * tip * root * (0.35 + 0.65 * side) * 0.9, 0.0, 0.78);
		}
	} else {
		vec4 ee = eye(uv * 2.0 - 1.0, kind);
		col = ee.rgb;
		a = ee.a;
	}
	col = mix(col, water_col, clamp(depth * 0.35, 0.0, 0.4));
	col += vec3(1.0, 0.9, 0.95) * glow * 0.1;
	COLOR = vec4(col, a);
}
