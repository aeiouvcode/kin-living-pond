shader_type canvas_item;
render_mode unshaded, blend_disabled;

#include "res://shaders/pond.gdshaderinc"

uniform sampler2D under : filter_linear, repeat_disable;
uniform sampler2D sim : filter_nearest, repeat_disable;
uniform vec2 grid = vec2(90.0, 195.0);
uniform float aspect = 0.462;
uniform float time = 0.0;
uniform float px_h = 0.0012; // one screen pixel in pond units
uniform float caustic_amt = 1.0;

float dec(vec2 rg) {
	float q = floor(rg.x * 255.0 + 0.5) * 256.0 + floor(rg.y * 255.0 + 0.5);
	return q / 65535.0 * 2.0 - 1.0;
}

float height(vec2 uv) {
	vec2 g = uv * grid - 0.5;
	vec2 i = floor(g);
	vec2 f = fract(g);
	vec2 inv = 1.0 / grid;
	float a = dec(texture(sim, (i + vec2(0.5, 0.5)) * inv).rg);
	float b = dec(texture(sim, (i + vec2(1.5, 0.5)) * inv).rg);
	float c = dec(texture(sim, (i + vec2(0.5, 1.5)) * inv).rg);
	float d = dec(texture(sim, (i + vec2(1.5, 1.5)) * inv).rg);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// Animated caustic network from moving Voronoi cells (F2 - F1 ridges).
float caustic(vec2 p, float t) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float b1 = 9.0;
	float b2 = 9.0;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 o = vec2(float(x), float(y));
			vec2 h = h22(i + o);
			vec2 r = o + 0.5 + 0.38 * sin(t * (0.6 + 0.5 * h) + 6.2831 * h) - f;
			float d = dot(r, r);
			if (d < b1) { b2 = b1; b1 = d; } else if (d < b2) { b2 = d; }
		}
	}
	float e = sqrt(b2) - sqrt(b1);
	return exp(-e * 9.0);
}

