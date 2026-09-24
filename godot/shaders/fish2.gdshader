shader_type canvas_item;
render_mode unshaded;

// COLOR.r: < 0.25 body, < 0.75 fin, else eye. COLOR.g: fin opacity.
uniform float kind = 0.0; // 0 ryukin (white-peach), 1 demekin (black)
uniform float depth = 0.3;
uniform float glow = 0.0;
uniform float seed = 0.0;
uniform vec4 bowl = vec4(0.5, 0.5, 0.6, 0.46); // centre uv, radius / width, aspect
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
		// Soft, rounded, glossy body: shade by a fake normal, one broad
		// specular along the back, a gentle rim. No scale pattern.
		float spec = exp(-pow((x + 0.18) / 0.32, 2.0)) * smoothstep(0.05, 0.3, uv.x) * smoothstep(0.95, 0.45, uv.x);
		float rim = pow(1.0 - nz, 3.0);
		if (kind < 0.5) {
			vec3 base = vec3(0.99, 0.93, 0.9);
			vec3 peach = vec3(0.99, 0.76, 0.68);
			vec3 blush = vec3(0.98, 0.66, 0.68);
			col = mix(base, peach, smoothstep(0.9, 0.1, abs(x)) * 0.45 * smoothstep(0.0, 0.5, uv.x));
			float b = smoothstep(0.35, 0.0, uv.x) * 0.8 + vn(vec2(uv.x * 3.0, x * 1.5) + seed) * 0.35 * smoothstep(0.2, 0.5, uv.x) * smoothstep(0.9, 0.6, uv.x);
			col = mix(col, blush, clamp(b, 0.0, 1.0) * 0.6);
			col *= 0.78 + 0.2 * nz;
			col += vec3(1.0) * spec * 0.16;
			col = mix(col, vec3(1.0, 0.95, 0.97), rim * 0.4);
		} else {
			col = vec3(0.03, 0.03, 0.045);
			col += vn(vec2(uv.x * 22.0, x * 5.0) + seed) * 0.018;
			col *= 0.7 + 0.3 * nz;
			col += vec3(0.16, 0.22, 0.48) * spec * 0.35;
			col += vec3(0.1, 0.13, 0.3) * rim * 0.5;
		}
		a = smoothstep(0.0, 0.14, edge);
	} else if (part < 0.75) {
		float streak = 0.88 + 0.12 * sin(uv.y * 40.0 + uv.x * 5.0 + vn(uv * vec2(3.0, 12.0) + seed) * 3.0);
		float sw = 0.22 + 0.25 * (1.0 - smoothstep(0.0, 0.4, uv.x));
		float side = smoothstep(0.0, sw, uv.y) * smoothstep(1.0, 1.0 - sw, uv.y);
		// Ragged, soft trailing edge so the veil never reads as a polygon.
		float rag = kind < 0.5 ? 0.72 + 0.22 * vn(vec2(uv.y * 9.0, seed)) : 0.5 + 0.42 * vn(vec2(uv.y * 16.0, seed + 3.0));
		float tip = smoothstep(1.0, rag, uv.x) * (1.0 - uv.x * 0.35);
		float root = 1.0 + 0.25 * smoothstep(0.3, 0.0, uv.x);
		float silk = 0.94 + 0.06 * sin(uv.y * 30.0 + vn(uv * vec2(2.0, 8.0) + seed) * 4.0);
		if (kind < 0.5) {
			col = mix(vec3(1.0, 0.9, 0.88), vec3(1.0, 0.99, 1.0), smoothstep(0.0, 0.3, uv.x)) * silk;
			a = COLOR.g * tip * root * (0.06 + 0.94 * side) * mix(1.1, 0.7, uv.x);
		} else {
			col = mix(vec3(0.03, 0.03, 0.05), vec3(0.09, 0.1, 0.2), smoothstep(0.2, 1.0, uv.x)) * silk;
			a = clamp(COLOR.g * tip * root * (0.1 + 0.9 * side) * mix(1.25, 0.8, uv.x), 0.0, 0.9);
		}
	} else {
		vec4 ee = eye(uv * 2.0 - 1.0, kind);
		col = ee.rgb;
		a = ee.a;
	}
	col = mix(col, water_col, clamp(depth * 0.35, 0.0, 0.4));
	col += vec3(1.0, 0.9, 0.95) * glow * 0.1;
	// Keep fish inside the glass: fade out just inside the rim.
	vec2 bp = (SCREEN_UV - bowl.xy) * vec2(1.0, 1.0 / bowl.w);
	a *= smoothstep(bowl.z * 0.99, bowl.z * 0.9, length(bp));
	COLOR = vec4(col, a);
}
