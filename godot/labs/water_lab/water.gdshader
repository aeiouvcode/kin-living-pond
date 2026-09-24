shader_type canvas_item;
// KIN water lab surface. Heightfield (CPU ripple sim) + analytic ambient
// swell, refracting a procedural floor. Caustics use the Clearwater idea of
// light focusing (area change of refracted rays), approximated here from the
// surface Laplacian, computed per colour channel for dispersion.

uniform sampler2D height_tex : filter_linear, repeat_disable;
uniform vec2 grid = vec2(96.0, 208.0);
uniform float time = 0.0;
uniform int floor_kind = 0;
uniform float depth = 1.0;
uniform float chroma = 1.0;
uniform float glint = 1.0;
uniform float wind = 1.0;

vec2 hash2(vec2 p) {
	p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
	return fract(sin(p) * 43758.5453);
}

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

float sim_h(vec2 uv) { return texture(height_tex, uv).r; }

vec3 floor_col(vec2 p) {
	// p in "screen-ish" units, aspect corrected
	if (floor_kind == 1) {
		vec2 g = p * 9.0;
		vec2 f = fract(g) - 0.5;
		vec2 id = floor(g);
		float grout = smoothstep(0.43, 0.49, max(abs(f.x), abs(f.y)));
		float tint = hash2(id).x;
		vec3 tile = mix(vec3(0.62, 0.86, 0.88), vec3(0.78, 0.9, 0.93), tint);
		if (hash2(id + 3.0).y > 0.92) tile = vec3(0.98, 0.78, 0.66);
		return mix(tile, vec3(0.9, 0.93, 0.92), grout);
	}
	if (floor_kind == 2) {
		float n = sin(p.x * 30.0 + sin(p.y * 7.0) * 2.0) * 0.5 + 0.5;
		return mix(vec3(0.86, 0.78, 0.64), vec3(0.93, 0.87, 0.74), n * 0.6);
	}
	// pebbles: rounded stones scattered on pale sand, not a mosaic
	vec2 g = p * 16.0;
	vec2 id = floor(g);
	vec2 f = fract(g);
	float sandn = sin(p.x * 60.0 + sin(p.y * 17.0) * 2.0) * 0.5 + 0.5;
	vec3 col = mix(vec3(0.86, 0.80, 0.74), vec3(0.92, 0.87, 0.80), sandn * 0.5);
	float ao = 1.0;
	for (int j = -1; j <= 1; j++) {
		for (int i = -1; i <= 1; i++) {
			vec2 o = vec2(float(i), float(j));
			vec2 hv = hash2(id + o);
			vec2 hv2 = hash2(id + o + 17.0);
			float rad = 0.26 + 0.2 * hv2.x;
			vec2 r = (o + 0.25 + hv * 0.5 - f) * vec2(1.0, 0.8 + 0.4 * hv2.y);
			float dd = length(r) / rad;
			ao *= mix(0.82, 1.0, smoothstep(0.95, 1.5, dd));
			if (dd < 1.0) {
				vec3 c0 = vec3(0.90, 0.74, 0.66);
				vec3 c1 = vec3(0.70, 0.68, 0.86);
				vec3 c2 = vec3(0.66, 0.82, 0.74);
				vec3 c3 = vec3(0.92, 0.89, 0.82);
				vec3 c4 = vec3(0.45, 0.46, 0.58);
				float pick = hash2(id + o + 5.0).x;
				vec3 sc = pick < 0.25 ? c0 : (pick < 0.45 ? c1 : (pick < 0.62 ? c2 : (pick < 0.85 ? c3 : c4)));
				float dome = sqrt(max(1.0 - dd * dd, 0.0));
				vec2 lr = normalize(vec2(0.35, 0.55));
				float lit = 0.72 + 0.28 * dome + 0.18 * dot(r / rad, -lr) * dome;
				col = mix(col, sc * lit, smoothstep(1.0, 0.9, dd));
				ao = 1.0;
			}
		}
	}
	return col * ao;
}

