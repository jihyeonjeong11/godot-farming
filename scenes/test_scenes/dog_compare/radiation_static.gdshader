shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform float intensity : hint_range(0.0, 1.0) = 0.5;
uniform float grain_size = 3.0;
uniform float tracking_speed = 0.12;
uniform float tracking_width = 0.07;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

vec3 sample_chroma(vec2 uv, float spread) {
	vec3 c = vec3(0.0);
	c.r += texture(screen_tex, uv + vec2(spread, 0.0)).r;
	c.r += texture(screen_tex, uv + vec2(spread * 2.0, 0.0)).r;
	c.g += texture(screen_tex, uv).g * 2.0;
	c.b += texture(screen_tex, uv - vec2(spread, 0.0)).b;
	c.b += texture(screen_tex, uv - vec2(spread * 2.0, 0.0)).b;
	return c * 0.5;
}

void fragment() {
	vec2 uv = SCREEN_UV;
	float t = TIME;
	float frame = floor(t * 30.0);
	float line = floor(FRAGCOORD.y / grain_size);

	float glitch = step(0.93, hash(vec2(floor(t * 3.0), 3.0))) * intensity;
	uv.y = fract(uv.y + glitch * (hash(vec2(frame, 9.0)) - 0.5) * 0.08);

	uv.x += sin(uv.y * 6.0 + t * 1.3) * 0.002 * intensity;
	uv.x += sin(uv.y * 140.0 + t * 9.0) * 0.0008 * intensity;
	uv.x += (hash(vec2(line, frame)) - 0.5) * 0.0015 * intensity;

	float band_y = 1.0 - fract(t * tracking_speed);
	float d = abs(uv.y - band_y);
	d = min(d, 1.0 - d);
	float band = smoothstep(tracking_width, 0.0, d) * intensity;
	uv.x += (hash(vec2(line, frame + 1.0)) - 0.3) * 0.05 * band;

	float head = smoothstep(0.96, 1.0, uv.y) * intensity;
	uv.x += (hash(vec2(line, frame + 2.0)) - 0.2) * 0.06 * head;

	vec3 col = sample_chroma(uv, 0.003 * intensity + 0.004 * band);

	float luma = dot(col, vec3(0.299, 0.587, 0.114));
	col = mix(col, vec3(luma), 0.35 * intensity);
	col = mix(col, col * vec3(1.05, 0.95, 1.1), 0.5 * intensity);
	col = col * (1.0 - 0.15 * intensity) + 0.05 * intensity;

	float noise = hash(floor(FRAGCOORD.xy / grain_size) + frame);
	col += (noise - 0.5) * 0.12 * intensity;
	float streak = step(0.7, hash(vec2(line, frame + 3.0)));
	col = mix(col, vec3(noise), clamp(band * 0.8 + head, 0.0, 1.0) * streak);

	col *= 1.0 - 0.12 * intensity * step(0.5, fract(FRAGCOORD.y / (grain_size * 2.0)));

	vec2 v = SCREEN_UV - 0.5;
	col *= 1.0 - dot(v, v) * 0.8 * intensity;

	col *= 1.0 - 0.06 * intensity * hash(vec2(frame, 7.0));

	COLOR = vec4(col, 1.0);
}
