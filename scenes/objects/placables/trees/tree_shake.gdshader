shader_type canvas_item;

// 이 y(스프라이트 로컬 px)보다 위쪽만 흔들린다. centered 스프라이트면 0.0 = 위 절반.
// 원점을 밑동에 둔 스프라이트는 음수로 내려줘야 수관만 흔들린다.
uniform float shake_top_y = 0.0;
uniform float shake_intensity = 1.0;
uniform float shake_speed = 20.0;

void vertex() {
	vec2 shake = vec2(0.0);

	if(VERTEX.y < shake_top_y) {
		shake.x = sin(TIME * shake_speed + VERTEX.y) * shake_intensity;
	}

	VERTEX.xy += shake;
}
