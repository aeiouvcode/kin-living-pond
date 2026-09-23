shader_type canvas_item;
render_mode blend_disabled, unshaded;

#include "res://shaders/pond.gdshaderinc"

uniform sampler2D prev : filter_nearest, repeat_disable;
uniform vec2 grid = vec2(90.0, 195.0);
uniform float aspect = 0.462;
uniform vec4 imp[24];
uniform int imp_count = 0;
uniform float damp = 0.987;
uniform float c2 = 0.46;
uniform bool reset = false;

float dec(vec2 rg) {
	float q = floor(rg.x * 255.0 + 0.5) * 256.0 + floor(rg.y * 255.0 + 0.5);
	return q / 65535.0 * 2.0 - 1.0;
}

vec2 enc(float v) {
	float q = floor(clamp(v * 0.5 + 0.5, 0.0, 1.0) * 65535.0 + 0.5);
	float hi = floor(q / 256.0);
	return vec2(hi, q - hi * 256.0) / 255.0;
}

void fragment() {
	vec2 px = 1.0 / grid;
	vec4 c = texture(prev, UV);
	float h = dec(c.rg);
	float hp = dec(c.ba);
	float l = dec(texture(prev, UV - vec2(px.x, 0.0)).rg);
	float r = dec(texture(prev, UV + vec2(px.x, 0.0)).rg);
	float u = dec(texture(prev, UV - vec2(0.0, px.y)).rg);
	float d = dec(texture(prev, UV + vec2(0.0, px.y)).rg);
	float hn = (2.0 * h - hp + c2 * (l + r + u + d - 4.0 * h)) * damp;
	vec2 cell = UV * grid;
	for (int i = 0; i < 24; i++) {
		if (i >= imp_count) { break; }
		vec2 dv = cell - imp[i].xy;
		hn += imp[i].w * exp(-dot(dv, dv) / (imp[i].z * imp[i].z));
	}
	vec2 p = pond_p(UV, aspect);
	float sdf = pond_sdf(p, aspect);
	float solid = solid_mask(sdf, stones(p), 0.002);
	hn *= 1.0 - solid;
	hn = clamp(hn, -0.98, 0.98);
	if (reset) { hn = 0.0; h = 0.0; }
	COLOR = vec4(enc(hn), enc(h * (1.0 - solid)));
}
