shader_type canvas_item;

// 밑동을 고정한 채 위로 갈수록 크게 기울어지는 흔들림.
// Sprite2D는 쿼드라서 정점이 네 개뿐이고, 흔들림은 밑동에서 꼭대기까지
// 선형으로 번지는 shear가 된다. 나무가 통째로 기우는 모양이라 픽셀아트에서는
// 이 정도가 오히려 자연스럽다.

// 스프라이트 로컬 좌표(px) 기준. centered 스프라이트면 base_y = height * 0.5.
uniform float base_y = 64.0;
uniform float bend_height : hint_range(1.0, 512.0) = 128.0;

// 상시 바람. 0으로 두면 가만히 서 있는다.
uniform float sway_amount : hint_range(0.0, 8.0) = 0.6;
uniform float sway_speed : hint_range(0.0, 10.0) = 1.3;

// interact/타격 때 스크립트가 값을 넣고 0으로 되돌린다.
uniform float shake_intensity : hint_range(0.0, 16.0) = 0.0;
uniform float shake_speed : hint_range(0.0, 80.0) = 26.0;

void vertex() {
	// 0 = 밑동, 1 = 꼭대기.
	float bend = clamp((base_y - VERTEX.y) / bend_height, 0.0, 1.0);

	// 나무마다 위상을 어긋내지 않으면 숲 전체가 한 몸처럼 움직인다.
	float phase = (MODEL_MATRIX[3].x + MODEL_MATRIX[3].y) * 0.07;

	float sway = sin(TIME * sway_speed + phase) * sway_amount;
	float shake = sin(TIME * shake_speed + phase) * shake_intensity;

	VERTEX.x += (sway + shake) * bend;
	// 옆으로 휠 때 조금 내려앉아야 나무가 늘어나 보이지 않는다.
	VERTEX.y += abs(shake) * bend * 0.15;
}
