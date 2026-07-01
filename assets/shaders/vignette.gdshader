shader_type canvas_item;
// Vinheta atmosférica: escurece as bordas da tela pra dar clima sombrio.
// Aplicada num ColorRect de tela cheia no HUD.

uniform float inner : hint_range(0.0, 1.0) = 0.42;
uniform float outer : hint_range(0.0, 1.5) = 1.0;
uniform float strength : hint_range(0.0, 1.0) = 0.9;
uniform vec3 tint : source_color = vec3(0.0);

void fragment() {
	vec2 d = UV - vec2(0.5);
	// 0 no centro, ~1 nos cantos.
	float dist = length(d) * 1.41421356;
	float v = smoothstep(inner, outer, dist) * strength;
	COLOR = vec4(tint, v);
}