void fragment() {
	vec2 uv = UV;
	vec2 p = pond_p(uv, aspect);
	float sdf = pond_sdf(p, aspect);
	vec3 st = stones(p);
	float solid = solid_mask(sdf, st, px_h * 0.8);

	vec3 col;
	if (solid < 0.999) {
		vec2 e = 1.0 / grid;
		float h = height(uv);
		float hx = height(uv + vec2(e.x, 0.0)) - height(uv - vec2(e.x, 0.0));
		float hy = height(uv + vec2(0.0, e.y)) - height(uv - vec2(0.0, e.y));
		vec2 grad = vec2(hx, hy);
		// Refraction through the moving surface.
		vec2 ruv = clamp(uv - grad * 0.05, vec2(0.001), vec2(0.999));
		vec3 w = texture(under, ruv).rgb;
		float depth = smoothstep(-0.01, -0.2, sdf);
		// Caustics: animated network, focused by surface curvature.
		vec2 cp = p * 16.0 + grad * 3.0;
		float c1 = caustic(cp, time * 0.9);
		float c2 = caustic(cp * 1.6 + 7.3, time * 1.2 + 3.0);
		float lap = (height(uv + vec2(e.x, 0.0)) + height(uv - vec2(e.x, 0.0)) + height(uv + vec2(0.0, e.y)) + height(uv - vec2(0.0, e.y)) - 4.0 * h);
		float focus = clamp(-lap * 18.0, -0.5, 1.5);
		float canopy = smoothstep(0.3, 0.72, fbm3(p * 3.0 + vec2(time * 0.012, -time * 0.008)));
		float caus = (c1 * 0.65 + c2 * 0.35) * (1.0 - depth * 0.55) * (0.35 + 0.65 * canopy);
		caus = caus * (1.0 + focus);
		// Chromatic fringe on the caustics.
		vec3 cc = vec3(1.0, 0.93, 0.74) * caus * 0.2 * caustic_amt;
		cc.r *= 1.0 + 0.3 * grad.x * 40.0;
		cc.b *= 1.0 - 0.3 * grad.x * 40.0;
		w += cc * (0.45 + 0.55 * w * 3.0);
		// Surface: faint sky, sparkle on slopes, shadow beside stones.
		vec3 n = normalize(vec3(-grad * 14.0, 1.0));
		vec3 L = normalize(vec3(-0.45, -0.7, 0.55));
		vec3 H = normalize(L + vec3(0.0, 0.0, 1.0));
		float spec = pow(max(dot(n, H), 0.0), 90.0);
		float fres = 0.03 + 0.25 * pow(1.0 - n.z, 2.0);
		// Reflected sky: brighter toward the upper left, broken by soft cloud and leaf shapes.
		vec2 rp = p + grad * 0.6;
		float cloud = fbm3(rp * vec2(2.2, 3.0) + vec2(time * 0.006, 0.0));
		float skyg = clamp(0.75 - (uv.x * 0.6 + uv.y * 0.8) * 0.6, 0.0, 1.0);
		vec3 sky = mix(vec3(0.42, 0.55, 0.58), vec3(0.8, 0.86, 0.84), skyg) * (0.6 + 0.5 * cloud) * (0.55 + 0.45 * canopy);
		w = mix(w, sky, clamp(fres * 0.5 + 0.1 * skyg * cloud, 0.0, 0.4));
		// Micro ripples from breeze: fine sparkle that never quite stops.
		vec2 mg = vec2(vnoise(p * 180.0 + time * 0.8) - vnoise(p * 180.0 + 3.1 - time * 0.7), vnoise(p * 160.0 + 7.7 + time * 0.6) - vnoise(p * 170.0 - time * 0.9));
		vec3 nm = normalize(vec3(-grad * 14.0 - mg * 0.35, 1.0));
		float sparkle = pow(max(dot(nm, H), 0.0), 220.0) * skyg;
		w += vec3(1.0, 0.96, 0.88) * (spec * 0.55 + sparkle * 0.6) * (0.4 + 0.6 * canopy);
		// Soft contact shadow cast by stones onto the water.
		vec2 so = p - L.xy * 0.018;
		float sh = solid_mask(pond_sdf(so, aspect), stones(so), 0.006);
		w *= 1.0 - 0.45 * sh;
		// Foam at the water line, broken by noise and fed by waves.
		float lineD = abs(sdf);
		float nearRock = smoothstep(0.34, 0.52, st.x * smoothstep(-0.034, -0.012, sdf));
		float edgeFoam = max(smoothstep(0.012, 0.0, lineD), nearRock * 0.7);
		float fn = vnoise(p * 140.0 + vec2(time * 0.3, 0.0)) * vnoise(p * 60.0 - time * 0.2);
		float foam = edgeFoam * smoothstep(0.18, 0.5, fn + abs(h) * 1.5);
		foam += smoothstep(0.3, 0.6, h) * smoothstep(0.45, 0.7, fn) * 0.6;
		w = mix(w, vec3(0.86, 0.9, 0.86), clamp(foam, 0.0, 1.0) * 0.55);
		col = w;
	}
	if (solid > 0.001) {
		// Stones and bank, lit from the upper left.
		float d = px_h * 3.0;
		float hx = stones(p + vec2(d, 0.0)).x - stones(p - vec2(d, 0.0)).x;
		float hy = stones(p + vec2(0.0, d)).x - stones(p - vec2(0.0, d)).x;
		vec3 n = normalize(vec3(-hx, -hy, 0.9 * d * 60.0));
		vec3 L = normalize(vec3(-0.45, -0.7, 0.55));
		float dif = clamp(dot(n, L), 0.0, 1.0);
		float bankness = smoothstep(0.0, 0.02, sdf);
		float g = fbm3(p * 90.0);
		vec3 rock = mix(vec3(0.36, 0.33, 0.28), vec3(0.56, 0.5, 0.42), st.y) * (0.8 + 0.4 * g);
		float moss = smoothstep(0.55, 0.85, fbm3(p * 30.0 + st.y * 9.0)) * smoothstep(0.3, 0.9, st.x);
		rock = mix(rock, vec3(0.2, 0.3, 0.12), moss * 0.7);
		vec3 lit = rock * (0.28 + 0.95 * dif) * (0.55 + 0.45 * st.x);
		// Wet dark rim where stone meets water.
		lit *= mix(0.55, 1.0, smoothstep(0.52, 0.66, st.x * smoothstep(-0.034, -0.012, sdf)) + bankness);
		// Bank between stones: dark soil and grass.
		vec3 soil = mix(vec3(0.07, 0.08, 0.05), vec3(0.14, 0.2, 0.08), smoothstep(0.35, 0.7, fbm3(p * 55.0)));
		float blade = smoothstep(0.55, 0.9, vnoise(vec2(p.x * 260.0, p.y * 40.0)));
		soil += vec3(0.1, 0.16, 0.05) * blade * 0.6;
		float stoneTop = smoothstep(0.25, 0.45, st.x);
		vec3 land = mix(soil, lit, max(stoneTop, 1.0 - bankness));
		col = mix(col, land, solid);
	}
	// Gentle vignette.
	vec2 v = uv - 0.5;
	col *= 1.0 - 0.35 * dot(v * vec2(1.2, 0.9), v * vec2(1.2, 0.9));
	COLOR = vec4(col, 1.0);
}
