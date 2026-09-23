shader_type canvas_item;
render_mode unshaded;

#include "res://shaders/pond.gdshaderinc"

uniform float aspect = 0.462;
uniform float time = 0.0;
uniform vec3 deep_col : source_color = vec3(0.018, 0.062, 0.068);
uniform vec3 mid_col : source_color = vec3(0.06, 0.13, 0.12);

// Small pebbles on the pond bed.
vec3 pebbles(vec2 p) {
	vec2 g = p * 120.0;
	vec2 i = floor(g);
	vec2 f = fract(g);
	float b1 = 9.0;
	float b2 = 9.0;
	vec2 id = vec2(0.0);
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 o = vec2(float(x), float(y));
			vec2 r = o + h22(i + o) - f;
			float d = dot(r, r);
			if (d < b1) { b2 = b1; b1 = d; id = i + o; }
			else if (d < b2) { b2 = d; }
		}
	}
	float edge = sqrt(b2) - sqrt(b1);
	return vec3(smoothstep(0.0, 0.45, edge), h21(id), sqrt(b1));
}

void fragment() {
	vec2 p = pond_p(UV, aspect);
	float sdf = pond_sdf(p, aspect);
	float depth = smoothstep(-0.01, -0.2, sdf);
	vec3 pb = pebbles(p);
	float tone = mix(0.55, 1.15, pb.y);
	vec3 pcol = mix(vec3(0.34, 0.29, 0.23), vec3(0.47, 0.43, 0.36), pb.y) * tone;
	pcol = mix(pcol * 0.62, pcol, pb.x);
	pcol *= 1.0 - 0.35 * pb.z;
	float silt = fbm3(p * 9.0);
	pcol = mix(pcol, vec3(0.2, 0.22, 0.14), smoothstep(0.45, 0.8, silt) * 0.7);
	float algae = smoothstep(0.55, 0.85, fbm3(p * 4.0 + 11.0));
	pcol = mix(pcol, vec3(0.08, 0.17, 0.09), algae * 0.55);
	// Submerged stone bases continue the shore stones under the surface.
	vec3 st = stones(p);
	float band = smoothstep(-0.06, -0.012, sdf);
	float sub = smoothstep(0.1, 0.35, st.x * band);
	vec3 scol = mix(vec3(0.24, 0.23, 0.2), vec3(0.36, 0.33, 0.27), st.y) * (0.6 + 0.5 * st.x);
	scol = mix(scol, vec3(0.12, 0.2, 0.1), smoothstep(0.4, 0.8, vnoise(p * 60.0)) * 0.5);
	pcol = mix(pcol, scol, sub);
	// Water absorption: shallow reads warm, the deep centre falls to green-black.
	vec3 col = mix(pcol * vec3(0.75, 0.85, 0.8), mid_col, 0.45 + 0.25 * depth);
	col = mix(col, deep_col, depth * 0.78);
	// Slow drifting light from the canopy.
	float dapple = fbm3(p * 3.0 + vec2(time * 0.012, -time * 0.008));
	col *= 0.82 + 0.3 * smoothstep(0.35, 0.75, dapple);
	COLOR = vec4(col, 1.0);
}
