/*
	CRT shader for Godot Engine by Yui Kinomoto @arlez80
	https://bitbucket.org/arlez80/godot-crt

	Copyright (c) 2020-2022 Yui Kinomoto

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in
	all copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE.
*/
shader_type canvas_item;


uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform float intensity : hint_range(0.0, 1.0) = 1.0;
uniform float pixel_size : hint_range(1.0, 8.0) = 3.0;
uniform float crt_curve : hint_range(0.0, 1.0) = 0.02;
uniform float crt_scan_line_color : hint_range(0.0, 1.0) = 0.347;
uniform float aperture_grille_rate : hint_range(0.0, 1.0) = 0.4;
uniform float rf_switch_esque_blur : hint_range(0.0, 1.0) = 1.0;
uniform float white_noise_rate : hint_range(0.0, 1.0) = 0.0;

float random(vec2 pos) {
	return fract(sin(dot(pos, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 px = SCREEN_PIXEL_SIZE * pixel_size;

	vec2 crt_curve_shift = (vec2(1.0) - sin(UV.yx * PI)) * crt_curve;
	vec2 crt_curve_scale = vec2(1.0) + crt_curve_shift * 2.0;
	vec2 texture_fixed_uv = UV * crt_curve_scale - crt_curve_shift;
	vec2 fixed_uv = SCREEN_UV * crt_curve_scale - crt_curve_shift;
	float enable_color = float(
		0.0 <= texture_fixed_uv.x && texture_fixed_uv.x <= 1.0
		&& 0.0 <= texture_fixed_uv.y && texture_fixed_uv.y <= 1.0
	);

	vec3 original = texture(screen_tex, SCREEN_UV).rgb;

	vec4 col;
	col.rgb = (
		texture(screen_tex, fixed_uv).rgb * (1.0 - rf_switch_esque_blur * 0.5)
		+ (
			texture(screen_tex, fixed_uv + vec2(-px.x * 3.1, 0.0)).rgb
			+ texture(screen_tex, fixed_uv + vec2(px.x * 3.1, 0.0)).rgb
		) * (rf_switch_esque_blur * 0.25)
	) * enable_color;
	col.a = 1.0;

	vec2 aperture_grille_pixel = vec2(floor((fixed_uv.x / px.x) / 3.0) * 3.0, fixed_uv.y);

	float white_noise = random(aperture_grille_pixel + vec2(sin(TIME * 0.543254), cos(TIME * 0.254323563)));
	col.rgb = mix(col.rgb, vec3(white_noise), white_noise_rate * enable_color);

	float aperture_grille_point = mod(((SCREEN_UV.x * crt_curve_scale.x) - crt_curve_shift.x) / px.x, 3.0);
	float aperture_grille_r_rate = clamp(1.0 - aperture_grille_point, 0.0, 1.0) + clamp(aperture_grille_point - 2.0, 0.0, 1.0);
	float aperture_grille_g_rate = clamp(1.0 - abs(1.0 - aperture_grille_point), 0.0, 1.0);
	float aperture_grille_b_rate = 1.0 - aperture_grille_r_rate - aperture_grille_g_rate;
	col = clamp(
		col * vec4(
			normalize(vec3(
				clamp(aperture_grille_r_rate, aperture_grille_rate, 1.0),
				clamp(aperture_grille_g_rate, aperture_grille_rate, 1.0),
				clamp(aperture_grille_b_rate, aperture_grille_rate, 1.0)
			)),
			1.0
		),
		vec4(0.0),
		vec4(1.0)
	);

	col = mix(
		col,
		vec4(0.0, 0.0, 0.0, 1.0),
		float(0 == int(fixed_uv.y / px.y) % 2) * crt_scan_line_color
	);

	COLOR = vec4(mix(original, col.rgb, intensity), 1.0);
}
