shader_type canvas_item;

uniform float base_y = 0.0;
uniform float bend_height : hint_range(1.0, 512.0) = 64.0;
uniform float shake_intensity : hint_range(0.0, 16.0) = 0.0;
uniform float shake_speed : hint_range(0.0, 80.0) = 20.0;

void vertex() {
	float bend = clamp((base_y - VERTEX.y) / bend_height, 0.0, 1.0);
	float phase = (MODEL_MATRIX[3].x + MODEL_MATRIX[3].y) * 0.07;
	float shake = sin(TIME * shake_speed + phase) * shake_intensity;

	VERTEX.x += shake * bend;
	VERTEX.y += abs(shake) * bend * 0.15;
}
