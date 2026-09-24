shader_type spatial;
render_mode unshaded, cull_disabled;
// Dev-scene grid floor for solo model tests (Hakozaki's test scenes use a bare
// debug grid). Lines soften with distance from the focus plane: a cheap
// depth-of-field stand-in, since the Compatibility renderer has no DOF.
uniform float blur_intensity = 0.4;
uniform float blur_min = 0.05;
uniform float focus_dist = 3.0;
uniform vec3 bg : source_color = vec3(0.16, 0.17, 0.2);
uniform vec3 line : source_color = vec3(0.42, 0.44, 0.5);
varying vec3 wp;
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	float d = length(wp - CAMERA_POSITION_WORLD);
	float blur = max(blur_min, blur_intensity * abs(d - focus_dist) / focus_dist);
	vec2 g = wp.xz / 0.25;
	vec2 f = abs(fract(g - 0.5) - 0.5) / fwidth(g);
	float w = 1.0 + blur * 30.0;
	float minor = 1.0 - clamp(min(f.x, f.y) / w, 0.0, 1.0);
	vec2 g2 = wp.xz;
	vec2 f2 = abs(fract(g2 - 0.5) - 0.5) / fwidth(g2);
	float major = 1.0 - clamp(min(f2.x, f2.y) / (1.5 + blur * 30.0), 0.0, 1.0);
	float fade = 1.0 / (1.0 + w * 0.35);
	vec3 c = mix(bg, line, max(minor * 0.35, major) * fade);
	float far = smoothstep(4.0, 12.0, d);
	ALBEDO = mix(c, bg, far);
}
