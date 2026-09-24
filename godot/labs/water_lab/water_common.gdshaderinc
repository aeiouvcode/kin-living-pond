// Shared by the surface shader and the caustics ray grid.
uniform sampler2D height_tex : filter_linear, repeat_disable;
uniform vec2 grid = vec2(96.0, 208.0);
uniform float time = 0.0;
uniform float wind = 1.0;
uniform float depth = 1.0;

// ambient swell: travelling sines. Returns grad (xy) and Hessian (xx, yy, xy)
// so caustics can use the true area change of refracted rays.
void swell(vec2 p, out vec2 grad, out vec3 hess) {
	grad = vec2(0.0);
	hess = vec3(0.0);
	for (int i = 0; i < 9; i++) {
		float fi = float(i);
		float ang = fi * 2.399 + 0.3;
		float kl = 18.0 + fi * 9.0;
		vec2 k = vec2(cos(ang), sin(ang)) * kl;
		float w = sqrt(9.8 * kl) * 0.22;
		float a = 0.0011 * pow(0.85, fi) * 18.0 / kl;
		float ph = dot(k, p) - w * time + fi * 1.7;
		float s = sin(ph);
		float c = cos(ph);
		grad += a * c * k;
		hess += -a * s * vec3(k.x * k.x, k.y * k.y, k.x * k.y);
	}
	grad *= wind;
	hess *= wind;
}

// surface gradient (p units) at a uv, sim + swell
vec2 surf_grad(vec2 uv, vec2 p) {
	vec2 tx = 1.0 / grid;
	float sc = grid.x / 96.0;
	float cell = 0.5 * sc / grid.x;
	float hl = textureLod(height_tex, uv - vec2(tx.x, 0.0), 0.0).r;
	float hr = textureLod(height_tex, uv + vec2(tx.x, 0.0), 0.0).r;
	float hd = textureLod(height_tex, uv - vec2(0.0, tx.y), 0.0).r;
	float hu = textureLod(height_tex, uv + vec2(0.0, tx.y), 0.0).r;
	float ef = smoothstep(0.0, 0.04, min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y)));
	vec2 g = vec2(hr - hl, hu - hd) * 0.5 / cell * 0.004 * ef;
	vec2 wg; vec3 wh;
	swell(p, wg, wh);
	return g + wg;
}

vec2 uv_to_p(vec2 uv) {
	float sc = grid.x / 96.0;
	return vec2(uv.x, uv.y * grid.y / grid.x) * 0.5 * sc;
}
vec2 p_to_uv_delta(vec2 dp) {
	float sc = grid.x / 96.0;
	return vec2(dp.x, dp.y * grid.x / grid.y) / (0.5 * sc);
}
