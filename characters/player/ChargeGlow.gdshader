shader_type canvas_item;
render_mode blend_add;

uniform vec4 glow_color : source_color = vec4(0.25, 1.0, 0.92, 1.0);

void fragment() {
	vec2 uv = UV * 2.0 - 1.0;
	float d = length(uv);
	float ring = smoothstep(0.55, 0.85, d) * (1.0 - smoothstep(0.85, 1.0, d));
	float core = 1.0 - smoothstep(0.0, 0.6, d);
	float pulse = 0.65 + 0.35 * sin(TIME * 14.0);
	COLOR = vec4(glow_color.rgb, (ring * 1.2 + core * 0.25) * pulse);
}
