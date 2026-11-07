shader_type canvas_item;

uniform float base_y = 0.0;
uniform float fall_angle = 0.0;

void vertex() {
	vec2 point = VERTEX - vec2(0.0, base_y);
	float c = cos(fall_angle);
	float s = sin(fall_angle);
	VERTEX = vec2(point.x * c - point.y * s, point.x * s + point.y * c) + vec2(0.0, base_y);
}
