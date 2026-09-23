// Shared pond geometry: shoreline SDF and shore stones.
// p is in pond units: y spans [-0.5, 0.5], x spans [-aspect/2, aspect/2].

float h21(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

vec2 h22(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.xx + p3.yz) * p3.zy);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	float a = h21(i);
	float b = h21(i + vec2(1.0, 0.0));
	float c = h21(i + vec2(0.0, 1.0));
	float d = h21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float fbm3(vec2 p) {
	return 0.55 * vnoise(p) + 0.3 * vnoise(p * 2.07 + 13.1) + 0.15 * vnoise(p * 4.13 + 41.7);
}

vec2 pond_p(vec2 uv, float asp) {
	return (uv - 0.5) * vec2(asp, 1.0);
}

// Negative inside the water.
float pond_sdf(vec2 p, float asp) {
	vec2 b = vec2(asp * 0.5 - 0.018, 0.5 - 0.07);
	float r = min(0.12, b.x * 0.6);
	vec2 q = abs(p) - b + r;
	float d = length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
	d += 0.016 * (vnoise(p * 7.0 + 3.0) - 0.5) + 0.007 * (vnoise(p * 21.0) - 0.5);
	return d;
}

// Shore stones. x = dome height 0..1, y = stone id hash, z = normalised distance.
vec3 stones(vec2 p) {
	vec2 g = p * 19.0;
	vec2 i = floor(g);
	vec2 f = fract(g);
	float best = 9.0;
	vec2 bid = vec2(0.0);
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 o = vec2(float(x), float(y));
			vec2 h = h22(i + o);
			vec2 r = o + 0.15 + 0.7 * h - f;
			float rad = 0.42 + 0.3 * h21(i + o + 7.0);
			float d = length(r * vec2(1.0, 1.0 + 0.5 * h.x)) / rad;
			if (d < best) { best = d; bid = i + o; }
		}
	}
	return vec3(clamp(1.0 - best * best, 0.0, 1.0), h21(bid), best);
}

// 1 where a stone breaks the surface or the bank is dry.
float solid_mask(float sdf, vec3 st, float aa) {
	float bank = smoothstep(-aa, aa, sdf);
	float band = smoothstep(-0.034, -0.012, sdf);
	float rock = smoothstep(0.52 - aa * 8.0, 0.52 + aa * 8.0, st.x * band);
	return max(bank, rock);
}
