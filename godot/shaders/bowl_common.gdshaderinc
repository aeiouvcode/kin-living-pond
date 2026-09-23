float bh21(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}
float bnoise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(bh21(i), bh21(i + vec2(1, 0)), u.x), mix(bh21(i + vec2(0, 1)), bh21(i + vec2(1, 1)), u.x), u.y);
}
float bfbm(vec2 p) {
	return 0.55 * bnoise(p) + 0.3 * bnoise(p * 2.03 + 7.1) + 0.15 * bnoise(p * 4.1 + 19.3);
}
