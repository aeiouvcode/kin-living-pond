shader_type canvas_item;
render_mode unshaded, blend_disabled;
#include "res://shaders/bowl_common.gdshaderinc"

uniform sampler2D under : filter_linear, repeat_disable;
uniform sampler2D small : filter_linear, repeat_disable;
uniform sampler2D sim : filter_nearest, repeat_disable;
uniform vec2 grid = vec2(90.0, 195.0);
uniform vec2 res = vec2(390.0, 844.0);
uniform vec2 center = vec2(195.0, 422.0);
uniform float radius = 200.0;
uniform float time = 0.0;
uniform float bloom = 1.0;

float dec(vec2 rg) {
	float q = floor(rg.x * 255.0 + 0.5) * 256.0 + floor(rg.y * 255.0 + 0.5);
	return q / 65535.0 * 2.0 - 1.0;
}
float height(vec2 uv) {
	vec2 g = uv * grid - 0.5;
	vec2 i = floor(g); vec2 f = fract(g); vec2 inv = 1.0 / grid;
	float a = dec(texture(sim, (i + vec2(0.5, 0.5)) * inv).rg);
	float b = dec(texture(sim, (i + vec2(1.5, 0.5)) * inv).rg);
	float c = dec(texture(sim, (i + vec2(0.5, 1.5)) * inv).rg);
	float d = dec(texture(sim, (i + vec2(1.5, 1.5)) * inv).rg);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}
vec3 hue(float t) {
	return clamp(abs(fract(t + vec3(0.0, 0.667, 0.333)) * 6.0 - 3.0) - 1.0, 0.0, 1.0);
}
void fragment() {
	vec2 uv = UV;
	vec2 e = 1.0 / grid;
	float hx = height(uv + vec2(e.x, 0.0)) - height(uv - vec2(e.x, 0.0));
	float hy = height(uv + vec2(0.0, e.y)) - height(uv - vec2(0.0, e.y));
	vec2 grad = vec2(hx, hy);
	vec2 ruv = clamp(uv - grad * 0.06, vec2(0.001), vec2(0.999));
	vec3 col = texture(under, ruv).rgb;
	// Bloom: wide soft glow of the bright parts, from the mip chain.
	vec2 st = 1.0 / vec2(textureSize(small, 0));
	vec3 glow = vec3(0.0);
	for (int j = -2; j <= 2; j++) {
		for (int i = -2; i <= 2; i++) {
			vec2 o = vec2(float(i), float(j));
			glow += texture(small, ruv + o * st * 1.3).rgb * exp(-dot(o, o) * 0.35);
		}
	}
	glow /= 11.7;
	col += max(glow - 0.62, 0.0) * 1.1 * bloom;
	col = mix(col, glow, 0.08 * bloom);
	// Ripple light.
	vec3 n = normalize(vec3(-grad * 16.0, 1.0));
	vec3 L = normalize(vec3(0.45, -0.7, 0.55));
	float spec = pow(max(dot(n, normalize(L + vec3(0, 0, 1))), 0.0), 60.0);
	col += vec3(1.0) * spec * 0.18;
	col += vec3(0.06, 0.06, 0.08) * clamp(-(hx + hy) * 20.0, -1.0, 1.0);
	// Glass rim with a rainbow refraction glint at the upper right.
	vec2 px = uv * res;
	vec2 d = (px - center) / radius;
	float r = length(d);
	float a = atan(d.y, d.x);
	float pxr = 1.0 / radius;
	float rim = exp(-pow((r - 1.0) / (pxr * 1.6), 2.0));
	float rim2 = exp(-pow((r - 0.985) / (pxr * 5.0), 2.0));
	col += vec3(0.95, 0.96, 1.0) * rim * 0.4 + vec3(0.9, 0.92, 1.0) * rim2 * 0.06;
	float ga = -0.85;
	float gw = exp(-pow((a - ga) / 0.32, 2.0));
	float band = exp(-pow((r - 0.975) / (pxr * 9.0), 2.0));
	col += hue(r * 6.0 + a * 0.6 + 0.1) * band * gw * 0.45;
	col += vec3(1.0) * exp(-pow((r - 0.99) / (pxr * 2.5), 2.0)) * gw * 0.5;
	// Bokeh glints near the rim light.
	for (int i = 0; i < 5; i++) {
		float fi = float(i);
		float aa = ga + (fi - 2.0) * 0.14 + 0.03 * sin(time * 0.3 + fi);
		float rr = 0.9 - 0.06 * fi + 0.02 * sin(time * 0.2 + fi * 2.0);
		vec2 c = vec2(cos(aa), sin(aa)) * rr;
		float s = 0.028 + 0.012 * bh21(vec2(fi, 3.0));
		float disc = smoothstep(s, s * 0.6, length(d - c));
		float tw = 0.5 + 0.5 * sin(time * (0.7 + fi * 0.3) + fi * 5.0);
		col += mix(vec3(0.75, 0.95, 1.0), vec3(1.0, 0.95, 0.85), bh21(vec2(fi, 9.0))) * disc * (0.12 + 0.18 * tw);
	}
	// Dust motes and tiny sparkles drifting in the light.
	vec2 mp = px / 7.0 + vec2(time * 0.9, -time * 0.6);
	vec2 mi = floor(mp);
	float mh = bh21(mi);
	vec2 mo = vec2(bh21(mi + 3.1), bh21(mi + 7.7));
	float mote = smoothstep(0.22, 0.0, length(fract(mp) - mo)) * step(0.996, mh);
	col += vec3(1.0) * mote * (0.35 + 0.35 * sin(time * 3.0 + mh * 40.0));
	// Dreamy overexposure and a soft vignette.
	col = 1.0 - (1.0 - col) * 0.93;
	vec2 v = uv - 0.5;
	col *= 1.0 - 0.12 * dot(v, v) * 2.0;
	COLOR = vec4(col, 1.0);
}
