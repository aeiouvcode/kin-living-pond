shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;
// Fish lab body: soft sheen, not plastic. Colour from a white base with
// peach/red patches (ryukin) or velvet black (demekin, kept in form by rim light).
uniform float kind = 0.0;
uniform float time_s = 0.0;
uniform float swim = 1.0;
uniform float bend = 0.0;
uniform float body_len = 1.0;
uniform vec3 patch_col : source_color = vec3(0.98, 0.55, 0.42);

float h21(vec2 p) { vec3 q = fract(vec3(p.xyx) * 0.1031); q += dot(q, q.yzx + 33.33); return fract((q.x + q.y) * q.z); }
float vn(vec2 p) { vec2 i = floor(p); vec2 f = fract(p); vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(h21(i), h21(i + vec2(1, 0)), u.x), mix(h21(i + vec2(0, 1)), h21(i + vec2(1, 1)), u.x), u.y); }

// Spine wave shared with the fins: 0 at the head, growing toward the tail.
float spine_off(float x, float t) {
	float u = clamp((0.35 * body_len - x) / body_len, 0.0, 1.5);
	return (0.06 * u * u * sin(u * 3.2 - t * 3.0) * swim + bend * u * u * 0.6) * body_len;
}

void vertex() {
	float off = spine_off(VERTEX.x, time_s);
	float d = spine_off(VERTEX.x + 0.01, time_s) - off;
	VERTEX.z += off;
	NORMAL = normalize(NORMAL + vec3(d * 40.0 * NORMAL.z, 0.0, 0.0));
}

void fragment() {
	vec2 uv = UV; // x: nose->tail, y: around
	vec3 col;
	float rough;
	float spec = 0.35;
	// Faint scale lattice: offset rows, only a hint in the sheen.
	vec2 sp = vec2(uv.x * 60.0, uv.y * 52.0);
	sp.y += floor(sp.x) * 0.5;
	float scale = smoothstep(0.35, 0.5, length(fract(sp) - 0.5));
	if (kind < 0.5) {
		vec3 base = vec3(0.93, 0.88, 0.85);
		float pn = vn(vec2(uv.x * 4.0, uv.y * 3.0) + 11.0) + 0.5 * vn(vec2(uv.x * 9.0, uv.y * 7.0));
		float top = smoothstep(0.35, 0.0, abs(uv.y - 0.25));
		float patchm = smoothstep(0.75, 0.95, pn + top * 0.35) * smoothstep(0.08, 0.2, uv.x);
		float head = smoothstep(0.18, 0.02, uv.x) * smoothstep(0.5, 0.1, abs(uv.y - 0.25));
		col = mix(base, patch_col, clamp(patchm + head * 0.8, 0.0, 1.0));
		col = mix(col, vec3(1.0, 0.8, 0.76), 0.25 * smoothstep(0.4, 1.0, uv.x));
		rough = 0.45 - scale * 0.04;
	} else {
		col = vec3(0.018, 0.018, 0.026) + vn(uv * vec2(40.0, 30.0)) * 0.012;
		rough = 0.5 - scale * 0.04;
		spec = 0.45;
	}
	// Gill plate: a soft crease arc behind the eye, and a small mouth.
	float gx = 0.2 + 0.035 * cos((uv.y - 0.5) * 6.2832);
	float gill = exp(-pow((uv.x - gx) / 0.012, 2.0)) * smoothstep(0.02, 0.15, abs(uv.y - 0.25)) * smoothstep(0.02, 0.15, abs(uv.y - 0.75));
	col *= 1.0 - gill * (kind < 0.5 ? 0.22 : 0.4);
	col = mix(col, col * 1.08 + 0.02, smoothstep(gx, gx - 0.08, uv.x) * 0.3);
	float mouth = smoothstep(0.035, 0.0, uv.x) * smoothstep(0.2, 0.0, abs(uv.y - 0.5));
	col = mix(col, vec3(0.45, 0.2, 0.2) * (kind < 0.5 ? 1.0 : 0.1), mouth * 0.7);
	ALBEDO = col;
	ROUGHNESS = rough;
	SPECULAR = spec;
	float fr = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	// Cheap subsurface feel on the pale fish, cool rim light on the black one.
	vec3 rimc = kind < 0.5 ? vec3(1.0, 0.86, 0.84) : vec3(0.35, 0.45, 0.85);
	EMISSION = rimc * fr * (kind < 0.5 ? 0.2 : 0.55);
	BACKLIGHT = kind < 0.5 ? vec3(0.5, 0.25, 0.2) : vec3(0.0);
}
