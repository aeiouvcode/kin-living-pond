shader_type canvas_item;
// KIN water lab surface. Heightfield (CPU ripple sim) + analytic ambient
// swell, refracting a procedural floor. Caustics use the Clearwater idea of
// light focusing (area change of refracted rays), approximated here from the
// surface Laplacian, computed per colour channel for dispersion.

#include "res://labs/water_lab/water_common.gdshaderinc"
uniform sampler2D caus_tex : filter_linear, repeat_disable;
uniform int floor_kind = 0;
uniform float chroma = 1.0;
uniform float glint = 1.0;
uniform float warm = 1.0;
uniform float bloom = 1.0;
uniform float refl = 1.0;
uniform float crisp = 1.0;
uniform float density = 0.55;
uniform float slope = 1.0;


vec2 hash2(vec2 p) {
	p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
	return fract(sin(p) * 43758.5453);
}

float vnz(vec2 p) { vec2 i = floor(p); vec2 f = fract(p); vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash2(i).x, hash2(i + vec2(1, 0)).x, u.x), mix(hash2(i + vec2(0, 1)).x, hash2(i + vec2(1, 1)).x, u.x), u.y); }

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
	// pebbles: rounded stones scattered on warm sand, in drifts with bare sand between
	vec2 g = p * 16.0;
	vec2 id = floor(g);
	vec2 f = fract(g);
	float sandn = sin(p.x * 60.0 + sin(p.y * 17.0) * 2.0) * 0.5 + 0.5;
	float big = vnz(p * 2.2 + 4.0);             // large patches: drifts of stones vs open sand
	float grain = hash2(floor(p * 900.0)).x;      // fine sand grain
	vec3 col = mix(vec3(0.95, 0.83, 0.68), vec3(1.0, 0.92, 0.79), sandn * 0.45 + big * 0.35);
	col *= 0.94 + 0.08 * grain;
	float ao = 1.0;
	for (int j = -1; j <= 1; j++) {
		for (int i = -1; i <= 1; i++) {
			vec2 o = vec2(float(i), float(j));
			vec2 hv = hash2(id + o);
			vec2 hv2 = hash2(id + o + 17.0);
			float rad = 0.26 + 0.2 * hv2.x;
			vec2 r = (o + 0.25 + hv * 0.5 - f) * vec2(1.0, 0.8 + 0.4 * hv2.y);
			float dd = length(r) / rad;
			// stone drifts: each stone decides from its own cell's block (5x5 cells),
			// so a stone is never cut at a cell edge; one hash per neighbour
			float drift = density * (0.3 + 1.2 * hash2(floor((id + o) * 0.2) + 4.0).x);
			float keep = step(hash2(id + o + 29.0).x, drift);
			if (keep < 0.5) { continue; }
			// contact shadow, pushed away from the sun
			float ds = length(r + vec2(-0.35, -0.55) * rad * 0.35) / rad;
			ao *= mix(0.62, 1.0, smoothstep(0.85, 1.45, ds));
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
				// speckle (mineral grains) and a small wet highlight toward the sun
				float spk = hash2(floor((f - o) * 70.0) + id * 13.0).x;
				sc *= 0.9 + 0.16 * spk + 0.08 * (vnz(r / rad * 5.0 + pick * 20.0) - 0.5);
				vec2 hp = r / rad + lr * 0.45;
				float wet = smoothstep(0.22, 0.05, length(hp * vec2(1.0, 1.4))) * dome;
				lit += wet * 0.35;
				col = mix(col * ao, sc * lit, smoothstep(1.0, 0.93, dd));
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
	vec2 grad = surf_grad(uv, p);
	vec3 n = normalize(vec3(-grad, 1.0));

	// refraction of the floor, dispersed per channel (Clearwater-style IOR split)
	// the pool floor slopes: shallow at the bottom-left, deep toward the top-right
	float dl = depth * (1.0 + slope * (0.55 * (1.0 - uv.y) + 0.25 * uv.x - 0.4));
	float d = 0.35 * dl;
	float ch = 0.035 * chroma;
	vec2 off = -grad * d;
	vec3 base;
	base.r = floor_col(p + off * (1.0 - ch)).r;
	base.g = floor_col(p + off).g;
	base.b = floor_col(p + off * (1.0 + ch)).b;

	// caustics from the ray-grid pass, looked up where this pixel's view ray
	// meets the floor
	vec2 fuv = uv + p_to_uv_delta(off);
	vec2 ct = mix(0.8, 0.5, crisp) / vec2(textureSize(caus_tex, 0));
	vec3 caus = (texture(caus_tex, fuv + vec2(ct.x, ct.y)).rgb + texture(caus_tex, fuv + vec2(-ct.x, ct.y)).rgb
		+ texture(caus_tex, fuv + vec2(ct.x, -ct.y)).rgb + texture(caus_tex, fuv - ct).rgb) * 0.5; // 4-tap soften

	// cheap bloom: a ring of wider taps, only the bright part glows
	vec3 glow = vec3(0.0);
	for (int k = 0; k < 8; k++) {
		float ang = float(k) * 0.785398;
		glow += texture(caus_tex, fuv + vec2(cos(ang), sin(ang)) * ct * 10.0).rgb;
	}
	glow = max(glow / 8.0 * 2.0 - 1.2, vec3(0.0));
	caus = mix(vec3(1.0), caus, clamp(1.25 - 0.35 * dl, 0.45, 1.0)); // deeper water spreads the net thinner
	vec3 cl = max(caus - 1.0, vec3(0.0));
	vec3 sun = mix(vec3(1.0), vec3(1.0, 0.9, 0.74), warm);
	vec3 col = base * (0.72 + 0.24 * min(caus, vec3(2.5)) * sun) + sun * cl * 0.08 + sun * glow * 0.1 * bloom;

	// depth tint and a soft vignette
	vec2 cuv = uv - 0.5;
	float vig = clamp(1.0 - dot(cuv * vec2(1.3, 0.9), cuv * vec2(1.3, 0.9)) * 1.4, 0.0, 1.0);
	// Beer-Lambert style absorption: red fades first, so the water reads aqua
	vec3 absorb = exp(-vec3(0.10, 0.05, 0.045) * dl * (1.3 - 0.5 * vig));
	col = col * absorb + mix(vec3(0.10, 0.30, 0.38), vec3(0.16, 0.36, 0.42), warm) * (1.0 - absorb.r) * 0.45;

	// sun glints
	vec3 L = normalize(vec3(-0.35, -0.55, 0.76));
	vec3 Hh = normalize(L + vec3(0.0, 0.0, 1.0));
	float spread = clamp((fwidth(n.x) + fwidth(n.y)) * 6.0, 0.0, 1.0);
	float shin = mix(900.0, 120.0, spread);
	float sp = pow(max(dot(n, Hh), 0.0), shin) * sqrt(shin / 900.0);
	col += vec3(1.0, 0.97, 0.9) * sp * 2.0 * glint;
	col += vec3(0.85, 0.9, 1.0) * min(pow(1.0 - n.z, 2.0), 0.12) * 0.6;
	// surface reflection: a soft warm sky with a blossom canopy at one edge,
	// seen in the reflected ray so it wobbles with every ripple
	vec3 R = reflect(vec3(0.0, 0.0, -1.0), n);
	vec2 rp = uv * vec2(1.0, grid.y / grid.x) + R.xy * 0.9;
	float canopy = smoothstep(0.62, 0.05, rp.x + 0.12 * sin(rp.y * 9.0) + 0.06 * sin(rp.y * 23.0 + 1.3));
	vec3 sky = mix(vec3(0.98, 0.93, 0.88), vec3(0.8, 0.84, 0.98), clamp(rp.y * 0.4, 0.0, 1.0));
	// canopy is clusters of blossom with bright sky showing through the gaps
	float leaf = vnz(rp * 9.0) * 0.75 + vnz(rp * 21.0 + 3.0) * 0.25; // soft: reflections are out of focus
	float gaps = smoothstep(0.34, 0.74, leaf);

	float cmask = canopy * gaps;
	vec3 bloss = mix(vec3(0.93, 0.62, 0.72), vec3(1.0, 0.82, 0.86), vnz(rp * 60.0));
	sky = mix(sky * (1.0 + 0.15 * canopy), bloss, cmask * 0.75);
	float fres = min(0.02 + 0.98 * pow(1.0 - n.z, 5.0), 0.3); // capped: steep fresh drop rings were flat cream sheets
	col = mix(col, sky, clamp(fres + 0.05 + 0.4 * cmask + 0.1 * canopy, 0.0, 1.0) * refl);

	col = col / (1.0 + max(col - 0.85, vec3(0.0)) * 0.9); // soft shoulder, no blowout
	COLOR = vec4(col, 1.0);
}
