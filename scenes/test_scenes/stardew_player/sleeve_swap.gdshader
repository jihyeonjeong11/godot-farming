shader_type canvas_item;

uniform vec4 src0 : source_color;
uniform vec4 src1 : source_color;
uniform vec4 src2 : source_color;
uniform vec4 dst0 : source_color;
uniform vec4 dst1 : source_color;
uniform vec4 dst2 : source_color;

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	if (c.a > 0.0) {
		if (distance(c.rgb, src0.rgb) < 0.02) c.rgb = dst0.rgb;
		else if (distance(c.rgb, src1.rgb) < 0.02) c.rgb = dst1.rgb;
		else if (distance(c.rgb, src2.rgb) < 0.02) c.rgb = dst2.rgb;
	}
	COLOR = c;
}