void fragment() {
	vec2 uv = UV;
	float aspect = grid.y / grid.x;
	float sc = grid.x / 96.0; // keep world scale per pixel the same on phone and desktop
	vec2 p = vec2(uv.x, uv.y * aspect) * 0.5 * sc;
	vec2 tx = 1.0 / grid;
	float edge_fade = smoothstep(0.0, 0.04, min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y)) );
	float hc = sim_h(uv);
	float hl = sim_h(uv - vec2(tx.x, 0.0));
	float hr = sim_h(uv + vec2(tx.x, 0.0));
	float hd = sim_h(uv - vec2(0.0, tx.y));
	float hu = sim_h(uv + vec2(0.0, tx.y));
	float h1 = sim_h(uv + tx);
	float h2 = sim_h(uv - tx);
	float h3 = sim_h(uv + vec2(tx.x, -tx.y));
	float h4 = sim_h(uv + vec2(-tx.x, tx.y));
	// sim cell size in p units = 0.5 / grid.x
	float cell = 0.5 * sc / grid.x;
	vec2 sgrad = vec2(hr - hl, hu - hd) * 0.5 / cell * 0.004;
	vec3 shess = vec3(hl + hr - 2.0 * hc, hu + hd - 2.0 * hc, (h1 + h2 - h3 - h4) * 0.25) / (cell * cell) * 0.004;
	sgrad *= edge_fade;
	shess *= edge_fade;
	vec2 wg; vec3 wh;
	swell(p, wg, wh);
	vec2 grad = sgrad + wg;
	vec3 hs = shess + wh;
	vec3 n = normalize(vec3(-grad, 1.0));

	// refraction of the floor, dispersed per channel (Clearwater-style IOR split)
	float d = 0.35 * depth;
	float ch = 0.035 * chroma;
	vec2 off = -grad * d;
	vec3 base;
	base.r = floor_col(p + off * (1.0 - ch)).r;
	base.g = floor_col(p + off).g;
	base.b = floor_col(p + off * (1.0 + ch)).b;

	// caustics: light through the surface lands on the floor; the brightness is
	// the inverse area change of the refracted ray bundle, det(I + d*k*Hessian)
	float kc = 0.42 * depth;
	vec3 caus;
	for (int c = 0; c < 3; c++) {
		float kk = kc * (1.0 + (float(c) - 1.0) * ch * 3.0);
		float det = (1.0 + kk * hs.x) * (1.0 + kk * hs.y) - kk * kk * hs.z * hs.z;
		caus[c] = 1.0 / max(abs(det), 0.22);
	}
	caus = clamp(caus, 0.0, 6.0);
	vec3 cl = max(caus - 1.0, vec3(0.0));
	vec3 col = base * (0.7 + 0.16 * cl) + vec3(1.0, 0.95, 0.84) * cl * cl * 0.018;

	// depth tint and a soft vignette
	vec2 cuv = uv - 0.5;
	float vig = clamp(1.0 - dot(cuv * vec2(1.3, 0.9), cuv * vec2(1.3, 0.9)) * 1.4, 0.0, 1.0);
	// Beer-Lambert style absorption: red fades first, so the water reads aqua
	vec3 absorb = exp(-vec3(0.32, 0.1, 0.05) * depth * (1.3 - 0.5 * vig));
	col = col * absorb + vec3(0.10, 0.26, 0.34) * (1.0 - absorb.r) * 0.55;

	// sun glints
	vec3 L = normalize(vec3(-0.35, -0.55, 0.76));
	vec3 Hh = normalize(L + vec3(0.0, 0.0, 1.0));
	float spread = clamp((fwidth(n.x) + fwidth(n.y)) * 6.0, 0.0, 1.0);
	float shin = mix(900.0, 120.0, spread);
	float sp = pow(max(dot(n, Hh), 0.0), shin) * sqrt(shin / 900.0);
	col += vec3(1.0, 0.97, 0.9) * sp * 2.0 * glint;
	col += vec3(0.85, 0.9, 1.0) * pow(1.0 - n.z, 2.0) * 0.6;

	col = col / (1.0 + max(col - 0.85, vec3(0.0)) * 0.9); // soft shoulder, no blowout
	COLOR = vec4(col, 1.0);
}
