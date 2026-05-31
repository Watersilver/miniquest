shader_type canvas_item;

uniform vec4 clr : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform int type : hint_range(0, 2) = 2;
uniform float thickness = 1.0;

const vec2[8] DIRECTIONS = {
	vec2(1.0, 0.0),
	vec2(0.0, 1.0),
	vec2(-1.0, 0.0),
	vec2(0.0, -1.0),
	vec2(1.0, 1.0),
	vec2(-1.0, 1.0),
	vec2(-1.0, -1.0),
	vec2(1.0, -1.0)
};

float gtz(float input) { return max(0, sign(input)); }
// returns 1 if input > 0, else 0

float check(sampler2D tex, vec2 from, vec2 size) {
	float result = 0.0;
	for (int i = 0; i < 4 * type; i++) {
		result += texture(tex, from + DIRECTIONS[i] * size * thickness).a;
	}
	return gtz(result);
}

void fragment() {
	if (COLOR.a > 0.1 && COLOR.r < 0.5) {
		//vec2 uv = fract(UV * vec2(float(6), float(43)));
		COLOR = vec4(UV.x * 0.75, UV.y * 0.9, 1.0, 1.0);
	} else {
		COLOR = mix(COLOR, clr, max(0, check(TEXTURE, UV, TEXTURE_PIXEL_SIZE) - gtz(COLOR.a)));
	}
}


//shader_type canvas_item;
//
//void fragment() {
	//if (COLOR.a > 0.1 && COLOR.r < 0.5) {
		////vec2 uv = fract(UV * vec2(float(6), float(43)));
		//COLOR = vec4(UV.x * 0.75, UV.y * 0.9, 1.0, 1.0);
	//}
//}
