shader_type canvas_item;

// 1-texel outline around opaque pixels: keeps dark bosses readable on dark backdrops.
uniform vec4 outline_color : source_color = vec4(0.85, 0.4, 1.0, 1.0);
uniform float pulse_speed = 0.0;

// fragment()'s COLOR already contains the texture alpha (0 where the outline goes),
// so the node's modulate is carried over from vertex() instead.
varying vec4 modulate_color;

void vertex() {
	modulate_color = COLOR;
}

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	if (col.a < 0.1) {
		vec2 px = TEXTURE_PIXEL_SIZE;
		float a = texture(TEXTURE, UV + vec2(px.x, 0.0)).a;
		a = max(a, texture(TEXTURE, UV - vec2(px.x, 0.0)).a);
		a = max(a, texture(TEXTURE, UV + vec2(0.0, px.y)).a);
		a = max(a, texture(TEXTURE, UV - vec2(0.0, px.y)).a);
		float glow = pulse_speed > 0.0 ? 0.7 + 0.3 * sin(TIME * pulse_speed) : 1.0;
		col = vec4(outline_color.rgb, outline_color.a * step(0.1, a) * glow);
	}
	COLOR = col * modulate_color;
}
