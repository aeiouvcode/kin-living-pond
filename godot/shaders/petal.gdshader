shader_type canvas_item;
render_mode unshaded;

// UV in [0,1] across the quad. COLOR: r = blur, g = alpha, b = type (0 petal, 1 flower).
void fragment() {
	vec2 q = UV * 2.0 - 1.0;
	float blur = COLOR.r;
	float alpha = COLOR.g;
	float soft = 0.04 + blur * 0.55;
	float dist;
	float centre;
	if (COLOR.b > 0.5) {
		float a = atan(q.y, q.x) + 1.5708;
		float k = abs(cos(2.5 * a));
		float edge = 0.42 + 0.5 * sqrt(k) - 0.12 * smoothstep(0.985, 1.0, k);
		dist = length(q) - edge;
		centre = smoothstep(0.35, 0.0, length(q));
	} else {
		vec2 p = q * vec2(1.45, 1.0);
		dist = length(p + vec2(0.0, 0.1)) - 0.82;
		float notch = 0.24 - length(q - vec2(0.0, -0.98));
		dist = max(dist, notch);
		centre = smoothstep(1.0, 0.1, q.y + 0.9) * 0.6;
	}
	float a = smoothstep(soft, -soft, dist) * alpha;
	vec3 white = vec3(1.0, 0.97, 0.98);
	vec3 pink = vec3(0.97, 0.66, 0.78);
	vec3 col = mix(white, pink, centre * 0.8);
	col *= 0.93 + 0.07 * smoothstep(-0.6, 0.0, dist);
	if (COLOR.b > 0.5) {
		col = mix(col, vec3(0.98, 0.84, 0.45), smoothstep(0.1, 0.03, length(q)) * 0.8);
	}
	col = mix(col, vec3(0.8, 0.82, 0.98), blur * 0.35);
	COLOR = vec4(col, a);
}
