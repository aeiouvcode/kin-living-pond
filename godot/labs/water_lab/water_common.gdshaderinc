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

// Cubic B-spline sample of the sim height (4 bilinear taps). Bilinear
// heights have kinked slopes at every cell edge, which focus into a sawtooth
// "zipper" along caustic lines; the B-spline is smooth through second order.
float h_bspline(vec2 uv) {
	vec2 tp = uv * grid - 0.5;
	vec2 i = floor(tp);
	vec2 f = tp - i;
	vec2 f2 = f * f;
	vec2 f3 = f2 * f;
	vec2 w0 = (1.0 - 3.0 * f + 3.0 * f2 - f3) / 6.0;
	vec2 w1 = (4.0 - 6.0 * f2 + 3.0 * f3) / 6.0;
	vec2 w2 = (1.0 + 3.0 * f + 3.0 * f2 - 3.0 * f3) / 6.0;
	vec2 w3 = f3 / 6.0;
	vec2 g0 = w0 + w1;
	vec2 g1 = w2 + w3;
	vec2 h0 = (w1 / g0) - 0.5 + i;
	vec2 h1 = (w3 / g1) + 1.5 + i;
	vec2 inv = 1.0 / grid;
	float a = textureLod(height_tex, (vec2(h0.x, h0.y) + 0.5) * inv, 0.0).r;
	float b = textureLod(height_tex, (vec2(h1.x, h0.y) + 0.5) * inv, 0.0).r;
	float c = textureLod(height_tex, (vec2(h0.x, h1.y) + 0.5) * inv, 0.0).r;
	float d = textureLod(height_tex, (vec2(h1.x, h1.y) + 0.5) * inv, 0.0).r;
	return g0.y * (g0.x * a + g1.x * b) + g1.y * (g0.x * c + g1.x * d);
}

// surface gradient (p units) at a uv, sim + swell
vec2 surf_grad(vec2 uv, vec2 p) {
	vec2 tx = 1.0 / grid;
	float sc = grid.x / 96.0;
	float cell = 0.5 * sc / grid.x;
	// 1.5-cell central differences: smoother normals, so caustic lines from
	// the sim do not show the bilinear "zipper"
	vec2 o = tx * 1.5;
	float hl = h_bspline(uv - vec2(o.x, 0.0));
	float hr = h_bspline(uv + vec2(o.x, 0.0));
	float hd = h_bspline(uv - vec2(0.0, o.y));
	float hu = h_bspline(uv + vec2(0.0, o.y));
	float ef = smoothstep(0.0, 0.04, min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y)));
	vec2 g = vec2(hr - hl, hu - hd) / 3.0 / cell * 0.004 * ef;
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

// One reflected canopy for the floor and the over-fish surface. Broad, soft
// forks read as a tree at phone size; leaf masses mask their ends. No thin
// high-contrast lines that would look like scratches on the water.
float canopy_noise(vec2 p) {
 vec2 i = floor(p), f = fract(p); f = f*f*(3.0-2.0*f);
 float a = fract(sin(dot(i, vec2(127.1,311.7)))*43758.5453);
 float b = fract(sin(dot(i+vec2(1.,0.), vec2(127.1,311.7)))*43758.5453);
 float c = fract(sin(dot(i+vec2(0.,1.), vec2(127.1,311.7)))*43758.5453);
 float d = fract(sin(dot(i+vec2(1.,1.), vec2(127.1,311.7)))*43758.5453);
 return mix(mix(a,b,f.x),mix(c,d,f.x),f.y);
}
float canopy_segment(vec2 p, vec2 a, vec2 b, float width) {
 vec2 v = b-a;
 float t = clamp(dot(p-a,v)/dot(v,v),0.0,1.0);
 return 1.0-smoothstep(width-0.015,width+0.035,length(p-a-v*t));
}
void canopy_sky(vec2 rp, out vec3 sky, out float mass, out float bough) {
 sky = mix(vec3(0.98,0.93,0.88), vec3(0.8,0.84,0.98), clamp(rp.y*0.4,0.0,1.0));
 // A trunk and two softened forks enter from the left, behind the flower clusters.
 float tree = max(canopy_segment(rp,vec2(-0.20,1.9),vec2(0.30,0.80),0.105),
                  canopy_segment(rp,vec2(0.16,1.13),vec2(0.62,0.36),0.08));
 tree = max(tree,canopy_segment(rp,vec2(0.20,1.05),vec2(0.48,1.65),0.075));
 tree = max(tree,canopy_segment(rp,vec2(0.42,0.69),vec2(0.68,0.82),0.06));
 float edge = smoothstep(0.83,0.10,rp.x+0.09*sin(rp.y*7.0)+0.05*sin(rp.y*17.0+1.3));
 float leaf = canopy_noise(rp*7.0)*0.65+canopy_noise(rp*17.0+3.0)*0.35;
 mass = edge*smoothstep(0.37,0.66,leaf);
 bough = tree*edge;
 // Pale blossom masses, small muted branch hint. Keep open sky between boughs.
 sky = mix(sky,vec3(0.48,0.37,0.32),bough*0.66);
 vec3 petals = mix(vec3(0.94,0.68,0.67),vec3(1.0,0.85,0.81),canopy_noise(rp*48.0));
 sky = mix(sky,petals,mass*0.59*(1.0-bough*0.7));
}
